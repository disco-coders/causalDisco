# Extending causalDisco with new algorithms

``` r

library(causalDisco)
#> causalDisco startup:
#>   Java heap size requested: 2 GB
#>   Tetrad version: 7.6.10
#>   Java successfully initialized with 2 GB.
#>   To change heap size, set options(java.heap.size = 'Ng') or Sys.setenv(JAVA_HEAP_SIZE = 'Ng') *before* loading.
#>   Restart R to apply changes.
```

This article illustrates how to add a new algorithm to causalDisco from
bnlearn, pcalg and Tetrad. Both bnlearn and pcalg are R packages and
therefore share the same interface, while Tetrad is a Java library and
requires a slightly different integration pattern.

## bnlearn and pcalg

Suppose we want to add the Hybrid Parents and Children (HPC) algorithm
from bnlearn. We can integrate it into causalDisco by creating a new
function `hpc()`.

HPC is a constraint-based algorithm, so it requires a conditional
independence test and a significance level alpha. It returns a PDAG, so
we set the `graph_class` attribute to `"PDAG"`.

The function takes an `engine` argument, which specifies which
implementation of the algorithm to use. Even though we only add HPC from
bnlearn in this example, we set up the structure to allow for multiple
engines in the future. The `...` argument allows us to pass additional
arguments to the underlying algorithm and test.

The code for the `hpc()` function is as follows:

``` r

hpc <- function(
  engine = c("bnlearn"),
  test,
  alpha = 0.05,
  ...
) {
  engine <- match.arg(engine)

  make_method(
    method_name = "hpc",
    engine = engine,
    engine_fns = list(
      bnlearn = function(...) make_runner(engine = "bnlearn", alg = "hpc", ...)
    ),
    test = test,
    alpha = alpha,
    graph_class = "PDAG",
    ...
  )
}
```

We see that the `hpc()` function is very simple, and all the logic is
handled by the
[`make_method()`](https://disco-coders.github.io/causalDisco/reference/make_method.md)
and
[`make_runner()`](https://disco-coders.github.io/causalDisco/reference/make_runner.md)
functions.

Once defined, the HPC algorithm can be used like any other method in
causalDisco. We first construct the method using `hpc()`, and then pass
it to
[`disco()`](https://disco-coders.github.io/causalDisco/reference/disco.md).
Here we demonstrate using the included `tpc_example` dataset:

``` r

data(tpc_example)
hpc_bnlearn <- hpc(engine = "bnlearn", test = "fisher_z", alpha = 0.05)
hpc_bnlearn_result <- disco(tpc_example, hpc_bnlearn)
plot(hpc_bnlearn_result)
```

![](new-algorithm_files/figure-html/hpc-example-1.png)

To implement a **score-based** algorithm instead, the structure would
remain the same. The main difference is that the method would accept a
`score` argument rather than `test` and `alpha`. A **hybrid** algorithm
would accept `test`, `alpha`, and `score` arguments.

To implement an algorithm from pcalg rather than bnlearn, we would
follow the same structure but change all instances of `"bnlearn"` to
`"pcalg"`.

## Tetrad

We will illustrate how to make a custom version (which actually does the
same as our implementation, just with some defensive programming
omitted) of the BOSS algorithm from Tetrad. Tetrad algorithms follow a
slightly different integration pattern because Tetrad is a Java library
rather than an R package.

To add a new Tetrad algorithm, first register it with
[`register_tetrad_algorithm()`](https://disco-coders.github.io/causalDisco/reference/register_tetrad_algorithm.md).
This function requires:

- The algorithm name.
- A setup function that configures a `TetradSearch` object to execute
  the algorithm.

The setup function receives the TetradSearch object as its first
argument, along with any additional parameters passed via `...` when the
method is constructed. Its responsibilities are to:

1.  Configure the TetradSearch object with the appropriate parameters
    and score.
2.  Instantiate the correct Tetrad algorithm class.

The fully qualified class name can be identified by inspecting the
Tetrad source code at:

https://github.com/cmu-phil/tetrad

Be sure to browse the version corresponding to the installed Tetrad
release. The relevant Java classes are located under:

https://github.com/cmu-phil/tetrad/tree/development/tetrad-lib/src/main/java

``` r

register_tetrad_algorithm(
  "my_boss_variant",
  function(
    self,
    num_starts = 1,
    use_bes = TRUE,
    use_data_order = TRUE,
    output_cpdag = TRUE
  ) {
    self$set_params(
      USE_BES = use_bes,
      NUM_STARTS = num_starts,
      USE_DATA_ORDER = use_data_order,
      OUTPUT_CPDAG = output_cpdag
    )

    self$alg <- rJava::.jnew(
      "edu/cmu/tetrad/algcomparison/algorithm/oracle/cpdag/Boss",
      self$score
    )
    self$alg$setKnowledge(self$knowledge)
  }
)
```

You can view all the custom registered Tetrad algorithms using
[`list_registered_tetrad_algorithms()`](https://disco-coders.github.io/causalDisco/reference/list_registered_tetrad_algorithms.md),
and reset it using
[`reset_tetrad_alg_registry()`](https://disco-coders.github.io/causalDisco/reference/reset_tetrad_alg_registry.md).

The structure of the method function for a Tetrad algorithm is then the
exact same as for bnlearn and pcalg, as seen below. BOSS is a
**score-based** algorithm, so it accepts a `score` argument. The
algorithm returns a PDAG, so we set the `graph_class` attribute to
`"PDAG"`.

``` r

my_boss_variant <- function(
  engine = "tetrad",
  score,
  ...
) {
  engine <- match.arg(engine)

  make_method(
    method_name = "my_boss_variant",
    engine = engine,
    engine_fns = list(
      tetrad = function(...) {
        make_runner(engine = "tetrad", alg = "my_boss_variant", ...)
      }
    ),
    score = score,
    graph_class = "PDAG",
    ...
  )
}
```

We can now run `my_boss_variant()` like any other method in causalDisco.

``` r

# Ensure Tetrad is installed and Java is working before running the algorithm
if (verify_tetrad()$installed && verify_tetrad()$java_ok) {
  my_boss_variant_tetrad <- my_boss_variant(
    engine = "tetrad",
    score = "sem_bic"
  )
  my_boss_variant_tetrad_result <- disco(tpc_example, my_boss_variant_tetrad)
  plot(my_boss_variant_tetrad_result)
}
```

![](new-algorithm_files/figure-html/my_boss_variant-example-1.png)

Once again, if using a hybrid or constraint-based algorithm rather than
a score-based one, the structure would remain the same but the method
would accept different arguments (e.g., `test` and `alpha` for a
constraint-based algorithm).

Finally, we clean up the custom registered Tetrad algorithm

``` r

reset_tetrad_alg_registry()
```

## Conclusion

In this article, we have illustrated how to add new algorithms to
causalDisco, both from the R packages pcalg and bnlearn and from Tetrad.

If you have any feedback or suggestions for improvement on the API and
functionality for extending causalDisco, please let us know by opening
an issue on GitHub.
