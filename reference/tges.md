# TGES Algorithm for Causal Discovery

Run the Temporal Greedy Equivalent Search algorithm for causal discovery
using one of several engines.

## Usage

``` r
tges(engine = c("causalDisco"), score, ...)
```

## Arguments

- engine:

  Character; which engine to use. Must be one of:

  `"causalDisco"`

  :   causalDisco library.

- score:

  Character; name of the scoring function to use.

- ...:

  Additional arguments passed to the chosen engine (e.g. test or
  algorithm parameters).

## Details

For specific details on the supported scores, see
[CausalDiscoSearch](https://disco-coders.github.io/causalDisco/reference/CausalDiscoSearch.md).
For additional parameters passed via `...`, see
[`tges_run()`](https://disco-coders.github.io/causalDisco/reference/tges_run.md).

## Recommendation

While it is possible to call the function returned directly with a data
frame, we recommend using
[`disco()`](https://disco-coders.github.io/causalDisco/reference/disco.md).
This provides a consistent interface and handles knowledge integration.

## Value

A function that takes a single argument `data` (a data frame). When
called, this function returns a list containing:

- `knowledge` A `Knowledge` object with the background knowledge used in
  the causal discovery algorithm. See
  [`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md)
  for how to construct it.

- `caugi` A [`caugi::caugi`](https://caugi.org/reference/caugi.html)
  object (of class `PDAG`) representing the learned causal graph from
  the causal discovery algorithm.

## References

Larsen TE, Ekstrøm CT, and Petersen AH. Score-Based Causal Discovery
with Temporal Background Information, 2025.
<doi:10.48550/arXiv.2502.06232>.

## See also

Other causal discovery algorithms:
[`boss()`](https://disco-coders.github.io/causalDisco/reference/boss.md),
[`boss_fci()`](https://disco-coders.github.io/causalDisco/reference/boss_fci.md),
[`fci()`](https://disco-coders.github.io/causalDisco/reference/fci.md),
[`ges()`](https://disco-coders.github.io/causalDisco/reference/ges.md),
[`gfci()`](https://disco-coders.github.io/causalDisco/reference/gfci.md),
[`grasp()`](https://disco-coders.github.io/causalDisco/reference/grasp.md),
[`grasp_fci()`](https://disco-coders.github.io/causalDisco/reference/grasp_fci.md),
[`gs()`](https://disco-coders.github.io/causalDisco/reference/gs.md),
[`iamb-family`](https://disco-coders.github.io/causalDisco/reference/iamb-family.md),
[`pc()`](https://disco-coders.github.io/causalDisco/reference/pc.md),
[`rfci()`](https://disco-coders.github.io/causalDisco/reference/rfci.md),
[`sp_fci()`](https://disco-coders.github.io/causalDisco/reference/sp_fci.md),
[`tfci()`](https://disco-coders.github.io/causalDisco/reference/tfci.md),
[`tpc()`](https://disco-coders.github.io/causalDisco/reference/tpc.md)

## Examples

``` r
# Recommended route using disco:
kn <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    old ~ starts_with("old")
  )
)

my_tges <- tges(engine = "causalDisco", score = "tbic")

disco(tpc_example, my_tges, knowledge = kn)
#> <Disco MPDAG: 6 nodes | 6 edges | Knowledge: 3 tiers>
#> Learned graph:
#>   nodes: child_x2, child_x1, youth_x4, youth_x3, oldage_x6, oldage_x5
#>   edges: child_x1---child_x2, child_x2-->oldage_x5, child_x2-->youth_x4
#>          oldage_x5-->oldage_x6, youth_x3-->oldage_x5, youth_x4-->oldage_x6
#> Knowledge:
#>   tier(child): child_x1, child_x2
#>   tier(youth): youth_x3, youth_x4
#>   tier(old): oldage_x5, oldage_x6

# another way to run it

my_tges <- my_tges |>
  set_knowledge(kn)
my_tges(tpc_example)
#> <Disco PDAG: 6 nodes | 6 edges>
#>   nodes: child_x2, child_x1, youth_x4, youth_x3, oldage_x6, oldage_x5
#>   edges: child_x1---child_x2, child_x2-->oldage_x5, child_x2-->youth_x4
#>          oldage_x5-->oldage_x6, youth_x3-->oldage_x5, youth_x4-->oldage_x6


# or you can run directly with tges_run()

data(tpc_example)

score_bic <- new(
  "TemporalBIC",
  data = tpc_example,
  nodes = colnames(tpc_example),
  knowledge = kn
)

res_bic <- tges_run(score_bic)
res_bic
#> <Disco PDAG: 6 nodes | 6 edges>
#>   nodes: child_x2, child_x1, youth_x4, youth_x3, oldage_x6, oldage_x5
#>   edges: child_x1---child_x2, child_x2-->oldage_x5, child_x2-->youth_x4
#>          oldage_x5-->oldage_x6, youth_x3-->oldage_x5, youth_x4-->oldage_x6
```
