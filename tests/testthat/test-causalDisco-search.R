# ──────────────────────────────────────────────────────────────────────────────
# Scores
# ──────────────────────────────────────────────────────────────────────────────

test_that("set_score builds temporal scores lazily and errors on unknown", {
  s_bad <- CausalDiscoSearch$new()
  expect_error(
    s_bad$set_score("not-a-score"),
    "Unknown score type using causalDisco engine: not-a-score",
    fixed = TRUE
  )

  df_g <- matrix(rnorm(100), ncol = 4) |> as.data.frame()
  colnames(df_g) <- paste0("p1_X", 1:4)

  s_bic <- CausalDiscoSearch$new()
  s_bic$set_data(df_g, set_suff_stat = FALSE)
  s_bic$set_score("tbic")
  sc_bic <- s_bic$.__enclos_env__$private$score_function()
  expect_true(methods::is(sc_bic, "TemporalBIC"))

  df_d <- data.frame(
    A = factor(sample(letters[1:3], 100, TRUE)),
    B = factor(sample(letters[1:2], 100, TRUE))
  )
  s_bdeu <- CausalDiscoSearch$new()
  s_bdeu$set_data(df_d, set_suff_stat = FALSE)
  s_bdeu$set_score("tbdeu")
  sc_bdeu <- s_bdeu$.__enclos_env__$private$score_function()
  expect_true(methods::is(sc_bdeu, "TemporalBDeu"))

  s_err <- CausalDiscoSearch$new()
  s_err$set_score("tbic")
  expect_error(
    s_err$.__enclos_env__$private$score_function(),
    "Data must be set before score.",
    fixed = TRUE
  )
})

test_that("set_score internal unsupported method branch errors", {
  s <- CausalDiscoSearch$new()
  s$set_data(data.frame(X = rnorm(100)), set_suff_stat = FALSE)
  s$set_score("tbic")
  s$.__enclos_env__$private$score_method <- "unknown-internal"
  expect_error(
    s$.__enclos_env__$private$score_function(),
    "Internal: unsupported score method.",
    fixed = TRUE
  )
})

# ──────────────────────────────────────────────────────────────────────────────
# Tests
# ──────────────────────────────────────────────────────────────────────────────

test_that("set_test unknown method errors", {
  s <- CausalDiscoSearch$new()
  expect_error(
    s$set_test("not-a-test"),
    "Unknown method: not-a-test",
    fixed = TRUE
  )
})

# ──────────────────────────────────────────────────────────────────────────────
# Initialization
# ──────────────────────────────────────────────────────────────────────────────

test_that("initialize sets sensible defaults", {
  s <- CausalDiscoSearch$new()
  expect_null(s$data)
  expect_null(s$score)
  expect_null(s$test)
  expect_null(s$knowledge)
  expect_type(s$params, "list")
  expect_identical(s$params$na_method, "none")
  expect_null(s$suff_stat)
  expect_null(s$alg)
  expect_null(s$continuous)
})

# ──────────────────────────────────────────────────────────────────────────────
# Sufficient Statistics
# ──────────────────────────────────────────────────────────────────────────────

test_that("set_suff_stat covers reg, cor and bad-type paths", {
  s <- CausalDiscoSearch$new()
  my_df <- data.frame(X = rnorm(100), Y = rnorm(100))

  s$set_test("reg", alpha = 0.01)
  s$set_data(my_df, set_suff_stat = TRUE)
  expect_true(is.list(s$suff_stat))

  s$set_test("fisher_z", alpha = 0.01)
  s$set_data(my_df, set_suff_stat = FALSE)
  expect_silent(s$set_suff_stat())
  expect_named(s$suff_stat, c("C", "n"))

  expect_error(
    s$set_test("bad"),
    "Unknown method: bad",
    fixed = TRUE
  )
})

test_that("set_data triggers set_suff_stat when requested", {
  s <- CausalDiscoSearch$new()
  my_df <- matrix(rnorm(100), ncol = 2) |> as.data.frame()
  colnames(my_df) <- c("X", "Y")
  s$set_test("fisher_z")
  expect_silent(s$set_data(my_df, set_suff_stat = TRUE))
  expect_named(s$suff_stat, c("C", "n"))
})

# ──────────────────────────────────────────────────────────────────────────────
# Other setters
# ──────────────────────────────────────────────────────────────────────────────

