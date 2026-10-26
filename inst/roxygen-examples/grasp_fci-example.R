data(tpc_example)

# Requires Tetrad to be installed
if (verify_tetrad()$installed && verify_tetrad()$java_ok) {
  # Recommended path using disco()
  grasp_fci_tetrad <- grasp_fci(
    engine = "tetrad",
    test = "fisher_z",
    score = "sem_bic",
    alpha = 0.05
  )
  disco(tpc_example, grasp_fci_tetrad)

  # or using grasp_fci_tetrad directly
  grasp_fci_tetrad(tpc_example)
}

#### With tier knowledge ####
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
  grasp_fci_tetrad <- grasp_fci(
    engine = "tetrad",
    test = "fisher_z",
    score = "sem_bic",
    alpha = 0.05
  )
  disco(tpc_example, grasp_fci_tetrad, knowledge = kn)

  # or using grasp_fci_tetrad directly
  grasp_fci_tetrad <- grasp_fci_tetrad |> set_knowledge(kn)
  grasp_fci_tetrad(tpc_example)
}

# With all algorithm arguments specified
if (verify_tetrad()$installed && verify_tetrad()$java_ok) {
  grasp_fci_tetrad <- grasp_fci(
    engine = "tetrad",
    test = "poisson_prior",
    score = "rank_bic",
    alpha = 0.05,
    depth = 3,
    max_disc_path_length = 5,
    singular_depth = 2,
    nonsingular_depth = 2,
    ordered_alg = TRUE,
    raskutti_uhler = TRUE,
    use_data_order = FALSE,
    num_starts = 3,
    guarantee_pag = TRUE,
    use_score = TRUE,
    use_heuristic = FALSE,
    exclude_selection_bias = FALSE,
    seed = 1405
  )
  disco(tpc_example, grasp_fci_tetrad)
}
