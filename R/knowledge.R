# ──────────────────────────────────────────────────────────────────────────────
# ─────────────────────────── Public API  ──────────────────────────────────────
# ──────────────────────────────────────────────────────────────────────────────

#' Define Background Knowledge
#'
#' Create a `Knowledge` object using a concise mini-DSL with `tier()`, `exogenous()` and infix edge operators
#' `%-->%` and `%!-->%`.
#'
#' @description
#' Constructs a `Knowledge` object optionally initialized with a data frame and
#' extended with variable relationships expressed via formulas, selectors, or infix operators:
#'
#' ```r
#' tier(1 ~ V1 + V2, exposure ~ E)
#' V1 %-->% V3    # infix syntax for required edge from V1 to V3
#' V2 %!-->% V3    # infix syntax for an edge from V2 to V3 that is forbidden
#' exogenous(V1, V2)
#' ```
#'
#' @details
#' The first argument can be a data frame, which will be used to populate the
#' `Knowledge` object with variable names. Supplying a data frame also gives
#' \pkg{tidyselect} helpers (e.g. [tidyselect::starts_with()]), a set of column
#' names to resolve against, so they can be used throughout the mini-DSL, for example
#' `tier(1 ~ starts_with("V"))` or `everything() %-->% Y`. If you later add
#' variables with
#' `add_*` verbs, this will throw a warning, since the `Knowledge` object will
#' be *frozen*. You can unfreeze a `Knowledge` object by using the function
#' [unfreeze()].
#'
#' If no data frame is provided, the object is initially empty. Variables can
#' then be added via `tier()`, `forbidden()`, `required()`, infix operators, or `add_vars()`.
#'
#' - `tier()`: Assigns variables to tiers. Tiers may be numeric or string labels.
#'   The left-hand side (LHS) of the formula is the tier; the right-hand side (RHS)
#'   specifies variables. Variables can also be selected using tidyselect syntax:
#'   `tier(1 ~ starts_with("V"))`.
#'
#' - `%-->%` and `%!-->%`: Infix operators to define required and forbidden edges, respectively.
#'   Both sides of the operator can use tidyselect syntax to select multiple variables.
#'
#' - `exogenous()` / `exo()`: Mark variables as exogenous.
#'
#' - Numeric vector shortcut for `tier()`:
#'   `tier(c(1, 2, 1))` assigns tiers by index to all existing variables.
#'
#' Multiple calls or operators are additive: each call adds new edges to the `Knowledge` object.
#' For example:
#'
#' ```r
#' V1 %-->% V3
#' V2 %-->% V3
#' ```
#'
#' results in both edges being required - i.e., the union of all specified required edges.
#'
#' @param ... Arguments to define the `Knowledge` object:
#'   * Optionally, a single data frame (first argument) whose column names
#'     initialize and freeze the variable set.
#'   * Zero or more mini-DSL calls:
#'     `tier()`, `exogenous()`, (shorthand `exo()`), or infix operators `%-->%`, `%!-->%`.
#'     - `tier()`: One or more two-sided formulas (`tier(1 ~ x + y)`), or a numeric vector.
#'     - `exogenous()` / `exo()`: Variable names or tidyselect selectors.
#'     Arguments are evaluated in order; only these calls are allowed.
#'
#' @returns A populated `Knowledge` object.
#'
#' @importFrom tidyselect eval_select everything starts_with ends_with
#' @importFrom tidyselect starts_with ends_with contains matches num_range
#' @importFrom rlang !! .data
#'
#' @example inst/roxygen-examples/knowledge-example.R
#'
#' @family knowledge functions
#' @concept knowledge
#'
#' @export
knowledge <- function(...) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "dplyr",
      "rlang",
      "stats",
      "tibble",
      "tidyselect",
      "utils"
    ),
    function_name = knowledge
  )

  dots <- as.list(substitute(list(...)))[-1]
  df <- NULL

  if (length(dots)) {
    first <- tryCatch(
      eval(dots[[1]], parent.frame()),
      error = function(e) NULL
    )

    if (inherits(first, c("data.frame", "matrix", "tbl_df"))) {
      df <- as.data.frame(first)
      dots <- dots[-1]
    }
  }
  kn <- if (is.null(df)) {
    .new_knowledge()
  } else {
    .new_knowledge(names(df), frozen = TRUE)
  }

  tier <- function(...) {
    specs <- rlang::list2(...)

    # ─────────────────────────── numeric-vector shortcut ──────────────────────
    if (
      length(specs) == 1L &&
        is.numeric(specs[[1]]) &&
        is.atomic(specs[[1]])
    ) {
      vec_num <- specs[[1]]
      vars <- kn$vars$var

      if (!length(vars)) {
        stop(
          "Using tier(<numeric vector>) needs the data-frame columns first.",
          call. = FALSE
        )
      }
      if (length(vec_num) != length(vars)) {
        stop(
          "Tier vector length (",
          length(vec_num),
          ") must equal number of variables (",
          length(vars),
          ").",
          call. = FALSE
        )
      }

      existing_num <- suppressWarnings(as.numeric(kn$tiers$label))
      existing_num <- existing_num[!is.na(existing_num)]
      dup <- intersect(vec_num, existing_num)
      if (length(dup)) {
        stop(
          sprintf(
            "Tier index(es) %s already exist.",
            paste(dup, collapse = ", ")
          ),
          call. = FALSE
        )
      }

      vec_lab <- as.character(vec_num) # treat as labels
      new_lbl <- setdiff(unique(vec_lab), kn$tiers$label)

      if (length(new_lbl)) {
        kn$tiers <<- dplyr::bind_rows(
          kn$tiers,
          tibble::tibble(label = new_lbl)
        ) |>
          dplyr::arrange(suppressWarnings(as.numeric(.data$label)), .data$label)
      }

      kn$vars <<- dplyr::mutate(kn$vars, tier = vec_lab)
      return(kn)
    }

    if (!length(specs)) {
      stop("tier() needs at least one two-sided formula.", call. = FALSE) # nocov
    }

    # ────────────────────────────── main loop ─────────────────────────────────
    for (fml in specs) {
      # ---------- tier_bundle ----------
      if (inherits(fml, "tier_bundle")) {
        tier_vec <- character(length(kn$vars$var))

        for (g in fml) {
          lbl <- as.character(rlang::f_lhs(g))
          rhs <- rlang::f_rhs(g)

          pos <- tidyselect::eval_select(
            rhs,
            stats::setNames(seq_along(kn$vars$var), kn$vars$var)
          )

          if (!length(pos)) {
            stop(
              "Pattern ",
              deparse(rhs),
              " matched no variables.",
              call. = FALSE
            )
          }
          if (any(tier_vec[pos] != "")) {
            dup <- kn$vars$var[pos[tier_vec[pos] != ""]]
            stop(
              "Some variables matched by two patterns: ",
              paste(dup, collapse = ", "),
              call. = FALSE
            )
          }
          tier_vec[pos] <- lbl
        }

        # ensure catalog contains every referenced label
        miss <- setdiff(unique(tier_vec[tier_vec != ""]), kn$tiers$label)
        if (length(miss)) {
          kn$tiers <<- dplyr::bind_rows(
            kn$tiers,
            tibble::tibble(label = miss)
          )
        }

        kn$vars$tier[tier_vec != ""] <<- tier_vec[tier_vec != ""]
        next
      }

      # ────────────────────── ordinary two-sided formula ──────────────────────
      if (!rlang::is_formula(fml, lhs = TRUE)) {
        stop("Each tier() argument must be a two-sided formula.", call. = FALSE)
      }

      lhs_expr <- rlang::f_lhs(fml)
      rhs_expr <- rlang::f_rhs(fml)

      # derive a single-string label:
      tier_val <- tryCatch(
        rlang::eval_tidy(lhs_expr, env = parent.frame()),
        error = function(e) NULL
      )

      if (
        is.character(tier_val) && length(tier_val) == 1L && nzchar(tier_val)
      ) {
        tier_label <- tier_val
      } else if (is.numeric(tier_val) && length(tier_val) == 1L) {
        tier_label <- as.character(tier_val)
      } else {
        tier_label <- rlang::as_label(lhs_expr)
      }

      vars <- .formula_vars(kn, rhs_expr)
      if (!length(vars)) {
        stop(
          sprintf(
            "Tier specification %s matched no variables.",
            deparse(fml)
          ),
          call. = FALSE
        )
      }
      kn <<- add_vars(kn, vars)

      # guard against re-assigning a var that is already in another tier
      clash <- kn$vars$tier[match(vars, kn$vars$var)]
      if (any(!is.na(clash) & clash != tier_label)) {
        bad <- vars[!is.na(clash) & clash != tier_label]
        stop(
          sprintf(
            "Tier specification %s tries to re-assign variable(s) [%s] to a new tier.",
            paste(deparse(fml), collapse = ""),
            paste(bad, collapse = ", ")
          ),
          call. = FALSE
        )
      }

      if (tier_label %in% kn$tiers$label) {
        kn <<- add_to_tier(kn, fml) # already exists, so just attach
        next
      }

      # create new tier after the current last one
      after_anchor <- if (nrow(kn$tiers)) {
        utils::tail(kn$tiers$label, 1)
      } else {
        NULL
      }

      if (is.null(after_anchor)) {
        kn <<- add_tier(kn, !!lhs_expr)
      } else {
        kn <<- rlang::inject(add_tier(kn, !!lhs_expr, after = !!after_anchor))
      }

      kn <<- add_to_tier(kn, fml)
    }

    kn
  }

  add_edge_infix <- function(expr, status) {
    status_cap <- paste0(
      toupper(substr(status, 1L, 1L)),
      substr(status, 2L, nchar(status))
    )

    # Evaluate infix call to get lhs/rhs expressions
    obj <- eval(expr, envir = parent.frame())
    from_vars <- .formula_vars(kn, obj$lhs)
    to_vars <- .formula_vars(kn, obj$rhs)

    lhs_text <- paste0("'", paste(deparse(obj$lhs), collapse = ""), "'")
    rhs_text <- paste0("'", paste(deparse(obj$rhs), collapse = ""), "'")

    if (!length(from_vars)) {
      stop(
        sprintf(
          "%s edge: no variables matched %s from the left-hand side.",
          status_cap,
          lhs_text
        ),
        call. = FALSE
      )
    }

    if (!length(to_vars)) {
      stop(
        sprintf(
          "%s edge: no variables matched %s from the right-hand side.",
          status_cap,
          rhs_text
        ),
        call. = FALSE
      )
    }

    kn <<- add_vars(kn, c(from_vars, to_vars))
    kn <<- .add_edges(kn, status, from_vars, to_vars)
  }

  exogenous <- function(...) {
    # capture the raw expressions the user typed
    specs <- rlang::enexprs(...)

    if (length(specs) == 0L) {
      stop(
        "exogenous() needs at least one variable specification.",
        call. = FALSE
      )
    }

    # if they passed >1 selector, splice them into a single c(...) call
    vars_expr <- if (length(specs) == 1L) {
      specs[[1]]
    } else {
      rlang::expr(c(!!!specs))
    }

    # inject that call straight into add_exogenous()
    kn <<- add_exogenous(
      kn,
      !!vars_expr
    )
  }
  # synonyms for exogenous
  exo <- exogenous

  # evaluate the call list
  allowed <- c("tier", "forbidden", "required", "exogenous", "exo")

  for (expr in dots) {
    if (is.call(expr)) {
      fun <- as.character(expr[[1]])
    }

    # Handle expressions like A + B %-->% C + D where + mixes with edge ops.
    # R parses %any% before +, so A + B %-->% C + D becomes A + (B %-->% C) + D.
    # Flatten the whole + chain into terms, find
    # the single edge-op term, then attach left/right node-terms to its LHS/RHS.
    if (is.call(expr) && identical(expr[[1]], as.name("+"))) {
      .split_terms <- function(e) {
        if (is.call(e) && identical(e[[1L]], as.name("+"))) {
          c(.split_terms(e[[2L]]), .split_terms(e[[3L]]))
        } else {
          list(e)
        }
      }
      .join_plus <- function(ts) Reduce(function(a, b) call("+", a, b), ts)

      terms <- .split_terms(expr)
      is_edge_term <- vapply(
        terms,
        function(t) {
          is.call(t) && as.character(t[[1L]]) %in% c("%-->%", "%!-->%")
        },
        logical(1L)
      )

      if (any(is_edge_term)) {
        if (sum(is_edge_term) > 1L) {
          stop(
            "Only one edge operator per + expression is supported.\n",
            "Expression: ",
            deparse(expr),
            call. = FALSE
          )
        }
        i <- which(is_edge_term)
        edge_term <- terms[[i]]
        left_terms <- terms[seq_len(i - 1L)]
        right_terms <- if (i < length(terms)) {
          terms[seq(i + 1L, length(terms))]
        } else {
          list()
        }

        natural_lhs <- edge_term[[2L]]
        natural_rhs <- edge_term[[3L]]

        new_lhs <- if (length(left_terms)) {
          call("+", .join_plus(left_terms), natural_lhs)
        } else {
          natural_lhs
        }
        new_rhs <- if (length(right_terms)) {
          call("+", natural_rhs, .join_plus(right_terms))
        } else {
          natural_rhs
        }

        new_edge <- edge_term
        new_edge[[2L]] <- new_lhs
        new_edge[[3L]] <- new_rhs

        status <- if (identical(edge_term[[1L]], as.name("%-->%"))) {
          "required"
        } else {
          "forbidden"
        }
        add_edge_infix(new_edge, status)
        next
      }
    }

    # Infix required
    if (is.call(expr) && identical(expr[[1]], as.name("%-->%"))) {
      add_edge_infix(expr, "required")
      next
    }

    # Infix forbidden
    if (is.call(expr) && identical(expr[[1]], as.name("%!-->%"))) {
      add_edge_infix(expr, "forbidden")
      next
    }

    if (inherits(expr, "required_edge")) {
      add_edge_infix(expr, "required")
      next
    }
    if (inherits(expr, "forbidden_edge")) {
      add_edge_infix(expr, "forbidden")
      next
    }

    # Standard function calls
    if (!is.call(expr) || !(as.character(expr[[1]]) %in% allowed)) {
      stop(
        "Only tier(), exogenous(), ",
        "and infix edge operators (%-->%, %!-->%) are allowed.\n",
        "The expression that triggered this error was: ",
        deparse(expr),
        call. = FALSE
      )
    }

    eval(expr, envir = environment())
  }

  # Sort tiers only if all labels are numeric-coercible
  suppressWarnings({
    tier_num_tiers <- as.numeric(kn$tiers$label)
  })

  if (!anyNA(tier_num_tiers)) {
    # Sort kn$tiers
    kn$tiers <- kn$tiers |>
      dplyr::mutate(.tier_num = tier_num_tiers) |>
      dplyr::arrange(.data$.tier_num) |>
      dplyr::select(-".tier_num")

    # Sort kn$vars by numeric tier
    kn$vars <- kn$vars |>
      dplyr::mutate(.tier_num = as.numeric(tier)) |>
      dplyr::arrange(.data$.tier_num, .data$var) |>
      dplyr::select(-".tier_num")
  }

  kn
}