test_that("set_params stores values and respects reserved keys", {
  s <- CausalDiscoSearch$new()

  s$set_params(list(alpha = 0.05, method = "stable.fast"))
  expect_identical(s$params$alpha, 0.05)
  expect_identical(s$params$method, "stable.fast")

  expect_error(
    s$set_params(list(data = iris)),
    "reserved and cannot be set via set_params",
    fixed = TRUE
  )
})

test_that("set_params(NULL) is a no-op and returns invisibly", {
  s <- CausalDiscoSearch$new()
  before <- s$params
  expect_invisible(s$set_params(NULL))
  expect_identical(s$params, before)
})

test_that("set_data stores data; can skip suff stat", {
  s <- CausalDiscoSearch$new()

  my_df <- matrix(rnorm(100), ncol = 4) |> as.data.frame()
  colnames(my_df) <- c("X", "Y", "Z", "W")

  s$set_data(my_df, set_suff_stat = FALSE)
  expect_identical(s$data, my_df)
  expect_null(s$suff_stat)
})

test_that("set_knowledge assigns to self$knowledge and validates", {
  s <- CausalDiscoSearch$new()

  expect_error(
    s$set_knowledge(knowledge_obj = 123),
    class = "simpleError"
  )

  my_df <- data.frame(a = rnorm(100), b = rnorm(100), c = rnorm(100))
  kn <- knowledge(
    my_df,
    tier(
      early ~ tidyselect::starts_with("a"),
      late ~ tidyselect::starts_with("b")
    )
  )
  expect_silent(s$set_knowledge(kn))
  expect_identical(s$knowledge, kn)
})

# ──────────────────────────────────────────────────────────────────────────────
# Alg
# ──────────────────────────────────────────────────────────────────────────────

test_that("set_alg builds callables and guards correctly", {
  s <- CausalDiscoSearch$new()

  expect_error(
    s$set_alg("tpc"),
    "No test is set. Use set_test() first.",
    fixed = TRUE
  )
  expect_error(
    s$set_alg("tfci"),
    "No test is set. Use set_test() first.",
    fixed = TRUE
  )

  s$set_test("fisher_z")
  s$set_alg("tpc")
  expect_true(is.function(s$alg))

  s$set_alg("tfci")
  expect_true(is.function(s$alg))

  s2 <- CausalDiscoSearch$new()
  s2$set_alg("tges")
  expect_true(is.function(s2$alg))

  expect_error(
    s$set_alg("nope"),
    "Unknown method type using causalDisco engine: nope",
    fixed = TRUE
  )
})

test_that("set_alg builds tpc/tfci callables and unknown errors", {
  s <- CausalDiscoSearch$new()
  s$set_test("fisher_z")
  s$set_alg("tpc")
  expect_true(is.function(s$alg))

  s$set_alg("tfci")
  expect_true(is.function(s$alg))

  expect_error(
    s$set_alg("nope"),
    "Unknown method type using causalDisco engine: nope",
    fixed = TRUE
  )
})

# ──────────────────────────────────────────────────────────────────────────────
# run_search
# ──────────────────────────────────────────────────────────────────────────────

test_that("run_search errors are thrown in the right order", {
  s <- CausalDiscoSearch$new()

  expect_error(
    s$run_search(),
    "No data is set. Use set_data() first or pass data to run_search().",
    fixed = TRUE
  )

  my_df <- matrix(rnorm(100), ncol = 4) |> as.data.frame()
  colnames(my_df) <- c("X", "Y", "Z", "W")

  s$set_test("fisher_z")
  s$set_data(my_df, set_suff_stat = FALSE)

  expect_error(
    s$run_search(),
    "No algorithm is set. Use set_alg() first.",
    fixed = TRUE
  )

  s$set_alg("tpc")
  expect_error(
    s$run_search(),
    "No sufficient statistic is set. Use set_data() first.",
    fixed = TRUE
  )
})

test_that("run_search returns disco for tpc success path", {
  set.seed(1405)
  my_df <- data.frame(
    p1_x = rnorm(100),
    p1_y = rnorm(100),
    p2_z = rnorm(100)
  )
  kn <- knowledge(
    my_df,
    tier(
      p1 ~ tidyselect::starts_with("p1"),
      p2 ~ tidyselect::starts_with("p2")
    )
  )
  s <- CausalDiscoSearch$new()
  s$set_test("fisher_z")
  s$set_knowledge(kn)
  s$set_alg("tpc")
  s$set_data(my_df, set_suff_stat = TRUE)
  res <- s$run_search()
  expect_s3_class(res, "Disco")
})

