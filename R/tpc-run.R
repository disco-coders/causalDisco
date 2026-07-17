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
#' @param directed_as_undirected Logical; if \code{TRUE}, treat any directed
#'   edges in \code{knowledge} as undirected during skeleton learning. This
#'   is due to the fact that \pkg{pcalg} does not allow directed edges in
#'   \code{fixedEdges} or \code{fixedGaps}. Default is \code{FALSE}.
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
  directed_as_undirected = FALSE,
  varnames = NULL,
  num_cores = 1,
  ...
) {
  prep <- constraint_based_prepare_inputs(
    data = data,
    knowledge = knowledge,
    varnames = varnames,
    na_method = na_method,
    test = test,
    suff_stat = suff_stat,
    directed_as_undirected = directed_as_undirected,
    function_name = "tpc"
  )

  # unpack returned values
  data <- prep$data
  knowledge <- prep$knowledge
  vnames <- prep$vnames
  suff_stat <- prep$suff_stat
  na_method <- prep$na_method
  directed_as_undirected <- prep$directed_as_undirected
  test <- prep$internal_test # Ensure we use the internal test with camelCase so it works downstream with pcalg

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
    labels = vnames,
    directed_as_undirected = directed_as_undirected
  )

  # learn skeleton
  skel <- pcalg::skeleton(
    suffStat = suff_stat,
    indepTest = indep_test_dir,
    alpha = alpha,
    labels = vnames,
    method = method,
    fixedGaps = constraints$fixed_gaps,
    fixedEdges = constraints$fixed_edges,
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
#' Turn directed forbidden/required edges into undirected \code{fixedGaps} and
#' \code{fixedEdges} matrices in the supplied \code{labels} order. Tier
#' annotations are ignored here; use \code{order_restrict_amat_cpdag()} for
#' tier-based pruning.
#'
#' @param kn A `Knowledge` object.
#' @param labels Character vector of variable names in the desired order.
#'
#' @example inst/roxygen-examples/dot-pcalg_constraints_from_knowledge-example.R
#'
#' @return A list with logical matrices \code{fixedGaps} and \code{fixedEdges}.
#' @keywords internal
#' @noRd
.pcalg_constraints_from_knowledge <- function(
  kn,
  labels,
  directed_as_undirected
) {
  kn_undirected <- kn
  kn_undirected$vars$tier <- NA_character_
  as_pcalg_constraints(
    kn_undirected,
    labels = labels,
    directed_as_undirected = TRUE
  )
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
