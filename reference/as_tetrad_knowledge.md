# Convert Knowledge to Tetrad Knowledge

Converts a `Knowledge` object to a Tetrad
`edu.cmu.tetrad.data.Knowledge`. This requires `rJava`. This is used
internally, when setting knowledge with
[`set_knowledge()`](https://disco-coders.github.io/causalDisco/reference/set_knowledge.md)
for methods using the Tetrad engine.
[`set_knowledge()`](https://disco-coders.github.io/causalDisco/reference/set_knowledge.md)
is used internally, when using the
[`disco()`](https://disco-coders.github.io/causalDisco/reference/disco.md)
function with knowledge given.

## Usage

``` r
as_tetrad_knowledge(kn)
```

## Arguments

- kn:

  A `Knowledge` object.

## Value

A Java `edu.cmu.tetrad.data.Knowledge` object.

## See also

Other knowledge helpers:
[`+.Knowledge()`](https://disco-coders.github.io/causalDisco/reference/plus-.Knowledge.md),
[`add_exogenous()`](https://disco-coders.github.io/causalDisco/reference/add_exogenous.md),
[`add_tier()`](https://disco-coders.github.io/causalDisco/reference/add_tier.md),
[`add_to_tier()`](https://disco-coders.github.io/causalDisco/reference/add_to_tier.md),
[`add_vars()`](https://disco-coders.github.io/causalDisco/reference/add_vars.md),
[`as_bnlearn_knowledge()`](https://disco-coders.github.io/causalDisco/reference/as_bnlearn_knowledge.md),
[`as_pcalg_constraints()`](https://disco-coders.github.io/causalDisco/reference/as_pcalg_constraints.md),
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
# convert to Tetrad Knowledge via rJava
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

jk <- try(as_tetrad_knowledge(kn)) # will run only if rJava/JVM available
try(print(jk)) # prints a Java reference if successful
#> [1] "Java-Object{/knowledge\naddtemporal\n\n1  child_x1 child_x2\n2  youth_x3 youth_x4\n3  oldage_x5 oldage_x6\n\nforbiddirect\n\nrequiredirect\nchild_x1 youth_x3}"
```
