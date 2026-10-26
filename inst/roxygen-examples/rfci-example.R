data(tpc_example)

# Recommended path using disco()
rfci_pcalg <- rfci(engine = "pcalg", test = "fisher_z", alpha = 0.05)
disco(tpc_example, rfci_pcalg)

# or using rfci_pcalg directly
rfci_pcalg(tpc_example)

# With all algorithm arguments specified
rfci_pcalg <- rfci(
  engine = "pcalg",
  test = "fisher_z",
  alpha = 0.05,
  skel.method = "original",
  fixedGaps = NULL,
  fixedEdges = NULL,
  NAdelete = FALSE,
  m.max = 10,
  rules = c(rep(TRUE, 9), FALSE),
  conservative = TRUE,
  maj.rule = FALSE,
  numCores = 1,
  verbose = FALSE
)
disco(tpc_example, rfci_pcalg)

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
  rfci_tetrad <- rfci(engine = "tetrad", test = "fisher_z", alpha = 0.05)
  disco(tpc_example, rfci_tetrad, knowledge = kn)

  # or using rfci_tetrad directly
  rfci_tetrad <- rfci_tetrad |> set_knowledge(kn)
  rfci_tetrad(tpc_example)
}

# With all algorithm arguments specified
if (verify_tetrad()$installed && verify_tetrad()$java_ok) {
  rfci_tetrad <- rfci(
    engine = "tetrad",
    test = "fisher_z",
    alpha = 0.05,
    depth = 10,
    max_disc_path_length = 2,
    exclude_selection_bias = FALSE,
    fdr_q = 0.05
  )
  disco(tpc_example, rfci_tetrad)
}
