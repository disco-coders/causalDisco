# Merge Knowledge Objects

Merge Knowledge Objects

## Usage

``` r
# S3 method for class 'Knowledge'
kn1 + kn2
```

## Arguments

- kn1:

  A `Knowledge` object.

- kn2:

  Another `Knowledge` object.

## See also

Other knowledge helpers:
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
# Create two Knowledge objects
kn1 <- knowledge(
  tier(
    1 ~ V1,
    2 ~ V2
  ),
  V1 %-->% V2
)

kn2 <- knowledge(
  tier(3 ~ V3),
  V2 %!-->% V3
)

kn_merged <- kn1 + kn2

# Error paths
# Merging with conflicting tier information

kn1 <- knowledge(
  tier(
    1 ~ V1,
    2 ~ V2
  )
)

kn2 <- knowledge(
  tier(3 ~ V2)
)

try(kn1 + kn2)
#> Error : Tier conflict detected for 1 variable:
#> - V2: kn1: 2, kn2: 3

kn2 <- knowledge(
  tier(1 ~ V1 + V2)
)

try(kn1 + kn2)
#> Error : Tier conflict detected for 1 variable:
#> - V2: kn1: 2, kn2: 1

# Required / forbidden violations

kn1 <- knowledge(
  V1 %!-->% V2
)

kn2 <- knowledge(
  V1 %-->% V2
)

try(kn1 + kn2)
#> Error : Edge(s) appear as both forbidden and required: V1 --> V2
```
