# ────────────────────────────────── Add / Insert ─────────────────────────────────────
#' @title Add Variables to Knowledge
#'
#' @description Adds variables to the `Knowledge` object. If the object is
#' frozen, an error is thrown if any of the variables are not present in the
#' data frame provided to the object.
#'
#' @param kn A `Knowledge` object.
#' @param vars A character vector of variable names to add.
#'
#' @returns The updated `Knowledge` object.
#'
#' @example inst/roxygen-examples/knowledge_verbs-example.R
#'
#' @family knowledge helpers
#' @concept knowledge-helper
#'
#' @export
add_vars <- function(kn, vars) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "dplyr",
      "tibble"
    ),
    function_name = "add_vars"
  )

  is_knowledge(kn)

  missing <- setdiff(vars, kn$vars$var)

  if (kn$frozen && length(missing)) {
    stop(
      "Unknown variable(s): [",
      paste(missing, collapse = ", "),
      "]\nThey are not present in the data frame provided to this Knowledge object.",
      call. = FALSE
    )
  }

  if (length(missing)) {
    new_rows <- tibble::tibble(var = missing, tier = NA_character_)
    kn$vars <- dplyr::bind_rows(kn$vars, new_rows)
  }
  kn
}

#' @title Add a Tier to Knowledge
#'
#' @description
#' Adds a new tier to the `Knowledge` object, either at the start, end,
#' or before/after an existing tier.
#'
#' @param kn A `Knowledge` object.
#' @param tier Bare symbol / character (label) **or** numeric literal.
#' @param before,after  Optional anchor relative to an existing tier label,
#'  tier index, or variable.  Once the `Knowledge` object already
#'  has >= 1 tier, you must supply **exactly one** of these.
#'
#' @returns The updated `Knowledge` object.
#'
#' @example inst/roxygen-examples/knowledge_verbs-example.R
#'
#' @family knowledge helpers
#' @concept knowledge-helper
#'
#' @export
add_tier <- function(kn, tier, before = NULL, after = NULL) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "dplyr",
      "rlang",
      "tibble"
    ),
    function_name = "add_tier"
  )

  is_knowledge(kn)
  before_sup <- !missing(before)
  after_sup <- !missing(after)

  if (before_sup && after_sup) {
    stop("Cannot supply both `before` and `after`.", call. = FALSE)
  }

  # capture the new label
  tier_expr <- rlang::enexpr(tier)

  if (length(tier_expr) != 1L) {
    stop(
      "`tier` must be a single non-empty label or a non-negative numeric literal.",
      call. = FALSE
    )
  }
  tier_val <- tryCatch(
    rlang::eval_tidy(tier_expr, env = parent.frame()),
    error = function(e) NULL
  )

  if (!is.symbol(tier_expr)) {
    if (is.null(tier_expr) || is.na(tier_expr)) {
      stop(
        "`tier` must be a single non-empty label or a non-negative numeric literal.",
        call. = FALSE
      )
    }
  }

  if (is.character(tier_val) && length(tier_val) == 1L) {
    label <- tier_val
  } else if (is.numeric(tier_val) && length(tier_val) == 1L) {
    label <- as.character(tier_val)
  } else {
    label <- rlang::as_label(tier_expr)
  }

  if (length(label) != 1L || is.na(label) || !nzchar(label)) {
    stop("`tier` must be a non-empty label.", call. = FALSE)
  }

  # duplicate?
  if (label %in% kn$tiers$label) {
    stop(sprintf("Tier label `%s` already exists.", label), call. = FALSE)
  }

  tiers_exist <- nrow(kn$tiers) > 0L

  # no tiers yet
  if (!tiers_exist) {
    if (before_sup || after_sup) {
      stop(
        "`before`/`after` cannot be used when there are no existing tiers.",
        call. = FALSE
      )
    }
    kn$tiers <- dplyr::bind_rows(kn$tiers, tibble::tibble(label = label))
    return(kn)
  }

  # tiers exist

  # must supply exactly one of before/after
  if ((before_sup + after_sup) != 1L) {
    stop(
      "Once the Knowledge object already has tiers, supply exactly one of ",
      "`before` or `after`.",
      call. = FALSE
    )
  }

  # resolve anchor to a label string
  anchor_lbl <- if (before_sup) {
    as.character(rlang::enexpr(before))
  } else {
    as.character(rlang::enexpr(after))
  }

  pos <- match(anchor_lbl, kn$tiers$label)
  if (is.na(pos)) {
    stop(
      sprintf("`%s` does not refer to an existing tier.", anchor_lbl),
      call. = FALSE
    )
  }

  insert_at <- if (before_sup) pos else pos + 1L

  # build new tiers in three parts
  head_part <- dplyr::slice(kn$tiers, seq_len(insert_at - 1L))

  tail_part <- if (insert_at <= nrow(kn$tiers)) {
    dplyr::slice(kn$tiers, insert_at:nrow(kn$tiers))
  } else {
    kn$tiers[0, ] # empty tibble w/ same columns
  }

  kn$tiers <- dplyr::bind_rows(
    head_part,
    tibble::tibble(label = label),
    tail_part
  )
  kn
}

