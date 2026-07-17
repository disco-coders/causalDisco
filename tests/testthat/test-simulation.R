test_that("sim_data errors", {
  cg <- caugi::caugi(A %-->% B, B %-->% C, A %-->% C, class = "PDAG")
  expect_error(
    sim_data(cg, n = 100),
    "`simulate_data` currently only supports DAGs. Graph class is: PDAG"
  )

  cg_empty <- caugi::caugi(class = "DAG")
  expect_error(
    sim_data(cg_empty, n = 100),
    "Cannot simulate data from an empty graph"
  )
})

test_that("sim_data works", {
  cg <- caugi::caugi(A %-->% B, B %-->% C, A %-->% C, class = "DAG")
  sim_data <- sim_data(cg, n = 100)
  expect_equal(nrow(sim_data), 100)
  expect_equal(ncol(sim_data), 3)

  sim_data_seed <- sim_data(cg, n = 100, seed = 1405)
  expect_equal(sim_data_seed, sim_data(cg, n = 100, seed = 1405))

  sim_data_custom <- sim_data(
    cg,
    n = 100,
    C = A^2 + B + rnorm(100, sd = 0.7)
  )
  expect_equal(nrow(sim_data_custom), 100)
  expect_equal(ncol(sim_data_custom), 3)
  expect_equal(
    deparse(attr(sim_data_custom, "generating_model")$dgp$C),
    "A^2 + B + rnorm(100, sd = 0.7)"
  )
})

test_that("sim_dag errors", {
  expect_error(
    sim_dag(n = 5, m = 3, p = 0.2),
    "Exactly one of 'm' or 'p' must be supplied."
  )
  expect_error(
    sim_dag(n = 4.5, m = 3)
  )
  expect_error(
    sim_dag(n = 5, m = 100)
  )
  expect_error(
    sim_dag(n = 5, p = 1.1)
  )
})

test_that("sim_dag works", {
  out <- sim_dag(n = 5, m = 4)
  expect_true(inherits(out, "caugi::caugi"))
})
