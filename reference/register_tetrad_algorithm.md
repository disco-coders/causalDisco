# Register a New Tetrad Algorithm

Registers a new Tetrad algorithm by adding it to the internal registry.
The `setup_fun()` should be a function that takes the same arguments as
the runner function for the algorithm and sets up the Tetrad search
object accordingly. This allows you to extend the set of Tetrad
algorithms that can be used with causalDisco.

## Usage

``` r
register_tetrad_algorithm(name, setup_fun)
```

## Arguments

- name:

  Algorithm name (string)

- setup_fun:

  A function that sets up the Tetrad search object for the algorithm. It
  should take the same arguments as the runner function for the
  algorithm.

## See also

Other Extending causalDisco:
[`as_disco()`](https://disco-coders.github.io/causalDisco/reference/as_disco.md),
[`distribute_engine_args()`](https://disco-coders.github.io/causalDisco/reference/distribute_engine_args.md),
[`list_registered_engines()`](https://disco-coders.github.io/causalDisco/reference/list_registered_engines.md),
[`list_registered_tetrad_algorithms()`](https://disco-coders.github.io/causalDisco/reference/list_registered_tetrad_algorithms.md),
[`make_method()`](https://disco-coders.github.io/causalDisco/reference/make_method.md),
[`make_runner()`](https://disco-coders.github.io/causalDisco/reference/make_runner.md),
[`new_disco_method()`](https://disco-coders.github.io/causalDisco/reference/new_disco_method.md),
[`register_engine()`](https://disco-coders.github.io/causalDisco/reference/register_engine.md),
[`reset_engine_registry()`](https://disco-coders.github.io/causalDisco/reference/reset_engine_registry.md),
[`reset_tetrad_alg_registry()`](https://disco-coders.github.io/causalDisco/reference/reset_tetrad_alg_registry.md)
