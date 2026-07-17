# ──────────────────────────────────────────────────────────────────────────────
# ─────────────────────────── Internal helpers  ────────────────────────────────
# ──────────────────────────────────────────────────────────────────────────────

# ────────────────────────────── New knowledge  ────────────────────────────────
#' @title Create a `Knowledge` object
#'
#' @param vars Character vector of variable names.  Defaults to empty.
#' @param frozen Logical. If `TRUE`, no new variables can be added. Defaults to `FALSE`.
#'
#' @returns An S3 object of class `"Knowledge"`.
#'
#' @example inst/roxygen-examples/dot-new_knowledge-example.R
#' @noRd
#' @keywords internal
.new_knowledge <- function(vars = character(), frozen = FALSE) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "tibble"
    ),
    function_name = ".new_knowledge"
  )

  stopifnot(is.character(vars), !anyDuplicated(vars))

  structure(
    list(
      vars = tibble::tibble(var = vars, tier = NA_character_),
      tiers = tibble::tibble(label = character()),
      edges = tibble::tibble(
        status = character(),
        from = character(),
        to = character(),
        tier_from = character(),
        tier_to = character()
      ),
      frozen = frozen
    ),
    class = "Knowledge"
  )
}

# ─────────────────────────── Validation helpers  ──────────────────────────────
#' @title Validate that no edge runs from higher tier to lower tier
#'
#' @param edges_df A data frame with columns `status`, `from`,
#' `to`, `tier_from`, and `tier_to`.
#' @param tiers A data frame with a column `label` listing tier labels
#'
#' @example inst/roxygen-examples/dot-validate_tier_rule-example.R
#' @importFrom rlang .data
#' @noRd
#' @keywords internal
.validate_tier_rule <- function(edges_df, tiers) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "dplyr"
    ),
    function_name = ".validate_tier_rule"
  )

  rank <- function(lbl) match(lbl, tiers$label)

  bad <- dplyr::filter(
    edges_df,
    !is.na(.data$tier_from),
    !is.na(.data$tier_to),
    .data$status != "forbidden",
    rank(.data$tier_from) > rank(.data$tier_to)
  )
  if (nrow(bad)) {
    stop(
      "Edge(s) violate tier ordering: ",
      paste(bad$from, "-->", bad$to, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

#' @title Detect inconsistent edge declarations
#'
#' @description Throws an error if any edges are declared as both
#' `forbidden` and `required`, or if a required edge is declared in both
#' directions.
#'
#' @param edges_df Data frame with columns `status`, `from`, `to`,
#'   `tier_from`, and `tier_to`.
#'
#' @example inst/roxygen-examples/dot-validate_forbidden_required-example.R
#' @importFrom rlang .data
#' @noRd
#' @keywords internal
.validate_forbidden_required <- function(edges_df) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "dplyr"
    ),
    function_name = ".validate_forbidden_required"
  )

  # same ordered edge both forbidden and required
  clash_fr <- edges_df |>
    dplyr::group_by(.data$from, .data$to) |>
    dplyr::filter(all(c("forbidden", "required") %in% .data$status)) |>
    dplyr::ungroup() |>
    dplyr::distinct(.data$from, .data$to)

  if (nrow(clash_fr)) {
    stop(
      "Edge(s) appear as both forbidden and required: ",
      paste0(clash_fr$from, " --> ", clash_fr$to, collapse = ", "),
      call. = FALSE
    )
  }

  # required edge in both directions
  req <- dplyr::filter(edges_df, .data$status == "required")

  if (nrow(req) > 1) {
    # normalise each pair to an unordered signature "A||B"
    sig <- paste(pmin(req$from, req$to), pmax(req$from, req$to), sep = "||")
    dup <- sig[duplicated(sig)]

    if (length(dup)) {
      offending <- unique(dup)
      pretty <- gsub("\\|\\|", " <-> ", offending) # A <-> B
      stop(
        "Edge(s) required in both directions: ",
        paste(pretty, collapse = ", "),
        call. = FALSE
      )
    }
  }

  # no problems
  invisible(TRUE)
}

