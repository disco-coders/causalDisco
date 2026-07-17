test_that("bnlearn test argument works (discrete)", {
  data(cat_data)
  run_pc_test <- function(data, test) {
    pc_method <- pc(engine = "bnlearn", test = test, alpha = 0.05)
    pc_result <- disco(data, method = pc_method)
    expect_equal(class(pc_result), "Disco")
    pc_result
  }

  tests <- c(
    "mi",
    "mi-adf",
    "mc-mi",
    "smc-mi",
    "sp-mi",
    "mi-sh",
    "x2",
    "x2-adf",
    "mc-x2",
    "smc-x2",
    "sp-x2"
  )
  lapply(tests, function(t) suppressWarnings(run_pc_test(cat_data, t))) # bnlearn can give harmless warnings

  # Discrete - ordered factors
  data(cat_ord_data)

  tests_ord <- c("jt", "mc-jt", "smc-jt")

  lapply(tests_ord, function(t) suppressWarnings(run_pc_test(cat_ord_data, t))) # bnlearn can give harmless warnings
})

test_that("bnlearn test argument works (continuous)", {
  data(num_data)
  run_pc_test <- function(data, test) {
    pc_method <- pc(engine = "bnlearn", test = test, alpha = 0.05, B = 100)
    pc_result <- disco(data, method = pc_method)
    expect_equal(class(pc_result), "Disco")
    pc_result
  }

  tests <- c(
    "cor",
    "mc-cor",
    "smc-cor",
    "fisher_z",
    "mc-zf",
    "smc-zf",
    "mi-g",
    "mc-mi-g",
    "smc-mi-g",
    "mi-g-sh"
  )

  lapply(tests, function(t) suppressWarnings(run_pc_test(num_data, t)))
})

test_that("bnlearn test argument works (mixed)", {
  data(mix_data)
  run_pc_test <- function(data, test) {
    pc_method <- pc(engine = "bnlearn", test = test, alpha = 0.05)
    pc_result <- disco(data, method = pc_method)
    expect_equal(class(pc_result), "Disco")
    pc_result
  }

  tests <- c(
    "mi_cg",
    "conditional_gaussian"
  )

  lapply(tests, function(t) suppressWarnings(run_pc_test(mix_data, t)))
})


test_that("bnlearn score argument works", {
  skip("Currently no bnlearn score algorithms are implemented")
})
