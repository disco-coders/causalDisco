# Developer Notes

This document is intended for developers maintaining or extending this project.

If you are new to the codebase, or returning after a long break, start here.

## 1. High-Level Architecture

Each engine (i.e., an underlying R, Python, or Java package) is wrapped in its
own R6 class. The R6 class is responsible for:

- Handling engine-specific logic
- Managing parameter translation and validation
- Defining the public API exposed to users
- Housing engine-specific documentation

## 2. Tetrad Engine Information

The Tetrad integration is implemented via `rJava`. Relevant Java source
locations in the Tetrad repository are:

- **Tests**\
  https://github.com/cmu-phil/tetrad/tree/development/tetrad-lib/src/main/java/edu/cmu/tetrad/algcomparison/independence

- **Scores**\
  https://github.com/cmu-phil/tetrad/tree/development/tetrad-lib/src/main/java/edu/cmu/tetrad/algcomparison/score

- **Algorithms**\
  https://github.com/cmu-phil/tetrad/tree/development/tetrad-lib/src/main/java/edu/cmu/tetrad/algcomparison/algorithm

These classes define what is available to be wrapped on the R side. Always
ensure you are browsing the source corresponding to the current
`.default_tetrad_version`.

### Adding a New Tetrad Score

#### Finding Score and Test Descriptions in Tetrad

To obtain brief descriptions of scores or tests (as presented in the Tetrad
GUI): 1. Download and open the Tetrad GUI (the default version) 2. Create a Data
block and load a `.csv` file 3. Create a Search block 4. Connect the Data block
to the Search block using an arrow 5. Double-click the Search block 6. Hover
over the arguments to see short descriptions and parameter hints

These descriptions are often the best reference for concise documentation.

#### Implementing a new score/test

Implementing a new independence test follows the same pattern as implementing a
new score. Only score registration is documented here.

When adding a new score, it must be registered in **three places** in the
engine-specific R6 class:

1. **Public field `score`**\
   Add the score name so it is visible to users.

2. **`set_score()`method**\
   Add a new case that maps the score name to the corresponding private method.

3. **`...`argument of `set_score()`**\
   Document and validate any additional parameters accepted by the score.

In the `set_score()` method, add an entry of the form:

```r
"my_score" <- {
  private$my_score(..., use_for_mc = mc)
}
```
Then implement the corresponding private method:

```r
private$my_score <- function(...) {
  # score-specific setup
}
```

## 3. Style Guide

### General R Style

We follow the [tidyverse style guide](https://style.tidyverse.org/) for general
R code.

### R6 Conventions

For R6 classes, we use **PascalCase** for class names, following the conventions
used in [mlr3](https://github.com/mlr-org/mlr3/wiki/Roxygen-Guide).

- Public methods and fields use `snake_case`
- Private methods and fields use `snake_case`
- R6 class names are nouns (e.g., `TetradSearch`)

This distinction helps visually separate classes from functions and emphasizes
that R6 classes represent entities rather than actions.

### Formatting

We use [Air](https://posit-dev.github.io/air/formatter.html) as the automatic
code formatter.

Code should be formatted with Air before committing. We recommend enabling
format-on-save in your editor.

### Documentation Style

- When wrapping external libraries (e.g., Tetrad), prefer concise documentation
  that mirrors upstream terminology.
- If the external library does not use `snake_case` for argument names, users
  should supply arguments in `snake_case`.
- Where feasible, also allow the underlying library's native naming conventions
  (e.g., kebab-case) for convenience.

See, for example,
[`BnlearnSearch`](https://disco-coders.github.io/causalDisco/reference/BnlearnSearch.html),
where this approach is implemented.

### File Names

We recommend using kebab-case for file names (e.g., `tetrad-search.R`).
