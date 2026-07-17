# Create a Custom Causal Discovery Method

**\[experimental\]**

Constructs a new causal discovery method that can be used with the
[`disco()`](https://disco-coders.github.io/causalDisco/reference/disco.md)
framework. Users can provide an engine, engine-specific functions, and
optional test and alpha parameters.

## Usage

``` r
make_method(
  method_name,
  engine,
  engine_fns,
  test = NULL,
  alpha = NULL,
  score = NULL,
  graph_class,
  ...
)
```

## Arguments

- method_name:

  Character. The name of the method to create.

- engine:

  Character. The engine to use. Must be one of the names of
  `engine_fns`.

- engine_fns:

  Named list of functions. Each element corresponds to an engine and is
  a function that implements the causal discovery algorithm.

- test:

  Optional. A test statistic to pass to the engine function.

- alpha:

  Optional. A significance level to pass to the engine function.

- score:

  Optional. A score to pass to the engine function.

- graph_class:

  Character. The graph class that this method produces.

- ...:

  Additional arguments passed to the engine function.

## Value

A `disco_method` object with attributes `engine` and `graph_class`.

## See also

Other Extending causalDisco:
[`as_disco()`](https://disco-coders.github.io/causalDisco/reference/as_disco.md),
[`distribute_engine_args()`](https://disco-coders.github.io/causalDisco/reference/distribute_engine_args.md),
[`list_registered_engines()`](https://disco-coders.github.io/causalDisco/reference/list_registered_engines.md),
[`list_registered_tetrad_algorithms()`](https://disco-coders.github.io/causalDisco/reference/list_registered_tetrad_algorithms.md),
[`make_runner()`](https://disco-coders.github.io/causalDisco/reference/make_runner.md),
[`new_disco_method()`](https://disco-coders.github.io/causalDisco/reference/new_disco_method.md),
[`register_engine()`](https://disco-coders.github.io/causalDisco/reference/register_engine.md),
[`register_tetrad_algorithm()`](https://disco-coders.github.io/causalDisco/reference/register_tetrad_algorithm.md),
[`reset_engine_registry()`](https://disco-coders.github.io/causalDisco/reference/reset_engine_registry.md),
[`reset_tetrad_alg_registry()`](https://disco-coders.github.io/causalDisco/reference/reset_tetrad_alg_registry.md)
