# ──────────────────────────────────────────────────────────────────────────────
# ─────────────────────────── Public API  ──────────────────────────────────────
# ──────────────────────────────────────────────────────────────────────────────

#' Run the TPC Algorithm for Causal Discovery
#'
#' @description
#' Run a tier-aware variant of the PC algorithm that respects background
#' knowledge about a partial temporal order. Supply the temporal order via a
#' `Knowledge` object.
#'
#' @param data A data frame with the observed variables.
#' @param knowledge A `Knowledge` object created with [knowledge()],
#'   encoding tier assignments and optional forbidden/required edges. This is
#'   the preferred way to provide temporal background knowledge.
#' @param alpha The alpha level used as the per-test significance
#'   threshold for conditional independence testing.
#' @param test A conditional independence test. The default [reg_test()]
#'   uses a regression-based information-loss test. Another available option is
#'   [cor_test()] which tests for vanishing partial correlations. User-supplied
#'   functions may also be used; see details for the required interface.
#' @param suff_stat A sufficient statistic. If supplied, it is passed directly
#'   to the test and no statistics are computed from \code{data}. Its structure
#'   depends on the chosen \code{test}.
#' @param method Skeleton construction method, one of \code{"stable"},
#'   \code{"original"}, or \code{"stable.fast"} (default). See
#'   [pcalg::skeleton()] for details.
#' @param na_method Handling of missing values, one of \code{"none"} (default;
#'   error on any \code{NA}), \code{"cc"} (complete-case analysis), or
#'   \code{"twd"} (test-wise deletion).
#' @param orientation_method Conflict-handling method when orienting edges.
#'   Currently only the conservative method is available.
#' @param directed_as_undirected `r lifecycle::badge("deprecated")` This
#'   argument no longer has any effect and will be removed in a future
#'   release. Directed forbidden edges are now resolved using tier
#'   information, or must be specified in both directions.
#' @param varnames Character vector of variable names. Only needed when
#'   \code{data} is not supplied and all information is passed via
#'   \code{suff_stat}.
#' @param num_cores Integer number of CPU cores to use for parallel skeleton learning.
#' @param ... Additional arguments passed to
#'   [pcalg::skeleton()] during skeleton construction.
#'
#' @details
#' Any independence test implemented in \pkg{pcalg} may be used; see
#' [pcalg::pc()]. When \code{na_method = "twd"}, test-wise deletion is
#' performed: for [cor_test()], each pairwise correlation uses complete cases;
#' for [reg_test()], each conditional test performs its own deletion. If you
#' supply a user-defined \code{test}, you must also provide \code{suff_stat}.
#'
#' Temporal or tiered knowledge enters in two places:
#' \itemize{
#'   \item during skeleton estimation, candidate conditioning sets are pruned so
#'   they do not contain variables that are strictly after both endpoints;
#'   \item during orientation, any cross-tier edge is restricted to point
#'   forward in time.
#' }
#'
#' @inheritSection disco_note Recommendation
#' @inheritSection disco_algs_return_doc_pdag Value
#'
#' @example inst/roxygen-examples/tpc-example.R
#'
#' @export
tpc_run <- function(
  data = NULL,
  knowledge = NULL,
  alpha = 0.05,
  test = reg_test,
  suff_stat = NULL,
  method = "stable.fast",
  na_method = "none",
  orientation_method = "conservative",
  directed_as_undirected = lifecycle::deprecated(),
  varnames = NULL,
  num_cores = 1,
  ...
) {
  if (lifecycle::is_present(directed_as_undirected)) {
    lifecycle::deprecate_warn(
      when = "1.2.0",
      what = "tpc_run(directed_as_undirected)",
      details = paste0(
        "The argument is ignored. Directed forbidden edges are now resolved ",
        "using tier information, or must be specified in both directions."
      )
    )
  }

  prep <- constraint_based_prepare_inputs(
    data = data,
    knowledge = knowledge,
    varnames = varnames,
    na_method = na_method,
    test = test,
    suff_stat = suff_stat,
    function_name = "tpc"
  )

  # unpack returned values
  data <- prep$data
  knowledge <- prep$knowledge
  vnames <- prep$vnames
  suff_stat <- prep$suff_stat
  na_method <- prep$na_method
  test <- prep$internal_test # Ensure we use the internal test with camelCase so it works downstream with pcalg

  knowledge <- .infer_tiers_from_forbidden(knowledge)
  knowledge <- prepare_knowledge(knowledge) # Precompute variable ranks for efficient access

  # check orientation method
  if (!(orientation_method %in% c("standard", "conservative", "maj.rule"))) {
    stop(
      "Orientation method must be one of standard, conservative or maj.rule."
    )
  }

  # CI test that forbids conditioning on future tiers
  indep_test_dir <- dir_test(test, vnames, knowledge)

  # pcalg background constraints (forbidden/required) from knowledge
  constraints <- .pcalg_constraints_from_knowledge(
    knowledge,
    labels = vnames
  )

  # learn skeleton
  skel <- pcalg::skeleton(
    suffStat = suff_stat,
    indepTest = indep_test_dir,
    alpha = alpha,
    labels = vnames,
    method = method,
    fixedGaps = constraints$fixed_gaps,
    numCores = num_cores,
    ...
  )
  ntests <- sum(skel@n.edgetests)

  res <- tpdag(skel, knowledge = knowledge)
  # caugi assumes rows are the "from" nodes and columns the "to" nodes, so transpose.
  cg <- caugi::as_caugi(t(res), collapse = TRUE, class = "UNKNOWN")
  as_disco(cg, knowledge)
}

