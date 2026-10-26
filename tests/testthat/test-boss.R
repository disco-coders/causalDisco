test_that("boss Tetrad algorithm run without error and return correct classes", {
  skip_if_no_tetrad()

  test_tier_knowledge(
    alg_fun = boss,
    engine = "tetrad",
    score = "sem_bic"
  )

  test_forbidden_knowledge(
    alg_fun = boss,
    engine = "tetrad",
    score = "sem_bic"
  )

  test_that("required works", {
    skip("boss Tetrad runs forever with required. See #1950 in Tetrad.")
    test_required_knowledge(
      alg_fun = boss,
      engine = "tetrad",
      score = "sem_bic"
    )
  })

  test_additional_alg_args(
    alg_fun = boss,
    engine = "tetrad",
    score = "sem_bic",
    alg_args = list(
      num_starts = 3,
      use_bes = FALSE,
      use_data_order = FALSE,
      output_cpdag = FALSE,
      num_threads = 2,
      seed = 1405
    )
  )

  test_additional_test_or_score_args(
    alg_fun = boss,
    engine = "tetrad",
    score = "poisson_prior",
    test_args = list(poisson_lambda = 2, singularity_lambda = 0.1)
  )
})
