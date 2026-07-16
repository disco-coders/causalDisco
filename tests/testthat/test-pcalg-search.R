# ──────────────────────────────────────────────────────────────────────────────
# PcalgSearch
# ──────────────────────────────────────────────────────────────────────────────

# ──────────────────────────────────────────────────────────────────────────────
# Initialize
# ──────────────────────────────────────────────────────────────────────────────

test_that("initialize sets clean defaults", {
  s <- PcalgSearch$new()
  expect_null(s$data)
  expect_null(s$score)
  expect_null(s$test)
  expect_null(s$knowledge)
  expect_equal(s$params, list())
  expect_null(s$suff_stat)
  expect_null(s$alg)
  expect_null(s$continuous)
})

# ──────────────────────────────────────────────────────────────────────────────
# set_params, set_data, set_suff_stat
# ──────────────────────────────────────────────────────────────────────────────

test_that("set_params and set_data store values; set_data can skip suff stat", {
  s <- PcalgSearch$new()
  s$set_params(list(alpha = 0.05, m.max = 2L))
  expect_identical(s$params, list(alpha = 0.05, m.max = 2L))

  my_df <- matrix(rnorm(12), ncol = 3) |> as.data.frame()
  colnames(my_df) <- c("X", "Y", "Z")

  # skipping suff stat path
  s$set_data(my_df, set_suff_stat = FALSE)
  expect_identical(s$data, my_df)
  expect_null(s$suff_stat)
})

test_that("set_suff_stat guards and branches", {
  s <- PcalgSearch$new()

  # error: no data
  expect_error(
    s$set_suff_stat(),
    "Data must be set before sufficient statistic.",
    fixed = TRUE
  )

  # error: no test
  s$data <- data.frame(X = rnorm(5), Y = rnorm(5))
  expect_error(
    s$set_suff_stat(),
    "Test must be set before sufficient statistic.",
    fixed = TRUE
  )

  # continuous with good data via getter
  s <- PcalgSearch$new()
  s$set_test("fisher_z")
  s$data <- data.frame(X = rnorm(10), Y = rnorm(10))
  expect_silent(s$set_suff_stat())
  expect_true(is.list(s$suff_stat))
  expect_named(s$suff_stat, c("C", "n"))

  # discrete via getter, expects dm + nlev + adaptDF
  s <- PcalgSearch$new()
  s$set_test("g_square")
  s$data <- data.frame(
    A = factor(sample(letters[1:2], 10, TRUE)),
    B = factor(sample(letters[1:2], 10, TRUE))
  )
  expect_silent(s$set_suff_stat())
  expect_named(s$suff_stat, c("dm", "nlev", "adaptDF"))
})

test_that("set_suff_stat works on matrix input for g_square", {
  s <- PcalgSearch$new()
  s$set_test("g_square")
  m <- matrix(sample(0:1, 20, TRUE), ncol = 2)
  colnames(m) <- c("A", "B")
  expect_silent(s$set_data(m, set_suff_stat = TRUE))
  expect_named(s$suff_stat, c("dm", "nlev", "adaptDF"))
})


# ──────────────────────────────────────────────────────────────────────────────
# set_test()
# ──────────────────────────────────────────────────────────────────────────────
test_that("set_test stores key and resolves test in set_suff_stat", {
  s <- PcalgSearch$new()
  my_df <- matrix(rnorm(20), ncol = 2) |> as.data.frame()
  colnames(my_df) <- c("X", "Y")
  s$set_test("fisher_z")
  s$set_data(my_df, set_suff_stat = TRUE)
  expect_equal(s$test, pcalg::gaussCItest, ignore_attr = TRUE)

  s2 <- PcalgSearch$new()
  ddisc <- data.frame(
    A = factor(sample(0:1, 50, TRUE)),
    B = factor(sample(0:1, 50, TRUE))
  )
  s2$set_test("g_square")
  s2$set_data(ddisc, set_suff_stat = TRUE)
  expect_true(is.function(s2$test))
})


test_that("set_test unknown test errors", {
  s <- PcalgSearch$new()

  expect_error(
    s$set_test("not-a-test"),
    "Unknown method: not-a-test",
    fixed = TRUE
  )
})

