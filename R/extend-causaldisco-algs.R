#' Add a New causalDisco Method
#'
#' This function allows you to create a new causal discovery method that can be used with the [disco()] function.
#' You provide a builder function that constructs a runner object, along with metadata about the algorithm, and it
#' returns a closure that can be called with a data frame to perform causal discovery and return a [caugi::caugi] object.
#'
#' @param builder A function returning a runner
#' @param name Algorithm name
#' @param engine Engine identifier
#' @param graph_class Output graph class
#' @return A function of class \code{"disco_method"} that takes a single argument
#' \code{data} (a data frame) and returns a [caugi::caugi] object.
#'
#' @family Extending causalDisco
#' @concept extending_causalDisco
#' @export
new_disco_method <- function(builder, name, engine, graph_class) {
  method <- disco_method(builder, name)
  attr(method, "engine") <- engine
  attr(method, "graph_class") <- graph_class
  method
}

#' Distribute and Validate Engine Arguments
#'
#' This function checks the provided arguments against the expected arguments for the specified engine and algorithm,
#' and distributes them appropriately to the search object. It ensures that the arguments are valid for the given
#' engine and algorithm, and then sets them on the search object.
#'
#' @param search R6 object, either `TetradSearch`, `BnlearnSearch`, `PcalgSearch`, or `CausalDiscoSearch`.
#' @param args List of arguments to distribute
#' @param engine Engine identifier, either "tetrad", "bnlearn", "pcalg", or "causalDisco"
#' @param alg Algorithm name
#'
#' @family Extending causalDisco
#' @concept extending_causalDisco
#' @export
distribute_engine_args <- function(search, args, engine, alg) {
  check_args_and_distribute_args(search, args, engine, alg)
}

tetrad_alg_registry <- new.env(parent = emptyenv())

#' Register a New Tetrad Algorithm
#'
#' Registers a new Tetrad algorithm by adding it to the internal registry. The `setup_fun()` should be a function that
#' takes the same arguments as the runner function for the algorithm and sets up the Tetrad search object accordingly.
#' This allows you to extend the set of Tetrad algorithms that can be used with causalDisco.
#'
#' @param name Algorithm name (string)
#' @param setup_fun A function that sets up the Tetrad search object for the
#' algorithm. It should take the same arguments as the runner function for the algorithm.
#'
#' @family Extending causalDisco
#' @concept extending_causalDisco
#' @export
register_tetrad_algorithm <- function(name, setup_fun) {
  name <- tolower(name)
  if (!is.function(setup_fun)) {
    stop("`setup_fun` must be a function")
  }
  tetrad_alg_registry[[name]] <- setup_fun
}

#' List Registered Tetrad Algorithms
#'
#' Returns the names of all custom registered Tetrad algorithms.
#'
#' @return Character vector of algorithm names.
#' @family Extending causalDisco
#' @concept extending_causalDisco
#' @export
list_registered_tetrad_algorithms <- function() {
  sort(ls(envir = tetrad_alg_registry))
}

#' Reset the Tetrad Algorithm Registry
#'
#' Clears all custom registered algorithms.
#'
#' @family Extending causalDisco
#' @concept extending_causalDisco
#'
#' @export
reset_tetrad_alg_registry <- function() {
  rm(
    list = ls(tetrad_alg_registry, all.names = TRUE),
    envir = tetrad_alg_registry
  )
  invisible(NULL)
}

engine_registry_env <- new.env(parent = emptyenv())

#' Register a New Engine
#'
#' The built-in engines ("bnlearn", "causalDisco", "pcalg", "tetrad") are
#' backed by R6 search classes ([BnlearnSearch], [CausalDiscoSearch],
#' [PcalgSearch], [TetradSearch]) that [make_runner()] knows how to build and
#' configure. `register_engine()` lets you plug in a backend for a package
#' that isn't one of the built-ins, so that it can be selected by name from
#' [make_runner()] the same way as a built-in engine.
#'
#' `make_runner_fn` must accept `alg` and `...`, and return a runner: a list
#' with two elements,
#' \itemize{
#'   \item `set_knowledge`, a function that takes a single `Knowledge`
#'   object and configures background knowledge on the underlying search, and
#'   \item `run`, a function that takes a single data frame, runs the search,
#'   and returns the algorithm's result using [as_disco()].
#' }
#' [make_runner()] calls `make_runner_fn` with `alg`, `test`, `alpha`,
#' `score`, and any additional arguments it was itself called with. Pick up
#' whichever of these your engine needs by naming them explicitly, and let
#' `...` absorb the rest.
#'
#' @param name Engine name (string). Cannot be one of the built-in engine
#' names ("bnlearn", "causalDisco", "pcalg", "tetrad").
#' @param make_runner_fn A function implementing the engine. See Details.
#' @param pkgs Character vector of package names required by the engine.
#' Checked, with an informative error if missing, before `make_runner_fn` is
#' called.
#'
#' @family Extending causalDisco
#' @concept extending_causalDisco
#' @export
register_engine <- function(name, make_runner_fn, pkgs = character(0)) {
  checkmate::assert_string(name)
  checkmate::assert_character(pkgs, any.missing = FALSE)
  if (!is.function(make_runner_fn)) {
    stop("`make_runner_fn` must be a function", call. = FALSE)
  }
  if (name %in% .engines) {
    stop(
      "'",
      name,
      "' is a built-in engine name and cannot be overridden. ",
      "Built-in engines are: ",
      paste(.engines, collapse = ", "),
      call. = FALSE
    )
  }
  engine_registry_env[[name]] <- list(
    make_runner_fn = make_runner_fn,
    pkgs = pkgs
  )
  invisible(NULL)
}

#' List Registered Engines
#'
#' Returns the names of all custom engines registered via
#' [register_engine()] (in addition to the built-in engines "bnlearn",
#' "causalDisco", "pcalg", and "tetrad", which are always available).
#'
#' @return Character vector of engine names.
#' @family Extending causalDisco
#' @concept extending_causalDisco
#' @export
list_registered_engines <- function() {
  sort(ls(envir = engine_registry_env))
}

#' Reset the Engine Registry
#'
#' Clears all custom registered engines.
#'
#' @family Extending causalDisco
#' @concept extending_causalDisco
#' @export
reset_engine_registry <- function() {
  rm(
    list = ls(engine_registry_env, all.names = TRUE),
    envir = engine_registry_env
  )
  invisible(NULL)
}