#' @title Infix operator for required edges
#' @description
#' Creates a required edge between two variables or sets of variables.
#'
#' @param lhs Left-hand side variable(s).
#' @param rhs Right-hand side variable(s).
#' @returns An object of class `required_edge`.
#' @keywords internal
#' @noRd
`%-->%` <- function(lhs, rhs) {
  structure(
    list(lhs = substitute(lhs), rhs = substitute(rhs)),
    class = "required_edge"
  )
}

#' @title Infix operator for forbidden edges
#' @description
#' Creates a forbidden edge between two variables or sets of variables.
#'
#' @param lhs Left-hand side variable(s).
#' @param rhs Right-hand side variable(s).
#' @returns An object of class `forbidden_edge`.
#' @keywords internal
#' @noRd
`%!-->%` <- function(lhs, rhs) {
  structure(
    list(lhs = substitute(lhs), rhs = substitute(rhs)),
    class = "forbidden_edge"
  )
}

# ────────────────────────────────── Print ─────────────────────────────────────
#' @title Print a Knowledge Object
#'
#' @param x A `Knowledge` object.
#' @param ... Additional arguments (not used).
#' @returns Invisibly returns the `Knowledge` object.
#' @examples
#' kn <- knowledge(
#'   tpc_example,
#'   tier(
#'     child ~ starts_with("child"),
#'     youth ~ starts_with("youth"),
#'     old ~ starts_with("old")
#'   )
#' )
#' print(kn)
#'
#' @exportS3Method print Knowledge
print.Knowledge <- function(x, ...) {
  .check_if_pkgs_are_installed(
    pkgs = c("cli"),
    function_name = "print.Knowledge"
  )

  n_tiers <- if (!is.null(x$tiers)) nrow(x$tiers) else 0L
  n_vars <- if (!is.null(x$vars)) nrow(x$vars) else 0L
  n_required <- sum(x$edges$status == "required", na.rm = TRUE)
  n_forbidden <- sum(x$edges$status == "forbidden", na.rm = TRUE)

  if (n_tiers == 0L && n_vars == 0L && n_required == 0L && n_forbidden == 0L) {
    cat("<Knowledge: empty>\n")
    return(invisible(x))
  }

  parts <- character(0)
  if (n_tiers > 0L) {
    parts <- c(parts, paste0(n_tiers, " tier", if (n_tiers != 1L) "s"))
  }
  if (n_vars > 0L) {
    parts <- c(parts, paste0(n_vars, " var", if (n_vars != 1L) "s"))
  }
  if (n_required > 0L) {
    parts <- c(parts, paste0(n_required, " required"))
  }
  if (n_forbidden > 0L) {
    parts <- c(parts, paste0(n_forbidden, " forbidden"))
  }
  cat(sprintf("<Knowledge: %s>\n", paste(parts, collapse = " | ")))

  .print_knowledge_body(x)
  invisible(x)
}