# ──────────────────────────────────────────────────────────────────────────────
# g_square
# ──────────────────────────────────────────────────────────────────────────────
test_that("g_square dispatches to binCItest or disCItest", {
  set.seed(1405)

  # binary levels -> binCItest path executes
  s2 <- PcalgSearch$new()
  d2 <- data.frame(
    X = factor(sample(0:1, 80, TRUE)),
    Y = factor(sample(0:1, 80, TRUE)),
    Z = factor(sample(0:1, 80, TRUE))
  )
  s2$set_test("g_square")
  s2$set_data(d2, set_suff_stat = TRUE)
  p2 <- s2$test(1, 2, integer(), s2$suff_stat)
  expect_type(p2, "double")

  # multi-level -> disCItest path executes
  s3 <- PcalgSearch$new()
  d3 <- data.frame(
    X = factor(sample(0:2, 80, TRUE)),
    Y = factor(sample(0:2, 80, TRUE)),
    Z = factor(sample(0:2, 80, TRUE))
  )
  s3$set_test("g_square")
  s3$set_data(d3, set_suff_stat = TRUE)
  p3 <- s3$test(1, 2, integer(), s3$suff_stat)
  expect_type(p3, "double")
})


# ──────────────────────────────────────────────────────────────────────────────
# set_score
# ──────────────────────────────────────────────────────────────────────────────

test_that("set_score builds scorer for obs/int and errors on unknown", {
  # obs score
  s1 <- PcalgSearch$new()
  s1$set_score("sem_bic")
  # scorer errors if data missing when invoked through run
  expect_error(
    s1$run_search(data = NULL, set_suff_stat = TRUE),
    "No data is set. Use set_data() first or input data directly into run_search().",
    fixed = TRUE
  )

  # int score
  s2 <- PcalgSearch$new()
  s2$set_score("sem_bic_int")
  expect_error(
    s2$run_search(data = NULL, set_suff_stat = TRUE),
    "No data is set. Use set_data() first or input data directly into run_search().",
    fixed = TRUE
  )

  # unknown
  s3 <- PcalgSearch$new()
  expect_error(
    s3$set_score("not-a-score"),
    "Unknown score type using pcalg engine: not-a-score",
    fixed = TRUE
  )
})

test_that("set_score() lazy builder errors if data missing", {
  s <- PcalgSearch$new()
  s$set_score("sem_bic") # stores closure only

  # call the stored builder directly to hit the error site
  expect_error(
    s$.__enclos_env__$private$score_function(),
    "Data must be set before score.",
    fixed = TRUE
  )
})

test_that("GaussL0penIntScore is constructed when data present", {
  my_df <- data.frame(
    A = as.integer(sample(0:3, 20, TRUE)),
    B = as.integer(sample(0:3, 20, TRUE))
  )
  s <- PcalgSearch$new()
  s$set_data(my_df, set_suff_stat = FALSE)
  s$set_score("sem_bic_int")

  sc <- s$.__enclos_env__$private$score_function()
  expect_true(methods::is(sc, "GaussL0penIntScore"))
})

# ──────────────────────────────────────────────────────────────────────────────
# set_alg()
# ──────────────────────────────────────────────────────────────────────────────

test_that("set_alg builds partials and errors on unknown/guard", {
  s <- PcalgSearch$new()

  # pc and fci requires test
  expect_error(
    s$set_alg("pc"),
    "No test is set. Use set_test() first.",
    fixed = TRUE
  )
  expect_error(
    s$set_alg("fci"),
    "No test is set. Use set_test() first.",
    fixed = TRUE
  )

  s$set_params(list(alpha = 0.05))
  s$set_test("fisher_z")
  s$set_alg("pc")
  expect_true(is.function(s$alg))

  # fci builds partial even if no test set (it will be passed as NULL)
  s2 <- PcalgSearch$new()
  s2$set_params(list(alpha = 0.05))
  s2$set_test("fisher_z")
  s2$set_alg("fci")
  expect_true(is.function(s2$alg))

  # ges builds partial; score is added in run_search
  s3 <- PcalgSearch$new()
  s3$set_alg("ges")
  expect_true(is.function(s3$alg))

  # unknown
  expect_error(
    s$set_alg("nope"),
    "Unknown method type using pcalg engine: nope",
    fixed = TRUE
  )
})

# ──────────────────────────────────────────────────────────────────────────────
# set_knowledge()
# ──────────────────────────────────────────────────────────────────────────────

