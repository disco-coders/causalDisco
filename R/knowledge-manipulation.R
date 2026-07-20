# ────────────────────────────── Manipulation ──────────────────────────────────
#' @title Merge Knowledge Objects
#' @param kn1 A `Knowledge` object.
#' @param kn2 Another `Knowledge` object.
#'
#' @example inst/roxygen-examples/plus-knowledge-example.R
#'
#' @family knowledge helpers
#' @concept knowledge-helper
#' @importFrom rlang .data
#' @exportS3Method "+" Knowledge
`+.Knowledge` <- function(kn1, kn2) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "dplyr",
      "tibble"
    ),
    function_name = "+.Knowledge"
  )

  is_knowledge(kn1)
  is_knowledge(kn2)

  # combine
  vars_all <- unique(c(kn1$vars$var, kn2$vars$var))
  out <- .new_knowledge(vars_all)

  # capture caller-provided names for messaging
  src1 <- deparse(substitute(kn1))
  src2 <- deparse(substitute(kn2))

  # detect tier conflicts
  tier_conflicts <- dplyr::bind_rows(
    dplyr::mutate(kn1$vars, .src = src1),
    dplyr::mutate(kn2$vars, .src = src2)
  ) |>
    dplyr::distinct(.data$.src, .data$var, .data$tier) |>
    dplyr::group_by(.data$var) |>
    dplyr::filter(
      dplyr::n_distinct(.data$.src) > 1L, # var present in both
      dplyr::n_distinct(.data$tier, na.rm = TRUE) > 1L # and tiers differ
    ) |>
    dplyr::summarise(
      tier_1 = paste(unique(.data$tier[.data$.src == src1]), collapse = ", "),
      tier_2 = paste(unique(.data$tier[.data$.src == src2]), collapse = ", "),
      .groups = "drop"
    )

  # throw error if there are conflicts
  if (nrow(tier_conflicts) > 0L) {
    details <- paste0(
      "- ",
      tier_conflicts$var,
      ": ",
      src1,
      ": ",
      tier_conflicts$tier_1,
      ", ",
      src2,
      ": ",
      tier_conflicts$tier_2
    )
    msg <- paste0(
      "Tier conflict detected for ",
      nrow(tier_conflicts),
      if (nrow(tier_conflicts) == 1L) " variable:\n" else " variables:\n",
      paste(details, collapse = "\n")
    )
    stop(msg, call. = FALSE)
  }

  # var tiers
  vtiers <- dplyr::bind_rows(kn1$vars, kn2$vars) |>
    dplyr::distinct(.data$var, .keep_all = TRUE)

  # merge vars
  out$vars$tier <- vtiers$tier[match(out$vars$var, vtiers$var)]

  # merge tier labels, preserving kn1 order then any new from kn2
  all_labels <- unique(c(kn1$tiers$label, kn2$tiers$label))
  out$tiers <- tibble::tibble(label = all_labels)

  # merge edges (status, from, to, tier_from, tier_to are all character)
  out$edges <- dplyr::distinct(dplyr::bind_rows(kn1$edges, kn2$edges)) |>
    dplyr::mutate(
      tier_from = out$vars$tier[match(.data$from, out$vars$var)],
      tier_to = out$vars$tier[match(.data$to, out$vars$var)]
    )

  # validate
  .validate_forbidden_required(out$edges)
  .validate_tier_rule(out$edges, out$tiers)

  out
}

