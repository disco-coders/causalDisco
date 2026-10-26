data(tpc_example)

#### Using pcalg engine ####
# Recommended path using disco()
ges_pcalg <- ges(engine = "pcalg", score = "sem_bic")
disco(tpc_example, ges_pcalg)

# or using ges_pcalg directly
ges_pcalg(tpc_example)

# With all algorithm arguments specified
ges_pcalg <- ges(
  engine = "pcalg",
  score = "sem_bic",
  adaptive = "vstructures",
  phase = "forward",
  iterate = FALSE,
  maxDegree = 3,
  verbose = FALSE
)
disco(tpc_example, ges_pcalg)


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
  ges_tetrad <- ges(engine = "tetrad", score = "sem_bic")
  disco(tpc_example, ges_tetrad, knowledge = kn)

  # or using ges_tetrad directly
  ges_tetrad <- ges_tetrad |> set_knowledge(kn)
  ges_tetrad(tpc_example)
}

# With all algorithm arguments specified
if (verify_tetrad()$installed && verify_tetrad()$java_ok) {
  ges_tetrad <- ges(
    engine = "tetrad",
    score = "ebic",
    symmetric_first_step = TRUE,
    max_degree = 3,
    faithfulness_assumed = TRUE,
    num_threads = 1
  )
  disco(tpc_example, ges_tetrad)
}
