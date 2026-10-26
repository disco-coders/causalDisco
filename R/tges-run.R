# ──────────────────────────────────────────────────────────────────────────────
# ─────────────────────────── Public API  ──────────────────────────────────────
# ──────────────────────────────────────────────────────────────────────────────

#' Run the TGES Algorithm for Causal Discovery
#'
#' Perform causal discovery using the temporal greedy equivalence search algorithm.
#'
#' @param score tiered scoring object to be used.
#'    At the moment only scores supported are
#'    * [TemporalBIC] and
#'    * [TemporalBDeu].
#' @param verbose	indicates whether debug output should be printed.
#'
#' @author Tobias Ellegaard Larsen
#'
#' @example inst/roxygen-examples/tges-example.R
#'
#' @inheritSection disco_note Recommendation
#' @inheritSection disco_algs_return_doc_pdag Value
#'
#' @export
tges_run <- function(score, verbose = FALSE) {
  if (!inherits(score, c("TemporalBIC", "TemporalBDeu"))) {
    stop(
      "Score must be of type TemporalBIC or TemporalBDeu, ",
      "the only score criteria supported by tges at the moment.",
      call. = FALSE
    )
  }
  if (
    inherits(score, "TemporalBDeu") &&
      !all(vapply(score$pp.dat$data, is.factor, logical(1)))
  ) {
    stop(
      "When using TemporalBDeu, the data must be factors.",
      call. = FALSE
    )
  }
  if (anyNA(score$pp.dat$data)) {
    stop("Data must not contain missing values.", call. = FALSE)
  }
  node_numers <- 1:score$pp.dat$vertex.count
  essgraph <- new(
    "TEssGraph",
    nodes = as.character(node_numers),
    score = score
  )
  Forbidden.edges <- essgraph$.in.edges # all with integer(0) entry (list)
  node.names <- score$.nodes
  num.bidir <- 0
  num.directed <- 0

  ord <- score$.order
  for (n in node_numers) {
    Forbidden.edges[[n]] <- node_numers[ord[n] < ord]
  }
  cont <- TRUE
  update_phase <- function(phase, essgraph, Forbidden.edges, verbose) {
    runwhile <- TRUE
    while (runwhile) {
      tempstep <- essgraph$greedy_step(phase, verbose = verbose)
      runwhile <- as.logical(tempstep[1])

      if (!runwhile) {
        break
      }

      # mark that the overall loop should continue
      cont <<- TRUE

      for (i in names(tempstep[-1])) {
        in_node_edges <- tempstep[-1][[i]]
        forbidden_node_edges <- Forbidden.edges[[as.numeric(i)]]
        removed_edges <- in_node_edges[in_node_edges %in% forbidden_node_edges]

        if (length(removed_edges) > 0) {
          bgx <- rep(as.numeric(i), length(removed_edges))
          bgy <- removed_edges
          amatbg <- pcalg::addBgKnowledge(
            gInput = create_adj_matrix_from_list(essgraph$.in.edges),
            x = bgx,
            y = bgy,
            verbose = verbose
          )
          if (is.null(amatbg)) {
            stop(
              "addBgKnowledge() did not return a coercible graph/matrix.",
              call. = FALSE
            )
          }
          essgraph$.in.edges <- create_list_from_adj_matrix(amatbg)
        }
      }
    }
    essgraph
  }

  # Main loop
  while (cont) {
    cont <- FALSE
    for (phase in c("forward", "backward", "turning")) {
      essgraph <- update_phase(phase, essgraph, Forbidden.edges, verbose)
    }
  }

  essgraph$.nodes <- score$.nodes

  as_disco(essgraph)
}


# ──────────────────────────────────────────────────────────────────────────────
# ──────────────────────────── Helpers  ────────────────────────────────────────
# ──────────────────────────────────────────────────────────────────────────────

