# Temporal Bayesian Dirichlet equivalent uniform (Score criterion)

A reference class for categorical observational data Scoring with Tiered
Background Knowledge. This class represents a score for causal discovery
using tiered background knowledge from observational categorical data;
it is used in the causal discovery function
[`tges()`](https://disco-coders.github.io/causalDisco/reference/tges.md).

## Arguments

- data:

  A numeric matrix with \\n\\ rows and \\p\\ columns. Each row
  corresponds to one observational realization.

- nodes:

  A character vector of variable names corresponding to the columns of
  the data.

- iss:

  Imaginary Sample Size (ISS), also referred to as Equivalent Sample
  Size (ESS), determines how much weight is assigned to the prior in
  terms of the size of an imaginary sample supporting it. Increasing the
  ISS will increase the density of the estimated graph.

- knowledge:

  A `Knowledge` object.

- debug:

  Logical; indicates whether to perform validation of the vertex and
  parents in every local score calculation. Setting this to TRUE will
  slow down the algorithm, but may be useful for debugging.

## Details

The class implements a score which scores all edges contradicting the
ordering (edge going from a later tier to an earlier) to minus
\\\infty\\. If the edges do not contradict, the score is equal to that
of the standard BDeu.

## Extends

Class `Score-class` from pcalg, directly.

All reference classes extend and inherit methods from `envRefClass`.

## Constructor


    new(
     "TemporalBdeu",
     data = matrix(1, 1, 1),
     order =  rep(1,ncol(data)),
     iss = 1
     ...
    )

## See also

[`tges()`](https://disco-coders.github.io/causalDisco/reference/tges.md)

## Author

Tobias Ellegaard Larsen

## Examples

``` r
# For reproducibility
set.seed(1405)

# Number of samples
n <- 1000

# Define probabilities for A
p_A <- c(0.4, 0.35, 0.25) # Probabilities for A = {1, 2, 3}

# Simulate A from a categorical distribution
A <- sample(1:3, n, replace = TRUE, prob = p_A)

# Define conditional probabilities for B given A
p_B_given_A <- list(
  c(0.7, 0.3), # P(B | A=1)
  c(0.4, 0.6), # P(B | A=2)
  c(0.2, 0.8) # P(B | A=3)
)

# Sample B based on A
B <- sapply(A, function(a) sample(1:2, 1, prob = p_B_given_A[[a]]))

# Define conditional probabilities for C given A and B
p_C_given_A_B <- list(
  "1_1" = c(0.6, 0.4), # P(C | A=1, B=1)
  "1_2" = c(0.3, 0.7), # P(C | A=1, B=2)
  "2_1" = c(0.5, 0.5), # P(C | A=2, B=1)
  "2_2" = c(0.2, 0.8), # P(C | A=2, B=2)
  "3_1" = c(0.7, 0.3), # P(C | A=3, B=1)
  "3_2" = c(0.4, 0.6) # P(C | A=3, B=2)
)

# Sample C based on A and B
C <- mapply(
  function(a, b) sample(1:2, 1, prob = p_C_given_A_B[[paste(a, b, sep = "_")]]),
  A,
  B
)

# Create dataset
simdata <- data.frame(as.factor(A), as.factor(B), as.factor(C))

# Define order in prefix way
colnames(simdata) <- c("child_A", "child_B", "adult_C")
prefix_order <- c("child", "adult")

# Define Knowledge object
kn <- knowledge(
  simdata,
  tier(
    child ~ tidyselect::starts_with("child"),
    adult ~ tidyselect::starts_with("adult")
  )
)

# Define TemporalBDeu score
t_score <- new("TemporalBDeu", knowledge = kn, data = simdata)
# Run tges
tges_pre <- tges_run(t_score)

# Plot MPDAG
# plot(tges_pre)
```