test_that("tpc and tfci run end-to-end and return disco", {
  set.seed(1405)
  my_df <- data.frame(
    child_x = rnorm(100),
    child_y = rnorm(100),
    adult_x = rnorm(100),
    adult_y = rnorm(100)
  )

  kn <- knowledge(
    my_df,
    tier(
      child ~ tidyselect::starts_with("child"),
      adult ~ tidyselect::starts_with("adult")
    )
  )

  s_tpc <- CausalDiscoSearch$new()
  s_tpc$set_params(list(method = "stable.fast", na_method = "none"))
  s_tpc$set_test("fisher_z")
  s_tpc$set_knowledge(kn)
  s_tpc$set_alg("tpc")
  s_tpc$set_data(my_df, set_suff_stat = TRUE)
  res_tpc <- s_tpc$run_search()
  expect_s3_class(res_tpc, "Disco")

  s_tfci <- CausalDiscoSearch$new()
  s_tfci$set_params(list(method = "stable.fast", na_method = "none"))
  s_tfci$set_test("fisher_z")
  s_tfci$set_knowledge(kn)
  s_tfci$set_alg("tfci")
  s_tfci$set_data(my_df, set_suff_stat = TRUE)
  res_tfci <- s_tfci$run_search()
  expect_s3_class(res_tfci, "Disco")
})

test_that("tges runs with TemporalBIC (Gaussian) and TemporalBDeu (categorical)", {
  set.seed(1405)
  gdf <- matrix(rnorm(100), ncol = 4) |> as.data.frame()
  colnames(gdf) <- c("p1_A", "p1_B", "p2_C", "p2_D")

  kn_g <- knowledge(
    gdf,
    tier(
      p1 ~ tidyselect::starts_with("p1"),
      p2 ~ tidyselect::starts_with("p2")
    )
  )

  s_g <- CausalDiscoSearch$new()
  s_g$set_data(gdf, set_suff_stat = FALSE)
  s_g$set_knowledge(kn_g)
  s_g$set_score("tbic")
  s_g$set_alg("tges")
  out_g <- s_g$run_search()
  expect_s3_class(out_g, "Disco")

  set.seed(1405)
  dfc <- data.frame(
    a = factor(sample(letters[1:3], 300, TRUE)),
    b = factor(sample(letters[1:2], 300, TRUE)),
    c = factor(sample(letters[1:2], 300, TRUE))
  )
  colnames(dfc) <- c("t1_a", "t1_b", "t2_c")

  kn_c <- knowledge(
    dfc,
    tier(
      t1 ~ tidyselect::starts_with("t1"),
      t2 ~ tidyselect::starts_with("t2")
    )
  )

  s_c <- CausalDiscoSearch$new()
  s_c$set_data(dfc, set_suff_stat = FALSE)
  s_c$set_knowledge(kn_c)
  s_c$set_score("tbdeu")
  s_c$set_alg("tges")
  out_c <- s_c$run_search()
  expect_s3_class(out_c, "Disco")
})

test_that("verbose is accepted via set_params and passed to tges", {
  gdf <- matrix(rnorm(100), ncol = 4) |> as.data.frame()
  colnames(gdf) <- paste0("p1_X", 1:4)

  kn <- knowledge(
    gdf,
    tier(
      p1 ~ tidyselect::starts_with("p1")
    )
  )

  s <- CausalDiscoSearch$new()
  s$set_params(list(verbose = TRUE))
  s$set_data(gdf, set_suff_stat = FALSE)
  s$set_knowledge(kn)
  s$set_score("tbic")
  s$set_alg("tges")
  expect_s3_class(s$run_search(), "Disco")
})

test_that("run_search errors when suff_stat missing for constraint-based algs", {
  s <- CausalDiscoSearch$new()
  my_df <- matrix(rnorm(100), ncol = 4) |> as.data.frame()
  colnames(my_df) <- c("X", "Y", "Z", "W")
  s$set_test("fisher_z")
  s$set_data(my_df, set_suff_stat = FALSE)
  s$set_alg("tpc")
  expect_error(
    s$run_search(),
    "No sufficient statistic is set. Use set_data() first.",
    fixed = TRUE
  )
})

