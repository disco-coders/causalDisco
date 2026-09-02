# Changelog

## causalDisco (development version)

### Bug fixes

- `pc(engine = "pcalg")` no longer errors when the estimated graph
  contains a cycle. Now emits a message and returns the graph with its
  class downgraded to `"UNKNOWN"`.

## causalDisco 1.2.1

CRAN release: 2026-07-20

### New features

- Added support for the RFCI algorithm via
  [`rfci()`](https://disco-coders.github.io/causalDisco/reference/rfci.md),
  interfacing with implementations from pcalg and Tetrad.

- The infix edge operators `%-->%` and `%!-->%` in
  [`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md)
  now accept `+` on both sides to specify multiple variables,
  e.g. `A + B %-->% C + D` is equivalent to `c(A, B) %-->% c(C, D)`.

- The infix edge operators `%-->%` and `%!-->%` in
  [`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md)
  now support tidyselect set operations such as `!`, `&`, and `|` on
  either side, e.g. `child_x1 %!-->% !starts_with("child")`.

- You can now plug a fully custom, user-written search algorithm into
  the causalDisco engine and run it through
  [`disco()`](https://disco-coders.github.io/causalDisco/reference/disco.md)
  (via `CausalDiscoSearch$set_alg()` and
  [`make_method()`](https://disco-coders.github.io/causalDisco/reference/make_method.md)).
  See the “Extending causalDisco with new algorithms” article for a
  worked example.

- Added
  [`register_engine()`](https://disco-coders.github.io/causalDisco/reference/register_engine.md),
  which lets you plug in an entirely new engine backend (i.e. one not
  built on bnlearn, causalDisco, pcalg, or Tetrad) so. See the
  “Extending causalDisco with new algorithms” article for a worked
  example.

### Deprecated

- The [`summary()`](https://rdrr.io/r/base/summary.html) methods for
  `Knowledge` and `Disco` objects are deprecated; use
  [`print()`](https://rdrr.io/r/base/print.html) instead.

- The `directed_as_undirected` argument of
  [`tpc_run()`](https://disco-coders.github.io/causalDisco/reference/tpc_run.md),
  [`tfci_run()`](https://disco-coders.github.io/causalDisco/reference/tfci_run.md),
  and `CausalDiscoSearch$set_knowledge()` is deprecated and ignored; see
  the related bug-fix entry below for the new handling of directed
  forbidden edges.

- The internal-only `directed_as_undirected_knowledge` argument of
  [`make_runner()`](https://disco-coders.github.io/causalDisco/reference/make_runner.md)
  has been removed, and the `directed_as_undirected` argument of
  `PcalgSearch$set_knowledge()` and
  [`as_pcalg_constraints()`](https://disco-coders.github.io/causalDisco/reference/as_pcalg_constraints.md)
  is deprecated and ignored.

- [`as_pcalg_constraints()`](https://disco-coders.github.io/causalDisco/reference/as_pcalg_constraints.md)
  no longer returns a `fixed_edges` matrix. pcalg’s `fixedEdges`
  argument only protects an undirected adjacency in the skeleton, so a
  directed required edge (`A %-->% B`) cannot be honored through it.

### Bug fixes

- Fixed
  [`tpc()`](https://disco-coders.github.io/causalDisco/reference/tpc.md)
  and
  [`tfci()`](https://disco-coders.github.io/causalDisco/reference/tfci.md)
  silently treating directed forbidden edges as undirected: forbidding
  `i %!-->% j` also forbidden `j !--> i`. Forbidden edges now follow the
  same rule as the pcalg engine: both directions must be supplied
  explicitly, otherwise an error is raised. The exception is if the
  `Knowledge` forbidden knowledge is equivalent to tiered knowledge.

- Fixed
  [`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md)
  dropping variables from `tier()` formulas when infix edge operators
  (`%-->%`, `%!-->%`) appeared before the `tier()` call and had already
  registered some (but not all) of the tier’s variables. This only
  affected the no-data-frame form of
  [`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md).

### Improvements

- The [`print()`](https://rdrr.io/r/base/print.html) methods for
  `Knowledge` and `Disco` objects now give a more concise and readable
  summary.

- `Disco` objects now store an attribute `graph_class` of the actual
  learned graph class.

- `Knowledge` objects generated from
  [`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md)
  now verifies the knowledge for requires edges doesn’t contain a
  directed cycle.

- Improved the documentation.

- Reduced the number of package dependencies.

### Other changes

- Converted most vignettes to articles to reduce package size.

## causalDisco 1.1.0

CRAN release: 2026-04-13

### New features

- Exports
  [`list_registered_tetrad_algorithms()`](https://disco-coders.github.io/causalDisco/reference/list_registered_tetrad_algorithms.md)
  to view the custom registered Tetrad algorithms.

- Allows the user to specify custom conditional independence tests for
  use with the engines bnlearn, causalDisco, and pcalg. The custom test
  should have the signature
  `function(x, y, conditioning_set, suff_stat)` (optionally with an
  additional `args` argument for additional parameters), and return a
  p-value. See the documentation and the associated vignette for
  details.

- Added support for micd tests such as
  [`micd::gaussCItestMI()`](https://rdrr.io/pkg/micd/man/gaussMItest.html)
  for pcalg and causalDisco engine. See all the new available tests in
  [`?PcalgSearch`](https://disco-coders.github.io/causalDisco/reference/PcalgSearch.md)
  and
  [`?CausalDiscoSearch`](https://disco-coders.github.io/causalDisco/reference/CausalDiscoSearch.md)
  under the test field.

- Simplified the interface for extending causalDisco with new
  algorithms. Exports
  [`make_method()`](https://disco-coders.github.io/causalDisco/reference/make_method.md)
  and
  [`make_runner()`](https://disco-coders.github.io/causalDisco/reference/make_runner.md)
  to do this. Please see the documentation and the associated vignette
  for details.

### Improvements

- Improved speed of
  [`tfci()`](https://disco-coders.github.io/causalDisco/reference/tfci.md),
  [`tges()`](https://disco-coders.github.io/causalDisco/reference/tges.md),
  and
  [`tpc()`](https://disco-coders.github.io/causalDisco/reference/tpc.md)
  algorithms by at least 3x, and often much more.

- Updated
  [`knowledge_to_caugi()`](https://disco-coders.github.io/causalDisco/reference/knowledge_to_caugi.md)
  to include information about required and forbidden edges in the
  output.

- Improve documentation for many functions.

## causalDisco 1.0.1

CRAN release: 2026-02-24

- This release should be considered essentially a **new package** with
  many new features, and some breaking changes (mainly renaming
  functions, arguments, and object classes) to be consistent.

- Please see the vignettes and documentation for details on using the
  new features.

## causalDisco 0.9.5

CRAN release: 2026-01-20

- Fixed warnings and notes from R CMD check regarding documentation.

## causalDisco 0.9.3

- Changed structure of tpdag and tskeleton objects so they include tamat
  objects rather than amat and order slots. This is a major change, not
  backwards compatible!
- tpc now passes … argument to skeleton() function call
- Added functionality in tpc to handle missing information when using
  built-in tests. Three options are now available: complete case
  analysis, test wise deletion, or no handling (i.e., and error is
  thrown if there are NAs, this is the default and it is backwards
  compatible).

## causalDisco 0.9.2

- Fixed bug in maketikz() function so it now works with tpdag and tamat
  objects, and added examples to the documentation.

## causalDisco 0.9.1

CRAN release: 2022-05-12

- Added three new functions: simDAG, simGausFromDAG, nDAGs.
- Changed structure of tamat objects so they inherit directly from
  matrix.

## causalDisco 0.9.0

- Added a NEWS.md file to track changes to the package.
- First CRAN submission.