#' Create adjacency matrix from an in-edge list
#'
#' Converts a list of in-edges (parents) per node into a 0/1 adjacency matrix
#' with rows and columns ordered by the list names.
#'
#' @param input_list A named list of integer vectors; each element `input_list[[i]]`
#'   contains the indices of the parents of node `i`. Names must be the node
#'   labels in order.
#'
#' @example inst/roxygen-examples/create_adj_matrix_from_list_from_adj-example.R
#'
#' @return A numeric matrix with row and column names equal to `names(input_list)`,
#'   where entry `(i, j) = 1` iff `j` is a parent of `i`.
#'
#' @keywords internal
#' @noRd
create_adj_matrix_from_list <- function(input_list) {
  n <- length(input_list)
  result_matrix <- matrix(0, nrow = n, ncol = n)
  for (i in seq_along(input_list)) {
    indices <- input_list[[i]]
    valid_indices <- indices[indices <= n]
    if (length(valid_indices) > 0) {
      result_matrix[i, valid_indices] <- 1
    }
  }
  rownames(result_matrix) <- names(input_list)
  colnames(result_matrix) <- names(input_list)
  result_matrix
}

#' Create in-edge list from an adjacency matrix
#'
#' Converts a 0/1 adjacency matrix into a list where each element contains the
#' integer indices of the parents of the corresponding row/node.
#'
#' @param adj_matrix A square numeric matrix with row and column names giving
#'   node labels. Entry `(i, j) = 1` indicates an edge `j -> i`.
#'
#' @example inst/roxygen-examples/create_adj_matrix_from_list_from_adj-example.R
#'
#' @return A named list of integer vectors with one element per node; each
#'   element lists the parent indices (columns with value 1 in that row).
#'
#' @keywords internal
#' @noRd
create_list_from_adj_matrix <- function(adj_matrix) {
  n <- nrow(adj_matrix)
  result_list <- vector("list", n)
  names(result_list) <- rownames(adj_matrix)
  for (i in seq_len(n)) {
    connected_indices <- as.integer(which(adj_matrix[i, ] == 1))
    result_list[[i]] <- if (length(connected_indices) > 0) {
      connected_indices
    } else {
      integer(0)
    }
  }
  result_list
}

# ──────────────────────────────────────────────────────────────────────────────
# ───────────────────────── Graph / Score  ─────────────────────────────────────
# ──────────────────────────────────────────────────────────────────────────────

#' @title Temporal EssGraph class with greedy steps
#' @description
#' A `RefClass` extending `EssGraph` that exposes a single-step greedy move
#' (`forward`, `backward`, or `turning`) through `greedy_step()`. Used by
#' [tges_run] to iterate GIES one step at a time and interleave background
#' knowledge enforcement.
#'
#' @section Methods:
#' `greedy_step(direction = c("forward", "backward", "turning"), verbose = FALSE, ...)`
#' \itemize{
#'  \item `direction` Character; one of `"forward"`, `"backward"`, or `"turning"`,
#'   indicating which phase of GIES to perform a single step of.
#'  \item `verbose` Logical; indicates whether debug output should be printed.
#'  \item `...` Additional arguments passed to the underlying C++ function causalInference from pcalg.
#' }
#'
#' @seealso [tges_run], [TemporalBIC], [TemporalBDeu]
#' @importClassesFrom pcalg EssGraph
#' @importFrom methods new
#' @keywords internal
#' @noRd
TEssGraph <- setRefClass(
  "TEssGraph",
  contains = "EssGraph",
  methods = list(
    # Performs one greedy step
    greedy_step = function(
      direction = c("forward", "backward", "turning"),
      verbose = FALSE,
      ...
    ) {
      score <- getScore()
      stopifnot(!is.null(score))

      # Cast direction
      direction <- match.arg(direction)
      alg_name <- switch(
        direction,
        forward = "GIES-F",
        backward = "GIES-B",
        turning = "GIES-T"
      )

      new_graph <- .Call(
        causalInference,
        .in.edges,
        score$pp.dat,
        alg_name,
        "none",
        causal.inf.options(
          caching = FALSE,
          maxSteps = 1,
          verbose = verbose,
          ...
        )
      )
      if (identical(new_graph, "interrupt")) {
        return(FALSE)
      }

      if (new_graph$steps > 0) {
        last.edges <- .in.edges
        .in.edges <<- new_graph$in.edges
        names(.in.edges) <<- .nodes

        new_in.edges <- .in.edges[sapply(names(.in.edges), function(x) {
          !identical(.in.edges[[x]], last.edges[[x]])
        })]
      } else {
        new_in.edges <- list()
      }

      c((new_graph$steps == 1), new_in.edges)
    }
  ),
  inheritPackage = TRUE
)

