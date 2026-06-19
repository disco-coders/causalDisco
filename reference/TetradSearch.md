# R6 Interface to Tetrad Search Algorithms

High-level wrapper around the Java-based Tetrad causal-discovery
library. The class lets you choose independence tests, scores, and
search algorithms from Tetrad, run them on an R data set, and retrieve
the resulting graph or statistics.

## Public fields

- `data`:

  Java object that stores the (possibly converted) data set used by
  Tetrad.

- `rdata`:

  Original **R** `data.frame` supplied by the user.

- `score`:

  Java object holding the scoring function selected with `set_score()`.
  Supply one of the method strings for `set_score()`. Recognised values
  are:

  **Continuous - Gaussian**

  - `"ebic"` - Extended BIC score.

  - `"gic"` - Generalized Information Criterion (GIC) score.

  - `"poisson_prior"` - Poisson prior score.

  - `"rank_bic"` - Rank-based BIC score.

  - `"sem_bic"` - SEM BIC score.

  - `"zhang_shen_bound"` - Zhang and Shen bound score.

  **Discrete - categorical**

  - `"bdeu"` - Bayes Dirichlet Equivalent score with uniform priors.

  - `"discrete_bic"` - BIC score for discrete data.

  **Mixed Discrete/Gaussian**

  - `"basis_function_bic"` - BIC score for basis-function models. This
    is a generalization of the Degenerate Gaussian score.

  - `"basis_function_blocks_bic"` - BIC score for mixed data using
    basis-function models.

  - `"basis_function_sem_bic"` - SEM BIC score for basis-function
    models.

  - `"conditional_gaussian"` - Conditional Gaussian BIC score.

  - `"degenerate_gaussian"` - Degenerate Gaussian BIC score.

  - `"mag_degenerate_gaussian_bic"` - MAG Degenerate Gaussian BIC Score.

- `test`:

  Java object holding the independence test selected with `set_test()`.
  Supply one of the method strings for `set_test()`. Recognised values
  are:

  **Continuous - Gaussian**

  - `"fisher_z"` - Fisher \\Z\\ (partial correlation) test.

  - `"poisson_prior"` - Poisson prior test.

  - `"rank_independence"` - Rank-based independence test.

  - `"sem_bic"` - SEM BIC test.

  **Discrete - categorical**

  - `"chi_square"` - chi-squared test

  - `"g_square"` - likelihood-ratio \\G^2\\ test.

  - `"probabilistic"` - Uses BCInference by Cooper and Bui to calculate
    probabilistic conditional independence judgments.

  **General**

  - `"gin"` - Generalized Independence Noise test.

  - `"kci"` - Kernel Conditional Independence Test (KCI) by Kun Zhang.

  - `"rcit"` - Randomized Conditional Independence Test (RCIT).

  **Mixed Discrete/Gaussian**

  - `"basis_function_blocks"` - Basis-function blocks test.

  - `"basis_function_lrt"` - basis-function likelihood-ratio.

  - `"conditional_gaussian"` - Conditional Gaussian test as a likelihood
    ratio test.

  - `"degenerate_gaussian"` - Degenerate Gaussian test as a likelihood
    ratio test.

