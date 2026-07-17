# Print a Knowledge Object

Print a Knowledge Object

## Usage

``` r
# S3 method for class 'Knowledge'
print(x, ...)
```

## Arguments

- x:

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
print(kn)
#> <Knowledge: 3 tiers | 6 vars>
#>   tier(child): child_x1, child_x2
#>   tier(youth): youth_x3, youth_x4
#>   tier(old): oldage_x5, oldage_x6
```
