# Summarize a Knowledge Object

Summarize a Knowledge Object

## Usage

``` r
# S3 method for class 'Knowledge'
summary(object, ...)
```

## Arguments

- object:

  A `Knowledge` object.

- ...:

  Additional arguments (not used).

## Value

Invisibly returns the `Knowledge` object.

## Examples

``` r
kn <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    old ~ starts_with("old")
  )
)
summary(kn)
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
