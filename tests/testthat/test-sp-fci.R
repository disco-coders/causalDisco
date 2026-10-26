test_that("sp_fci Tetrad algorithm run without error and return correct classes", {
  skip_if_no_tetrad()

  test_tier_knowledge(
    alg_fun = sp_fci,
    engine = "tetrad",
    score = "sem_bic",
    test = "fisher_z"
  )

  test_forbidden_knowledge(
    alg_fun = sp_fci,
    engine = "tetrad",
    score = "sem_bic",
    test = "fisher_z"
  )

  test_that("required works", {
    skip(
      "sp_fci Tetrad does not yet support required background knowledge correctly."
    )
    test_required_knowledge(
      alg_fun = sp_fci,
      engine = "tetrad",
      score = "sem_bic",
      test = "fisher_z"
    )
  })

  test_additional_alg_args(
    alg_fun = sp_fci,
    engine = "tetrad",
    score = "poisson_prior",
    test = "rank_independence",
    alg_args = list(
      max_disc_path_length = 5,
      use_heuristic = FALSE,
      complete_rule_set_used = FALSE,
      guarantee_pag = TRUE,
      exclude_selection_bias = TRUE,
      verbose = FALSE
    )
  )

  test_additional_test_or_score_args(
    alg_fun = sp_fci,
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