.print_knowledge_body <- function(x, max_tiers = 5L, max_edge_groups = 8L) {
  n_tiers <- if (!is.null(x$tiers)) nrow(x$tiers) else 0L
  n_vars <- if (!is.null(x$vars)) nrow(x$vars) else 0L
  n_required <- sum(x$edges$status == "required", na.rm = TRUE)
  n_forbidden <- sum(x$edges$status == "forbidden", na.rm = TRUE)

  # ---- Tiers ----
  if (n_tiers > 0L) {
    show <- min(n_tiers, max_tiers)
    for (lbl in x$tiers$label[seq_len(show)]) {
      tier_vars <- x$vars$var[!is.na(x$vars$tier) & x$vars$tier == lbl]
      .print_item_line(paste0("tier(", lbl, ")"), tier_vars)
    }
    if (n_tiers > max_tiers) {
      cat(sprintf(
        "  ... and %d more tier%s\n",
        n_tiers - max_tiers,
        if (n_tiers - max_tiers != 1L) "s" else ""
      ))
    }
  }

  # ---- Untiered vars ----
  if (n_vars > 0L) {
    untiered <- x$vars$var[is.na(x$vars$tier)]
    if (length(untiered) > 0L) {
      .print_item_line("vars", untiered)
    }
  }

  # ---- Edges ----
  if (n_required > 0L || n_forbidden > 0L) {
    n_shown <- 0L
    for (status in c("required", "forbidden")) {
      op <- if (status == "required") "-->" else "!-->"
      grp <- x$edges[x$edges$status == status, , drop = FALSE]
      if (nrow(grp) == 0L) {
        next
      }
      cat(sprintf("  %s:\n", status))
      by_from <- split(grp$to, grp$from)
      for (from_var in names(by_from)) {
        if (n_shown >= max_edge_groups) {
          n_total_groups <- length(unique(x$edges$from))
          cat(sprintf(
            "  ... and %d more edge group%s\n",
            n_total_groups - n_shown,
            if (n_total_groups - n_shown != 1L) "s" else ""
          ))
          return(invisible())
        }
        to_vars <- by_from[[from_var]]
        rhs <- paste(to_vars, collapse = " + ")
        cat(sprintf("    %s%s%s\n", from_var, op, rhs))
        n_shown <- n_shown + 1L
      }
    }
  }
}

