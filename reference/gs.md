# GS Algorithm for Causal Discovery

Run the Grow-Shrink algorithm for causal discovery using one of several
engines.

## Usage

``` r
gs(engine = c("bnlearn"), test, alpha = 0.05, ...)
```

## Arguments

- engine:

  Character; which engine to use. Must be one of:

  `"bnlearn"`

  :   bnlearn R package.

- test:

  Character; name of the conditional‐independence test.

- alpha:

  Numeric; significance level for the CI tests.

- ...:

  Additional arguments passed to the chosen engine (e.g. test or
  algorithm parameters).

## Details

For specific details on the supported tests and parameters for each
engine, see:

- [BnlearnSearch](https://disco-coders.github.io/causalDisco/reference/BnlearnSearch.md)
  for bnlearn.

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

Margaritis, D., Thrun, S.: Bayesian network induction via local
neighborhoods. Tech. rep., DTIC Document (2000).

## See also

Other causal discovery algorithms:
[`boss()`](https://disco-coders.github.io/causalDisco/reference/boss.md),
[`boss_fci()`](https://disco-coders.github.io/causalDisco/reference/boss_fci.md),
[`fci()`](https://disco-coders.github.io/causalDisco/reference/fci.md),
[`ges()`](https://disco-coders.github.io/causalDisco/reference/ges.md),
[`gfci()`](https://disco-coders.github.io/causalDisco/reference/gfci.md),
[`grasp()`](https://disco-coders.github.io/causalDisco/reference/grasp.md),
[`grasp_fci()`](https://disco-coders.github.io/causalDisco/reference/grasp_fci.md),
[`iamb-family`](https://disco-coders.github.io/causalDisco/reference/iamb-family.md),
[`pc()`](https://disco-coders.github.io/causalDisco/reference/pc.md),
[`rfci()`](https://disco-coders.github.io/causalDisco/reference/rfci.md),
[`sp_fci()`](https://disco-coders.github.io/causalDisco/reference/sp_fci.md),
[`tfci()`](https://disco-coders.github.io/causalDisco/reference/tfci.md),
[`tges()`](https://disco-coders.github.io/causalDisco/reference/tges.md),
[`tpc()`](https://disco-coders.github.io/causalDisco/reference/tpc.md)

## Examples

``` r
data(tpc_example)

kn <- knowledge(
  tpc_example,
  starts_with("child") %-->% starts_with("youth")
)


# Recommended path using disco()
gs_bnlearn <- gs(
  engine = "bnlearn",
  test = "fisher_z",
  alpha = 0.05
)
disco(tpc_example, gs_bnlearn, knowledge = kn)
#> <Disco PDAG: 6 nodes | 9 edges | Knowledge: 4 required>
#> Learned graph:
#>   nodes: child_x2, child_x1, youth_x4, youth_x3, oldage_x6, oldage_x5
#>   edges: child_x1---child_x2, child_x1-->youth_x3, child_x1-->youth_x4
#>          child_x2-->oldage_x5, child_x2-->youth_x3, child_x2-->youth_x4
#>          oldage_x5-->oldage_x6, youth_x3-->oldage_x5, youth_x4-->oldage_x6
#> Knowledge:
#>   vars: child_x1, child_x2, oldage_x5, oldage_x6, youth_x3, youth_x4
#>   child_x1 %-->% youth_x3 + youth_x4
#>   child_x2 %-->% youth_x3 + youth_x4

# or using gs_bnlearn directly
gs_bnlearn <- gs_bnlearn |> set_knowledge(kn)
gs_bnlearn(tpc_example)
#> <Disco PDAG: 6 nodes | 9 edges>
#>   nodes: child_x2, child_x1, youth_x4, youth_x3, oldage_x6, oldage_x5
#>   edges: child_x1---child_x2, child_x1-->youth_x3, child_x1-->youth_x4
#>          child_x2-->oldage_x5, child_x2-->youth_x3, child_x2-->youth_x4
#>          oldage_x5-->oldage_x6, youth_x3-->oldage_x5, youth_x4-->oldage_x6


# With all algorithm arguments specified
gs_bnlearn <- gs(
  engine = "bnlearn",
  test = "fisher_z",
  alpha = 0.05,
  max.sx = 2,
  debug = FALSE,
  undirected = TRUE
)

disco(tpc_example, gs_bnlearn)
#> <Disco PDAG: 6 nodes | 5 edges>
#>   nodes: child_x2, child_x1, youth_x4, youth_x3, oldage_x6, oldage_x5
#>   edges: child_x1---child_x2, child_x2---oldage_x6, child_x2---youth_x4
#>          oldage_x6---youth_x3, oldage_x6---youth_x4
```