# ───────────────────────────── Edge helpers  ──────────────────────────────────
#' @title Add Edges to a Knowledge Object
#'
#' @param kn A `Knowledge` object.
#' @param status A string, either "forbidden" or "required".
#' @param from A tidyselect specification or character vector of variable names.
#' @param to A tidyselect specification or character vector of variable names.
#' @param remove_self_loops Logical. If `TRUE`, self-loops are removed.
#' Defaults to `FALSE`.
#'
#' @returns The updated `Knowledge` object.
#'
#' @example inst/roxygen-examples/dot-add_edges-example.R
#' @noRd
#' @keywords internal
.add_edges <- function(kn, status, from, to, remove_self_loops = TRUE) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "dplyr",
      "tidyr"
    ),
    function_name = ".add_edges"
  )

  # resolve `from` / `to` specs into character vectors of variable names
  from_chr <- .vars_from_spec(kn, {{ from }})
  to_chr <- .vars_from_spec(kn, {{ to }})

  # ensure all endpoint variables exist in `kn$vars`
  kn <- add_vars(kn, unique(c(from_chr, to_chr)))

  # cartesian product
  # one row per directed edge, then annotate
  block <- tidyr::crossing(from = from_chr, to = to_chr) |>
    dplyr::mutate(
      status = status,
      tier_from = kn$vars$tier[match(from, kn$vars$var)],
      tier_to = kn$vars$tier[match(to, kn$vars$var)]
    )

  # stop if any new edge violates the tier rule
  .validate_tier_rule(block, kn$tiers)

  # stop if any new edge violates the forbidden/required rule
  .validate_forbidden_required(block)

  # merge into edge table, dropping duplicates, and return updated object
  kn$edges <- dplyr::distinct(dplyr::bind_rows(kn$edges, block))

  if (remove_self_loops) {
    kn$edges <- dplyr::filter(kn$edges, from != to)
  }

  # validate again for safety
  .validate_forbidden_required(kn$edges)
  # required edges must not form a directed cycle: no DAG could satisfy them
  .validate_no_required_cycle(kn$edges)
  kn
}

#' @title Reject Required Edges That Form a Directed Cycle
#'
#' @description
#' Required edges are directed constraints, so a directed cycle among them
#' (e.g. `A %-->% B`, `B %-->% C`, `C %-->% A`) cannot be satisfied by any DAG.
#' This helper detects such cycles and errors. Forbidden edges impose no
#' orientation and are ignored.
#'
#' @param edges The `edges` tibble of a `Knowledge` object.
#' @returns Invisibly `NULL`; called for its side effect of erroring on a cycle.
#' @keywords internal
#' @noRd
.validate_no_required_cycle <- function(edges) {
  req <- edges[
    !is.na(edges$status) & edges$status == "required",
    ,
    drop = FALSE
  ]
  if (nrow(req) == 0L) {
    return(invisible(NULL))
  }

  acyclic <- tryCatch(
    caugi::is_acyclic(
      caugi::caugi(
        from = req$from,
        edge = rep("-->", nrow(req)),
        to = req$to,
        class = "UNKNOWN"
      )
    ),
    error = function(e) FALSE
  )

  if (!isTRUE(acyclic)) {
    stop(
      "Required edges form a directed cycle, so no DAG can satisfy them. ",
      "Remove or redirect the conflicting required edge(s).",
      call. = FALSE
    )
  }
  invisible(NULL)
}

#' @title Handle forbid_edge() / require_edge() calls
#'
#' @description
#' Internal helper that turns each **two-sided formula** supplied by
#' `forbid_edge()` or `require_edge()` into concrete variable names, then passes
#' the cross-product to `.add_edges()`.
#'
#' @param kn A `Knowledge` object.
#' @param status Either `"forbidden"` or `"required"`.
#' @param fml A quosure that must wrap a two-sided formula.
#'
#' @example inst/roxygen-examples/dot-edge_verb-example.R
#' @noRd
#' @keywords internal
.edge_verb <- function(kn, status, fml) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "rlang"
    ),
    function_name = ".edge_verb"
  )

  if (!(status %in% c("required", "forbidden"))) {
    stop(
      "`status` (edge type) must be 'required' or 'forbidden' for ",
      "knowledge edge generation.",
      call. = FALSE
    )
  }

  if (!rlang::quo_is_call(fml, "~")) {
    stop(
      "Edge specification must be a two-sided formula like `A ~ B`.",
      call. = FALSE
    )
  }

  expr <- rlang::get_expr(fml)

  from_vars <- .formula_vars(kn, rlang::f_lhs(expr))
  to_vars <- .formula_vars(kn, rlang::f_rhs(expr))

  if (!length(from_vars) || !length(to_vars)) {
    stop(
      sprintf("Formula `%s` matched no variables.", deparse(expr)),
      call. = FALSE
    )
  }
  kn <- .add_edges(kn, status, from_vars, to_vars)
  kn
}