# ──────────────────────────────────────────────────────────────────────────────
# ──────────────────────────── Helpers  ────────────────────────────────────────
# ──────────────────────────────────────────────────────────────────────────────

#' Build tiered knowledge from legacy order prefixes
#'
#' @description
#' Helper that converts a character \code{order} of prefixes into a
#' `Knowledge` object by creating one tier per prefix and assigning
#' variables with \code{tidyselect::starts_with("<prefix>")}.
#'
#' @param order Character vector of prefixes in temporal order.
#' @param data Optional data frame used to freeze the knowledge variable set.
#' @param vnames Optional character vector of variable names when \code{data}
#'   is not supplied.
#'
#' @example inst/roxygen-examples/dot-build_knowledge_from_order-example.R
#'
#' @return A `Knowledge` object with tiers matching \code{order}.
#' @keywords internal
#' @noRd
.build_knowledge_from_order <- function(order, data = NULL, vnames = NULL) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "rlang",
      "tidyselect",
      "utils"
    ),
    function_name = ".build_knowledge_from_order"
  )

  checkmate::assert_character(order, min.len = 1)

  # build tier specs like: "<lbl>" ~ starts_with("<lbl>")
  fmls <- lapply(order, function(lbl) {
    rlang::new_formula(
      lhs = rlang::expr(!!lbl),
      rhs = rlang::expr(tidyselect::starts_with(!!lbl)),
      env = rlang::empty_env()
    )
  })

  # if data is provided, delegate to knowledge() with tier() rules
  if (!is.null(data)) {
    return(rlang::inject(knowledge(data, tier(!!!fmls))))
  }

  # otherwise, build a bare `Knowledge` object from variable names
  if (is.null(vnames) && is.null(data)) {
    stop("`data` is NULL, so `vnames` should be provided.")
  }

  kn <- knowledge() |> add_vars(vnames)

  # create tiers in declared order
  for (lbl in order) {
    if (nrow(kn$tiers) == 0L) {
      kn <- add_tier(kn, !!lbl)
    } else {
      last <- utils::tail(kn$tiers$label, 1)
      kn <- rlang::inject(add_tier(kn, !!lbl, after = !!last))
    }
  }

  # assign tiers by prefix match; do not overwrite earlier assignments
  for (lbl in order) {
    hits <- startsWith(vnames, lbl)
    if (any(hits)) {
      idx <- match(vnames[hits], kn$vars$var)
      unassigned <- is.na(kn$vars$tier[idx])
      if (any(unassigned)) {
        kn$vars$tier[idx[unassigned]] <- lbl
      }
    }
  }
  kn
}

