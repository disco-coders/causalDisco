# Set a Maximum Tier Lag on Knowledge

Forbids every edge between variables that are more than `max_lag` tiers
apart, based on the tiers currently defined on `kn`.

## Usage

``` r
set_max_lag(kn, max_lag)
```

## Arguments

- kn:

  A `Knowledge` object that already has tiers defined.

- max_lag:

  A single positive integer: the maximum allowed tier distance between
  the endpoints of an edge.

## Value

The updated `Knowledge` object, with the new forbidden edges added and
`max_lag` stored on it.

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
#> <Knowledge: 3 tiers | max_lag = 1 | 6 vars | 4 forbidden>
#>   tier(child): child_x1, child_x2
#>   tier(youth): youth_x3, youth_x4
#>   tier(old): oldage_x5, oldage_x6
#>   forbidden:
#>     child_x1!-->oldage_x5 + oldage_x6
#>     child_x2!-->oldage_x5 + oldage_x6

# DSL form: max_lag() inside tier() is equivalent
kn2 <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    old ~ starts_with("oldage"),
    max_lag(1)
  )
)

print(identical(kn1, kn2))
#> [1] TRUE
```
