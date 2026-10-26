test_that("boss_fci Tetrad algorithm run without error and return correct classes", {
  skip_if_no_tetrad()

  test_that("grasp with raskutti uhler works correctly.", {
    skip(
      "grasp Tetrad with raskutti uhler doesn't respect tier knowledge. See #1954 in Tetrad."
    )
    test_tier_knowledge(
      alg_fun = grasp,
      engine = "tetrad",
      score = "sem_bic",
      test = "fisher_z",
      alg_args = list(
        covered_depth = 3,
        singular_depth = 2,
        ordered_alg = TRUE,
        raskutti_uhler = TRUE,
        use_data_order = FALSE,
        num_starts = 3
      )
    )
  })

  run_all_tests(
    alg_fun = grasp,
    engine = "tetrad",
    score = "rank_bic",
    test = "poisson_prior",
    alg_args = list(
      covered_depth = 3,
      singular_depth = 2,
      ordered_alg = TRUE,
      raskutti_uhler = FALSE,
      use_data_order = FALSE,
      num_starts = 3,
      use_score = FALSE,
      allow_internal_randomness = FALSE,
      output_cpdag = TRUE,
      seed = 42
    ),
    test_args = list(
      poisson_lambda = 2,
      singularity_lambda = 0.1,
      gamma = 0.5,
      penalty_discount = 3
    )
  )
})

test_that("grasp Tetrad is reproducible without internal randomness", {
  skip_if_no_tetrad()
  data(tpc_example)

  fit <- function() {
    method <- grasp(
      engine = "tetrad",
      score = "sem_bic",
      test = "fisher_z",
      allow_internal_randomness = FALSE
    )
    disco(tpc_example, method)$caugi@edges
  }
  first <- fit()
  for (i in 1:5) {
    expect_identical(fit(), first)
  }
})
