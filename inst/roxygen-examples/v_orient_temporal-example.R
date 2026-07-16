data(tpc_example)
vnames <- names(tpc_example)

kn <- knowledge(
  tpc_example,
  tier(
    child ~ tidyselect::starts_with("child"),
    youth ~ tidyselect::starts_with("youth"),
    oldage ~ tidyselect::starts_with("oldage")
  )
)

ss_cor <- make_suff_stat(tpc_example, type = "cor_test")
wrapped_test <- dir_test(cor_test, vnames, kn)
pc_cons <- .pcalg_constraints_from_knowledge(
  kn,
  labels = vnames
)

set.seed(1405)
skel <- pcalg::skeleton(
  suffStat = ss_cor,
  indepTest = wrapped_test,
  alpha = 0.05,
  labels = vnames,
  method = "stable.fast",
  fixedGaps = pc_cons$fixed_gaps
)
