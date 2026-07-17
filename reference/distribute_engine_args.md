# Distribute and Validate Engine Arguments

This function checks the provided arguments against the expected
arguments for the specified engine and algorithm, and distributes them
appropriately to the search object. It ensures that the arguments are
valid for the given engine and algorithm, and then sets them on the
search object.

## Usage

``` r
distribute_engine_args(search, args, engine, alg)
```

## Arguments

- search:

  R6 object, either `TetradSearch`, `BnlearnSearch`, `PcalgSearch`, or
  `CausalDiscoSearch`.

- args:

  List of arguments to distribute

- engine:

  Engine identifier, either "tetrad", "bnlearn", "pcalg", or
  "causalDisco"

- alg:

  Algorithm name

## See also

Other Extending causalDisco:
[`as_disco()`](https://disco-coders.github.io/causalDisco/reference/as_disco.md),
[`list_registered_engines()`](https://disco-coders.github.io/causalDisco/reference/list_registered_engines.md),
[`list_registered_tetrad_algorithms()`](https://disco-coders.github.io/causalDisco/reference/list_registered_tetrad_algorithms.md),
[`make_method()`](https://disco-coders.github.io/causalDisco/reference/make_method.md),
[`make_runner()`](https://disco-coders.github.io/causalDisco/reference/make_runner.md),
[`new_disco_method()`](https://disco-coders.github.io/causalDisco/reference/new_disco_method.md),
[`register_engine()`](https://disco-coders.github.io/causalDisco/reference/register_engine.md),
[`register_tetrad_algorithm()`](https://disco-coders.github.io/causalDisco/reference/register_tetrad_algorithm.md),
[`reset_engine_registry()`](https://disco-coders.github.io/causalDisco/reference/reset_engine_registry.md),
[`reset_tetrad_alg_registry()`](https://disco-coders.github.io/causalDisco/reference/reset_tetrad_alg_registry.md)
