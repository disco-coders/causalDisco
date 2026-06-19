# RFCI Algorithm for Causal Discovery

Run the Really Fast Causal Inference algorithm for causal discovery
using one of several engines.

## Usage

``` r
rfci(engine = c("tetrad", "pcalg"), test, alpha = 0.05, ...)
```

## Arguments

- engine:

  Character; which engine to use. Must be one of:

  `"tetrad"`

  :   Tetrad Java library.

  `"pcalg"`

  :   pcalg R package.

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

- [TetradSearch](https://disco-coders.github.io/causalDisco/reference/TetradSearch.md)
  for Tetrad,

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
  object representing the learned causal graph. This graph is an
  RFCI-PAG (RFCI Partial Ancestral Graph), but since RFCI-PAGs are not
  yet natively supported in caugi, it is currently stored with class
  `UNKNOWN`.

Please see the definition 3.2 of the paper referenced for definition of
an RFCI-PAG, and it's differences from a standard PAG.

## References

Colombo, D., Maathuis, M. H., Kalisch, M., & Richardson, T. S. (2012).
Learning high-dimensional directed acyclic graphs with latent and
selection variables. The Annals of Statistics, 294-321.

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
[`sp_fci()`](https://disco-coders.github.io/causalDisco/reference/sp_fci.md),
[`tfci()`](https://disco-coders.github.io/causalDisco/reference/tfci.md),
[`tges()`](https://disco-coders.github.io/causalDisco/reference/tges.md),
[`tpc()`](https://disco-coders.github.io/causalDisco/reference/tpc.md)

## Examples

``` r
data(tpc_example)

# Recommended path using disco()
rfci_pcalg <- rfci(engine = "pcalg", test = "fisher_z", alpha = 0.05)
disco(tpc_example, rfci_pcalg)
#> 
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: UNKNOWN
#> 
#> ── Edges ──
#> 
#>   from      edge  to       
#>   <chr>     <chr> <chr>    
#> 1 child_x2  o-o   child_x1 
#> 2 child_x2  o->   oldage_x5
#> 3 child_x2  o-o   youth_x4 
#> 4 oldage_x5 -->   oldage_x6
#> 5 youth_x3  o->   oldage_x5
#> 6 youth_x4  -->   oldage_x6
#> ── Nodes ──
#> 
#>   name     
#>   <chr>    
#> 1 child_x2 
#> 2 child_x1 
#> 3 youth_x4 
#> 4 youth_x3 
#> 5 oldage_x6
#> 6 oldage_x5
#> ── Knowledge object ────────────────────────────────────────────────────────────

# or using rfci_pcalg directly
rfci_pcalg(tpc_example)
#> 
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: UNKNOWN
#> 
#> ── Edges ──
#> 
#>   from      edge  to       
#>   <chr>     <chr> <chr>    
#> 1 child_x2  o-o   child_x1 
#> 2 child_x2  o->   oldage_x5
#> 3 child_x2  o-o   youth_x4 
#> 4 oldage_x5 -->   oldage_x6
#> 5 youth_x3  o->   oldage_x5
#> 6 youth_x4  -->   oldage_x6
#> ── Nodes ──
#> 
#>   name     
#>   <chr>    
#> 1 child_x2 
#> 2 child_x1 
#> 3 youth_x4 
#> 4 youth_x3 
#> 5 oldage_x6
#> 6 oldage_x5
#> ── Knowledge object ────────────────────────────────────────────────────────────

# With all algorithm arguments specified
rfci_pcalg <- rfci(
  engine = "pcalg",
  test = "fisher_z",
  alpha = 0.05,
  skel.method = "original",
  fixedGaps = NULL,
  fixedEdges = NULL,
  NAdelete = FALSE,
  m.max = 10,
  rules = c(rep(TRUE, 9), FALSE),
  conservative = TRUE,
  maj.rule = FALSE,
  numCores = 1,
  verbose = FALSE
)
disco(tpc_example, rfci_pcalg)
#> 
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: UNKNOWN
#> 
#> ── Edges ──
#> 
#>   from      edge  to       
#>   <chr>     <chr> <chr>    
#> 1 child_x2  o-o   child_x1 
#> 2 child_x2  o->   oldage_x5
#> 3 child_x2  o-o   youth_x4 
#> 4 oldage_x5 -->   oldage_x6
#> 5 youth_x3  o->   oldage_x5
#> 6 youth_x4  -->   oldage_x6
#> ── Nodes ──
#> 
#>   name     
#>   <chr>    
#> 1 child_x2 
#> 2 child_x1 
#> 3 youth_x4 
#> 4 youth_x3 
#> 5 oldage_x6
#> 6 oldage_x5
#> ── Knowledge object ────────────────────────────────────────────────────────────

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
  rfci_tetrad <- rfci(engine = "tetrad", test = "fisher_z", alpha = 0.05)
  disco(tpc_example, rfci_tetrad, knowledge = kn)

  # or using rfci_tetrad directly
  rfci_tetrad <- rfci_tetrad |> set_knowledge(kn)
  rfci_tetrad(tpc_example)
}
#> 
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: UNKNOWN
#> 
#> ── Edges ──
#> 
#>   from      edge  to       
#>   <chr>     <chr> <chr>    
#> 1 child_x2  o-o   child_x1 
#> 2 child_x2  o->   oldage_x5
#> 3 child_x2  o-o   youth_x4 
#> 4 oldage_x5 -->   oldage_x6
#> 5 youth_x3  o->   oldage_x5
#> 6 youth_x4  -->   oldage_x6
#> ── Nodes ──
#> 
#>   name     
#>   <chr>    
#> 1 child_x2 
#> 2 child_x1 
#> 3 youth_x4 
#> 4 youth_x3 
#> 5 oldage_x6
#> 6 oldage_x5
#> ── Knowledge object ────────────────────────────────────────────────────────────

# With all algorithm arguments specified
if (verify_tetrad()$installed && verify_tetrad()$java_ok) {
  rfci_tetrad <- rfci(
    engine = "tetrad",
    test = "fisher_z",
    alpha = 0.05,
    depth = 10,
    stable_fas = FALSE,
    max_disc_path_length = 2,
    complete_rule_set_used = TRUE
  )
  disco(tpc_example, rfci_tetrad)
}
#> 
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: UNKNOWN
#> 
#> ── Edges ──
#> 
#>   from      edge  to       
#>   <chr>     <chr> <chr>    
#> 1 child_x2  o-o   child_x1 
#> 2 child_x2  o->   oldage_x5
#> 3 child_x2  o-o   youth_x4 
#> 4 oldage_x5 -->   oldage_x6
#> 5 youth_x3  o->   oldage_x5
#> 6 youth_x4  -->   oldage_x6
#> ── Nodes ──
#> 
#>   name     
#>   <chr>    
#> 1 child_x2 
#> 2 child_x1 
#> 3 youth_x4 
#> 4 youth_x3 
#> 5 oldage_x6
#> 6 oldage_x5
#> ── Knowledge object ────────────────────────────────────────────────────────────
```
