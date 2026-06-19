# Changelog

## causalDisco (development version)

### New features

- Added support for the RFCI algorithm via
  [`rfci()`](https://disco-coders.github.io/causalDisco/reference/rfci.md),
  interfacing with implementations from pcalg and Tetrad.

### Bug fixes

- Fixed
  [`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md)
  dropping variables from `tier()` formulas when infix edge operators
  (`%-->%`, `%!-->%`) appeared before the `tier()` call and had already
  registered some (but not all) of the tier’s variables. This only
  affected the no-data-frame form of
  [`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md).

### Improvements

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