#' @title Reorder Tiers in Knowledge
#'
#' @param kn A `Knowledge` object.
#' @param order A vector that lists *every* tier exactly once, either by
#'  label (default) or by numeric index (`by_index = TRUE`).
#'  Be careful if you have numeric tier labels.
#' @param by_index If `TRUE`, treat `order` as the positions instead of
#'  labels. Defaults to `FALSE`.
#'
#' @returns The same `Knowledge` object with tiers rearranged.
#'
#' @example inst/roxygen-examples/reorder_tiers-example.R
#'
#' @family knowledge helpers
#' @concept knowledge-helper
#'
#' @export
reorder_tiers <- function(kn, order, by_index = FALSE) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "rlang",
      "tibble"
    ),
    function_name = "reorder_tiers"
  )

  is_knowledge(kn)

  current <- kn$tiers$label
  n <- length(current)

  # helper function to convert a label expression to a string
  as_label1 <- function(expr) {
    if (rlang::is_symbol(expr)) {
      return(as.character(expr))
    }
    if (rlang::is_character(expr)) {
      return(rlang::as_string(expr))
    }
    if (rlang::is_atomic(expr) && length(expr) == 1L) {
      val <- rlang::eval_tidy(expr, env = parent.frame())
      if (is.numeric(val)) {
        return(as.character(val))
      }
      # nocov start
      # this is a fallback that currently can't be reached, but will be kept
      # there for future-proofing.
      if (is.character(val) && nzchar(val)) {
        return(val)
      }
      # nocov end
    }
    stop(
      "`order` contains an unsupported element: ",
      rlang::expr_text(expr),
      call. = FALSE
    )
  }

  # turn input into character label
  if (by_index) {
    idx <- rlang::eval_tidy(rlang::enexpr(order), env = parent.frame())
    if (!is.numeric(idx) || length(idx) != n || !setequal(idx, seq_len(n))) {
      stop(
        "`order` must be a permutation of 1:",
        n,
        " when `by_index = TRUE`.",
        call. = FALSE
      )
    }
    labels <- current[idx]
  } else {
    expr <- rlang::enexpr(order)

    # unwrap literal c(...) call, and get a list of expressions
    parts <- if (rlang::is_call(expr, "c")) {
      rlang::call_args(expr)
    } else {
      list(expr)
    }

    labels <- vapply(parts, as_label1, character(1))
    labels <- unname(labels)

    if (length(labels) != n || !setequal(labels, current)) {
      stop("`order` must list every existing tier exactly once.", call. = FALSE)
    }
  }

  # apply new order
  kn$tiers <- tibble::tibble(label = labels)

  # validate
  .validate_tier_rule(kn$edges, kn$tiers)
  .validate_forbidden_required(kn$edges)

  # return
  kn
}

#' @title Move a Tier Relative to Another in Knowledge
#'
#' @inheritParams reorder_tiers
#' @param tier The tier to move (label or index, honouring `by_index`).
#' @param before Exactly one of these must be supplied and must identify
#'  another existing tier.
#' @param after Exactly one of these must be supplied and must identify
#'  another existing tier.
#'
#' @returns The updated `Knowledge` object.
#'
#' @example inst/roxygen-examples/reorder_tiers-example.R
#'
#' @family knowledge helpers
#' @concept knowledge-helper
#'
#' @export
reposition_tier <- function(
  kn,
  tier,
  before = NULL,
  after = NULL,
  by_index = FALSE
) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "rlang"
    ),
    function_name = "reposition_tier"
  )

  is_knowledge(kn)
  if (!xor(missing(before), missing(after))) {
    stop("Supply exactly one of `before` or `after`.", call. = FALSE)
  }

  current <- kn$tiers$label

  resolve_label <- function(expr) {
    if (by_index) {
      idx <- rlang::eval_tidy(expr, env = parent.frame())
      if (!is.numeric(idx) || length(idx) != 1L) {
        stop(
          "When `by_index = TRUE`, tier references must be length-1 numeric."
        )
      }
      return(current[idx])
    }

    val <- tryCatch(
      rlang::eval_tidy(expr, env = parent.frame()),
      error = function(e) NULL
    )

    if (is.character(val) && length(val) == 1L && nzchar(val)) {
      return(val)
    }
    if (is.numeric(val) && length(val) == 1L) {
      return(as.character(val))
    }
    if (rlang::is_symbol(expr)) {
      return(as.character(expr))
    }
    stop("Tier reference ", rlang::expr_text(expr), " is invalid.")
  }

  tier_lbl <- resolve_label(rlang::enexpr(tier))
  anchor_lbl <- resolve_label(
    if (missing(before)) {
      rlang::enexpr(after)
    } else {
      rlang::enexpr(before)
    }
  )

  if (!tier_lbl %in% current) {
    stop("Tier `", tier_lbl, "` does not exist.")
  }
  if (!anchor_lbl %in% current) {
    stop("Anchor tier `", anchor_lbl, "` does not exist.")
  }
  if (tier_lbl == anchor_lbl) {
    return(kn)
  } # nothing to do

  new_order <- setdiff(current, tier_lbl) # drop, then re-insert
  pos <- match(anchor_lbl, new_order)
  insert_at <- if (missing(before)) pos + 1L else pos
  new_order <- append(new_order, tier_lbl, after = insert_at - 1L)
  reorder_tiers(kn, c(!!!new_order))
}