- `alg`:

  Java object representing the search algorithm. Supply one of the
  method strings for `set_alg()`. Recognised values are:

  **Constraint-based**

  - `"fci"` - FCI algorithm. See
    [`fci()`](https://disco-coders.github.io/causalDisco/reference/fci.md).

  - `"pc"` - Peter-Clark (PC) algorithm. See
    [`pc()`](https://disco-coders.github.io/causalDisco/reference/pc.md).

  - `"rfci"` - Restricted FCI algorithm. See
    [`rfci()`](https://disco-coders.github.io/causalDisco/reference/rfci.md).

  **Hybrid**

  - `"boss_fci"` - BOSS-FCI algorithm. See
    [`boss_fci()`](https://disco-coders.github.io/causalDisco/reference/boss_fci.md).

  - `"gfci"` - GFCI algorithm. See
    [`gfci()`](https://disco-coders.github.io/causalDisco/reference/gfci.md).

  - `"grasp_fci"` - GRaSP-FCI algorithm. See
    [`grasp_fci()`](https://disco-coders.github.io/causalDisco/reference/grasp_fci.md).

  - `"sp_fci"` - Sparsest Permutation using FCI. See
    [`sp_fci()`](https://disco-coders.github.io/causalDisco/reference/sp_fci.md).

  **Score-based**

  - `"boss"` - BOSS algorithm. See
    [`boss()`](https://disco-coders.github.io/causalDisco/reference/boss.md).

  - `"ges" ("fges")` - (Fast) Greedy Equivalence Search (GES) algorithm.
    See
    [`ges()`](https://disco-coders.github.io/causalDisco/reference/ges.md).

  - `"grasp"` - GRaSP (Greedy Relations of Sparsest Permutation)
    algorithm. See
    [`grasp()`](https://disco-coders.github.io/causalDisco/reference/grasp.md).

- `mc_test`:

  Java independence-test object used by the Markov checker.

- `java`:

  Java object returned by the search (typically a graph).

- `result`:

  Convenience alias for `java`; may store additional metadata depending
  on the search type.

- `knowledge`:

  Java `Knowledge` object carrying background constraints
  (required/forbidden edges).

- `params`:

  Java `Parameters` object holding algorithm settings.

- `bootstrap_graphs`:

  Java `List` of graphs produced by bootstrap resampling, if that
  feature was requested.

- `mc_ind_results`:

  Java `List` with Markov-checker test results.

## Methods

### Public methods

- [`TetradSearch$new()`](#method-TetradSearch-initialize)

- [`TetradSearch$set_test()`](#method-TetradSearch-set_test)

- [`TetradSearch$set_score()`](#method-TetradSearch-set_score)

- [`TetradSearch$set_alg()`](#method-TetradSearch-set_alg)

- [`TetradSearch$set_knowledge()`](#method-TetradSearch-set_knowledge)

- [`TetradSearch$set_params()`](#method-TetradSearch-set_params)

- [`TetradSearch$get_parameters_for_function()`](#method-TetradSearch-get_parameters_for_function)

- [`TetradSearch$run_search()`](#method-TetradSearch-run_search)

- [`TetradSearch$set_bootstrapping()`](#method-TetradSearch-set_bootstrapping)

- [`TetradSearch$set_data()`](#method-TetradSearch-set_data)

- [`TetradSearch$set_verbose()`](#method-TetradSearch-set_verbose)

- [`TetradSearch$set_time_lag()`](#method-TetradSearch-set_time_lag)

- [`TetradSearch$get_data()`](#method-TetradSearch-get_data)

- [`TetradSearch$get_knowledge()`](#method-TetradSearch-get_knowledge)

- [`TetradSearch$get_java()`](#method-TetradSearch-get_java)

- [`TetradSearch$get_string()`](#method-TetradSearch-get_string)

- [`TetradSearch$get_dot()`](#method-TetradSearch-get_dot)

- [`TetradSearch$get_amat()`](#method-TetradSearch-get_amat)

- [`TetradSearch$clone()`](#method-TetradSearch-clone)

------------------------------------------------------------------------

### `TetradSearch$new()`

Initializes the `TetradSearch` object, creating new Java objects for
`knowledge` and `params`.

#### Usage

    TetradSearch$new()

------------------------------------------------------------------------

### `TetradSearch$set_test()`

Sets the independence test to use in Tetrad.

#### Usage

    TetradSearch$set_test(method, ..., use_for_mc = FALSE)

#### Arguments

- `method`:

  (character) Name of the test method (e.g., "chi_square", "fisher_z").

  - `"basis_function_blocks"` - Basis-function blocks test

  - `"basis_function_lrt"` - basis-function likelihood-ratio

  - `"chi_square"` - chi-squared test

  - `"conditional_gaussian"` - Mixed discrete/continuous test

  - `"degenerate_gaussian"` - Degenerate Gaussian test as a likelihood
    ratio test

  - `"fisher_z"` - Fisher \\Z\\ (partial correlation) test

  - `"gin"` - Generalized Independence Noise test

  - `"kci"` - Kernel Conditional Independence Test (KCI) by Kun Zhang

  - `"poisson_prior"` - Poisson prior test

  - `"probabilistic"` - Uses BCInference by Cooper and Bui to calculate
    probabilistic conditional independence judgments.

  - `"rcit"` - Randomized Conditional Independence Test (RCIT)

  - `"rank_independence"` - Rank-based independence test

  - `"sem_bic"` - SEM BIC test

- `...`:

  Additional arguments passed to the private test-setting methods. For
  the following tests, the following parameters are available:

  - `"basis_function_blocks"` - Basis-function blocks test.

    - `alpha = 0.05` - Significance level for the independence test,

    - `basis_type = "polynomial"` - The type of basis to use. Supported
      types are `"polynomial"`, `"legendre"`, `"hermite"`, and
      `"chebyshev"`,

    - `truncation_limit = 3` - Basis functions 1 through this number
      will be used. The Degenerate Gaussian category indicator variables
      for mixed data are also used.

  - `"basis_function_lrt"` - basis-function likelihood-ratio

    - `truncation_limit = 3` - Basis functions 1 through this number
      will be used. The Degenerate Gaussian category indicator variables
      for mixed data are also used,

    - `alpha = 0.05` - Significance level for the likelihood-ratio test,

    - `singularity_lambda = 0.0` - Small number \>= 0: Add lambda to the
      diagonal, \< 0 Pseudoinverse,

    - `do_one_equation_only = FALSE` - If TRUE, only one equation should
      be used when expanding the basis.

  - `"chi_square"` - chi-squared test

    - `min_count = 1` - Minimum count for the chi-squared test per cell.
      Increasing this can improve accuracy of the test estimates,

    - `alpha = 0.05` - Significance level for the independence test,

    - `cell_table_type = "ad"` - The type of cell table to use for
      optimization. Available types are: `"ad"` - AD tree, `"count"` -
      Count sample.

  - `"conditional_gaussian"` - Mixed discrete/continuous test

    - `alpha = 0.05` - Significance level for the independence test,

    - `discretize = TRUE` - If TRUE for the conditional Gaussian
      likelihood, when scoring X –\> D where X is continuous and D
      discrete, one should simply discretize X for just those cases. If
      FALSE, the integration will be exact,

    - `num_categories_to_discretize = 3` - In case the exact algorithm
      is not used for discrete children and continuous parents is not
      used, this parameter gives the number of categories to use for
      this second (discretized) backup copy of the continuous variables,

    - `min_sample_size_per_cell = 4` - Minimum sample size per cell for
      the independence test.

  - `"degenerate_gaussian"` - Degenerate Gaussian likelihood ratio test

    - `alpha = 0.05` - Significance level for the independence test,

    - `singularity_lambda = 0.0` - Small number \>= 0: Add lambda to the
      diagonal, \< 0 Pseudoinverse.

  - `"fisher_z"` - Fisher \\Z\\ (partial correlation) test

    - `alpha = 0.05` - Significance level for the independence test,

    - `singularity_lambda = 0.0` - Small number \>= 0: Add lambda to the
      diagonal, \< 0 Pseudoinverse.

  - `"gin"` - Generalized Independence Noise test.

    - `alpha = 0.05` - Significance level for the independence test,

    - `gin_backend = "dcor"` - Unconditional test for residual
      independence. Available types are `"dcor"` - Distance correlation
      (for non-linear) and `"pearson"` - Pearson correlation (for
      linear),

    - `num_permutations = 200` - Number of permutations used for
      `"dcor"` backend. If `"pearson"` backend is used, this parameter
      is ignored.

    - `gin_ridge = 1e-8` - Ridge parameter used when computing
      residuals. A small number \>= 0.

    - `seed = -1` - Random seed for the independence test. If -1, no
      seed is set.

  - `"kci"` - Kernel Conditional Independence Test (KCI) by Kun Zhang

    - `alpha = 0.05` - Significance level for the independence test,

    - `approximate = TRUE` - If TRUE, use the approximate Gamma
      approximation algorithm. If FALSE, use the exact,

    - `scaling_factor = 1` - For Gaussian kernel: The scaling factor \*
      Silverman bandwidth.

    - `num_bootstraps = 1000` - Number of bootstrap samples to use for
      the KCI test. Only used if `approximate = FALSE`.

    - `threshold = 1e-3` - Threshold for the KCI test. Threshold to
      determine how many eigenvalues to use – the lower the more (0 to
      1).

    - `kernel_type = "gaussian"` - The type of kernel to use. Available
      types are `"gaussian"`, `"linear"`, or `"polynomial"`.

    - `polyd = 5` - The degree of the polynomial kernel, if used.

    - `polyc = 1` - The constant of the polynomial kernel, if used.

  - `"poisson_prior"` - Poisson prior test

    - `poisson_lambda = 1` - Lambda parameter for the Poisson
      distribution (\> 0),

    - `singularity_lambda = 0.0` - Small number \>= 0: Add lambda to the
      diagonal, \< 0 Pseudoinverse.

  - `"probabilistic"` - Uses BCInference by Cooper and Bui to calculate
    probabilistic conditional independence judgments.

    - `threshold = FALSE` - Set to TRUE if using the cutoff threshold
      for the independence test,

    - `cutoff = 0.5` - Cutoff for the independence test,

    - `prior_ess = 10` - Prior equivalent sample size for the
      independence test. This number is added to the sample size for
      each conditional probability table in the model and is divided
      equally among the cells in the table.

  - `"rcit"` - Randomized Conditional Independence Test (RCIT).

    - `alpha = 0.05` - Significance level for the independence test,

    - `rcit_approx = "lpb4"` - Null approximation method. Recognized
      values are: `"lpb4"` - Lindsay-Pilla-Basak method with 4 support
      points, `"hbe"` - Hall-Buckley-Eagleson method, `"gamma"` - Gamma
      (Satterthwaite-Welch), `"chi_square"` - Chi-square (normalized),
      `"permutation"` - Permutation-based (computationally intensive),

    - `rcit_ridge = 1e-3` - Ridge parameter used when computing
      residuals. A small number \>= 0,

    - `num_feat = 10` - Number of random features to use for the
      regression of X and Y on Z. Values between 5 and 20 often suffice.

    - `num_fourier_feat_xy = 5` - Number of random Fourier features to
      use for the tested variables X and Y. Small values often suffice
      (e.g., 3 to 10),

    - `num_fourier_feat_z = 100` - Number of random Fourier features to
      use for the conditioning set Z. Values between 50 and 300 often
      suffice,

    - `center_features = TRUE` - If TRUE, center the random features to
      have mean zero. Recommended for better numerical stability,

    - `use_rcit = TRUE` - If TRUE, use RCIT; if FALSE, use RCoT
      (Randomized Conditional Correlation Test),

    - `num_permutations = 500` - Number of permutations used for the
      independence test when `rcit_approx = "permutation"` is selected.

    - `seed = -1` - Random seed for the independence test. If -1, no
      seed is set.

  - `"rank_independence"` - Rank-based independence test.

    - `alpha = 0.05` - Significance level for the independence test.

  - `"sem_bic"` - SEM BIC test.

    - `penalty_discount = 2` - Penalty discount factor used in BIC =
      2L - ck log N, where c is the penalty. Higher c yield sparser
      graphs,

    - `structure_prior = 0` - The default number of parents for any
      conditional probability table. Higher weight is accorded to tables
      with about that number of parents. The prior structure weights are
      distributed according to a binomial distribution,

    - `singularity_lambda = 0.0` - Small number \>= 0: Add lambda to the
      diagonal, \< 0 Pseudoinverse.

- `use_for_mc`:

  (logical) If TRUE, sets this test for the Markov checker `mc_test`.

#### Returns

Invisibly returns `self`, for chaining.

------------------------------------------------------------------------

### `TetradSearch$set_score()`

Sets the scoring function to use in Tetrad.

#### Usage

    TetradSearch$set_score(method, ...)

#### Arguments

- `method`:

  (character) Name of the score (e.g., "sem_bic", "ebic", "bdeu").

  - `"bdeu"` - Bayes Dirichlet Equivalent score with uniform priors.

  - `"basis_function_bic"` - BIC score for basis-function models. This
    is a generalization of the Degenerate Gaussian score.

  - `"basis_function_blocks_bic"` - BIC score for mixed data using
    basis-function models.

  - `"basis_function_sem_bic"` - SEM BIC score for basis-function
    models.

  - `"conditional_gaussian"` - Mixed discrete/continuous BIC score.

  - `"degenerate_gaussian"` - Degenerate Gaussian BIC score.

  - `"discrete_bic"` - BIC score for discrete data.

  - `"ebic"` - Extended BIC score.

  - `"gic"` - Generalized Information Criterion (GIC) score.

  - `"mag_degenerate_gaussian_bic"` - MAG Degenerate Gaussian BIC Score.

  - `"poisson_prior"` - Poisson prior score.

  - `"rank_bic"` - Rank-based BIC score.

  - `"sem_bic"` - SEM BIC score.

  - `"zhang_shen_bound"` - Zhang and Shen bound score.

- `...`:

  Additional arguments passed to the private score-setting methods. For
  the following scores, the following parameters are available:

  - `"bdeu"` - Bayes Dirichlet Equivalent score with uniform priors.

    - `sample_prior = 10` - This sets the prior equivalent sample size.
      This number is added to the sample size for each conditional
      probability table in the model and is divided equally among the
      cells in the table,

    - `singularity_lambda = 0.0` - Small number \>= 0: Add lambda to the
      diagonal, \< 0 Pseudoinverse.

  - `"basis_function_bic"` - BIC score for basis-function models. This
    is a generalization of the Degenerate Gaussian score.

    - `truncation_limit = 3` - Basis functions 1 though this number will
      be used. The Degenerate Gaussian category indicator variables for
      mixed data are also used,

    - `penalty_discount = 2` - Penalty discount. Higher penalty yields
      sparser graphs,

    - `singularity_lambda = 0.0` - Small number \>= 0: Add lambda to the
      diagonal, \< 0 Pseudoinverse,

    - `do_one_equation_only = FALSE` - If TRUE, only one equation should
      be used when expanding the basis.

  - `"basis_function_blocks_bic"` - BIC score for mixed data using
    basis-function models.

    - `basis_type = "polynomial"` - The type of basis to use. Supported
      types are `"polynomial"`, `"legendre"`, `"hermite"`, and
      `"chebyshev"`,

    - `penalty_discount = 2` - Penalty discount factor used in BIC =
      2L - ck log N, where c is the penalty. Higher c yield sparser
      graphs,

    - `truncation_limit = 3` - Basis functions 1 through this number
      will be used. The Degenerate Gaussian category indicator variables
      for mixed data are also used.

  - `"basis_function_sem_bic"` - SEM BIC score for basis-function
    models.

    - `penalty_discount = 2` - Penalty discount factor used in BIC =
      2L - ck log N, where c is the penalty. Higher c yield sparser
      graphs,

    - `jitter = 1e-8` - Small non-negative constant added to the
      diagonal of covariance/correlation matrices for numerical
      stability,

    - `truncation_limit = 3` - Basis functions 1 through this number
      will be used. The Degenerate Gaussian category indicator variables
      for mixed data are also used.

  - `"conditional_gaussian"` - Mixed discrete/continuous BIC score.

    - `penalty_discount = 1` - Penalty discount. Higher penalty yields
      sparser graphs,

    - `discretize = TRUE` - If TRUE for the conditional Gaussian
      likelihood, when scoring X –\> D where X is continuous and D
      discrete, one should simply discretize X for just those cases. If
      FALSE, the integration will be exact,

    - `num_categories_to_discretize = 3` - In case the exact algorithm
      is not used for discrete children and continuous parents is not
      used, this parameter gives the number of categories to use for
      this second (discretized) backup copy of the continuous variables,

    - `structure_prior = 0` - The default number of parents for any
      conditional probability table. Higher weight is accorded to tables
      with about that number of parents. The prior structure weights are
      distributed according to a binomial distribution.

  - `"degenerate_gaussian"` - Degenerate Gaussian BIC score.

    - `penalty_discount = 1` - Penalty discount. Higher penalty yields
      sparser graphs,

    - `structure_prior = 0` - The default number of parents for any
      conditional probability table. Higher weight is accorded to tables
      with about that number of parents. The prior structure weights are
      distributed according to a binomial distribution,

    - `singularity_lambda = 0.0` - Small number \>= 0: Add lambda to the
      diagonal, \< 0 Pseudoinverse.

  - `"discrete_bic"` - BIC score for discrete data.

    - `penalty_discount = 2` - Penalty discount. Higher penalty yields
      sparser graphs,

    - `structure_prior = 0` - The default number of parents for any
      conditional probability table. Higher weight is accorded to tables
      with about that number of parents. The prior structure weights are
      distributed according to a binomial distribution.

  - `"ebic"` - Extended BIC score.

    - `gamma` - The gamma parameter in the EBIC score.

    - `singularity_lambda = 0.0` - Small number \>= 0: Add lambda to the
      diagonal, \< 0 Pseudoinverse.

  - `"gic"` - Generalized Information Criterion (GIC) score.

    - `penalty_discount = 1` - Penalty discount. Higher penalty yields
      sparser graphs,

    - `sem_gic_rule = "bic"` - The following rules are available:
      `"bic"` - \\\ln n\\, `"gic2"` - \\p n^{1/3}\\, `"ric"` - \\2 \ln(p
      n)\\, `"ricc"` - \\2(\ln(p n) + \ln\ln(p n))\\, `"gic6"` - \\\ln n
      \ln(p n)\\.

    - `singularity_lambda = 0.0` - Small number \>= 0: Add lambda to the
      diagonal, \< 0 Pseudoinverse.

  - `"mag_degenerate_gaussian_bic"` - MAG Degenerate Gaussian BIC Score.

    - `penalty_discount = 1` - Penalty discount. Higher penalty yields
      sparser graphs,

    - `structure_prior = 0` - The default number of parents for any
      conditional probability table. Higher weight is accorded to tables
      with about that number of parents. The prior structure weights are
      distributed according to a binomial distribution,

  - `"poisson_prior"` - Poisson prior score.

    - `poisson_lambda = 1` - Lambda parameter for the Poisson
      distribution (\> 0),

    - `singularity_lambda = 0.0` - Small number \>= 0: Add lambda to the
      diagonal, \< 0 Pseudoinverse.

  - `"sem_bic"` - SEM BIC score.

    - `penalty_discount = 2` - Penalty discount factor used in BIC =
      2L - ck log N, where c is the penalty. Higher c yield sparser
      graphs,

    - `structure_prior = 0` - The default number of parents for any
      conditional probability table. Higher weight is accorded to tables
      with about that number of parents. The prior structure weights are
      distributed according to a binomial distribution,

    - `singularity_lambda = 0.0` - Small number \>= 0: Add lambda to the
      diagonal, \< 0 Pseudoinverse.

  - `"rank_bic"` - Rank-based BIC score.

    - `gamma = 0.8` - Gamma parameter for Extended BIC (Chen and Chen,
      2008). Between 0 and 1,

    - `penalty_discount = 2` - Penalty discount factor used in BIC =
      2L - ck log N, where c is the penalty. Higher c yield sparser
      graphs.

  - `"zhang_shen_bound"` - Zhang and Shen bound score.

    - `risk_bound = 0.2` - This is the probability of getting the true
      model if a correct model is discovered. Could underfit.

    - `singularity_lambda = 0.0` - Small number \>= 0: Add lambda to the
      diagonal, \< 0 Pseudoinverse.

#### Returns

Invisibly returns `self`.

------------------------------------------------------------------------

### `TetradSearch$set_alg()`

Sets the causal discovery algorithm to use in Tetrad.

#### Usage

    TetradSearch$set_alg(method, ...)

#### Arguments

- `method`:

  (character) Name of the algorithm (e.g., "fges", "pc", "fci", etc.).

- `...`:

  Additional parameters passed to the private algorithm-setting methods.
  For the following algorithms, the following parameters are available:

  - `"boss"` - BOSS algorithm.

    - `num_starts = 1` - The number of times the algorithm should be
      started from different initializations. By default, the algorithm
      will be run through at least once using the initialized
      parameters,

    - `use_bes = TRUE` - If TRUE, the algorithm uses the backward
      equivalence search from the GES algorithm as one of its steps,

    - `use_data_order = TRUE` - If TRUE, the data variable order should
      be used for the first initial permutation,

    - `output_cpdag = TRUE` - If TRUE, the DAG output of the algorithm
      is converted to a CPDAG.

  - `"boss_fci"` - BOSS-FCI algorithm.

    - `depth = -1` - Maximum size of conditioning set. Set to -1 for
      unlimited,

    - `max_disc_path_length = -1` - Maximum length for any
      discriminating path. Set to -1 for unlimited,

    - `use_bes = TRUE` - If TRUE, the algorithm uses the backward
      equivalence search from the GES algorithm as one of its steps,

    - `use_heuristic = FALSE` - If TRUE, use the max p heuristic
      version,

    - `complete_rule_set_used = TRUE` - FALSE if the (simpler) final
      orientation rules set due to P. Spirtes, guaranteeing arrow
      completeness, should be used; TRUE if the (fuller) set due to J.
      Zhang, should be used guaranteeing additional tail completeness,

    - `guarantee_pag = FALSE` - Ensure the output is a legal PAG (where
      feasible).

  - `"fci"` - FCI algorithm.

    - `depth = -1` - Maximum size of conditioning set. Set to -1 for
      unlimited,

    - `stable_fas = TRUE` - If TRUE, the "stable" version of the PC
      adjacency search is used, which for k \> 0 fixes the graph for
      depth k + 1 to that of the previous depth k.

    - `max_disc_path_length = -1` - Maximum length for any
      discriminating path. Set to -1 for unlimited,

    - `complete_rule_set_used = TRUE` - FALSE if the (simpler) final
      orientation rules set due to P. Spirtes, guaranteeing arrow
      completeness, should be used; TRUE if the (fuller) set due to J.
      Zhang, should be used guaranteeing additional tail completeness.

    - `guarantee_pag = FALSE` - Ensure the output is a legal PAG (where
      feasible).

  - `"ges" ("fges")` - Fast Greedy Equivalence Search (FGES) algorithm.

    - `symmetric_first_step = FALSE` - If TRUE, scores for both X –\> Y
      and X \<– Y will be calculated and the higher score used.

    - `max_degree = -1` - Maximum degree of any node in the graph. Set
      to -1 for unlimited,

    - `parallelized = FALSE` - If TRUE, the algorithm should be
      parallelized,

    - `faithfulness_assumed = FALSE` - If TRUE, assume that if \\X
      \perp\\\\\\\perp Y\\ (by an independence test) then \\X
      \perp\\\\\\\perp Y\\ \| Z for nonempty Z.

  - `"gfci"` - GFCI algorithm. Combines FGES and FCI.

    - `depth = -1` - Maximum size of conditioning set,

    - `max_degree = -1` - Maximum degree of any node in the graph. Set
      to -1 for unlimited,

    - `max_disc_path_length = -1` - Maximum length for any
      discriminating path. Set to -1 for unlimited,

    - `complete_rule_set_used = TRUE` - FALSE if the (simpler) final
      orientation rules set due to P. Spirtes, guaranteeing arrow
      completeness, should be used; TRUE if the (fuller) set due to J.
      Zhang, should be used guaranteeing additional tail completeness,

    - `guarantee_pag = FALSE` - Ensure the output is a legal PAG (where
      feasible),

    - `use_heuristic = FALSE` - If TRUE, use the max p heuristic.

    - `start_complete = FALSE` - If TRUE, start from a complete graph.

  - `"grasp"` - GRaSP (Greedy Relations of Sparsest Permutation)
    algorithm.

    - `covered_depth = 4` - The depth of recursion for first search,

    - `singular_depth = 1` - Recursion depth for singular tucks,

    - `nonsingular_depth = 1` - Recursion depth for nonsingular tucks,

    - `ordered_alg = FALSE` - If TRUE, earlier GRaSP stages should be
      performed before later stages,

    - `raskutti_uhler = FALSE` - If TRUE, use Raskutti and Uhler's
      DAG-building method (test); if FALSE, use Grow-Shrink (score).

    - `use_data_order = TRUE` - If TRUE, the data variable order should
      be used for the first initial permutation,

    - `num_starts = 1` - The number of times the algorithm should be
      started from different initializations. By default, the algorithm
      will be run through at least once using the initialized
      parameters.

  - `"grasp_fci"` - GRaSP-FCI algorithm. Combines GRaSP and FCI.

    - `depth = -1` - Maximum size of conditioning set. Set to -1 for
      unlimited,

    - `stable_fas = TRUE` - If TRUE, the "stable" version of the PC
      adjacency search is used, which for k \> 0 fixes the graph for
      depth k + 1 to that of the previous depth k.

    - `max_disc_path_length = -1` - Maximum length for any
      discriminating path. Set to -1 for unlimited,

    - `complete_rule_set_used = TRUE` - FALSE if the (simpler) final
      orientation rules set due to P. Spirtes, guaranteeing arrow
      completeness, should be used; TRUE if the (fuller) set due to J.
      Zhang, should be used guaranteeing additional tail completeness,

    - `covered_depth = 4` - The depth of recursion for first search,

    - `singular_depth = 1` - Recursion depth for singular tucks,

    - `nonsingular_depth = 1` - Recursion depth for nonsingular tucks,

    - `ordered_alg = FALSE` - If TRUE, earlier GRaSP stages should be
      performed before later stages,

    - `raskutti_uhler = FALSE` - If TRUE, use Raskutti and Uhler's
      DAG-building method (test); if FALSE, use Grow-Shrink (score).

    - `use_data_order = TRUE` - If TRUE, the data variable order should
      be used for the first initial permutation,

    - `num_starts = 1` - The number of times the algorithm should be
      started from different initializations. By default, the algorithm
      will be run through at least once using the initialized
      parameters,

    - `guarantee_pag = FALSE` - If TRUE, ensure the output is a legal
      PAG (where feasible).

  - `"pc"` - Peter-Clark (PC) algorithm

    - `conflict_rule = 1` - The value of `conflict_rule` determines how
      collider conflicts are handled. `1` corresponds to the "overwrite"
      rule as introduced in the pcalg package, see
      [`pcalg::pc()`](https://rdrr.io/pkg/pcalg/man/pc.html). `2` means
      that all collider conflicts using bidirected edges should be
      prioritized, while `3` means that existing colliders should be
      prioritized, ignoring subsequent conflicting information.

    - `depth = -1` - Maximum size of conditioning set. Set to -1 for
      unlimited,

    - `stable_fas = TRUE` - If TRUE, the "stable" version of the PC
      adjacency search is used, which for k \> 0 fixes the graph for
      depth k + 1 to that of the previous depth k.

    - `guarantee_cpdag = FALSE` - If TRUE, ensure the output is a legal
      CPDAG.

  - `"rfci"` - Restricted FCI algorithm

    - `depth = -1` - Maximum size of conditioning set. Set to -1 for
      unlimited,

    - `stable_fas = TRUE` - If TRUE, the "stable" version of the PC
      adjacency search is used, which for k \> 0 fixes the graph for
      depth k + 1 to that of the previous depth k.

    - `max_disc_path_length = -1` - Maximum length for any
      discriminating path. Set to -1 for unlimited,

    - `complete_rule_set_used = TRUE` - FALSE if the (simpler) final
      orientation rules set due to P. Spirtes, guaranteeing arrow
      completeness, should be used; TRUE if the (fuller) set due to J.
      Zhang, should be used guaranteeing additional tail completeness.

  - `"sp_fci"` - Sparsest Permutation using FCI

    - `depth = -1` - Maximum size of conditioning set. Set to -1 for
      unlimited,

    - `max_disc_path_length = -1` - Maximum length for any
      discriminating path. Set to -1 for unlimited,

    - `complete_rule_set_used = TRUE` - FALSE if the (simpler) final
      orientation rules set due to P. Spirtes, guaranteeing arrow
      completeness, should be used; TRUE if the (fuller) set due to J.
      Zhang, should be used guaranteeing additional tail completeness,

    - `guarantee_pag = FALSE` - Ensure the output is a legal PAG (where
      feasible),

    - `use_heuristic = FALSE` - If TRUE, use the max p heuristic
      version.

#### Returns

Invisibly returns `self`.

------------------------------------------------------------------------

### `TetradSearch$set_knowledge()`

Sets the background `Knowledge` object.

#### Usage

    TetradSearch$set_knowledge(knowledge_obj)

#### Arguments

- `knowledge_obj`:

  An object containing Tetrad knowledge.

------------------------------------------------------------------------

### `TetradSearch$set_params()`

Sets parameters for the Tetrad search.

#### Usage

    TetradSearch$set_params(...)

#### Arguments

- `...`:

  Named arguments for the parameters to set.

------------------------------------------------------------------------

### `TetradSearch$get_parameters_for_function()`

Retrieves the argument names of a matching private function.

#### Usage

    TetradSearch$get_parameters_for_function(
      fn_pattern,
      score = FALSE,
      test = FALSE,
      alg = FALSE
    )

#### Arguments

- `fn_pattern`:

  (character) A pattern that should match a private method name.

- `score`:

  If TRUE, retrieves parameters for a scoring function.

- `test`:

  If TRUE, retrieves parameters for a test function.

- `alg`:

  If TRUE, retrieves parameters for an algorithm.

#### Returns

(character) The names of the parameters.

------------------------------------------------------------------------

### `TetradSearch$run_search()`

Runs the chosen Tetrad algorithm on the data.

#### Usage

    TetradSearch$run_search(
      data = NULL,
      bootstrap = FALSE,
      int_cols_as_cont = TRUE
    )

#### Arguments

- `data`:

  (optional) If provided, overrides the previously set data.

- `bootstrap`:

  (logical) If TRUE, bootstrapped graphs will be generated.

- `int_cols_as_cont`:

  (logical) If `TRUE`, integer columns are treated as continuous, since
  Tetrad does not support ordinal data, but only either continuous or
  nominal data. Default is `TRUE.`

#### Returns

A `Disco` object (a list with a `caugi` and a `Knowledge` object). Also
populates `self$java`.

------------------------------------------------------------------------

### `TetradSearch$set_bootstrapping()`

Configures bootstrapping parameters for the Tetrad search.

#### Usage

    TetradSearch$set_bootstrapping(
      number_resampling = 0,
      percent_resample_size = 100,
      add_original = TRUE,
      with_replacement = TRUE,
      resampling_ensemble = 1,
      seed = -1
    )

#### Arguments

- `number_resampling`:

  (integer) Number of bootstrap samples.

- `percent_resample_size`:

  (numeric) Percentage of sample size for each bootstrap.

- `add_original`:

  (logical) If TRUE, add the original dataset to the bootstrap set.

- `with_replacement`:

  (logical) If TRUE, sampling is done with replacement.

- `resampling_ensemble`:

  (integer) How the resamples are used or aggregated.

- `seed`:

  (integer) Random seed, or -1 for none.

------------------------------------------------------------------------

### `TetradSearch$set_data()`

Sets or overrides the data used by Tetrad.

#### Usage

    TetradSearch$set_data(data, int_cols_as_cont = TRUE)

#### Arguments

- `data`:

  (data.frame) The new data to load.

- `int_cols_as_cont`:

  (logical) If `TRUE`, integer columns are treated as continuous, since
  Tetrad does not support ordinal data, but only either continuous or
  nominal data. Default is `TRUE.`

------------------------------------------------------------------------

### `TetradSearch$set_verbose()`

Toggles the verbosity in Tetrad.

#### Usage

    TetradSearch$set_verbose(verbose)

#### Arguments

- `verbose`:

  (logical) TRUE to enable verbose logging, FALSE otherwise.

------------------------------------------------------------------------

### `TetradSearch$set_time_lag()`

Sets an integer time lag for time-series algorithms.

#### Usage

    TetradSearch$set_time_lag(time_lag = 0)

#### Arguments

- `time_lag`:

  (integer) The time lag to set.

------------------------------------------------------------------------

### `TetradSearch$get_data()`

Retrieves the current Java data object.

#### Usage

    TetradSearch$get_data()

#### Returns

(Java object) Tetrad dataset.

------------------------------------------------------------------------

### `TetradSearch$get_knowledge()`

Returns the background `Knowledge` object.

#### Usage

    TetradSearch$get_knowledge()

#### Returns

(Java object) Tetrad Knowledge.

------------------------------------------------------------------------

### `TetradSearch$get_java()`

Gets the main Java result object (usually a graph) from the last search.

#### Usage

    TetradSearch$get_java()

#### Returns

(Java object) The Tetrad result graph or model.

------------------------------------------------------------------------

### `TetradSearch$get_string()`

Returns the string representation of a given Java object or `self$java`.

#### Usage

    TetradSearch$get_string(java_obj = NULL)

#### Arguments

- `java_obj`:

  (Java object, optional) If NULL, uses `self$java`.

#### Returns

(character) The [`toString()`](https://rdrr.io/r/base/toString.html) of
that Java object.

------------------------------------------------------------------------

### `TetradSearch$get_dot()`

Produces a DOT (Graphviz) representation of the graph.

#### Usage

    TetradSearch$get_dot(java_obj = NULL)

#### Arguments

- `java_obj`:

  (Java object, optional) If NULL, uses `self$java`.

#### Returns

(character) The DOT-format string.

------------------------------------------------------------------------

### `TetradSearch$get_amat()`

Produces an amat representation of the graph.

#### Usage

    TetradSearch$get_amat(java_obj = NULL)

#### Arguments

- `java_obj`:

  (Java object, optional) If NULL, uses `self$java`.

#### Returns

(character) The adjacency matrix.

------------------------------------------------------------------------

### `TetradSearch$clone()`

The objects of this class are cloneable with this method.

#### Usage

    TetradSearch$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
### tetrad_search R6 class examples ###

# Generally, we do not recommend using the R6 classes directly, but rather
# use the disco() or any method function, for example pc(), instead.

# Requires Tetrad to be installed
if (verify_tetrad()$installed && verify_tetrad()$java_ok) {
  data(num_data)

  # Recommended:
  my_pc <- pc(engine = "tetrad", test = "fisher_z")
  my_pc(num_data)

  # or
  disco(data = num_data, method = my_pc)

  # Example with detailed settings:
  my_pc2 <- pc(
    engine = "tetrad",
    test = "sem_bic",
    penalty_discount = 1,
    structure_prior = 1,
    singularity_lambda = 0.1
  )
  disco(data = num_data, method = my_pc2)

  # Using R6 class:
  s <- TetradSearch$new()

  s$set_data(num_data)
  s$set_test(method = "fisher_z", alpha = 0.05)
  s$set_alg("pc")

  g <- s$run_search()

  print(g)
}
#> 
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: UNKNOWN
#> 
#> ── Edges ──
#> 
#>   from  edge  to   
#>   <chr> <chr> <chr>
#> 1 X1    -->   Y    
#> 2 X1    ---   Z    
#> 3 X2    ---   X3   
#> 4 X2    -->   Y    
#> 5 X3    -->   Y    
#> 6 Z     -->   Y    
#> ── Nodes ──
#> 
#>   name 
#>   <chr>
#> 1 X1   
#> 2 X2   
#> 3 X3   
#> 4 Z    
#> 5 Y    
#> ── Knowledge object ────────────────────────────────────────────────────────────
```
