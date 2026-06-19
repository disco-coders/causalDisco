# Unfreeze a Knowledge Object.

This allows you to add new variables to the `Knowledge` object, even
though it was frozen earlier by adding a data frame to the knowledge
constructor
[`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md).

## Usage

``` r
unfreeze(kn)
```

## Arguments

- kn:

  A `Knowledge` object.

## Value

The same `Knowledge` object with the `frozen` attribute set to `FALSE`.

## See also

Other knowledge functions:
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
[`seq_tiers()`](https://disco-coders.github.io/causalDisco/reference/seq_tiers.md)

## Examples

``` r
# unfreeze allows adding variables beyond the original data frame columns
data(tpc_example)

kn <- knowledge(tpc_example)

# this would error while frozen
try(add_vars(kn, "new_var"))
#> Error : Unknown variable(s): [new_var]
#> They are not present in the data frame provided to this Knowledge object.

# unfreeze and add the new variable successfully
kn <- unfreeze(kn)
kn <- add_vars(kn, "new_var")

print(kn)
#> 
#> ── Knowledge object ────────────────────────────────────────────────────────────
#> 
#> ── Variables ──
#> 
#>   var       tier 
#>   <chr>     <chr>
#> 1 child_x1  NA   
#> 2 child_x2  NA   
#> 3 oldage_x5 NA   
#> 4 oldage_x6 NA   
#> 5 youth_x3  NA   
#> 6 youth_x4  NA   
#> 7 new_var   NA   
```
