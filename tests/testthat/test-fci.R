test_that("fci Tetrad disco respects tier knowledge", {
  skip_if_no_tetrad()

  data(tpc_example)

  kn <- knowledge(
    tpc_example,
    tier(
      child ~ starts_with("child"),
      youth ~ starts_with("youth"),
      old ~ starts_with("old")
    )
  )

  tetrad_fci <- fci(
    engine = "tetrad",
    test = "conditional_gaussian",
    alpha = 0.05
  )
  output <- disco(data = tpc_example, method = tetrad_fci, knowledge = kn)

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

  tetrad_fci <- fci(
    engine = "tetrad",
    test = "conditional_gaussian",
    alpha = 0.05
  )
  output <- disco(tpc_example, tetrad_fci, knowledge = kn)
  edges <- output$caugi@edges

  violations <- check_tier_violations(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Tier violations were found in the output graph."
  )
})

test_that("fci Tetrad disco respects required background knowledge", {
  skip_if_no_tetrad()
  # TODO Works in unreleased version, so will work in next released version (7.6.11?)
  skip(
    "fci Tetrad does not yet support required background knowledge correctly."
  )

  data(tpc_example)

  kn <- knowledge(
    tpc_example,
    child_x1 %-->% youth_x3
  )

  tetrad_fci <- fci(
    engine = "tetrad",
    test = "conditional_gaussian",
    alpha = 0.05
  )
  output <- disco(data = tpc_example, method = tetrad_fci, knowledge = kn)
  edges <- output$caugi@edges

  violations <- check_edge_constraints(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Required edge not found in the output graph."
  )

  # With tier+required knowledge
  skip(
    "fci Tetrad does not yet support knowledge with both tiers+required edges."
  )

  kn <- knowledge(
    tpc_example,
    tier(
      child ~ starts_with("child"),
      youth ~ starts_with("youth"),
      old ~ starts_with("old")
    ),
    youth_x3 %-->% oldage_x5
  )

  tetrad_fci <- fci(
    engine = "tetrad",
    test = "conditional_gaussian",
    alpha = 0.05
  )
  output <- disco(data = tpc_example, method = tetrad_fci, knowledge = kn)
  edges <- output$caugi@edges

  violations_tiers <- check_tier_violations(edges, kn)
  expect_true(
    nrow(violations_tiers) == 0,
    info = "Tier violations were found in the output graph."
  )

  violations_req <- check_edge_constraints(edges, kn)
  expect_true(
    nrow(violations_req) == 0,
    info = "Required edge not found in the output graph."
  )
})

test_that("fci Tetrad disco respects forbidden background knowledge", {
  skip_if_no_tetrad()

  data(tpc_example)

  kn <- knowledge(
    tpc_example,
    child_x2 %!-->% child_x1
  )

  tetrad_fci <- fci(
    engine = "tetrad",
    test = "conditional_gaussian",
    alpha = 0.05
  )
  output <- disco(data = tpc_example, method = tetrad_fci, knowledge = kn)
  edges <- output$caugi@edges

  violations <- check_edge_constraints(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Required edge not found in the output graph."
  )

  # Verify it actually changes the output when forbidding an edge present above
  kn <- knowledge(
    tpc_example,
    child_x2 %!-->% child_x1 + oldage_x5
  )

  tetrad_fci <- fci(
    engine = "tetrad",
    test = "conditional_gaussian",
    alpha = 0.05
  )
  output <- disco(data = tpc_example, method = tetrad_fci, knowledge = kn)
  edges <- output$caugi@edges
  violations <- check_edge_constraints(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Required edge not found in the output graph."
  )

  # The forbidden edge is not present anymore
  forbidden_present <- edges$from == "child_x2" & edges$to == "oldage_x5"
  expect_true(
    sum(forbidden_present) >= 1,
    info = "Forbidden edge child_x2 --> oldage_x5 was not found in the output graph without knowledge."
  )
})

#### pcalg fci tests

test_that("fci pcalg disco errors on tier knowledge", {
  # See ?as_pcalg_constraints - only forbidden edges are supported
  data(tpc_example)

  kn <- knowledge(
    tpc_example,
    tier(
      child ~ starts_with("child"),
      youth ~ starts_with("youth"),
      old ~ starts_with("old")
    )
  )

  pcalg_fci <- fci(
    engine = "pcalg",
    test = "conditional_gaussian",
    alpha = 0.05
  )
  expect_error(
    disco(data = tpc_example, method = pcalg_fci, knowledge = kn),
    regexp = "pcalg does not support directed tier constraints."
  )
})

test_that("fci pcalg disco errors on required background knowledge", {
  # See ?as_pcalg_constraints - only forbidden edges are supported
  data(tpc_example)

  kn <- knowledge(
    tpc_example,
    child_x1 %-->% youth_x3
  )

  pcalg_fci <- fci(
    engine = "pcalg",
    test = "conditional_gaussian",
    alpha = 0.05
  )
  expect_error(
    disco(data = tpc_example, method = pcalg_fci, knowledge = kn),
    regexp = "pcalg does not support asymmetric edges."
  )
})

test_that("fci pcalg disco respects forbidden background knowledge", {
  data(tpc_example)

  kn <- knowledge(
    tpc_example,
    child_x1 %!-->% youth_x3
  )

  pcalg_fci <- fci(
    engine = "pcalg",
    test = "conditional_gaussian",
    alpha = 0.05
  )
  expect_error(
    disco(data = tpc_example, method = pcalg_fci, knowledge = kn),
    regexp = "pcalg does not support asymmetric edges."
  )

  kn <- knowledge(
    tpc_example,
    child_x1 %!-->% youth_x3,
    youth_x3 %!-->% child_x1
  )

  pcalg_fci <- fci(
    engine = "pcalg",
    test = "conditional_gaussian",
    alpha = 0.05
  )
  output <- disco(data = tpc_example, method = pcalg_fci, knowledge = kn)
  edges <- output$caugi@edges

  violations <- check_edge_constraints(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Required edge not found in the output graph."
  )

  pcalg_fci <- fci(
    engine = "pcalg",
    test = "conditional_gaussian",
    alpha = 0.05
  )
  output <- disco(data = tpc_example, method = pcalg_fci)
  edges_new <- output$caugi@edges

  # Test the original edges had the forbidden edge
  forbidden_present <-
    (edges$from == "child_x1" & edges$to == "child_x2") |
    (edges$from == "child_x2" & edges$to == "child_x1")

  expect_true(
    sum(forbidden_present) >= 1,
    info = "Forbidden edge child_x1 --> child_x2 was not found in the output graph without this knowledge."
  )
})
