test_that("tpc causalDisco arguments to tfci_run can be passed along correctly", {
  data(tpc_example)

  my_tpc <- tpc(engine = "causalDisco", test = "fisher_z", method = "stable")

  expect_no_warning(disco(tpc_example, my_tpc))
})

test_that("tpc causalDisco respects tier knowledge", {
  data(tpc_example)

  kn <- knowledge(
    tpc_example,
    tier(
      child ~ starts_with("child"),
      youth ~ starts_with("youth"),
      old ~ starts_with("old")
    )
  )

  my_tpc <- tpc(engine = "causalDisco", test = "fisher_z")

  output <- disco(tpc_example, my_tpc, knowledge = kn)
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

  my_tpc <- tpc(engine = "causalDisco", test = "fisher_z")
  output <- disco(tpc_example, my_tpc, knowledge = kn)
  edges <- output$caugi@edges

  violations <- check_tier_violations(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Tier violations were found in the output graph."
  )
})

test_that("tpc causalDisco errors on required background knowledge", {
  data(tpc_example)

  kn <- knowledge(
    tpc_example,
    child_x1 %-->% youth_x3
  )

  my_tpc <- tpc(engine = "causalDisco", test = "fisher_z")
  expect_error(
    disco(data = tpc_example, method = my_tpc, knowledge = kn),
    "causalDisco engine does not support required edges in knowledge."
  )
})

test_that("tpc causalDisco respects forbidden background knowledge", {
  data(tpc_example)

  # a single directed forbidden edge is tier-shaped (two one-variable
  # tiers), so it is interpreted as a temporal order and respected
  kn <- knowledge(
    tpc_example,
    child_x2 %!-->% oldage_x5
  )

  my_tpc <- tpc(engine = "causalDisco", test = "fisher_z")
  expect_message(
    out <- disco(data = tpc_example, method = my_tpc, knowledge = kn),
    "encode a temporal order"
  )
  expect_true(
    nrow(check_edge_constraints(out$caugi@edges, kn)) == 0,
    info = "Forbidden edges were found in the output graph."
  )

  # forbidding both directions removes the adjacency
  kn <- knowledge(
    tpc_example,
    child_x2 %!-->% oldage_x5,
    oldage_x5 %!-->% child_x2
  )

  my_tpc <- tpc(engine = "causalDisco", test = "fisher_z")
  out <- disco(data = tpc_example, method = my_tpc, knowledge = kn)
  edges <- out$caugi@edges

  violations <- check_edge_constraints(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Forbidden edges were found in the output graph."
  )
})

test_that("tpc causalDisco combines directed forbidden knowledge with tiers", {
  data(tpc_example)

  # forbidding child_x2 -> oldage_x5 is allowed: the reverse direction is
  # already forbidden by the tier ordering, so the pair becomes a gap
  kn <- knowledge(
    tpc_example,
    tier(
      child ~ starts_with("child"),
      youth ~ starts_with("youth"),
      oldage ~ starts_with("old")
    ),
    child_x2 %!-->% oldage_x5
  )

  my_tpc <- tpc(engine = "causalDisco", test = "fisher_z")
  out <- disco(data = tpc_example, method = my_tpc, knowledge = kn)
  edges <- out$caugi@edges

  expect_true(
    nrow(check_edge_constraints(edges, kn)) == 0,
    info = "Forbidden edges were found in the output graph."
  )
  expect_true(
    nrow(check_tier_violations(edges, kn)) == 0,
    info = "Tier violations were found in the output graph."
  )
  expect_false(
    any(
      (edges$from == "child_x2" & edges$to == "oldage_x5") |
        (edges$from == "oldage_x5" & edges$to == "child_x2")
    ),
    info = "child_x2 and oldage_x5 should not be adjacent."
  )

  # a forbidden edge that is already implied by the tiers is redundant and
  # simply ignored
  kn_redundant <- knowledge(
    tpc_example,
    tier(
      child ~ starts_with("child"),
      youth ~ starts_with("youth"),
      oldage ~ starts_with("old")
    ),
    oldage_x5 %!-->% child_x2
  )

  my_tpc <- tpc(engine = "causalDisco", test = "fisher_z")
  out_redundant <- disco(
    data = tpc_example,
    method = my_tpc,
    knowledge = kn_redundant
  )
  expect_true(
    nrow(check_tier_violations(out_redundant$caugi@edges, kn_redundant)) == 0,
    info = "Tier violations were found in the output graph."
  )
})

test_that("tpc causalDisco infers tiers from tier-shaped forbidden knowledge", {
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

  my_tpc <- tpc(engine = "causalDisco", test = "fisher_z")
  out_tiers <- disco(data = tpc_example, method = my_tpc, knowledge = kn)

  my_tpc <- tpc(engine = "causalDisco", test = "fisher_z")
  expect_message(
    out_forbidden <- disco(
      data = tpc_example,
      method = my_tpc,
      knowledge = kn_forbidden
    ),
    "encode a temporal order"
  )

  expect_identical(out_tiers$caugi@edges, out_forbidden$caugi@edges)

  # forbidden edges that do not form a temporal order still error
  kn_bad <- knowledge(
    tpc_example,
    child_x1 %!-->% youth_x3,
    child_x2 %!-->% youth_x4
  )
  my_tpc <- tpc(engine = "causalDisco", test = "fisher_z")
  expect_error(
    disco(data = tpc_example, method = my_tpc, knowledge = kn_bad),
    "asymmetric edges"
  )
})
