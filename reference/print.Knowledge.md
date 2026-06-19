# Print a Knowledge Object

Print a Knowledge Object

## Usage

``` r
# S3 method for class 'Knowledge'
print(x, compact = FALSE, wide_vars = FALSE, ...)
```

## Arguments

- x:

  A `Knowledge` object.

- compact:

  Logical. If `TRUE`, prints a more compact summary.

- wide_vars:

  Logical. If `TRUE`, prints the variables in a wide format.

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
print(kn)
#> 
#> ── Knowledge object ────────────────────────────────────────────────────────────
#> 
#> ── Tiers ──
#> 
#>   tier 
#>   <chr>
#> 1 child
#> 2 youth
#> 3 old  
#> ── Variables ──
#> 
#>   var       tier 
#>   <chr>     <chr>
#> 1 child_x1  child
#> 2 child_x2  child
#> 3 youth_x3  youth
#> 4 youth_x4  youth
#> 5 oldage_x5 old  
#> 6 oldage_x6 old  
print(kn, wide_vars = TRUE)
#> ── Knowledge object ────────────────────────────────────────────────────────────
#> 
#> ── Tiers ──
#> 
#>   tier 
#>   <chr>
#> 1 child
#> 2 youth
#> 3 old  
#> ── Variables ──
#> 
#>   tier  var1      var2     
#>   <chr> <chr>     <chr>    
#> 1 child child_x1  child_x2 
#> 2 old   oldage_x5 oldage_x6
#> 3 youth youth_x3  youth_x4 
print(kn, compact = TRUE)
#> ── Knowledge object ────────────────────────────────────────────────────────────
#> 
#> ── Tiers ──
#> 
#>   tier 
#>   <chr>
#> 1 child
#> 2 youth
#> 3 old  
#> ── Variables ──
#> 
#>   var       tier 
#>   <chr>     <chr>
#> 1 child_x1  child
#> 2 child_x2  child
#> 3 youth_x3  youth
#> ... and 3 more rows
```