#' @title Add Variables to a Tier in Knowledge
#'
#' @param kn A `Knowledge` object.
#' @param ...  One or more two-sided formulas `tier ~ vars`.
#'
#' @returns The updated `Knowledge` object.
#'
#' @example inst/roxygen-examples/knowledge_verbs-example.R
#'
#' @family knowledge helpers
#' @concept knowledge-helper
#' @importFrom rlang .data
#' @export
add_to_tier <- function(kn, ...) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "dplyr",
      "rlang"
    ),
    function_name = "add_to_tier"
  )

  is_knowledge(kn)

  specs <- rlang::list2(...)
  if (!length(specs)) {
    stop("add_to_tier() needs at least one two-sided formula.")
  }

  for (fml in specs) {
    if (!rlang::is_formula(fml, lhs = TRUE)) {
      stop("Each argument must be a two-sided formula.")
    }

    lhs_expr <- rlang::f_lhs(fml)
    rhs_expr <- rlang::f_rhs(fml)
    tier_label <- as.character(lhs_expr)

    # tier must already exist
    if (!tier_label %in% kn$tiers$label) {
      stop(
        sprintf(
          "Tier `%s` does not exist. Create it first with add_tier().",
          tier_label
        ),
        call. = FALSE
      )
    }

    # resolve variables on the RHS
    vars <- .formula_vars(kn, rhs_expr)
    if (!length(vars)) {
      cli::cli_abort(
        "Specification `{paste(deparse(rhs_expr), collapse = '')}` matched no variables."
      )
    }

    # detect variables already assigned to a different tier
    current <- kn$vars$tier[match(vars, kn$vars$var)]
    clash <- !is.na(current) & current != tier_label
    if (any(clash)) {
      bad <- vars[clash]
      stop(
        sprintf(
          "Cannot reassign variable(s) [%s] to tier `%s` using add_to_tier().\n",
          paste(bad, collapse = ", "),
          tier_label
        ),
        call. = FALSE
      )
    }

    # register variables and attach the tier label
    kn <- add_vars(kn, vars)
    kn$vars$tier[match(vars, kn$vars$var)] <- tier_label
  }

  # update tier_from and tier_to in edges
  if (nrow(kn$edges)) {
    idx_from <- match(kn$edges$from, kn$vars$var)
    idx_to <- match(kn$edges$to, kn$vars$var)

    kn$edges$tier_from <- kn$vars$tier[idx_from]
    kn$edges$tier_to <- kn$vars$tier[idx_to]

    # check if we violate tier order
    .validate_tier_rule(kn$edges, kn$tiers)
  }

  # tidy variable table: order by tier rank, then name
  rank <- match(kn$vars$tier, kn$tiers$label)
  kn$vars <- dplyr::arrange(kn$vars, rank, .data$var)

  kn
}

#' Add Forbidden Edges to Knowledge
#'
#' @description
#' Forbid one or more directed edges.
#' Each argument **must** be a two–sided formula, e.g. `X ~ Y`.
#' Formulas can use tidy-select on either side, so
#' `forbid_edge(kn, starts_with("X") ~ Y)` forbids every `X_i --> Y`.
#'
#' @param kn  A `Knowledge` object.
#' @param ...  One or more two-sided formulas.
#'
#' @returns The updated `Knowledge` object.
#'
#' @example inst/roxygen-examples/knowledge_verbs-example.R
#'
#' @family knowledge helpers
#' @concept knowledge-helper
#'
#' @export
forbid_edge <- function(kn, ...) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "rlang"
    ),
    function_name = "forbid_edge"
  )

  dots <- rlang::enquos(...)
  if (!length(dots)) {
    stop("forbid_edge() needs at least one two-sided formula.", call. = FALSE)
  }

  for (formula in dots) {
    kn <- .edge_verb(kn, "forbidden", formula)
  }
  kn
}

