#' Generate Synthetic Data from a Linear Gaussian DAG
#'
#' Generates synthetic data from a directed acyclic graph (DAG) specified as a
#' `caugi` graph object. Each node is modeled as a linear combination of its
#' parents plus additive Gaussian noise. Coefficients are randomly signed with
#' a minimum absolute value, and noise standard deviations are sampled
#' log-uniformly from a specified range. Custom node equations can override
#' automatic linear generation.
#'
#' @param cg A `caugi` graph object representing a DAG.
#' @param n Integer. Number of observations to simulate.
#' @param ... Optional named node equations to override automatic linear generation.
#'   Each should be an expression referencing all parent nodes.
#' @param standardize Logical. If `TRUE`, each column of the output is standardized
#'   to mean 0 and standard deviation 1.
#' @param coef_range Numeric vector of length 2 specifying the minimum and maximum
#'   absolute value of edge coefficients. For each edge, an absolute value is sampled
#'   uniformly from this range and then assigned a positive or negative sign with equal
#'   probability. Must satisfy `coef_range[1] > 0` and `coef_range[2] >= coef_range[1]`.
#' @param error_sd Numeric vector of length 2 specifying the minimum and maximum
#'   standard deviation of the additive Gaussian noise at each node. For each node,
#'   a standard deviation is sampled from a log-uniform distribution over this range.
#'   Must satisfy `error_sd[1] > 0` and `error_sd[2] >= error_sd[1]`.
#' @param seed Optional integer. Sets the random seed for reproducibility.
#'
#' @return A `tibble` of simulated data with one column per node in the DAG,
#'   ordered according to the graph's node order. Standardization is applied
#'   if `standardize = TRUE`.
#'
#'   The returned tibble has an attribute `generating_model`, which is a list containing:
#'   \itemize{
#'     \item `sd`: Named numeric vector of node-specific noise standard deviations.
#'     \item `coef`: Named list of numeric vectors, where each element corresponds
#'       to a child node. For a child node, the vector stores the coefficients of
#'       its parent nodes in the linear structural equation. That is:
#'       \code{generating_model$coef[[child]][parent]} gives the coefficient
#'       of \code{parent} in the equation for \code{child}.
#'   }
#'
#' @examples
#' cg <- caugi::caugi(A %-->% B, B %-->% C, A %-->% C, class = "DAG")
#'
#' # Simulate 1000 observations
#' sim_data <- sim_data(
#'   cg,
#'   n = 1000,
#'   coef_range = c(0.2, 0.8),
#'   error_sd = c(0.5, 1.5)
#' )
#'
#' head(sim_data)
#' attr(sim_data, "generating_model")
#'
#' # Simulate with custom equation for node C
#' sim_data_custom <- sim_data(
#'   cg,
#'   n = 1000,
#'   C = A^2 + B + rnorm(n, sd = 0.7),
#'   seed = 1405
#' )
#' head(sim_data_custom)
#' attr(sim_data_custom, "generating_model")
#' @export
sim_data <- function(
  cg,
  n,
  ...,
  standardize = TRUE,
  coef_range = c(0.1, 0.9),
  error_sd = c(0.3, 2),
  seed = NULL
) {
  caugi::is_caugi(cg, throw_error = TRUE)
  if (cg@graph_class != "DAG") {
    stop(
      "`simulate_data` currently only supports DAGs. ",
      "Graph class is: ",
      cg@graph_class,
      call. = FALSE
    )
  }
  cg <- caugi::build(cg)
  if (caugi::is_empty_caugi(cg)) {
    stop("Cannot simulate data from an empty graph", call. = FALSE)
  }

  if (!is.null(seed)) {
    set.seed(seed)
  }

  n <- as.integer(n)
  checkmate::assert_int(n, lower = 1)

  checkmate::assert_numeric(coef_range, len = 2, lower = 0, any.missing = FALSE)
  checkmate::assert_true(coef_range[2] >= coef_range[1])

  checkmate::assert_numeric(error_sd, len = 2, lower = 0, any.missing = FALSE)
  checkmate::assert_true(error_sd[2] >= error_sd[1])

  # capture custom equations
  equations <- as.list(substitute(list(...)))[-1L]
  node_order <- caugi::topological_sort(cg)
  node_names <- caugi::nodes(cg)$name

  eq_names <- names(equations)
  if (length(eq_names) > 0L) {
    unknown <- setdiff(eq_names, node_names)
    if (length(unknown) > 0L) {
      stop(
        "Unknown node(s) in equations: ",
        paste(unknown, collapse = ", "),
        call. = FALSE
      )
    }
  }

  env <- new.env(parent = parent.frame())
  env$n <- n

  data <- vector("list", length(node_order))
  names(data) <- node_order

  model <- list(
    dgp = list()
  )

  sample_coef <- function(n, min_abs, max_abs) {
    sign <- sample(c(-1, 1), n, TRUE)
    magnitude <- stats::runif(n, min_abs, max_abs)
    sign * magnitude
  }

  make_expr <- function(signal_expr = NULL, sd_node) {
    # Round numeric values for printing
    sd_node <- round(sd_node, 3)
    if (is.null(signal_expr) || signal_expr == "") {
      # no signal, just noise
      parse(text = paste0("rnorm(n, sd=", sd_node, ")"))[[1]]
    } else {
      # signal + noise
      parse(text = paste0(signal_expr, " + rnorm(n, sd=", sd_node, ")"))[[1]]
    }
  }

  for (node in node_order) {
    pa <- caugi::parents(cg, node)
    if (is.null(pa)) {
      pa <- character(0)
    }

    # log-uniform SD
    sd_node <- exp(stats::runif(1L, log(error_sd[1]), log(error_sd[2])))

    if (node %in% eq_names) {
      # custom equation
      for (p in pa) {
        env[[p]] <- data[[p]]
      }
      data[[node]] <- eval(equations[[node]], env)
      model$dgp[[node]] <- equations[[node]]
    } else {
      if (length(pa) == 0L) {
        data[[node]] <- stats::rnorm(n, sd = sd_node)
        model$dgp[[node]] <- make_expr(NULL, sd_node) # Only noise, no sd=0 term
      } else {
        coefs <- sample_coef(length(pa), coef_range[1], coef_range[2])
        pa_mat <- do.call(cbind, data[pa])
        signal <- as.vector(pa_mat %*% coefs)
        data[[node]] <- signal + stats::rnorm(n, sd = sd_node)

        # Create readable signal part
        terms <- paste(pa, round(coefs, 3), sep = "*")
        signal_expr <- paste(terms, collapse = " + ")
        model$dgp[[node]] <- make_expr(signal_expr, sd_node)
      }
    }
  }

  out <- tibble::as_tibble(data)[, node_names, drop = FALSE]

  if (standardize) {
    out <- dplyr::mutate(
      out,
      dplyr::across(
        dplyr::everything(),
        ~ (.x - mean(.x)) / stats::sd(.x)
      )
    )
  }

  attr(out, "generating_model") <- model
  out
}

