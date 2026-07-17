#' Create a Custom Causal Discovery Method
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Constructs a new causal discovery method that can be used
#' with the [disco()] framework. Users can provide an engine, engine-specific
#' functions, and optional test and alpha parameters.
#'
#' @param method_name Character. The name of the method to create.
#' @param engine Character. The engine to use. Must be one of the names of
#'   `engine_fns`.
#' @param engine_fns Named list of functions. Each element corresponds to an
#'   engine and is a function that implements the causal discovery algorithm.
#' @param test Optional. A test statistic to pass to the engine function.
#' @param alpha Optional. A significance level to pass to the engine function.
#' @param score Optional. A score to pass to the engine function.
#' @param graph_class Character. The graph class that this method produces.
#' @param ... Additional arguments passed to the engine function.
#'
#' @return A `disco_method` object with attributes `engine` and `graph_class`.
#' @family Extending causalDisco
#' @concept extending_causalDisco
#' @export
make_method <- function(
  method_name,
  engine,
  engine_fns,
  test = NULL,
  alpha = NULL,
  score = NULL,
  graph_class,
  ...
) {
  .check_if_pkgs_are_installed(
    pkgs = "rlang",
    function_name = method_name
  )

  engine <- match.arg(engine, names(engine_fns))
  args <- rlang::list2(...)

  builder <- function(knowledge = NULL) {
    rlang::exec(
      engine_fns[[engine]],
      !!!c(
        if (!is.null(test)) list(test = test) else list(),
        if (!is.null(alpha)) list(alpha = alpha) else list(),
        if (!is.null(score)) list(score = score) else list(),
        args
      )
    )
  }

  method <- disco_method(builder, method_name)
  attr(method, "engine") <- engine
  attr(method, "graph_class") <- graph_class
  method
}

#' Create a Custom Runner for a Causal Discovery Algorithm
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Constructs a runner function for a specific causal discovery
#' engine and algorithm. This allows users to support new algorithms.
#'
#' @param engine Character. The engine to use. Options include `"causalDisco"`,
#'   `"pcalg"`, `"bnlearn"`, `"tetrad"`, or the name of any engine added via
#'   [register_engine()].
#' @param alg Character. The algorithm name.
#' @param test Optional. A test statistic to pass to the engine.
#' @param alpha Optional. Significance level to pass to the engine.
#' @param score Optional. A scoring function for score-based methods.
#' @param ... Additional arguments passed to the engine-specific runner.
#' @param directed_as_undirected_knowledge Logical. Used internally for \pkg{pcalg}.
#'
#' @return An object representing a configured runner for the chosen engine.
#'   The type depends on the engine.
#' @family Extending causalDisco
#' @concept extending_causalDisco
#' @export
make_runner <- function(
  engine,
  alg,
  test = NULL,
  alpha = NULL,
  score = NULL,
  ...,
  directed_as_undirected_knowledge = FALSE
) {
  if (exists(engine, envir = engine_registry_env, inherits = FALSE)) {
    custom_engine <- engine_registry_env[[engine]]
    if (length(custom_engine$pkgs) > 0) {
      .check_if_pkgs_are_installed(
        pkgs = custom_engine$pkgs,
        function_name = paste0(alg, "_", engine, "_runner")
      )
    }
    return(custom_engine$make_runner_fn(
      alg = alg,
      test = test,
      alpha = alpha,
      score = score,
      ...,
      directed_as_undirected_knowledge = directed_as_undirected_knowledge
    ))
  }

  engine_map <- list(
    causalDisco = list(class = CausalDiscoSearch, pkgs = "causalDisco"),
    pcalg = list(class = PcalgSearch, pkgs = "pcalg"),
    bnlearn = list(class = BnlearnSearch, pkgs = "bnlearn"),
    tetrad = list(class = TetradSearch, pkgs = "rJava")
  )

  if (!engine %in% names(engine_map)) {
    stop(
      "Unknown engine: '",
      engine,
      "'. Supported engines are: ",
      paste(
        c(names(engine_map), list_registered_engines()),
        collapse = ", "
      ),
      ". Use register_engine() to add support for a new engine.",
      call. = FALSE
    )
  }

  required_pkgs <- engine_map[[engine]]$pkgs
  .check_if_pkgs_are_installed(
    pkgs = required_pkgs,
    function_name = paste0(alg, "_", engine, "_runner")
  )

  switch(
    engine,
    pcalg = ,
    causalDisco = .make_runner_standard(
      engine = engine,
      alg = alg,
      test = test,
      alpha = alpha,
      score = score,
      ...,
      directed_as_undirected_knowledge = directed_as_undirected_knowledge
    ),
    bnlearn = .make_runner_bnlearn(
      alg = alg,
      test = test,
      alpha = alpha,
      score = score,
      ...
    ),
    tetrad = .make_runner_tetrad(
      alg = alg,
      test = test,
      alpha = alpha,
      score = score,
      ...
    )
  )
}

