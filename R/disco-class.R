#' @title Wrap a Graph as a Disco Object
#'
#' @description
#' Wraps a causal graph object (e.g. a [caugi::caugi] graph, or a graph object
#' from \pkg{pcalg} or \pkg{bnlearn}) and a `Knowledge` object into a `Disco`
#' object, which is the output object of causal discovery methods used in
#' \pkg{causalDisco}.
#'
#' @details
#' The conversion from any graph type to a [caugi::caugi] is handled by the \pkg{caugi}
#' package.
#'
#' @param graph A causal graph object
#' @param kn A `Knowledge` object. Default is an empty `Knowledge` object.
#' @param class A string describing the graph class.
#'
#' @returns A `Disco` object containing a [caugi::caugi] and a `Knowledge` object in a list.
#'
#' @seealso [caugi::caugi()]
#' @family Extending causalDisco
#' @concept extending_causalDisco
#' @export
as_disco <- function(graph, kn = knowledge(), class = "PDAG") {
  UseMethod("as_disco")
}

# delegate field names used by `Knowledge` methods
.knowledge_fields <- c("vars", "tiers", "edges", "frozen")

#' @title Create a Disco Object
#'
#' @param cg A [caugi::caugi] object
#' @param kn A `Knowledge` object
#' @returns A `Disco` object containing the [caugi::caugi] and `Knowledge` objects.
#' @keywords internal
#' @noRd
new_disco <- function(cg, kn) {
  if (!is_knowledge(kn)) {
    stop("`kn` must be a Knowledge object.", call. = FALSE)
  }
  caugi::is_caugi(cg, throw_error = TRUE)
  structure(
    list(
      caugi = cg,
      knowledge = kn
    ),
    class = "Disco"
  )
}

#' @title Build a caugi Graph, Falling Back to UNKNOWN on an Invalid Claimed Class
#'
#' @description
#' Constraint-based algorithms can, due to statistical errors in finite samples, return edges
#' that do not form a valid graph of the claimed `class`. Rather than erroring, this builds the
#' graph as `"UNKNOWN"` instead and messages with a diagnostic naming the actual defect, checked
#' via [caugi::is_acyclic()] and the presence of `<->` edges.
#'
#' @param build A function taking a single `class` argument and returning a [caugi::caugi]
#' object of that class (e.g. `\(cls) caugi::caugi(..., class = cls)` or
#' `\(cls) caugi::mutate_caugi(cg, cls)`).
#' @param class The claimed graph class.
#' @returns The result of `build(class)` if that succeeds, otherwise `build("UNKNOWN")`.
#' @keywords internal
#' @noRd
.caugi_with_fallback <- function(build, class) {
  tryCatch(
    build(class),
    error = function(e) {
      cg_unknown <- build("UNKNOWN")
      detail <- ""
      if (identical(class, "PDAG")) {
        acyclic <- tryCatch(caugi::is_acyclic(cg_unknown), error = function(e) {
          NA
        })
        has_bidirected <- any(caugi::edges(cg_unknown)$edge == "<->")
        detail <- if (isFALSE(acyclic) && has_bidirected) {
          " The graph contains a directed cycle and bidirected conflict edges."
        } else if (isFALSE(acyclic)) {
          " The graph contains a directed cycle."
        } else if (has_bidirected) {
          " The graph contains bidirected conflict edges."
        } else {
          " The graph is not a valid PDAG."
        }
      }
      message(sprintf("Cannot mutate graph to class '%s'.%s", class, detail))
      cg_unknown
    }
  )
}

#' @inheritParams as_disco
#' @export
as_disco.default <- function(
  graph,
  kn = knowledge(),
  class = "PDAG"
) {
  if (!is_knowledge(kn)) {
    stop("`kn` must be a Knowledge object.", call. = FALSE)
  }
  if (caugi::is_caugi(graph)) {
    cg <- graph
  } else {
    cg <- caugi::as_caugi(graph, collapse = TRUE, class = class)
  }
  new_disco(cg, kn)
}

