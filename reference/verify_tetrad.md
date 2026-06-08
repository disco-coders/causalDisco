# Check Tetrad Installation

Check Tetrad Installation

## Usage

``` r
verify_tetrad(version = getOption("causalDisco.tetrad.version"))
```

## Arguments

- version:

  Character. The version of Tetrad to check. Default is the value of
  `getOption("causalDisco.tetrad.version")`.

## Value

A list with elements:

- `installed`: Logical, whether Tetrad is installed.

- `version`: Character or NULL, the installed version if found.

- `java_ok`: Logical, whether Java \>= 21.

- `java_version`: Character, the installed Java version.

- `message`: Character, a message describing the status.

## Examples

``` r
verify_tetrad()
#> $installed
#> [1] TRUE
#> 
#> $version
#> [1] "7.6.10"
#> 
#> $java_ok
#> [1] TRUE
#> 
#> $java_version
#> [1] "25.0.3"
#> 
#> $message
#> [1] "Tetrad version 7.6.10 is installed and ready to use."
#> 
```
