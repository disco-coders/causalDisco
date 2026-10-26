# See https://github.com/r-lib/roxygen2/issues/1158 for why this is needed
#' @title R6 Interface to Tetrad Search Algorithms
#'
#' @name TetradSearch
#'
#' @example inst/roxygen-examples/tetrad-search-example.R
NULL

#' @title R6 Interface to Tetrad Search Algorithms
#'
#' @description
#' High-level wrapper around the Java-based \pkg{Tetrad} causal-discovery
#' library. The class lets you choose independence tests, scores, and search
#' algorithms from \pkg{Tetrad}, run them on an R data set, and retrieve the
#' resulting graph or statistics.
#'
#' @docType class
#' @name TetradSearch
#' @rdname TetradSearch
#' @importFrom R6 R6Class
#' @export
TetradSearch <- R6Class(
  "TetradSearch",
  public = list(
    #' @field data Java object that stores the (possibly converted) data set
    #'  used by \pkg{Tetrad}.
    data = NULL,

    #' @field rdata Original **R** `data.frame` supplied by the user.
    rdata = NULL,

    #' @field score Java object holding the scoring function selected with
    #'   \code{set_score()}. Supply one of the method strings for
    #'   \code{set_score()}. Recognised values are:
    #'
    #'   **Continuous - Gaussian**
    #'   \itemize{
    #'      \item \code{"ebic"} - Extended BIC score.
    #'      \item \code{"gic"} - Generalized Information Criterion (GIC) score.
    #'      \item \code{"poisson_prior"} - Poisson prior score.
    #'      \item \code{"rank_bic"} - Rank-based BIC score.
    #'      \item \code{"sem_bic"} - SEM BIC score.
    #'      \item \code{"zhang_shen_bound"} - Zhang and Shen bound score.
    #'   }
    #'
    #'   **Discrete - categorical**
    #'   \itemize{
    #'      \item \code{"bdeu"} - Bayes Dirichlet Equivalent score with uniform priors.
    #'      \item \code{"discrete_bic"} - BIC score for discrete data.
    #'   }
    #'
    #'   **Mixed Discrete/Gaussian**
    #'   \itemize{
    #'      \item \code{"basis_function_bic"} - BIC score for basis-function models.
    #'        This is a generalization of the Degenerate Gaussian score.
    #'      \item \code{"basis_function_blocks_bic"} - BIC score for mixed data using basis-function models.
    #'      \item \code{"basis_function_sem_bic"} - SEM BIC score for basis-function models.
    #'      \item \code{"conditional_gaussian"} - Conditional Gaussian BIC score.
    #'      \item \code{"degenerate_gaussian"} - Degenerate Gaussian BIC score.
    #'      \item \code{"mag_degenerate_gaussian_bic"} - MAG Degenerate Gaussian BIC Score.
    #'   }
    #'
    # #'   **General (non-linear Gaussian?)**
    # #'   \itemize{
    # #'      \item \code{"mixed_variable_polynomial"} - Mixed variable polynomial BIC score.
    # #'   }
    score = NULL,

    #' @field test Java object holding the independence test selected with
    #'   \code{set_test()}. Supply one of the method strings for
    #'   \code{set_test()}. Recognised values are:
    #'
    #'
    #'   **Continuous - Gaussian**
    #'   \itemize{
    #'     \item \code{"fisher_z"} - Fisher \eqn{Z} (partial correlation) test.
    #'     \item \code{"poisson_prior"} - Poisson prior test.
    #'     \item \code{"rank_independence"} - Rank-based independence test.
    #'     \item \code{"sem_bic"} - SEM BIC test.
    #'   }
    #'
    #'   **Discrete - categorical**
    #'   \itemize{
    #'     \item \code{"chi_square"} - chi-squared test
    #'     \item \code{"g_square"} - likelihood-ratio \eqn{G^2} test.
    #'     \item \code{"probabilistic"} - Uses BCInference by Cooper and Bui to calculate
    #'        probabilistic conditional independence judgments.
    #'   }
    #'
    #'   **General**
    #'   \itemize{
    #'     \item \code{"gin"} - Generalized Independence Noise test.
    #'     \item \code{"kci"} - Kernel Conditional Independence Test (KCI) by Kun Zhang.
    #'     \item \code{"rcit"} - Randomized Conditional Independence Test (RCIT).
    #'   }
    #'
    #'   **Mixed Discrete/Gaussian**
    #'   \itemize{
    #'     \item \code{"basis_function_blocks"} - Basis-function blocks test.
    #'     \item \code{"basis_function_lrt"} - basis-function likelihood-ratio.
    #'     \item \code{"conditional_gaussian"} - Conditional Gaussian test as a likelihood ratio test.
    #'     \item \code{"degenerate_gaussian"} - Degenerate Gaussian test as a likelihood ratio test.
    #'   }
    #'
    test = NULL,

    #' @field alg Java object representing the search algorithm.
    #'  Supply one of the method strings for \code{set_alg()}.
    #'  Recognised values are:
    #'
    #' **Constraint-based**
    #' \itemize{
    #    \item \code{"cpc"} - Conservative PC algorithm.
    #'   \item \code{"fci"} - FCI algorithm. See [fci()].
    #    \item \code{"fcit"} - FCI Targeted Testing (FCIT) algorithm.
    #'   \item \code{"pc"} - Peter-Clark (PC) algorithm. See [pc()].
    #    \item \code{"pc_max"} - PCMax algorithm.
    #'   \item \code{"rfci"} - Restricted FCI algorithm. See [rfci()].
    #' }
    #'
    #' **Hybrid**
    #' \itemize{
    #'   \item \code{"boss_fci"} - BOSS-FCI algorithm. See [boss_fci()].
    #    \item \code{"cfci"} - Adjusts FCI to use conservative orientation as in CPC.
    #'   \item \code{"gfci"} - GFCI algorithm. See [gfci()].
    #'   \item \code{"grasp_fci"} - GRaSP-FCI algorithm. See [grasp_fci()].
    #'   \item \code{"sp_fci"} - Sparsest Permutation using FCI. See [sp_fci()].
    #' }
    #'
    #' **Score-based**
    #' \itemize{
    #'   \item \code{"boss"} - BOSS algorithm. See [boss()].
    #    \item \code{"dagma"} - DAGMA algorithm.
    #    \item \code{"fask"} - FASK algorithm.
    #'   \item \code{"ges" ("fges")} - (Fast) Greedy Equivalence Search (GES) algorithm. See [ges()].
    #    \item \code{"ges_mb" ("fges_mb")} - Fast Greedy Equivalence Search with Markov Blanket (FGES-MB) algorithm.
    #'   \item \code{"grasp"} - GRaSP (Greedy Relations of Sparsest Permutation) algorithm. See [grasp()].
    # #'   \item \code{"restricted_boss"} - Restricted BOSS algorithm. See [restricted_boss()].
    #    \item \code{"sp"} - Sparsest Permutation algorithm.
    #' }
    #'
    #  **Miscellaneous**
    #  \itemize{
    #   \item \code{"ccd"} - Cyclic Causal Discovery.
    #   \item \code{"cstar"} - CStaR algorithm (Causal Stability Ranking).
    #   \item \code{"direct_lingam"} - DirectLiNGAM algorithm.
    #   \item \code{"ica_lingam"} - ICA LiNGAM algorithm.
    #   \item \code{"ica_lingd"} - ICA-LiNG-D algorithm.
    #  }
    alg = NULL,

    #' @field mc_test Java independence-test object used by the Markov checker.
    mc_test = NULL,

    #' @field java Java object returned by the search (typically a graph).
    java = NULL,

    #' @field result Convenience alias for \code{java}; may store additional
    #'  metadata depending on the search type.
    result = NULL,

    #' @field knowledge Java \code{Knowledge} object carrying background
    #'  constraints (required/forbidden edges).
    knowledge = NULL,

    #' @field params Java \code{Parameters} object holding algorithm settings.
    params = NULL,

    #' @field bootstrap_graphs Java \code{List} of graphs produced by bootstrap
    #'  resampling, if that feature was requested.
    bootstrap_graphs = NULL,

    #' @field mc_ind_results Java \code{List} with Markov-checker test results.
    mc_ind_results = NULL,

    #' @description Initializes the \code{TetradSearch} object, creating new Java objects for
    #'   \code{knowledge} and \code{params}.
    initialize = function() {
      .check_if_pkgs_are_installed(
        pkgs = c(
          "rJava"
        ),
        function_name = "TetradSearch"
      )

      if (!rJava::.jniInitialized) {
        init_java() # nocov
      }
      self$data <- NULL
      self$score <- NULL
      self$test <- NULL
      self$mc_test <- NULL
      self$knowledge <- rJava::.jnew("edu/cmu/tetrad/data/Knowledge")
      self$params <- rJava::.jnew("edu/cmu/tetrad/util/Parameters")
      self$bootstrap_graphs <- NULL
      self$set_verbose(FALSE) # Set verbose to FALSE per default.
    },

    #' @description Sets the independence test to use in Tetrad.
    #' @param method (character) Name of the test method (e.g., "chi_square", "fisher_z").
    #'   \itemize{
    #'     \item \code{"basis_function_blocks"} - Basis-function blocks test
    #'     \item \code{"basis_function_lrt"} - basis-function likelihood-ratio
    #'     \item \code{"chi_square"} - chi-squared test
    #'     \item \code{"conditional_gaussian"} - Mixed discrete/continuous test
    #'     \item \code{"degenerate_gaussian"} - Degenerate Gaussian test as a likelihood ratio test
    #'     \item \code{"fisher_z"} - Fisher \(Z\) (partial correlation) test
    #'     \item \code{"gin"} - Generalized Independence Noise test
    #'     \item \code{"kci"} - Kernel Conditional Independence Test (KCI) by Kun Zhang
    #'     \item \code{"poisson_prior"} - Poisson prior test
    #'     \item \code{"probabilistic"} - Uses BCInference by Cooper and Bui to calculate
    #'        probabilistic conditional independence judgments.
    #'     \item \code{"rcit"} - Randomized Conditional Independence Test (RCIT)
    #'     \item \code{"rank_independence"} - Rank-based independence test
    #'     \item \code{"sem_bic"} - SEM BIC test
    #'   }
    #' @param ... Additional arguments passed to the private test-setting methods.
    #'   For the following tests, the following parameters are available:
    #'   \itemize{
    #'      \item \code{"basis_function_blocks"} - Basis-function blocks test.
    #'       \itemize{
    #'         \item \code{alpha = 0.05} - Significance level for the
    #'         independence test,
    #'         \item \code{basis_type = "polynomial"} - The type of basis to use. Supported
    #'         types are \code{"polynomial"}, \code{"legendre"}, \code{"hermite"}, and
    #'         \code{"chebyshev"},
    #'         \item \code{truncation_limit = 3} - Basis functions 1 through
    #'         this number will be used. The Degenerate Gaussian category
    #'         indicator variables for mixed data are also used.
    #'      }
    #'      \item \code{"basis_function_lrt"} - basis-function likelihood-ratio
    #'       \itemize{
    #'         \item \code{truncation_limit = 3} - Basis functions 1 through
    #'         this number will be used. The Degenerate Gaussian category
    #'         indicator variables for mixed data are also used,
    #'         \item \code{alpha = 0.05} - Significance level for the
    #'         likelihood-ratio test,
    #'         \item \code{singularity_lambda = 0.0} - Small number >= 0: Add
    #'         lambda to the diagonal, < 0 Pseudoinverse,
    #'         \item \code{do_one_equation_only = FALSE} - If TRUE, only one
    #'         equation should be used when expanding the basis.
    #'       }
    #'       \item \code{"chi_square"} - chi-squared test
    #'       \itemize{
    #'         \item \code{min_count = 1} - Minimum count for the chi-squared
    #'         test per cell. Increasing this can improve accuracy of the test
    #'         estimates,
    #'         \item \code{alpha = 0.05} - Significance level for the
    #'         independence test,
    #'         \item \code{cell_table_type = "ad"} - The type of cell table to
    #'         use for optimization. Available types are:
    #'         \code{"ad"} - AD tree, \code{"count"} - Count sample.
    #'       }
    #'       \item \code{"conditional_gaussian"} - Mixed discrete/continuous test
    #'       \itemize{
    #'         \item \code{alpha = 0.05} - Significance level for the
    #'         independence test,
    #'         \item \code{discretize = TRUE} - If TRUE for the conditional
    #'         Gaussian likelihood, when scoring X --> D where X is continuous
    #'         and D discrete, one should simply discretize X for just
    #'         those cases.
    #'         If FALSE, the integration will be exact,
    #'         \item \code{num_categories_to_discretize = 3} - In case the exact
    #'         algorithm is not used for discrete children and continuous
    #'         parents is not used, this parameter gives the number of
    #'         categories to use for this second (discretized) backup copy of
    #'         the continuous variables,
    #'         \item \code{min_sample_size_per_cell = 4} - Minimum sample size
    #'         per cell for the independence test.
    #'       }
    #'       \item \code{"degenerate_gaussian"} - Degenerate Gaussian
    #'       likelihood ratio test
    #'       \itemize{
    #'         \item \code{alpha = 0.05} - Significance level for the
    #'         independence test,
    #'         \item \code{singularity_lambda = 0.0} - Small number >= 0: Add
    #'         lambda to the diagonal, < 0 Pseudoinverse.
    #'       }
    #'       \item \code{"fisher_z"} - Fisher \(Z\) (partial correlation) test
    #'       \itemize{
    #'         \item \code{alpha = 0.05} - Significance level for the independence test,
    #'         \item \code{singularity_lambda = 0.0} - Small number >= 0: Add
    #'         lambda to the diagonal, < 0 Pseudoinverse.
    #'       }
    #'       \item \code{"gin"} - Generalized Independence Noise test.
    #'       \itemize{
    #'         \item \code{alpha = 0.05} - Significance level for the
    #'         independence test,
    #'         \item \code{gin_backend = "dcor"} - Unconditional test for residual
    #'         independence. Available types are \code{"dcor"} - Distance correlation (for non-linear)
    #'         and \code{"pearson"} - Pearson correlation (for linear),
    #'         \item \code{num_permutations = 200} - Number of permutations used for
    #'         \code{"dcor"} backend. If \code{"pearson"} backend is used, this parameter is ignored.
    #'         \item \code{gin_ridge = 1e-8} - Ridge parameter used when computing residuals.
    #'         A small number >= 0.
    #'         \item \code{seed = -1} - Random seed for the independence test. If -1, no seed is set.
    #'       }
    #'       \item \code{"kci"} - Kernel Conditional Independence Test (KCI) by Kun Zhang
    #'       \itemize{
    #'         \item \code{alpha = 0.05} - Significance level for the
    #'         independence test,
    #'         \item \code{approximate = TRUE} - If TRUE, use the approximate
    #'         Gamma approximation algorithm. If FALSE, use the exact,
    #'         \item \code{scaling_factor = 1} - For Gaussian kernel: The
    #'         scaling factor * Silverman bandwidth.
    #'         \item \code{num_bootstraps = 1000} - Number of bootstrap
    #'         samples to use for the KCI test. Only used if \code{approximate = FALSE}.
    #'         \item \code{threshold = 1e-3} - Threshold for the KCI test.
    #'         Threshold to determine how many eigenvalues to use --
    #'         the lower the more (0 to 1).
    #'         \item \code{kernel_type = "gaussian"} - The type of kernel to
    #'         use. Available types are \code{"gaussian"}, \code{"linear"}, or
    #'         \code{"polynomial"}.
    #'         \item \code{polyd = 5} - The degree of the polynomial kernel,
    #'         if used.
    #'         \item \code{polyc = 1} - The constant of the polynomial kernel,
    #'         if used.
    #'       }
    #'       \item \code{"poisson_prior"} - Poisson prior test
    #'       \itemize{
    #'         \item \code{poisson_lambda = 1} - Lambda parameter for the Poisson
    #'         distribution (> 0),
    #     #'   \item \code{precompute_covariances = TRUE} - For more than 5000
    #     #'   variables or so, set this to FALSE in order to calculate
    #     #'   covariances on the fly from data,
    #'         \item \code{singularity_lambda = 0.0} - Small number >= 0: Add
    #'         lambda to the diagonal, < 0 Pseudoinverse.
    #'       }
    #'       \item \code{"probabilistic"} - Uses BCInference by Cooper and Bui
    #'       to calculate probabilistic conditional independence judgments.
    #'       \itemize{
    #'         \item \code{threshold = FALSE} - Set to TRUE if using the cutoff
    #'         threshold for the independence test,
    #'         \item \code{cutoff = 0.5} - Cutoff for the independence test,
    #'         \item \code{prior_ess = 10} - Prior equivalent sample size
    #'         for the independence test. This number is added to the sample
    #'         size for each conditional probability table in the model and is
    #'         divided equally among the cells in the table.
    #'       }
    #'       \item \code{"rcit"} - Randomized Conditional Independence Test (RCIT).
    #'       \itemize{
    #'         \item \code{alpha = 0.05} - Significance level for the
    #'         independence test,
    #'         \item \code{rcit_approx = "lpb4"} - Null approximation method. Recognized values are:
    #'         \code{"lpb4"} - Lindsay-Pilla-Basak method with 4 support points,
    #'         \code{"hbe"} - Hall-Buckley-Eagleson method,
    #'         \code{"gamma"} - Gamma (Satterthwaite-Welch),
    #'         \code{"chi_square"} - Chi-square (normalized),
    #'         \code{"permutation"} - Permutation-based (computationally intensive),
    #'         \item \code{rcit_ridge = 1e-3} - Ridge parameter used when computing residuals.
    #'         A small number >= 0,
    #'         \item \code{num_feat = 10} - Number of random features to use
    #'         for the regression of X and Y on Z. Values between 5 and 20 often suffice.
    #'         \item \code{num_fourier_feat_xy = 5} - Number of random Fourier features to use for
    #'         the tested variables X and Y. Small values often suffice (e.g., 3 to 10),
    #'         \item \code{num_fourier_feat_z = 100} - Number of random Fourier features to use for
    #'         the conditioning set Z. Values between 50 and 300 often suffice,
    #'         \item \code{center_features = TRUE} - If TRUE, center the random features to have mean zero. Recommended
    #'         for better numerical stability,
    #'         \item \code{use_rcit = TRUE} - If TRUE, use RCIT; if FALSE, use RCoT
    #'         (Randomized Conditional Correlation Test),
    #'         \item \code{num_permutations = 500} - Number of permutations used for
    #'         the independence test when \code{rcit_approx = "permutation"} is selected.
    #'         \item \code{seed = -1} - Random seed for the independence test. If -1, no seed is set.
    #'       }
    #'       \item \code{"rank_independence"} - Rank-based independence test.
    #'       \itemize{
    #'         \item \code{alpha = 0.05} - Significance level for the
    #'         independence test.
    #'       }
    #'       \item \code{"sem_bic"} - SEM BIC test.
    #'       \itemize{
    #'         \item \code{penalty_discount = 2} - Penalty discount factor used in
    #'         BIC = 2L - ck log N, where c is the penalty. Higher c yield sparser
    #'         graphs,
    #'         \item \code{structure_prior = 0} - The default number of parents
    #'         for any conditional probability table. Higher weight is accorded
    #'         to tables with about that number of parents. The prior structure
    #'         weights are distributed according to a binomial distribution,
    #     #'   \item \code{precompute_covariances = TRUE} - For more than 5000
    #     #'   variables or so, set this to FALSE in order to calculate
    #     #'   covariances on the fly from data,
    #'         \item \code{singularity_lambda = 0.0} - Small number >= 0: Add
    #'         lambda to the diagonal, < 0 Pseudoinverse.
    #'       }
    #'     }
    #' @param use_for_mc (logical) If TRUE, sets this test for the Markov checker \code{mc_test}.
    #' @return Invisibly returns \code{self}, for chaining.
    set_test = function(method, ..., use_for_mc = FALSE) {
      checkmate::assert_logical(use_for_mc, len = 1)

      method <- tolower(method)
      switch(
        method,
        "chi_square" = {
          private$use_chi_square_test(..., use_for_mc = use_for_mc)
        },
        "fisher_z" = {
          private$use_fisher_z_test(..., use_for_mc = use_for_mc)
        },
        "cci" = {
          private$use_cci_test(..., use_for_mc = use_for_mc)
        },
        "basis_function_lrt" = {
          private$use_basis_function_lrt_test(..., use_for_mc = use_for_mc)
        },
        "conditional_gaussian" = {
          private$use_conditional_gaussian_test(..., use_for_mc = use_for_mc)
        },
        "degenerate_gaussian" = {
          private$use_degenerate_gaussian_test(..., use_for_mc = use_for_mc)
        },
        "g_square" = {
          private$use_g_square_test(..., use_for_mc = use_for_mc)
        },
        "kci" = {
          private$use_kci_test(..., use_for_mc = use_for_mc)
        },
        "probabilistic" = {
          private$use_probabilistic_test(..., use_for_mc = use_for_mc)
        },
        "poisson_prior" = {
          private$use_poisson_prior_test(..., use_for_mc = use_for_mc)
        },
        "gin" = {
          private$use_gin_test(..., use_for_mc = use_for_mc)
        },
        "rcit" = {
          private$use_rcit_test(..., use_for_mc = use_for_mc)
        },
        "sem_bic" = {
          private$use_sem_bic_test(..., use_for_mc = use_for_mc)
        },
        "rank_independence" = {
          private$use_rank_independence_test(..., use_for_mc = use_for_mc)
        },
        "basis_function_blocks" = {
          private$use_basis_function_blocks_test(..., use_for_mc = use_for_mc)
        },
        {
          stop("Unknown test type using tetrad engine: ", method, call. = FALSE)
        }
      )
      invisible(self)
    },

    #' @description Sets the scoring function to use in Tetrad.
    #' @param method (character) Name of the score (e.g., "sem_bic", "ebic", "bdeu").
    #'   \itemize{
    #'      \item \code{"bdeu"} - Bayes Dirichlet Equivalent score with uniform priors.
    #'      \item \code{"basis_function_bic"} - BIC score for basis-function models.
    #'          This is a generalization of the Degenerate Gaussian score.
    #'      \item \code{"basis_function_blocks_bic"} - BIC score for mixed data using basis-function models.
    #'      \item \code{"basis_function_sem_bic"} - SEM BIC score for basis-function models.
    #'      \item \code{"conditional_gaussian"} - Mixed discrete/continuous BIC score.
    #'      \item \code{"degenerate_gaussian"} - Degenerate Gaussian BIC score.
    #'      \item \code{"discrete_bic"} - BIC score for discrete data.
    #'      \item \code{"ebic"} - Extended BIC score.
    #'      \item \code{"gic"} - Generalized Information Criterion (GIC) score.
    #'      \item \code{"mag_degenerate_gaussian_bic"} - MAG Degenerate Gaussian BIC Score.
    #       \item \code{"mixed_variable_polynomial"} - Mixed variable polynomial BIC score.
    #'      \item \code{"poisson_prior"} - Poisson prior score.
    #'      \item \code{"rank_bic"} - Rank-based BIC score.
    #'      \item \code{"sem_bic"} - SEM BIC score.
    #'      \item \code{"zhang_shen_bound"} - Zhang and Shen bound score.
    #'   }

    #' @param ... Additional arguments passed to the private score-setting methods.
    #'    For the following scores, the following parameters are available:
    #'   \itemize{
    #'      \item \code{"bdeu"} - Bayes Dirichlet Equivalent score with uniform priors.
    #'      \itemize{
    #'        \item \code{sample_prior = 10} - This sets the prior equivalent
    #'        sample size. This number is added to the sample size for each
    #'        conditional probability table in the model and is divided equally
    #'        among the cells in the table,
    #'        \item \code{singularity_lambda = 0.0} - Small number >= 0: Add
    #'        lambda to the diagonal, < 0 Pseudoinverse.
    #'      }
    #'      \item \code{"basis_function_bic"} - BIC score for basis-function models.
    #'      This is a generalization of the Degenerate Gaussian score.
    #'      \itemize{
    #'        \item \code{truncation_limit = 3} - Basis functions 1 though this
    #'        number will be used. The Degenerate Gaussian category indicator
    #'        variables for mixed data are also used,
    #'        \item \code{penalty_discount = 2} - Penalty discount. Higher penalty
    #'        yields sparser graphs,
    #'        \item \code{singularity_lambda = 0.0} - Small number >= 0: Add
    #'        lambda to the diagonal, < 0 Pseudoinverse,
    #'        \item \code{do_one_equation_only = FALSE} - If TRUE, only one
    #'        equation should be used when expanding the basis.
    #'      }
    #'      \item \code{"basis_function_blocks_bic"} - BIC score for mixed data using basis-function models.
    #'      \itemize{
    #'        \item \code{basis_type = "polynomial"} - The type of basis to use. Supported
    #'        types are \code{"polynomial"}, \code{"legendre"}, \code{"hermite"}, and
    #'        \code{"chebyshev"},
    #'        \item \code{penalty_discount = 2} - Penalty discount factor used in
    #'        BIC = 2L - ck log N, where c is the penalty. Higher c yield sparser
    #'        graphs,
    #'        \item \code{truncation_limit = 3} - Basis functions 1 through this number will be used.
    #'        The Degenerate Gaussian category indicator variables for mixed data are also used.
    #'      }
    #'      \item \code{"basis_function_sem_bic"} - SEM BIC score for basis-function models.
    #'      \itemize{
    #'        \item \code{penalty_discount = 2} - Penalty discount factor used in
    #'        BIC = 2L - ck log N, where c is the penalty. Higher c yield sparser
    #'        graphs,
    #'        \item \code{jitter = 1e-8} - Small non-negative constant added to the diagonal of
    #'        covariance/correlation matrices for numerical stability,
    #'        \item \code{truncation_limit = 3} - Basis functions 1 through this number will be used.
    #'        The Degenerate Gaussian category indicator variables for mixed data are also used.
    #'      }
    #'      \item \code{"conditional_gaussian"} - Mixed discrete/continuous BIC score.
    #'      \itemize{
    #'        \item \code{penalty_discount = 1} - Penalty discount. Higher penalty
    #'        yields sparser graphs,
    #'        \item \code{discretize = TRUE} - If TRUE for the conditional
    #'         Gaussian likelihood, when scoring X --> D where X is continuous and
    #'         D discrete, one should simply discretize X for just those cases.
    #'         If FALSE, the integration will be exact,
    #'        \item \code{num_categories_to_discretize = 3} -  In case the exact
    #'         algorithm is not used for discrete children and continuous parents
    #'         is not used, this parameter gives the number of categories to use
    #'         for this second (discretized) backup copy of the continuous
    #'         variables,
    #'        \item \code{structure_prior = 0} - The default number of parents
    #'          for any conditional probability table. Higher weight is accorded
    #'          to tables with about that number of parents. The prior structure
    #'          weights are distributed according to a binomial distribution.
    #'      }
    #'      \item \code{"degenerate_gaussian"} - Degenerate Gaussian BIC score.
    #'      \itemize{
    #'        \item \code{penalty_discount = 1} - Penalty discount. Higher penalty
    #'        yields sparser graphs,
    #'        \item \code{structure_prior = 0} - The default number of parents
    #'        for any conditional probability table. Higher weight is accorded
    #'        to tables with about that number of parents. The prior structure
    #'        weights are distributed according to a binomial distribution,
    #'        \item \code{singularity_lambda = 0.0} - Small number >= 0: Add
    #'        lambda to the diagonal, < 0 Pseudoinverse.
    #     #'   \item \code{precompute_covariances = TRUE} - For more than 5000
    #     #'   variables or so, set this to FALSE in order to calculate
    #     #'   covariances on the fly from data.
    #'      }
    #'      \item \code{"discrete_bic"} - BIC score for discrete data.
    #'      \itemize{
    #'        \item \code{penalty_discount = 2} - Penalty discount. Higher penalty
    #'        yields sparser graphs,
    #'        \item \code{structure_prior = 0} - The default number of parents
    #'        for any conditional probability table. Higher weight is accorded
    #'        to tables with about that number of parents. The prior structure
    #'        weights are distributed according to a binomial distribution.
    #'      }
    #'      \item \code{"ebic"} - Extended BIC score.
    #'      \itemize{
    #'        \item \code{gamma} - The gamma parameter in the EBIC score.
    #     #'      \item \code{precompute_covariances = TRUE} - For more than 5000
    #     #'      variables or so, set this to FALSE in order to calculate
    #     #'      covariances on the fly from data,
    #'        \item \code{singularity_lambda = 0.0} - Small number >= 0: Add
    #'        lambda to the diagonal, < 0 Pseudoinverse.
    #'      }
    #'      \item \code{"gic"} - Generalized Information Criterion (GIC) score.
    #'      \itemize{
    #'        \item \code{penalty_discount = 1} - Penalty discount. Higher penalty
    #'        yields sparser graphs,
    #'        \item \code{sem_gic_rule = "bic"} - The following rules are available:
    #'        \code{"bic"} - \eqn{\ln n},
    #'        \code{"gic2"} - \eqn{p n^{1/3}},
    #'        \code{"ric"} - \eqn{2 \ln(p n)},
    #'        \code{"ricc"} - \eqn{2(\ln(p n) + \ln\ln(p n))},
    #'        \code{"gic6"} - \eqn{\ln n \ln(p n)}.
    #     #'      \item \code{precompute_covariances = TRUE} - For more than 5000
    #     #'      variables or so, set this to FALSE in order to calculate
    #     #'      covariances on the fly from data,
    #'        \item \code{singularity_lambda = 0.0} - Small number >= 0: Add
    #'        lambda to the diagonal, < 0 Pseudoinverse.
    #'      }
    #'      \item \code{"mag_degenerate_gaussian_bic"} - MAG Degenerate Gaussian BIC Score.
    #'      \itemize{
    #'        \item \code{penalty_discount = 1} - Penalty discount. Higher penalty
    #'        yields sparser graphs,
    #'        \item \code{structure_prior = 0} - The default number of parents
    #'        for any conditional probability table. Higher weight is accorded
    #'        to tables with about that number of parents. The prior structure
    #'        weights are distributed according to a binomial distribution,
    #     #'      \item \code{precompute_covariances = TRUE} - For more than 5000
    #     #'      variables or so, set this to FALSE in order to calculate
    #     #'      covariances on the fly from data.
    #'      }
    #       \item \code{"mixed_variable_polynomial"} - Mixed variable polynomial BIC score.
    #'      \item \code{"poisson_prior"} - Poisson prior score.
    #'      \itemize{
    #'        \item \code{poisson_lambda = 1} - Lambda parameter for the Poisson
    #'        distribution (> 0),
    #     #'      \item \code{precompute_covariances = TRUE} - For more than 5000
    #     #'      variables or so, set this to FALSE in order to calculate
    #     #'      covariances on the fly from data,
    #'        \item \code{singularity_lambda = 0.0} - Small number >= 0: Add
    #'        lambda to the diagonal, < 0 Pseudoinverse.
    #'      }
    #'      \item \code{"sem_bic"} - SEM BIC score.
    #'      \itemize{
    #'        \item \code{penalty_discount = 2} - Penalty discount factor used in
    #'        BIC = 2L - ck log N, where c is the penalty. Higher c yield sparser
    #'        graphs,
    #'        \item \code{structure_prior = 0} - The default number of parents
    #'        for any conditional probability table. Higher weight is accorded
    #'        to tables with about that number of parents. The prior structure
    #'        weights are distributed according to a binomial distribution,
    #     #'      \item \code{precompute_covariances = TRUE} - For more than 5000
    #     #'      variables or so, set this to FALSE in order to calculate
    #     #'      covariances on the fly from data,
    #'        \item \code{singularity_lambda = 0.0} - Small number >= 0: Add
    #'        lambda to the diagonal, < 0 Pseudoinverse.
    #'      }
    #'      \item \code{"rank_bic"} - Rank-based BIC score.
    #'      \itemize{
    #'        \item \code{gamma = 0.8} - Gamma parameter for Extended BIC (Chen and Chen, 2008). Between 0 and 1,
    #'        \item \code{penalty_discount = 2} - Penalty discount factor used in
    #'        BIC = 2L - ck log N, where c is the penalty. Higher c yield sparser
    #'        graphs.
    #'      }
    #'      \item \code{"zhang_shen_bound"} - Zhang and Shen bound score.
    #'      \itemize{
    #'        \item \code{risk_bound = 0.2} - This is the probability of getting
    #'        the true model if a correct model is discovered. Could underfit.
    #     #'      \item \code{precompute_covariances = TRUE} - For more than 5000
    #     #'      variables or so, set this to FALSE in order to calculate
    #     #'      covariances on the fly from data,
    #'        \item \code{singularity_lambda = 0.0} - Small number >= 0: Add
    #'        lambda to the diagonal, < 0 Pseudoinverse.
    #'      }
    #'   }
    #'
    #' @return Invisibly returns \code{self}.
    set_score = function(method, ...) {
      method <- tolower(method)
      switch(
        method,
        "sem_bic" = {
          private$use_sem_bic_score(...)
        },
        "ebic" = {
          private$use_ebic_score(...)
        },
        "bdeu" = {
          private$use_bdeu_score(...)
        },
        "basis_function_bic" = {
          private$use_basis_function_bic_score(...)
        },
        "conditional_gaussian" = {
          private$use_conditional_gaussian_score(...)
        },
        "degenerate_gaussian" = {
          private$use_degenerate_gaussian_score(...)
        },
        "discrete_bic" = {
          private$use_discrete_bic_score(...)
        },
        "gic" = {
          private$use_gic_score(...)
        },
        "mag_degenerate_gaussian_bic" = {
          private$use_mag_degenerate_gaussian_bic_score(...)
        },
        #"mixed_variable_polynomial" = {
        #  private$use_mixed_variable_polynomial_score(...)
        #},
        "poisson_prior" = {
          private$use_poisson_prior_score(...)
        },
        "zhang_shen_bound" = {
          private$use_zhang_shen_bound_score(...)
        },
        "basis_function_blocks_bic" = {
          private$use_basis_function_blocks_bic_score(...)
        },
        "basis_function_sem_bic" = {
          private$use_basis_function_sem_bic_score(...)
        },
        "rank_bic" = {
          private$use_rank_bic_score(...)
        },
        {
          stop(
            "Unknown score type using tetrad engine: ",
            method,
            call. = FALSE
          )
        }
      )
      invisible(self)
    },

    #' @description Sets the causal discovery algorithm to use in Tetrad.
    #' @param method (character) Name of the algorithm (e.g., "fges", "pc",
    #'  "fci", etc.).
    #' @param ... Additional parameters passed to the private algorithm-setting
    #' methods.
    #' For the following algorithms, the following parameters are available:
    #' \itemize{
    #'   \item \code{"boss"} - BOSS algorithm.
    #'    \itemize{
    #'      \item \code{num_starts = 1} - The number of times the algorithm
    #'      should be started from different initializations. By default, the
    #'       algorithm will be run through at least once using the initialized
    #'       parameters,
    #'      \item \code{use_bes = TRUE} - If TRUE, the algorithm uses the
    #'       backward equivalence search from the GES algorithm as one of its
    #'        steps,
    #'      \item \code{use_data_order = TRUE} - If TRUE, the data variable
    #'       order should be used for the first initial permutation,
    #'      \item \code{output_cpdag = TRUE} - If TRUE, the DAG output of the
    #'      algorithm is converted to a CPDAG,
    #'      \item \code{num_threads = 1} - Number of threads to use for the
    #'       search,
    #'      \item \code{seed = -1} - Seed for Tetrad's random number generator.
    #'       If -1, no seed is set.
    #'    }
    #'  \item \code{"boss_fci"} - BOSS-FCI algorithm.
    #'   \itemize{
    #'    \item \code{depth = -1} - Maximum size of conditioning set.
    #'     Set to -1 for unlimited,
    #'    \item \code{max_disc_path_length = -1} - Maximum length for any
    #'     discriminating path. Set to -1 for unlimited,
    #'    \item \code{use_bes = TRUE} - If TRUE, the algorithm uses the
    #'     backward equivalence search from the GES algorithm as one of its
    #'     steps,
    #'    \item \code{use_heuristic = FALSE} - If TRUE, use the max p heuristic
    #'     version,
    #'    \item \code{complete_rule_set_used = TRUE} -  FALSE if the (simpler)
    #'     final orientation rules set due to P. Spirtes, guaranteeing arrow
    #'     completeness, should be used; TRUE if the (fuller) set due to
    #'     J. Zhang, should be used guaranteeing additional tail completeness,
    #'    \item \code{guarantee_pag = FALSE} - Ensure the output is a legal PAG
    #'     (where feasible),
    #'    \item \code{num_starts = 1} - The number of times the algorithm
    #'     should be started from different initializations,
    #'    \item \code{num_threads = 1} - Number of threads to use for the
    #'     search,
    #'    \item \code{exclude_selection_bias = FALSE} - If TRUE, exclude the
    #'     possibility of selection bias.
    #'   }
    #    \item \code{"ccd"} - Cyclic Causal Discovery.
    #     \itemize{
    #       \item \code{apply_r1 = TRUE} - Set this parameter to FALSE if a
    #        chain of directed edges pointing in the same direction, when only
    #        the first few such orientations are justified based on the data,
    #       \item \code{fdr_q = 0} - False discovery rate q value. If 0, FDR
    #        control is not used.
    #     }
    #    \item \code{"cfci"} - Adjusts FCI to use conservative orientation as in
    #     CPC.
    #     \itemize{
    #       \item \code{depth = -1} - Maximum size of conditioning set,
    #       \item \code{max_disc_path_length = -1} - Maximum length for any
    #       discriminating path,
    #       \item \code{complete_rule_set_used = TRUE} - FALSE if the (simpler)
    #       final orientation rules set due to P. Spirtes, guaranteeing arrow
    #       completeness, should be used; TRUE if the (fuller) set due to
    #       J. Zhang, should be used guaranteeing additional tail completeness,
    #       \item \code{do_possible_dsep = TRUE} - If TRUE, the possible d-sep
    #       search is done.
    #     }
    #    \item \code{"cpc"} - Conservative PC algorithm.
    #     \itemize{
    #       \item \code{depth = -1} - Maximum size of conditioning set,
    #       \item \code{stable_fas = TRUE} - If TRUE, the "stable" version of
    #        the PC adjacency search is used, which for k > 0 fixes the graph
    #        for depth k + 1 to that of the previous depth k,
    #       \item \code{allow_bidirected = FALSE} - If TRUE, collider conflicts
    #        are shown as bidirected edges.
    #     }
    #    \item \code{"cstar"} - CStaR algorithm (Causal Stability Ranking).
    #     \itemize{
    #       \item \code{targets = ""} - Target names (comma or space separated),
    #       \item \code{file_out_path = "cstar_out"} -  Path to a directory in
    #        which results can be stored
    #       \item \code{selection_min_effect = 0.0} - Minimum effect size for
    #        listing effects in the CStaR table
    #       \item \code{num_subsamples = 50} -  CStaR works by generating
    #        subsamples and summarizing across them;
    #        this specifies the number of subsamples to generate.
    #        Must be >= 1,
    #       \item \code{top_bracket = 10} - Top bracket to look for causes in,
    #       \item \code{parallelized = FALSE} - If TRUE, the algorithm should
    #        be parallelized,
    #       \item \code{cpdag_algorithm = "restricted_boss"} - The CPDAG algorithm to use.
    #       \code{"pc"} corresponds to PC Stable, \code{"fges"} selects the FGES algorithm,
    #       \code{"boss"} selects the BOSS algorithm, and \code{"restricted_boss"} selects
    #       the restricted BOSS variant.
    #       \item \code{remove_effect_nodes = TRUE} - If TRUE, the effect nodes
    #       should be removed from possible causes,
    #       \item \code{sample_style = "subsample"} - The sampling style to use. Available options are
    #       \code{"subsample"} and \code{"bootstrap"}.
    #    }
    #    \item \code{"dagma"} - DAGMA algorithm.
    #     \itemize{
    #       \item \code{lambda1 = 0.05} - Tuning parameter for DAGMA,
    #       \item \code{w_threshold = 0.1} - Second tuning parameter for DAGMA,
    #       \item \code{cpdag = TRUE} - The algorithm returns a DAG;
    #       if this is set to TRUE, this DAG is converted to a CPDAG.
    #    }
    #    \item \code{"direct_lingam"} - DirectLiNGAM algorithm. No parameters.
    #    \item \code{"fask"} - FASK algorithm.
    #     \itemize{
    #       \item \code{alpha = 0.05} - Significance level for the
    #       independence test,
    #       \item \code{depth = -1} - Maximum size of conditioning set,
    #       \item \code{fask_delta = -0.3} - The bias for orienting with
    #       negative coefficients (\code{0} means no bias) for \code{FASK v1},
    #       \item \code{left_right_rule = 1} - The FASK left right rule v2 is
    #       default, but two other (related) left-right rules are given for
    #       relation to the literature, and the v1 FASK rule is included for
    #       backward compatibility,
    #       \item \code{skew_edge_threshold = 0.3} - For FASK, this includes an
    #       adjacency `X --- Y` in the model if
    #       `|corr(X, Y | X > 0) - corr(X, Y | Y > 0)|`
    #       exceeds some threshold.
    #    }
    #'   \item \code{"fci"} - FCI algorithm.
    #'    \itemize{
    #'      \item \code{depth = -1} - Maximum size of conditioning set.
    #'        Set to -1 for unlimited,
    #'      \item \code{stable_fas = TRUE} - If TRUE, the "stable" version of
    #'       the PC adjacency search is used, which for k > 0 fixes the graph
    #'       for depth k + 1 to that of the previous depth k.
    #'      \item \code{max_disc_path_length = -1} - Maximum length for any
    #'       discriminating path. Set to -1 for unlimited,
    #'      \item \code{complete_rule_set_used = TRUE} - FALSE if the (simpler)
    #'       final orientation rules set due to P. Spirtes, guaranteeing arrow
    #'       completeness, should be used; TRUE if the (fuller) set due to
    #'       J. Zhang, should be used guaranteeing additional tail completeness.
    #'      \item \code{guarantee_pag = FALSE} - Ensure the output is a legal
    #'       PAG (where feasible),
    #'      \item \code{collider_orientation_style = "max_p"} - How unshielded
    #'       colliders are oriented in the initial step.
    #'       \code{"sepsets"} orients a collider if Z is not in the separating
    #'       set of X and Y found during the adjacency search (as in the
    #'       original FCI). \code{"conservative"} orients a collider only if Z
    #'       is in none of the separating sets of X and Y, and leaves the
    #'       triple unoriented if they disagree. \code{"max_p"} orients a
    #'       collider if Z is not in the separating set with the highest
    #'       p-value,
    #'      \item \code{do_possible_dsep = TRUE} - If TRUE, the possible d-sep
    #'       search is done,
    #'      \item \code{exclude_selection_bias = FALSE} - If TRUE, exclude the
    #'       possibility of selection bias,
    #'      \item \code{fdr_q = 0} - False discovery rate q value. If 0, FDR
    #'       control is not used.
    #'    }
    #    \item \code{"fcit"} - FCI Targeted Testing (FCIT) algorithm
    #    \itemize{
    #      \item \code{use_bes = TRUE} - If TRUE, the algorithm uses the
    #      backward equivalence search from the GES algorithm as one of its
    #      steps,
    #      \item \code{use_data_order = TRUE} - If TRUE, the data variable
    #      order should be used for the first initial permutation,
    #      \item \code{num_starts = 1} - The number of times the algorithm
    #      should be started from different initializations. By default, the
    #      algorithm will be run through at least once using the initialized
    #      parameters,
    #      \item \code{start_with = "BOSS"} - What algorithm to run first to get
    #      the initial CPDAG that the rest of the FCIT procedure refines. Available
    #      options are: \code{"BOSS"}, \code{"GRaSP"}, and \code{"SP"}.
    #      \item \code{complete_rule_set_used = TRUE} - FALSE if the (simpler)
    #      final orientation rules set due to P. Spirtes, guaranteeing arrow
    #      completeness, should be used; TRUE if the (fuller) set due to
    #      J. Zhang, should be used guaranteeing additional tail completeness,
    #      \item \code{depth = -1} - Maximum size of conditioning set,
    #      \item \code{exclude_selection_bias = FALSE} - If TRUE, exclude the
    #      possibility of selection bias.
    #   }
    #'   \item \code{"ges" ("fges")} - Fast Greedy Equivalence Search (FGES) algorithm.
    #'    \itemize{
    #'      \item \code{symmetric_first_step = FALSE} - If TRUE, scores for both
    #'       X --> Y and X <-- Y will be calculated and the higher score used.
    #'      \item \code{max_degree = -1} - Maximum degree of any node in the
    #'       graph. Set to -1 for unlimited,
    #'      \item \code{faithfulness_assumed = FALSE} - If TRUE, assume that if
    #'       \eqn{X \perp\!\!\!\perp Y} (by an independence test) then
    #'       \eqn{X \perp\!\!\!\perp Y} | Z for nonempty Z,
    #'      \item \code{num_threads = 1} - Number of threads to use for the
    #'       search.
    #'    }
    #    \item \code{"ges_mb" ("fges_mb")} - Fast Greedy Equivalence Search with Markov
    #    Blanket (FGES-MB) algorithm.
    #     \itemize{
    #       \item \code{targets = ""} - Target names (comma or space separated),
    #       \item \code{max_degree = -1} - Maximum degree of any node in the
    #       graph. Set to -1 for unlimited,
    #       \item \code{trimming_style = "mb_dags"} - The trimming style to use:
    #       \code{"none"} applies no trimming. \code{"adj"} trims to the adjacencies
    #       of the targets. \code{"mb_dags"} trims to Union(MB(targets)) U targets.
    #       \code{"semidir_paths"} trims to nodes with semidirected paths to the targets.
    #       \item \code{number_of_expansions = 2} - Number of expansions of the
    #       algorithm away from the target,
    #       \item \code{faithfulness_assumed = FALSE} - If TRUE, assume that if
    #        \eqn{X \perp\!\!\!\perp Y} (by an independence test) then
    #        \eqn{X \perp\!\!\!\perp Y} | Z for nonempty Z.
    #    }
    #'   \item \code{"gfci"} - GFCI algorithm. Combines FGES and FCI.
    #'    \itemize{
    #'      \item \code{depth = -1} - Maximum size of conditioning set,
    #'      \item \code{max_degree = -1} - Maximum degree of any node in the
    #'       graph. Set to -1 for unlimited,
    #'      \item \code{max_disc_path_length = -1} - Maximum length for any
    #'       discriminating path. Set to -1 for unlimited,
    #'      \item \code{complete_rule_set_used = TRUE} - FALSE if the (simpler)
    #'       final orientation rules set due to P. Spirtes, guaranteeing arrow
    #'       completeness, should be used; TRUE if the (fuller) set due to
    #'       J. Zhang, should be used guaranteeing additional tail completeness,
    #'      \item \code{guarantee_pag = FALSE} - Ensure the output is a legal
    #'       PAG (where feasible),
    #'      \item \code{use_heuristic = FALSE} - If TRUE, use the max p heuristic.
    #'      \item \code{start_complete = FALSE} - If TRUE, start from a complete
    #'      graph,
    #'      \item \code{num_threads = 1} - Number of threads to use for the
    #'       search,
    #'      \item \code{exclude_selection_bias = FALSE} - If TRUE, exclude the
    #'       possibility of selection bias.
    #'    }
    #'   \item \code{"grasp"} - GRaSP (Greedy Relations of Sparsest Permutation)
    #'   algorithm.
    #'    \itemize{
    #'      \item \code{covered_depth = 4} - The depth of recursion for first
    #'       search,
    #'      \item \code{singular_depth = 1} - Recursion depth for singular
    #'       tucks,
    #'      \item \code{nonsingular_depth = 1} - Recursion depth for nonsingular
    #'       tucks,
    #'      \item \code{ordered_alg = FALSE} - If TRUE, earlier GRaSP stages
    #'       should be performed before later stages,
    #'      \item \code{raskutti_uhler = FALSE} - If TRUE, use Raskutti and
    #'       Uhler's DAG-building method, which uses the independence test.
    #'       If FALSE, use Grow-Shrink, which uses the score or the test
    #'       depending on \code{use_score},
    #'      \item \code{use_data_order = TRUE} - If TRUE, the data variable
    #'       order should be used for the first initial permutation,
    #'      \item \code{num_starts = 1} - The number of times the algorithm
    #'       should be started from different initializations. By default, the
    #'       algorithm will be run through at least once using the initialized
    #'       parameters,
    #'      \item \code{use_score = TRUE} - Only used when
    #'       \code{raskutti_uhler = FALSE}. If TRUE, Grow-Shrink uses the score
    #'       to find parents; if FALSE, it uses the independence test,
    #'      \item \code{allow_internal_randomness = TRUE} - If TRUE, the search
    #'       shuffles variables and parents in random order. This randomness
    #'       is not controlled by \code{set.seed()} or \code{seed}, so set it
    #'       to FALSE for reproducible results,
    #'      \item \code{output_cpdag = TRUE} - If TRUE, the DAG output of the
    #'       algorithm is converted to a CPDAG,
    #'      \item \code{seed = -1} - Seed for Tetrad's random number generator.
    #'       If -1, no seed is set.
    #'    }
    #'   \item \code{"grasp_fci"} - GRaSP-FCI algorithm. Combines GRaSP and FCI.
    #'    \itemize{
    #'      \item \code{depth = -1} - Maximum size of conditioning set.
    #'        Set to -1 for unlimited,
    #'      \item \code{max_disc_path_length = -1} - Maximum length for any
    #'       discriminating path. Set to -1 for unlimited,
    #'      \item \code{complete_rule_set_used = TRUE} - FALSE if the (simpler)
    #'       final orientation rules set due to P. Spirtes, guaranteeing arrow
    #'       completeness, should be used; TRUE if the (fuller) set due to
    #'       J. Zhang, should be used guaranteeing additional tail completeness,
    #'      \item \code{singular_depth = 1} - Recursion depth for singular
    #'       tucks,
    #'      \item \code{nonsingular_depth = 1} - Recursion depth for nonsingular
    #'       tucks,
    #'      \item \code{ordered_alg = FALSE} - If TRUE, earlier GRaSP stages
    #'       should be performed before later stages,
    #'      \item \code{raskutti_uhler = FALSE} - If TRUE, use Raskutti and
    #'       Uhler's DAG-building method, which uses the independence test.
    #'       If FALSE, use Grow-Shrink, which uses the score or the test
    #'       depending on \code{use_score},
    #'      \item \code{use_data_order = TRUE} - If TRUE, the data variable
    #'       order should be used for the first initial permutation,
    #'      \item \code{num_starts = 1} - The number of times the algorithm
    #'       should be started from different initializations. By default, the
    #'       algorithm will be run through at least once using the initialized
    #'       parameters,
    #'      \item \code{guarantee_pag = FALSE} - If TRUE, ensure the output is a
    #'       legal PAG (where feasible),
    #'      \item \code{use_score = TRUE} - Only used when
    #'       \code{raskutti_uhler = FALSE}. If TRUE, Grow-Shrink uses the score
    #'       to find parents; if FALSE, it uses the independence test,
    #'      \item \code{use_heuristic = FALSE} - If TRUE, use the max p
    #'       heuristic,
    #'      \item \code{exclude_selection_bias = FALSE} - If TRUE, exclude the
    #'       possibility of selection bias,
    #'      \item \code{seed = -1} - Seed for Tetrad's random number generator.
    #'       If -1, no seed is set.
    #'    }
    #     \item \code{"ica_lingam"} - ICA LiNGAM algorithm.
    #     \itemize{
    #       \item \code{ica_a = 1.1} - The 'a' parameter of Fast ICA
    #       (see Hyvarinen, A. (2001)). It ranges between 1 and 2.
    #       \item \code{ica_max_iter = 5000} -  Maximum number if iterations of
    #       the optimization procedure of ICA.
    #       \item \code{ica_tolerance = 1e-8} - Fast ICA tolerance parameter.
    #       \item \code{threshold_b = 0.1} - The estimated B matrix is
    #       thresholded by setting small entries less than this threshold to
    #       zero.
    #    }
    #    \item \code{"ica_lingd"} - ICA-LiNG-D algorithm
    #    \itemize{
    #      \item \code{ica_a = 1.1} - The 'a' parameter of Fast ICA
    #      (see Hyvarinen, A. (2001)). It ranges between 1 and 2.
    #      \item \code{ica_max_iter = 5000} -  Maximum number if iterations of
    #      the optimization procedure of ICA.
    #      \item \code{ica_tolerance = 1e-8} - Fast ICA tolerance parameter.
    #      \item \code{threshold_b = 0.1} - The estimated B matrix is
    #      thresholded by setting small entries less than this threshold to
    #      zero.
    #      \item \code{threshold_w} - The estimated W matrix is thresholded by
    #      setting small entries less than this threshold to zero.
    #   }
    #'
    #'   \item \code{"pc"} - Peter-Clark (PC) algorithm
    #'    \itemize{
    #'      \item \code{depth = -1} - Maximum size of conditioning set.
    #'        Set to -1 for unlimited,
    #'      \item \code{stable_fas = TRUE} - If TRUE, the "stable" version of
    #'       the PC adjacency search is used, which for k > 0 fixes the graph
    #'       for depth k + 1 to that of the previous depth k,
    #'      \item \code{collider_orientation_style = "max_p"} - How unshielded
    #'       colliders are oriented. \code{"sepsets"} orients a
    #'       collider if Z is not in the separating set of X and Y found during
    #'       the adjacency search (as in the original PC).
    #'       \code{"conservative"} orients a collider only if Z is in none of
    #'       the separating sets of X and Y, and leaves the triple unoriented
    #'       if they disagree. \code{"max_p"} orients a collider if Z is not in
    #'       the separating set with the highest p-value,
    #'      \item \code{allow_bidirected = FALSE} - If TRUE, collider conflicts
    #'       are shown as bidirected edges,
    #'      \item \code{fdr_q = 0} - False discovery rate q value. If 0, FDR
    #'       control is not used.
    #'    }
    #   \item \code{"pc_max"} - PCMax algorithm
    #   \itemize{
    #      \item \code{depth = -1} - Maximum size of conditioning set,
    #      \item \code{stable_fas = TRUE} - If TRUE, the "stable" version of
    #      the PC adjacency search is used, which for k > 0 fixes the graph
    #      for depth k + 1 to that of the previous depth k,
    #      \item \code{allow_bidirected = FALSE} - If TRUE, collider conflicts
    #      are shown as bidirected edges.
    #  }
    # #'   \item \code{"restricted_boss"} - Restricted BOSS algorithm
    # #'    \itemize{
    # #'      \item \code{targets = ""} - Target names (comma or space separated),
    # #'      \item \code{use_bes = TRUE} - If TRUE, the algorithm uses the
    # #'       backward equivalence search from the GES algorithm as one of its
    # #'       steps,
    # #'      \item \code{num_starts = 1} - The number of times the algorithm
    # #'       should be started from different initializations. By default, the
    # #'       algorithm will be run through at least once using the initialized
    # #'       parameters,
    # #'      \item \code{trimming_style = "mb_dags"} - The trimming style to use:
    # #'       \code{"none"}, \code{"adj"}, \code{"mb_dags"}, or
    # #'       \code{"semdir_paths"}. See \code{"ges_mb"} for details,
    # #'      \item \code{seed = -1} - Seed for Tetrad's random number
    # #'       generator. If -1, no seed is set.
    # #'    }
    #'   \item \code{"rfci"} - Restricted FCI algorithm
    #'    \itemize{
    #'      \item \code{depth = -1} - Maximum size of conditioning set. Set
    #'        to -1 for unlimited,
    #'      \item \code{max_disc_path_length = -1} - Maximum length for any
    #'       discriminating path. Set to -1 for unlimited,
    #'      \item \code{exclude_selection_bias = FALSE} - If TRUE, exclude the
    #'       possibility of selection bias,
    #'      \item \code{fdr_q = 0} - False discovery rate q value. If 0, FDR
    #'       control is not used.
    #'    }
    #    \item \code{"sp"} - Sparsest Permutation algorithm. No parameters.
    #'   \item \code{"sp_fci"} - Sparsest Permutation using FCI
    #'    \itemize{
    #'      \item \code{max_disc_path_length = -1} - Maximum length for any
    #'       discriminating path. Set to -1 for unlimited,
    #'      \item \code{complete_rule_set_used = TRUE} - FALSE if the (simpler)
    #'       final orientation rules set due to P. Spirtes, guaranteeing arrow
    #'       completeness, should be used; TRUE if the (fuller) set due to
    #'       J. Zhang, should be used guaranteeing additional tail completeness,
    #'       \item \code{guarantee_pag = FALSE} - Ensure the output is a legal
    #'       PAG (where feasible),
    #'       \item \code{use_heuristic = FALSE} - If TRUE, use the max p heuristic version,
    #'       \item \code{exclude_selection_bias = FALSE} - If TRUE, exclude the
    #'       possibility of selection bias.
    #'    }
    #' }
    #' @return Invisibly returns \code{self}.
    set_alg = function(method, ...) {
      method <- tolower(method)

      # Custom / registered algorithms
      if (exists(method, envir = tetrad_alg_registry, inherits = FALSE)) {
        tetrad_alg_registry[[method]](self, ...)
        return(invisible(self))
      }

      switch(
        method,
        "fges" = {
          if (is.null(self$score)) {
            stop("No score is set. Use set_score() first.", call. = FALSE)
          }
          private$set_fges_alg(...)
        },
        "fges_mb" = {
          if (is.null(self$score)) {
            stop("No score is set. Use set_score() first.", call. = FALSE)
          }
          private$set_fges_mb_alg(...)
        },
        "boss" = {
          if (is.null(self$score)) {
            stop("No score is set. Use set_score() first.", call. = FALSE)
          }
          private$set_boss_alg(...)
        },
        "restricted_boss" = {
          if (is.null(self$score)) {
            stop("No score is set. Use set_score() first.", call. = FALSE)
          }
          if (!rJava::.jcall(self$knowledge, "Z", "isEmpty")) {
            warning(
              "Background knowledge is set.",
              " This algorithm does not use background knowledge.",
              call. = FALSE
            )
          }
          private$set_restricted_boss_alg(...)
        },
        "cstar" = {
          if (is.null(self$score)) {
            stop("No score is set. Use set_score() first.", call. = FALSE)
          }
          if (is.null(self$test)) {
            stop("No test is set. Use set_test() first.", call. = FALSE)
          }
          if (!rJava::.jcall(self$knowledge, "Z", "isEmpty")) {
            warning(
              "Background knowledge is set.",
              " This algorithm does not use background knowledge.",
              call. = FALSE
            )
          }
          private$set_cstar_alg(...)
        },
        "sp" = {
          if (is.null(self$score)) {
            stop("No score is set. Use set_score() first.", call. = FALSE)
          }
          private$set_sp_alg(...)
        },
        "grasp" = {
          if (is.null(self$score)) {
            stop("No score is set. Use set_score() first.", call. = FALSE)
          }
          if (is.null(self$test)) {
            stop("No test is set. Use set_test() first.", call. = FALSE)
          }
          private$set_grasp_alg(...)
        },
        "pc" = {
          if (is.null(self$test)) {
            stop("No test is set. Use set_test() first.", call. = FALSE)
          }
          private$set_pc_alg(...)
        },
        "cpc" = {
          if (is.null(self$test)) {
            stop("No test is set. Use set_test() first.", call. = FALSE)
          }
          private$set_cpc_alg(...)
        },
        "pc_max" = {
          if (is.null(self$test)) {
            stop("No test is set. Use set_test() first.", call. = FALSE)
          }
          private$set_pc_max_alg(...)
        },
        "fci" = {
          if (is.null(self$test)) {
            stop("No test is set. Use set_test() first.", call. = FALSE)
          }
          private$set_fci_alg(...)
        },
        "rfci" = {
          if (is.null(self$test)) {
            stop("No test is set. Use set_test() first.", call. = FALSE)
          }
          private$set_rfci_alg(...)
        },
        "cfci" = {
          if (is.null(self$test)) {
            stop("No test is set. Use set_test() first.", call. = FALSE)
          }
          private$set_cfci_alg(...)
        },
        "gfci" = {
          if (is.null(self$score)) {
            stop("No score is set. Use set_score() first.", call. = FALSE)
          }
          if (is.null(self$test)) {
            stop("No test is set. Use set_test() first.", call. = FALSE)
          }
          private$set_gfci_alg(...)
        },
        "boss_fci" = {
          if (is.null(self$score)) {
            stop("No score is set. Use set_score() first.", call. = FALSE)
          }
          if (is.null(self$test)) {
            stop("No test is set. Use set_test() first.", call. = FALSE)
          }
          private$set_boss_fci_alg(...)
        },
        "fcit" = {
          if (is.null(self$score)) {
            stop("No score is set. Use set_score() first.", call. = FALSE)
          }
          if (is.null(self$test)) {
            stop("No test is set. Use set_test() first.", call. = FALSE)
          }
          private$set_fcit_alg(...)
        },
        "grasp_fci" = {
          if (is.null(self$score)) {
            stop("No score is set. Use set_score() first.", call. = FALSE)
          }
          if (is.null(self$test)) {
            stop("No test is set. Use set_test() first.", call. = FALSE)
          }
          private$set_grasp_fci_alg(...)
        },
        "sp_fci" = {
          if (is.null(self$score)) {
            stop("No score is set. Use set_score() first.", call. = FALSE)
          }
          if (is.null(self$test)) {
            stop("No test is set. Use set_test() first.", call. = FALSE)
          }
          private$set_sp_fci_alg(...)
        },
        "ica_lingam" = {
          if (!rJava::.jcall(self$knowledge, "Z", "isEmpty")) {
            warning(
              "Background knowledge is set.",
              "This algorithm does not use background knowledge.",
              call. = FALSE
            )
          }
          private$set_ica_lingam_alg(...)
        },
        "ica_lingd" = {
          if (!rJava::.jcall(self$knowledge, "Z", "isEmpty")) {
            warning(
              "Background knowledge is set.",
              "This algorithm does not use background knowledge.",
              call. = FALSE
            )
          }
          private$set_ica_lingd_alg(...)
        },
        "fask" = {
          if (is.null(self$score)) {
            stop("No score is set. Use set_score() first.", call. = FALSE)
          }
          private$set_fask_alg(...)
        },
        "ccd" = {
          if (is.null(self$test)) {
            stop("No test is set. Use set_test() first.", call. = FALSE)
          }
          if (!rJava::.jcall(self$knowledge, "Z", "isEmpty")) {
            warning(
              "Background knowledge is set.",
              "This algorithm does not use background knowledge.",
              call. = FALSE
            )
          }
          private$set_ccd_alg(...)
        },
        "direct_lingam" = {
          if (is.null(self$score)) {
            stop("No score is set. Use set_score() first.", call. = FALSE)
          }
          if (!rJava::.jcall(self$knowledge, "Z", "isEmpty")) {
            warning(
              "Background knowledge is set.",
              "This algorithm does not use background knowledge.",
              call. = FALSE
            )
          }
          private$set_direct_lingam_alg(...)
        },
        "dagma" = {
          if (!rJava::.jcall(self$knowledge, "Z", "isEmpty")) {
            warning(
              "Background knowledge is set.",
              "This algorithm does not use background knowledge.",
              call. = FALSE
            )
          }
          private$set_dagma_alg(...)
        },
        {
          stop(
            "Unknown method type using tetrad engine: ",
            method,
            call. = FALSE
          )
        }
      )
      invisible(self)
    },
    #' @description Sets the background `Knowledge` object.
    #' @param knowledge_obj An object containing \pkg{Tetrad} knowledge.
    set_knowledge = function(knowledge_obj) {
      is_knowledge(knowledge_obj)
      knowledge_tetrad <- as_tetrad_knowledge(knowledge_obj)
      self$knowledge <- knowledge_tetrad

      # Set knowledge to algorithm
      if (!is.null(self$alg)) {
        self$alg$setKnowledge(self$knowledge)
      }
    },
    #' @description Sets parameters for the Tetrad search.
    #' @param ... Named arguments for the parameters to set.
    set_params = function(...) {
      # Capture the named arguments as a list.
      arg_list <- list(...)
      for (param_name in names(arg_list)) {
        value <- arg_list[[param_name]]
        # Get the key (static field) from Params using the field name.
        key <- rJava::.jfield("edu/cmu/tetrad/util/Params", "S", param_name)

        # Wrap the value based on its type.
        wrapped <- if (is.integer(value)) {
          rJava::.jcast(
            rJava::.jnew("java/lang/Integer", as.integer(value)),
            "java/lang/Object"
          )
        } else if (is.numeric(value)) {
          rJava::.jcast(
            rJava::.jnew("java/lang/Double", as.double(value)),
            "java/lang/Object"
          )
        } else if (is.logical(value)) {
          rJava::.jcast(
            rJava::.jnew("java/lang/Boolean", as.logical(value)),
            "java/lang/Object"
          )
        } else if (is.character(value)) {
          rJava::.jcast(
            rJava::.jnew("java/lang/String", value),
            "java/lang/Object"
          )
        } else {
          rJava::.jcast(value, "java/lang/Object") # must already be a Java object
        }

        # Set the parameter using the key and wrapped value.
        self$params$set(key, wrapped)
      }
      invisible(NULL)
    },
    #' @description Retrieves the argument names of a matching private function.
    #' @param fn_pattern (character) A pattern that should match a private method name.
    #' @param score If TRUE, retrieves parameters for a scoring function.
    #' @param test If TRUE, retrieves parameters for a test function.
    #' @param alg If TRUE, retrieves parameters for an algorithm.
    #' @return (character) The names of the parameters.
    get_parameters_for_function = function(
      fn_pattern,
      score = FALSE,
      test = FALSE,
      alg = FALSE
    ) {
      checkmate::assert_character(fn_pattern)
      checkmate::assert_logical(score, len = 1)
      checkmate::assert_logical(test, len = 1)
      checkmate::assert_logical(alg, len = 1)

      # Check if exclusively one of score, test, or alg is TRUE
      if (sum(c(score, test, alg)) != 1) {
        stop(
          "Score is: ",
          score,
          ", test is: ",
          test,
          ", and alg is: ",
          alg,
          ". (Exclusively) one of them should be TRUE.",
          call. = FALSE
        )
      }
      if (score) {
        function_names <- sprintf("^(set_|use_)%s(_score)?$", fn_pattern)
      } else if (test) {
        function_names <- sprintf("^(set_|use_)%s(_test)?$", fn_pattern)
      } else if (alg) {
        function_names <- sprintf("^(set_|use_)%s(_alg)?$", fn_pattern)
      }

      is_private_method <- function(name) {
        is.function(get(name, envir = as.environment(private))) &&
          grepl(function_names, name)
      }
      private_names <- ls(envir = as.environment(private))
      matched_function <- base::Filter(is_private_method, private_names)
      if (length(matched_function) != 1) {
        if (length(matched_function) > 1) {
          # this is an extra precaution, which cannot be triggered currently,
          # but is nice to have for extra security.
          # nocov start
          error_message_suffix <- paste0(
            "\n  Matches: ",
            paste(matched_function, collapse = ", ")
          ) # nocov end
        } else {
          error_message_suffix <- ""
        }
        stop(
          paste0(
            "There is ",
            length(matched_function),
            " matches to the function pattern: ",
            fn_pattern,
            "\n  This is probably a misspecification of either a algorithm, test, or score.",
            "\n  There should be (only) a single match.",
            error_message_suffix
          ),
          call. = FALSE
        )
      }
      names(formals(matched_function, envir = as.environment(private)))
    },
    #' @description Runs the chosen Tetrad algorithm on the data.
    #' @param data (optional) If provided, overrides the previously set data.
    #' @param bootstrap (logical) If TRUE, bootstrapped graphs will be
    #' generated.
    #' @param int_cols_as_cont (logical) If `TRUE`, integer columns are treated
    #' as continuous, since \pkg{Tetrad} does not support ordinal data, but only
    #' either continuous or nominal data. Default is `TRUE.`
    #' @return A `Disco` object (a list with a `caugi` and a `Knowledge` object).
    #' Also populates \code{self$java}.
    run_search = function(
      data = NULL,
      bootstrap = FALSE,
      int_cols_as_cont = TRUE
    ) {
      checkmate::assert_logical(bootstrap, len = 1)
      if (!is.null(data)) {
        self$set_data(data, int_cols_as_cont)
      }
      if (is.null(self$data)) {
        stop(
          "No data is set. Use set_data() first or input data directly into run_search().",
          call. = FALSE
        )
      }
      if (is.null(self$alg)) {
        stop("No algorithm is set. Use set_alg() first.", call. = FALSE)
      }
      # run the search
      self$java <- self$alg$search(self$data, self$params)

      # convert to tetrad_graph object (essentially a wrapper around amat.pag)
      self$result <- tetrad_graph(self$get_amat())

      if (bootstrap) {
        self$bootstrap_graphs <- self$alg$getBootstrapGraphs()
      }

      # todo: make a better solution, probably in caugi

      # Always call with class = "PAG"?
      # Old code:
      # out <- tryCatch(as_disco(self$result),
      #   error = function(e) {
      #      as_disco(self$result, class = "PAG")
      #   }
      # )
      # But gives incorrect edges for PC algorithm?
      as_disco(self$result, class = "PAG")
    },
    #' @description Configures bootstrapping parameters for the Tetrad search.
    #' @param number_resampling (integer) Number of bootstrap samples.
    #' @param percent_resample_size (numeric) Percentage of sample size for each bootstrap.
    #' @param add_original (logical) If TRUE, add the original dataset to the bootstrap set.
    #' @param with_replacement (logical) If TRUE, sampling is done with replacement.
    #' @param resampling_ensemble (integer) How the resamples are used or aggregated.
    #' @param seed (integer) Random seed, or -1 for none.
    set_bootstrapping = function(
      number_resampling = 0,
      percent_resample_size = 100,
      add_original = TRUE,
      with_replacement = TRUE,
      resampling_ensemble = 1,
      seed = -1
    ) {
      checkmate::assert_int(number_resampling, lower = 0)

      checkmate::assert_number(
        percent_resample_size,
        lower = 0,
        upper = 100,
        finite = TRUE
      )

      checkmate::assert_logical(add_original, len = 1)
      checkmate::assert_logical(with_replacement, len = 1)

      checkmate::assert_int(resampling_ensemble)

      checkmate::assert_int(seed)

      self$set_params(
        NUMBER_RESAMPLING = number_resampling,
        PERCENT_RESAMPLE_SIZE = percent_resample_size,
        ADD_ORIGINAL_DATASET = add_original,
        RESAMPLING_WITH_REPLACEMENT = with_replacement,
        RESAMPLING_ENSEMBLE = resampling_ensemble,
        SEED = seed
      )
    },
    #' @description Sets or overrides the data used by Tetrad.
    #' @param data (data.frame) The new data to load.
    #' @param int_cols_as_cont (logical) If `TRUE`, integer columns are treated
    #' as continuous, since Tetrad does not support ordinal data, but only
    #' either continuous or nominal data. Default is `TRUE.`
    set_data = function(data, int_cols_as_cont = TRUE) {
      checkmate::assert_data_frame(data)

      if (
        is.null(self$data) ||
          is.null(self$rdata) ||
          !isTRUE(all.equal(self$rdata, data))
      ) {
        self$rdata <- data
        self$data <- rdata_to_tetrad(data, int_cols_as_cont)
      }
    },
    #' @description Toggles the verbosity in Tetrad.
    #' @param verbose (logical) TRUE to enable verbose logging, FALSE otherwise.
    set_verbose = function(verbose) {
      checkmate::assert_logical(verbose, len = 1)
      self$set_params(
        VERBOSE = verbose
      )
    },
    #' @description Sets an integer time lag for time-series algorithms.
    #' @param time_lag (integer) The time lag to set.
    set_time_lag = function(time_lag = 0) {
      checkmate::assert_int(time_lag, lower = 0)

      self$set_params(
        TIME_LAG = time_lag
      )
    },
    #' @description Retrieves the current Java data object.
    #' @return (Java object) Tetrad dataset.
    get_data = function() {
      self$data
    },
    #' @description Returns the background `Knowledge` object.
    #' @return (Java object) Tetrad Knowledge.
    get_knowledge = function() {
      self$knowledge
    },
    #' @description Gets the main Java result object (usually a graph) from the last search.
    #' @return (Java object) The Tetrad result graph or model.
    get_java = function() {
      self$java
    },
    #' @description Returns the string representation of a given Java object or \code{self$java}.
    #' @param java_obj (Java object, optional) If NULL, uses \code{self$java}.
    #' @return (character) The \code{toString()} of that Java object.
    get_string = function(java_obj = NULL) {
      if (is.null(java_obj)) {
        rJava::.jcall(self$java, "S", "toString")
      } else {
        rJava::.jcall(java_obj, "S", "toString")
      }
    },
    #' @description Produces a DOT (Graphviz) representation of the graph.
    #' @param java_obj (Java object, optional) If NULL, uses \code{self$java}.
    #' @return (character) The DOT-format string.
    get_dot = function(java_obj = NULL) {
      if (is.null(java_obj)) {
        self$java <- cast_obj(self$java)
        rJava::.jcall(
          "edu/cmu/tetrad/graph/GraphSaveLoadUtils",
          "S",
          "graphToDot",
          self$java
        )
      } else {
        java_obj <- cast_obj(java_obj)
        rJava::.jcall(
          "edu/cmu/tetrad/graph/GraphSaveLoadUtils",
          "S",
          "graphToDot",
          java_obj
        )
      }
    },
    #' @description Produces an amat representation of the graph.
    #' @param java_obj (Java object, optional) If NULL, uses \code{self$java}.
    #' @return (character) The adjacency matrix.
    get_amat = function(java_obj = NULL) {
      if (is.null(java_obj)) {
        self$java <- cast_obj(self$java)
        rJava::.jcall(
          "edu/cmu/tetrad/graph/GraphSaveLoadUtils",
          "S",
          "graphToPcalg",
          self$java
        )
      } else {
        java_obj <- cast_obj(java_obj)
        rJava::.jcall(
          "edu/cmu/tetrad/graph/GraphSaveLoadUtils",
          "S",
          "graphToPcalg",
          java_obj
        )
      }
    }
  ),

  # Setting scores and tests is done through private functions,
  # and should be this should be done through set_score() and set_test().
  private = list(
    # Scores
    use_basis_function_bic_score = function(
      truncation_limit = 3,
      penalty_discount = 2,
      singularity_lambda = 0.0,
      do_one_equation_only = FALSE
    ) {
      checkmate::assert_int(truncation_limit, lower = 0)
      checkmate::assert_number(penalty_discount, lower = 0, finite = TRUE)
      checkmate::assert_number(singularity_lambda, lower = 0, finite = TRUE)
      checkmate::assert_logical(do_one_equation_only, len = 1)

      self$set_params(
        TRUNCATION_LIMIT = truncation_limit,
        PENALTY_DISCOUNT = penalty_discount,
        SINGULARITY_LAMBDA = singularity_lambda,
        DO_ONE_EQUATION_ONLY = do_one_equation_only
      )
      self$score <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/score/BasisFunctionBicScore"
      )
      self$score <- cast_obj(self$score)
    },
    use_bdeu_score = function(sample_prior = 10, structure_prior = 0) {
      checkmate::assert_number(sample_prior, finite = TRUE)
      checkmate::assert_number(structure_prior, finite = TRUE)

      self$set_params(
        PRIOR_EQUIVALENT_SAMPLE_SIZE = sample_prior,
        STRUCTURE_PRIOR = structure_prior
      )
      self$score <- rJava::.jnew("edu/cmu/tetrad/algcomparison/score/BdeuScore")
      self$score <- cast_obj(self$score)
    },
    use_conditional_gaussian_score = function(
      penalty_discount = 1,
      discretize = TRUE,
      num_categories_to_discretize = 3,
      structure_prior = 0
    ) {
      checkmate::assert_number(penalty_discount, lower = 0, finite = TRUE)
      checkmate::assert_int(num_categories_to_discretize, lower = 0)
      checkmate::assert_logical(discretize, len = 1)
      checkmate::assert_number(structure_prior, lower = 0, finite = TRUE)

      self$set_params(
        PENALTY_DISCOUNT = penalty_discount,
        STRUCTURE_PRIOR = structure_prior,
        DISCRETIZE = discretize,
        NUM_CATEGORIES_TO_DISCRETIZE = num_categories_to_discretize
      )
      self$score <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/score/ConditionalGaussianBicScore"
      )
      self$score <- cast_obj(self$score)
    },
    use_degenerate_gaussian_score = function(
      penalty_discount = 1,
      structure_prior = 0,
      singularity_lambda = 0.0,
      precompute_covariances = TRUE
    ) {
      checkmate::assert_number(penalty_discount, lower = 0, finite = TRUE)
      checkmate::assert_number(structure_prior, lower = 0, finite = TRUE)
      checkmate::assert_number(singularity_lambda, lower = 0, finite = TRUE)
      checkmate::assert_logical(precompute_covariances, len = 1)
      if (!precompute_covariances) {
        warning("`precompute_covariances = FALSE` doesn't work properly yet.")
        precompute_covariances <- TRUE
      }

      self$set_params(
        PENALTY_DISCOUNT = penalty_discount,
        STRUCTURE_PRIOR = structure_prior,
        SINGULARITY_LAMBDA = singularity_lambda,
        PRECOMPUTE_COVARIANCES = precompute_covariances
      )
      self$score <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/score/DegenerateGaussianBicScore"
      )
      self$score <- cast_obj(self$score)
    },
    use_discrete_bic_score = function(
      penalty_discount = 2,
      structure_prior = 0
    ) {
      checkmate::assert_number(penalty_discount, lower = 0, finite = TRUE)
      checkmate::assert_number(structure_prior, lower = 0, finite = TRUE)

      self$set_params(
        PENALTY_DISCOUNT = penalty_discount,
        STRUCTURE_PRIOR = structure_prior
      )
      self$score <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/score/DiscreteBicScore"
      )
      self$score <- cast_obj(self$score)
    },
    use_ebic_score = function(
      gamma = 0.8,
      precompute_covariances = TRUE,
      singularity_lambda = 0.0
    ) {
      checkmate::assert_number(gamma, lower = 0, finite = TRUE)
      checkmate::assert_number(singularity_lambda, lower = 0, finite = TRUE)
      checkmate::assert_logical(precompute_covariances, len = 1)
      if (!precompute_covariances) {
        warning("`precompute_covariances = FALSE` doesn't work properly yet.")
        precompute_covariances <- TRUE
      }

      self$set_params(
        EBIC_GAMMA = gamma,
        PRECOMPUTE_COVARIANCES = precompute_covariances,
        SINGULARITY_LAMBDA = singularity_lambda
      )

      self$score <- rJava::.jnew("edu/cmu/tetrad/algcomparison/score/EbicScore")
      self$score <- cast_obj(self$score)
    },
    use_gic_score = function(
      penalty_discount = 1,
      sem_gic_rule = "bic",
      precompute_covariances = TRUE,
      singularity_lambda = 0.0
    ) {
      checkmate::assert_number(penalty_discount, lower = 0, finite = TRUE)
      checkmate::assert_number(singularity_lambda, lower = 0, finite = TRUE)
      checkmate::assert_character(sem_gic_rule)
      if (!precompute_covariances) {
        warning("`precompute_covariances = FALSE` doesn't work properly yet.")
        precompute_covariances <- TRUE
      }
      sem_gic_rule_int <- switch(
        sem_gic_rule,
        "bic" = 1L,
        "gic2" = 2L,
        "ric" = 3L,
        "ricc" = 4L,
        "gic5" = 5L,
        "gic6" = 6L,
        stop(
          "Unsupported `sem_gic_rule` input:",
          sem_gic_rule,
          "\n",
          "Supported values are: 'bic', 'gic2', 'ric', 'ricc', 'gic5', and ",
          "'gic6'.",
          call. = FALSE
        )
      )
      self$set_params(
        SEM_GIC_RULE = sem_gic_rule_int,
        PENALTY_DISCOUNT_ZS = penalty_discount,
        PRECOMPUTE_COVARIANCES = precompute_covariances,
        SINGULARITY_LAMBDA = singularity_lambda
      )
      self$score <- rJava::.jnew("edu/cmu/tetrad/algcomparison/score/GicScores")
      self$score <- cast_obj(self$score)
    },
    use_mag_degenerate_gaussian_bic_score = function(
      penalty_discount = 1,
      structure_prior = 0,
      precompute_covariances = TRUE
    ) {
      checkmate::assert_number(penalty_discount, lower = 0, finite = TRUE)
      checkmate::assert_number(structure_prior, lower = 0, finite = TRUE)
      checkmate::assert_logical(precompute_covariances, len = 1)
      if (!precompute_covariances) {
        warning("`precompute_covariances = FALSE` doesn't work properly yet.")
        precompute_covariances <- TRUE
      }

      self$set_params(
        PENALTY_DISCOUNT = penalty_discount,
        STRUCTURE_PRIOR = structure_prior,
        PRECOMPUTE_COVARIANCES = precompute_covariances
      )
      self$score <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/score/MagDgBicScore"
      )
      self$score <- cast_obj(self$score)
    },
    # use_mixed_variable_polynomial_score = function(
    #   structure_prior = 0,
    #   f_degree = 0,
    #   discretize = FALSE
    # ) {
    #   stopifnot(
    #     is.numeric(c(structure_prior, f_degree)),
    #     floor(f_degree) == f_degree,
    #     is.logical(discretize),
    #     length(discretize) == 1
    #   )
    #   self$set_params(
    #     STRUCTURE_PRIOR = structure_prior,
    #     DISCRETIZE = discretize
    #   )
    #   # f_degree is not a static field in Params so we set it manually.
    #   self$params$set(
    #     "fDegree",
    #     rJava::.jcast(
    #       rJava::.jnew("java/lang/Double", as.double(f_degree)),
    #       "java/lang/Object"
    #     )
    #   )
    #   self$score <- rJava::.jnew(
    #     "edu/cmu/tetrad/algcomparison/score/MVPBicScore"
    #   )
    #   self$score <- cast_obj(self$score)
    # },
    use_poisson_prior_score = function(
      poisson_lambda = 1,
      precompute_covariances = TRUE,
      singularity_lambda = 0.0
    ) {
      checkmate::assert_number(poisson_lambda, lower = 0, finite = TRUE)
      checkmate::assert_number(singularity_lambda, lower = 0, finite = TRUE)
      checkmate::assert_logical(precompute_covariances, len = 1)
      if (!precompute_covariances) {
        warning("`precompute_covariances = FALSE` doesn't work properly yet.")
        precompute_covariances <- TRUE
      }

      self$set_params(
        PRECOMPUTE_COVARIANCES = precompute_covariances,
        POISSON_LAMBDA = poisson_lambda,
        SINGULARITY_LAMBDA = singularity_lambda
      )
      self$score <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/score/PoissonPriorScore"
      )
      self$score <- cast_obj(self$score)
    },
    use_sem_bic_score = function(
      penalty_discount = 2,
      structure_prior = 0,
      sem_bic_rule = 1,
      precompute_covariances = TRUE,
      singularity_lambda = 0.0
    ) {
      checkmate::assert_number(singularity_lambda, lower = 0, finite = TRUE)
      checkmate::assert_int(penalty_discount, lower = 0)
      checkmate::assert_int(structure_prior, lower = 0)
      checkmate::assert_choice(sem_bic_rule, choices = c(1, 2))
      checkmate::assert_logical(precompute_covariances, len = 1)
      if (!precompute_covariances) {
        warning("`precompute_covariances = FALSE` doesn't work properly yet.")
        precompute_covariances <- TRUE
      }

      self$set_params(
        PENALTY_DISCOUNT = penalty_discount,
        SEM_BIC_STRUCTURE_PRIOR = structure_prior,
        SEM_BIC_RULE = sem_bic_rule,
        PRECOMPUTE_COVARIANCES = precompute_covariances,
        SINGULARITY_LAMBDA = singularity_lambda
      )
      self$score <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/score/SemBicScore"
      )
      self$score <- cast_obj(self$score)
    },
    use_zhang_shen_bound_score = function(
      risk_bound = 0.2,
      precompute_covariances = TRUE,
      singularity_lambda = 0.0
    ) {
      checkmate::assert_number(risk_bound, lower = 0, finite = TRUE)
      checkmate::assert_number(singularity_lambda, lower = 0, finite = TRUE)
      checkmate::assert_logical(precompute_covariances, len = 1)
      if (!precompute_covariances) {
        warning("`precompute_covariances = FALSE` doesn't work properly yet.")
        precompute_covariances <- TRUE
      }

      self$set_params(
        ZS_RISK_BOUND = risk_bound,
        PRECOMPUTE_COVARIANCES = precompute_covariances,
        SINGULARITY_LAMBDA = singularity_lambda
      )
      self$score <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/score/ZhangShenBoundScore"
      )
      self$score <- cast_obj(self$score)
    },
    use_basis_function_blocks_bic_score = function(
      basis_type = "polynomial",
      penalty_discount = 2,
      truncation_limit = 3
    ) {
      checkmate::assert_number(penalty_discount, lower = 0, finite = TRUE)
      checkmate::assert_int(truncation_limit, lower = 0)
      checkmate::assert_character(basis_type, len = 1)

      basis_type_int <- switch(
        basis_type,
        polynomial = 0L,
        legendre = 1L,
        hermite = 2L,
        chebyshev = 3L,
        stop(
          "Unsupported `basis_type` input: ",
          basis_type,
          "\n",
          "Supported values are: 'polynomial', 'legendre', 'hermite', and 'chebyshev'.",
          call. = FALSE
        )
      )

      self$set_params(
        BASIS_TYPE = basis_type_int,
        PENALTY_DISCOUNT = penalty_discount,
        TRUNCATION_LIMIT = truncation_limit
      )
      self$score <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/score/BfBlocksBicScore"
      )
      self$score <- cast_obj(self$score)
    },
    use_basis_function_sem_bic_score = function(
      penalty_discount = 2,
      jitter = 1e-8,
      truncation_limit = 3
    ) {
      checkmate::assert_number(penalty_discount, lower = 0, finite = TRUE)
      checkmate::assert_number(jitter, lower = 0, finite = TRUE)
      checkmate::assert_int(truncation_limit, lower = 0)

      self$set_params(
        REGULARIZATION_LAMBDA = jitter,
        PENALTY_DISCOUNT = penalty_discount,
        TRUNCATION_LIMIT = truncation_limit
      )
      self$score <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/score/BasisFunctionBicScore"
      )
      self$score <- cast_obj(self$score)
    },
    use_rank_bic_score = function(
      gamma = 0.8,
      penalty_discount = 2
    ) {
      checkmate::assert_number(gamma, lower = 0, upper = 1, finite = TRUE)
      checkmate::assert_number(penalty_discount, lower = 0, finite = TRUE)

      self$set_params(
        EBIC_GAMMA = gamma,
        PENALTY_DISCOUNT = penalty_discount
      )
      self$score <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/score/RankBicScore"
      )
      self$score <- cast_obj(self$score)
    },
    # Tests
    use_basis_function_lrt_test = function(
      truncation_limit = 3,
      alpha = 0.05,
      singularity_lambda = 0.0,
      do_one_equation_only = FALSE,
      use_for_mc = FALSE
    ) {
      checkmate::assert_int(truncation_limit, lower = 0)
      checkmate::assert_number(alpha, lower = 0, finite = TRUE)
      checkmate::assert_number(singularity_lambda, lower = 0, finite = TRUE)
      checkmate::assert_logical(do_one_equation_only, len = 1)
      checkmate::assert_logical(use_for_mc, len = 1)

      self$set_params(
        ALPHA = alpha,
        TRUNCATION_LIMIT = truncation_limit,
        SINGULARITY_LAMBDA = singularity_lambda,
        DO_ONE_EQUATION_ONLY = do_one_equation_only
      )
      set_tetrad_test(
        self,
        "edu/cmu/tetrad/algcomparison/independence/BasisFunctionLrt",
        use_for_mc = use_for_mc
      )
    },
    use_fisher_z_test = function(
      alpha = 0.05,
      singularity_lambda = 0.0,
      use_for_mc = FALSE
    ) {
      checkmate::assert_number(alpha, lower = 0, finite = TRUE)
      checkmate::assert_number(singularity_lambda, lower = 0, finite = TRUE)
      checkmate::assert_logical(use_for_mc, len = 1)

      self$set_params(
        ALPHA = alpha,
        SINGULARITY_LAMBDA = singularity_lambda
      )
      set_tetrad_test(
        self,
        "edu/cmu/tetrad/algcomparison/independence/FisherZ",
        use_for_mc = use_for_mc
      )
    },
    use_poisson_prior_test = function(
      poisson_lambda = 1,
      precompute_covariances = TRUE,
      singularity_lambda = 0.0,
      use_for_mc = FALSE,
      alpha = NULL
    ) {
      # poisson_prior does not use alpha
      checkmate::assert_number(poisson_lambda, lower = 0, finite = TRUE)
      checkmate::assert_number(singularity_lambda, lower = 0, finite = TRUE)
      checkmate::assert_logical(precompute_covariances, len = 1)
      if (!precompute_covariances) {
        warning("`precompute_covariances = FALSE` doesn't work properly yet.")
        precompute_covariances <- TRUE
      }
      checkmate::assert_logical(use_for_mc, len = 1)

      self$set_params(
        POISSON_LAMBDA = poisson_lambda,
        PRECOMPUTE_COVARIANCES = precompute_covariances,
        SINGULARITY_LAMBDA = singularity_lambda
      )
      set_tetrad_test(
        self,
        "edu/cmu/tetrad/algcomparison/independence/PoissonBicTest",
        use_for_mc = use_for_mc
      )
    },
    use_chi_square_test = function(
      min_count = 1,
      alpha = 0.05,
      cell_table_type = "ad",
      use_for_mc = FALSE
    ) {
      checkmate::assert_int(min_count, lower = 0)
      checkmate::assert_number(alpha, lower = 0, finite = TRUE)
      checkmate::assert_character(cell_table_type)
      checkmate::assert_logical(use_for_mc, len = 1)

      cell_table_type_int <- switch(
        tolower(cell_table_type),
        ad = 1L,
        count = 2L,
        stop(
          "Unsupported `cell_table_type` input: ",
          cell_table_type,
          "\n",
          "Supported values are: 'ad' and 'count'.",
          call. = FALSE
        )
      )
      self$set_params(
        ALPHA = alpha,
        MIN_COUNT_PER_CELL = min_count,
        CELL_TABLE_TYPE = cell_table_type_int
      )
      set_tetrad_test(
        self,
        "edu/cmu/tetrad/algcomparison/independence/ChiSquare",
        use_for_mc = use_for_mc
      )
    },
    use_g_square_test = function(
      min_count = 1,
      alpha = 0.05,
      cell_table_type = "ad",
      use_for_mc = FALSE
    ) {
      checkmate::assert_int(min_count, lower = 0)
      checkmate::assert_number(alpha, lower = 0, finite = TRUE)
      checkmate::assert_character(cell_table_type)
      checkmate::assert_logical(use_for_mc, len = 1)

      cell_table_type_int <- switch(
        tolower(cell_table_type),
        ad = 1L,
        count = 2L,
        stop(
          "Unsupported `cell_table_type` input: ",
          cell_table_type,
          "\n",
          "Supported values are: 'ad' and 'count'.",
          call. = FALSE
        )
      )
      self$set_params(
        ALPHA = alpha,
        MIN_COUNT_PER_CELL = min_count,
        CELL_TABLE_TYPE = cell_table_type_int
      )
      set_tetrad_test(
        self,
        "edu/cmu/tetrad/algcomparison/independence/GSquare",
        use_for_mc = use_for_mc
      )
    },
    use_conditional_gaussian_test = function(
      alpha = 0.05,
      discretize = TRUE,
      num_categories_to_discretize = 3,
      min_sample_size_per_cell = 4,
      use_for_mc = FALSE
    ) {
      checkmate::assert_number(alpha, lower = 0, finite = TRUE)
      checkmate::assert_int(num_categories_to_discretize, lower = 0)
      checkmate::assert_int(min_sample_size_per_cell, lower = 0)
      checkmate::assert_logical(discretize, len = 1)

      self$set_params(
        ALPHA = alpha,
        DISCRETIZE = discretize,
        NUM_CATEGORIES_TO_DISCRETIZE = num_categories_to_discretize,
        MIN_SAMPLE_SIZE_PER_CELL = min_sample_size_per_cell
      )
      set_tetrad_test(
        self,
        "edu/cmu/tetrad/algcomparison/independence/ConditionalGaussianLrt",
        use_for_mc = use_for_mc
      )
    },
    use_degenerate_gaussian_test = function(
      alpha = 0.05,
      singularity_lambda = 0.0,
      use_for_mc = FALSE
    ) {
      checkmate::assert_number(alpha, lower = 0, finite = TRUE)
      checkmate::assert_number(singularity_lambda, lower = 0, finite = TRUE)
      checkmate::assert_logical(use_for_mc, len = 1)

      self$set_params(
        ALPHA = alpha,
        SINGULARITY_LAMBDA = singularity_lambda
      )
      set_tetrad_test(
        self,
        "edu/cmu/tetrad/algcomparison/independence/DegenerateGaussianLrt",
        use_for_mc = use_for_mc
      )
    },
    use_probabilistic_test = function(
      threshold = FALSE,
      cutoff = 0.5,
      prior_ess = 10,
      use_for_mc = FALSE,
      alpha = NULL
    ) {
      checkmate::assert_logical(threshold, len = 1)
      checkmate::assert_logical(use_for_mc, len = 1)
      checkmate::assert_number(cutoff, lower = 0, finite = TRUE)
      checkmate::assert_number(prior_ess, lower = 0, finite = TRUE)

      self$set_params(
        NO_RANDOMLY_DETERMINED_INDEPENDENCE = threshold,
        CUTOFF_IND_TEST = cutoff,
        PRIOR_EQUIVALENT_SAMPLE_SIZE = prior_ess
      )
      set_tetrad_test(
        self,
        "edu/cmu/tetrad/algcomparison/independence/ProbabilisticTest",
        use_for_mc = use_for_mc
      )
    },
    use_kci_test = function(
      alpha = 0.05,
      approximate = TRUE,
      scaling_factor = 1,
      num_bootstraps = 1000,
      threshold = 1e-3,
      kernel_type = "gaussian",
      polyd = 5,
      polyc = 1,
      use_for_mc = FALSE
    ) {
      checkmate::assert_number(alpha, lower = 0, finite = TRUE)
      checkmate::assert_number(scaling_factor, lower = 0, finite = TRUE)
      checkmate::assert_int(num_bootstraps, lower = 0)
      checkmate::assert_number(threshold, lower = 0, finite = TRUE)
      checkmate::assert_int(polyd, lower = 1)
      checkmate::assert_int(polyc, lower = 0)
      checkmate::assert_logical(approximate, len = 1)
      checkmate::assert_logical(use_for_mc, len = 1)
      checkmate::assert_choice(
        kernel_type,
        choices = c("gaussian", "linear", "polynomial")
      )

      kernel_type_int <- switch(
        kernel_type,
        gaussian = 1L,
        linear = 2L,
        polynomial = 3L
      )

      self$set_params(
        KCI_USE_APPROXIMATION = approximate,
        ALPHA = alpha,
        KERNEL_TYPE = kernel_type_int,
        SCALING_FACTOR = scaling_factor,
        KCI_NUM_BOOTSTRAPS = num_bootstraps,
        THRESHOLD_FOR_NUM_EIGENVALUES = threshold,
        POLYNOMIAL_DEGREE = polyd,
        POLYNOMIAL_CONSTANT = polyc
      )
      set_tetrad_test(
        self,
        "edu/cmu/tetrad/algcomparison/independence/Kci",
        use_for_mc = use_for_mc
      )
    },
    use_cci_test = function(
      alpha = 0.05,
      scaling_factor = 2,
      basis_type = "legendre",
      basis_scale = 0.0,
      truncation_limit = 3,
      use_for_mc = FALSE
    ) {
      checkmate::assert_number(alpha, lower = 0, finite = TRUE)
      checkmate::assert_number(scaling_factor, lower = 0, finite = TRUE)
      checkmate::assert_int(truncation_limit, lower = 0)
      checkmate::assert_number(basis_scale, lower = 0, finite = TRUE)
      checkmate::assert_logical(use_for_mc, len = 1)
      checkmate::assert_character(basis_type, len = 1)

      basis_type_int <- switch(
        tolower(basis_type),
        polynomial = 1L,
        hermite1 = 2L,
        hermite2 = 3L,
        legendre = 4L,
        chebyshev = 5L,
        stop(
          "Unsupported `basis_type` input: ",
          basis_type,
          "\nSupported values are: 'polynomial', 'hermite1', 'hermite2', 'legendre', 'chebyshev'.",
          call. = FALSE
        )
      )

      self$set_params(
        ALPHA = alpha,
        SCALING_FACTOR = scaling_factor,
        BASIS_TYPE = basis_type_int,
        BASIS_SCALE = basis_scale,
        TRUNCATION_LIMIT = truncation_limit
      )
      set_tetrad_test(
        self,
        "edu/cmu/tetrad/algcomparison/independence/CciTest",
        use_for_mc = use_for_mc
      )
    },
    use_gin_test = function(
      alpha = 0.05,
      gin_backend = "dcor",
      num_permutations = 200,
      gin_ridge = 1e-8,
      seed = -1,
      use_for_mc = FALSE
    ) {
      checkmate::assert_number(alpha, lower = 0, finite = TRUE)
      checkmate::assert_int(num_permutations, lower = 0)
      checkmate::assert_number(gin_ridge, lower = 0, finite = TRUE)
      checkmate::assert_number(seed, finite = TRUE)
      checkmate::assert_logical(use_for_mc, len = 1)
      checkmate::assert_character(gin_backend, len = 1)
      checkmate::assert_choice(gin_backend, choices = c("dcor", "pearson"))

      self$set_params(
        ALPHA = alpha,
        GIN_PERMUTATIONS = num_permutations,
        GIN_RIDGE = gin_ridge,
        SEED = seed,
        GIN_BACKEND = gin_backend
      )
      set_tetrad_test(
        self,
        "edu/cmu/tetrad/algcomparison/independence/Gin",
        use_for_mc = use_for_mc
      )
    },
    use_rcit_test = function(
      alpha = 0.05,
      rcit_approx = "lpb4",
      rcit_ridge = 1e-3,
      num_feat = 10,
      num_fourier_feat_xy = 5,
      num_fourier_feat_z = 100,
      num_permutations = 500,
      center_features = TRUE,
      use_rcit = TRUE,
      seed = -1,
      use_for_mc = FALSE
    ) {
      checkmate::assert_number(alpha, lower = 0, finite = TRUE)
      checkmate::assert_number(rcit_ridge, lower = 0, finite = TRUE)
      checkmate::assert_int(num_feat, lower = 0)
      checkmate::assert_int(num_fourier_feat_xy, lower = 0)
      checkmate::assert_int(num_fourier_feat_z, lower = 0)
      checkmate::assert_int(num_permutations, lower = 0)
      checkmate::assert_number(seed, finite = TRUE)

      checkmate::assert_logical(use_for_mc, len = 1)
      checkmate::assert_logical(center_features, len = 1)
      checkmate::assert_logical(use_rcit, len = 1)

      checkmate::assert_character(rcit_approx, len = 1)
      checkmate::assert_choice(
        rcit_approx,
        choices = c("lpb4", "hbe", "gamma", "chi_square", "permutation")
      )

      self$set_params(
        ALPHA = alpha,
        RCIT_APPROX = rcit_approx,
        RCIT_LAMBDA = rcit_ridge,
        RCIT_NUM_FEATURES = num_feat,
        RCIT_NUM_FEATURES_XY = num_fourier_feat_xy,
        RCIT_NUM_FEATURES_Z = num_fourier_feat_z,
        RCIT_CENTER_FEATURES = center_features,
        RCIT_MODE = use_rcit,
        RCIT_PERMUTATIONS = num_permutations,
        SEED = seed
      )

      set_tetrad_test(
        self,
        "edu/cmu/tetrad/algcomparison/independence/Rcit",
        use_for_mc = use_for_mc
      )
    },
    use_sem_bic_test = function(
      penalty_discount = 2,
      structure_prior = 0,
      precompute_covariances = TRUE,
      singularity_lambda = 0.0,
      use_for_mc = FALSE,
      alpha = NULL
    ) {
      # sem_bic doesn't use alpha
      checkmate::assert_number(penalty_discount, lower = 0, finite = TRUE)
      checkmate::assert_number(structure_prior, lower = 0, finite = TRUE)
      checkmate::assert_number(singularity_lambda, lower = 0, finite = TRUE)
      checkmate::assert_logical(precompute_covariances, len = 1)
      checkmate::assert_logical(use_for_mc, len = 1)
      if (!precompute_covariances) {
        warning("`precompute_covariances = FALSE` doesn't work properly yet.")
        precompute_covariances <- TRUE
      }

      self$set_params(
        PENALTY_DISCOUNT = penalty_discount,
        STRUCTURE_PRIOR = structure_prior,
        PRECOMPUTE_COVARIANCES = precompute_covariances,
        SINGULARITY_LAMBDA = singularity_lambda
      )
      set_tetrad_test(
        self,
        "edu/cmu/tetrad/algcomparison/independence/SemBicTest",
        use_for_mc = use_for_mc
      )
    },
    use_rank_independence_test = function(
      alpha = 0.05,
      use_for_mc = FALSE
    ) {
      checkmate::assert_number(alpha, lower = 0, finite = TRUE)
      checkmate::assert_logical(use_for_mc, len = 1)

      self$set_params(
        ALPHA = alpha
      )
      set_tetrad_test(
        self,
        "edu/cmu/tetrad/algcomparison/independence/RankIndependenceTestTs",
        use_for_mc = use_for_mc
      )
    },
    use_basis_function_blocks_test = function(
      alpha = 0.05,
      basis_type = "polynomial",
      truncation_limit = 3,
      use_for_mc = FALSE
    ) {
      checkmate::assert_number(alpha, lower = 0, finite = TRUE)
      checkmate::assert_int(truncation_limit, lower = 0)
      checkmate::assert_character(basis_type, len = 1)
      checkmate::assert_logical(use_for_mc, len = 1)

      basis_type_int <- switch(
        tolower(basis_type),
        polynomial = 0L,
        legendre = 1L,
        hermite = 2L,
        chebyshev = 3L,
        stop(
          "Unsupported `basis_type` input: ",
          basis_type,
          "\n",
          "Supported values are: 'polynomial', 'legendre', 'hermite', and 'chebyshev'.",
          call. = FALSE
        )
      )
      self$set_params(
        ALPHA = alpha,
        BASIS_TYPE = basis_type_int,
        TRUNCATION_LIMIT = truncation_limit
      )
      set_tetrad_test(
        self,
        "edu/cmu/tetrad/algcomparison/independence/BasisFunctionBlocksIndTest",
        use_for_mc = use_for_mc
      )
    },

    # ---------------------------------- Algorithms ---------------------------
    set_fges_alg = function(
      symmetric_first_step = FALSE,
      max_degree = -1,
      faithfulness_assumed = FALSE,
      num_threads = 1
    ) {
      checkmate::assert_logical(symmetric_first_step, len = 1)
      checkmate::assert_number(max_degree, finite = TRUE)
      checkmate::assert_logical(faithfulness_assumed, len = 1)
      checkmate::assert_int(num_threads, lower = 1)

      self$set_params(
        SYMMETRIC_FIRST_STEP = symmetric_first_step,
        MAX_DEGREE = max_degree,
        FAITHFULNESS_ASSUMED = faithfulness_assumed,
        NUM_THREADS = num_threads
      )
      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/oracle/cpdag/Fges",
        self$score
      )

      # Set the `Knowledge` object
      self$alg$setKnowledge(self$knowledge)
    },
    set_fges_mb_alg = function(
      targets = "",
      max_degree = -1,
      trimming_style = "mb_dags",
      number_of_expansions = 2,
      faithfulness_assumed = FALSE
    ) {
      checkmate::assert_character(targets, len = 1)
      checkmate::assert_number(max_degree, lower = -1, finite = TRUE)
      checkmate::assert_character(trimming_style, len = 1)
      checkmate::assert_int(number_of_expansions, lower = 0)
      checkmate::assert_logical(faithfulness_assumed, len = 1)

      trimming_style_int <- switch(
        tolower(trimming_style),
        none = 1L,
        adj = 2L,
        mb_dags = 3L,
        semdir_paths = 4L,
        stop(
          "Unsupported `trimming_style` input: ",
          trimming_style,
          "\n",
          "Supported values are: 'none', 'adj', 'mb_dags' or 'semdir_paths'.",
          call. = FALSE
        )
      )
      self$set_params(
        TARGETS = targets,
        FAITHFULNESS_ASSUMED = faithfulness_assumed,
        MAX_DEGREE = max_degree,
        TRIMMING_STYLE = trimming_style_int,
        NUMBER_OF_EXPANSIONS = number_of_expansions
      )
      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/oracle/cpdag/FgesMb",
        self$score
      )
      self$alg$setKnowledge(self$knowledge)
    },
    set_boss_alg = function(
      num_starts = 1,
      use_bes = TRUE,
      use_data_order = TRUE,
      output_cpdag = TRUE,
      num_threads = 1,
      seed = -1
    ) {
      checkmate::assert_int(num_starts, lower = 1)
      checkmate::assert_logical(use_bes, len = 1)
      checkmate::assert_logical(use_data_order, len = 1)
      checkmate::assert_logical(output_cpdag, len = 1)
      checkmate::assert_int(num_threads, lower = 1)
      checkmate::assert_int(seed)

      self$set_params(
        USE_BES = use_bes,
        NUM_STARTS = num_starts,
        USE_DATA_ORDER = use_data_order,
        OUTPUT_CPDAG = output_cpdag,
        NUM_THREADS = num_threads,
        SEED = seed
      )

      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/oracle/cpdag/Boss",
        self$score
      )
      self$alg$setKnowledge(self$knowledge)
    },
    set_restricted_boss_alg = function(
      targets = "",
      use_bes = TRUE,
      num_starts = 1,
      trimming_style = "mb_dags",
      seed = -1
    ) {
      checkmate::assert_character(targets, len = 1)
      checkmate::assert_int(num_starts, lower = 1)
      checkmate::assert_logical(use_bes, len = 1)
      checkmate::assert_character(trimming_style, len = 1)
      checkmate::assert_int(seed)

      trimming_style_int <- switch(
        tolower(trimming_style),
        none = 1L,
        adj = 2L,
        mb_dags = 3L,
        semdir_paths = 4L,
        stop(
          "Unsupported `trimming_style` input: ",
          trimming_style,
          "\n",
          "Supported values are: 'none', 'adj', 'mb_dags' or 'semdir_paths'.",
          call. = FALSE
        )
      )

      self$set_params(
        TARGETS = targets,
        USE_BES = use_bes,
        NUM_STARTS = num_starts,
        TRIMMING_STYLE = trimming_style_int,
        SEED = seed
      )

      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/oracle/cpdag/RestrictedBoss",
        self$score
      )
    },
    set_cstar_alg = function(
      targets = "",
      file_out_path = "cstar-out",
      selection_min_effect = 0.0,
      num_subsamples = 50,
      top_bracket = 10,
      parallelized = FALSE,
      cpdag_algorithm = "restricted_boss",
      remove_effect_nodes = TRUE,
      sample_style = "subsample"
    ) {
      checkmate::assert_character(targets, len = 1)
      checkmate::assert_character(sample_style, len = 1)
      checkmate::assert_character(cpdag_algorithm, len = 1)

      checkmate::assert_number(selection_min_effect, lower = 0, finite = TRUE)
      checkmate::assert_int(num_subsamples, lower = 1)
      checkmate::assert_int(top_bracket, lower = 1)

      checkmate::assert_logical(parallelized, len = 1)
      checkmate::assert_logical(remove_effect_nodes, len = 1)

      sample_style_int <- switch(
        tolower(sample_style),
        subsample = 1L,
        bootstrap = 2L,
        stop(
          "Unsupported `sample_style` input: ",
          sample_style,
          "\n",
          "Supported values are: 'subsample' or 'bootstrap'.",
          call. = FALSE
        )
      )
      cpdag_algorithm_int <- switch(
        tolower(cpdag_algorithm),
        pc = 1L,
        fges = 2L,
        boss = 3L,
        restricted_boss = 4L,
        stop(
          "Unsupported `cpdag_algorithm` input: ",
          cpdag_algorithm,
          "\n",
          "Supported values are: 'pc', 'fges', 'boss', or 'restricted_boss'.",
          call. = FALSE
        )
      )
      self$set_params(
        SELECTION_MIN_EFFECT = selection_min_effect,
        NUM_SUBSAMPLES = num_subsamples,
        TARGETS = targets,
        TOP_BRACKET = top_bracket,
        PARALLELIZED = parallelized,
        CSTAR_CPDAG_ALGORITHM = cpdag_algorithm_int,
        FILE_OUT_PATH = file_out_path,
        REMOVE_EFFECT_NODES = remove_effect_nodes,
        SAMPLE_STYLE = sample_style_int
      )

      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/oracle/cpdag/Cstar",
        self$test,
        self$score
      )
    },
    set_sp_alg = function() {
      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/oracle/cpdag/Sp",
        self$score
      )
    },
    set_grasp_alg = function(
      covered_depth = 4,
      singular_depth = 1,
      nonsingular_depth = 1,
      ordered_alg = FALSE,
      raskutti_uhler = FALSE,
      use_data_order = TRUE,
      num_starts = 1,
      use_score = TRUE,
      allow_internal_randomness = TRUE,
      output_cpdag = TRUE,
      seed = -1
    ) {
      checkmate::assert_int(covered_depth)
      checkmate::assert_int(singular_depth)
      checkmate::assert_int(nonsingular_depth)

      checkmate::assert_logical(ordered_alg, len = 1)
      checkmate::assert_logical(raskutti_uhler, len = 1)
      checkmate::assert_logical(use_data_order, len = 1)
      checkmate::assert_logical(use_score, len = 1)
      checkmate::assert_logical(allow_internal_randomness, len = 1)
      checkmate::assert_logical(output_cpdag, len = 1)

      checkmate::assert_int(num_starts, lower = 1)
      checkmate::assert_int(seed)

      self$set_params(
        GRASP_DEPTH = covered_depth,
        GRASP_SINGULAR_DEPTH = singular_depth,
        GRASP_NONSINGULAR_DEPTH = nonsingular_depth,
        GRASP_ORDERED_ALG = ordered_alg,
        GRASP_USE_RASKUTTI_UHLER = raskutti_uhler,
        USE_DATA_ORDER = use_data_order,
        NUM_STARTS = num_starts,
        GRASP_USE_SCORE = use_score,
        ALLOW_INTERNAL_RANDOMNESS = allow_internal_randomness,
        OUTPUT_CPDAG = output_cpdag,
        SEED = seed
      )

      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/oracle/cpdag/Grasp",
        self$test,
        self$score
      )
      self$alg$setKnowledge(self$knowledge)
    },
    set_pc_alg = function(
      depth = -1,
      stable_fas = TRUE,
      collider_orientation_style = "max_p",
      allow_bidirected = FALSE,
      fdr_q = 0
    ) {
      checkmate::assert_number(depth, lower = -1, finite = TRUE)

      checkmate::assert_logical(stable_fas, len = 1)
      checkmate::assert_logical(allow_bidirected, len = 1)
      checkmate::assert_number(fdr_q, lower = 0, upper = 1)

      self$set_params(
        DEPTH = depth,
        STABLE_FAS = stable_fas,
        COLLIDER_ORIENTATION_STYLE = collider_orientation_style_int(
          collider_orientation_style
        ),
        ALLOW_BIDIRECTED = allow_bidirected,
        FDR_Q = fdr_q
      )

      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/oracle/cpdag/Pc",
        self$test
      )
      self$alg$setKnowledge(self$knowledge)
    },
    set_cpc_alg = function(
      depth = -1,
      stable_fas = TRUE,
      allow_bidirected = FALSE
    ) {
      checkmate::assert_number(depth, lower = -1, finite = TRUE)

      checkmate::assert_logical(stable_fas, len = 1)
      checkmate::assert_logical(allow_bidirected, len = 1)

      self$set_params(
        DEPTH = depth,
        STABLE_FAS = stable_fas,
        ALLOW_BIDIRECTED = allow_bidirected
      )

      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/oracle/cpdag/Cpc",
        self$test
      )
      self$alg$setKnowledge(self$knowledge)
    },
    set_pc_max_alg = function(
      depth = -1,
      stable_fas = TRUE,
      allow_bidirected = FALSE
    ) {
      checkmate::assert_number(depth, lower = -1, finite = TRUE)
      checkmate::assert_logical(stable_fas, len = 1)
      checkmate::assert_logical(allow_bidirected, len = 1)

      self$set_params(
        DEPTH = depth,
        STABLE_FAS = stable_fas,
        ALLOW_BIDIRECTED = allow_bidirected
      )

      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/oracle/cpdag/PcMax",
        self$test
      )
      self$alg$setKnowledge(self$knowledge)
    },
    set_fci_alg = function(
      depth = -1,
      stable_fas = TRUE,
      max_disc_path_length = -1,
      complete_rule_set_used = TRUE,
      guarantee_pag = FALSE,
      collider_orientation_style = "max_p",
      do_possible_dsep = TRUE,
      exclude_selection_bias = FALSE,
      fdr_q = 0
    ) {
      checkmate::assert_number(depth, lower = -1, finite = TRUE)
      checkmate::assert_logical(stable_fas, len = 1)

      checkmate::assert_number(max_disc_path_length, finite = TRUE)
      if (!(max_disc_path_length >= 0 || max_disc_path_length == -1)) {
        stop(
          "`max_disc_path_length` must be >= 0 or equal to -1.",
          call. = FALSE
        )
      }

      checkmate::assert_logical(complete_rule_set_used, len = 1)
      checkmate::assert_logical(guarantee_pag, len = 1)
      checkmate::assert_logical(do_possible_dsep, len = 1)
      checkmate::assert_logical(exclude_selection_bias, len = 1)
      checkmate::assert_number(fdr_q, lower = 0, upper = 1)

      self$set_params(
        DEPTH = depth,
        STABLE_FAS = stable_fas,
        MAX_DISCRIMINATING_PATH_LENGTH = max_disc_path_length,
        COMPLETE_RULE_SET_USED = complete_rule_set_used,
        GUARANTEE_PAG = guarantee_pag,
        COLLIDER_ORIENTATION_STYLE = collider_orientation_style_int(
          collider_orientation_style
        ),
        DO_POSSIBLE_DSEP = do_possible_dsep,
        EXCLUDE_SELECTION_BIAS = exclude_selection_bias,
        FDR_Q = fdr_q
      )

      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/oracle/pag/Fci",
        self$test
      )
      self$alg$setKnowledge(self$knowledge)
    },
    set_rfci_alg = function(
      depth = -1,
      max_disc_path_length = -1,
      exclude_selection_bias = FALSE,
      fdr_q = 0
    ) {
      checkmate::assert_number(depth, lower = -1, finite = TRUE)

      checkmate::assert_number(max_disc_path_length, finite = TRUE)
      if (!(max_disc_path_length >= 0 || max_disc_path_length == -1)) {
        stop(
          "`max_disc_path_length` must be >= 0 or equal to -1.",
          call. = FALSE
        )
      }

      checkmate::assert_logical(exclude_selection_bias, len = 1)
      checkmate::assert_number(fdr_q, lower = 0, upper = 1)

      self$set_params(
        DEPTH = depth,
        MAX_DISCRIMINATING_PATH_LENGTH = max_disc_path_length,
        EXCLUDE_SELECTION_BIAS = exclude_selection_bias,
        FDR_Q = fdr_q
      )

      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/oracle/pag/Rfci",
        self$test
      )
      self$alg$setKnowledge(self$knowledge)
    },
    set_cfci_alg = function(
      depth = -1,
      max_disc_path_length = -1,
      complete_rule_set_used = TRUE,
      do_possible_dsep = TRUE
    ) {
      checkmate::assert_number(depth, lower = -1, finite = TRUE)

      checkmate::assert_number(max_disc_path_length, finite = TRUE)
      if (!(max_disc_path_length >= 0 || max_disc_path_length == -1)) {
        stop(
          "`max_disc_path_length` must be >= 0 or equal to -1.",
          call. = FALSE
        )
      }

      checkmate::assert_logical(complete_rule_set_used, len = 1)
      checkmate::assert_logical(do_possible_dsep, len = 1)

      self$set_params(
        DEPTH = depth,
        MAX_DISCRIMINATING_PATH_LENGTH = max_disc_path_length,
        COMPLETE_RULE_SET_USED = complete_rule_set_used,
        DO_POSSIBLE_DSEP = do_possible_dsep
      )

      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/oracle/pag/Cfci",
        self$test
      )
      self$alg$setKnowledge(self$knowledge)
    },
    set_gfci_alg = function(
      depth = -1,
      max_degree = -1,
      max_disc_path_length = -1,
      complete_rule_set_used = TRUE,
      guarantee_pag = FALSE,
      use_heuristic = FALSE,
      start_complete = FALSE,
      num_threads = 1,
      exclude_selection_bias = FALSE
    ) {
      checkmate::assert_number(depth, lower = -1, finite = TRUE)
      checkmate::assert_number(max_degree, finite = TRUE)
      checkmate::assert_int(num_threads, lower = 1)

      checkmate::assert_number(max_disc_path_length, finite = TRUE)
      if (!(max_disc_path_length >= 0 || max_disc_path_length == -1)) {
        stop(
          "`max_disc_path_length` must be >= 0 or equal to -1.",
          call. = FALSE
        )
      }

      checkmate::assert_logical(complete_rule_set_used, len = 1)
      checkmate::assert_logical(guarantee_pag, len = 1)
      checkmate::assert_logical(use_heuristic, len = 1)
      checkmate::assert_logical(start_complete, len = 1)
      checkmate::assert_logical(exclude_selection_bias, len = 1)

      self$set_params(
        DEPTH = depth,
        MAX_DEGREE = max_degree,
        COMPLETE_RULE_SET_USED = complete_rule_set_used,
        MAX_DISCRIMINATING_PATH_LENGTH = max_disc_path_length,
        GUARANTEE_PAG = guarantee_pag,
        USE_MAX_P_HEURISTIC = use_heuristic,
        START_FROM_COMPLETE_GRAPH = start_complete,
        NUM_THREADS = num_threads,
        EXCLUDE_SELECTION_BIAS = exclude_selection_bias
      )

      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/oracle/pag/Gfci",
        self$test,
        self$score
      )
      self$alg$setKnowledge(self$knowledge)
    },
    set_boss_fci_alg = function(
      use_bes = TRUE,
      max_disc_path_length = -1,
      complete_rule_set_used = TRUE,
      depth = -1,
      num_threads = 1,
      guarantee_pag = FALSE,
      use_heuristic = FALSE,
      num_starts = 1,
      exclude_selection_bias = FALSE
    ) {
      checkmate::assert_int(max_disc_path_length)
      if (!(max_disc_path_length >= 0 || max_disc_path_length == -1)) {
        stop(
          "`max_disc_path_length` must be >= 0 or equal to -1.",
          call. = FALSE
        )
      }

      checkmate::assert_int(depth, lower = -1)
      checkmate::assert_int(num_starts, lower = 1)
      checkmate::assert_int(num_threads, lower = 1)

      checkmate::assert_logical(use_bes, len = 1)
      checkmate::assert_logical(complete_rule_set_used, len = 1)
      checkmate::assert_logical(guarantee_pag, len = 1)
      checkmate::assert_logical(use_heuristic, len = 1)
      checkmate::assert_logical(exclude_selection_bias, len = 1)

      self$set_params(
        USE_BES = use_bes,
        MAX_DISCRIMINATING_PATH_LENGTH = max_disc_path_length,
        COMPLETE_RULE_SET_USED = complete_rule_set_used,
        DEPTH = depth,
        GUARANTEE_PAG = guarantee_pag,
        USE_MAX_P_HEURISTIC = use_heuristic,
        NUM_STARTS = num_starts,
        NUM_THREADS = num_threads,
        EXCLUDE_SELECTION_BIAS = exclude_selection_bias
      )

      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/oracle/pag/BossFci",
        self$test,
        self$score
      )
      self$alg$setKnowledge(self$knowledge)
    },
    set_fcit_alg = function(
      use_bes = TRUE,
      use_data_order = TRUE,
      num_starts = 1,
      start_with = "boss",
      complete_rule_set_used = TRUE,
      depth = -1,
      exclude_selection_bias = FALSE
    ) {
      checkmate::assert_int(num_starts, lower = 1)
      checkmate::assert_int(depth, lower = -1)

      checkmate::assert_logical(use_bes, len = 1)
      checkmate::assert_logical(use_data_order, len = 1)
      checkmate::assert_logical(complete_rule_set_used, len = 1)
      checkmate::assert_logical(exclude_selection_bias, len = 1)

      checkmate::assert_character(start_with, len = 1)

      start_with_int <- switch(
        tolower(start_with),
        boss = 1L,
        grasp = 2L,
        sp = 3L,
        stop(
          "Unsupported `start_with` input: ",
          start_with,
          "\n",
          "Supported values are: 'boss', 'grasp', or 'sp'.",
          call. = FALSE
        )
      )
      self$set_params(
        USE_BES = use_bes,
        USE_DATA_ORDER = use_data_order,
        NUM_STARTS = num_starts,
        FCIT_STARTS_WITH = start_with_int,
        COMPLETE_RULE_SET_USED = complete_rule_set_used,
        DEPTH = depth,
        EXCLUDE_SELECTION_BIAS = exclude_selection_bias
      )

      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/oracle/pag/Fcit",
        self$test,
        self$score
      )
      self$alg$setKnowledge(self$knowledge)
    },
    set_grasp_fci_alg = function(
      depth = -1,
      max_disc_path_length = -1,
      complete_rule_set_used = TRUE,
      singular_depth = 1,
      nonsingular_depth = 1,
      ordered_alg = FALSE,
      raskutti_uhler = FALSE,
      use_data_order = TRUE,
      num_starts = 1,
      guarantee_pag = FALSE,
      use_score = TRUE,
      use_heuristic = FALSE,
      exclude_selection_bias = FALSE,
      seed = -1
    ) {
      checkmate::assert_int(depth, lower = -1)
      checkmate::assert_int(max_disc_path_length)
      if (!(max_disc_path_length >= 0 || max_disc_path_length == -1)) {
        stop(
          "`max_disc_path_length` must be >= 0 or equal to -1.",
          call. = FALSE
        )
      }
      checkmate::assert_int(singular_depth)
      checkmate::assert_int(nonsingular_depth)
      checkmate::assert_int(num_starts, lower = 1)
      checkmate::assert_int(seed)

      checkmate::assert_logical(ordered_alg, len = 1)
      checkmate::assert_logical(raskutti_uhler, len = 1)
      checkmate::assert_logical(use_data_order, len = 1)
      checkmate::assert_logical(guarantee_pag, len = 1)
      checkmate::assert_logical(use_score, len = 1)
      checkmate::assert_logical(use_heuristic, len = 1)
      checkmate::assert_logical(exclude_selection_bias, len = 1)

      self$set_params(
        GRASP_SINGULAR_DEPTH = singular_depth,
        GRASP_NONSINGULAR_DEPTH = nonsingular_depth,
        GRASP_ORDERED_ALG = ordered_alg,
        GRASP_USE_RASKUTTI_UHLER = raskutti_uhler,
        USE_DATA_ORDER = use_data_order,
        NUM_STARTS = num_starts,
        GUARANTEE_PAG = guarantee_pag,
        DEPTH = depth,
        MAX_DISCRIMINATING_PATH_LENGTH = max_disc_path_length,
        COMPLETE_RULE_SET_USED = complete_rule_set_used,
        GRASP_USE_SCORE = use_score,
        USE_MAX_P_HEURISTIC = use_heuristic,
        EXCLUDE_SELECTION_BIAS = exclude_selection_bias,
        SEED = seed
      )

      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/oracle/pag/GraspFci",
        self$test,
        self$score
      )
      self$alg$setKnowledge(self$knowledge)
    },
    set_sp_fci_alg = function(
      max_disc_path_length = -1,
      complete_rule_set_used = TRUE,
      guarantee_pag = FALSE,
      use_heuristic = FALSE,
      exclude_selection_bias = FALSE
    ) {
      checkmate::assert_int(max_disc_path_length)
      if (!(max_disc_path_length >= 0 || max_disc_path_length == -1)) {
        stop(
          "`max_disc_path_length` must be >= 0 or equal to -1.",
          call. = FALSE
        )
      }

      checkmate::assert_logical(complete_rule_set_used, len = 1)
      checkmate::assert_logical(guarantee_pag, len = 1)
      checkmate::assert_logical(use_heuristic, len = 1)
      checkmate::assert_logical(exclude_selection_bias, len = 1)

      self$set_params(
        MAX_DISCRIMINATING_PATH_LENGTH = max_disc_path_length,
        COMPLETE_RULE_SET_USED = complete_rule_set_used,
        GUARANTEE_PAG = guarantee_pag,
        USE_MAX_P_HEURISTIC = use_heuristic,
        EXCLUDE_SELECTION_BIAS = exclude_selection_bias
      )

      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/oracle/pag/SpFci",
        self$test,
        self$score
      )
      self$alg$setKnowledge(self$knowledge)
    },
    set_ica_lingam_alg = function(
      ica_a = 1.1,
      ica_max_iter = 5000,
      ica_tolerance = 1e-8,
      threshold_b = 0.1
    ) {
      checkmate::assert_number(ica_a, lower = 0, finite = TRUE)
      checkmate::assert_int(ica_max_iter, lower = 0)
      checkmate::assert_number(ica_tolerance, lower = 0, finite = TRUE)
      checkmate::assert_number(threshold_b, lower = 0, finite = TRUE)

      self$set_params(
        FAST_ICA_A = ica_a,
        FAST_ICA_MAX_ITER = ica_max_iter,
        FAST_ICA_TOLERANCE = ica_tolerance,
        THRESHOLD_B = threshold_b
      )

      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/continuous/dag/IcaLingam"
      )
    },
    set_ica_lingd_alg = function(
      ica_a = 1.1,
      ica_max_iter = 5000,
      ica_tolerance = 1e-8,
      threshold_b = 0.1,
      threshold_w = 0.1
    ) {
      checkmate::assert_number(ica_a, lower = 0, finite = TRUE)
      checkmate::assert_int(ica_max_iter, lower = 0)
      checkmate::assert_number(ica_tolerance, lower = 0, finite = TRUE)
      checkmate::assert_number(threshold_b, lower = 0, finite = TRUE)
      checkmate::assert_number(threshold_w, lower = 0, finite = TRUE)

      self$set_params(
        FAST_ICA_A = ica_a,
        FAST_ICA_MAX_ITER = ica_max_iter,
        FAST_ICA_TOLERANCE = ica_tolerance,
        THRESHOLD_B = threshold_b,
        THRESHOLD_W = threshold_w
      )

      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/continuous/dag/IcaLingD"
      )
    },
    set_fask_alg = function(
      alpha = 0.05,
      depth = -1,
      fask_delta = -0.3,
      left_right_rule = 1,
      skew_edge_threshold = 0.3
    ) {
      checkmate::assert_number(alpha, lower = 0, finite = TRUE)
      checkmate::assert_int(depth, lower = -1)
      checkmate::assert_number(fask_delta, lower = -1, finite = TRUE)
      checkmate::assert_number(skew_edge_threshold, lower = 0, finite = TRUE)
      checkmate::assert_int(left_right_rule)

      self$set_params(
        ALPHA = alpha,
        DEPTH = depth,
        FASK_DELTA = fask_delta,
        FASK_LEFT_RIGHT_RULE = left_right_rule,
        SKEW_EDGE_THRESHOLD = skew_edge_threshold
      )

      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/continuous/dag/Fask",
        self$score
      )
      self$alg$setKnowledge(self$knowledge)
    },
    set_ccd_alg = function(apply_r1 = TRUE, fdr_q = 0) {
      checkmate::assert_logical(apply_r1, len = 1)
      checkmate::assert_number(fdr_q, lower = 0, upper = 1)

      self$set_params(
        APPLY_R1 = apply_r1,
        FDR_Q = fdr_q
      )

      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/oracle/pag/Ccd",
        self$test
      )
    },
    set_direct_lingam_alg = function() {
      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/continuous/dag/DirectLingam",
        self$score
      )
    },
    set_dagma_alg = function(lambda1 = 0.05, w_threshold = 0.1, cpdag = TRUE) {
      checkmate::assert_number(lambda1, lower = 0, finite = TRUE)
      checkmate::assert_number(w_threshold, lower = 0, finite = TRUE)
      checkmate::assert_logical(cpdag, len = 1)

      self$set_params(
        LAMBDA1 = lambda1,
        W_THRESHOLD = w_threshold,
        CPDAG = cpdag
      )
      self$alg <- rJava::.jnew(
        "edu/cmu/tetrad/algcomparison/algorithm/continuous/dag/Dagma"
      )
    }
  )
)

