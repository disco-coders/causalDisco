# See https://github.com/r-lib/roxygen2/issues/1158 for why this is needed
#' @title R6 Interface to pcalg Search Algorithms
#'
#' @name PcalgSearch
#'
#' @example inst/roxygen-examples/pcalg-search-example.R
NULL

#' @title R6 Interface to pcalg Search Algorithms
#'
#' @description
#' A wrapper that lets you drive \pkg{pcalg} algorithms within the \pkg{causalDisco} framework.
#' For arguments to the test, score, and algorithm, see the \pkg{pcalg} documentation, which we link to
#' in the respective sections below.
#'
#' @rdname PcalgSearch
#'
#' @importFrom R6 R6Class
#' @export PcalgSearch
PcalgSearch <- R6::R6Class(
  "PcalgSearch",
  public = list(
    #' @template data-field
    data = NULL,

    #' @field score A function that will be used to build the score,
    #'  when data is set. Can be set with \code{$set_score()}. Recognized values
    #'  are:
    #'  \itemize{
    #'     \item \code{"sem_bic"} - BIC score for Gaussian observed data.
    #'     See [pcalg::GaussL0penObsScore-class].
    #'     \item \code{"sem_bic_int"} - BIC score for Gaussian data from jointly
    #'     interventional and observational Gaussian data.
    #'     See [pcalg::GaussL0penIntScore-class].
    #'     }
    score = NULL,

    #' @field test A function that will be used to test independence.
    #'  Can be set with \code{$set_test()}. Recognized values are:
    #'  \itemize{
    #'    \item \code{"fisher_z"} - Fisher Z test for Gaussian data.
    #'    See [pcalg::gaussCItest()].
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
    #'   \item \code{"fci"} - FCI algorithm. See [fci()] and the underlying [pcalg::fci()].
    #'   \item \code{"ges"} - GES algorithm. See [ges()] and the underlying [pcalg::ges()].
    #'   \item \code{"pc"} - PC algorithm. See [pc()] and the underlying [pcalg::pc()].
    #'   \item \code{"rfci"} - RFCI algorithm. See [rfci()] and the underlying [pcalg::rfci()].
    #' }
    alg = NULL,

    #' @field params A list of parameters for the test and algorithm.
    #' Can be set with \code{$set_params()}.
    #' The parameters are passed to the test and algorithm functions.
    params = NULL,

    #' @field suff_stat Sufficient statistic. The format and contents of the
    #' sufficient statistic depends on which test is being used.
    suff_stat = NULL,

    #' @field continuous Logical; whether the sufficient statistic is for a
    #' continuous test. If both continuous and discrete are `TRUE`, the
    #' sufficient statistic is build for a mixed test.
    continuous = NULL,

    #' @field discrete Logical; whether the sufficient statistic is for a
    #' discrete test. If both continuous and discrete are `TRUE`, the sufficient
    #' statistic is build for a mixed test.
    discrete = NULL,

    #' @field knowledge A list of fixed constraints for the search algorithm. Note, that
    #' pcalg only works with symmetric knowledge. Thus, the only allowed types of knowledge
    #' is forbidden edges in both directions.
    knowledge = NULL,

    #' @field adapt_df Logical; whether to adapt the degrees of freedom
    #' for discrete tests.
    adapt_df = TRUE,

    #' @description
    #' Constructor for the `PcalgSearch` class.
    initialize = function() {
      .check_if_pkgs_are_installed(
        pkgs = c(
          "pcalg",
          "purrr",
          "rlang"
        ),
        class_name = "PcalgSearch"
      )

      self$data <- NULL
      self$score <- NULL
      self$test <- NULL
      self$knowledge <- NULL
      self$params <- list()
      self$adapt_df <- TRUE
      self$suff_stat <- NULL
    },

    #' @description
    #' Sets the parameters for the test and algorithm.
    #'
    #' @param params A list of parameters to set.
    set_params = function(params) {
      self$params <- params
    },

    #' @description
    #' Sets the data for the search algorithm.
    #'
    #' @param data A `data.frame` or a `matrix` containing the data.
    #' @param set_suff_stat Logical; whether to set the sufficient statistic.
    #' for the data.
    set_data = function(data, set_suff_stat = TRUE) {
      self$data <- data
      if (set_suff_stat) {
        self$set_suff_stat()
      }
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
      if (!is.logical(self$adapt_df)) {
        stop("adapt_df must be a logical.", call. = FALSE)
      }
      out <- .get_pcalg_test_from_string(
        method = private$test_key,
        X = self$data,
        suff_stat = TRUE,
        adaptDF = self$adapt_df,
        nlev = NULL
      )
      self$test <- out$method
      self$suff_stat <- out$suff_stat
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
      } else {
        stop("alpha must be set before using tests", call. = FALSE)
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
      private$test_key <- tolower(method)

      if (!is.null(self$data)) {
        self$set_suff_stat()
      } else {
        out <- .get_pcalg_test_from_string(
          method = private$test_key,
          suff_stat = FALSE
        )
        self$test <- out$method
      }
    },

    #' @description
    #' Sets the score for the search algorithm.
    #'
    #' @param method A string specifying the type of score to use.
    #' @param params A list of parameters to pass to the score function.
    set_score = function(method, params = list()) {
      method <- tolower(method)
      allowed <- c("sem_bic", "sem_bic_int")
      if (!(method %in% allowed)) {
        stop("Unknown score type using pcalg engine: ", method, call. = FALSE)
      }
      # Function that will be used to build the score, when data is set
      return_pcalg_score <- function() {
        if (is.null(self$data)) {
          stop("Data must be set before score.", call. = FALSE)
        }
        switch(
          method,
          "sem_bic" = {
            score <- rlang::exec(
              "new",
              Class = "GaussL0penObsScore",
              data = self$data,
              !!!params
            )
          },
          "sem_bic_int" = {
            score <- rlang::exec(
              "new",
              Class = "GaussL0penIntScore",
              data = self$data,
              !!!params
            )
          }
        )
        score
      }
      private$score_function <- return_pcalg_score
    },

    #' @description
    #' Sets the algorithm for the search.
    #'
    #' @param method A string specifying the type of algorithm to use.
    set_alg = function(method) {
      method <- tolower(method)
      switch(
        method,
        "pc" = {
          if (is.null(self$test)) {
            stop("No test is set. Use set_test() first.", call. = FALSE)
          }
          self$alg <- purrr::partial(
            pcalg::pc,
            indepTest = self$test,
            !!!self$params
          )
        },
        "fci" = {
          if (is.null(self$test)) {
            stop("No test is set. Use set_test() first.", call. = FALSE)
          }
          self$alg <- purrr::partial(
            pcalg::fci,
            indepTest = self$test,
            !!!self$params
          )
        },
        "ges" = {
          # Score will be set when we use run_search()
          self$alg <- purrr::partial(
            pcalg::ges,
            !!!self$params
          )
        },
        "rfci" = {
          if (is.null(self$test)) {
            stop("No test is set. Use set_test() first.", call. = FALSE)
          }
          self$alg <- purrr::partial(
            pcalg::rfci,
            indepTest = self$test,
            !!!self$params
          )
        },
        stop("Unknown method type using pcalg engine: ", method, call. = FALSE)
      )
    },

    #' @description
    #' Sets the knowledge for the search algorithm. Due to the nature of pcalg,
    #' we cannot set knowledge before we run it on data. So we set the function
    #' that will be used to build the fixed constraints, but it can first be
    #' done when data is provided.
    #'
    #' @param knowledge_obj A `Knowledge` object that contains the fixed constraints.
    #' @param directed_as_undirected `r lifecycle::badge("deprecated")`
    #' Logical; if \code{TRUE}, directed knowledge edges are mirrored into
    #' symmetric constraints. Deprecated: specify directed edges in both
    #' directions in [knowledge()] instead.
    set_knowledge = function(
      knowledge_obj,
      directed_as_undirected = lifecycle::deprecated()
    ) {
      if (lifecycle::is_present(directed_as_undirected)) {
        lifecycle::deprecate_warn(
          when = "1.2.0",
          what = "PcalgSearch$set_knowledge(directed_as_undirected)",
          details = paste0(
            "Specify directed edges in both directions in knowledge() ",
            "instead."
          )
        )
      } else {
        directed_as_undirected <- FALSE
      }
      is_knowledge(knowledge_obj)

      private$knowledge_function <- function() {
        if (is.null(self$data)) {
          stop("Data must be set before knowledge.", call. = FALSE)
        }
        labels <- colnames(self$data)
        constraints <- as_pcalg_constraints(
          knowledge_obj,
          labels,
          directed_as_undirected = directed_as_undirected
        )
        if (any(constraints$fixed_edges)) {
          warning(
            "Engine pcalg does not use required edges; ignoring them.",
            call. = FALSE
          )
        }
        constraints
      }
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
          "No data is set. ",
          "Use set_data() first or input data directly into run_search().",
          call. = FALSE
        )
      }
      if (is.null(self$alg)) {
        stop("No algorithm is set. Use set_alg() first.", call. = FALSE)
      }

      # If score_function is NULL, then we are not using a score-based algorithm
      if (is.null(private$score_function)) {
        if (is.null(self$suff_stat) && set_suff_stat) {
          stop(
            "No sufficient statistic is set. Use set_data() first.",
            call. = FALSE
          )
        }
        if (!is.null(private$knowledge_function)) {
          # If knowledge is set, we now need to call the function
          # to get the fixed constraints.
          self$knowledge <- private$knowledge_function()
          if (inherits(self$data, "mids")) {
            labels = colnames(mice::complete(self$data, action = 1))
          } else {
            labels = colnames(self$data)
          }
          result <- self$alg(
            suffStat = self$suff_stat,
            labels = labels,
            fixedGaps = self$knowledge$fixed_gaps,
            fixedEdges = self$knowledge$fixed_edges
          )
        } else {
          if (inherits(self$data, "mids")) {
            labels = colnames(mice::complete(self$data, action = 1))
          } else {
            labels = colnames(self$data)
          }
          result <- self$alg(
            suffStat = self$suff_stat,
            labels = labels
          )
        }
        # score_function is not null, so we are using a score-based algorithm
      } else {
        if (!is.null(private$knowledge_function)) {
          # If knowledge is set, we now need to call the function
          # to get the fixed constraints.
          self$knowledge <- private$knowledge_function()
          self$score <- private$score_function()
          result <- self$alg(
            self$score,
            fixedGaps = self$knowledge$fixedGaps
          )
        } else {
          self$score <- private$score_function()
          result <- self$alg(
            self$score
          )
        }
      }
      out <- if (is.list(result) && !is.null(result$essgraph)) {
        # if ges output
        result$essgraph
      } else {
        result
      }
      as_disco(out)
    }
  ),
  private = list(
    knowledge_function = NULL,
    score_function = NULL,
    test_key = NULL,
    user_suff_stat_fun = NULL
  )
)
