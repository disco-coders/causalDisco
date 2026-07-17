# Regression-based Information Loss Test

Test whether `x` and `y` are associated, given `conditioning_set` using
a generalized linear model.

## Usage

``` r
reg_test(x, y, conditioning_set, suff_stat)
```

## Arguments

- x:

  Index of x variable.

- y:

  Index of y variable.

- conditioning_set:

  Index vector of conditioning variable(s), possibly `NULL`.

- suff_stat:

  List with data, binary variables and order.

## Value

A numeric, which is the p-value of the test.

## Details

All included variables should be either numeric or binary. If `y` is
binary, a logistic regression model is fitted. If `y` is numeric, a
linear regression model is fitted. `x` and `conditioning_set` are
included as explanatory variables. Any numeric variables among `x` and
`conditioning_set` are modeled with spline expansions (natural splines,
3 df). This model is tested against a numeric where `x` (including a
possible spline expansion) has been left out using a likelihood ratio
test. The model is fitted in both directions (interchanging the roles of
`x` and `y`). The final p-value is the maximum of the two obtained
p-values.

## Examples

``` r
# Use via disco() and method functions (recommended):
data(tpc_example)
my_tpc <- tpc(engine = "causalDisco", test = "reg", alpha = 0.05)
result <- disco(data = tpc_example, method = my_tpc)
```
