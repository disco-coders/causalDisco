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