#' Generate Synthetic Data from a Linear Gaussian DAG
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' This function has been renamed to [sim_data()] instead.
#' @keywords internal
#' @export
generate_dag_data <- function(
  cg,
  n,
  ...,
  standardize = TRUE,
  coef_range = c(0.1, 0.9),
  error_sd = c(0.3, 2),
  seed = NULL
) {
  lifecycle::deprecate_warn(
    when = "1.2.0",
    what = "generate_dag_data()",
    with = "sim_data()"
  )

  sim_data(
    cg = cg,
    n = n,
    ...,
    standardize = standardize,
    coef_range = coef_range,
    error_sd = error_sd,
    seed = seed
  )
}

#' Simulate a Random DAG
#'
#' Simulates a random directed acyclic graph adjacency (DAG) matrix with `n` nodes
#' and either `m` edges, edge creation probability `p`, or edge creation
#' probability range `p_range`.
#'
#' @param n The number of nodes.
#' @param m Integer in `0, n*(n-1)/2`. Number of edges in the graph. Exactly one
#' of `m` or `p` must be supplied.
#' @param p Numeric in `[0,1]`. Probability of edge creation. Exactly one of
#' `m` or `p` must be supplied.
#'
#' @returns The sampled `caugi` object.
#' @examples
#' # Simulate a DAG with 5 nodes and 3 edges
#' sim_dag(n = 5, m = 3)
#'
#' # Simulate a DAG with 5 nodes and edge creation probability of 0.2
#' sim_dag(n = 5, p = 0.2)
#'
#' @seealso [caugi::generate_graph()]
#' @export
sim_dag <- function(
  n,
  m = NULL,
  p = NULL
) {
  # Check only one of m, p, p_range is supplied
  n_args_supplied <- sum(!sapply(list(m, p), is.null))

  if (n_args_supplied != 1) {
    stop("Exactly one of 'm' or 'p' must be supplied.")
  }
  checkmate::assert_int(n, lower = 1)
  checkmate::assert(
    checkmate::check_null(m),
    checkmate::check_int(m, lower = 0, upper = n * (n - 1) / 2)
  )
  checkmate::assert(
    checkmate::check_null(p),
    checkmate::check_number(p, lower = 0, upper = 1)
  )

  caugi::generate_graph(
    n = n,
    m = m,
    p = p,
    class = "DAG"
  )
}
