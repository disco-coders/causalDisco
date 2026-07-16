set.seed(1405)
n <- 200
X1 <- rnorm(n)
X2 <- X1 + rnorm(n)
X3 <- X1 + rnorm(n)
X4 <- X3 + rnorm(n)

d <- data.frame(
  p1_X1 = X1,
  p1_X2 = X2,
  p2_X3 = X3,
  p2_X4 = X4
)
vnames <- names(d)

kn <- knowledge(
  d,
  tier(
    p1 ~ tidyselect::starts_with("p1_"),
    p2 ~ tidyselect::starts_with("p2_")
  )
)

ss_cor <- make_suff_stat(d, type = "cor_test")
wrapped <- dir_test(cor_test, vnames, kn)
cons <- .pcalg_constraints_from_knowledge(
  kn,
  labels = vnames
)

skel <- pcalg::skeleton(
  suffStat = ss_cor,
  indepTest = wrapped,
  alpha = 0.05,
  labels = vnames,
  method = "stable.fast",
  fixedGaps = cons$fixed_gaps
)

fci_skel <- pcalg::pdsep(
  skel = skel,
  suffStat = ss_cor,
  indepTest = wrapped,
  p = length(vnames),
  sepset = skel@sepset,
  pMax = skel@pMax,
  unfVect = c(),
  alpha = 0.05
)

# Remove separating sets that condition on variables strictly in the future
sepset_clean <- order_restrict_sepset(
  fci_skel$sepset,
  knowledge = kn,
  vnames = vnames
)
str(sepset_clean, max.level = 1)
