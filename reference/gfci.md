# GFCI Algorithm for Causal Discovery

Run the Greedy Fast Causal Inference algorithm for causal discovery
using one of several engines.

## Usage

``` r
gfci(engine = "tetrad", score, test, alpha = 0.05, ...)
```

## Arguments

- engine:

  Character; which engine to use. Must be one of:

  `"tetrad"`

  :   Tetrad Java library.

- score:

  Character; name of the scoring function to use.

- test:

  Character; name of the conditional‐independence test.

- alpha:

  Numeric; significance level for the CI tests.

- ...:

  Additional arguments passed to the chosen engine (e.g. score and
  algorithm parameters).

## Details

For specific details on the supported scores, and parameters for each
engine, see:

- [TetradSearch](https://disco-coders.github.io/causalDisco/reference/TetradSearch.md)
  for Tetrad.

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
  object representing the learned causal graph. This graph is a PAG
  (Partial Ancestral Graph), but since PAGs are not yet natively
  supported in caugi, it is currently stored with class `UNKNOWN`.

## References

Ogarrio, J. M., Spirtes, P., and Ramsey, J. (2016). A hybrid causal
search algorithm for latent variable models. In Conference on
probabilistic graphical models, pages 368–379. PMLR.

## See also

Other causal discovery algorithms:
[`boss()`](https://disco-coders.github.io/causalDisco/reference/boss.md),
[`boss_fci()`](https://disco-coders.github.io/causalDisco/reference/boss_fci.md),
[`fci()`](https://disco-coders.github.io/causalDisco/reference/fci.md),
[`ges()`](https://disco-coders.github.io/causalDisco/reference/ges.md),
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
data(num_data)

# Requires Tetrad to be installed
if (verify_tetrad()$installed && verify_tetrad()$java_ok) {
  # Recommended path using disco()
  gfci_tetrad <- gfci(
    engine = "tetrad",
    score = "sem_bic",
    test = "fisher_z"
  )
  disco(tpc_example, gfci_tetrad)

  # or using gfci_tetrad directly
  gfci_tetrad(tpc_example)
}
#> <Disco UNKNOWN: 6 nodes | 6 edges>
#>   nodes: child_x2, child_x1, youth_x4, youth_x3, oldage_x6, oldage_x5
#>   edges: child_x2o-ochild_x1, child_x2o->oldage_x5, child_x2o-oyouth_x4
#>          oldage_x5-->oldage_x6, youth_x3o->oldage_x5, youth_x4-->oldage_x6

#### With tier knowledge ####
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
  gfci_tetrad <- gfci(
    engine = "tetrad",
    score = "sem_bic",
    test = "fisher_z"
  )
  disco(tpc_example, gfci_tetrad, knowledge = kn)

  # or using gfci_tetrad directly
  gfci_tetrad <- gfci_tetrad |> set_knowledge(kn)
  gfci_tetrad(tpc_example)
}
#> <Disco UNKNOWN: 6 nodes | 6 edges>
#>   nodes: child_x2, child_x1, youth_x4, youth_x3, oldage_x6, oldage_x5
#>   edges: child_x2o-ochild_x1, child_x2o->oldage_x5, child_x2o-oyouth_x4
#>          oldage_x5-->oldage_x6, youth_x3o->oldage_x5, youth_x4-->oldage_x6

# With all algorithm arguments specified
if (verify_tetrad()$installed && verify_tetrad()$java_ok) {
  gfci_tetrad <- gfci(
    engine = "tetrad",
    score = "poisson_prior",
    test = "rank_independence",
    depth = 3,
    max_degree = 2,
    max_disc_path_length = 5,
    use_heuristic = FALSE,
    complete_rule_set_used = FALSE,
    guarantee_pag = TRUE,
    start_complete = TRUE,
    num_threads = 2,
    verbose = TRUE
  )
  disco(num_data, gfci_tetrad)
}
#> <Disco UNKNOWN: 5 nodes | 0 edges>
#>   nodes: X1, X2, X3, Z, Y
```
