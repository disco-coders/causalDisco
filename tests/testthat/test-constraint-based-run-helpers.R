test_that("Various errors", {
  data(num_data)

  my_tpc <- tpc(test = "fisher_z_mi")
  expect_error(
    disco(num_data, my_tpc),
    "fisher_z_mi requires a mids object.",
    fixed = TRUE
  )

  expect_error(
    constraint_based_prepare_inputs(
      data = num_data,
      knowledge = NULL,
      varnames = NULL,
      na_method = "none",
      test = structure(list(), missing_mode = "mi"),
      suff_stat = NULL,
      function_name = "test_function"
    ),
    "Selected CI test requires a 'mids' object (multiple imputation data).",
    fixed = TRUE
  )

  expect_error(
    constraint_based_prepare_inputs(
      data = NULL,
      knowledge = NULL,
      varnames = NULL,
      na_method = "none",
      test = structure(list(), missing_mode = "none"),
      suff_stat = NULL,
      function_name = "test_function"
    ),
    "Either data or sufficient statistic must be supplied.",
    fixed = TRUE
  )

  expect_error(
    constraint_based_prepare_inputs(
      data = NULL,
      knowledge = NULL,
      varnames = NULL,
      na_method = "none",
      test = structure(list(), missing_mode = "none"),
      suff_stat = 1,
      function_name = "test_function"
    ),
    "Unknown suff_stat format; cannot infer variable names.",
    fixed = TRUE
  )
})

test_that("tpc reg_test() and cor_test works with twd", {
  data(tpc_example)
  tpc_example_miss <- tpc_example
  tpc_example_miss[1, 1] <- NA
  tpc_cd <- tpc(engine = "causalDisco", "reg", na_method = "twd")
  res <- disco(tpc_example_miss, tpc_cd)
  expect_true(inherits(res, "Disco"))

  tpc_cd <- tpc(engine = "causalDisco", "fisher_z", na_method = "twd")
  res <- disco(tpc_example_miss, tpc_cd)
  expect_true(inherits(res, "Disco"))
})
