# GES Algorithm for Causal Discovery

Run the Greedy Equivalent Search algorithm for causal discovery using
one of several engines.

## Usage

``` r
ges(engine = c("tetrad", "pcalg"), score, ...)
```

## Arguments

- engine:

  Character; which engine to use. Must be one of:

  `"tetrad"`

  :   Tetrad Java library.

  `"pcalg"`

  :   pcalg R package.

- score:

  Character; name of the scoring function to use.

- ...:

  Additional arguments passed to the chosen engine (e.g. score and
  algorithm parameters).

## Details

For specific details on the supported scores, and parameters for each
engine, see:

- [TetradSearch](https://disco-coders.github.io/causalDisco/reference/TetradSearch.md)
  for Tetrad (note, Tetrad refers to it as "fges"),

- [PcalgSearch](https://disco-coders.github.io/causalDisco/reference/PcalgSearch.md)
  for pcalg.

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

Chickering, D. M. (2002). Optimal structure identification with greedy
search. Journal of Machine Learning Research 3, 507-554.

## See also

Other causal discovery algorithms:
[`boss()`](https://disco-coders.github.io/causalDisco/reference/boss.md),
[`boss_fci()`](https://disco-coders.github.io/causalDisco/reference/boss_fci.md),
[`fci()`](https://disco-coders.github.io/causalDisco/reference/fci.md),
[`gfci()`](https://disco-coders.github.io/causalDisco/reference/gfci.md),
[`grasp()`](https://disco-coders.github.io/causalDisco/reference/grasp.md),
[`grasp_fci()`](https://disco-coders.github.io/causalDisco/reference/grasp_fci.md),
[`gs()`](https://disco-coders.github.io/causalDisco/reference/gs.md),
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

#### Using pcalg engine ####
# Recommended path using disco()
ges_pcalg <- ges(engine = "pcalg", score = "sem_bic")
disco(tpc_example, ges_pcalg)
#> <Disco CPDAG: 6 nodes | 6 edges>
#>   nodes: child_x2, child_x1, youth_x4, youth_x3, oldage_x6, oldage_x5
#>   edges: child_x1---child_x2, child_x2-->oldage_x5, child_x2---youth_x4
#>          oldage_x5-->oldage_x6, youth_x3-->oldage_x5, youth_x4-->oldage_x6

# or using ges_pcalg directly
ges_pcalg(tpc_example)
#> <Disco PDAG: 6 nodes | 6 edges>
#>   nodes: child_x2, child_x1, youth_x4, youth_x3, oldage_x6, oldage_x5
#>   edges: child_x1---child_x2, child_x2-->oldage_x5, child_x2---youth_x4
#>          oldage_x5-->oldage_x6, youth_x3-->oldage_x5, youth_x4-->oldage_x6

# With all algorithm arguments specified
ges_pcalg <- ges(
  engine = "pcalg",
  score = "sem_bic",
  adaptive = "vstructures",
  phase = "forward",
  iterate = FALSE,
  maxDegree = 3,
  verbose = FALSE
)
disco(tpc_example, ges_pcalg)
#> <Disco CPDAG: 6 nodes | 6 edges>
#>   nodes: child_x2, child_x1, youth_x4, youth_x3, oldage_x6, oldage_x5
#>   edges: child_x1---child_x2, child_x2-->oldage_x5, child_x2---youth_x4
#>          oldage_x5-->oldage_x6, youth_x3-->oldage_x5, youth_x4-->oldage_x6


#### Using tetrad engine with tier knowledge ####
# Requires Tetrad to be installed
if (verify_tetrad()$installed && verify_tetrad()$java_ok) {
  kn <- knowledge(
    tpc_example,
    tier(
      child ~ tidyselect::starts_with("child"),
      youth ~ tidyselect::starts_with("youth"),
      oldage ~ tidyselect::starts_with("oldage")
    )
  )

  # Recommended path using disco()
  ges_tetrad <- ges(engine = "tetrad", score = "sem_bic")
  disco(tpc_example, ges_tetrad, knowledge = kn)

  # or using ges_tetrad directly
  ges_tetrad <- ges_tetrad |> set_knowledge(kn)
  ges_tetrad(tpc_example)
}
#> <Disco UNKNOWN: 6 nodes | 6 edges>
#>   nodes: child_x2, child_x1, youth_x4, youth_x3, oldage_x6, oldage_x5
#>   edges: child_x2---child_x1, child_x2-->oldage_x5, child_x2-->youth_x4
#>          oldage_x5-->oldage_x6, youth_x3-->oldage_x5, youth_x4-->oldage_x6

# With all algorithm arguments specified
if (verify_tetrad()$installed && verify_tetrad()$java_ok) {
  ges_tetrad <- ges(
    engine = "tetrad",
    score = "ebic",
    symmetric_first_step = TRUE,
    max_degree = 3,
    parallelized = TRUE,
    faithfulness_assumed = TRUE
  )
  disco(tpc_example, ges_tetrad)
}
#> <Disco CPDAG: 6 nodes | 6 edges>
#>   nodes: child_x2, child_x1, youth_x4, youth_x3, oldage_x6, oldage_x5
#>   edges: child_x2---child_x1, child_x2-->oldage_x5, child_x2---youth_x4
#>          oldage_x5-->oldage_x6, youth_x3-->oldage_x5, youth_x4-->oldage_x6
```
