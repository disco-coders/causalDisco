# Incorporating Knowledge

``` r

library(causalDisco)
#> causalDisco startup:
#>   Java heap size requested: 2 GB
#>   Tetrad version: 7.6.10
#>   Java successfully initialized with 2 GB.
#>   To change heap size, set options(java.heap.size = 'Ng') or Sys.setenv(JAVA_HEAP_SIZE = 'Ng') *before* loading.
#>   Restart R to apply changes.
```

This article demonstrates how to use the
[`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md)
function to incorporate prior knowledge into causal discovery
algorithms. The different supported knowledge types are explained below,
along with examples of how to create `Knowledge` objects and use them
with causal discovery methods. All knowledge types can be freely
combined. Multiple calls or operators are additive: each call adds new
edges to the `Knowledge` object. For example if we require an edge from
`A` to `B` and then require an edge from A to C, the resulting
`Knowledge` object will require both edges from `A` to `B` and from `A`
to `C`.

At a conceptual level, all knowledge is represented as constraints on
edges, specifying which edges are required and forbidden. Some knowledge
types provide higher-level abstractions for expressing common modeling
assumptions more conveniently.

## Required and forbidden knowledge

At the most basic level, prior knowledge is expressed as required or
forbidden edges between variables. These constraints apply to directed
edges in the causal graph.

- Required edges specify that a directed edge must exist between two
  variables.
- Forbidden edges specify that a directed edge is not allowed between
  two variables.

These constraints are specified using the `%-->%` (required) and
`%!-->%` (forbidden) operators, with the exclamation mark (`!`)
indicating negation of the edge, i.e. the absence of the edge.
Conceptually, this could be written as `%!(-->)%`, but we find this
syntax too verbose.

### Specifying required and forbidden edges

Suppose we want to require an edge from A to B, from A to C, and forbid
an edge from B to C:

``` r

kn_1 <- knowledge(
  A %-->% c(B, C), # Require edges from A to B and A to C
  B %!-->% C # Forbid edge from B to C
)
```

This `Knowledge` object can be visualized:

``` r

plot(kn_1)
```

![](knowledge_files/figure-html/plot-required-and-forbidden-knowledge-1.png)

The blue edge represents the required edge from A to B, while the red
edge represents the forbidden edge from B to C.

If one wishes to remove some edges (either required or forbidden)
knowledge from an existing `Knowledge` object, the
[`remove_edge()`](https://disco-coders.github.io/causalDisco/reference/remove_edge.md)
function can be used. For example, to remove the required edge from A to
B:

``` r

kn_1_removed <- remove_edge(kn_1, from = A, to = B)
plot(kn_1_removed)
```

![](knowledge_files/figure-html/remove-required-edge-1.png)

### Specifying required and forbidden edges in a dataset

We will use the `tpc_example` dataset available in the package for the
following examples. The dataset contains 6 variables, as shown below:

``` r

data(tpc_example)
head(tpc_example)
#>   child_x2   child_x1    youth_x4 youth_x3  oldage_x6  oldage_x5
#> 1        0 -0.7104066 -0.07355602        1  6.4984994  3.0740123
#> 2        0  0.2568837 -1.16865142        1  0.3254685  1.9726530
#> 3        0 -0.2466919 -0.63474826        1  4.1298927  1.9666697
#> 4        1  1.6524574  0.97115845        0 -7.9064009 -4.5160676
#> 5        0 -0.9516186  0.67069597        0  1.7089134  0.7903853
#> 6        1  1.9549723 -0.65054654        0 -6.9758928 -3.2107342
```

When specifying knowledge, it is often more convenient to specify the
dataset so that the variables are checked for existence and selected
correctly. To do this, pass the dataset as the first argument to
[`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md).

``` r

kn_2 <- knowledge(
  tpc_example,
  child_x1 %-->% youth_x3, # Require edge from child_x1 to youth_x3
  child_x2 %!-->% oldage_x5 # Forbid edge from child_x2 to oldage_x5
)
```

This `Knowledge` object can also be visualized (we manually adjust the
layout for better appearance):

``` r

cg <- knowledge_to_caugi(kn_2)$caugi
layout <- caugi::caugi_layout_sugiyama(cg)
layout[6, 2] <- layout[4, 2]

plot(kn_2, layout = layout)
```

![](knowledge_files/figure-html/plot-required-and-forbidden-knowledge-with-data-1.png)

The plot then plots all variables in the dataset, with the required
edges as blue edges and forbidden edges as red edges.

#### Using tidyselect helpers

To make specifying variables easier, you can use tidyselect helpers such
as `starts_with`:

``` r

kn_3 <- knowledge(
  tpc_example,
  starts_with("child") %-->% starts_with("youth"),
  starts_with("oldage") %!-->% starts_with("youth")
)
```

