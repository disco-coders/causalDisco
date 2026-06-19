# Simulate a Random DAG

Simulates a random directed acyclic graph adjacency (DAG) matrix with
`n` nodes and either `m` edges, edge creation probability `p`, or edge
creation probability range `p_range`.

## Usage

``` r
sim_dag(n, m = NULL, p = NULL)
```

## Arguments

- n:

  The number of nodes.

- m:

  Integer in `0, n*(n-1)/2`. Number of edges in the graph. Exactly one
  of `m` or `p` must be supplied.

- p:

  Numeric in `[0,1]`. Probability of edge creation. Exactly one of `m`
  or `p` must be supplied.

## Value

The sampled `caugi` object.

## See also

[`caugi::generate_graph()`](https://caugi.org/reference/generate_graph.html)

## Examples

``` r
# Simulate a DAG with 5 nodes and 3 edges
sim_dag(n = 5, m = 3)
#> <caugi object; 5 nodes, 3 edges; simple: TRUE; session=0x55d1a21ecfd0>
#>   graph_class: DAG
#>   nodes: V1, V2, V3, V4, V5
#>   edges: V2-->V5, V3-->V1, V3-->V5

# Simulate a DAG with 5 nodes and edge creation probability of 0.2
sim_dag(n = 5, p = 0.2)
#> <caugi object; 5 nodes, 1 edges; simple: TRUE; session=0x55d1a11fef60>
#>   graph_class: DAG
#>   nodes: V1, V2, V3, V4, V5
#>   edges: V2-->V5
```
