# ──────────────────────────────────────────────────────────────────────────────
# ───────────── Conversion to External Engines: Tetrad, pcalg, bnlearn ─────────
# ──────────────────────────────────────────────────────────────────────────────

#' @title Convert Knowledge to Tetrad Knowledge
#'
#' @description
#' Converts a `Knowledge` object to a Tetrad `edu.cmu.tetrad.data.Knowledge`.
#' This requires `rJava`. This is used internally, when setting knowledge with
#' [set_knowledge()] for methods using the Tetrad engine. [set_knowledge()] is used
#' internally, when using the [disco()] function with knowledge given.
#' @param kn A `Knowledge` object.
#'
#' @returns A Java `edu.cmu.tetrad.data.Knowledge` object.
#'
#' @example inst/roxygen-examples/as_tetrad_knowledge-example.R
#'
#' @family knowledge functions
#' @concept knowledge
#'
#' @export
as_tetrad_knowledge <- function(kn) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "purrr",
      "rJava"
    ),
    function_name = "as_tetrad_knowledge"
  )

  is_knowledge(kn)
  # nocov start
  if (!rJava::.jniInitialized) {
    init_java()
  } # nocov end

  j <- rJava::.jnew("edu/cmu/tetrad/data/Knowledge")

  # attach every variable that has a tier label
  purrr::pwalk(
    list(kn$vars$var, kn$vars$tier),
    function(v, t) {
      if (!is.na(t)) {
        idx <- match(t, kn$tiers$label) # row position = tier rank
        j$addToTier(as.integer(idx), v)
      }
    }
  )

  # transfer forbidden / required edges
  purrr::pwalk(
    kn$edges,
    function(status, from, to, ...) {
      switch(
        status,
        forbidden = j$setForbidden(from, to),
        required = j$setRequired(from, to)
      )
    }
  )

  j
}