#' @inheritParams as_disco
#' @export
as_disco.pcAlgo <- function(
  graph,
  kn = knowledge(),
  class = "PDAG"
) {
  if (!is_knowledge(kn)) {
    stop("`kn` must be a Knowledge object.", call. = FALSE)
  }
  # Convert via the adjacency matrix rather than the `graphNEL` slot so that
  # bidirected conflict edges (\pkg{pcalg} amat code 2, produced with
  # `solve.confl = TRUE`) are preserved as `<->` instead of being collapsed to
  # undirected edges.
  amat <- methods::as(graph, "amat")
  nodes <- colnames(amat)
  edges <- .pcalg_amat_to_edges(amat, nodes)

  if (nrow(edges) == 0L) {
    cg <- caugi::caugi(nodes = nodes, class = class)
  } else {
    cg_class <- if (any(edges$edge == "<->")) "UNKNOWN" else class
    cg <- .caugi_with_fallback(
      build = function(cls) {
        caugi::caugi(
          from = edges$from,
          edge = edges$edge,
          to = edges$to,
          nodes = nodes,
          class = cls
        )
      },
      class = cg_class
    )
  }
  new_disco(cg, kn)
}

#' @title Convert a \pkg{pcalg} CPDAG Adjacency Matrix to caugi Edges
#'
#' @description
#' Decodes a \pkg{pcalg} `amat` of type `"cpdag"` into a data frame of caugi
#' edge triplets. The \pkg{pcalg} coding for an unordered pair `(i, j)` is:
#' `amat[i,j] = 1, amat[j,i] = 0` means `j -> i`; `amat[i,j] = 1, amat[j,i] = 1`
#' means `i -- j`; and `amat[i,j] = 2, amat[j,i] = 2` (only with
#' `solve.confl = TRUE`) means the bidirected conflict edge `i <-> j`.
#'
#' @param amat A \pkg{pcalg} adjacency matrix of type `"cpdag"`.
#' @param nodes The node names (column names of `amat`).
#' @returns A data frame with character columns `from`, `edge`, and `to`.
#' @keywords internal
#' @noRd
.pcalg_amat_to_edges <- function(amat, nodes) {
  from <- character(0)
  edge <- character(0)
  to <- character(0)
  np <- length(nodes)

  if (np >= 2L) {
    for (i in seq_len(np - 1L)) {
      for (j in seq(i + 1L, np)) {
        a <- amat[i, j]
        b <- amat[j, i]
        if (a == 0 && b == 0) {
          next
        }
        ni <- nodes[i]
        nj <- nodes[j]
        if (a == 2 || b == 2) {
          from <- c(from, ni)
          edge <- c(edge, "<->")
          to <- c(to, nj)
        } else if (a == 1 && b == 1) {
          from <- c(from, ni)
          edge <- c(edge, "---")
          to <- c(to, nj)
        } else if (a == 1 && b == 0) {
          # amat[i,j] = 1, amat[j,i] = 0  =>  j -> i
          from <- c(from, nj)
          edge <- c(edge, "-->")
          to <- c(to, ni)
        } else {
          # amat[i,j] = 0, amat[j,i] = 1  =>  i -> j
          from <- c(from, ni)
          edge <- c(edge, "-->")
          to <- c(to, nj)
        }
      }
    }
  }

  data.frame(from = from, edge = edge, to = to, stringsAsFactors = FALSE)
}

#' @inheritParams as_disco
#' @export
as_disco.fciAlgo <- function(
  graph,
  kn = knowledge(),
  class = "PAG"
) {
  if (!is_knowledge(kn)) {
    stop("`kn` must be a Knowledge object.", call. = FALSE)
  }
  amat <- methods::as(graph, "matrix")
  cg <- caugi::as_caugi(amat, class = class)
  new_disco(cg, kn)
}

