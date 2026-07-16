test_that("tfci causalDisco works with no knowledge", {
  data(tpc_example)

  my_tfci <- tfci(engine = "causalDisco", test = "fisher_z")

  output <- disco(tpc_example, my_tfci)
  expect_true(TRUE)
})

test_that("tfci causalDisco arguments to tfci_run can be passed along correctly", {
  # Just test no warning given
  data(tpc_example)

  my_tfci <- tfci(engine = "causalDisco", test = "fisher_z", method = "stable")

  expect_no_warning(disco(tpc_example, my_tfci))
})


test_that("tfci causalDisco respects tier knowledge", {
  data(tpc_example)

  kn <- knowledge(
    tpc_example,
    tier(
      child ~ starts_with("child"),
      youth ~ starts_with("youth"),
      old ~ starts_with("old")
    )
  )

  my_tfci <- tfci(engine = "causalDisco", test = "fisher_z")

  output <- disco(tpc_example, my_tfci, knowledge = kn)
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

  my_tfci <- tfci(engine = "causalDisco", test = "fisher_z")
  output <- disco(tpc_example, my_tfci, knowledge = kn)
  edges <- output$caugi@edges

  violations <- check_tier_violations(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Tier violations were found in the output graph."
  )
})

test_that("tfci causalDisco respects required background knowledge", {
  skip(
    "tfci causalDisco does not yet support required edges from knowledge objects."
  )
  data(tpc_example)

  kn <- knowledge(
    tpc_example,
    child_x1 %-->% youth_x3
  )

  my_tfci <- tfci(engine = "causalDisco", test = "fisher_z")
  out <- disco(data = tpc_example, method = my_tfci, knowledge = kn)

  edges <- out$caugi@edges

  violations <- check_edge_constraints(edges, kn)

  expect_true(
    nrow(violations) == 0,
    info = "Required edge not found in the output graph."
  )
})

test_that("tfci causalDisco respects forbidden background knowledge", {
  data(tpc_example)

  # a single directed forbidden edge is tier-shaped (two one-variable
  # tiers), so it is interpreted as a temporal order and respected
  kn_directed <- knowledge(
    tpc_example,
    child_x2 %!-->% oldage_x5
  )
  my_tfci <- tfci(engine = "causalDisco", test = "fisher_z")
  expect_message(
    out_directed <- disco(
      data = tpc_example,
      method = my_tfci,
      knowledge = kn_directed
    ),
    "encode a temporal order"
  )
  expect_true(
    nrow(check_edge_constraints(out_directed$caugi@edges, kn_directed)) == 0,
    info = "Forbidden edges were found in the output graph."
  )

  # forbidding both directions removes the adjacency
  kn <- knowledge(
    tpc_example,
    child_x2 %!-->% oldage_x5,
    oldage_x5 %!-->% child_x2
  )

  my_tfci <- tfci(engine = "causalDisco", test = "fisher_z")
  out <- disco(data = tpc_example, method = my_tfci, knowledge = kn)

  edges <- out$caugi@edges

  violations <- check_edge_constraints(edges, kn)

  expect_true(
    nrow(violations) == 0,
    info = "Forbidden edges were found in the output graph."
  )

  # Verify it actually changes the output when adding forbidden knowledge
  my_tfci_no_kn <- tfci(engine = "causalDisco", test = "fisher_z")
  out_no_kn <- disco(
    data = tpc_example,
    method = my_tfci_no_kn,
    knowledge = knowledge()
  )
  edges_no_kn <- out_no_kn$caugi@edges

  # The forbidden edge is present
  forbidden_present <- edges_no_kn$from == "child_x2" &
    edges_no_kn$to == "oldage_x5"
  expect_true(
    sum(forbidden_present) >= 1,
    info = "Forbidden edge child_x2 --> oldage_x5 was not found in the output graph without knowledge."
  )
})

test_that("tfci causalDisco infers tiers from tier-shaped forbidden knowledge", {
  data(tpc_example)

  kn <- knowledge(
    tpc_example,
    tier(
      child ~ starts_with("child"),
      youth ~ starts_with("youth"),
      oldage ~ starts_with("old")
    )
  )
  kn_forbidden <- convert_tiers_to_forbidden(kn)

  my_tfci <- tfci(engine = "causalDisco", test = "fisher_z")
  out_tiers <- disco(data = tpc_example, method = my_tfci, knowledge = kn)

  my_tfci <- tfci(engine = "causalDisco", test = "fisher_z")
  expect_message(
    out_forbidden <- disco(
      data = tpc_example,
      method = my_tfci,
      knowledge = kn_forbidden
    ),
    "encode a temporal order"
  )

  expect_identical(out_tiers$caugi@edges, out_forbidden$caugi@edges)
})
