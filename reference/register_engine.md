# Register a New Engine

The built-in engines ("bnlearn", "causalDisco", "pcalg", "tetrad") are
backed by R6 search classes
([BnlearnSearch](https://disco-coders.github.io/causalDisco/reference/BnlearnSearch.md),
[CausalDiscoSearch](https://disco-coders.github.io/causalDisco/reference/CausalDiscoSearch.md),
[PcalgSearch](https://disco-coders.github.io/causalDisco/reference/PcalgSearch.md),
[TetradSearch](https://disco-coders.github.io/causalDisco/reference/TetradSearch.md))
that
[`make_runner()`](https://disco-coders.github.io/causalDisco/reference/make_runner.md)
knows how to build and configure. `register_engine()` lets you plug in a
backend for a package that isn't one of the built-ins, so that it can be
selected by name from
[`make_runner()`](https://disco-coders.github.io/causalDisco/reference/make_runner.md)
the same way as a built-in engine.

## Usage

``` r
register_engine(name, make_runner_fn, pkgs = character(0))
```

## Arguments

- name:

  Engine name (string). Cannot be one of the built-in engine names
  ("bnlearn", "causalDisco", "pcalg", "tetrad").

- make_runner_fn:

  A function implementing the engine. See Details.

- pkgs:

  Character vector of package names required by the engine. Checked,
  with an informative error if missing, before `make_runner_fn` is
  called.

## Details

`make_runner_fn` must accept `alg` and `...`, and return a runner: a
list with two elements,

- `set_knowledge`, a function that takes a single `Knowledge` object and
  configures background knowledge on the underlying search, and

- `run`, a function that takes a single data frame, runs the search, and
  returns the algorithm's result using
  [`as_disco()`](https://disco-coders.github.io/causalDisco/reference/as_disco.md).

[`make_runner()`](https://disco-coders.github.io/causalDisco/reference/make_runner.md)
calls `make_runner_fn` with `alg`, `test`, `alpha`, `score`, and any
additional arguments it was itself called with. Pick up whichever of
these your engine needs by naming them explicitly, and let `...` absorb
the rest.

## See also

Other Extending causalDisco:
[`as_disco()`](https://disco-coders.github.io/causalDisco/reference/as_disco.md),
[`distribute_engine_args()`](https://disco-coders.github.io/causalDisco/reference/distribute_engine_args.md),
[`list_registered_engines()`](https://disco-coders.github.io/causalDisco/reference/list_registered_engines.md),
[`list_registered_tetrad_algorithms()`](https://disco-coders.github.io/causalDisco/reference/list_registered_tetrad_algorithms.md),
[`make_method()`](https://disco-coders.github.io/causalDisco/reference/make_method.md),
[`make_runner()`](https://disco-coders.github.io/causalDisco/reference/make_runner.md),
[`new_disco_method()`](https://disco-coders.github.io/causalDisco/reference/new_disco_method.md),
[`register_tetrad_algorithm()`](https://disco-coders.github.io/causalDisco/reference/register_tetrad_algorithm.md),
[`reset_engine_registry()`](https://disco-coders.github.io/causalDisco/reference/reset_engine_registry.md),
[`reset_tetrad_alg_registry()`](https://disco-coders.github.io/causalDisco/reference/reset_tetrad_alg_registry.md)
