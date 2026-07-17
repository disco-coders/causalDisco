# Generate Synthetic Data from a Linear Gaussian DAG

**\[deprecated\]**

This function has been renamed to
[`sim_data()`](https://disco-coders.github.io/causalDisco/reference/sim_data.md)
instead.

## Usage

``` r
generate_dag_data(
  cg,
  n,
  ...,
  standardize = TRUE,
  coef_range = c(0.1, 0.9),
  error_sd = c(0.3, 2),
  seed = NULL
)
```
