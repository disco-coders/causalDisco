# causalDisco (development version)

## New features

- Added support for the RFCI algorithm via `rfci()`, interfacing with
  implementations from pcalg and Tetrad.

- The infix edge operators `%-->%` and `%!-->%` in `knowledge()` now accept `+`
  on both sides to specify multiple variables, e.g. `A + B %-->% C + D` is
  equivalent to `c(A, B) %-->% c(C, D)`.

- The infix edge operators `%-->%` and `%!-->%` in `knowledge()` now support
  tidyselect set operations such as `!`, `&`, and `|` on either side, e.g.
  `child_x1 %!-->% !starts_with("child")`.

- You can now plug a fully custom, user-written search algorithm into the
  causalDisco engine and run it through `disco()` (via
  `CausalDiscoSearch$set_alg()` and `make_method()`). See the "Extending
  causalDisco with new algorithms" article for a worked example.

- Added `register_engine()`, which lets you plug in an entirely new engine
  backend (i.e. one not built on bnlearn, causalDisco, pcalg, or Tetrad) so. See
  the "Extending causalDisco with new algorithms" article for a worked example.

## Deprecated

- The `summary()` methods for `Knowledge` and `Disco` objects are deprecated;
  use `print()` instead.

## Bug fixes

- Fixed `knowledge()` dropping variables from `tier()` formulas when infix edge
  operators (`%-->%`, `%!-->%`) appeared before the `tier()` call and had
  already registered some (but not all) of the tier's variables. This only
  affected the no-data-frame form of `knowledge()`.

## Improvements

- The `print()` methods for `Knowledge` and `Disco` objects now give a more
  concise and readable summary.

- `Disco` objects now store an attribute `graph_class` of the actual learned
  graph class.

- `Knowledge` objects generated from `knowledge()` now verifies the knowledge
  for requires edges doesn't contain a directed cycle.

- Improved the documentation.

- Reduced the number of package dependencies.

## Other changes

- Converted most vignettes to articles to reduce package size.

# causalDisco 1.1.0

## New features

- Exports `list_registered_tetrad_algorithms()` to view the custom registered
  Tetrad algorithms.

- Allows the user to specify custom conditional independence tests for use with
  the engines bnlearn, causalDisco, and pcalg. The custom test should have the
  signature `function(x, y, conditioning_set, suff_stat)` (optionally with an
  additional `args` argument for additional parameters), and return a p-value.
  See the documentation and the associated vignette for details.

- Added support for micd tests such as `micd::gaussCItestMI()` for pcalg and
  causalDisco engine. See all the new available tests in `?PcalgSearch` and
  `?CausalDiscoSearch` under the test field.

- Simplified the interface for extending causalDisco with new algorithms.
  Exports `make_method()` and `make_runner()` to do this. Please see the
  documentation and the associated vignette for details.

## Improvements

- Improved speed of `tfci()`, `tges()`, and `tpc()` algorithms by at least 3x,
  and often much more.

- Updated `knowledge_to_caugi()` to include information about required and
  forbidden edges in the output.

- Improve documentation for many functions.

# causalDisco 1.0.1

- This release should be considered essentially a **new package** with many new
  features, and some breaking changes (mainly renaming functions, arguments, and
  object classes) to be consistent.

- Please see the vignettes and documentation for details on using the new
  features.

# causalDisco 0.9.5

- Fixed warnings and notes from R CMD check regarding documentation.

# causalDisco 0.9.3

- Changed structure of tpdag and tskeleton objects so they include tamat objects
  rather than amat and order slots. This is a major change, not backwards
  compatible!
- tpc now passes ... argument to skeleton() function call
- Added functionality in tpc to handle missing information when using built-in
  tests. Three options are now available: complete case analysis, test wise
  deletion, or no handling (i.e., and error is thrown if there are NAs, this is
  the default and it is backwards compatible).

# causalDisco 0.9.2

- Fixed bug in maketikz() function so it now works with tpdag and tamat objects,
  and added examples to the documentation.

# causalDisco 0.9.1

- Added three new functions: simDAG, simGausFromDAG, nDAGs.
- Changed structure of tamat objects so they inherit directly from matrix.

# causalDisco 0.9.0

- Added a NEWS.md file to track changes to the package.
- First CRAN submission.
