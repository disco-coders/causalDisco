data(tpc_example)

# verb form: forbid edges that skip more than one tier
kn1 <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    old ~ starts_with("oldage")
  )
) |>
  set_max_lag(1)

print(kn1)

# DSL form: max_lag() inside knowledge() is equivalent
kn2 <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    old ~ starts_with("oldage")
  ),
  max_lag(1)
)

print(identical(kn1, kn2))