#' @inheritParams as_disco
#' @export
as_disco.tetrad_graph <- function(
  graph,
  kn = knowledge(),
  class = "PDAG"
) {
  if (!is_knowledge(kn)) {
    stop("`kn` must be a Knowledge object.", call. = FALSE)
  }
  cg <- caugi::as_caugi(graph$amat, collapse = TRUE, class)
  new_disco(cg, kn)
}

#' @inheritParams as_disco
#' @importFrom rlang .data
#' @export
as_disco.EssGraph <- function(
  graph,
  kn = knowledge(),
  class = "PDAG"
) {
  if (!is_knowledge(kn)) {
    stop("`kn` must be a Knowledge object.", call. = FALSE)
  }
  nodes <- graph$.nodes

  edges <- purrr::map2_dfr(
    seq_along(graph$.in.edges),
    graph$.in.edges,
    \(child_idx, parent_vec) {
      if (length(parent_vec) == 0L) {
        return(tibble::tibble(
          from = character(),
          to = character(),
          edge = character()
        ))
      }
      tibble::tibble(
        from = nodes[parent_vec],
        to = rep(nodes[child_idx], length(parent_vec)),
        edge = rep("-->", length(parent_vec))
      )
    }
  )

  if (nrow(edges) == 0L) {
    cg <- caugi::caugi(nodes = nodes, class = "PDAG")
    return(new_disco(cg, kn))
  }

  collapsed <- edges |>
    dplyr::mutate(
      canon_from = pmin(.data$from, .data$to),
      canon_to = pmax(.data$from, .data$to)
    ) |>
    dplyr::group_by(.data$canon_from, .data$canon_to) |>
    dplyr::summarise(
      has_fw = any(
        .data$from == .data$canon_from & .data$to == .data$canon_to
      ),
      has_bw = any(
        .data$from == .data$canon_to & .data$to == .data$canon_from
      ),
      .groups = "drop"
    ) |>
    dplyr::transmute(
      from = dplyr::case_when(
        has_fw & has_bw ~ canon_from,
        has_fw ~ canon_from,
        TRUE ~ canon_to
      ),
      to = dplyr::case_when(
        has_fw & has_bw ~ canon_to,
        has_fw ~ canon_to,
        TRUE ~ canon_from
      ),
      edge = dplyr::if_else(.data$has_fw & .data$has_bw, "---", "-->")
    )

  cg <- .caugi_with_fallback(
    build = function(cls) {
      caugi::caugi(
        from = collapsed$from,
        edge = collapsed$edge,
        to = collapsed$to,
        nodes = nodes,
        class = cls
      )
    },
    class = class
  )
  new_disco(cg, kn)
}

#' @title Print a Disco Object
#' @param x A `Disco` object.
#' @param ... Additional arguments (not used).
#' @returns Invisibly returns the `Disco` object.
#' @examples
#' data(tpc_example)
#' kn <- knowledge(
#'   tpc_example,
#'   tier(
#'     child ~ starts_with("child"),
#'     youth ~ starts_with("youth"),
#'     old ~ starts_with("old")
#'   )
#' )
#' cd_tges <- tpc(engine = "causalDisco", test = "fisher_z")
#' disco_cd_tges <- disco(data = tpc_example, method = cd_tges, knowledge = kn)
#' print(disco_cd_tges)
#'
#' @concept print
#' @family print
#' @exportS3Method print Disco
print.Disco <- function(x, ...) {
  .check_if_pkgs_are_installed(
    pkgs = c("cli"),
    function_name = "print.Disco"
  )

  cg <- x$caugi
  graph_class <- x$graph_type
  if (is.null(graph_class)) {
    graph_class <- cg@graph_class
  }
  nd <- nodes(cg)
  ed <- edges(cg)
  n_nodes <- nrow(nd)
  n_edges <- nrow(ed)

  kn <- x$knowledge
  n_tiers <- if (!is.null(kn$tiers)) nrow(kn$tiers) else 0L
  n_vars <- if (!is.null(kn$vars)) nrow(kn$vars) else 0L
  n_required <- sum(kn$edges$status == "required", na.rm = TRUE)
  n_forbidden <- sum(kn$edges$status == "forbidden", na.rm = TRUE)
  kn_has_content <- n_tiers > 0L || n_required > 0L || n_forbidden > 0L

  kn_parts <- character(0)
  if (n_tiers > 0L) {
    kn_parts <- c(kn_parts, paste0(n_tiers, " tier", if (n_tiers != 1L) "s"))
  }
  if (n_required > 0L) {
    kn_parts <- c(kn_parts, paste0(n_required, " required"))
  }
  if (n_forbidden > 0L) {
    kn_parts <- c(kn_parts, paste0(n_forbidden, " forbidden"))
  }
  kn_str <- if (length(kn_parts) > 0L) {
    paste0(" | Knowledge: ", paste(kn_parts, collapse = ", "))
  } else {
    ""
  }

  cat(sprintf(
    "<Disco %s: %d nodes | %d edges%s>\n",
    graph_class,
    n_nodes,
    n_edges,
    kn_str
  ))

  if (kn_has_content) {
    cat("Learned graph:\n")
  }
  .print_item_line("nodes", nd$name)
  if (n_edges > 0L) {
    .print_item_line("edges", paste0(ed$from, ed$edge, ed$to))
  }

  if (kn_has_content) {
    cat("Knowledge:\n")
    .print_knowledge_body(kn)
  }

  invisible(x)
}