#' Temporal Bayesian Information Criterion (Score criterion)
#'
#' A Reference Class for Gaussian Observational Data Scoring with Tiered
#' Background Knowledge. This class represents a score for causal discovery
#' using tiered background knowledge from observational Gaussian
#' data; it is used in the causal discovery function [tges()].
#'
#' The class implements a score which scores all edges contradicting the ordering
#' (edge going from a later tier to an earlier) to minus \eqn{\infty}{∞}. If the
#' edges do not contradict, the score is equal to that of the standard BIC.
#' The class implements an \eqn{\ell_0}{ℓ0}-penalized Gaussian maximum
#' likelihood estimator. The penalization is a constant (specified by
#' the argument \code{lambda} in the constructor) times the number of
#' parameters of the DAG model. By default, the constant \eqn{\lambda}{λ} is
#' chosen as \eqn{\log(n)/2}{log(n)/2}, which corresponds to the BIC score.
#'
#' @section Extends:
#' Class \code{GaussL0penObsScore} from \pkg{pcalg}, directly.
#'
#' All reference classes extend and inherit methods from \code{\linkS4class{envRefClass}}.
#'
#' @section Constructor:
#' \preformatted{
#' new(
#'  "TemporalBIC",
#'  data = matrix(1, 1, 1),
#'  order =  rep(1,ncol(data)),
#'  lambda = 0.5 * log(nrow(data)),
#'  intercept = TRUE,
#'  ...
#' )
#' }
#'
#' @param data A numeric matrix with \eqn{n} rows and \eqn{p} columns. Each row
#' corresponds to one observational realization.
#' @param nodes A character vector of variable names corresponding to the columns of the data.
#' @param lambda Penalization constant (see details).
#' @param intercept Logical; indicates whether an intercept is allowed in the
#' linear structural equations (i.e., whether a nonzero mean is allowed).
#' @param format Character; either "raw" or "scatter". If "raw", the score is calculated
#' from the raw data matrix. If "scatter", the score is calculated from pre-calculated scatter matrices.
#' @param knowledge A `Knowledge` object.
#' @param debug Logical; indicates whether to perform validation of the vertex and parents in every local score
#' calculation. Setting this to TRUE will slow down the algorithm, but may be useful for debugging.
#'
#' @author Tobias Ellegaard Larsen
#'
#' @example inst/roxygen-examples/tbic-example.R
#'
#' @seealso [tges()]
#'
#' @importClassesFrom pcalg GaussL0penIntScore
#'
#' @keywords internal
TemporalBIC <- setRefClass(
  "TemporalBIC",
  contains = "GaussL0penIntScore",
  fields = list(
    .order = "vector",
    debug = "logical"
  ),
  methods = list(
    initialize = function(
      data = NULL,
      nodes = colnames(data),
      lambda = 0.5 * log(nrow(data)),
      intercept = TRUE,
      format = c("raw", "scatter"),
      knowledge = NULL,
      debug = FALSE,
      ...
    ) {
      debug <<- debug

      if (is.null(knowledge)) {
        knowledge <- knowledge() |> add_vars(nodes)
      }

      # `:::` is required: Reference Class methods are evaluated in the object
      # environment, which does not see unexported package functions.
      causalDisco:::is_knowledge(knowledge)

      .order <<- causalDisco:::.tier_index(knowledge, nodes)

      callSuper(
        data = data,
        targets = list(integer(0)),
        target.index = rep(as.integer(1), nrow(data)),
        nodes = nodes,
        lambda = lambda,
        intercept = intercept,
        format = format,
        ...
      )
    },
    local.score = function(vertex, parents, ...) {
      # When profiling it was expensive to validate the vertex and parents in every local score calculation,
      # so only do it when debug = TRUE
      if (debug) {
        validate.vertex(vertex)
        validate.parents(parents)
      }

      ord <- .order
      child_t <- ord[vertex]
      parent_ts <- ord[parents]

      # do not enforce if child or any parent lacks a tier (NA)
      if (
        is.na(child_t) ||
          anyNA(parent_ts) ||
          child_t >= max(c(parent_ts, -Inf))
      ) {
        # calculate score in R
        if (.format == "raw") {
          # calculate score from raw data matrix
          # response vector for linear regression
          Y <- pp.dat$data[pp.dat$non.int[[vertex]], vertex]
          sigma2 <- sum(Y^2)

          if (length(parents) + pp.dat$intercept != 0) {
            # get data matrix on which linear regression is based
            Z <- pp.dat$data[pp.dat$non.int[[vertex]], parents, drop = FALSE]
            if (pp.dat$intercept) {
              Z <- cbind(1, Z)
            }

            # calculate the scaled error covariance using QR decomposition
            Q <- qr.Q(qr(Z))
            sigma2 <- sigma2 - sum((Y %*% Q)^2)
          }
        } else if (.format == "scatter") {
          # calculate the score based on pre-calculated scatter matrices
          # if an intercept is allowed, add a fake parent node
          if (length(parents) > 1) {
            parents <- sort(parents) # TODO: Figure out how to avoid sorting in every local score calculation
          }
          if (pp.dat$intercept) {
            parents <- c(pp.dat$vertex.count + 1, parents)
          }

          pd.scMat <- pp.dat$scatter[[pp.dat$scatter.index[vertex]]]
          sigma2 <- pd.scMat[vertex, vertex]
          if (length(parents) != 0) {
            b <- pd.scMat[vertex, parents]
            sigma2 <- sigma2 -
              as.numeric(b %*% solve(pd.scMat[parents, parents], b))
          }
        }

        # return local score
        lscore <- -0.5 *
          pp.dat$data.count[vertex] *
          (1 + log(sigma2 / pp.dat$data.count[vertex])) -
          pp.dat$lambda * (1 + length(parents))

        lscore
      } else {
        -Inf
      } # set score to minus infinity if vertex earlier than parents
    }
  ),
  inheritPackage = TRUE
)

