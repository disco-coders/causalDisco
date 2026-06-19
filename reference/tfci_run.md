# Run the TFCI Algorithm for Causal Discovery

Use a modification of the FCI algorithm that makes use of background
knowledge in the format of a partial ordering. This may, for instance,
come about when variables can be assigned to distinct tiers or periods
(i.e., a temporal ordering).

## Usage

``` r
tfci_run(
  data = NULL,
  knowledge = NULL,
  alpha = 0.05,
  test = reg_test,
  suff_stat = NULL,
  method = "stable.fast",
  na_method = "none",
  orientation_method = "conservative",
  directed_as_undirected = FALSE,
  varnames = NULL,
  num_cores = 1,
  ...
)
```

## Arguments

- data:

  A data frame with the observed variables.

- knowledge:

  A `Knowledge` object describing tiers/periods and optional
  forbidden/required edges.

- alpha:

  The alpha level used as the per-test significance threshold for
  conditional independence testing.

- test:

  A conditional independence test. The default
  [`reg_test()`](https://disco-coders.github.io/causalDisco/reference/reg_test.md)
  uses a regression-based information-loss test. Another available
  option is
  [`cor_test()`](https://disco-coders.github.io/causalDisco/reference/cor_test.md)
  which tests for vanishing partial correlations. User-supplied
  functions may also be used; see details for the required interface.

- suff_stat:

  A sufficient statistic. If supplied, it is passed directly to the test
  and no statistics are computed from `data`. Its structure depends on
  the chosen `test`.

- method:

  Skeleton construction method, one of `"stable"`, `"original"`, or
  `"stable.fast"` (default). See
  [`pcalg::skeleton()`](https://rdrr.io/pkg/pcalg/man/skeleton.html) for
  details.

- na_method:

  Handling of missing values, one of `"none"` (default; error on any
  `NA`), `"cc"` (complete-case analysis), or `"twd"` (test-wise
  deletion).

- orientation_method:

  Method for handling conflicting separating sets when orienting edges;
  must be one of `"standard"`, `"conservative"` (the default) or
  `"maj.rule"`. See
  [`pcalg::pc()`](https://rdrr.io/pkg/pcalg/man/pc.html) for further
  details.

- directed_as_undirected:

  Logical; if `TRUE`, treat any directed edges in `knowledge` as
  undirected during skeleton learning. This is due to the fact that
  pcalg does not allow directed edges in `fixedEdges` or `fixedGaps`.
  Default is `FALSE`.

- varnames:

  Character vector of variable names. Only needed when `data` is not
  supplied and all information is passed via `suff_stat`.

- num_cores:

  Integer number of CPU cores to use for parallel skeleton learning.

- ...:

  Additional arguments passed to
  [`pcalg::skeleton()`](https://rdrr.io/pkg/pcalg/man/skeleton.html)
  during skeleton construction.

## Details

The temporal/tiered background information enters several places in the
TFCI algorithm: (1) In the skeleton construction phase, when looking for
separating sets \\Z\\ between two variables \\X\\ and \\Y\\, \\Z\\ is
not allowed to contain variables that are strictly after both \\X\\ and
\\Y\\ in the temporal order (as specified by the `knowledge` tiers). (2)
This also applies to the subsequent phase where the algorithm searches
for possible D-SEP sets. (3) Prior to other orientation steps, any
cross-tier edges get an arrowhead placed at their latest node.

After this, the usual FCI orientation rules are applied; see
[`pcalg::udag2pag()`](https://rdrr.io/pkg/pcalg/man/udag2pag.html) for
details.

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
  object representing the learned causal graph. This graph is a PAG
  (Partial Ancestral Graph), but since PAGs are not yet natively
  supported in caugi, it is currently stored with class `UNKNOWN`.

## Examples

``` r
data(tpc_example)

kn <- knowledge(
  tpc_example,
  tier(
    child ~ tidyselect::starts_with("child"),
    youth ~ tidyselect::starts_with("youth"),
    oldage ~ tidyselect::starts_with("oldage")
  )
)

# Recommended path using disco()
my_tfci <- tfci(engine = "causalDisco", test = "fisher_z", alpha = 0.05)

disco(tpc_example, my_tfci, knowledge = kn)
#> <Disco UNKNOWN: 6 nodes | 6 edges | Knowledge: 3 tiers>
#> Learned graph:
#>   nodes: child_x2, child_x1, youth_x4, youth_x3, oldage_x6, oldage_x5
#>   edges: child_x2o-ochild_x1, child_x2o->oldage_x5, child_x2o->youth_x4
#>          oldage_x5-->oldage_x6, youth_x3o->oldage_x5, youth_x4-->oldage_x6
#> Knowledge:
#>   tier(child): child_x1, child_x2
#>   tier(youth): youth_x3, youth_x4
#>   tier(oldage): oldage_x5, oldage_x6

# or using my_tfci directly
my_tfci <- my_tfci |> set_knowledge(kn)
my_tfci(tpc_example)
#> <Disco UNKNOWN: 6 nodes | 6 edges | Knowledge: 3 tiers>
#> Learned graph:
#>   nodes: child_x2, child_x1, youth_x4, youth_x3, oldage_x6, oldage_x5
#>   edges: child_x2o-ochild_x1, child_x2o->oldage_x5, child_x2o->youth_x4
#>          oldage_x5-->oldage_x6, youth_x3o->oldage_x5, youth_x4-->oldage_x6
#> Knowledge:
#>   tier(child): child_x1, child_x2
#>   tier(youth): youth_x3, youth_x4
#>   tier(oldage): oldage_x5, oldage_x6

# Also possible: using tfci_run()
tfci_run(tpc_example, test = cor_test, knowledge = kn)
#> <Disco UNKNOWN: 6 nodes | 6 edges | Knowledge: 3 tiers>
#> Learned graph:
#>   nodes: child_x2, child_x1, youth_x4, youth_x3, oldage_x6, oldage_x5
#>   edges: child_x2o-ochild_x1, child_x2o->oldage_x5, child_x2o->youth_x4
#>          oldage_x5-->oldage_x6, youth_x3o->oldage_x5, youth_x4-->oldage_x6
#> Knowledge:
#>   tier(child): child_x1, child_x2
#>   tier(youth): youth_x3, youth_x4
#>   tier(oldage): oldage_x5, oldage_x6
```
