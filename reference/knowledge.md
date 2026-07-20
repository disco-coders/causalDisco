# Define Background Knowledge

Constructs a `Knowledge` object optionally initialized with a data frame
and extended with variable relationships expressed via formulas,
selectors, or infix operators:

    tier(1 ~ V1 + V2, exposure ~ E)
    V1 %-->% V3    # infix syntax for required edge from V1 to V3
    V2 %!-->% V3    # infix syntax for an edge from V2 to V3 that is forbidden
    exogenous(V1, V2)

## Usage

``` r
knowledge(...)
```

## Arguments

- ...:

  Arguments to define the `Knowledge` object:

  - Optionally, a single data frame (first argument) whose column names
    initialize and freeze the variable set.

  - Zero or more mini-DSL calls: `tier()`, `exogenous()`, (shorthand
    `exo()`), or infix operators `%-->%`, `%!-->%`.

    - `tier()`: One or more two-sided formulas (`tier(1 ~ x + y)`), or a
      numeric vector.

    - `exogenous()` / `exo()`: Variable names or tidyselect selectors.
      Arguments are evaluated in order; only these calls are allowed.

## Value

A populated `Knowledge` object.

## Details

Create a `Knowledge` object using a concise mini-DSL with `tier()`,
`exogenous()` and infix edge operators `%-->%` and `%!-->%`.

The first argument can be a data frame, which will be used to populate
the `Knowledge` object with variable names. Supplying a data frame also
gives tidyselect helpers (e.g.
[`tidyselect::starts_with()`](https://tidyselect.r-lib.org/reference/starts_with.html)),
a set of column names to resolve against, so they can be used throughout
the mini-DSL, for example `tier(1 ~ starts_with("V"))` or
`everything() %-->% Y`. If you later add variables with `add_*` verbs,
this will throw a warning, since the `Knowledge` object will be
*frozen*. You can unfreeze a `Knowledge` object by using the function
[`unfreeze()`](https://disco-coders.github.io/causalDisco/reference/unfreeze.md).

If no data frame is provided, the object is initially empty. Variables
can then be added via `tier()`, `forbidden()`, `required()`, infix
operators, or
[`add_vars()`](https://disco-coders.github.io/causalDisco/reference/add_vars.md).

- `tier()`: Assigns variables to tiers. Tiers may be numeric or string
  labels. The left-hand side (LHS) of the formula is the tier; the
  right-hand side (RHS) specifies variables. Variables can also be
  selected using tidyselect syntax: `tier(1 ~ starts_with("V"))`.

- `%-->%` and `%!-->%`: Infix operators to define required and forbidden
  edges, respectively. Both sides of the operator can use tidyselect
  syntax to select multiple variables.

- `exogenous()` / `exo()`: Mark variables as exogenous.

- Numeric vector shortcut for `tier()`: `tier(c(1, 2, 1))` assigns tiers
  by index to all existing variables.

Multiple calls or operators are additive: each call adds new edges to
the `Knowledge` object. For example:

    V1 %-->% V3
    V2 %-->% V3

results in both edges being required - i.e., the union of all specified
required edges.

## See also

Other knowledge helpers:
[`+.Knowledge()`](https://disco-coders.github.io/causalDisco/reference/plus-.Knowledge.md),
[`add_exogenous()`](https://disco-coders.github.io/causalDisco/reference/add_exogenous.md),
[`add_tier()`](https://disco-coders.github.io/causalDisco/reference/add_tier.md),
[`add_to_tier()`](https://disco-coders.github.io/causalDisco/reference/add_to_tier.md),
[`add_vars()`](https://disco-coders.github.io/causalDisco/reference/add_vars.md),
[`as_bnlearn_knowledge()`](https://disco-coders.github.io/causalDisco/reference/as_bnlearn_knowledge.md),
[`as_pcalg_constraints()`](https://disco-coders.github.io/causalDisco/reference/as_pcalg_constraints.md),
[`as_tetrad_knowledge()`](https://disco-coders.github.io/causalDisco/reference/as_tetrad_knowledge.md),
[`convert_tiers_to_forbidden()`](https://disco-coders.github.io/causalDisco/reference/convert_tiers_to_forbidden.md),
[`deparse_knowledge()`](https://disco-coders.github.io/causalDisco/reference/deparse_knowledge.md),
[`forbid_edge()`](https://disco-coders.github.io/causalDisco/reference/forbid_edge.md),
[`get_tiers()`](https://disco-coders.github.io/causalDisco/reference/get_tiers.md),
[`knowledge_to_caugi()`](https://disco-coders.github.io/causalDisco/reference/knowledge_to_caugi.md),
[`remove_edge()`](https://disco-coders.github.io/causalDisco/reference/remove_edge.md),
[`remove_tiers()`](https://disco-coders.github.io/causalDisco/reference/remove_tiers.md),
[`remove_vars()`](https://disco-coders.github.io/causalDisco/reference/remove_vars.md),
[`reorder_tiers()`](https://disco-coders.github.io/causalDisco/reference/reorder_tiers.md),
[`reposition_tier()`](https://disco-coders.github.io/causalDisco/reference/reposition_tier.md),
[`require_edge()`](https://disco-coders.github.io/causalDisco/reference/require_edge.md),
[`seq_tiers()`](https://disco-coders.github.io/causalDisco/reference/seq_tiers.md),
[`set_knowledge()`](https://disco-coders.github.io/causalDisco/reference/set_knowledge.md),
[`unfreeze()`](https://disco-coders.github.io/causalDisco/reference/unfreeze.md)

## Examples

``` r
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
#> Error : Unknown variable(s): [woops]
#> They are not present in the data frame provided to this Knowledge object.

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
```