.knowledge_has_content <- function(kn) {
  if (is.null(kn)) {
    return(FALSE)
  }
  n_tiers <- if (!is.null(kn$tiers)) nrow(kn$tiers) else 0L
  n_required <- sum(kn$edges$status == "required", na.rm = TRUE)
  n_forbidden <- sum(kn$edges$status == "forbidden", na.rm = TRUE)
  n_tiers > 0L || n_required > 0L || n_forbidden > 0L
}

.disco_graph_type <- function(graph_class, has_knowledge) {
  if (is.null(graph_class)) {
    return("UNKNOWN")
  }
  switch(
    graph_class,
    PDAG = if (has_knowledge) "MPDAG" else "CPDAG",
    PAG = "PAG",
    `RFCI-PAG` = "RFCI-PAG",
    graph_class
  )
}

#' @title Verify the Semantic Graph Class of a Learned Graph
#'
#' @description
#' Constraint-based algorithms may output graphs that are not valid CPDAGs/MPDAGs due to statistical errors in
#' finite samples, violations of faithfulness, or latent confounding. This helper checks the claimed
#' semantic class against the actual graph and, when the claim does not hold, emits a message then downgrades
#' the reported class to:
#' `"PDAG"` if the graph is at least a valid PDAG, otherwise to `"UNKNOWN"`.
#'
#' @param cg A [caugi::caugi] object.
#' @param claimed The semantic class proposed by `.disco_graph_type()`.
#' @param has_knowledge Whether background knowledge was supplied.
#'
#' @returns The verified semantic class: `claimed` if valid, otherwise `"PDAG"`
#'   or `"UNKNOWN"`.
#' @keywords internal
#' @noRd
.validate_graph_type <- function(cg, claimed, has_knowledge) {
  if (!claimed %in% c("CPDAG", "MPDAG")) {
    return(claimed)
  }

  valid <- tryCatch(
    if (claimed == "CPDAG") caugi::is_cpdag(cg) else caugi::is_mpdag(cg),
    error = function(e) NA
  )
  if (isTRUE(valid)) {
    return(claimed)
  }

  is_valid_pdag <- tryCatch(caugi::is_pdag(cg), error = function(e) NA)
  fallback <- if (isTRUE(is_valid_pdag)) "PDAG" else "UNKNOWN"

  reason <- if (has_knowledge) {
    "the background knowledge conflicts with the structure learned from the data"
  } else {
    "of conflicting edge orientations, which can happen due to statistical errors in finite samples, violations of faithfulness, or latent confounding"
  }
  message(
    sprintf(
      paste0(
        "The learned graph is not a valid %s because %s; it is reported as ",
        "%s instead."
      ),
      claimed,
      reason,
      fallback
    )
  )
  fallback
}

