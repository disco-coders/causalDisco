# Evaluate Causal Graph Estimates

Computes various metrics to evaluate the difference between the
estimated and true causal graph. Designed primarily for assessing the
performance of causal discovery algorithms.

Metrics are supplied as a list with three slots: `$adj`, `$dir`, and
`$other`.

- `$adj`:

  Metrics applied to the adjacency confusion matrix (see
  [`confusion()`](https://disco-coders.github.io/causalDisco/reference/confusion.md)).

- `$dir`:

  Metrics applied to the conditional orientation confusion matrix (see
  [`confusion()`](https://disco-coders.github.io/causalDisco/reference/confusion.md)).

- `$other`:

  Metrics applied directly to the adjacency matrices without computing
  confusion matrices.

Adjacency confusion matrix and conditional orientation confusion matrix
only supports [caugi::caugi](https://caugi.org/reference/caugi.html)
objects whose edges are restricted to `-->`, `<->`, `---`, or absence of
an edge.

## Usage

``` r
evaluate(truth, est, metrics = "all")
```

## Arguments

- truth:

  truth [caugi::caugi](https://caugi.org/reference/caugi.html) object.

- est:

  Estimated [caugi::caugi](https://caugi.org/reference/caugi.html)
  object.

- metrics:

  List of metrics, see details. If `metrics = "all"`, all available
  metrics are computed.

## Value

A data.frame with one column for each computed metric. Adjacency metrics
are prefixed with "adj\_", orientation metrics are prefixed with
"dir\_", other metrics do not get a prefix.

## See also

Other metrics:
[`confusion()`](https://disco-coders.github.io/causalDisco/reference/confusion.md),
[`f1_score()`](https://disco-coders.github.io/causalDisco/reference/f1_score.md),
[`false_omission_rate()`](https://disco-coders.github.io/causalDisco/reference/false_omission_rate.md),
[`fdr()`](https://disco-coders.github.io/causalDisco/reference/fdr.md),
[`g1_score()`](https://disco-coders.github.io/causalDisco/reference/g1_score.md),
[`npv()`](https://disco-coders.github.io/causalDisco/reference/npv.md),
[`precision()`](https://disco-coders.github.io/causalDisco/reference/precision.md),
[`recall()`](https://disco-coders.github.io/causalDisco/reference/recall.md),
`reexports`,
[`specificity()`](https://disco-coders.github.io/causalDisco/reference/specificity.md)

## Examples

``` r
cg1 <- caugi::caugi(A %-->% B + C)
cg2 <- caugi::caugi(B %-->% A + C)
evaluate(cg1, cg2)
#>   adj_precision adj_recall adj_specificity adj_false_omission_rate adj_fdr
#> 1           0.5        0.5               0                       1     0.5
#>   adj_npv adj_f1_score adj_g1_score dir_precision dir_recall dir_specificity
#> 1       0          0.5            0             0          0               0
#>   dir_false_omission_rate dir_fdr dir_npv dir_f1_score dir_g1_score shd hd
#> 1                       1       1       0            0            0   3  0
#>         aid
#> 1 0.6666667
evaluate(
  cg1,
  cg2,
  metrics = list(
    adj = c("precision", "recall"),
    dir = c("f1_score"),
    other = c("shd")
  )
)
#>   adj_precision adj_recall dir_f1_score shd
#> 1           0.5        0.5            0   3
```
