# Run the TGES Algorithm for Causal Discovery

Perform causal discovery using the temporal greedy equivalence search
algorithm.

## Usage

``` r
tges_run(score, verbose = FALSE)
```

## Arguments

- score:

  tiered scoring object to be used. At the moment only scores supported
  are

  - [TemporalBIC](https://disco-coders.github.io/causalDisco/reference/TemporalBIC-class.md)
    and

  - [TemporalBDeu](https://disco-coders.github.io/causalDisco/reference/TemporalBDeu-class.md).

- verbose:

  indicates whether debug output should be printed.

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

## Author

Tobias Ellegaard Larsen

## Examples

``` r
# Recommended route using disco:
kn <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    old ~ starts_with("old")
  )
)

my_tges <- tges(engine = "causalDisco", score = "tbic")

disco(tpc_example, my_tges, knowledge = kn)
#> <Disco PDAG: 6 nodes | 6 edges | Knowledge: 3 tiers>
#> Learned graph:
#>   nodes: child_x2, child_x1, youth_x4, youth_x3, oldage_x6, oldage_x5
#>   edges: child_x1---child_x2, child_x2-->oldage_x5, child_x2-->youth_x4
#>          oldage_x5-->oldage_x6, youth_x3-->oldage_x5, youth_x4-->oldage_x6
#> Knowledge:
#>   tier(child): child_x1, child_x2
#>   tier(youth): youth_x3, youth_x4
#>   tier(old): oldage_x5, oldage_x6

# another way to run it

my_tges <- my_tges |>
  set_knowledge(kn)
my_tges(tpc_example)
#> <Disco PDAG: 6 nodes | 6 edges>
#>   nodes: child_x2, child_x1, youth_x4, youth_x3, oldage_x6, oldage_x5
#>   edges: child_x1---child_x2, child_x2-->oldage_x5, child_x2-->youth_x4
#>          oldage_x5-->oldage_x6, youth_x3-->oldage_x5, youth_x4-->oldage_x6


# or you can run directly with tges_run()

data(tpc_example)

score_bic <- new(
  "TemporalBIC",
  data = tpc_example,
  nodes = colnames(tpc_example),
  knowledge = kn
)

res_bic <- tges_run(score_bic)
res_bic
#> <Disco PDAG: 6 nodes | 6 edges>
#>   nodes: child_x2, child_x1, youth_x4, youth_x3, oldage_x6, oldage_x5
#>   edges: child_x1---child_x2, child_x2-->oldage_x5, child_x2-->youth_x4
#>          oldage_x5-->oldage_x6, youth_x3-->oldage_x5, youth_x4-->oldage_x6
```