#' Temporally orient unshielded colliders
#'
#' @description
#' Given a CPDAG adjacency matrix and separation sets, orient v-structures
#' that do not contradict the current directions, respecting temporal tiering.
#'
#' @param amat Square adjacency matrix (from-to convention).
#' @param sepsets Separation sets as computed by \pkg{pcalg}.
#'
#' @example inst/roxygen-examples/v_orient_temporal-example.R
#'
#' @return The updated adjacency matrix with additional arrowheads.
#' @keywords internal
#' @noRd
v_orient_temporal <- function(amat, sepsets) {
  nvar <- nrow(amat)

  for (i in 1:nvar) {
    theseAdj <- find_adjacencies(amat, i)

    # if there are at least two adjacent nodes
    if (length(theseAdj) >= 2) {
      adjpairs <- t(utils::combn(theseAdj, 2))

      npairs <- nrow(adjpairs)

      if (npairs >= 1) {
        for (j in 1:npairs) {
          thisPair <- adjpairs[j, ]
          j1 <- thisPair[1]
          j2 <- thisPair[2]
          thisPairAdj <- j2 %in% find_adjacencies(amat, j1)

          # if pair is not adjacent (unmarried)
          if (!thisPairAdj) {
            sepset1 <- sepsets[[j1]][[j2]]
            sepset2 <- sepsets[[j2]][[j1]]

            # if middle node is not a separator of two other nodes
            if (!(i %in% sepset1) && !(i %in% sepset2)) {
              # if this does not contradict directional information
              # already in the graph
              if (amat[i, j1] == 1 && amat[i, j2] == 1) {
                amat[j1, i] <- 0
                amat[j2, i] <- 0
              }
            }
          }
        }
      }
    }
  }
  amat
}

#' Find adjacencies of a node in an adjacency matrix
#'
#' @param amatrix Square adjacency matrix.
#' @param index Integer index of the node.
#'
#' @example inst/roxygen-examples/find_adjacencies-example.R
#'
#' @return Integer vector of adjacent node indices.
#' @keywords internal
#' @noRd
find_adjacencies <- function(amatrix, index) {
  union(
    which(as.logical(amatrix[index, ])),
    which(as.logical(amatrix[, index]))
  )
}

#' Infer tiers from tier-shaped forbidden knowledge
#'
#' @description
#' If a `Knowledge` object has no tiers but its directed forbidden edges are
#' exactly the set a tier ordering would generate (e.g. the output of
#' [convert_tiers_to_forbidden()]), reconstruct that ordering: fill in the
#' tiers and drop the tier-implied forbidden edges. Under a tier ordering,
#' the set of variables each variable is forbidden to point at is exactly
#' the union of all earlier tiers, which identifies the tiers uniquely.
#' Symmetric forbidden pairs are gap constraints, not order statements, and
#' are left untouched. If the forbidden edges are not tier-shaped, the input
#' is returned unchanged.
#'
#' When the object already has tiers, directed forbidden edges involving
#' untiered variables are instead resolved by
#' `.assign_untiered_from_forbidden()`, which places those variables into
#' the existing tier ordering when the edges pin down a unique position.
#'
#' @param kn A `Knowledge` object.
#'
#' @return A `Knowledge` object.
#' @keywords internal
#' @noRd
.infer_tiers_from_forbidden <- function(kn) {
  forb_idx <- which(kn$edges$status == "forbidden")
  forb <- kn$edges[forb_idx, , drop = FALSE]
  if (!nrow(forb)) {
    return(kn)
  }

  sym <- paste(forb$from, forb$to) %in% paste(forb$to, forb$from)
  dir_forb <- forb[!sym, , drop = FALSE]
  dir_idx <- forb_idx[!sym]
  if (!nrow(dir_forb)) {
    return(kn)
  }

  if (!all(is.na(kn$vars$tier))) {
    return(.assign_untiered_from_forbidden(kn, dir_forb, dir_idx))
  }

  participants <- sort(unique(c(dir_forb$from, dir_forb$to)))
  earlier <- lapply(
    participants,
    function(v) unique(dir_forb$to[dir_forb$from == v])
  )
  names(earlier) <- participants

  sig <- vapply(
    earlier,
    function(x) paste(sort(x), collapse = "\r"),
    FUN.VALUE = ""
  )
  groups <- split(participants, sig)
  groups <- groups[
    order(vapply(groups, function(g) length(earlier[[g[[1]]]]), integer(1)))
  ]

  # tier-shaped iff each group's earlier-set is exactly the union of all
  # preceding groups
  seen <- character(0)
  for (g in groups) {
    if (!setequal(earlier[[g[[1]]]], seen)) {
      return(kn)
    }
    seen <- c(seen, g)
  }

  message(
    "The directed forbidden edges in `knowledge` encode a temporal order; ",
    "treating them as ",
    length(groups),
    " tiers."
  )

  labels <- as.character(seq_along(groups))
  tier_of <- stats::setNames(rep(labels, lengths(groups)), unlist(groups))
  kn$tiers <- tibble::tibble(label = labels)
  kn$vars$tier <- unname(tier_of[kn$vars$var])
  kn$edges <- kn$edges[-dir_idx, , drop = FALSE]
  kn
}

