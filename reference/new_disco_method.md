# Add a New causalDisco Method

This function allows you to create a new causal discovery method that
can be used with the
[`disco()`](https://disco-coders.github.io/causalDisco/reference/disco.md)
function. You provide a builder function that constructs a runner
object, along with metadata about the algorithm, and it returns a
closure that can be called with a data frame to perform causal discovery
and return a [caugi::caugi](https://caugi.org/reference/caugi.html)
object.

## Usage

``` r
new_disco_method(builder, name, engine, graph_class)
```

## Arguments

- builder:

  A function returning a runner

- name:

  Algorithm name

- engine:

  Engine identifier

- graph_class:

  Output graph class

## Value

A function of class `"disco_method"` that takes a single argument `data`
(a data frame) and returns a
[caugi::caugi](https://caugi.org/reference/caugi.html) object.

## See also

Other Extending causalDisco:
[`as_disco()`](https://disco-coders.github.io/causalDisco/reference/as_disco.md),
[`distribute_engine_args()`](https://disco-coders.github.io/causalDisco/reference/distribute_engine_args.md),
[`list_registered_engines()`](https://disco-coders.github.io/causalDisco/reference/list_registered_engines.md),
[`list_registered_tetrad_algorithms()`](https://disco-coders.github.io/causalDisco/reference/list_registered_tetrad_algorithms.md),
[`make_method()`](https://disco-coders.github.io/causalDisco/reference/make_method.md),
[`make_runner()`](https://disco-coders.github.io/causalDisco/reference/make_runner.md),
[`register_engine()`](https://disco-coders.github.io/causalDisco/reference/register_engine.md),
[`register_tetrad_algorithm()`](https://disco-coders.github.io/causalDisco/reference/register_tetrad_algorithm.md),
[`reset_engine_registry()`](https://disco-coders.github.io/causalDisco/reference/reset_engine_registry.md),
[`reset_tetrad_alg_registry()`](https://disco-coders.github.io/causalDisco/reference/reset_tetrad_alg_registry.md)
