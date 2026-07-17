# Create a Custom Runner for a Causal Discovery Algorithm

**\[experimental\]**

Constructs a runner function for a specific causal discovery engine and
algorithm. This allows users to support new algorithms.

## Usage

``` r
make_runner(
  engine,
  alg,
  test = NULL,
  alpha = NULL,
  score = NULL,
  ...,
  directed_as_undirected_knowledge = FALSE
)
```

## Arguments

- engine:

  Character. The engine to use. Options include `"causalDisco"`,
  `"pcalg"`, `"bnlearn"`, `"tetrad"`, or the name of any engine added
  via
  [`register_engine()`](https://disco-coders.github.io/causalDisco/reference/register_engine.md).

- alg:

  Character. The algorithm name.

- test:

  Optional. A test statistic to pass to the engine.

- alpha:

  Optional. Significance level to pass to the engine.

- score:

  Optional. A scoring function for score-based methods.

- ...:

  Additional arguments passed to the engine-specific runner.

- directed_as_undirected_knowledge:

  Logical. Used internally for pcalg.

## Value

An object representing a configured runner for the chosen engine. The
type depends on the engine.

## See also

Other Extending causalDisco:
[`as_disco()`](https://disco-coders.github.io/causalDisco/reference/as_disco.md),
[`distribute_engine_args()`](https://disco-coders.github.io/causalDisco/reference/distribute_engine_args.md),
[`list_registered_engines()`](https://disco-coders.github.io/causalDisco/reference/list_registered_engines.md),
[`list_registered_tetrad_algorithms()`](https://disco-coders.github.io/causalDisco/reference/list_registered_tetrad_algorithms.md),
[`make_method()`](https://disco-coders.github.io/causalDisco/reference/make_method.md),
[`new_disco_method()`](https://disco-coders.github.io/causalDisco/reference/new_disco_method.md),
[`register_engine()`](https://disco-coders.github.io/causalDisco/reference/register_engine.md),
[`register_tetrad_algorithm()`](https://disco-coders.github.io/causalDisco/reference/register_tetrad_algorithm.md),
[`reset_engine_registry()`](https://disco-coders.github.io/causalDisco/reference/reset_engine_registry.md),
[`reset_tetrad_alg_registry()`](https://disco-coders.github.io/causalDisco/reference/reset_tetrad_alg_registry.md)
