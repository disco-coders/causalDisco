# ──────────────────────────────────────────────────────────────────────────────
# tfci_run()
# ──────────────────────────────────────────────────────────────────────────────

test_that("tfci_run returns disco on example data", {
  set.seed(1405)
  data(tpc_example, package = "causalDisco")

  kn <- build_kn_from_order()

  res <- tfci_run(
    data = tpc_example,
    knowledge = kn,
    alpha = 0.01,
    test = cor_test,
    orientation_method = "conservative"
  )

  expect_s3_class(res, "Disco")
})

test_that("tfci_run works with reg_test as well", {
  set.seed(1405)
  data(tpc_example, package = "causalDisco")
  kn <- build_kn_from_order()
  res <- tfci_run(
    data = tpc_example,
    knowledge = kn,
    alpha = 0.02,
    test = reg_test,
    orientation_method = "standard"
  )

  expect_s3_class(res, "Disco")
})

test_that("tfci_run respects forbidden knowledge (edge is removed)", {
  set.seed(1405)
  data(tpc_example, package = "causalDisco")

  kn <- build_kn_from_order()

  vars <- names(tpc_example)
  x <- vars[1]
  y <- vars[2]

  # x and y are in the same tier, so a single direction is asymmetric
  kn_forb_directed <- kn |> forbid_edge(!!as.name(x) ~ !!as.name(y))
  expect_error(
    tfci_run(
      data = tpc_example,
      knowledge = kn_forb_directed,
      alpha = 0.02,
      test = cor_test
    ),
    "asymmetric edges"
  )

  # forbidding both directions removes the adjacency
  kn_forb <- kn |>
    forbid_edge(!!as.name(x) ~ !!as.name(y)) |>
    forbid_edge(!!as.name(y) ~ !!as.name(x))

  res <- tfci_run(
    data = tpc_example,
    knowledge = kn_forb,
    alpha = 0.02,
    test = cor_test
  )

  expect_s3_class(res, "Disco")
  edges <- res$caugi@edges
  expect_false(
    any(
      (edges$from == x & edges$to == y) | (edges$from == y & edges$to == x)
    )
  )
})

test_that("tfci_run uses provided suff_stat (no data needed) and completes", {
  set.seed(1405)
  my_df <- data.frame(
    p1_A = rnorm(25),
    p2_B = rnorm(25)
  )
  # Build a valid knowledge with both variables known
  kn <- knowledge(
    my_df,
    tier(
      p1 ~ tidyselect::starts_with("p1"),
      p2 ~ tidyselect::starts_with("p2")
    )
  )

  # Provide suff_stat directly to hit the else-branch
  ss <- make_suff_stat(my_df, type = "reg_test")

  out <- tfci_run(
    data = NULL, # no data path
    knowledge = kn,
    alpha = 0.2,
    test = reg_test,
    suff_stat = ss,
    varnames = names(my_df)
  )

  expect_s3_class(out, "Disco")
})


# ──────────────────────────────────────────────────────────────────────────────
# tfci_run() guards and errors
# ──────────────────────────────────────────────────────────────────────────────

test_that("tfci_run input guards fail fast with clear messages", {
  my_df <- data.frame(a = 1:3, b = 1:3)
  kn <- knowledge() |> add_vars(names(my_df))

  expect_error(
    tfci_run(data = NULL, suff_stat = NULL, knowledge = knowledge()),
    "Either data or sufficient statistic must be supplied.",
    fixed = TRUE
  )

  expect_error(
    tfci_run(data = my_df, knowledge = kn, na_method = "oops"),
    "Invalid choice of method for handling NA values.",
    fixed = TRUE
  )

  expect_error(
    tfci_run(data = my_df, knowledge = kn, orientation_method = "funky"),
    "Orientation method must be one of standard, conservative or maj.rule.",
    fixed = TRUE
  )
})

test_that("tfci_run NA handling: error on NAs with na_method = 'none', cc with zero rows", {
  df1 <- data.frame(a = c(1, NA), b = c(2, NA))
  kn1 <- knowledge() |> add_vars(names(df1))

  expect_error(
    tfci_run(data = df1, knowledge = kn1, na_method = "none"),
    "Inputted data contains NA but selected CI test does not support missing data.",
    fixed = TRUE
  )

  df2 <- data.frame(a = c(NA, NA), b = c(NA, NA))
  kn2 <- knowledge() |> add_vars(names(df2))

  expect_error(
    tfci_run(data = df2, knowledge = kn2, na_method = "cc"),
    "Complete case analysis resulted in empty dataset.",
    fixed = TRUE
  )
})

test_that("tfci_run errors when varnames are unknown with suff_stat-only usage", {
  suff <- list(dummy = TRUE)
  expect_error(
    tfci_run(
      data = NULL,
      suff_stat = suff,
      knowledge = knowledge(),
      varnames = NULL
    ),
    "Cannot infer variable names from suff_stat list.",
    fixed = TRUE
  )
})

test_that("tfci_run demands suff_stat for non-builtin test functions", {
  set.seed(1405)
  my_df <- data.frame(a = rnorm(10), b = rnorm(10))
  kn <- knowledge() |> add_vars(names(my_df))
  strange_test <- function(x, y, S, suff_stat) 0

  expect_error(
    tfci_run(data = my_df, knowledge = kn, test = strange_test),
    "suff_stat needs to be supplied when using a non-builtin test.",
    fixed = TRUE
  )
})

test_that("tfci_run() adds missing vars to knowledge via add_vars() and fails for bad variables", {
  # Provide knowledge missing one variable ("oldage_z")
  kn0 <- knowledge() |> add_vars(c("child_x1", "youth_x3"))

  res <- tfci_run(
    data = tpc_example,
    knowledge = kn0, # <- triggers the missing_vars path
    alpha = 0.2,
    test = reg_test
  )
  expect_s3_class(res, "Disco")
  kn_bad <- knowledge() |> add_vars(c("child_a"))
  expect_error(
    tfci_run(
      data = tpc_example,
      knowledge = kn_bad,
      alpha = 0.2,
      test = reg_test
    ),
    "Knowledge contains variables not present in `data`: child_a",
    fixed = TRUE
  )
})
