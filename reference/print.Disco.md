# Print a Disco Object

Print a Disco Object

## Usage

``` r
# S3 method for class 'Disco'
print(x, ...)
```

## Arguments

- x:

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
print(disco_cd_tges)
#> <Disco MPDAG: 6 nodes | 6 edges | Knowledge: 3 tiers>
#> Learned graph:
#>   nodes: child_x2, child_x1, youth_x4, youth_x3, oldage_x6, oldage_x5
#>   edges: child_x1---child_x2, child_x2-->oldage_x5, child_x2-->youth_x4
#>          oldage_x5-->oldage_x6, youth_x3-->oldage_x5, youth_x4-->oldage_x6
#> Knowledge:
#>   tier(child): child_x1, child_x2
#>   tier(youth): youth_x3, youth_x4
#>   tier(old): oldage_x5, oldage_x6
```