#' Convert Knowledge to pcalg Knowledge
#'
#' \pkg{pcalg} only supports _undirected_ (symmetric) background constraints:
#' * **fixed_gaps** - forbidding edges (zeros enforced)
#'
#' This function takes a `Knowledge` object (with only forbidden edges, no
#' tiers) and returns the logical constraint matrix in the exact variable
#' order you supply.
#'
#' Required edges in a `Knowledge` object are directed statements. \pkg{pcalg}
#' constraints are adjacency-level only, so a required edge cannot be honored;
#' any required edges are dropped with a warning.
#'
#' @param kn A `Knowledge` object.  Must have no tier information.
#' @param labels Character vector of all variable names, in the exact order
#'   of your data columns.  Every variable referenced by an edge in \code{kn}
#'   must appear here.
#' @param directed_as_undirected `r lifecycle::badge("deprecated")` This
#'   argument no longer has any effect and will be removed in a future
#'   release. Specify directed edges in both directions in [knowledge()]
#'   instead.
#'
#' @returns A list with one element, `fixed_gaps`: an \code{n × n} logical
#' matrix corresponding to the \pkg{pcalg} `fixedGaps` argument.
#'
#' @section Errors:
#' * If the `Knowledge` object contains tiered knowledge.
#' * If any forbidden edge lacks its symmetrical counterpart.
#'
#' @example inst/roxygen-examples/as_pcalg_constraints-example.R
#'
#' @family knowledge functions
#' @concept knowledge
#' @importFrom rlang .data
#' @export
as_pcalg_constraints <- function(
  kn,
  labels = kn$vars$var,
  directed_as_undirected = lifecycle::deprecated()
) {
  if (lifecycle::is_present(directed_as_undirected)) {
    lifecycle::deprecate_warn(
      when = "1.2.0",
      what = "as_pcalg_constraints(directed_as_undirected)",
      details = paste0(
        "The argument is ignored. Specify directed edges in both ",
        "directions in knowledge() instead."
      )
    )
  }
  .check_if_pkgs_are_installed(
    pkgs = c(
      "dplyr",
      "pcalg",
      "rlang"
    ),
    function_name = "as_pcalg_constraints"
  )

  is_knowledge(kn)

  if (!all(is.na(kn$vars$tier))) {
    stop(
      "Tiered background knowledge cannot be utilised by the pcalg engine.\n",
      "pcalg does not support directed tier constraints."
    )
  }
  if (!is.character(labels) || length(labels) == 0L) {
    stop("`labels` must be a non-empty character vector.", call. = FALSE)
  }
  if (length(labels) != length(unique(labels))) {
    stop("`labels` must be unique.", call. = FALSE)
  }
  # check that labels and `Knowledge` object are aligned
  if (!setequal(labels, kn$vars$var)) {
    # all labels that aren't in knowledge
    bad_vars <- setdiff(labels, kn$vars$var)
    if (length(bad_vars)) {
      stop(
        "`labels` contained variables that were not in the Knowledge object: [",
        paste(bad_vars, collapse = ", "),
        "]",
        call. = FALSE
      )
    }
    # all vars that aren't in labels
    missing_vars <- setdiff(kn$vars$var, labels)
    if (length(missing_vars)) {
      stop(
        "`labels` must contain all variables in the knowledge",
        " object. The following is missing: [",
        paste(missing_vars, collapse = ", "),
        "]\nYou can add variables to your Knowledge object with add_vars().",
        call. = FALSE
      )
    } else {
      # nocov start
      # this is a future-proofing security measure, not reachable as of now
      stop(
        "`labels` must contain all variables in the Knowledge object.",
        call. = FALSE
      )
    }
    # nocov end
  }

  p <- length(labels)
  fixed_gaps <- matrix(FALSE, p, p, dimnames = list(labels, labels))
  idx <- rlang::set_names(seq_along(labels), labels)

  # pcalg constraints are adjacency-level only; a directed required edge
  # cannot be honored, so drop required edges with a warning
  req <- kn$edges$status == "required"
  if (any(req)) {
    warning(
      "pcalg constraints cannot represent required edges; ignoring them.",
      call. = FALSE
    )
    kn$edges <- kn$edges[!req, , drop = FALSE]
  }

  bad <- kn$edges |>
    dplyr::anti_join(kn$edges, by = c("from" = "to", "to" = "from")) |>
    dplyr::mutate(desc = paste0(.data$from, " --> ", .data$to)) |>
    dplyr::pull(.data$desc)
  if (length(bad)) {
    stop(
      "pcalg does not support asymmetric edges.\n",
      "The following have no symmetrical counterpart:\n  * ",
      paste(bad, collapse = "\n  * "),
      call. = FALSE
    )
  }

  # fill forbidden
  forb <- dplyr::filter(kn$edges, .data$status == "forbidden")
  for (k in seq_len(nrow(forb))) {
    i <- match(forb$from[k], labels, nomatch = NA_integer_)
    j <- match(forb$to[k], labels, nomatch = NA_integer_)
    # extra security measure
    if (is.na(i) || is.na(j)) {
      stop("Forbidden edge refers to unknown variable(s).", call. = FALSE)
    }
    fixed_gaps[i, j] <- TRUE
  }

  list(fixed_gaps = fixed_gaps)
}

#' Convert Knowledge to bnlearn Knowledge
#'
#' @description
#' Converts a `Knowledge` object to a list of two data frames, namely
#' `whitelist` and `blacklist`, which can be used as arguments for
#' \pkg{bnlearn} algorithms. The `whitelist` contains all required edges, and the
#' `blacklist` contains all forbidden edges. Tiers will be made into forbidden
#' edges before running the conversion.
#'
#' @param kn A `Knowledge` object.  Must have no tier information.
#'
#' @returns A list with two elements, `whitelist` and `blacklist`, each a data
#' frame containing the edges in a `from`, `to` format.
#'
#' @example inst/roxygen-examples/as_bnlearn_knowledge-example.R
#'
#' @family knowledge functions
#' @concept knowledge
#' @importFrom rlang .data
#' @export
as_bnlearn_knowledge <- function(kn) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "dplyr"
    ),
    function_name = "as_bnlearn_knowledge"
  )

  is_knowledge(kn)

  # whitelist holds all required edges in a "from", "to" data frame
  whitelist <- dplyr::filter(kn$edges, .data$status == "required") |>
    dplyr::select("from", "to") |>
    as.data.frame()

  # blacklist holds all forbidden edges (including tier violations)
  blacklist <- forbid_tier_violations(kn)$edges |>
    dplyr::filter(.data$status == "forbidden") |>
    dplyr::select("from", "to") |>
    as.data.frame()

  list(
    whitelist = whitelist,
    blacklist = blacklist
  )
}


