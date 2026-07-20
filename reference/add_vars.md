# Add Variables to Knowledge

Adds variables to the `Knowledge` object. If the object is frozen, an
error is thrown if any of the variables are not present in the data
frame provided to the object.

## Usage

``` r
add_vars(kn, vars)
```

## Arguments

- kn:

  A `Knowledge` object.

- vars:

  A character vector of variable names to add.

## Value

The updated `Knowledge` object.

## See also

Other knowledge helpers:
[`+.Knowledge()`](https://disco-coders.github.io/causalDisco/reference/plus-.Knowledge.md),
[`add_exogenous()`](https://disco-coders.github.io/causalDisco/reference/add_exogenous.md),
[`add_tier()`](https://disco-coders.github.io/causalDisco/reference/add_tier.md),
[`add_to_tier()`](https://disco-coders.github.io/causalDisco/reference/add_to_tier.md),
[`as_bnlearn_knowledge()`](https://disco-coders.github.io/causalDisco/reference/as_bnlearn_knowledge.md),
[`as_pcalg_constraints()`](https://disco-coders.github.io/causalDisco/reference/as_pcalg_constraints.md),
[`as_tetrad_knowledge()`](https://disco-coders.github.io/causalDisco/reference/as_tetrad_knowledge.md),
[`convert_tiers_to_forbidden()`](https://disco-coders.github.io/causalDisco/reference/convert_tiers_to_forbidden.md),
[`deparse_knowledge()`](https://disco-coders.github.io/causalDisco/reference/deparse_knowledge.md),
[`forbid_edge()`](https://disco-coders.github.io/causalDisco/reference/forbid_edge.md),
[`get_tiers()`](https://disco-coders.github.io/causalDisco/reference/get_tiers.md),
[`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md),
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

# create Knowledge object using verbs
kn1 <- knowledge() |>
  add_vars(names(tpc_example)) |>
  add_tier(child) |>
  add_tier(old, after = child) |>
  add_tier(youth, before = old) |>
  add_to_tier(child ~ starts_with("child")) |>
  add_to_tier(youth ~ starts_with("youth")) |>
  add_to_tier(old ~ starts_with("oldage")) |>
  require_edge(child_x1 ~ youth_x3) |>
  forbid_edge(child_x2 ~ youth_x4) |>
  add_exogenous(child_x1) # synonym: add_exo()

# set kn1 to frozen
# (meaning you cannot add variables to the Knowledge object anymore)
# this is to get a true on the identical check
kn1$frozen <- TRUE

# create identical Knowledge object using DSL
kn2 <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    old ~ starts_with("oldage")
  ),
  child_x1 %-->% youth_x3,
  child_x2 %!-->% youth_x4,
  exo(child_x1) # synonym: exogenous()
)

print(identical(kn1, kn2))
#> [1] TRUE

# cannot require an edge against tier direction
try(
  kn1 |> require_edge(oldage_x6 ~ child_x1)
)
#> Error : Edge(s) violate tier ordering: oldage_x6 --> child_x1

# cannot forbid and require same edge
try(
  kn1 |> forbid_edge(child_x1 ~ youth_x3)
)
#> Error : Edge(s) appear as both forbidden and required: child_x1 --> youth_x3
```
