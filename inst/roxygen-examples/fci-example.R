data(tpc_example)

# Recommended path using disco()
fci_pcalg <- fci(engine = "pcalg", test = "fisher_z", alpha = 0.05)
disco(tpc_example, fci_pcalg)

# or using fci_pcalg directly
fci_pcalg(tpc_example)

# With all algorithm arguments specified
fci_pcalg <- fci(
  engine = "pcalg",
  test = "fisher_z",
  alpha = 0.05,
  skel.method = "original",
  type = "anytime",
  fixedGaps = NULL,
  fixedEdges = NULL,
  NAdelete = FALSE,
  m.max = 10,
  pdsep.max = 2,
  rules = c(rep(TRUE, 9), FALSE),
  doPdsep = FALSE,
  biCC = TRUE,
  conservative = TRUE,
  maj.rule = FALSE,
  numCores = 1,
  selectionBias = FALSE,
  jci = "1",
  verbose = FALSE
)
disco(tpc_example, fci_pcalg)

#### Using tetrad engine with tier knowledge ####
# Requires Tetrad to be installed
if (verify_tetrad()$installed && verify_tetrad()$java_ok) {
  kn <- knowledge(
    tpc_example,
    tier(
      child ~ tidyselect::starts_with("child"),
      youth ~ tidyselect::starts_with("youth"),
      oldage ~ tidyselect::starts_with("oldage")
    )
  )

  # Recommended path using disco()
  fci_tetrad <- fci(engine = "tetrad", test = "fisher_z", alpha = 0.05)
  disco(tpc_example, fci_tetrad, knowledge = kn)

  # or using fci_tetrad directly
  fci_tetrad <- fci_tetrad |> set_knowledge(kn)
  fci_tetrad(tpc_example)
}

# With all algorithm arguments specified
if (verify_tetrad()$installed && verify_tetrad()$java_ok) {
  fci_tetrad <- fci(
    engine = "tetrad",
    test = "fisher_z",
    alpha = 0.05,
    complete_rule_set_used = FALSE,
    max_disc_path_length = 4,
    depth = 10,
    stable_fas = FALSE,
    guarantee_pag = TRUE,
    collider_orientation_style = "sepsets",
    do_possible_dsep = FALSE,
    exclude_selection_bias = FALSE,
    fdr_q = 0.05
  )
  disco(tpc_example, fci_tetrad)
}