#' Convert Knowledge to Caugi
#'
#' @description
#' Converts a `Knowledge` object to a [caugi::caugi] object used for plotting.
#'
#' @param kn A `Knowledge` object.
#'
#' @returns A list with the [caugi::caugi] object alongside information about the knowledge (tiers, required and
#' forbidden edges) that can be used for plotting.
#'
#' @examples
#' data(tpc_example)
#' kn <- knowledge(
#'   tpc_example,
#'   tier(
#'     child ~ starts_with("child"),
#'     youth ~ starts_with("youth"),
#'     old ~ starts_with("old")
#'   ),
#'   child_x1 %-->% youth_x3,
#'   child_x2 %!-->% youth_x3
#' )
#' cg <- knowledge_to_caugi(kn)
#'
#' @family knowledge functions
#' @concept knowledge
#'
#' @export
knowledge_to_caugi <- function(kn) {
  .check_if_pkgs_are_installed(
    pkgs = c("dplyr", "caugi"),
    function_name = "knowledge_to_caugi"
  )
  is_knowledge(kn)

  ## ---- build caugi(vars...) ----
  caugi_call <- as.call(
    c(
      list(quote(caugi::caugi)),
      lapply(kn$vars$var, as.name),
      list(
        class = "UNKNOWN",
        simple = FALSE
      )
    )
  )

  ## ---- build edge calls ----
  edges <- kn$edges[kn$edges$status %in% c("required", "forbidden"), ]

  if (nrow(edges) == 0) {
    cg <- eval(caugi_call, envir = parent.frame())
  } else {
    edge_calls <- lapply(seq_len(nrow(edges)), function(i) {
      as.call(list(
        as.name("%-->%"),
        as.name(edges$from[i]),
        as.name(edges$to[i])
      ))
    })

    full_call <- as.call(
      c(list(quote(caugi::add_edges), caugi_call), edge_calls)
    )

    cg <- eval(full_call, envir = parent.frame())
  }

  ## ---- build tiers list ----
  if (all(is.na(kn$vars$tier))) {
    tiers <- list()
  } else {
    tier_levels <- unique(stats::na.omit(kn$vars$tier))
    tiers <- lapply(tier_levels, function(t) kn$vars$var[kn$vars$tier == t])
    names(tiers) <- tier_levels
  }

  ## ---- extract required and forbidden edges ----
  required_edges <- forbidden_edges <- NULL
  if (nrow(edges) > 0) {
    edges_split <- split(edges[, c("from", "to")], edges$status)

    required_edges <- edges_split[["required"]]
    forbidden_edges <- edges_split[["forbidden"]]
  }

  ## ---- return list ----
  list(
    caugi = cg,
    tiers = tiers,
    required_edges = required_edges,
    forbidden_edges = forbidden_edges
  )
}

#' Combine Knowledge and caugi object
#' @param cg A [caugi::caugi] object.
#' @param kn A `Knowledge` object.
#' @returns A list with the updated [caugi::caugi] object alongside information.
#' @keywords internal
#' @noRd
combine_knowledge_and_caugi <- function(cg, kn) {
  .check_if_pkgs_are_installed(
    pkgs = c("dplyr", "caugi"),
    function_name = "combine_knowledge_and_caugi"
  )

  # Only keep required for now (need to figure out what to do with forbidden edges)
  edges <- kn$edges[kn$edges$status %in% c("required"), ]

  if (nrow(edges) == 0) {
    combined_cg <- cg
  } else {
    existing_edges <- cg@edges[, c("from", "to")]

    # Keep only edges that do NOT already exist
    edges_to_add <- edges[
      !with(edges, paste(from, to)) %in%
        with(existing_edges, paste(from, to)),
    ]

    if (nrow(edges_to_add) == 0) {
      combined_cg <- cg
    } else {
      # Convert to edge calls: from %-->% to
      edge_calls <- lapply(seq_len(nrow(edges_to_add)), function(i) {
        as.call(list(
          as.name("%-->%"),
          as.name(edges_to_add$from[i]),
          as.name(edges_to_add$to[i])
        ))
      })

      # Combine with existing caugi
      full_call <- as.call(c(list(quote(caugi::add_edges), cg), edge_calls))
      combined_cg <- eval(full_call, envir = parent.frame())
    }
  }

  # Build tiers from `Knowledge` object
  if (all(is.na(kn$vars$tier))) {
    tiers <- list()
  } else {
    tier_levels <- unique(stats::na.omit(kn$vars$tier))
    tiers <- lapply(tier_levels, function(t) kn$vars$var[kn$vars$tier == t])
    names(tiers) <- tier_levels
  }

  list(
    caugi = combined_cg,
    tiers = tiers
  )
}
