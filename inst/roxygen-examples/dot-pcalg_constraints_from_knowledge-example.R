data(tpc_example)

kn <- knowledge(
  tpc_example,
  tier(
    child ~ tidyselect::starts_with("child"),
    youth ~ tidyselect::starts_with("youth"),
    oldage ~ tidyselect::starts_with("oldage")
  )
)

pc_cons <- .pcalg_constraints_from_knowledge(
  kn,
  labels = names(tpc_example)
)
pc_cons
