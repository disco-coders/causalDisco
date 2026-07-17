data(tpc_example)

# Knowledge objects can contain tier information, forbidden and required edges
kn <- knowledge(
  tier(
    1 ~ V1 + V2,
    2 ~ V3
  ),
  V1 %-->% V2,
  V3 %!-->% V1
)

# If a data frame is provided, variable names are checked against it
kn <- knowledge(
  tpc_example,
  tier(
    1 ~ child_x1 + child_x2,
    2 ~ youth_x3 + youth_x4,
    3 ~ oldage_x5 + oldage_x6
  )
)

# Throws error if variable not in data
try(
  knowledge(
    tpc_example,
    tier(
      1 ~ child_x1 + child_x2,
      2 ~ youth_x3 + youth_x4,
      3 ~ oldage_x5 + woops
    )
  )
)

# Using tidyselect helpers
kn <- knowledge(
  tpc_example,
  tier(
    1 ~ starts_with("child"),
    2 ~ ends_with(c("_x3", "_x4")),
    3 ~ starts_with("oldage")
  )
)

# Numeric vector shortcut
kn <- knowledge(
  tpc_example,
  tier(c(1, 1, 2, 2, 3, 3))
)

# Custom tier naming
kn <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    elderly ~ starts_with("oldage")
  )
)

# There is also required and forbidden edges, which are specified like so
kn <- knowledge(
  tpc_example,
  child_x1 %-->% youth_x3,
  oldage_x6 %!-->% child_x1
)

# Both sides of an edge operator accept tidyselect helpers, so a set of edges
# can be specified at once. Here every "child" variable is forbidden from
# pointing to every "youth" variable.
kn <- knowledge(
  tpc_example,
  starts_with("child") %!-->% starts_with("youth")
)

# tidyselect set operations such as `!` (negation) and `&` (intersection)
# also work. Forbid edges from child_x1 to every variable that is not a
# "child" variable.
kn <- knowledge(
  tpc_example,
  child_x1 %!-->% !starts_with("child")
)

# You can also add exogenous variables
kn <- knowledge(
  tpc_example,
  exogenous(child_x1),
  exo(child_x2) # shorthand
)

# Mix different operators
kn <- knowledge(
  tpc_example,
  tier(
    1 ~ starts_with("child") + youth_x4,
    2 ~ youth_x3 + starts_with("oldage")
  ),
  child_x1 %-->% youth_x3,
  oldage_x6 %!-->% oldage_x5,
  exo(child_x2)
)

# You can also build knowledge with a verb pipeline
kn <-
  knowledge() |>
  add_vars(c("A", "B", "C", "D")) |> # Knowledge now only takes these variables
  add_tier(One) |>
  add_to_tier(One ~ A + B) |>
  add_tier(2, after = One) |>
  add_to_tier(2 ~ C + D) |>
  forbid_edge(A ~ C) |>
  require_edge(A ~ B)

# Mix DSL start + verb refinement
kn <-
  knowledge(
    tier(1 ~ V5, 2 ~ V6),
    V5 %!-->% V6
  ) |>
  add_tier(3, after = "2") |>
  add_to_tier(3 ~ V7) |>
  add_exo(V2) |>
  add_exogenous(V3)

# Using seq_tiers for larger datasets
large_data <- as.data.frame(
  matrix(
    runif(100),
    nrow = 1,
    ncol = 100,
    byrow = TRUE
  )
)

names(large_data) <- paste0("X_", 1:100)

kn <- knowledge(
  large_data,
  tier(
    seq_tiers(
      1:100,
      ends_with("_{i}")
    )
  ),
  X_1 %-->% X_2
)

small_data <- data.frame(
  X_1 = 1,
  X_2 = 2,
  tier3_A = 3,
  Y5_ok = 4,
  check.names = FALSE
)

kn <- knowledge(
  small_data,
  tier(
    seq_tiers(1:2, ends_with("_{i}")),
    seq_tiers(3, starts_with("tier{i}")),
    seq_tiers(5, matches("Y{i}_ok"))
  )
)