#' Place untiered variables into existing tiers via forbidden edges
#'
#' @description
#' Given a `Knowledge` object that already has tiers, resolve
#' forbidden edges involving untiered variables by assigning those variables
#' a position in the tier ordering.
#'
#' @param kn A `Knowledge` object with at least one tiered variable.
#' @param dir_forb Forbidden edges of \code{kn}.
#' @param dir_idx Row indices of \code{dir_forb} within \code{kn$edges}.
#'
#' @return A `Knowledge` object.
#' @keywords internal
#' @noRd
.assign_untiered_from_forbidden <- function(kn, dir_forb, dir_idx) {
  rank_of <- stats::setNames(
    match(kn$vars$tier, kn$tiers$label),
    kn$vars$var
  )
  n_tiers <- nrow(kn$tiers)

  involves_untiered <- is.na(rank_of[dir_forb$from]) |
    is.na(rank_of[dir_forb$to])
  if (!any(involves_untiered)) {
    return(kn)
  }

  ue <- dir_forb[involves_untiered, , drop = FALSE]
  participants <- unique(c(ue$from, ue$to))
  new_vars <- participants[is.na(rank_of[participants])]
  tiered_vars <- kn$vars$var[!is.na(rank_of[kn$vars$var])]

  # place each untiered variable on a slot scale where existing tier k
  # occupies slot 2k, so odd slots are the gaps between adjacent tiers
  slot <- stats::setNames(integer(length(new_vars)), new_vars)
  for (v in new_vars) {
    later <- unique(ue$from[ue$to == v])
    earlier <- unique(ue$to[ue$from == v])
    later_tiered <- intersect(later, tiered_vars)
    earlier_tiered <- intersect(earlier, tiered_vars)

    a <- if (length(later_tiered)) {
      min(rank_of[later_tiered])
    } else {
      n_tiers + 1L
    }
    b <- if (length(earlier_tiered)) max(rank_of[earlier_tiered]) else 0L

    # exactness: everything from tier a on must be stated as later than v,
    # everything up to tier b as earlier, and nothing else may be stated
    if (
      !setequal(later_tiered, tiered_vars[rank_of[tiered_vars] >= a]) ||
        !setequal(earlier_tiered, tiered_vars[rank_of[tiered_vars] <= b])
    ) {
      return(kn)
    }

    if (a - b == 2L) {
      # exactly one tier strictly between: v joins it, implying nothing new
      slot[[v]] <- 2L * (b + 1L)
    } else if (a - b == 1L) {
      # no tier strictly between: v forms a new tier in the gap
      slot[[v]] <- 2L * b + 1L
    } else {
      # several tiers between with no stated relation to v: any placement
      # would imply unstated constraints, so this is not tier-shaped
      return(kn)
    }
  }

  # the same exactness must hold among the placed variables themselves
  for (v in new_vars) {
    for (w in new_vars) {
      if (v == w) {
        next
      }
      stated <- any(ue$from == w & ue$to == v)
      if (stated != (slot[[w]] > slot[[v]])) {
        return(kn)
      }
    }
  }

  slots <- sort(unique(c(2L * seq_len(n_tiers), slot)))
  labels <- character(length(slots))
  used <- kn$tiers$label
  next_int <- 1L
  for (i in seq_along(slots)) {
    if (slots[[i]] %% 2L == 0L) {
      labels[[i]] <- kn$tiers$label[[slots[[i]] %/% 2L]]
    } else {
      while (as.character(next_int) %in% used) {
        next_int <- next_int + 1L
      }
      labels[[i]] <- as.character(next_int)
      used <- c(used, labels[[i]])
    }
  }

  message(
    "The directed forbidden edges in `knowledge` place ",
    length(new_vars),
    " untiered variable(s) in the temporal order; assigning them to tiers."
  )

  kn$tiers <- tibble::tibble(label = labels)
  slot_label <- stats::setNames(labels, slots)
  kn$vars$tier[match(new_vars, kn$vars$var)] <-
    unname(slot_label[as.character(slot)])
  kn$edges <- kn$edges[-dir_idx[involves_untiered], , drop = FALSE]
  if (nrow(kn$edges)) {
    kn$edges$tier_from <- kn$vars$tier[match(kn$edges$from, kn$vars$var)]
    kn$edges$tier_to <- kn$vars$tier[match(kn$edges$to, kn$vars$var)]
  }
  kn
}

