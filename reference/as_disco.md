# Wrap a Graph as a Disco Object

Wraps a causal graph object (e.g. a
[caugi::caugi](https://caugi.org/reference/caugi.html) graph, or a graph
object from pcalg or bnlearn) and a `Knowledge` object into a `Disco`
object, which is the output object of causal discovery methods used in
causalDisco.

## Usage

``` r
as_disco(graph, kn = knowledge(), class = "PDAG")
```

## Arguments

- graph:

  A causal graph object

- kn:

  A `Knowledge` object. Default is an empty `Knowledge` object.

- class:

  A string describing the graph class.

## Value

A `Disco` object containing a
[caugi::caugi](https://caugi.org/reference/caugi.html) and a `Knowledge`
object in a list.

## Details

The conversion from any graph type to a
[caugi::caugi](https://caugi.org/reference/caugi.html) is handled by the
caugi package.

## See also

[`caugi::caugi()`](https://caugi.org/reference/caugi.html)

Other Extending causalDisco:
[`distribute_engine_args()`](https://disco-coders.github.io/causalDisco/reference/distribute_engine_args.md),
[`list_registered_engines()`](https://disco-coders.github.io/causalDisco/reference/list_registered_engines.md),
[`list_registered_tetrad_algorithms()`](https://disco-coders.github.io/causalDisco/reference/list_registered_tetrad_algorithms.md),
[`make_method()`](https://disco-coders.github.io/causalDisco/reference/make_method.md),
[`make_runner()`](https://disco-coders.github.io/causalDisco/reference/make_runner.md),
[`new_disco_method()`](https://disco-coders.github.io/causalDisco/reference/new_disco_method.md),
[`register_engine()`](https://disco-coders.github.io/causalDisco/reference/register_engine.md),
[`register_tetrad_algorithm()`](https://disco-coders.github.io/causalDisco/reference/register_tetrad_algorithm.md),
[`reset_engine_registry()`](https://disco-coders.github.io/causalDisco/reference/reset_engine_registry.md),
[`reset_tetrad_alg_registry()`](https://disco-coders.github.io/causalDisco/reference/reset_tetrad_alg_registry.md)
