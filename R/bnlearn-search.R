# See https://github.com/r-lib/roxygen2/issues/1158 for why this is needed
#' @title R6 Interface to bnlearn Search Algorithms
#'
#' @name BnlearnSearch
#'
#' @example inst/roxygen-examples/bnlearn-search-example.R
NULL

# We import a function from bnlearn and R6 using @importFrom here to avoid false positives about packages not used,
# see this discussion: https://stat.ethz.ch/pipermail/r-package-devel/2026q1/012259.html
#' @title R6 Interface to bnlearn Search Algorithms
#'
#' @description A wrapper that lets you drive \pkg{bnlearn} algorithms within the \pkg{causalDisco} framework.
#' For arguments to the test, score, and algorithm, see the \pkg{bnlearn} documentation.
#'
#' @return An R6 object with the methods documented below.
#'
#' @importFrom R6 R6Class
#' @importFrom bnlearn pc.stable
#'
#' @rdname BnlearnSearch
#'
#' @export
BnlearnSearch <- R6::R6Class(
  "BnlearnSearch",
  public = list(
    #' @template data-field
    data = NULL,

    #' @field score Character scalar naming the score function used in
    #'   \pkg{bnlearn}. Can be set with \code{$set_score()}. Kebab-case score names (as used in \pkg{bnlearn}, e.g.
    #'   \code{"pred-loglik"}) are also accepted and automatically translated to snake_case.
    #'   Recognised values are:
    #'
    #'   **Continuous - Gaussian**
    #'   \itemize{
    #'     \item \code{"aic_g"}, \code{"bic_g"}, \code{"ebic_g"}, \code{"loglik_g"}, \code{"pred_loglik_g"} -
    #'     gaussian versions of the respective scores for discrete data.
    #'     \item \code{"bge"} - Gaussian posterior density.
    #'     \item \code{"nal_g"} - node-average log-likelihood.
    #'     \item \code{"pnal_g"} - penalised node-average log-likelihood.
    #'   }
    #'
    #'  **Discrete – categorical**
    #'   \itemize{
    #'     \item \code{"aic"} - Akaike Information Criterion.
    #'     \item \code{"bdla"} - locally averaged BDE.
    #'     \item \code{"bde"} - Bayesian Dirichlet equivalent (uniform).
    #'     \item \code{"bds"} - Bayesian Dirichlet score.
    #'     \item \code{"bic"} - Bayesian Information Criterion.
    #'     \item \code{"ebic"} - Extended BIC.
    #'     \item \code{"fnml"} - factorised NML.
    #'     \item \code{"k2"} - K2 score.
    #'     \item \code{"loglik"} - log-likelihood.
    #'     \item \code{"mbde"} - modified BDE.
    #'     \item \code{"nal"} - node-average log-likelihood.
    #'     \item \code{"pnal"} - penalised node-average log-likelihood.
    #'     \item \code{"pred_loglik"} - predictive log-likelihood.
    #'     \item \code{"qnml"} - quotient NML.
    #'   }
    #'
    #'   **Mixed Discrete/Gaussian**
    #'   \itemize{
    #'     \item \code{"aic_cg"}, \code{"bic_cg"}, \code{"ebic_cg"}, \code{"loglik_cg"}, \code{"nal_cg"},
    #'     \code{"pnal_cg"}, \code{"pred_loglik_cg"} - conditional Gaussian versions of the respective scores for
    #'     discrete data.
    #'   }
    score = NULL,

    #' @field test Character scalar naming the conditional-independence test
    #'   passed to \pkg{bnlearn}. Can be set with \code{$set_score()}. Kebab-case test names
    #'   (as used in \pkg{bnlearn}, e.g. "mi-adf") are also accepted and automatically translated to snake_case.
    #'   Recognised values are:
    #'
    #'   **Continuous - Gaussian**
    #'   \itemize{
    #'     \item \code{"cor"} – Pearson correlation
    #'     \item \code{"fisher_z"} / \code{"zf"} – Fisher Z test
    #'     \item \code{"mc_cor"} – Monte Carlo Pearson correlation
    #'     \item \code{"mc_mi_g"} – Monte Carlo mutual information (Gaussian)
    #'     \item \code{"mc_zf"} – Monte Carlo Fisher Z
    #'     \item \code{"mi_g"} – mutual information (Gaussian)
    #'     \item \code{"mi_g_sh"} – mutual information (Gaussian, shrinkage)
    #'     \item \code{"smc_cor"} – sequential Monte Carlo Pearson correlation
    #'     \item \code{"smc_mi_g"} – sequential Monte Carlo mutual information (Gaussian)
    #'     \item \code{"smc_zf"} – sequential Monte Carlo Fisher Z
    #'   }
    #'
    #'   **Discrete – categorical**
    #'   \itemize{
    #'     \item \code{"mc_mi"} – Monte Carlo mutual information
    #'     \item \code{"mc_x2"} – Monte Carlo chi-squared
    #'     \item \code{"mi"} – mutual information
    #'     \item \code{"mi_adf"} – mutual information with adjusted d.f.
    #'     \item \code{"mi_sh"} – mutual information (shrinkage)
    #'     \item \code{"smc_mi"} – sequential Monte Carlo mutual information
    #'     \item \code{"smc_x2"} – sequential Monte Carlo chi-squared
    #'     \item \code{"sp_mi"} – semi-parametric mutual information
    #'     \item \code{"sp_x2"} – semi-parametric chi-squared
    #'     \item \code{"x2"} – chi-squared
    #'     \item \code{"x2_adf"} – chi-squared with adjusted d.f.
    #'   }
    #'
    #'   **Discrete – ordered factors**
    #'   \itemize{
    #'     \item \code{"jt"} – Jonckheere–Terpstra
    #'     \item \code{"mc_jt"} – Monte Carlo Jonckheere–Terpstra
    #'     \item \code{"smc_jt"} – sequential Monte Carlo Jonckheere–Terpstra
    #'   }
    #'
    #'   **Mixed Discrete/Gaussian**
    #'   \itemize{
    #'     \item \code{"mi_cg"} / \code{"conditional_gaussian"} – mutual information (conditional Gaussian)
    #'   }
    #'
    #'   For Monte Carlo tests, set the number of permutations using the `B` argument.
    test = NULL,

    #' @field alg Function generated by \code{$set_alg()} that runs a
    #'   structure-learning algorithm from \pkg{bnlearn}. Period.case alg names
    #'   (as used in \pkg{bnlearn}, e.g. "fast.iamb") are also accepted and automatically translated to snake_case.
    #'   Recognised values are:
    #'
    #'   **Constraint-based**
    #'   \itemize{
    #'     \item \code{"fast_iamb"} – Fast-IAMB algorithm. See [fast_iamb()] and the underlying [bnlearn::fast.iamb()].
    #'     \item \code{"gs"} – Grow-Shrink algorithm. See [gs()] and the underlying [bnlearn::gs()].
    #'     \item \code{"iamb"} – Incremental Association Markov Blanket algorithm.
    #'     See [iamb()] and the underlying [bnlearn::iamb()].
    #'     \item \code{"iamb_fdr"} – IAMB with FDR control algorithm. See [iamb_fdr()] and the underlying
    #'     [bnlearn::iamb.fdr()].
    #'     \item \code{"inter_iamb"} – Interleaved-IAMB algorithm. See [inter_iamb()] and the underlying
    #'     [bnlearn::inter.iamb()].
    #'     \item \code{"pc"} – PC-stable algorithm. See [pc()] and the underlying
    #'     [bnlearn::pc.stable()].
    #'   }
    #'
    # #'   **Hybrid**
    # #'   \itemize{
    # #'     \item \code{"h2pc"} – Hybrid HPC–PC
    # #'     \item \code{"mmhc"} – Max–Min Hill-Climbing
    # #'     \item \code{"rsmax2"} – Restricted Maximisation (two-stage)
    # #'   }
    #'
    # #'   **Local / skeleton discovery**
    # #'   \itemize{
    # #'     \item \code{"hpc"} – Hybrid Parents and Children
    # #'     \item \code{"mmpc"} – Max–Min Parents and Children
    # #'     \item \code{"si_hiton_pc"} – Semi-Interleaved HITON-PC
    # #'   }
    #'
    # #'   **Pairwise mutual-information learners**
    # #'   \itemize{
    # #'     \item \code{"aracne"} – ARACNE network
    # #'     \item \code{"chow_liu"} – Chow–Liu tree
    # #'   }
    #'
    # #'   **Score-based**
    # #'   \itemize{
    # #'     \item \code{"hc"} – Hill-Climbing algorithm. See [hc()] and the underlying [bnlearn::hc()].
    # #'     \item \code{"tabu"} – Tabu search algorithm. See [tabu()] and the underlying [bnlearn::tabu()].
    # #'   }
    alg = NULL,

    #' @field params A list of extra tuning parameters stored by `set_params()`
    #'   and spliced into the learner call.
    params = NULL,

    #' @field knowledge A list with elements `whitelist` and `blacklist`
    #'   containing prior-knowledge constraints added via `set_knowledge()`.
    knowledge = NULL,

    #' @description
    #' Constructor for the `BnlearnSearch` class.
    initialize = function() {
      .check_if_pkgs_are_installed(
        pkgs = c(
          "bnlearn",
          "purrr"
        ),
        class_name = "BnlearnSearch"
      )
      self$data <- NULL
      self$score <- NULL
      self$test <- NULL
      self$knowledge <- NULL
      self$params <- list()
    },

    #' @description
    #' Set the parameters for the search algorithm.
    #'
    #' @param params A parameter to set.
    set_params = function(params) {
      self$params <- params
    },

    #' @description
    #' Set the data for the search algorithm.
    #'
    #' @param data A data frame containing the data to use for the search.
    set_data = function(data) {
      self$data <- data
    },

    #' @description
    #' Set the conditional-independence test to use in the search algorithm.
    #'
    #' @param method `r lifecycle::badge("experimental")`
    #'
    #' A string specifying the type of test to use. Can also be a user-defined function with signature
    #' `function(x, y, z, data, args)`, where `x` and `y` are the variables being
    #' tested for independence, `z` is the conditioning set, `data` is the dataset, and `args` is a list of additional
    #' arguments. The function should return the test statistic and the p-value.
    #' See [bnlearn::ci.test()] for more details.
    #'
    #' EXPERIMENTAL: user-defined tests syntax are subject to change.
    #' @param alpha Significance level for the test.
    set_test = function(method, alpha = 0.05) {
      checkmate::assert_number(
        alpha,
        lower = 0,
        upper = 1,
        finite = TRUE,
        null.ok = FALSE
      )
      if (is.function(method)) {
        # Wrap the user function so it is bnlearn-compatible.
        # Store translated function and alpha in params so they survive set_alg().
        self$test <- "custom-test"
        self$params$fun <- translate_custom_test_to_bnlearn(method)
        self$params$alpha <- alpha
        private$test_key <- "custom-test"
        return(invisible(self))
      }

      method <- tolower(method)
      # Convert snake_case to kebab-case for bnlearn compatibility
      method <- gsub("_", "-", method)

      allowed_tests <- c(
        # Discrete with categorical variables
        "mi", # mutual information
        "mi-adf", # with adjusted degrees of freedom
        "mc-mi", # Monte Carlo mutual information
        "smc-mi", # sequential Monte Carlo mutual information
        "sp-mi", # semi-parametric mutual information
        "mi-sh", # mutual information shrinkage estimator
        "x2", # chi-squared test
        "x2-adf", # chi-squared test with adjusted degrees of freedom
        "mc-x2", # Monte Carlo chi-squared test
        "smc-x2", # sequential Monte Carlo chi-squared test
        "sp-x2", # semi-parametric chi-squared test

        # Discrete with ordered factors
        "jt", # Jonckheere-Terpstra test
        "mc-jt", # Monte Carlo Jonckheere-Terpstra test
        "smc-jt", # sequential Monte Carlo Jonckheere-Terpstra test

        # Gaussian variables
        "cor", # pearson correlation
        "mc-cor", # Monte Carlo pearson correlation
        "smc-cor", # sequential Monte Carlo pearson correlation
        "zf", # fisher Z test
        "fisher-z",
        "mc-zf", # Monte Carlo fisher Z test
        "smc-zf", # sequential Monte Carlo fisher Z test
        "mi-g", # mutual information for Gaussian variables
        "mc-mi-g", # Monte Carlo mutual information for Gaussian variables
        "smc-mi-g", # sequential Monte Carlo mutual inf. for Gaussian variables
        "mi-g-sh", # mutual information for Gaussian variables with shrinkage

        # Conditional Gaussian
        "mi-cg", # mutual information for conditional Gaussian variables
        "conditional-gaussian" # alias for mi-cg
      )

      if (!(method %in% allowed_tests)) {
        stop("Unknown test type using bnlearn engine: ", method, call. = FALSE)
      }
      if (method == "fisher-z") {
        method <- "zf" # alias
      }
      if (method == "conditional-gaussian") {
        method <- "mi-cg" # alias
      }

      self$params$alpha <- alpha
      self$test <- method
      invisible(self)
    },

    #' @description
    #' Set the score function for the search algorithm.
    #'
    #' @param method Character naming the score function to use.
    set_score = function(method) {
      method <- tolower(method)
      # Convert snake_case to kebab-case for bnlearn compatibility
      method <- gsub("_", "-", method)

      allowed_scores <- c(
        # Discrete with categorical variables
        "loglik", # log-likelihood
        "aic", # Akaike Information Criterion
        "bic", # Bayesian Information Criterion
        "ebic", # Extended Bayesian Information Criterion
        "pred-loglik", # predictive log-likelihood
        "bde", # Bayesian Dirichlet equivalent (uniform)
        "bds", # Bayesian Dirichlet score
        "mbde", # modified Bayesian Dirichlet equivalent
        "bdla", # locally averaged Bayesian Dirichlet
        "k2", # K2 score
        "fnml", # factorized normalized maximum likelihood score
        "qnml", # quotient normalized maximum likelihood score
        "nal", # node-average (log-)likelihood
        "pnal", # penalized node-average (log-)likelihood

        # Gaussian variables
        "loglik-g", # log-likelihood for Gaussian variables
        "aic-g", # Akaike Information Criterion for Gaussian variables
        "bic-g", # Bayesian Information Criterion for Gaussian vars
        "ebic-g", # Extended Bayesian Information Criterion for Gaussian
        "pred-loglik-g", # predictive log-likelihood for Gaussian variables
        "bge", # Gaussian posterior density
        "nal-g", # node-average (log-)likelihood for Gaussian variables
        "pnal-g", # penalized node-average (log-)likelihood for Gaussian

        # Conditional Gaussian
        "loglik-cg", # log-likelihood for cg variables
        "aic-cg", # Akaike Information Criterion for cg variables
        "bic-cg", # Bayesian Information Criterion for cg variables
        "ebic-cg", # Extended Bayesian Information Criterion cg variables
        "pred-loglik-cg", # predictive log-likelihood for cg variables
        "nal-cg", # node-average (log-)likelihood for cg variables
        "pnal-cg" # penalized node-average (log-)likelihood for cg vars
      )
      if (!(method %in% allowed_scores)) {
        stop("Unknown score type using bnlearn engine: ", method, call. = FALSE)
      }

      self$score <- method
      invisible(self)
    },

    #' @description
    #' Set the causal discovery algorithm to use.
    #'
    #' @param method Character naming the algorithm to use.
    #' @param args A list of additional arguments to pass to the algorithm.
    set_alg = function(method, args = NULL) {
      method <- tolower(method)
      # Convert snake_case to period.case
      method <- gsub("_", ".", method)

      if (!is.null(args)) {
        if (!is.list(args)) {
          stop("Arguments must be provided as a list.", call. = FALSE)
        }
        # --- Flatten alg_args into args ---
        if (!is.null(args$alg_args)) {
          if (!is.list(args$alg_args)) {
            stop("args$alg_args must be a list.", call. = FALSE)
          }
          args[names(args$alg_args)] <- args$alg_args
          args$alg_args <- NULL
        }

        if (!is.null(args$fun)) {
          args$fun <- translate_custom_test_to_bnlearn(args$fun)
        }

        # --- Flatten alg_args into args ---
        if (!is.null(args$alg_args)) {
          if (!is.list(args$alg_args)) {
            stop("args$alg_args must be a list.", call. = FALSE)
          }
          args[names(args$alg_args)] <- args$alg_args
          args$alg_args <- NULL
        }

        merged_params <- self$params
        if (is.null(merged_params)) {
          merged_params <- list()
        }
        merged_params[names(args)] <- args
        self$set_params(merged_params)
      }
      need_test <- c(
        "pc",
        "gs",
        "iamb",
        "fast.iamb",
        "inter.iamb",
        "iamb.fdr",
        "mmpc",
        "si.hiton.pc",
        "hpc"
      )
      need_score <- c("hc", "tabu")
      need_both <- c("mmhc", "rsmax2", "h2pc")
      need_restrict_maximize <- c("rsmax2")
      # guard clauses
      if (method %in% need_test && is.null(self$test)) {
        stop("No test is set. Use set_test() first.", call. = FALSE)
      }

      if (method %in% need_score && is.null(self$score)) {
        stop("No score is set. Use set_score() first.", call. = FALSE)
      }

      if (method %in% need_both) {
        if (is.null(self$test) || is.null(self$score)) {
          stop(
            "Both test and score must be set for this algorithm.",
            call. = FALSE
          )
        }
        if (
          method %in%
            need_restrict_maximize ||
            is.null(self$maximize_alg) ||
            is.null(self$restrict_alg)
        ) {
          stop(
            "Both maximize and restrict algorithms must be set for this algorithm.",
            call. = FALSE
          )
        }
      }
      self$alg <- switch(
        method,

        # constraint-based
        "pc" = purrr::partial(
          bnlearn::pc.stable,
          test = self$test,
          !!!self$params
        ),
        "gs" = purrr::partial(bnlearn::gs, test = self$test, !!!self$params),
        "iamb" = purrr::partial(
          bnlearn::iamb,
          test = self$test,
          !!!self$params
        ),
        "fast.iamb" = purrr::partial(
          bnlearn::fast.iamb,
          test = self$test,
          !!!self$params
        ),
        "inter.iamb" = purrr::partial(
          bnlearn::inter.iamb,
          test = self$test,
          !!!self$params
        ),
        "iamb.fdr" = purrr::partial(
          bnlearn::iamb.fdr,
          test = self$test,
          !!!self$params
        ),

        # local / skeleton discovery
        "mmpc" = purrr::partial(
          bnlearn::mmpc,
          test = self$test,
          !!!self$params
        ),
        "si.hiton.pc" = purrr::partial(
          bnlearn::si.hiton.pc,
          test = self$test,
          !!!self$params
        ),
        "hpc" = purrr::partial(bnlearn::hpc, test = self$test, !!!self$params),

        # score-based
        "hc" = purrr::partial(bnlearn::hc, score = self$score, !!!self$params),
        "tabu" = purrr::partial(
          bnlearn::tabu,
          score = self$score,
          !!!self$params
        ),

        # hybrid
        "mmhc" = purrr::partial(
          bnlearn::mmhc,
          !!!self$params
        ),
        "rsmax2" = purrr::partial(
          bnlearn::rsmax2,
          test = self$test,
          score = self$score,
          !!!self$params
        ),
        "h2pc" = purrr::partial(
          bnlearn::h2pc,
          !!!self$params
        ),

        # pairwise mutual-information learners
        "chow.liu" = purrr::partial(
          bnlearn::chow.liu,
          !!!self$params
        ),
        "aracne" = purrr::partial(
          bnlearn::aracne,
          !!!self$params
        ),
        stop(
          "Unknown method type using bnlearn engine: ",
          method,
          call. = FALSE
        )
      )

      invisible(self)
    },

    #' @description
    #' Set the prior knowledge for the search algorithm using a `Knowledge` object.
    #'
    #' @param knowledge_obj A `Knowledge` object containing prior knowledge.
    set_knowledge = function(knowledge_obj) {
      is_knowledge(knowledge_obj)
      self$knowledge <- as_bnlearn_knowledge(knowledge_obj)
    },

    #' @description
    #' Run the search algorithm on the currently set data.
    #'
    #' @param data A data frame containing the data to use for the search.
    #'  If NULL, the currently set data will be used, i.e. \code{self$data}.
    run_search = function(data = NULL) {
      # Data checks
      if (!is.null(data)) {
        self$set_data(data)
      }

      if (is.null(self$data)) {
        stop(
          "No data is set. Use set_data() first or pass data to run_search().",
          call. = FALSE
        )
      }

      if (is.null(self$alg)) {
        stop("No algorithm is set. Use set_alg() first.", call. = FALSE)
      }

      # Build the argument list for the algorithm call
      arg_list <- list(x = self$data) # all bnlearn learners expect `x = data`

      # knowledge
      if (!is.null(self$knowledge)) {
        if (
          !is.null(self$knowledge$whitelist) &&
            nrow(self$knowledge$whitelist) > 0
        ) {
          arg_list$whitelist <- self$knowledge$whitelist
        }

        if (
          !is.null(self$knowledge$blacklist) &&
            nrow(self$knowledge$blacklist) > 0
        ) {
          arg_list$blacklist <- self$knowledge$blacklist
        }
      }

      result <- do.call(self$alg, arg_list)
      as_disco(result)
    }
  ),
  private = list(
    test_key = NULL
  )
)
