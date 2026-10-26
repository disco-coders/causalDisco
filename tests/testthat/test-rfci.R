test_that("rfci Tetrad algorithm run without error and return correct classes", {
  skip_if_no_tetrad()

  test_tier_knowledge(
    alg_fun = rfci,
    engine = "tetrad",
    test = "fisher_z"
  )

  test_forbidden_knowledge(
    alg_fun = rfci,
    engine = "tetrad",
    test = "fisher_z"
  )

  test_that("required works", {
    skip("rfci Tetrad runs forever with required. See #1950 in Tetrad.")
    test_required_knowledge(
      alg_fun = rfci,
      engine = "tetrad",
      test = "fisher_z"
    )
  })

  test_additional_alg_args(
    alg_fun = rfci,
    engine = "tetrad",
    test = "fisher_z",
    alg_args = list(
      depth = 3,
      max_disc_path_length = 2,
      exclude_selection_bias = TRUE,
      fdr_q = 0.05
    )
  )

  test_additional_test_or_score_args(
    alg_fun = rfci,
    engine = "tetrad",
    test = "fisher_z",
    test_args = list(singularity_lambda = 0.1)
  )
})

test_that("rfci pcalg algorithm run without error and return correct classes", {
  test_additional_alg_args(
    alg_fun = rfci,
    engine = "pcalg",
    test = "fisher_z",
    alg_args = list(
      skel.method = "original",
      fixedGaps = NULL,
      fixedEdges = NULL,
      NAdelete = FALSE,
      m.max = 10,
      rules = c(rep(TRUE, 9), FALSE),
      conservative = TRUE,
      maj.rule = FALSE,
      numCores = 1,
      verbose = FALSE
    )
  )
})