test_that("set_knowledge defers building constraints and validates input", {
  # error path from check_knowledge_obj propagated
  s_bad <- PcalgSearch$new()
  expect_error(
    s_bad$set_knowledge(knowledge_obj = 123),
    class = "simpleError"
  )

  my_df <- data.frame(A = rnorm(20), B = rnorm(20), C = rnorm(20))
  s <- PcalgSearch$new()
  kn <- knowledge(
    my_df,
    B %!-->% C,
    C %!-->% B
  )

  s$set_knowledge(kn)
  # knowledge_function is deferred; becomes a concrete list during run_search()
  s$set_params(list(alpha = 0.05))
  s$set_test("fisher_z")
  s$set_alg("pc")

  out <- s$run_search(my_df)
  expect_s3_class(out, "Disco")
})

test_that("knowledge builder errors if data missing", {
  # exercise the internal 'Data must be set before knowledge.' stop site
  s <- PcalgSearch$new()
  my_df <- data.frame(X = rnorm(5), Y = rnorm(5))
  kn <- knowledge(my_df, X %-->% Y)

  s$set_knowledge(kn)
  expect_error(
    s$.__enclos_env__$private$knowledge_function(),
    "Data must be set before knowledge.",
    fixed = TRUE
  )
})

test_that("set_knowledge with deprecated directed_as_undirected still mirrors", {
  s_bad <- PcalgSearch$new()
  expect_error(
    s_bad$set_knowledge(knowledge_obj = 123),
    class = "simpleError"
  )

  my_df <- data.frame(A = rnorm(20), B = rnorm(20), C = rnorm(20))
  s <- PcalgSearch$new()
  kn <- knowledge(
    my_df,
    A %-->% B,
    B %!-->% C
  )
  lifecycle::expect_deprecated(
    s$set_knowledge(kn, directed_as_undirected = TRUE)
  )
  s$set_test("fisher_z")
  s$set_data(my_df, set_suff_stat = TRUE)
  s$set_alg("pc")

  expect_warning(
    out <- s$run_search(),
    "Engine pcalg does not use required edges; ignoring them.",
    fixed = TRUE
  )
  expect_s3_class(out, "Disco")
})


# ──────────────────────────────────────────────────────────────────────────────
# run_search()
# ──────────────────────────────────────────────────────────────────────────────

test_that("run_search errors in correct order and messages", {
  s <- PcalgSearch$new()

  expect_error(
    s$run_search(),
    "No data is set. Use set_data() first or input data directly into run_search().",
    fixed = TRUE
  )

  my_df <- matrix(rnorm(30), ncol = 3) |> as.data.frame()
  colnames(my_df) <- c("X", "Y", "Z")
  s$set_test("fisher_z")
  s$set_data(my_df, set_suff_stat = FALSE)

  expect_error(
    s$run_search(),
    "No algorithm is set. Use set_alg() first.",
    fixed = TRUE
  )

  s$set_params(list(alpha = 0.05))
  s$set_alg("pc")
  expect_error(
    s$run_search(),
    "No sufficient statistic is set. Use set_data() first.",
    fixed = TRUE
  )
})

test_that("run_search without score_function (pc) works; with score_function (ges) warns on fixedEdges", {
  set.seed(1405)
  my_df <- matrix(rnorm(100), ncol = 5) |> as.data.frame()
  colnames(my_df) <- LETTERS[1:5]

  # PC path
  s_pc <- PcalgSearch$new()
  s_pc$set_test("fisher_z", alpha = 0.01)
  s_pc$set_data(my_df, set_suff_stat = TRUE)
  s_pc$set_alg("pc")
  res_pc <- s_pc$run_search()
  expect_s3_class(res_pc, "Disco")

  # GES without knowledge
  s_ges <- PcalgSearch$new()
  s_ges$set_alg("ges")
  s_ges$set_score("sem_bic")
  res_ges <- s_ges$run_search(my_df)
  expect_s3_class(res_ges, "Disco")

  # GES with knowledge warns on fixedEdges
  kn_req <- knowledge(my_df, A %-->% B)
  s_ges2 <- PcalgSearch$new()
  s_ges2$set_alg("ges")
  s_ges2$set_score("sem_bic")
  lifecycle::expect_deprecated(
    s_ges2$set_knowledge(kn_req, directed_as_undirected = TRUE)
  )
  expect_warning(
    s_ges2$run_search(my_df),
    "Engine pcalg does not use required edges; ignoring them.",
    fixed = TRUE
  )
})