#' @title Summarize a Knowledge Object
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' `summary()` for `Knowledge` objects is deprecated. Use [print()] instead.
#'
#' @param object A `Knowledge` object.
#' @param ... Additional arguments (not used).
#' @returns Invisibly returns the `Knowledge` object.
#' @examples
#' kn <- knowledge(
#'   tpc_example,
#'   tier(
#'     child ~ starts_with("child"),
#'     youth ~ starts_with("youth"),
#'     old ~ starts_with("old")
#'   )
#' )
#' print(kn)
#'
#' @exportS3Method summary Knowledge
summary.Knowledge <- function(object, ...) {
  lifecycle::deprecate_warn(
    when = "1.2.0",
    what = "summary.Knowledge()",
    with = "print.Knowledge()"
  )
  print(object, ...)
  invisible(object)
}

# ────────────────────────────────── Check ─────────────────────────────────────
#' @title Verify that an object is a knowledge
#'
#' @description Check that the object is a `Knowledge` object. Mostly
#' for internal use in causalDisco.
#'
#' @param x Object to check.
#'
#' @example inst/roxygen-examples/is_knowledge-example.R
#'
#' @family knowledge functions
#' @concept knowledge
#' @noRd
#' @keywords internal
is_knowledge <- function(x) {
  if (!inherits(x, "Knowledge")) {
    stop("Input must be a knowledge instance.", call. = FALSE)
  }
  TRUE
}