# ───────────────────────────── Misc helpers  ──────────────────────────────────
#' @title Resolve a tidy-select or character spec to character names
#'
#' @param kn A `Knowledge` object.
#' @param spec A tidyselect specification (e.g. `everything()`,
#' `starts_with("V")`) or a character vector.
#' @keywords internal
#' @title Resolve a tidy-select or character spec to character names
#'
#' @param kn A `Knowledge` object.
#' @param spec An unevaluated variable specification. May be:
#'   - a tidyselect helper (e.g. `everything()`, `starts_with("V")`)
#'   - a bare symbol naming a variable
#'   - a character vector of variable names
#'   - a literal `c(V1, V2, "V3")` call
#'   - a binary `+` expression combining any of the above (interpreted as union)
#'
#'   Specifications are resolved recursively.
#'
#' @example inst/roxygen-examples/dot-vars_from_spec-example.R
#' @noRd
#' @keywords internal
.vars_from_spec <- function(kn, spec) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "dplyr",
      "purrr",
      "rlang",
      "tidyselect"
    ),
    function_name = ".vars_from_spec"
  )
  if (is.atomic(spec) && length(spec) == 1L && !is.character(spec)) {
    return(character(0))
  }

  if (rlang::is_call(spec, "+")) {
    lhs <- .vars_from_spec(kn, spec[[2]])
    rhs <- .vars_from_spec(kn, spec[[3]])
    if (!length(lhs) && rlang::is_symbol(spec[[2]])) {
      lhs <- rlang::as_string(spec[[2]])
    }
    if (!length(rhs) && rlang::is_symbol(spec[[3]])) {
      rhs <- rlang::as_string(spec[[3]])
    }
    return(unique(c(lhs, rhs)))
  }

  # literal c(...) of names --> turn into a plain character vector
  if (rlang::is_call(spec, "c")) {
    args <- as.list(spec)[-1]
    out <- purrr::map_chr(args, function(arg) {
      # if they wrote c(V4), arg is a symbol
      if (rlang::is_symbol(arg)) {
        return(rlang::as_string(arg))
      }
      # if they wrote c("V4"), arg is a literal string
      if (is.character(arg) && length(arg) == 1L) {
        return(arg)
      }
      stop(
        "Unsupported argument in c(): ",
        deparse(arg),
        call. = FALSE
      )
    })
    return(out)
  }

  # bare symbol --> maybe a user-supplied character, or a var name
  if (rlang::is_symbol(spec)) {
    out <- tryCatch(
      rlang::eval_tidy(spec, env = parent.frame()),
      error = function(e) NULL
    )
    if (is.character(out)) {
      return(out)
    }
    nm <- rlang::as_string(spec)
    if (nm %in% kn$vars$var) {
      return(nm)
    }
    return(character(0))
  }

  # character vector --> wrap in all_of() so external names match strictly.
  # Any other expression is a tidy-select expression that eval_select() can
  # evaluate directly, which preserves set operations such as `!`, `&`, `|`,
  # and `-`.
  if (is.character(spec)) {
    q <- rlang::quo(dplyr::all_of(!!spec))
  } else {
    q <- rlang::as_quosure(spec, env = parent.frame())
  }

  # fall back to tidyselect
  vars <- tryCatch(
    names(tidyselect::eval_select(
      q,
      rlang::set_names(seq_along(kn$vars$var), kn$vars$var)
    )),
    error = function(e) character(0)
  )
  if (length(vars)) {
    return(vars)
  }

  # final fallback: evaluate as plain R
  out2 <- tryCatch(
    rlang::eval_tidy(spec, env = parent.frame()),
    error = function(e) NULL
  )
  if (is.character(out2)) {
    return(out2)
  }

  # nothing matched
  character(0)
}


#' @title Extract variable names from the RHS of a `tier()` formula
#'
#' @param kn A `Knowledge` object.
#' @param rhs A formula (e.g. `1 ~ V1 + V2`).
#'
#' @example inst/roxygen-examples/dot-formula_vars-example.R
#' @noRd
#' @keywords internal
.formula_vars <- function(kn, rhs) {
  vars <- .vars_from_spec(kn, rhs)
  if (length(vars)) {
    return(vars)
  } # tidy-select succeeded
  unique(all.vars(rhs)) # fallback to plain symbols
}
