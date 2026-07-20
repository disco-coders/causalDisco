# Convert Tiered Knowledge to Forbidden Knowledge

Converts tier assignments into forbidden edges, and drops tiers in the
output.

## Usage

``` r
convert_tiers_to_forbidden(kn)
```

## Arguments

- kn:

  A `Knowledge` object.

## Value

A `Knowledge` object with forbidden edges added, tiers removed.

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
kn <- knowledge(
 tpc_example,
 tier(
  child ~ starts_with("child"),
  youth ~ starts_with("youth"),
  old ~ starts_with("old")
 )
)
kn_converted <- convert_tiers_to_forbidden(kn)
print(kn_converted)
#> <Knowledge: 6 vars | 12 forbidden>
#>   vars: child_x1, child_x2, youth_x3, youth_x4, oldage_x5, oldage_x6
#>   forbidden:
#>     oldage_x5!-->child_x1 + child_x2 + youth_x3 + youth_x4
#>     oldage_x6!-->child_x1 + child_x2 + youth_x3 + youth_x4
#>     youth_x3!-->child_x1 + child_x2
#>     youth_x4!-->child_x1 + child_x2
plot(kn_converted)

```
