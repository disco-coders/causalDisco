# PC Algorithm for Causal Discovery

Run the Peter-Clark algorithm for causal discovery using one of several
engines.

## Usage

``` r
pc(engine = c("tetrad", "pcalg", "bnlearn"), test, alpha = 0.05, ...)
```

## Arguments

- engine:

  Character; which engine to use. Must be one of:

  `"tetrad"`

  :   Tetrad Java library.

  `"pcalg"`

  :   pcalg R package.

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

- [TetradSearch](https://disco-coders.github.io/causalDisco/reference/TetradSearch.md)
  for Tetrad,

- [PcalgSearch](https://disco-coders.github.io/causalDisco/reference/PcalgSearch.md)
  for pcalg,

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

Spirtes P, Glymour C, and Scheines R. Causation, Prediction, and Search.
MIT Press, 2000.

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
pc_pcalg <- pc(engine = "pcalg", test = "fisher_z", alpha = 0.05)
disco(tpc_example, pc_pcalg)
#> 
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: PDAG
#> 
#> ── Edges ──
#> 
#>   from      edge  to       
#>   <chr>     <chr> <chr>    
#> 1 child_x1  ---   child_x2 
#> 2 child_x2  -->   oldage_x5
#> 3 child_x2  ---   youth_x4 
#> 4 oldage_x5 -->   oldage_x6
#> 5 youth_x3  -->   oldage_x5
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

# or using pc_pcalg directly
pc_pcalg(tpc_example)
#> 
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: PDAG
#> 
#> ── Edges ──
#> 
#>   from      edge  to       
#>   <chr>     <chr> <chr>    
#> 1 child_x1  ---   child_x2 
#> 2 child_x2  -->   oldage_x5
#> 3 child_x2  ---   youth_x4 
#> 4 oldage_x5 -->   oldage_x6
#> 5 youth_x3  -->   oldage_x5
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
pc_pcalg <- pc(
  engine = "pcalg",
  test = "fisher_z",
  alpha = 0.05,
  fixedGaps = NULL,
  fixedEdges = NULL,
  NAdelete = FALSE,
  m.max = 10,
  u2pd = "relaxed",
  skel.method = "original",
  conservative = TRUE,
  maj.rule = FALSE,
  solve.confl = TRUE,
  numCores = 1,
  verbose = FALSE
)

#### Using bnlearn engine with required knowledge ####
kn <- knowledge(
  tpc_example,
  starts_with("child") %-->% starts_with("youth")
)


# Recommended path using disco()
pc_bnlearn <- pc(engine = "bnlearn", test = "fisher_z", alpha = 0.05)
disco(tpc_example, pc_bnlearn, knowledge = kn)
#> Warning: vstructure youth_x4 -> oldage_x6 <- oldage_x5 is not applicable, because one or both arcs are oriented in the opposite direction.
#> 
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: PDAG
#> 
#> ── Edges ──
#> 
#>   from      edge  to       
#>   <chr>     <chr> <chr>    
#> 1 child_x1  ---   child_x2 
#> 2 child_x1  -->   youth_x3 
#> 3 child_x1  -->   youth_x4 
#> 4 child_x2  ---   oldage_x5
#> 5 child_x2  -->   youth_x3 
#> 6 child_x2  -->   youth_x4 
#> 7 oldage_x5 ---   oldage_x6
#> 8 oldage_x5 -->   youth_x3 
#> 9 oldage_x6 -->   youth_x4 
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
#> ── Edges ──
#> 
#>  ✔  child_x1 → youth_x3
#>  ✔  child_x1 → youth_x4
#>  ✔  child_x2 → youth_x3
#>  ✔  child_x2 → youth_x4

# or using pc_bnlearn directly
pc_bnlearn <- pc_bnlearn |> set_knowledge(kn)
pc_bnlearn(tpc_example)
#> Warning: vstructure youth_x4 -> oldage_x6 <- oldage_x5 is not applicable, because one or both arcs are oriented in the opposite direction.
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: PDAG
#> 
#> ── Edges ──
#> 
#>   from      edge  to       
#>   <chr>     <chr> <chr>    
#> 1 child_x1  ---   child_x2 
#> 2 child_x1  -->   youth_x3 
#> 3 child_x1  -->   youth_x4 
#> 4 child_x2  ---   oldage_x5
#> 5 child_x2  -->   youth_x3 
#> 6 child_x2  -->   youth_x4 
#> 7 oldage_x5 ---   oldage_x6
#> 8 oldage_x5 -->   youth_x3 
#> 9 oldage_x6 -->   youth_x4 
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
pc_bnlearn <- pc(
  engine = "bnlearn",
  test = "fisher_z",
  alpha = 0.05,
  max.sx = 2,
  debug = FALSE,
  undirected = TRUE
)

disco(tpc_example, pc_bnlearn)
#> 
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: PDAG
#> 
#> ── Edges ──
#> 
#>   from      edge  to       
#>   <chr>     <chr> <chr>    
#> 1 child_x1  ---   child_x2 
#> 2 child_x2  ---   oldage_x5
#> 3 child_x2  ---   youth_x4 
#> 4 oldage_x5 ---   oldage_x6
#> 5 oldage_x5 ---   youth_x3 
#> 6 oldage_x6 ---   youth_x4 
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
  pc_tetrad <- pc(engine = "tetrad", test = "fisher_z", alpha = 0.05)
  disco(tpc_example, pc_tetrad, knowledge = kn)

  # or using pc_tetrad directly
  pc_tetrad <- pc_tetrad |> set_knowledge(kn)
  pc_tetrad(tpc_example)
}
#> 
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: UNKNOWN
#> 
#> ── Edges ──
#> 
#>   from      edge  to       
#>   <chr>     <chr> <chr>    
#> 1 child_x2  ---   child_x1 
#> 2 child_x2  -->   oldage_x5
#> 3 child_x2  -->   youth_x4 
#> 4 oldage_x5 -->   oldage_x6
#> 5 youth_x3  -->   oldage_x5
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
  pc_tetrad <- pc(
    engine = "tetrad",
    test = "fisher_z",
    alpha = 0.05,
    conflict_rule = 2,
    depth = 10,
    stable_fas = FALSE,
    guarantee_cpdag = TRUE
  )
  disco(tpc_example, pc_tetrad)
}
#> 
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: PDAG
#> 
#> ── Edges ──
#> 
#>   from      edge  to       
#>   <chr>     <chr> <chr>    
#> 1 child_x2  ---   child_x1 
#> 2 child_x2  -->   oldage_x5
#> 3 child_x2  ---   youth_x4 
#> 4 oldage_x5 -->   oldage_x6
#> 5 youth_x3  -->   oldage_x5
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
