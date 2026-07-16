# ──────────────────────────────────────────────────────────────────────────────
# ─────────────────────────── Public API  ──────────────────────────────────────
# ──────────────────────────────────────────────────────────────────────────────

#' Run the TFCI Algorithm for Causal Discovery
#'
#' Use a modification of the FCI algorithm that makes use of background knowledge
#' in the format of a partial ordering. This may, for instance, come about when
#' variables can be assigned to distinct tiers or periods (i.e., a temporal ordering).
#'
#' @details
#' The temporal/tiered background information enters several places in the TFCI
#' algorithm: (1) In the skeleton construction phase, when looking for separating
#' sets \eqn{Z} between two variables \eqn{X} and \eqn{Y}, \eqn{Z} is not allowed to
#' contain variables that are strictly after both \eqn{X} and \eqn{Y} in the temporal
#' order (as specified by the \code{knowledge} tiers). (2) This also applies to the
#' subsequent phase where the algorithm searches for possible D-SEP sets. (3) Prior
#' to other orientation steps, any cross-tier edges get an arrowhead placed at their
#' latest node.
#'
#' After this, the usual FCI orientation rules are applied; see [pcalg::udag2pag()]
#' for details.
#'
#' @inheritParams tpc_run
#' @param knowledge A `Knowledge` object describing tiers/periods and optional
#'   forbidden/required edges.
#' @param orientation_method Method for handling conflicting separating sets when orienting
#'   edges; must be one of \code{"standard"}, \code{"conservative"} (the default) or
#'   \code{"maj.rule"}. See [pcalg::pc()] for further details.
#'
#' @inheritSection disco_note Recommendation
#' @inheritSection disco_algs_return_doc_pag Value
#'
#' @example inst/roxygen-examples/tfci-example.R
#'
#' @importClassesFrom pcalg pcAlgo
#' @export
tfci_run <- function(
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
      what = "tfci_run(directed_as_undirected)",
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
    function_name = "tfci"
  )

  # unpack returned values
  data <- prep$data
  knowledge <- prep$knowledge
  vnames <- prep$vnames
  suffStat <- prep$suff_stat
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
    suffStat = suffStat,
    indepTest = indep_test_dir,
    alpha = alpha,
    labels = vnames,
    method = method,
    fixedGaps = constraints$fixed_gaps,
    numCores = num_cores,
    ...
  )
  ntests <- sum(skel@n.edgetests)

  # pdsep step: expand to MAG/PAG skeleton
  nvar <- length(skel@graph@nodes)
  fci_skel <- pcalg::pdsep(
    skel = skel,
    suffStat = suffStat,
    indepTest = indep_test_dir,
    p = nvar,
    sepset = skel@sepset,
    pMax = skel@pMax,
    unfVect = c(),
    alpha = alpha
  )
  nextratests <- fci_skel$n.edgetests
  ntests <- ntests + nextratests

  # optional conservative / majority-rule orientation info
  conservative <- identical(orientation_method, "conservative")
  maj_rule <- identical(orientation_method, "maj.rule")
  unfaithful_triples <- NULL

  if (conservative || maj_rule) {
    tmp <- methods::new(
      "pcAlgo",
      graph = as.graphNEL(t(fci_skel$G)),
      call = skel@call,
      n = integer(0),
      max.ord = as.integer(fci_skel$max.ord),
      n.edgetests = nextratests,
      sepset = fci_skel$sepset,
      pMax = fci_skel$pMax,
      zMin = matrix(NA, 1, 1)
    )
    tmpres <- pcalg::pc.cons.intern(
      tmp,
      suffStat = suffStat,
      indepTest = indep_test_dir,
      alpha = alpha,
      version.unf = c(1, 1),
      maj.rule = maj_rule
    )
    unfaithful_triples <- tmpres$unfTripl
    fci_skel$sepset <- tmpres$sk@sepset
  }

  # orient into a PAG using knowledge tiers
  res <- tpag(
    fci_skel,
    knowledge = knowledge,
    unfaithful_triples = unfaithful_triples
  )
  cg <- caugi::as_caugi(res, collapse = TRUE, class = "PAG")

  as_disco(cg, knowledge)
}

# ──────────────────────────────────────────────────────────────────────────────
# ──────────────────────────── Helpers  ────────────────────────────────────────
# ──────────────────────────────────────────────────────────────────────────────

