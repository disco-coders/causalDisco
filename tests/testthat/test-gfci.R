test_that("gfci Tetrad algorithm run without error and return correct classes", {
  skip_if_no_tetrad()

  test_tier_knowledge(
    alg_fun = gfci,
    engine = "tetrad",
    score = "sem_bic",
    test = "fisher_z"
  )

  test_forbidden_knowledge(
    alg_fun = gfci,
    engine = "tetrad",
    score = "sem_bic",
    test = "fisher_z"
  )

  test_that("required works", {
    skip(
      "gfci Tetrad does not yet support required background knowledge correctly."
    )
    test_required_knowledge(
      alg_fun = gfci,
      engine = "tetrad",
      score = "sem_bic",
      test = "fisher_z"
    )
  })

  test_additional_alg_args(
    alg_fun = gfci,
    engine = "tetrad",
    score = "poisson_prior",
    test = "rank_independence",
    alg_args = list(
      depth = 3,
      max_degree = 2,
      max_disc_path_length = 5,
      use_heuristic = FALSE,
      complete_rule_set_used = FALSE,
      guarantee_pag = TRUE,
      start_complete = TRUE,
      num_threads = 2,
      exclude_selection_bias = TRUE,
      verbose = TRUE
    )
  )

  test_additional_test_or_score_args(
    alg_fun = gfci,
    engine = "tetrad",
    score = "poisson_prior",
    test = "basis_function_blocks",
    test_args = list(
      poisson_lambda = 2,
      singularity_lambda = 0.1,
      basis_type = "legendre",
      truncation_limit = 2
    )
  )
})
