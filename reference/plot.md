# Plot Method for causalDisco Objects

This is the generic `plot()` function for objects of class `Knowledge`
or `Disco`. It dispatches to the class-specific plotting methods
[`plot.Knowledge()`](https://disco-coders.github.io/causalDisco/reference/plot.Knowledge.md)
and
[`plot.Disco()`](https://disco-coders.github.io/causalDisco/reference/plot.Disco.md).

## Value

Invisibly returns the input object. The primary effect is the generated
plot.

## See also

Other plot:
[`plot.Disco()`](https://disco-coders.github.io/causalDisco/reference/plot.Disco.md),
[`plot.Knowledge()`](https://disco-coders.github.io/causalDisco/reference/plot.Knowledge.md)

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
plot(kn)


cd_tges <- tges(engine = "causalDisco", score = "tbic")
disco_cd_tges <- disco(data = tpc_example, method = cd_tges, knowledge = kn)
plot(disco_cd_tges)

```