test_that("run_search tges errors without score and covers knowledge-NULL branch", {
  s_err <- CausalDiscoSearch$new()
  gdf <- matrix(rnorm(100), ncol = 4) |> as.data.frame()
  colnames(gdf) <- paste0("X", 1:4)
  s_err$set_data(gdf, set_suff_stat = FALSE)
  s_err$set_alg("tges")
  expect_error(
    s_err$run_search(),
    "No score is set. Use set_score() first.",
    fixed = TRUE
  )

  s_ok <- CausalDiscoSearch$new()
  s_ok$set_data(gdf, set_suff_stat = FALSE)
  s_ok$set_score("tbic")
  s_ok$set_alg("tges")
  out <- s_ok$run_search()
  expect_s3_class(out, "Disco")
})

test_that("run_search(data=...) takes constraint-based path and computes suff_stat", {
  my_df <- data.frame(
    p1_x = rnorm(100),
    p1_y = rnorm(100),
    p2_z = rnorm(100)
  )
  kn <- knowledge(
    my_df,
    tier(
      p1 ~ tidyselect::starts_with("p1"),
      p2 ~ tidyselect::starts_with("p2")
    )
  )

  s <- CausalDiscoSearch$new()
  s$set_test("fisher_z")
  s$set_knowledge(kn)
  s$set_alg("tpc")

  out <- s$run_search(data = my_df, set_suff_stat = TRUE)

  expect_false(is.null(s$suff_stat))
  expect_named(s$suff_stat, c("C", "n"))
  expect_s3_class(out, "Disco")
})

test_that("run_search(data=...) takes score-based path and skips suff_stat", {
  my_df <- matrix(rnorm(100), ncol = 4) |> as.data.frame()
  colnames(my_df) <- paste0("X", 1:4)

  s <- CausalDiscoSearch$new()
  s$set_score("tbic")
  s$set_alg("tges")

  out <- s$run_search(data = my_df, set_suff_stat = TRUE)

  expect_null(s$suff_stat)
  expect_s3_class(out, "Disco")
})

# ──────────────────────────────────────────────────────────────────────────────
# Custom (user-defined) algorithms
# ──────────────────────────────────────────────────────────────────────────────

test_that("set_alg accepts a custom constraint-based algorithm", {
  my_df <- data.frame(
    p1_x = rnorm(100),
    p1_y = rnorm(100),
    p2_z = rnorm(100)
  )
  kn <- knowledge(
    my_df,
    tier(
      p1 ~ tidyselect::starts_with("p1"),
      p2 ~ tidyselect::starts_with("p2")
    )
  )

  my_alg <- function(data, knowledge, suff_stat) {
    tpc_run(
      data = data,
      knowledge = knowledge,
      suff_stat = suff_stat,
      test = reg_test
    )
  }

  s <- CausalDiscoSearch$new()
  s$set_test("reg")
  s$set_knowledge(kn)
  s$set_alg(my_alg)
  s$set_data(my_df, set_suff_stat = TRUE)

  out <- s$run_search()
  expect_s3_class(out, "Disco")
})

test_that("set_alg accepts a custom score-based algorithm", {
  gdf <- matrix(rnorm(100), ncol = 4) |> as.data.frame()
  colnames(gdf) <- paste0("p1_X", 1:4)
  kn <- knowledge(gdf, tier(p1 ~ tidyselect::starts_with("p1")))

  my_alg <- function(score) {
    tges_run(score = score)
  }

  s <- CausalDiscoSearch$new()
  s$set_data(gdf, set_suff_stat = FALSE)
  s$set_knowledge(kn)
  s$set_score("tbic")
  s$set_alg(my_alg, type = "score")

  out <- s$run_search()
  expect_s3_class(out, "Disco")
})

test_that("set_alg forwards args to a custom algorithm", {
  my_df <- data.frame(
    p1_x = rnorm(100),
    p1_y = rnorm(100),
    p2_z = rnorm(100)
  )
  kn <- knowledge(
    my_df,
    tier(
      p1 ~ tidyselect::starts_with("p1"),
      p2 ~ tidyselect::starts_with("p2")
    )
  )

  seen_alpha <- NULL
  my_alg <- function(data, knowledge, suff_stat, args) {
    seen_alpha <<- args$alpha
    tpc_run(
      data = data,
      knowledge = knowledge,
      suff_stat = suff_stat,
      test = reg_test,
      alpha = args$alpha
    )
  }

  s <- CausalDiscoSearch$new()
  s$set_test("reg")
  s$set_knowledge(kn)
  s$set_alg(my_alg, args = list(alpha = 0.2))
  s$set_data(my_df, set_suff_stat = TRUE)

  out <- s$run_search()
  expect_identical(seen_alpha, 0.2)
  expect_s3_class(out, "Disco")
})