#' Add Required Edges to Knowledge
#'
#' @description
#' Require one or more directed edges.
#' Arguments follow the same rules as **`forbid_edge()`** but a required edge
#' may only be given in *one* direction (`X ~ Y` **or** `Y ~ X`, not both).
#'
#' @inheritParams forbid_edge
#' @returns The updated `Knowledge` object.
#'
#' @example inst/roxygen-examples/knowledge_verbs-example.R
#'
#' @family knowledge helpers
#' @concept knowledge-helper
#'
#' @export
require_edge <- function(kn, ...) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "rlang"
    ),
    function_name = "require_edge"
  )

  dots <- rlang::enquos(...)
  if (!length(dots)) {
    stop("require_edge() needs at least one two-sided formula.", call. = FALSE)
  }

  for (formula in dots) {
    kn <- .edge_verb(kn, "required", formula)
  }
  kn
}

#' @title Add Exogenous Variables to Knowledge
#'
#' @description
#' Adds variables that cannot have incoming edges (exogenous nodes).
#' Every possible incoming edge to these nodes is automatically forbidden.
#' This is equivalent to writing `forbidden(everything() ~ vars)`.
#'
#' @param kn A `Knowledge` object.
#' @param vars Tidyselect specification or character vector of variables.
#'
#' @returns Updated `Knowledge` object.
#'
#' @example inst/roxygen-examples/knowledge_verbs-example.R
#'
#' @family knowledge helpers
#' @concept knowledge-helper
#'
#' @export
add_exogenous <- function(kn, vars) {
  is_knowledge(kn)
  kn <- forbid_edge(kn, everything() ~ {{ vars }})
  kn
}

#' @rdname add_exogenous
#' @export
add_exo <- add_exogenous

#' @title Unfreeze a Knowledge Object.
#'
#' @description This allows you to add new variables to the `Knowledge` object,
#' even though it was frozen earlier by adding a data frame to the knowledge
#' constructor `knowledge()`.
#'
#' @param kn A `Knowledge` object.
#' @returns The same `Knowledge` object with the `frozen` attribute set to
#' `FALSE`.
#'
#' @example inst/roxygen-examples/unfreeze-example.R
#'
#' @family knowledge helpers
#' @concept knowledge-helper
#'
#' @export
unfreeze <- function(kn) {
  is_knowledge(kn)
  kn$frozen <- FALSE
  kn
}

# ────────────────────────────────── Inspect ───────────────────────────────────
#' @title Get Tiers from Knowledge
#'
#' @description
#' Get tiers from a `Knowledge` object.
#'
#' @param kn A `Knowledge` object.
#'
#' @returns A tibble with the tiers.
#'
#' @example inst/roxygen-examples/get_tiers-example.R
#'
#' @family knowledge helpers
#' @concept knowledge-helper
#'
#' @export
get_tiers <- function(kn) {
  is_knowledge(kn)
  kn$tiers$label
}

