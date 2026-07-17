# See https://github.com/r-lib/roxygen2/issues/1158 for why this is needed
#' @title R6 Interface to causalDisco Search Algorithms
#'
#' @name CausalDiscoSearch
#'
#' @example inst/roxygen-examples/causalDisco-search-example.R
NULL

#' @title R6 Interface to causalDisco Search Algorithms
#'
#' @description This class implements the search algorithms from the \pkg{causalDisco}
#' package, which wraps and adds temporal order to \pkg{pcalg} algorithms.
#' It allows to set the data, sufficient statistics, test, score, and algorithm.
#'
#' @importFrom R6 R6Class
#'
#' @rdname CausalDiscoSearch
#'
#' @export CausalDiscoSearch
CausalDiscoSearch <- R6::R6Class(
  "CausalDiscoSearch",
  public = list(
    #' @template data-field
    data = NULL,

    #' @field score A function that will be used to build the score,
    #'  when data is set. Can be set with \code{$set_score()}. Recognized values
    #'  are:
    #'  \itemize{
    #'     \item \code{"tbic"} - Temporal BIC score for Gaussian data.
    #'     See [TemporalBIC].
    #'     \item \code{"tbdeu"} - Temporal BDeu score for discrete data.
    #'     See [TemporalBDeu].
    #'     }
    score = NULL,

    #' @field test A function that will be used to test independence.
    #'  Can be set with \code{$set_test()}. Recognized values are:
    #'  \itemize{
    #'    \item \code{"fisher_z"} - Fisher Z test for Gaussian data.
    #'    See [cor_test()].
    #'    \item \code{"fisher_z_twd"} - Fisher Z test for Gaussian data with test-wise deletion.
    #'    See [micd::gaussCItwd()].
    #'    \item \code{"fisher_z_mi"} - Fisher Z test for Gaussian data with multiple imputation.
    #'    See [micd::gaussCItestMI()].
    #'
    #'    \item \code{"reg"} - Regression test for discrete or binary data.
    #'    See [reg_test()].
    #'    \item \code{"g_square"} - G square test for discrete data.
    #'    See [pcalg::binCItest()] and [pcalg::disCItest()].
    #'    \item \code{"g_square_twd"} - G square test for discrete data with test-wise deletion.
    #'    See [micd::disCItwd()].
    #'    \item \code{"g_square_mi"} - G square test for discrete data with multiple imputation.
    #'    See [micd::disMItest()].
    #'
    #'    \item \code{"conditional_gaussian"} - Test for conditional independence in mixed data.
    #'    See [micd::mixCItest()].
    #'    \item \code{"conditional_gaussian_twd"} - Test for conditional independence in mixed data
    #'    with test-wise deletion.
    #'    See [micd::mixCItwd()].
    #'    \item \code{"conditional_gaussian_mi"} - Test for conditional independence in mixed data
    #'    with multiple imputation.
    #'    See [micd::mixMItest()].
    #'  }
    test = NULL,

    #' @field alg A function that will be used to run the search algorithm.
    #' Can be set with \code{$set_alg()}. Recognized values are:
    #' \itemize{
    #'   \item \code{"tfci"} - TFCI algorithm.
    #'   See [tfci()].
    #'   \item \code{"tges"} - TGES algorithm.
    #'   See [tges()].
    #'   \item \code{"tpc"}  - TPC algorithm.
    #'   See [tpc()].
    #' }
    #' Can also be a user-defined function; see \code{$set_alg()} for details.
    alg = NULL,

    #' @field params A list of parameters for the test and algorithm.
    #' Can be set with \code{$set_params()}.
    #' TODO: not secure yet in terms of distributing arguments.
    #' Use with caution.
    params = NULL,

    #' @field suff_stat Sufficient statistic. The format and contents of the
    #' sufficient statistic depends on which test is being used.
    suff_stat = NULL,

    #' @field knowledge A `Knowledge` object holding background knowledge.
    knowledge = NULL,

    #' @description
    #' Constructor for the `CausalDiscoSearch` class.
    initialize = function() {
      .check_if_pkgs_are_installed(
        pkgs = c(
          "pcalg",
          "purrr",
          "R6",
          "rlang",
          "stats",
          "utils"
        ),
        class_name = "CausalDiscoSearch"
      )

      self$data <- NULL
      self$score <- NULL
      self$test <- NULL
      self$knowledge <- NULL
      self$params <- list(
        na_method = "none"
      )
    },

    #' @description
    #' Sets the parameters for the test and algorithm.
    #'
    #' @param params A list of parameters to set.
    set_params = function(params) {
      if (is.null(params)) {
        return(invisible(self))
      }
      reserved <- c(
        "data",
        "suff_stat",
        "Knowledge",
        "score",
        "test",
        "labels"
      )
      bad <- intersect(names(params), reserved)
      if (length(bad)) {
        stop(
          "These parameters are reserved and cannot be set via set_params(): ",
          paste(bad, collapse = ", "),
          call. = FALSE
        )
      }
      # allow overriding default output/na_method/verbose/etc.
      self$params <- utils::modifyList(self$params, params)
      invisible(self)
    },

    #' @description
    #' Sets the data for the search algorithm.
    #'
    #' @param data A `data.frame` or a `matrix` containing the data.
    #' @param set_suff_stat Logical; whether to set the sufficient statistic.
    set_data = function(data, set_suff_stat = TRUE) {
      self$data <- data
      if (set_suff_stat) {
        self$set_suff_stat()
      }

      invisible(self)
    },

    #' @description
    #' Sets the sufficient statistic for the data.
    set_suff_stat = function() {
      if (is.null(self$data)) {
        stop("Data must be set before sufficient statistic.", call. = FALSE)
      }
      if (identical(private$test_key, "custom-test")) {
        if (is.null(private$user_suff_stat_fun)) {
          stop(
            "For user-defined tests, provide suff_stat_fun in set_test().",
            call. = FALSE
          )
        }
        self$suff_stat <- private$user_suff_stat_fun(self$data)
        return(invisible(self))
      }
      if (is.null(private$test_key)) {
        stop("Test must be set before sufficient statistic.", call. = FALSE)
      }

      out <- .get_pcalg_test_from_string(
        method = private$test_key,
        X = self$data,
        suff_stat = TRUE
      )
      self$test <- out$method
      self$suff_stat <- out$suff_stat
      invisible(self)
    },

    #' @description
    #' Sets the test for the search algorithm.
    #'
    #' @param method `r lifecycle::badge("experimental")`
    #'
    #' A string specifying the type of test to use.
    #'
    #' Can also be a user-defined function with
    #' signature `function(x, y, conditioning_set, suff_stat)`, where `x` and `y` are the variables being tested for
    #' independence, `conditioning_set` is the conditioning set, and `suff_stat` is the sufficient statistic for the
    #' test. If a user-defined function is provided, then `suff_stat_fun` must also be provided, which is a
    #' function that should take the data as input and returns a sufficient statistic for the test. Optionally,
    #' the signature of the user-defined test function can also include an `args` parameter, which is a list of
    #' additional arguments to pass to the test function. If `args` is provided, then the test function should have the
    #' signature `function(x, y, conditioning_set, suff_stat, args)`, and the `args` parameter will be passed to the
    #' test function.
    #'
    #' EXPERIMENTAL: user-defined tests syntax are subject to change.
    #' @param alpha Significance level for the test.
    #' @param suff_stat_fun A function that takes the data as input and returns a sufficient statistic for the test.
    #' Only needed if `method` is a user-defined function.
    #' @param args A list of additional arguments to pass to the test.
    #' Only needed if `method` is a user-defined function with an `args` parameter in its signature.
    set_test = function(
      method,
      alpha = 0.05,
      suff_stat_fun = NULL,
      args = NULL
    ) {
      if (!is.null(alpha)) {
        self$params$alpha <- alpha
      }

      if (is.function(method)) {
        if (!is.null(args)) {
          self$test <- function(x, y, conditioning_set, suff_stat) {
            method(
              x,
              y,
              conditioning_set,
              suff_stat,
              args = args
            )
          }
        } else {
          self$test <- method
        }
        private$test_key <- "custom-test"

        if (!is.null(self$data) && !is.null(suff_stat_fun)) {
          self$suff_stat <- suff_stat_fun(self$data)
        }

        private$user_suff_stat_fun <- suff_stat_fun
        return(invisible(self))
      }

      method <- tolower(method)
      private$test_key <- method

      if (!is.null(self$data)) {
        self$set_suff_stat()
      } else {
        out <- .get_pcalg_test_from_string(
          method = private$test_key,
          suff_stat = FALSE
        )
        self$test <- out$method
      }
      invisible(self)
    },

    #' @description
    #' Sets the score for the search algorithm.
    #'
    #' @param method A string specifying the type of score to use.
    #' @param params A list of parameters to pass to the score function.
    set_score = function(method, params = list()) {
      method <- tolower(method)
      allowed <- c("tbic", "tbdeu")
      if (!(method %in% allowed)) {
        stop(
          "Unknown score type using causalDisco engine: ",
          method,
          call. = FALSE
        )
      }

      private$score_method <- method
      private$score_params <- if (is.null(params)) list() else params

      private$score_function <- function() {
        if (is.null(self$data)) {
          stop("Data must be set before score.", call. = FALSE)
        }

        if (identical(private$score_method, "tbic")) {
          # Gaussian temporal score
          return(rlang::exec(
            "new",
            Class = "TemporalBIC",
            data = self$data,
            nodes = colnames(self$data),
            knowledge = self$knowledge,
            !!!private$score_params
          ))
        }

        if (identical(private$score_method, "tbdeu")) {
          # Categorical temporal score
          return(rlang::exec(
            "new",
            Class = "TemporalBDeu",
            data = self$data,
            nodes = colnames(self$data),
            knowledge = self$knowledge,
            !!!private$score_params
          ))
        }

        stop("Internal: unsupported score method.", call. = FALSE)
      }

      invisible(self)
    },

    #' @description
    #' Sets the algorithm for the search.
    #'
    #' @param method `r lifecycle::badge("experimental")`
    #'
    #' A string specifying the type of algorithm to use.
    #'
    #' Can also be a user-defined function implementing a full search
    #' algorithm. Its required signature depends on \code{type}:
    #' \itemize{
    #'   \item \code{type = "constraint"} (default) - signature
    #'   \code{function(data, knowledge, suff_stat, ...)}, analogous to
    #'   [tpc_run()] and [tfci_run()].
    #'   \item \code{type = "score"} - signature \code{function(score, ...)},
    #'   analogous to [tges_run()].
    #' }
    #' Optionally, the function's signature can also include an \code{args}
    #' parameter, which is a list of additional arguments to pass to the
    #' algorithm function. If \code{args} is provided, the function should have
    #' the signature \code{function(data, knowledge, suff_stat, args)} (or
    #' \code{function(score, args)} for \code{type = "score"}), and the
    #' \code{args} parameter will be passed to the algorithm function.
    #'
    #' EXPERIMENTAL: user-defined algorithm syntax is subject to change.
    #' @param type Only used if \code{method} is a user-defined function.
    #' One of \code{"constraint"} (default) or \code{"score"}, specifying
    #' whether the algorithm is constraint-based (called with
    #' \code{data}/\code{knowledge}/\code{suff_stat}) or score-based (called
    #' with \code{score}).
    #' @param args A list of additional arguments to pass to the algorithm.
    #' Only needed if \code{method} is a user-defined function with an
    #' \code{args} parameter in its signature.
    set_alg = function(method, type = c("constraint", "score"), args = NULL) {
      if (is.function(method)) {
        type <- match.arg(type)

        if (!is.null(args)) {
          self$alg <- if (identical(type, "constraint")) {
            function(data, knowledge, suff_stat) {
              method(data, knowledge, suff_stat, args = args)
            }
          } else {
            function(score) {
              method(score, args = args)
            }
          }
        } else {
          self$alg <- method
        }

        private$alg_method <- "custom-alg"
        private$alg_family <- type
        return(invisible(self))
      }

      method <- tolower(method)
      private$alg_method <- method

      switch(
        method,
        "tpc" = {
          if (is.null(self$test)) {
            stop("No test is set. Use set_test() first.", call. = FALSE)
          }
          self$alg <- purrr::partial(
            tpc_run,
            test = self$test,
            !!!self$params
          )
          private$alg_family <- "constraint"
        },
        "tfci" = {
          if (is.null(self$test)) {
            stop("No test is set. Use set_test() first.", call. = FALSE)
          }
          self$alg <- purrr::partial(
            tfci_run,
            test = self$test,
            !!!self$params
          )
          private$alg_family <- "constraint"
        },
        "tges" = {
          self$alg <- purrr::partial(
            tges_run,
            verbose = isTRUE(self$params$verbose)
          )
          private$alg_family <- "score"
        },
        stop(
          "Unknown method type using causalDisco engine: ",
          method,
          call. = FALSE
        )
      )

      invisible(self)
    },

    #' @description
    #'
    #' Sets the background knowledge for the search with a `Knowledge` object.
    #'
    #' @param kn A `Knowledge` object.
    #' @param directed_as_undirected Logical; whether to treat directed edges in
    #' the knowledge as undirected. Default is `FALSE`. This is due to the
    #' nature of how \pkg{pcalg} handles background knowledge when using
    #' [pcalg::skeleton()] under the hood in
    #' [tpc()] and
    #' [tfci()].
    #' @seealso [knowledge()].
    set_knowledge = function(kn, directed_as_undirected = FALSE) {
      is_knowledge(kn)
      self$knowledge <- kn
      private$directed_as_undirected <- directed_as_undirected
      invisible(self)
    },

    #' @description
    #' Runs the search algorithm on the data.
    #'
    #' @param data A `data.frame` or a `matrix` containing the data.
    #' @param set_suff_stat Logical; whether to set the sufficient statistic
    run_search = function(data = NULL, set_suff_stat = TRUE) {
      if (!is.null(data)) {
        if (is.null(private$score_function)) {
          self$set_data(data, set_suff_stat = set_suff_stat)
        } else {
          self$set_data(data, set_suff_stat = FALSE)
        }
      }
      if (is.null(self$data)) {
        stop(
          "No data is set. Use set_data() first or pass data to ",
          "run_search().",
          call. = FALSE
        )
      }
      if (is.null(self$alg)) {
        stop("No algorithm is set. Use set_alg() first.", call. = FALSE)
      }

      # constraint-based path
      if (!identical(private$alg_family, "score")) {
        if (is.null(self$suff_stat) && set_suff_stat) {
          stop(
            "No sufficient statistic is set. Use set_data() first.",
            call. = FALSE
          )
        }
        res <- self$alg(
          data = self$data,
          knowledge = self$knowledge,
          suff_stat = self$suff_stat
        )
        res
      } else {
        # score-based path (tges)
        if (is.null(private$score_function)) {
          stop("No score is set. Use set_score() first.", call. = FALSE)
        }
        self$score <- private$score_function()

        res <- self$alg(
          score = self$score
        )
        res
      }
    }
  ),
  private = list(
    alg_method = NULL, # "tpc", "tfci", "tges", or "custom-alg"
    alg_family = NULL, # "constraint" or "score"
    test_key = NULL,
    directed_as_undirected = FALSE,
    score_method = NULL,
    score_params = NULL,
    score_function = NULL,
    user_suff_stat_fun = NULL
  )
)
