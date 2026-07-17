test_that("custom constraint-based algorithm works end-to-end via disco()", {
  my_alg <- function(data, knowledge, suff_stat) {
    tpc_run(
      data = data,
      knowledge = knowledge,
      suff_stat = suff_stat,
      test = reg_test
    )
  }

  my_engine_fn <- function(...) {
    search <- CausalDiscoSearch$new()
    search$set_test("reg")
    search$set_alg(my_alg)

    list(
      set_knowledge = function(knowledge) search$set_knowledge(knowledge),
      run = function(data) search$run_search(data)
    )
  }

  my_method <- make_method(
    method_name = "my_alg",
    engine = "causalDisco",
    engine_fns = list(causalDisco = my_engine_fn),
    graph_class = "PDAG"
  )

  data(tpc_example)
  kn <- knowledge(
    tpc_example,
    tier(
      child ~ tidyselect::starts_with("child"),
      youth ~ tidyselect::starts_with("youth"),
      old ~ tidyselect::starts_with("oldage")
    )
  )

  result <- disco(data = tpc_example, method = my_method, knowledge = kn)
  expect_s3_class(result, "Disco")
  expect_false(is.null(result$caugi))

  # And without knowledge
  result_no_kn <- disco(data = tpc_example, method = my_method)
  expect_s3_class(result_no_kn, "Disco")
})

test_that("custom score-based algorithm works end-to-end via disco()", {
  my_alg <- function(score) {
    tges_run(score = score)
  }

  my_engine_fn <- function(...) {
    search <- CausalDiscoSearch$new()
    search$set_score("tbic")
    search$set_alg(my_alg, type = "score")

    list(
      set_knowledge = function(knowledge) search$set_knowledge(knowledge),
      run = function(data) search$run_search(data)
    )
  }

  my_method <- make_method(
    method_name = "my_score_alg",
    engine = "causalDisco",
    engine_fns = list(causalDisco = my_engine_fn),
    graph_class = "PDAG"
  )

  set.seed(1405)
  gdf <- matrix(rnorm(200), ncol = 4) |> as.data.frame()
  colnames(gdf) <- paste0("p1_X", 1:4)

  result <- disco(data = gdf, method = my_method)
  expect_s3_class(result, "Disco")
})
