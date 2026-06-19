# IAMB Family of Causal Discovery Algorithms

Functions for causal discovery using variants of the Incremental
Association algorithm:

- `iamb`: Incremental Association (IAMB)

- `inter_iamb`: Interleaved Incremental Association (Inter-IAMB)

- `iamb_fdr`: Incremental Association with FDR (IAMB-FDR)

- `fast_iamb`: Fast Incremental Association (Fast-IAMB)

## Usage

``` r
iamb(engine = c("bnlearn"), test, alpha = 0.05, ...)

iamb_fdr(engine = c("bnlearn"), test, alpha = 0.05, ...)

fast_iamb(engine = c("bnlearn"), test, alpha = 0.05, ...)

inter_iamb(engine = c("bnlearn"), test, alpha = 0.05, ...)
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

  Additional arguments passed to the chosen engine (e.g., test or
  algorithm parameters).

## Details

Each function supports the same engines and parameters. For details on
tests and parameters for each engine, see:

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
  object representing the learned causal graph. This graph is a PAG
  (Partial Ancestral Graph), but since PAGs are not yet natively
  supported in caugi, it is currently stored with class `UNKNOWN`.

## References

I. Tsamardinos, C. F. Aliferis, and A. Statnikov. Algorithms for large
scale Markov blanket discovery. In Proceedings of the Sixteenth
International Florida Artificial Intelligence Research Society
Conference, pages 376-381. AAAI Press, 2003.

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

##### iamb #####

# Recommended path using disco()
iamb_bnlearn <- iamb(engine = "bnlearn", test = "fisher_z", alpha = 0.05)
disco(tpc_example, iamb_bnlearn, knowledge = kn)
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
#> 4 child_x2  -->   oldage_x5
#> 5 child_x2  -->   youth_x3 
#> 6 child_x2  -->   youth_x4 
#> 7 oldage_x5 -->   oldage_x6
#> 8 youth_x3  -->   oldage_x5
#> 9 youth_x4  -->   oldage_x6
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

# or using iamb_bnlearn directly
iamb_bnlearn <- iamb_bnlearn |> set_knowledge(kn)
iamb_bnlearn(tpc_example)
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
#> 4 child_x2  -->   oldage_x5
#> 5 child_x2  -->   youth_x3 
#> 6 child_x2  -->   youth_x4 
#> 7 oldage_x5 -->   oldage_x6
#> 8 youth_x3  -->   oldage_x5
#> 9 youth_x4  -->   oldage_x6
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
iamb_bnlearn <- iamb(
  engine = "bnlearn",
  test = "fisher_z",
  alpha = 0.05,
  max.sx = 2,
  debug = FALSE,
  undirected = TRUE
)

disco(tpc_example, iamb_bnlearn)
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
#> 3 oldage_x5 ---   oldage_x6
#> 4 oldage_x5 ---   youth_x3 
#> 5 oldage_x6 ---   youth_x4 
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

##### iamb_fdr #####

iamb_fdr_bnlearn <- iamb_fdr(
  engine = "bnlearn",
  test = "fisher_z",
  alpha = 0.05
)
disco(tpc_example, iamb_fdr_bnlearn, knowledge = kn)
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
#> 4 child_x2  -->   oldage_x5
#> 5 child_x2  -->   youth_x3 
#> 6 child_x2  -->   youth_x4 
#> 7 oldage_x5 -->   oldage_x6
#> 8 youth_x3  -->   oldage_x5
#> 9 youth_x4  -->   oldage_x6
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

##### fast_iamb #####

fast_iamb_bnlearn <- fast_iamb(
  engine = "bnlearn",
  test = "fisher_z",
  alpha = 0.05
)
disco(tpc_example, fast_iamb_bnlearn, knowledge = kn)
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
#> 4 child_x2  -->   oldage_x5
#> 5 child_x2  -->   youth_x3 
#> 6 child_x2  -->   youth_x4 
#> 7 oldage_x5 -->   oldage_x6
#> 8 youth_x3  -->   oldage_x5
#> 9 youth_x4  -->   oldage_x6
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

#### inter_iamb #####

inter_iamb_bnlearn <- inter_iamb(
  engine = "bnlearn",
  test = "fisher_z",
  alpha = 0.05
)
disco(tpc_example, inter_iamb_bnlearn, knowledge = kn)
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
#> 4 child_x2  -->   oldage_x5
#> 5 child_x2  -->   youth_x3 
#> 6 child_x2  -->   youth_x4 
#> 7 oldage_x5 -->   oldage_x6
#> 8 youth_x3  -->   oldage_x5
#> 9 youth_x4  -->   oldage_x6
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
```