.make_runner_standard <- function(
  engine,
  alg,
  test = NULL,
  alpha = NULL,
  score = NULL,
  ...,
  directed_as_undirected_knowledge = FALSE
) {
  engine_map <- list(
    causalDisco = list(class = CausalDiscoSearch, pkgs = "causalDisco"),
    pcalg = list(class = PcalgSearch, pkgs = "pcalg")
  )

  if (!engine %in% names(engine_map)) {
    stop("Unknown engine: ", engine)
  }

  search_class <- engine_map[[engine]]$class
  required_pkgs <- engine_map[[engine]]$pkgs

  .check_if_pkgs_are_installed(
    pkgs = required_pkgs,
    function_name = paste0(alg, "_", engine, "_runner")
  )

  search <- search_class$new()
  args <- list(...)

  args_to_pass <- check_args_and_distribute_args(
    search = search,
    args = args,
    engine = engine,
    alg = alg,
    test = test,
    score = score
  )

  # Set algorithm-specific parameters
  search$set_params(args_to_pass$alg_args)

  # Set test or score depending on what was passed
  if (!is.null(test)) {
    search$set_test(
      test,
      alpha,
      suff_stat_fun = args_to_pass$wrapper_args$suff_stat_fun,
      args = args_to_pass$wrapper_args$args
    )
  }
  if (!is.null(score)) {
    search$set_score(
      score,
      args_to_pass$score_args
    )
  }

  search$set_alg(alg)

  list(
    set_knowledge = function(knowledge) {
      search$set_knowledge(
        knowledge,
        directed_as_undirected = directed_as_undirected_knowledge
      )
    },
    run = function(data) {
      search$run_search(data)
    }
  )
}

.make_runner_bnlearn <- function(
  alg,
  test = NULL,
  alpha = NULL,
  score = NULL,
  ...
) {
  # TODO: Clean up passing args and check_args_and_distribute_args for bnlearn.
  args <- list(...)
  search <- BnlearnSearch$new()

  args_to_pass <- check_args_and_distribute_args(
    search,
    args,
    "bnlearn",
    alg,
    test = test,
    score = score
  )

  # Handle test
  if (!is.null(test)) {
    if (is.function(test)) {
      args_to_pass$alg_args$test <- "custom-test"
      args_to_pass$alg_args$fun <- test
    }
    search$set_test(
      test,
      alpha
    )
  }

  # Handle score
  if (!is.null(score)) {
    search$set_score(score)
  }

  search$set_alg(alg, args_to_pass)

  list(
    set_knowledge = function(knowledge) search$set_knowledge(knowledge),
    run = function(data) search$run_search(data)
  )
}

.make_runner_tetrad <- function(
  alg,
  test = NULL,
  alpha = NULL,
  score = NULL,
  ...
) {
  search <- TetradSearch$new()
  args <- list(...)

  args_to_pass <- check_args_and_distribute_args(
    search = search,
    args = args,
    engine = "tetrad",
    alg = alg,
    test = test,
    score = score
  )
  # score
  if (!is.null(score)) {
    if (length(args_to_pass$score_args) > 0) {
      rlang::exec(search$set_score, score, !!!args_to_pass$score_args)
    } else {
      search$set_score(score)
    }
  }

  # test
  if (!is.null(test)) {
    if (length(args_to_pass$test_args) > 0) {
      rlang::exec(
        search$set_test,
        test,
        alpha = alpha,
        !!!args_to_pass$test_args
      )
    } else {
      search$set_test(test, alpha = alpha)
    }
  }

  # algorithm
  if (length(args_to_pass$alg_args) > 0) {
    rlang::exec(search$set_alg, alg, !!!args_to_pass$alg_args)
  } else {
    search$set_alg(alg)
  }

  list(
    set_knowledge = function(knowledge) {
      search$set_knowledge(knowledge)
    },
    run = function(data) {
      search$run_search(data)
    }
  )
}