.print_item_line <- function(label, items, max_items = 10L) {
  if (!length(items)) {
    return(invisible())
  }
  width <- getOption("width", 80L)
  prefix <- paste0("  ", label, ": ")
  pad <- strrep(" ", nchar(prefix))

  n_omitted <- max(0L, length(items) - max_items)
  shown <- if (n_omitted > 0L) items[seq_len(max_items)] else items
  if (n_omitted > 0L) {
    shown <- c(shown, sprintf("... and %d more", n_omitted))
  }

  lines <- character(0)
  cur <- prefix
  first <- TRUE

  for (item in shown) {
    chunk <- if (first) item else paste0(", ", item)
    if (!first && nchar(cur) + nchar(chunk) > width) {
      lines <- c(lines, cur)
      cur <- paste0(pad, item)
    } else {
      cur <- paste0(cur, chunk)
      first <- FALSE
    }
  }

  lines <- c(lines, cur)
  cat(paste(lines, collapse = "\n"), "\n", sep = "")
}

#' @title Summarize a Disco Object
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' `summary()` for `Disco` objects is deprecated. Use `print()` instead.
#'
#' @param object A `Disco` object.
#' @param ... Additional arguments (not used).
#' @exportS3Method summary Disco
summary.Disco <- function(object, ...) {
  lifecycle::deprecate_warn(
    when = "1.2.0",
    what = "summary()",
    with = "print()"
  )
  print(object, ...)
  invisible(object)
}

#' @export
set_knowledge.Disco <- function(method, knowledge) {
  if (!is_knowledge(knowledge)) {
    stop("The knowledge must be a Knowledge object.", call. = FALSE)
  }
  method$knowledge <- knowledge
  method
}

#' @title Extract Knowledge from a Disco Object
#'
#' @description
#' S3 method to extract the `Knowledge` object from a `Disco`.
#'
#' @param x A `Disco` object.
#'
#' @return The nested `Knowledge` object.
#'
#' @keywords internal
#' @noRd
knowledge.Disco <- function(x) {
  x$knowledge
}

#' @title Is it a `Disco`?
#'
#' @param x An object
#'
#' @returns `TRUE` if the object is of class `Disco`, `FALSE` otherwise.
#' @keywords internal
#' @noRd
is_disco <- function(x) {
  inherits(x, "Disco")
}


# delegate accessors so `Knowledge` verbs operate on the nested object

#' @export
`$.Disco` <- function(x, name) {
  ux <- unclass(x)
  if (name %in% names(ux)) {
    return(ux[[name]])
  }
  if (name %in% .knowledge_fields) {
    return(ux$knowledge[[name]])
  }
  NULL
}

#' @export
`$<-.Disco` <- function(x, name, value) {
  ux <- unclass(x)
  if (name %in% names(ux) && !(name %in% .knowledge_fields)) {
    ux[[name]] <- value
    x <- ux
  } else if (name %in% .knowledge_fields) {
    ux$knowledge[[name]] <- value
    x <- ux
  } else {
    ux[[name]] <- value
    x <- ux
  }
  class(x) <- "Disco"
  x
}

#' @export
`[[.Disco` <- function(x, name, ...) {
  ux <- unclass(x)
  if (is.character(name)) {
    if (name %in% names(ux)) {
      return(ux[[name]])
    }
    if (name %in% .knowledge_fields) {
      return(ux$knowledge[[name]])
    }
  }
  ux[[name, ...]]
}

#' @export
`[[<-.Disco` <- function(x, name, value) {
  ux <- unclass(x)
  if (is.character(name) && (name %in% .knowledge_fields)) {
    ux$knowledge[[name]] <- value
    x <- ux
  } else {
    ux[[name]] <- value
    x <- ux
  }
  class(x) <- "Disco"
  x
}