#' Compute tier indices for variables
#'
#' @description
#' Map variable names to their tier ranks according to a \code{knowledge}
#' object. Variables without a tier receive \code{NA}.
#'
#' @param kn A `Knowledge` object.
#' @param vnames Character vector of variable names.
#'
#' @example inst/roxygen-examples/dot-tier_index-example.R
#'
#' @return Named integer vector of the same length as \code{vnames}.
#' @keywords internal
#' @noRd
.tier_index <- function(kn, vnames) {
  is_knowledge(kn)
  idx <- match(vnames, kn$vars$var)
  tiers <- kn$vars$tier[idx]
  rank <- match(tiers, kn$tiers$label)
  stats::setNames(rank, vnames)
}

prepare_knowledge <- function(kn) {
  is_knowledge(kn)

  # Direct variable -> tier rank mapping
  kn$.__var_rank <- stats::setNames(
    match(kn$vars$tier, kn$tiers$label),
    kn$vars$var
  )

  kn
}

#' Directed indepTest wrapper that forbids conditioning on the future
#'
#' @description
#' Wrap a conditional independence test so that conditioning sets that are
#' strictly after both endpoints are rejected, implementing the temporal
#' restriction during skeleton learning.
#'
#' @param test A function \code{f(x, y, S, suff_stat)} returning a p-value or
#'   test statistic compatible with \pkg{pcalg}.
#' @param vnames Character vector of variable names (labels).
#' @param knowledge A `Knowledge` object.
#'
#' @example inst/roxygen-examples/dir_test-example.R
#'
#' @return A function with the same interface as \code{test}.
#' @keywords internal
#' @noRd
dir_test <- function(test, vnames, knowledge) {
  vr <- knowledge$.__var_rank

  function(x, y, conditioning_set, suff_stat) {
    snames <- vnames[conditioning_set]
    x_rank <- vr[[vnames[x]]]
    y_rank <- vr[[vnames[y]]]

    if (length(snames) && !is.na(x_rank) && !is.na(y_rank)) {
      for (s in snames) {
        s_rank <- vr[[s]]
        if (
          !is.na(s_rank) &&
            s_rank > x_rank &&
            s_rank > y_rank
        ) {
          return(0)
        }
      }
    }
    do.call(
      test,
      list(x = x, y = y, S = conditioning_set, suffStat = suff_stat)
    )
  }
}

#' Convert knowledge to \pkg{pcalg} constraints
#'
#' @description
#' Turn directed forbidden edges into an undirected \code{fixedGaps} matrix
#' in the supplied \code{labels} order. Tier
#' membership is used to resolve directed forbidden edges: an edge forbidden
#' from a later tier into an earlier one is already enforced during
#' orientation and yields no skeleton constraint, while a forbidden edge
#' whose reverse direction is ruled out by the tier ordering amounts to a
#' full gap and is mirrored. Any remaining asymmetric edge is an error, as
#' in [as_pcalg_constraints()].
#'
#' @param kn A `Knowledge` object.
#' @param labels Character vector of variable names in the desired order.
#'
#' @example inst/roxygen-examples/dot-pcalg_constraints_from_knowledge-example.R
#'
#' @return A list with the logical matrix \code{fixed_gaps}. Required edges
#'   are dropped with a warning by [as_pcalg_constraints()].
#' @keywords internal
#' @noRd
.pcalg_constraints_from_knowledge <- function(kn, labels) {
  edges <- kn$edges
  ranks <- .tier_index(kn, labels)
  from_rank <- unname(ranks[edges$from])
  to_rank <- unname(ranks[edges$to])
  cross_tier <- edges$status == "forbidden" &
    !is.na(from_rank) &
    !is.na(to_rank) &
    from_rank != to_rank

  # later -> earlier is already forbidden by the tier ordering (enforced
  # during orientation), so it adds no skeleton constraint
  drop <- cross_tier & from_rank > to_rank
  # earlier -> later: the reverse direction is tier-forbidden, so forbidding
  # this direction too amounts to a full gap between the pair
  mirror <- cross_tier & from_rank < to_rank

  mirrored <- edges[mirror, , drop = FALSE]
  if (nrow(mirrored)) {
    tmp <- mirrored$from
    mirrored$from <- mirrored$to
    mirrored$to <- tmp
  }

  kn_undirected <- kn
  kn_undirected$edges <- rbind(edges[!drop, , drop = FALSE], mirrored)
  kn_undirected$vars$tier <- NA_character_
  as_pcalg_constraints(kn_undirected, labels = labels)
}

