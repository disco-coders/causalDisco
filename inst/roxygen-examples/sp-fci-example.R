data(num_data)

# Requires Tetrad to be installed
if (verify_tetrad()$installed && verify_tetrad()$java_ok) {
  # Recommended path using disco()
  sp_fci_tetrad <- sp_fci(
    engine = "tetrad",
    score = "sem_bic",
    test = "fisher_z"
  )
  disco(tpc_example, sp_fci_tetrad)

  # or using sp_fci_tetrad directly
  sp_fci_tetrad(tpc_example)
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
  sp_fci_tetrad <- sp_fci(
    engine = "tetrad",
    score = "sem_bic",
    test = "fisher_z"
  )
  disco(tpc_example, sp_fci_tetrad, knowledge = kn)

  # or using sp_fci_tetrad directly
  sp_fci_tetrad <- sp_fci_tetrad |> set_knowledge(kn)
  sp_fci_tetrad(tpc_example)
}

# With all algorithm arguments specified
if (verify_tetrad()$installed && verify_tetrad()$java_ok) {
  sp_fci_tetrad <- sp_fci(
    engine = "tetrad",
    score = "poisson_prior",
    test = "rank_independence",
    max_disc_path_length = 5,
    use_heuristic = FALSE,
    complete_rule_set_used = FALSE,
    guarantee_pag = TRUE,
    exclude_selection_bias = FALSE,
    verbose = FALSE
  )
  disco(num_data, sp_fci_tetrad)
}