# ───────────────────────────────── Deparse ────────────────────────────────────
#' @title Deparse a Knowledge Object into Knowledge DSL Code
#'
#' @description
#' Given a `Knowledge` object, return a single string containing
#' the R code (using `knowledge()`, `tier()`, `%-->%`, and `%!-->%`.
#' that would rebuild that same object.
#'
#' @param kn A `Knowledge` object.
#' @param df_name Optional name of the data frame you used
#' (used as the first argument to `knowledge()`).  If `NULL`,
#' `knowledge()` is called with no data frame.
#'
#' @returns A single string (with newlines) of R code.
#'
#' @example inst/roxygen-examples/deparse_knowledge-example.R
#'
#' @family knowledge functions
#' @concept knowledge
#'
#' @export
deparse_knowledge <- function(kn, df_name = NULL) {
  .check_if_pkgs_are_installed(
    pkgs = c("dplyr"),
    function_name = "deparse_knowledge"
  )

  is_knowledge(kn)

  fmt_fml <- function(lhs, rhs_vars) {
    paste0(
      as.character(lhs),
      " ~ ",
      paste(as.character(rhs_vars), collapse = " + ")
    )
  }

  fmt_edge <- function(lhs, rhs_vars, status) {
    op <- ifelse(status == "required", " %-->% ", " %!-->% ")
    rhs_str <- if (length(rhs_vars) > 1) {
      paste0("c(", paste(rhs_vars, collapse = ", "), ")")
    } else {
      rhs_vars
    }
    paste0(lhs, op, rhs_str)
  }

  out <- character()

  # ---- header ----
  if (is.null(df_name)) {
    out <- c(out, "knowledge(")
  } else {
    out <- c(out, paste0("knowledge(", df_name, ","))
  }

  # ---- tiers ----
  if (nrow(kn$tiers)) {
    tier_labels <- kn$tiers$label
    tier_fmls <- vapply(
      tier_labels,
      function(lbl) {
        vars <- kn$vars$var[kn$vars$tier == lbl]
        fmt_fml(lbl, vars)
      },
      character(1)
    )

    out <- c(
      out,
      "  tier(",
      paste0("    ", tier_fmls, collapse = ",\n"),
      "  ),"
    )
  }

  # ---- edges (grouped) ----
  if (nrow(kn$edges)) {
    # group edges by 'from' and 'status'
    edge_groups <- kn$edges |>
      dplyr::group_by(.data$from, .data$status) |>
      dplyr::summarise(to_vars = list(.data$to), .groups = "drop")

    edge_fmls <- vapply(
      seq_len(nrow(edge_groups)),
      function(i) {
        fmt_edge(
          edge_groups$from[i],
          edge_groups$to_vars[[i]],
          edge_groups$status[i]
        )
      },
      character(1)
    )

    out <- c(
      out,
      paste0("  ", edge_fmls, collapse = ",\n")
    )
  }

  # ---- footer ----
  last <- length(out)
  out[last] <- sub(",$", "", out[last])
  out <- c(out, ")")

  paste(out, collapse = "\n")
}
