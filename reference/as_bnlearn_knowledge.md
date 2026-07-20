# Convert Knowledge to bnlearn Knowledge

Converts a `Knowledge` object to a list of two data frames, namely
`whitelist` and `blacklist`, which can be used as arguments for bnlearn
algorithms. The `whitelist` contains all required edges, and the
`blacklist` contains all forbidden edges. Tiers will be made into
forbidden edges before running the conversion.

## Usage

``` r
as_bnlearn_knowledge(kn)
```

## Arguments

- kn:

  A `Knowledge` object. Must have no tier information.

## Value

A list with two elements, `whitelist` and `blacklist`, each a data frame
containing the edges in a `from`, `to` format.

## See also

Other knowledge helpers:
[`+.Knowledge()`](https://disco-coders.github.io/causalDisco/reference/plus-.Knowledge.md),
[`add_exogenous()`](https://disco-coders.github.io/causalDisco/reference/add_exogenous.md),
[`add_tier()`](https://disco-coders.github.io/causalDisco/reference/add_tier.md),
[`add_to_tier()`](https://disco-coders.github.io/causalDisco/reference/add_to_tier.md),
[`add_vars()`](https://disco-coders.github.io/causalDisco/reference/add_vars.md),
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
# produce whitelist/blacklist data frame for bnlearn
data(tpc_example)

kn <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    oldage ~ starts_with("old")
  ),
  child_x1 %-->% youth_x3
)

bnlearn_kn <- as_bnlearn_knowledge(kn)
print(bnlearn_kn)
#> $whitelist
#>       from       to
#> 1 child_x1 youth_x3
#> 
#> $blacklist
#>         from       to
#> 1  oldage_x5 child_x1
#> 2  oldage_x5 child_x2
#> 3  oldage_x5 youth_x3
#> 4  oldage_x5 youth_x4
#> 5  oldage_x6 child_x1
#> 6  oldage_x6 child_x2
#> 7  oldage_x6 youth_x3
#> 8  oldage_x6 youth_x4
#> 9   youth_x3 child_x1
#> 10  youth_x3 child_x2
#> 11  youth_x4 child_x1
#> 12  youth_x4 child_x2
#> 
```