# ───────────────────────────────── Remove / Delete ─────────────────────────────────────
#' @title Remove Variables from Knowledge
#'
#' @description
#' Drops the given variables from `kn$vars`, and automatically removes
#' any edges that mention them.
#'
#' @param kn A `Knowledge` object.
#' @param ... Unquoted variable names or tidy‐select helpers.
#'
#' @returns An updated `Knowledge` object.
#'
#' @example inst/roxygen-examples/remove_from_knowledge-example.R
#'
#' @family knowledge helpers
#' @concept knowledge-helper
#' @importFrom rlang .data
#' @export
remove_vars <- function(kn, ...) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "dplyr",
      "purrr",
      "rlang"
    ),
    function_name = "remove_vars"
  )

  is_knowledge(kn)
  specs <- rlang::enquos(..., .ignore_empty = "all")

  # resolve each quosure to a character vector of names
  vars_list <- purrr::map(specs, function(q) {
    .vars_from_spec(kn, rlang::get_expr(q))
  })
  vars <- unique(unlist(vars_list, use.names = FALSE))

  if (length(vars) == 0L) {
    stop("remove_vars() matched no variables.", call. = FALSE)
  }

  # drop them from the var table
  kn$vars <- dplyr::filter(kn$vars, !.data$var %in% vars)

  # drop any edges that mention them
  kn$edges <- dplyr::filter(
    kn$edges,
    !.data$from %in% vars,
    !.data$to %in% vars
  )

  kn
}
# ────────────────────────────────── Edge rules ───────────────────────────────
#' @title Remove an Edge from Knowledge
#' @description
#' Drop a single directed edge specified by `from` and `to`.
#' Errors if the edge does not exist.
#'
#' @param kn   A `Knowledge` object.
#' @param from  The source node (unquoted or character).
#' @param to    The target node (unquoted or character).
#'
#' @returns The updated `Knowledge` object.
#'
#' @example inst/roxygen-examples/remove_from_knowledge-example.R
#'
#' @family knowledge helpers
#' @concept knowledge-helper
#'
#' @export
remove_edge <- function(kn, from, to) {
  .check_if_pkgs_are_installed(
    pkgs = c("dplyr", "rlang", "tibble"),
    function_name = "remove_edge"
  )

  is_knowledge(kn)

  # capture as strings if unquoted
  from <- rlang::as_name(rlang::enquo(from))
  to <- rlang::as_name(rlang::enquo(to))

  # build tibble of edge to drop
  drop_tbl <- tibble::tibble(from = from, to = to)

  # check if the edge exists
  matched <- dplyr::inner_join(
    drop_tbl,
    dplyr::select(kn$edges, from, to),
    by = c("from", "to")
  )

  if (nrow(matched) == 0L) {
    stop(
      sprintf("Edge from '%s' to '%s' does not exist.", from, to),
      call. = FALSE
    )
  }

  # drop the edge
  kn$edges <- dplyr::anti_join(kn$edges, drop_tbl, by = c("from", "to"))
  kn
}

#' @title Remove Tiers from Knowledge
#'
#' @description
#' Drops tier definitions (and un‐tiers any vars assigned to them).
#'
#' @param kn   A `Knowledge` object.
#' @param ...   Tier labels (unquoted or character) or numeric indices.
#'
#' @returns An updated `Knowledge` object.
#'
#' @example inst/roxygen-examples/remove_from_knowledge-example.R
#'
#' @family knowledge helpers
#' @concept knowledge-helper
#' @importFrom rlang .data
#' @export
remove_tiers <- function(kn, ...) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "dplyr",
      "purrr",
      "rlang"
    ),
    function_name = "remove_tiers"
  )

  is_knowledge(kn)
  specs <- rlang::enquos(..., .ignore_empty = "all")
  keep <- kn$tiers$label
  to_drop <- purrr::map_chr(specs, function(q) {
    val <- rlang::eval_tidy(q, kn$tiers, env = parent.frame())
    if (is.numeric(val)) {
      return(kn$tiers$label[val])
    }
    as.character(val)
  })

  to_drop <- intersect(to_drop, keep)
  if (!length(to_drop)) {
    return(kn)
  }

  # drop the tier rows
  kn$tiers <- dplyr::filter(kn$tiers, !.data$label %in% to_drop)

  # reset any vars that were in those tiers
  kn$vars$tier[kn$vars$tier %in% to_drop] <- NA_character_

  kn
}

#' @title Forbid Tier Violations in Knowledge
#'
#' @description
#' Given a `Knowledge` object with variables already assigned to tiers,
#' forbids every directed edge that runs from a higher-numbered tier down
#' into a lower-numbered tier.
#'
#' @param kn A `Knowledge` object.
#' @returns The same `Knowledge` object with new forbidden edges added.
#'
#' @example inst/roxygen-examples/forbid_tier_violations-example.R
#'
#' @family knowledge helpers
#' @concept knowledge-helper
#' @importFrom rlang .data
#' @keywords internal
#' @noRd
forbid_tier_violations <- function(kn) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "dplyr",
      "rlang",
      "tibble",
      "tidyr"
    ),
    function_name = "forbid_tier_violations"
  )

  is_knowledge(kn)

  # build a named vector of tier rank
  tier_ranks <- rlang::set_names(
    seq_along(kn$tiers$label),
    kn$tiers$label
  )

  # annotate each var with its numeric rank
  vars <- kn$vars |>
    dplyr::mutate(rank = tier_ranks[tier])

  # select & rename for "from" vs "to"
  vf <- vars |> dplyr::select(var_from = "var", rank_from = rank)
  vt <- vars |> dplyr::select(var_to = "var", rank_to = rank)

  # true cartesian crossing of those two tibbles
  bad <- tidyr::crossing(vf, vt) |>
    dplyr::filter(.data$rank_from > .data$rank_to)

  # add all those forbidden edges, dropping self-loops
  if (nrow(bad)) {
    new_edges <- tibble::tibble(
      status = "forbidden",
      from = bad$var_from,
      to = bad$var_to,
      tier_from = kn$vars$tier[match(bad$var_from, kn$vars$var)],
      tier_to = kn$vars$tier[match(bad$var_to, kn$vars$var)]
    )

    # bind to existing, drop duplicates
    kn$edges <- dplyr::distinct(
      dplyr::bind_rows(kn$edges, new_edges)
    )
  }
  kn
}

