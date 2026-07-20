# Deparse a Knowledge Object into Knowledge DSL Code

Given a `Knowledge` object, return a single string containing the R code
(using
[`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md),
`tier()`, `%-->%`, and `%!-->%`. that would rebuild that same object.

## Usage

``` r
deparse_knowledge(kn, df_name = NULL)
```

## Arguments

- kn:

  A `Knowledge` object.

- df_name:

  Optional name of the data frame you used (used as the first argument
  to
  [`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md)).
  If `NULL`,
  [`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md)
  is called with no data frame.

## Value

A single string (with newlines) of R code.

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
# turn a Knowledge object back into DSL code
data(tpc_example)

kn <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    old ~ starts_with("old")
  ),
  child_x1 %-->% youth_x3,
  oldage_x6 %!-->% child_x1
)

code <- deparse_knowledge(kn, df_name = "tpc_example")
cat(code)
#> knowledge(tpc_example,
#>   tier(
#>     child ~ child_x1 + child_x2,
#>     youth ~ youth_x3 + youth_x4,
#>     old ~ oldage_x5 + oldage_x6
#>   ),
#>   child_x1 %-->% youth_x3,
#>   oldage_x6 %!-->% child_x1
#> )

# Explicitly add all forbidden edges implied by tiers
kn <- convert_tiers_to_forbidden(kn)
code <- deparse_knowledge(kn, df_name = "tpc_example")
cat(code)
#> knowledge(tpc_example,
#>   child_x1 %-->% youth_x3,
#>   oldage_x5 %!-->% c(child_x1, child_x2, youth_x3, youth_x4),
#>   oldage_x6 %!-->% c(child_x1, child_x2, youth_x3, youth_x4),
#>   youth_x3 %!-->% c(child_x1, child_x2),
#>   youth_x4 %!-->% c(child_x1, child_x2)
#> )
```