#' Set Tetrad Test Helper Function
#' @param self The instance of the class.
#' @param class_name The Java class name of the test to create.
#' @param use_for_mc Logical indicating if the test is for MC or not.
#' @return None. Sets the test object in the appropriate slot.
#' @keywords internal
#' @noRd
set_tetrad_test <- function(self, class_name, use_for_mc = FALSE) {
  # Create the Java test object once
  test_obj <- rJava::.jnew(class_name)
  test_obj <- cast_obj(test_obj)

  # Assign to the correct slots
  if (use_for_mc) {
    self$mc_test <- test_obj
  }
  self$test <- test_obj
}

#' Map a collider orientation style name to Tetrad's integer code
#' @param style One of \code{"sepsets"}, \code{"conservative"}, or
#'   \code{"max_p"}.
#' @return Integer code for \code{Params.COLLIDER_ORIENTATION_STYLE}.
#' @keywords internal
#' @noRd
collider_orientation_style_int <- function(style) {
  checkmate::assert_character(style, len = 1)
  switch(
    tolower(style),
    sepsets = 1L,
    conservative = 2L,
    max_p = 3L,
    stop(
      "Unsupported `collider_orientation_style` input: ",
      style,
      "\n",
      "Supported values are: 'sepsets', 'conservative', or 'max_p'.",
      call. = FALSE
    )
  )
}