#' Remove disallowed backward edges across tiers
#'
#' @description
#' Apply tier constraints to a CPDAG adjacency matrix by zeroing any entry that
#' points from a later tier into an earlier tier.
#'
#' @param amat Square adjacency matrix (from-to convention).
#' @param knowledge A `Knowledge` object with tier labels.
#'
#' @example inst/roxygen-examples/order_restrict_amat_cpdag-example.R
#'
#' @return The pruned adjacency matrix.
#' @keywords internal
#' @noRd
order_restrict_amat_cpdag <- function(amat, knowledge) {
  p <- nrow(amat)
  vnames <- rownames(amat)
  tr <- .tier_index(knowledge, vnames)

  if (all(is.na(tr))) {
    return(amat)
  }

  for (i in seq_len(p)) {
    for (j in seq_len(p)) {
      if (!is.na(tr[i]) && !is.na(tr[j]) && tr[i] > tr[j]) {
        amat[j, i] <- 0
      }
    }
  }
  amat
}

#' Orient a CPDAG under temporal background knowledge
#'
#' @description
#' Take a learned skeleton and apply tier-based pruning and v-structure
#' orientation, then delegate to \code{pcalg::addBgKnowledge()} for final
#' orientation under background knowledge.
#'
#' @param skel A [pcalg::pcAlgo-class] skeleton result.
#' @param knowledge A `Knowledge` object with tiers (and optionally edges).
#'
#' @example inst/roxygen-examples/tpdag-example.R
#'
#' @return A [pcalg::pcAlgo-class] object with an oriented graph.
#' @keywords internal
#' @noRd
tpdag <- function(skel, knowledge) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "pcalg"
    ),
    function_name = "tpdag"
  )
  cg <- caugi::as_caugi(skel@graph, collapse = TRUE, class = "UNKNOWN")
  amat <- caugi::as_adjacency(cg)
  skel_amat <- order_restrict_amat_cpdag(
    amat,
    knowledge = knowledge
  )
  pcalg::addBgKnowledge(
    v_orient_temporal(skel_amat, skel@sepset),
    checkInput = FALSE
  )
}

#' Construct sufficient statistics for built-in CI tests
#'
#' @description
#' Build the \emph{sufficient statistic} object expected by the built-in
#' conditional independence tests. Supports:
#' \itemize{
#'   \item \code{type = "reg_test"} - returns the original \code{data} and a
#'         logical indicator of which variables are binary;
#'   \item \code{type = "cor_test"} - returns a pairwise-complete correlation
#'         matrix and the sample size \code{n}.
#' }
#'
#' @param data A data frame (or numeric matrix) of variables used by the test.
#'   Columns are variables; rows are observations.
#' @param type A string selecting the test family. Must be either
#'   \code{"reg_test"} or \code{"cor_test"}.
#' @param ... currently ignored.
#'
#' @details
#' For \code{type = "reg_test"}, the return value is a list with elements:
#' \itemize{
#'   \item \code{data} - the original \code{data} object;
#'   \item \code{binary} - a logical vector (one per column) indicating whether
#'         the variable is binary.
#' }
#'
#' For \code{type = "cor_test"}, the return value is a list with elements:
#' \itemize{
#'   \item \code{C} - the correlation matrix computed with
#'         \code{use = "pairwise.complete.obs"};
#'   \item \code{n} - the number of rows in \code{data}.
#' }
#'
#' Any other \code{type} results in an error.
#'
#' @example inst/roxygen-examples/make_suff_stat-example.R
#'
#' @return A list whose structure depends on \code{type}, suitable for passing
#'   as \code{suff_stat} to the corresponding test.
#'
#' @keywords internal
#' @noRd
make_suff_stat <- function(data, type, ...) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "stats"
    ),
    function_name = "make_suff_stat"
  )

  if (type == "reg_test") {
    bin <- unlist(sapply(
      data,
      function(x) length(unique(stats::na.omit(x))) == 2
    ))
    suff <- list(data = data, binary = bin)
  } else if (type == "cor_test") {
    suff <- list(
      C = stats::cor(data, use = "pairwise.complete.obs"),
      n = nrow(data)
    )
  } else {
    stop(paste(
      type,
      "is not a supported type for autogenerating a sufficient statistic."
    ))
  }
  suff
}
