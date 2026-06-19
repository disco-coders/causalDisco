# Summarize a Disco Object

Summarize a Disco Object

## Usage

``` r
# S3 method for class 'Disco'
summary(object, ...)
```

## Arguments

- object:

  A `Disco` object.

- ...:

  Additional arguments (not used).

## Value

Invisibly returns the `Disco` object.

## Examples

``` r
data(tpc_example)
kn <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    old ~ starts_with("old")
  )
)
cd_tges <- tpc(engine = "causalDisco", test = "fisher_z")
disco_cd_tges <- disco(data = tpc_example, method = cd_tges, knowledge = kn)
summary(disco_cd_tges)
#> 
#> ── caugi graph summary ─────────────────────────────────────────────────────────
#> Graph class: PDAG
#> Nodes: 6
#> Edges: 6
#> 
#> ── Knowledge summary ──
#> 
#> Tiers: 3
#> Variables: 6
#> Required edges: 0
#> Forbidden edges: 0
#> 
#> ── Variables per Tier 
#> child: 2 variables
#> old: 2 variables
#> youth: 2 variables
```
