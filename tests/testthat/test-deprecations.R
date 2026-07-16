test_that("generate_dag_data deprecated", {
  out <- sim_dag(n = 5, m = 4)
  lifecycle::expect_deprecated(generate_dag_data(out, n = 5))
})

test_that("summary Knowledge deprecated", {
  kn <- knowledge(A %-->% B)
  lifecycle::expect_deprecated(summary(kn))
})

test_that("summary Disco deprecated", {
  pc_pcalg <- pc(engine = "pcalg", test = "fisher_z", alpha = 0.05)
  fit <- disco(tpc_example, pc_pcalg)
  lifecycle::expect_deprecated(summary(fit))
})

test_that("directed_as_undirected deprecated in tpc_run and tfci_run", {
  data(tpc_example)
  kn <- knowledge(
    tpc_example,
    tier(
      child ~ starts_with("child"),
      youth ~ starts_with("youth"),
      oldage ~ starts_with("old")
    )
  )
  lifecycle::expect_deprecated(
    tpc_run(
      tpc_example,
      knowledge = kn,
      test = cor_test,
      directed_as_undirected = TRUE
    )
  )
  lifecycle::expect_deprecated(
    tfci_run(
      tpc_example,
      knowledge = kn,
      test = cor_test,
      directed_as_undirected = TRUE
    )
  )
})

test_that("directed_as_undirected deprecated in CausalDiscoSearch$set_knowledge", {
  kn <- knowledge(A %-->% B)
  s <- CausalDiscoSearch$new()
  lifecycle::expect_deprecated(
    s$set_knowledge(kn, directed_as_undirected = TRUE)
  )
})

test_that("directed_as_undirected deprecated in PcalgSearch$set_knowledge", {
  kn <- knowledge(A %-->% B)
  s <- PcalgSearch$new()
  lifecycle::expect_deprecated(
    s$set_knowledge(kn, directed_as_undirected = TRUE)
  )
})
