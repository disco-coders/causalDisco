# causalDisco

causalDisco provides a unified interface for causal discovery on
observational data. It wraps multiple causal discovery backends under a
common, consistent syntax.

## Motivation

Causal discovery methods exist in many ecosystems, for example in
bnlearn, pcalg, or Tetrad, but their APIs vary widely.

causalDisco unifies them under one clear grammar, making it easy to
compare results, switch algorithms, and focus on scientific questions
rather than package quirks.

Time to hit the disco 🪩

## Available algorithms

causalDisco provides the following causal discovery algorithms, grouped
by methodological class, with the supported engines and output graph
class for each (function identifiers given in parentheses).

![Table of causal discovery algorithms available in causalDisco, grouped
by methodological class (constraint-based, score-based, hybrid), with
the supported engines and output graph class for
each.](reference/figures/algorithms-table-light.svg)

## Installation

### Install causalDisco

You can install the stable version of causalDisco from CRAN with:

``` r

install.packages("causalDisco")
```

or the development version of causalDisco from GitHub using pak:

``` r

pak::pak("disco-coders/causalDisco")
```

If you want to use algorithms from
[Tetrad](https://github.com/cmu-phil/tetrad), you also need to install
the suggested dependency rJava (and a Java JDK \>= 21). See the
instructions below for setting up Java and Tetrad.

### Installing Java / JDK

causalDisco provides an interface to the Java library Tetrad for causal
discovery algorithms. To use algorithms from Tetrad you need to install
a Java Development Kit (JDK) \>= 21. We recommend Eclipse Temurin
(OpenJDK), available at <https://adoptium.net/en-GB/temurin/releases>.
When using the installer from the Temurin website, make sure to select
the option to set the `JAVA_HOME` environment variable during
installation, so rJava correctly detects the Java installation.

For a simpler setup, we recommend using the
[rJavaEnv](https://github.com/e-kotov/rJavaEnv) package, which provides
a convenient function to install Java and configure the environment
automatically for rJava. You can install Java using the
`rJavaEnv::java_quick_install()` function:

``` r

# Use the development version of rJavaEnv from GitHub
# pak::pak("e-kotov/rJavaEnv")
rJavaEnv::java_quick_install(version = 25, distribution = "Temurin")
```

Once you have Java JDK set up correctly, the current supported version
of Tetrad can then be installed by calling

``` r

causalDisco::install_tetrad()
```

To verify everything is set up correctly you can run
[`verify_tetrad()`](https://disco-coders.github.io/causalDisco/reference/verify_tetrad.md):

``` r

causalDisco::verify_tetrad()
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
#> [1] "25.0.2"
#> 
#> $message
#> [1] "Tetrad version 7.6.10 is installed and ready to use."
```

## Example

With causalDisco you can currently run causal discovery algorithms from
the package causalDisco itself, the R packages bnlearn and pcalg, and
the Java library Tetrad with a consistent syntax. Here we provide a
simple example of how to use these different backends with the same code
structure. We also show how to incorporate tiered background knowledge.

``` r

library(causalDisco)
#> causalDisco startup:
#>   Java heap size requested: 2 GB
#>   Tetrad version: 7.6.10
#>   Java successfully initialized with 2 GB.
#>   To change heap size, set options(java.heap.size = 'Ng') or Sys.setenv(JAVA_HEAP_SIZE = 'Ng') *before* loading.
#>   Restart R to apply changes.

# Load data
data(tpc_example)

pcalg_ges <- ges(
  engine = "pcalg", # Use the pcalg implementation
  score = "sem_bic" # Use BIC score for the GES algorithm
)
disco_pcalg_ges <- disco(data = tpc_example, method = pcalg_ges)
```

We can also pass background knowledge to the engines that support it.
Here we use tiered knowledge, which is a common way to encode temporal
ordering of variables. We use tidyselect syntax to select variables for
each tier, but you can also use explicit variable names or regular
expressions.

``` r

kn <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    old ~ starts_with("old")
  )
)

cd_tpc <- tpc(
  engine = "causalDisco", # Use the causalDisco implementation
  test = "fisher_z", # Use Fisher's Z test for conditional independence
  alpha = 0.05 # Significance level for the test
)
disco_cd_tpc <- disco(data = tpc_example, method = cd_tpc, knowledge = kn)

bnlearn_pc <- pc(
  engine = "bnlearn", # Use the bnlearn implementation
  test = "cor", # Use Pearson correlation test for conditional independence
  alpha = 0.05
)
disco_bnlearn_pc <- disco(
  data = tpc_example,
  method = bnlearn_pc,
  knowledge = kn
)
```

To use algorithms from Tetrad, you need to have Java and Tetrad set up
correctly as described in the installation instructions above. Then you
can specify the Tetrad engine in the same way as for the other backends:

``` r

if (verify_tetrad()$installed && verify_tetrad()$java_ok) {
  tetrad_pc <- pc(
    engine = "tetrad", # Use the Tetrad implementation
    test = "conditional_gaussian", # Use conditional Gaussian test
    alpha = 0.05
  )
  disco_tetrad_pc <- disco(
    data = tpc_example,
    method = tetrad_pc,
    knowledge = kn
  )
}
```

You can visualize the resulting causal graph using the
[`plot()`](https://disco-coders.github.io/causalDisco/reference/plot.md)
function:

``` r

plot(disco_cd_tpc)
```

![A causal graph with the known tiers indicated by vertical positioning
of the nodes.](reference/figures/README-plot-1.png)

Please see our pkgdown site for more detailed introductions to the
package and its features, such as how to incorporate knowledge, run
causal discovery, and visualize results, here:
<https://disco-coders.github.io/causalDisco/>

## Bugs & requests

Bug reports and feature requests are welcome:

[open an issue](https://github.com/disco-coders/causalDisco/issues).
