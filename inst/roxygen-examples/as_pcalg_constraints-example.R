# pcalg supports undirected constraints; build a tierless knowledge and convert
data(tpc_example)

kn <- knowledge(
  tpc_example,
  child_x1 %!-->% youth_x3,
  youth_x3 %!-->% child_x1
)

pc_constraints <- as_pcalg_constraints(kn)
print(pc_constraints)

# error paths
# using tiers
kn <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    oldage ~ starts_with("old")
  ),
  child_x1 %-->% youth_x3
)

try(as_pcalg_constraints(kn), silent = TRUE) # fails due to tiers

# using directed knowledge
kn <- knowledge(
  tpc_example,
  child_x1 %!-->% youth_x3
)

try(as_pcalg_constraints(kn), silent = TRUE) # fails due to directed knowledge
