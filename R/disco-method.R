#' @title Wrap a runner list into a `disco_method` closure
#'
#' @description
#' A `disco_method()` is a closure that wraps a builder function.
#' The builder function is expected to return a runner object.
#' The closure can be called with a data frame, and it will
#' build a fresh runner with the empty knowledge. Use `set_knowledge`
#' to set knowledge into the method.
#'
#' Every `disco_method()` can be used in combination with [disco()]. If you want
#' to build your own method, you can use this function to create a closure
#' that will run with [disco()].
#'
#' @example inst/roxygen-examples/disco_method-example.R
#' @noRd
#' @keywords internal
disco_method <- function(builder, method_class) {
  f <- function(data) {
    if (!(is.data.frame(data) || inherits(data, "mids"))) {
      stop("`data` must be a data frame or a `mids` object.", call. = FALSE)
    }
    # build a fresh runner with the current knowledge
    runner <- builder(environment(f)$knowledge)
    runner$run(data)
  }

  # each closure gets its own private env
  env <- environment(f)
  env$builder <- builder
  env$knowledge <- NULL # no knowledge by default

  structure(f, class = c(method_class, "disco_method", "function"))
}


#' Set Background Knowledge to Disco Method
#'
#' @param method A \code{"disco_method"} function.
#' @param knowledge A `Knowledge` object appropriate for the engine.
#' @family knowledge helpers
#' @concept knowledge-helper
#' @export
set_knowledge <- function(method, knowledge) {
  UseMethod("set_knowledge")
}

#' @rdname set_knowledge
#' @export
set_knowledge.disco_method <- function(method, knowledge) {
  old_builder <- environment(method)$builder
  method_class <- class(method)[1]

  # wrap the old builder so it always injects this `Knowledge`
  new_builder <- function(k_unused) {
    runner <- old_builder(NULL)
    runner$set_knowledge(knowledge)
    runner
  }

  disco_method(new_builder, method_class)
}
