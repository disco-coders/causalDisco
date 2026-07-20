# Convert Knowledge to pcalg Knowledge

pcalg only supports *undirected* (symmetric) background constraints:

- **fixed_gaps** - forbidding edges (zeros enforced)

## Usage

``` r
as_pcalg_constraints(
  kn,
  labels = kn$vars$var,
  directed_as_undirected = lifecycle::deprecated()
)
```

## Arguments

- kn:

  A `Knowledge` object. Must have no tier information.

- labels:

  Character vector of all variable names, in the exact order of your
  data columns. Every variable referenced by an edge in `kn` must appear
  here.

- directed_as_undirected:

  **\[deprecated\]** This argument no longer has any effect and will be
  removed in a future release. Specify directed edges in both directions
  in
  [`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md)
  instead.

## Value

A list with one element, `fixed_gaps`: an `n × n` logical matrix
corresponding to the pcalg `fixedGaps` argument.

## Details

This function takes a `Knowledge` object (with only forbidden edges, no
tiers) and returns the logical constraint matrix in the exact variable
order you supply.

Required edges in a `Knowledge` object are directed statements. pcalg
constraints are adjacency-level only, so a required edge cannot be
honored; any required edges are dropped with a warning.

## Errors

- If the `Knowledge` object contains tiered knowledge.

- If any forbidden edge lacks its symmetrical counterpart.

## See also

Other knowledge functions:
[`+.Knowledge()`](https://disco-coders.github.io/causalDisco/reference/plus-.Knowledge.md),
[`add_exogenous()`](https://disco-coders.github.io/causalDisco/reference/add_exogenous.md),
[`add_tier()`](https://disco-coders.github.io/causalDisco/reference/add_tier.md),
[`add_to_tier()`](https://disco-coders.github.io/causalDisco/reference/add_to_tier.md),
[`add_vars()`](https://disco-coders.github.io/causalDisco/reference/add_vars.md),
[`as_bnlearn_knowledge()`](https://disco-coders.github.io/causalDisco/reference/as_bnlearn_knowledge.md),
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
[`unfreeze()`](https://disco-coders.github.io/causalDisco/reference/unfreeze.md)

## Examples

``` r
# pcalg supports undirected constraints; build a tierless knowledge and convert
data(tpc_example)

kn <- knowledge(
  tpc_example,
  child_x1 %!-->% youth_x3,
  youth_x3 %!-->% child_x1
)

pc_constraints <- as_pcalg_constraints(kn)
print(pc_constraints)
#> $fixed_gaps
#>           child_x1 child_x2 oldage_x5 oldage_x6 youth_x3 youth_x4
#> child_x1     FALSE    FALSE     FALSE     FALSE     TRUE    FALSE
#> child_x2     FALSE    FALSE     FALSE     FALSE    FALSE    FALSE
#> oldage_x5    FALSE    FALSE     FALSE     FALSE    FALSE    FALSE
#> oldage_x6    FALSE    FALSE     FALSE     FALSE    FALSE    FALSE
#> youth_x3      TRUE    FALSE     FALSE     FALSE    FALSE    FALSE
#> youth_x4     FALSE    FALSE     FALSE     FALSE    FALSE    FALSE
#> 

# error paths
# using tiers
kn <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    oldage ~ starts_with("old")
  ),
  child_x1 %-->% youth_x3
)

try(as_pcalg_constraints(kn), silent = TRUE) # fails due to tiers

# using directed knowledge
kn <- knowledge(
  tpc_example,
  child_x1 %!-->% youth_x3
)

try(as_pcalg_constraints(kn), silent = TRUE) # fails due to directed knowledge
```
