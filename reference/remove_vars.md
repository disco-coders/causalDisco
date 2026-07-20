# Remove Variables from Knowledge

Drops the given variables from `kn$vars`, and automatically removes any
edges that mention them.

## Usage

``` r
remove_vars(kn, ...)
```

## Arguments

- kn:

  A `Knowledge` object.

- ...:

  Unquoted variable names or tidy‐select helpers.

## Value

An updated `Knowledge` object.

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
[`reorder_tiers()`](https://disco-coders.github.io/causalDisco/reference/reorder_tiers.md),
[`reposition_tier()`](https://disco-coders.github.io/causalDisco/reference/reposition_tier.md),
[`require_edge()`](https://disco-coders.github.io/causalDisco/reference/require_edge.md),
[`seq_tiers()`](https://disco-coders.github.io/causalDisco/reference/seq_tiers.md),
[`set_knowledge()`](https://disco-coders.github.io/causalDisco/reference/set_knowledge.md),
[`unfreeze()`](https://disco-coders.github.io/causalDisco/reference/unfreeze.md)

## Examples

``` r
# remove variables and their incident edges
data(tpc_example)

kn <- knowledge(
  head(tpc_example),
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    oldage ~ starts_with("old")
  ),
  child_x1 %-->% youth_x3
)
print(kn)
#> <Knowledge: 3 tiers | 6 vars | 1 required>
#>   tier(child): child_x1, child_x2
#>   tier(youth): youth_x3, youth_x4
#>   tier(oldage): oldage_x5, oldage_x6
#>   required:
#>     child_x1-->youth_x3

kn <- remove_edge(kn, child_x1, youth_x3)
print(kn)
#> <Knowledge: 3 tiers | 6 vars>
#>   tier(child): child_x1, child_x2
#>   tier(youth): youth_x3, youth_x4
#>   tier(oldage): oldage_x5, oldage_x6

kn <- remove_vars(kn, starts_with("child_"))
print(kn)
#> <Knowledge: 3 tiers | 4 vars>
#>   tier(youth): youth_x3, youth_x4
#>   tier(oldage): oldage_x5, oldage_x6

kn <- remove_tiers(kn, "child")
print(kn)
#> <Knowledge: 2 tiers | 4 vars>
#>   tier(youth): youth_x3, youth_x4
#>   tier(oldage): oldage_x5, oldage_x6
```