#' Order-restrict a PAG skeleton by temporal knowledge
#'
#' Given a PAG adjacency matrix (with entries \code{0} = none, \code{1} = circle,
#' \code{2} = arrowhead, \code{3} = tail; indexed as \code{[from, to]} in the pcalg
#' convention), enforce temporal constraints implied by \code{knowledge}: whenever
#' an edge crosses tiers, place an arrowhead at the later node.
#'
#' @param amat A square numeric adjacency matrix in pcalg PAG format
#'   (rows/columns named by variable names).
#' @param knowledge A `Knowledge` object that provides tier labels for variables.
#'
#' @example inst/roxygen-examples/order_restrict_pag_skel-example.R
#'
#' @return The modified adjacency matrix with arrowheads added at the later node
#'   for cross-tier pairs.
#' @keywords internal
#' @noRd
order_restrict_pag_skel <- function(amat, knowledge) {
  vr <- knowledge$.__var_rank
  p <- nrow(amat)
  vnames <- rownames(amat)

  for (i in seq_len(p)) {
    for (j in seq_len(p)) {
      if (amat[j, i] != 0) {
        x_rank <- vr[[vnames[i]]]
        y_rank <- vr[[vnames[j]]]

        if (!is.na(x_rank) && !is.na(y_rank) && x_rank > y_rank) {
          # Place an arrowhead at the later node
          amat[j, i] <- 2
          # Note: [i,j] stays as-is (typically 1: circle) in the skeleton
        }
      }
    }
  }
  amat
}

#' Remove illegal separating sets under temporal knowledge
#'
#' Given a \code{sepset} structure (as used by \pkg{pcalg}) and temporal background
#' knowledge, drop any separating set that conditions on a variable strictly after
#' both endpoints.
#'
#' @param sepset A nested list of separating sets, typically \code{skel@sepset}
#'   from \pkg{pcalg}, where \code{sepset[[i]][[j]]} is a vector of node indices
#'   that separate node \code{i} and node \code{j}, or \code{NULL}.
#' @param knowledge A `Knowledge` object that provides tier labels for variables.
#' @param vnames Character vector of variable names, used to translate indices in
#'   \code{sepset} into names for tier comparison.
#'
#' @example inst/roxygen-examples/order_restrict_sepset-example.R
#'
#' @return The input \code{sepset} with any disallowed separating sets replaced by
#'   \code{NULL}. Emits a warning each time such a set is removed.
#' @keywords internal
#' @noRd
order_restrict_sepset <- function(sepset, knowledge, vnames) {
  vr <- knowledge$.__var_rank
  p <- length(vnames)

  for (i in seq_len(p)) {
    for (j in seq_len(p)) {
      sep_set <- sepset[[i]][[j]]
      if (length(sep_set) > 0) {
        x_rank <- vr[[vnames[i]]]
        y_rank <- vr[[vnames[j]]]

        if (!is.na(x_rank) && !is.na(y_rank)) {
          for (k in seq_along(sep_set)) {
            s_rank <- vr[[vnames[sep_set[k]]]]
            if (!is.na(s_rank) && s_rank > x_rank && s_rank > y_rank) {
              sepset[[i]][[j]] <- NULL
              warning(
                "Found sepset that was not allowed due to temporal order!"
              )
              break
            }
          }
        }
      }
    }
  }
  sepset
}

#' Orient a PAG from a skeleton using temporal knowledge
#'
#' Apply temporal restrictions and standard FCI orientation rules to produce a PAG.
#' Cross-tier edges receive an arrowhead at the later node and separating sets that
#' condition on the future are dropped (if \code{cautious = TRUE}) before calling
#' [pcalg::udag2pag()].
#'
#' @param skel A skeleton-like object as returned by [pcalg::pdsep()],
#'   containing \code{$G} (adjacency), \code{$sepset}, \code{$pMax}, and
#'   \code{$max.ord}.
#' @param knowledge A `Knowledge` object that provides tier labels for variables.
#' @param unfaithful_triples Optional vector of unfaithful triples from conservative/majority-rule
#'   orientation (see \pkg{pcalg} under \code{unfVect}); may be \code{NULL}.
#' @param cautious Logical; if \code{TRUE}, remove any separating set that violates
#'   temporal constraints before orientation.
#'
#' @example inst/roxygen-examples/tpag-example.R
#'
#' @return A PAG adjacency matrix in pcalg format (integer codes \code{0/1/2/3}).
#' @keywords internal
#' @noRd
tpag <- function(skel, knowledge, unfaithful_triples, cautious = TRUE) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "pcalg"
    ),
    function_name = "tpag"
  )

  # boolean amat -> add 0 converts to numeric
  amat <- order_restrict_pag_skel(skel$G + 0, knowledge = knowledge)
  sepsets <- skel$sepset

  # orientation rules to use (skip 5–7: selection bias rules)
  use_rules <- rep(TRUE, 10)
  use_rules[5:7] <- FALSE

  if (cautious) {
    sepsets <- order_restrict_sepset(
      sepsets,
      knowledge = knowledge,
      vnames = rownames(skel$G)
    )
  }

  pcalg::udag2pag(
    amat,
    sepset = sepsets,
    rules = use_rules,
    unfVect = unfaithful_triples
  )
}
