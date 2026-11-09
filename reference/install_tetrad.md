# Install Tetrad GUI

Downloads and installs the Tetrad GUI JAR file from [Maven
Central](https://repo1.maven.org/maven2/io/github/cmu-phil/tetrad-gui/).
It downloads the specified version of the Tetrad GUI JAR and its
corresponding SHA256 checksum file, and saves them in the specified
directory (or cache). If the JAR already exists and `force = FALSE`, it
will skip downloading.

## Usage

``` r
install_tetrad(
  version = getOption("causalDisco.tetrad.version"),
  dir = NULL,
  force = FALSE,
  quiet = FALSE,
  temp_dir = FALSE
)
```

## Arguments

- version:

  Character; the Tetrad version to install. Default is
  `getOption("causalDisco.tetrad.version")`.

- dir:

  Character; the directory where the JAR should be installed. If `NULL`
  (default), the JAR is installed in the cache directory for `version`,
  i.e.
  `tools::R_user_dir("causalDisco/tetrad_v<version>", which = "cache")`,
  or in `getOption("causalDisco.tetrad_cache")` if that option is set.
  The directory will be created if it does not exist.

- force:

  Logical; if `TRUE`, forces re-download even if the JAR already exists.
  Default is `FALSE`.

- quiet:

  Logical; if `FALSE`, shows progress and messages about downloading and
  checksum verification. Default is `FALSE`.

- temp_dir:

  Logical; if `TRUE`, installs the JAR in a temporary directory instead
  of the cache. Default is `FALSE`.

## Value

Invisibly returns the full path to the installed Tetrad JAR.

## Details

In line with [CRAN
policies](https://cran.r-project.org/web/packages/policies.html) this
function will only return messages and not throw warnings/errors if the
installation fails (e.g. due to no internet connection), and return
`NULL`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Install default version in cache directory
install_tetrad()

# Install a specific version and force re-download
install_tetrad(version = "7.6.10", force = TRUE)

# Install in a temporary directory
install_tetrad(temp_dir = TRUE)

# Install quietly (suppress messages)
install_tetrad(quiet = TRUE)
} # }
```