#' Temporal Bayesian Dirichlet equivalent uniform (Score criterion)
#'
#' A reference class for categorical observational data Scoring with Tiered
#' Background Knowledge. This class represents a score for causal discovery
#' using tiered background knowledge from observational categorical
#' data; it is used in the causal discovery function [tges()].
#'
#' The class implements a score which scores all edges contradicting the ordering
#' (edge going from a later tier to an earlier) to minus \eqn{\infty}{∞}. If the
#' edges do not contradict, the score is equal to that of the standard BDeu.
#'
#' @section Extends:
#' Class \code{Score-class} from \pkg{pcalg}, directly.
#'
#' All reference classes extend and inherit methods from \code{\linkS4class{envRefClass}}.
#'
#' @section Constructor:
#' \preformatted{
#' new(
#'  "TemporalBdeu",
#'  data = matrix(1, 1, 1),
#'  order =  rep(1,ncol(data)),
#'  iss = 1
#'  ...
#' )
#' }
#'
#' @param data A numeric matrix with \eqn{n} rows and \eqn{p} columns. Each row
#' corresponds to one observational realization.
#' @param nodes A character vector of variable names corresponding to the columns of the data.
#' @param iss Imaginary Sample Size (ISS), also referred to as
#' Equivalent Sample Size (ESS), determines how much weight is assigned to the prior
#' in terms of the size of an imaginary sample supporting it. Increasing the ISS will
#' increase the density of the estimated graph.
#' @param knowledge A `Knowledge` object.
#' @param debug Logical; indicates whether to perform validation of the vertex and parents in every local score
#' calculation. Setting this to TRUE will slow down the algorithm, but may be useful for debugging.
#'
#' @author Tobias Ellegaard Larsen
#'
#' @example inst/roxygen-examples/tbdeu-example.R
#'
#' @seealso [tges()]
#'
#' @importClassesFrom pcalg Score
#'
#' @keywords internal
TemporalBDeu <- setRefClass(
  "TemporalBDeu",
  contains = "DataScore",
  fields = list(
    .order = "vector",
    .iss = "numeric",
    debug = "logical"
  ),
  methods = list(
    initialize = function(
      data = matrix(1, 1, 1),
      nodes = colnames(data),
      iss = 1,
      knowledge = NULL,
      debug = FALSE,
      ...
    ) {
      if (is.null(knowledge)) {
        knowledge <- knowledge() |> add_vars(nodes)
      }

      # `:::` is required: Reference Class methods are evaluated in the object
      # environment, which does not see unexported package functions.
      causalDisco:::is_knowledge(knowledge)

      .order <<- causalDisco:::.tier_index(knowledge, nodes)
      .iss <<- iss
      debug <<- debug

      callSuper(
        data = data,
        nodes = nodes,
        iss = iss,
        ...
      )
    },
    local.score = function(vertex, parents, ...) {
      # When profiling it was expensive to validate the vertex and parents in every local score calculation,
      # so only do it when debug = TRUE
      if (debug) {
        validate.vertex(vertex)
        validate.parents(parents)
      }
      ord <- .order
      iss <- .iss
      child_t <- ord[vertex]
      parent_ts <- ord[parents]

      # do not enforce if child or any parent lacks a tier (NA)
      if (
        is.na(child_t) ||
          anyNA(parent_ts) ||
          child_t >= max(c(parent_ts, -Inf))
      ) {
        D <- pp.dat$data[, c(vertex, parents), drop = FALSE]
        pa_nam <- colnames(pp.dat$data)[parents]
        ve_nam <- colnames(pp.dat$data)[vertex]

        if (length(parents) == 0) {
          # number of possible configurations of states of parents
          q <- 1

          # number of states for vertex
          r <- nlevels(D[[ve_nam]])

          alpha_j <- iss

          # set pa_score to 0
          pa_score <- lgamma(alpha_j) - lgamma(alpha_j + nrow(D))
        } else {
          # number of in variables
          nlev_D <- sapply(D[, c(ve_nam, pa_nam)], nlevels)

          # number of possible configurations of states of parents
          q <- prod(nlev_D[pa_nam])

          # number of states for vertex
          r <- nlev_D[ve_nam]

          # table with number of occurences for parents and parents combinations
          tab_pa <- as.data.frame(table(D[, c(pa_nam)]))

          alpha_j <- iss / q

          pa_score <- nrow(tab_pa) *
            lgamma(alpha_j) -
            sum(sapply(tab_pa$Freq, function(x) lgamma(alpha_j + x)))
        }

        # table with number of occurences and state combinations
        tab_D <- as.data.frame(table(D))

        # uniform prior with alpha according to imaginary sample size (iss)
        alpha_jk <- alpha_j / r

        constant <- nrow(tab_D) * lgamma(alpha_jk) + pa_score
        BdeuScore <- sum(
          sapply(
            tab_D$Freq,
            function(x) lgamma(alpha_jk + x)
          )
        ) -
          constant

        BdeuScore
      } else {
        -Inf
      }
    }
  ),
  inheritPackage = TRUE
)