#' @title Convert Tiered Knowledge to Forbidden Knowledge
#' @description Converts tier assignments into forbidden edges, and drops tiers in the output.
#' @param kn A `Knowledge` object.
#' @returns A `Knowledge` object with forbidden edges added, tiers removed.
#'
#' @examples
#' kn <- knowledge(
#'  tpc_example,
#'  tier(
#'   child ~ starts_with("child"),
#'   youth ~ starts_with("youth"),
#'   old ~ starts_with("old")
#'  )
#' )
#' kn_converted <- convert_tiers_to_forbidden(kn)
#' print(kn_converted)
#' plot(kn_converted)
#'
#' @family knowledge helpers
#' @concept knowledge-helper
#' @export
convert_tiers_to_forbidden <- function(kn) {
  kn <- forbid_tier_violations(kn)

  # drop tiers in the returned object
  kn$tiers <- tibble::tibble(label = character(0))
  kn$vars <- kn$vars |> dplyr::mutate(tier = NA_character_)

  # set tier info in edges to NA
  if ("tier_from" %in% names(kn$edges)) {
    kn$edges$tier_from <- NA_character_
  }
  if ("tier_to" %in% names(kn$edges)) {
    kn$edges$tier_to <- NA_character_
  }

  kn
}

# ────────────────────────────────── Tier helpers ─────────────────────────────
#' @title Generate a Bundle of Tier–Variable Formulas
#'
#' @description
#' Quickly create a series of two‐sided formulas for use with \code{tier()},
#' where each formula maps a numeric tier index to a tidyselect specification
#' that contains the placeholder \code{i}.  The placeholder \code{i} is replaced
#' by each element of \code{tiers} in turn, allowing you to write a single
#' template rather than many nearly identical formulas.
#'
#' @param tiers
#'   An integer vector of tier indices (each >= 1). These will appear as the
#'   left‐hand sides of the generated formulas.
#'
#' @param vars
#'   A tidyselect specification (unevaluated) that *must* contain the special
#'   placeholder \code{i}, either as the symbol \code{i} or inside a string
#'   like \code{"…{i}…"}.  For each value of \code{i} in \code{tiers}, that
#'   placeholder will be substituted and the resulting call used as the
#'   right‐hand side of a formula.
#'
#' @returns
#'   A list of two‐sided formulas, each of class \code{"tier_bundle"}.
#'   You can pass this list directly to \code{tier()} (which will expand it
#'   automatically).
#'
#' @example inst/roxygen-examples/seq_tiers-example.R
#'
#' @family knowledge helpers
#' @concept knowledge-helper
#'
#' @export
seq_tiers <- function(tiers, vars) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "rlang"
    ),
    function_name = "seq_tiers"
  )

  checkmate::assert_integerish(tiers, lower = 1)

  vars_expr <- rlang::enexpr(vars)

  # guard: placeholder must be present
  if (
    !rlang::is_call(vars_expr) &&
      !identical(vars_expr, quote(i)) &&
      !grepl("{i}", deparse(vars_expr), fixed = TRUE)
  ) {
    stop("`vars` must contain the placeholder `i`.", call. = FALSE)
  }

  # recursively substitute `i` or "{i}" helper
  replace_i <- function(expr, i_chr) {
    switch(
      typeof(expr),
      "language" = as.call(lapply(as.list(expr), replace_i, i_chr)),
      "symbol" = if (identical(expr, quote(i))) rlang::expr(!!i_chr) else expr,
      "character" = rlang::expr(!!gsub("{i}", i_chr, expr, fixed = TRUE)),
      expr
    )
  }

  # build formulas helper
  build_formula <- function(i) {
    rhs <- replace_i(vars_expr, as.character(i))
    rlang::new_formula(i, rhs, env = rlang::empty_env())
  }
  # create the formulas
  structure(lapply(tiers, build_formula), class = "tier_bundle")
}
