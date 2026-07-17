#' @title Perform Causal Discovery
#'
#' @description
#' Apply a causal discovery method to a data frame to infer causal relationships on observational data.
#' Supports multiple algorithms and optionally incorporates prior knowledge.
#'
#' @param data A data frame.
#' @param method A `disco_method` object representing a causal discovery
#' algorithm. Available methods are
#' \itemize{
#'  \item [boss()] - BOSS algorithm,
#'  \item [boss_fci()] - BOSS-FCI algorithm,
#'  \item [fci()] - FCI algorithm,
#'  \item [gfci()] - GFCI algorithm,
#'  \item [ges()] - GES algorithm,
#'  \item [grasp()] - GRaSP algorithm,
#'  \item [grasp_fci()] - GRaSP-FCI algorithm,
#'  \item [gs()] - GS algorithm,
#'  \item [iamb()], [iamb_fdr()], [fast_iamb()], [inter_iamb()] - IAMB algorithms,
#'  \item [pc()] - PC algorithm,
#'  \item [sp_fci()] - SP-FCI algorithm,
#'  \item [tfci()] - TFCI algorithm,
#'  \item [tges()] - TGES algorithm,
#'  \item [tpc()] - TPC algorithm.
#' }
#' @param knowledge A `Knowledge` object to be incorporated into the causal discovery algorithm.
#'  If `NULL` (default), the causal discovery algorithm is run without background knowledge. See [knowledge()]
#'  for how to create a `Knowledge` object.
#'
#' @details
#' For specific details on the supported algorithms, scores, tests, and parameters for each engine, see:
#' \itemize{
#'  \item [BnlearnSearch] for \pkg{bnlearn},
#'  \item [CausalDiscoSearch] for \pkg{causalDisco},
#'  \item [PcalgSearch] for \pkg{pcalg},
#'  \item [TetradSearch] for \pkg{Tetrad}.
#' }
#'
#' @example inst/roxygen-examples/disco-example.R
#'
#' @returns
#' A `Disco` object (a list) containing the following components:
#' \itemize{
#'   \item `knowledge` A `Knowledge` object with the background knowledge
#'   used in the causal discovery algorithm.
#'   \item `caugi` A [caugi::caugi] object representing the learned causal graph from the causal discovery algorithm.
#'   \item `graph_type` A string with the semantic class of the learned graph
#'   (e.g. `"CPDAG"`, `"MPDAG"`, or `"PAG"`).
#' }
#'
#' Constraint-based algorithms may output graphs that are not valid CPDAGs/MPDAGs due to statistical errors in finite
#' samples, violations of faithfulness, or latent confounding. In that case `disco()` emits a message and downgrades
#' `graph_type`.
#' @export
disco <- function(data, method, knowledge = NULL) {
  engine <- attr(method, "engine")
  method_graph_class <- attr(method, "graph_class")
  graph_class <- method_graph_class

  if (is.null(graph_class)) {
    graph_class <- "UNKNOWN"
  }

  if (graph_class == "PAG" || graph_class == "RFCI-PAG") {
    # caugi currently does not support PAGs or RFCI-PAGs
    graph_class <- "UNKNOWN"
  }

  if (!inherits(method, "disco_method")) {
    stop("The method must be a disco method object.", call. = FALSE)
  }
  check_method_knowledge_bug(method, knowledge)

  if (engine == "causalDisco" && any(knowledge$edges$status == "required")) {
    warning(
      "causalDisco engine does not support required edges in knowledge. ",
      "These will be ignored.",
      call. = FALSE
    )
  }

  # inject knowledge via S3 generic
  if (!is.null(knowledge)) {
    is_knowledge(knowledge)
    tryCatch(
      {
        method <- set_knowledge(method, knowledge)
      },
      error = function(e) {
        # extra precaution to catch errors in setting knowledge
        stop("Error in setting knowledge: ", e$message, call. = FALSE) # nocov
      }
    )
  }
  out <- method(data)

  if (!is.null(out$caugi)) {
    out$caugi <- tryCatch(
      {
        caugi::mutate_caugi(out$caugi, graph_class)
      },
      error = function(e) {
        detail <- ""
        if (identical(graph_class, "PDAG")) {
          detail <- paste0(
            " The graph is not a valid PDAG (it may contain a directed cycle ",
            "or bidirected conflict edges)."
          )
        }
        warning(
          sprintf(
            "Cannot mutate graph to class '%s'.%s",
            graph_class,
            detail
          ),
          call. = FALSE
        )
        out$caugi
      }
    )
  }

  if (!is.null(knowledge)) {
    out <- set_knowledge(out, knowledge)
  }

  # Record the semantic graph class so that print.Disco can report the actual
  # class the algorithm produced. The claimed class (CPDAG/MPDAG) is verified
  # against the graph and downgraded to "PDAG" with a message if it does not
  # hold (e.g. finite-sample conflicts or contradictory background knowledge).
  has_knowledge <- .knowledge_has_content(knowledge)
  claimed_type <- .disco_graph_type(method_graph_class, has_knowledge)
  out$graph_type <- if (!is.null(out$caugi)) {
    .validate_graph_type(out$caugi, claimed_type, has_knowledge)
  } else {
    claimed_type
  }
  out
}
