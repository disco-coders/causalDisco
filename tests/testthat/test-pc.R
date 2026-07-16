test_that("pc Tetrad disco respects tier knowledge", {
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

  tetrad_pc <- pc(
    engine = "tetrad",
    test = "conditional_gaussian",
    alpha = 0.05
  )
  output <- disco(data = tpc_example, method = tetrad_pc, knowledge = kn)

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

  tetrad_pc <- pc(
    engine = "tetrad",
    test = "conditional_gaussian",
    alpha = 0.05
  )
  output <- disco(tpc_example, tetrad_pc, knowledge = kn)
  edges <- output$caugi@edges

  violations <- check_tier_violations(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Tier violations were found in the output graph."
  )
})

test_that("pc Tetrad disco respects required background knowledge", {
  skip_if_no_tetrad()

  data(tpc_example)

  kn <- knowledge(
    tpc_example,
    child_x1 %-->% youth_x3
  )

  tetrad_pc <- pc(engine = "tetrad", test = "fisher_z", alpha = 0.05)
  output <- disco(data = tpc_example, method = tetrad_pc, knowledge = kn)
  edges <- output$caugi@edges

  violations <- check_edge_constraints(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Required edge not found in the output graph."
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

  tetrad_pc <- pc(
    engine = "tetrad",
    test = "conditional_gaussian",
    alpha = 0.05
  )
  output <- disco(data = tpc_example, method = tetrad_pc, knowledge = kn)
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

test_that("pc Tetrad disco respects forbidden background knowledge", {
  skip_if_no_tetrad()

  data(tpc_example)

  kn <- knowledge(
    tpc_example,
    child_x1 %!-->% youth_x3,
    child_x2 %!-->% child_x1
  )

  tetrad_pc <- pc(
    engine = "tetrad",
    test = "conditional_gaussian",
    alpha = 0.05
  )
  output <- disco(data = tpc_example, method = tetrad_pc, knowledge = kn)
  edges <- output$caugi@edges

  violations <- check_edge_constraints(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Required edge not found in the output graph."
  )

  # Verify it actually changes the output when adding forbidden knowledge
  tetrad_pc_no_kn <- pc(
    engine = "tetrad",
    test = "conditional_gaussian",
    alpha = 0.05
  )
  out_no_kn <- disco(data = tpc_example, method = tetrad_pc_no_kn)
  edges_no_kn <- out_no_kn$caugi@edges

  # The forbidden edge is present
  forbidden_present <- edges_no_kn$from == "child_x2" &
    edges_no_kn$to == "oldage_x5"
  expect_true(
    sum(forbidden_present) >= 1,
    info = "Forbidden edge child_x2 --> oldage_x5 was not found in the output graph without knowledge."
  )
})

#### pcalg PC tests

test_that("pc pcalg disco errors on tier knowledge", {
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

  pcalg_pc <- pc(engine = "pcalg", test = "conditional_gaussian", alpha = 0.05)
  expect_error(
    disco(data = tpc_example, method = pcalg_pc, knowledge = kn),
    regexp = "pcalg does not support directed tier constraints."
  )
})

test_that("pc pcalg disco warns and ignores required background knowledge", {
  # See ?as_pcalg_constraints - only forbidden edges are supported
  data(tpc_example)

  kn <- knowledge(
    tpc_example,
    child_x1 %-->% youth_x3
  )

  pcalg_pc <- pc(engine = "pcalg", test = "conditional_gaussian", alpha = 0.05)
  expect_warning(
    out <- disco(data = tpc_example, method = pcalg_pc, knowledge = kn),
    regexp = "cannot represent required edges"
  )
  expect_s3_class(out, "Disco")
})

test_that("pc pcalg disco respects forbidden background knowledge", {
  data(tpc_example)

  kn <- knowledge(
    tpc_example,
    child_x1 %!-->% youth_x3
  )

  pcalg_pc <- pc(engine = "pcalg", test = "conditional_gaussian", alpha = 0.05)
  expect_error(
    disco(data = tpc_example, method = pcalg_pc, knowledge = kn),
    regexp = "pcalg does not support asymmetric edges."
  )

  kn <- knowledge(
    tpc_example,
    child_x1 %!-->% youth_x3,
    youth_x3 %!-->% child_x1
  )

  pcalg_pc <- pc(engine = "pcalg", test = "conditional_gaussian", alpha = 0.05)
  output <- disco(data = tpc_example, method = pcalg_pc, knowledge = kn)
  edges <- output$caugi@edges

  violations <- check_edge_constraints(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Required edge not found in the output graph."
  )

  pcalg_pc <- pc(engine = "pcalg", test = "conditional_gaussian", alpha = 0.05)
  output <- disco(data = tpc_example, method = pcalg_pc)
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


#### bnlearn PC tests

test_that("pc bnlearn disco respects tier knowledge", {
  data(tpc_example)

  kn <- knowledge(
    tpc_example,
    tier(
      child ~ starts_with("child"),
      youth ~ starts_with("youth"),
      old ~ starts_with("old")
    )
  )

  bnlearn_pc <- pc(engine = "bnlearn", test = "fisher_z", alpha = 0.05)
  output <- disco(data = tpc_example, method = bnlearn_pc, knowledge = kn)

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

  bnlearn_pc <- pc(engine = "bnlearn", test = "fisher_z", alpha = 0.05)
  output <- disco(tpc_example, bnlearn_pc, knowledge = kn)
  edges <- output$caugi@edges

  violations <- check_tier_violations(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Tier violations were found in the output graph."
  )
})

test_that("pc bnlearn disco respects required background knowledge", {
  data(tpc_example)

  kn <- knowledge(
    tpc_example,
    child_x1 %-->% youth_x3
  )
  bnlearn_pc <- pc(engine = "bnlearn", test = "fisher_z", alpha = 0.05)

  # bnlearn gives a harmless(?) warning about v-structures when using required edges sometimes
  expect_warning(
    output <- disco(data = tpc_example, method = bnlearn_pc, knowledge = kn),
    "vstructure"
  )
  edges <- output$caugi@edges

  violations <- check_edge_constraints(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Required edge not found in the output graph."
  )

  kn <- knowledge(
    tpc_example,
    oldage_x5 %-->% youth_x3
  )

  bnlearn_pc <- pc(engine = "bnlearn", test = "fisher_z", alpha = 0.05)
  output <- disco(data = tpc_example, method = bnlearn_pc, knowledge = kn)
  edges <- output$caugi@edges

  violations <- check_edge_constraints(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Required edge not found in the output graph."
  )

  # With tier+required knowledge
  kn <- knowledge(
    tpc_example,
    tier(
      child ~ starts_with("child"),
      youth ~ starts_with("youth"),
      old ~ starts_with("old")
    ),
    youth_x3 %-->% oldage_x5
  )

  bnlearn_pc <- pc(engine = "bnlearn", test = "fisher_z", alpha = 0.05)
  output <- disco(data = tpc_example, method = bnlearn_pc, knowledge = kn)
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


test_that("pc bnlearn disco respects forbidden background knowledge", {
  data(tpc_example)

  kn <- knowledge(
    tpc_example,
    child_x1 %!-->% youth_x3
  )

  bnlearn_pc <- pc(engine = "bnlearn", test = "cor", alpha = 0.05)
  output <- disco(data = tpc_example, method = bnlearn_pc, knowledge = kn)
  edges <- output$caugi@edges

  violations <- check_edge_constraints(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Required edge not found in the output graph."
  )

  kn <- knowledge(
    tpc_example,
    child_x1 %!-->% youth_x3,
    youth_x3 %!-->% child_x1
  )

  bnlearn_pc <- pc(engine = "bnlearn", test = "cor", alpha = 0.05)
  output <- disco(data = tpc_example, method = bnlearn_pc, knowledge = kn)
  edges <- output$caugi@edges

  violations <- check_edge_constraints(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Required edge not found in the output graph."
  )

  # Test that if we forbid first edge from edges it's not present anymore (test it actually does something)
  # Find edges which are "-->"
  edge_required <- edges$edge == "-->"
  edges <- edges[edge_required, ]
  # Forbid the 1st such edge
  op <- paste0("%", edges$edge[1], "%")

  edge_expr <- as.call(list(
    as.name(op),
    as.name(edges$from[1]),
    as.name(edges$to[1])
  ))

  kn <- do.call(
    knowledge,
    list(
      tpc_example,
      child_x1 %!-->% youth_x3,
      youth_x3 %!-->% child_x1,
      edge_expr
    )
  )

  bnlearn_pc <- pc(engine = "bnlearn", test = "cor", alpha = 0.05)
  output <- disco(data = tpc_example, method = bnlearn_pc, knowledge = kn)
  edges <- output$caugi@edges

  violations <- check_edge_constraints(edges, kn)
  expect_true(
    nrow(violations) == 0,
    info = "Required edge not found in the output graph."
  )
})


# All engines can learn collider structure (A -> B <- C):
test_that("pc disco learns colliders with all engines", {
  set.seed(1405)
  n <- 10000
  A <- rnorm(n)
  C <- rnorm(n)
  B <- 0.8 * A + 0.5 * C + rnorm(n)
  data_simple <- data.frame(A, B, C)

  if (verify_tetrad()$installed && verify_tetrad()$java_ok) {
    tetrad_pc <- pc(engine = "tetrad", test = "fisher_z", alpha = 0.05)
    output_tetrad <- disco(data = data_simple, method = tetrad_pc)
    edges_tetrad <- output_tetrad$caugi@edges
    edges_tetrad
  }

  pc_pcalg <- pc(engine = "pcalg", test = "fisher_z", alpha = 0.05)
  output_pcalg <- disco(data = data_simple, method = pc_pcalg)
  edges_pcalg <- output_pcalg$caugi@edges

  pc_bnlearn <- pc(engine = "bnlearn", test = "fisher_z", alpha = 0.05)
  output_bnlearn <- disco(data = data_simple, method = pc_bnlearn)
  edges_bnlearn <- output_bnlearn$caugi@edges

  expect_true(
    any(
      edges_pcalg$from == "A" &
        edges_pcalg$to == "B" &
        edges_pcalg$edge == "-->"
    ) &
      any(
        edges_pcalg$from == "C" &
          edges_pcalg$to == "B" &
          edges_pcalg$edge == "-->"
      ),
    info = "pcalg PC did not learn the collider structure A -> B <- C"
  )

  expect_true(
    any(
      edges_bnlearn$from == "A" &
        edges_bnlearn$to == "B" &
        edges_bnlearn$edge == "-->"
    ) &
      any(
        edges_bnlearn$from == "C" &
          edges_bnlearn$to == "B" &
          edges_bnlearn$edge == "-->"
      ),
    info = "bnlearn PC did not learn the collider structure A -> B <- C"
  )
  skip_if_no_tetrad()
  expect_true(
    any(
      edges_tetrad$from == "A" &
        edges_tetrad$to == "B" &
        edges_tetrad$edge == "-->"
    ) &
      any(
        edges_tetrad$from == "C" &
          edges_tetrad$to == "B" &
          edges_tetrad$edge == "-->"
      ),
    info = "tetrad PC did not learn the collider structure A -> B <- C"
  )
})


# All engines learn the same DAG structure on a slightly more complex example
test_that("pc disco learns same structure with all engines", {
  set.seed(1405)
  n <- 1000
  x <- rnorm(n)
  v <- x + rnorm(n) * 0.5
  w <- x + rnorm(n) * 0.5
  z <- v + w + rnorm(n) * 0.5
  s <- z + rnorm(n) * 0.5

  data_simple <- data.frame(x = x, v = v, w = w, z = z, s = s)

  pc_pcalg <- pc(engine = "pcalg", test = "fisher_z", alpha = 0.05)
  pc_bnlearn <- pc(engine = "bnlearn", test = "fisher_z", alpha = 0.05)

  pc_result_pcalg <- disco(data_simple, method = pc_pcalg)
  pc_result_bnlearn <- disco(data_simple, method = pc_bnlearn)

  edges_pcalg <- pc_result_pcalg$caugi@edges
  edges_bnlearn <- pc_result_bnlearn$caugi@edges

  # Function to normalize undirected edges for comparison (so a --- b and b --- a are the same, and sorted)
  normalize_edges <- function(df) {
    i <- df$edge == "---"

    from_orig <- df$from
    to_orig <- df$to

    df$from[i] <- pmin(from_orig[i], to_orig[i])
    df$to[i] <- pmax(from_orig[i], to_orig[i])

    df <- df[order(df$from, df$edge, df$to), ]
    rownames(df) <- NULL
    df
  }

  edges_pcalg_norm <- normalize_edges(edges_pcalg)
  edges_bnlearn_norm <- normalize_edges(edges_bnlearn)

  expect_equal(
    edges_pcalg_norm,
    edges_bnlearn_norm,
    info = "pcalg and bnlearn PC did not learn the same structure"
  )

  skip_if_no_tetrad()

  tetrad_pc <- pc(engine = "tetrad", test = "fisher_z", alpha = 0.05)
  pc_result_tetrad <- disco(data_simple, method = tetrad_pc)
  edges_tetrad <- pc_result_tetrad$caugi@edges
  edges_tetrad_norm <- normalize_edges(edges_tetrad)

  expect_equal(
    edges_tetrad_norm,
    edges_pcalg_norm,
    info = "tetrad and pcalg PC did not learn the same structure"
  )
})