This means, that all variables starting with “child” are required to
have edges to all variables starting with “youth”, and no variables
starting with “oldage” can have edges to any variables starting with
“youth”. We can visualize this:

``` r

plot(kn_3)
```

![](knowledge_files/figure-html/plot-required-and-forbidden-knowledge-with-tidyselect-1.png)

For a list of all available tidyselect helpers we refer to the
[tidyselect reference
documentation](https://tidyselect.r-lib.org/reference/index.html).

## Tiered knowledge

Tiered knowledge provides a higher-level abstraction for expressing
systematic ordering assumptions, such as temporal or logical precedence.
Internally, tiered knowledge is translated into a collection of
forbidden edges, but it is exposed separately because it provides a
concise and structured way to express common ordering assumptions.

For example, consider a dataset with three groups of variables: child,
youth, and old. We may wish to enforce that child variables precede
youth variables, which in turn precede old variables. This can be
expressed using tiered knowledge.

Tiered knowledge enforces that edges may only point from earlier tiers
to later tiers. Edges within the same tier are unrestricted unless
additional knowledge is supplied.

### Creating a tiered `Knowledge` object

Suppose we observe variables over time: first the `A`’s, then the `B`’s,
and finally the `C`’s. This ordering implies that causal direction
cannot go backward in time (e.g., `B`’s cannot cause `A`’s). A tiered
`Knowledge` object captures this temporal structure by specifying tiers
and their associated variables. If numeric tiers are used, lower numbers
indicate earlier tiers; otherwise, tiers are ordered by their
appearance.

The following specifications encode the same tier structure:

``` r

kn <- knowledge(
  tier(
    1 ~ c(A1, A2),
    2 ~ c(B1, B2),
    3 ~ c(C1, C2)
  )
)

# Same object, since tiers are ordered numerically
kn_same <- knowledge(
  tier(
    1 ~ c(A1, A2),
    3 ~ c(C1, C2),
    2 ~ c(B1, B2)
  )
)

# Functionally equivalent, though not identical
kn_almost <- knowledge(
  tier(
    10 ~ c(A1, A2),
    30 ~ c(C1, C2),
    20 ~ c(B1, B2)
  )
)

# Again functionally equivalent
kn_also_almost <- knowledge(
  tier(
    A ~ c(A1, A2),
    B ~ c(B1, B2),
    C ~ c(C1, C2)
  )
)

# Has a letter, so tiers are ordered by appearance, thus functionally equivalent
kn_mixed <- knowledge(
  tier(
    3 ~ c(A1, A2),
    B ~ c(B1, B2),
    1 ~ c(C1, C2)
  )
)
```

We can visualize the tiers:

``` r

plot(kn)
```

![](knowledge_files/figure-html/plot-tier-knowledge-1.png)

The plot then shows the tiers as layers, with the earliest tiers to the
left and latest to the right.

We can convert the meaning of the tiered knowledge into explicit
forbidden edges using
[`convert_tiers_to_forbidden()`](https://disco-coders.github.io/causalDisco/reference/convert_tiers_to_forbidden.md):

``` r

kn_converted <- convert_tiers_to_forbidden(kn)
print(kn_converted)
#> 
#> ── Knowledge object ────────────────────────────────────────────────────────────
#> 
#> ── Variables ──
#> 
#>   [1mvar[22m   [1mtier[22m 
#>   <chr> <chr>
#> 1 A1    <NA> 
#> 2 A2    <NA> 
#> 3 B1    <NA> 
#> 4 B2    <NA> 
#> 5 C1    <NA> 
#> 6 C2    <NA>
#> ── Edges ──
#>  ✖  B1 → A1
#>  ✖  B1 → A2
#>  ✖  B2 → A1
#>  ✖  B2 → A2
#>  ✖  C1 → A1
#>  ✖  C1 → A2
#>  ✖  C1 → B1
#>  ✖  C1 → B2
#>  ✖  C2 → A1
#>  ✖  C2 → A2
#>  ✖  C2 → B1
#>  ✖  C2 → B2
plot(kn_converted)
```

![](knowledge_files/figure-html/convert-tiers-to-forbidden-1.png)

Tidyselect helpers such as `starts_with` can also be used to define
tiers in a concise way, just as with required and forbidden edges.
Different tidyselect helpers can be freely combined within a tier
definition using `+`. For example, the following tiered `Knowledge`
object defines two tiers, “young” and “old”, by combining tidyselect
helpers on the variables in the `tpc_example` dataset:

``` r

kn_tier_tidyselect <- knowledge(
  tpc_example,
  tier(
    young ~ starts_with("child") + ends_with(c("3", "4")),
    old ~ starts_with("old")
  )
)
plot(kn_tier_tidyselect)
```

![](knowledge_files/figure-html/tier-knowledge-with-tidyselect-1.png)

## Exogenous variables knowledge

Exogenous variables are those that have no incoming edges in the causal
graph. That is, variables which are known causes but are not affected by
other variables. Exogenous variables can be specified using the
`exogenous()` function within
[`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md).

### Specifying exogenous variables

The most natural usage is to supply the dataset so that the variables
are checked for existence and selected correctly:

``` r

kn_exo_1 <- knowledge(
  tpc_example,
  exogenous("child_x1")
)
```

Instead of `exogenous()`, you can also use the shorthand function
`exo()`. This `Knowledge` object can be visualized:

``` r

plot(kn_exo_1)
```

![](knowledge_files/figure-html/plot-exogenous-knowledge-1.png)

Below we add both `child_x1` and `child_x2` as exogenous variables using
tidyselect helpers:

``` r

kn_exo_2 <- knowledge(
  tpc_example,
  exo(starts_with("child"))
)
plot(kn_exo_2, layout = "bipartite", orientation = "columns")
```

![](knowledge_files/figure-html/exogenous-knowledge-with-tidyselect-1.png)

## Combining different knowledge types

Different knowledge types can be freely combined in a single `Knowledge`
object. For example, we can combine tiered knowledge with required and
forbidden edges:

``` r

kn_combined <- knowledge(
  tpc_example,
  tier(
    1 ~ starts_with("child"),
    2 ~ starts_with("youth"),
    3 ~ starts_with("oldage")
  ),
  child_x1 %-->% youth_x3,
  child_x1 %!-->% child_x2
)

plot(kn_combined)
```

![](knowledge_files/figure-html/combined-knowledge-1.png)

## Using knowledge with causal discovery

Once prior knowledge has been specified, it can be supplied to causal
discovery algorithms by passing the `Knowledge` object to the
[`disco()`](https://disco-coders.github.io/causalDisco/reference/disco.md)
function via the `knowledge` argument. For example, we can use the
Temporal GES algorithm
[`tges()`](https://disco-coders.github.io/causalDisco/reference/tges.md)
with engine “causalDisco” and temporal BIC (“tbic”) score, while
providing tiered knowledge:

``` r

kn <- knowledge(
  tpc_example,
  tier(
    1 ~ starts_with("child"),
    2 ~ starts_with("youth"),
    3 ~ starts_with("oldage")
  )
)

cd_tges <- tges(engine = "causalDisco", score = "tbic")
disco_cd_tges <- disco(data = tpc_example, method = cd_tges, knowledge = kn)
```

The causal discovery algorithms will then learn the causal graph from
the data given the constraints specified in the `Knowledge` object.

``` r

plot(disco_cd_tges)
```

![](knowledge_files/figure-html/plot-causal-discovery-with-tier-knowledge-1.png)

The black edges are those inferred from the data.

## Engine specific information about knowledge

By engine we mean the underlying implementation of the causal discovery
algorithm, i.e. the engine you specify to an algorithm such as
`pc(engine = "bnlearn")` or `tges(engine = "causalDisco")`.

### bnlearn

All knowledge types are supported with the bnlearn engine. When required
knowledge is provided, bnlearn may emit a warning during structure
learning. This occurs when the algorithm identifies a candidate
v-structure (collider) from the data whose orientation conflicts with
edges already oriented due to background knowledge.

``` r

data(tpc_example)

kn <- knowledge(
  tpc_example,
  child_x1 %-->% youth_x3
)

bnlearn_pc <- pc(engine = "bnlearn", test = "fisher_z", alpha = 0.05)
output <- disco(data = tpc_example, method = bnlearn_pc, knowledge = kn)
#> Warning in vstruct.apply(arcs = arcs, vs = vs, nodes = nodes, debug = debug):
#> vstructure child_x2 -> oldage_x5 <- youth_x3 is not applicable, because one or
#> both arcs are oriented in the opposite direction.
```

The resulting causal graph will still respect the provided knowledge.

``` r

plot(output)
```

![](knowledge_files/figure-html/plot-bnlearn-1.png)

### causalDisco

The causalDisco engine only supports tiered and forbidden knowledge. If
required knowledge is provided, it will give a warning and ignore the
required knowledge.

### pcalg

Only symmetric forbidden-edge constraints are supported by the pcalg
engine. In practice, this means an edge must be forbidden in both
directions. Such constraints can be specified using `%!-->%` in both
directions, as illustrated below:

``` r

data(tpc_example)
kn <- knowledge(
  tpc_example,
  child_x1 %!-->% youth_x3,
  youth_x3 %!-->% child_x1
)
pc_pcalg <- pc(engine = "pcalg", test = "fisher_z", alpha = 0.05)
output <- disco(data = tpc_example, method = pc_pcalg, knowledge = kn)
```

### Tetrad

All knowledge types are supported with the Tetrad engine.
