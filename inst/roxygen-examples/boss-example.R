data(tpc_example)

# Requires Tetrad to be installed
if (verify_tetrad()$installed && verify_tetrad()$java_ok) {
  # Recommended path using disco()
  boss_tetrad <- boss(engine = "tetrad", score = "sem_bic")
  disco(tpc_example, boss_tetrad)

  # or using boss_tetrad directly
  boss_tetrad(tpc_example)
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
  boss_tetrad <- boss(engine = "tetrad", score = "sem_bic")
  disco(tpc_example, boss_tetrad, knowledge = kn)

  # or using boss_tetrad directly
  boss_tetrad <- boss_tetrad |> set_knowledge(kn)
  boss_tetrad(tpc_example)
}

# With all algorithm arguments specified
if (verify_tetrad()$installed && verify_tetrad()$java_ok) {
  boss_tetrad <- boss(
    engine = "tetrad",
    score = "gic",
    num_starts = 2,
    use_bes = FALSE,
    use_data_order = FALSE,
    output_cpdag = FALSE,
    num_threads = 1,
    seed = 1405
  )
  disco(tpc_example, boss_tetrad)
}
