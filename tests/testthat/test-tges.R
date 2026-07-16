test_that("tges causalDisco arguments to tfci_run can be passed along correctly", {
  # Just test no warning given
  data(tpc_example)

  my_tges <- tges(engine = "causalDisco", score = "tbic", verbose = TRUE)

  output <- capture.output(
    expect_no_warning(disco(tpc_example, my_tges))
  )
  # Verify verbose works
  expect_true(any(grepl("Casting graph", output)))
})


test_that("TGES causalDisco respects tier-based background knowledge", {
  data(tpc_example)

  kn <- knowledge(
    tpc_example,
    tier(
      child ~ starts_with("child"),
      youth ~ starts_with("youth"),
      old ~ starts_with("old")
    )
  )

  my_tges <- tges(engine = "causalDisco", score = "tbic")

  output <- disco(tpc_example, my_tges, knowledge = kn)
  edges <- output$caugi@edges

  violations <- check_tier_violations(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Tier violations were found in the output graph."
  )

  kn <- knowledge(
    tpc_example,
    tier(
      1 ~ starts_with("old"),
      2 ~ starts_with("youth"),
      3 ~ starts_with("child")
    )
  )

  my_tges <- tges(engine = "causalDisco", score = "tbic")

  output <- disco(tpc_example, my_tges, knowledge = kn)
  edges <- output$caugi@edges

  violations <- check_tier_violations(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Tier violations were found in the output graph."
  )
})

test_that("TGES causalDisco respects forbidden background knowledge", {
  data(tpc_example)

  kn <- knowledge(
    tpc_example,
    child_x1 %!-->% youth_x3
  )

  # Run TGES with TemporalBIC
  my_tges <- tges(engine = "causalDisco", score = "tbic")
  out <- disco(data = tpc_example, method = my_tges, knowledge = kn)

  edges <- out$caugi@edges

  violations <- check_edge_constraints(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Forbidden edge found in the output graph."
  )
})
