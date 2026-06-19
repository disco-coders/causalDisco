# R6 Interface to causalDisco Search Algorithms

This class implements the search algorithms from the causalDisco
package, which wraps and adds temporal order to pcalg algorithms. It
allows to set the data, sufficient statistics, test, score, and
algorithm.

## See also

[`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md).

## Public fields

- `data`:

  A `data.frame` holding the data set currently attached to the search
  object. Can be set with `set_data()`.

- `score`:

  A function that will be used to build the score, when data is set. Can
  be set with `$set_score()`. Recognized values are:

  - `"tbic"` - Temporal BIC score for Gaussian data. See
    [TemporalBIC](https://disco-coders.github.io/causalDisco/reference/TemporalBIC-class.md).

  - `"tbdeu"` - Temporal BDeu score for discrete data. See
    [TemporalBDeu](https://disco-coders.github.io/causalDisco/reference/TemporalBDeu-class.md).

- `test`:

  A function that will be used to test independence. Can be set with
  `$set_test()`. Recognized values are:

  - `"fisher_z"` - Fisher Z test for Gaussian data. See
    [`cor_test()`](https://disco-coders.github.io/causalDisco/reference/cor_test.md).

  - `"fisher_z_twd"` - Fisher Z test for Gaussian data with test-wise
    deletion. See
    [`micd::gaussCItwd()`](https://rdrr.io/pkg/micd/man/gaussCItwd.html).

  - `"fisher_z_mi"` - Fisher Z test for Gaussian data with multiple
    imputation. See
    [`micd::gaussCItestMI()`](https://rdrr.io/pkg/micd/man/gaussMItest.html).

  - `"reg"` - Regression test for discrete or binary data. See
    [`reg_test()`](https://disco-coders.github.io/causalDisco/reference/reg_test.md).

  - `"g_square"` - G square test for discrete data. See
    [`pcalg::binCItest()`](https://rdrr.io/pkg/pcalg/man/binCItest.html)
    and
    [`pcalg::disCItest()`](https://rdrr.io/pkg/pcalg/man/disCItest.html).

  - `"g_square_twd"` - G square test for discrete data with test-wise
    deletion. See
    [`micd::disCItwd()`](https://rdrr.io/pkg/micd/man/disCItwd.html).

  - `"g_square_mi"` - G square test for discrete data with multiple
    imputation. See
    [`micd::disMItest()`](https://rdrr.io/pkg/micd/man/disMItest.html).

  - `"conditional_gaussian"` - Test for conditional independence in
    mixed data. See
    [`micd::mixCItest()`](https://rdrr.io/pkg/micd/man/mixCItest.html).

  - `"conditional_gaussian_twd"` - Test for conditional independence in
    mixed data with test-wise deletion. See
    [`micd::mixCItwd()`](https://rdrr.io/pkg/micd/man/mixCItwd.html).

  - `"conditional_gaussian_mi"` - Test for conditional independence in
    mixed data with multiple imputation. See
    [`micd::mixMItest()`](https://rdrr.io/pkg/micd/man/mixMItest.html).

- `alg`:

  A function that will be used to run the search algorithm. Can be set
  with `$set_alg()`. Recognized values are:

  - `"tfci"` - TFCI algorithm. See
    [`tfci()`](https://disco-coders.github.io/causalDisco/reference/tfci.md).

  - `"tges"` - TGES algorithm. See
    [`tges()`](https://disco-coders.github.io/causalDisco/reference/tges.md).

  - `"tpc"` - TPC algorithm. See
    [`tpc()`](https://disco-coders.github.io/causalDisco/reference/tpc.md).

- `params`:

  A list of parameters for the test and algorithm. Can be set with
  `$set_params()`. TODO: not secure yet in terms of distributing
  arguments. Use with caution.

- `suff_stat`:

  Sufficient statistic. The format and contents of the sufficient
  statistic depends on which test is being used.

- `knowledge`:

  A `Knowledge` object holding background knowledge.

## Methods

### Public methods

- [`CausalDiscoSearch$new()`](#method-CausalDiscoSearch-initialize)

- [`CausalDiscoSearch$set_params()`](#method-CausalDiscoSearch-set_params)

- [`CausalDiscoSearch$set_data()`](#method-CausalDiscoSearch-set_data)

- [`CausalDiscoSearch$set_suff_stat()`](#method-CausalDiscoSearch-set_suff_stat)

- [`CausalDiscoSearch$set_test()`](#method-CausalDiscoSearch-set_test)

- [`CausalDiscoSearch$set_score()`](#method-CausalDiscoSearch-set_score)

- [`CausalDiscoSearch$set_alg()`](#method-CausalDiscoSearch-set_alg)

- [`CausalDiscoSearch$set_knowledge()`](#method-CausalDiscoSearch-set_knowledge)

- [`CausalDiscoSearch$run_search()`](#method-CausalDiscoSearch-run_search)

- [`CausalDiscoSearch$clone()`](#method-CausalDiscoSearch-clone)

------------------------------------------------------------------------

### `CausalDiscoSearch$new()`

Constructor for the `CausalDiscoSearch` class.

#### Usage

    CausalDiscoSearch$new()

------------------------------------------------------------------------

### `CausalDiscoSearch$set_params()`

Sets the parameters for the test and algorithm.

#### Usage

    CausalDiscoSearch$set_params(params)

#### Arguments

- `params`:

  A list of parameters to set.

------------------------------------------------------------------------

### `CausalDiscoSearch$set_data()`

Sets the data for the search algorithm.

#### Usage

    CausalDiscoSearch$set_data(data, set_suff_stat = TRUE)

#### Arguments

- `data`:

  A `data.frame` or a `matrix` containing the data.

- `set_suff_stat`:

  Logical; whether to set the sufficient statistic.

------------------------------------------------------------------------

### `CausalDiscoSearch$set_suff_stat()`

Sets the sufficient statistic for the data.

#### Usage

    CausalDiscoSearch$set_suff_stat()

------------------------------------------------------------------------

### `CausalDiscoSearch$set_test()`

Sets the test for the search algorithm.

#### Usage

    CausalDiscoSearch$set_test(
      method,
      alpha = 0.05,
      suff_stat_fun = NULL,
      args = NULL
    )

#### Arguments

- `method`:

  **\[experimental\]**

  A string specifying the type of test to use.

  Can also be a user-defined function with signature
  `function(x, y, conditioning_set, suff_stat)`, where `x` and `y` are
  the variables being tested for independence, `conditioning_set` is the
  conditioning set, and `suff_stat` is the sufficient statistic for the
  test. If a user-defined function is provided, then `suff_stat_fun`
  must also be provided, which is a function that should take the data
  as input and returns a sufficient statistic for the test. Optionally,
  the signature of the user-defined test function can also include an
  `args` parameter, which is a list of additional arguments to pass to
  the test function. If `args` is provided, then the test function
  should have the signature
  `function(x, y, conditioning_set, suff_stat, args)`, and the `args`
  parameter will be passed to the test function.

  EXPERIMENTAL: user-defined tests syntax are subject to change.

- `alpha`:

  Significance level for the test.

- `suff_stat_fun`:

  A function that takes the data as input and returns a sufficient
  statistic for the test. Only needed if `method` is a user-defined
  function.

- `args`:

  A list of additional arguments to pass to the test. Only needed if
  `method` is a user-defined function with an `args` parameter in its
  signature.

------------------------------------------------------------------------

### `CausalDiscoSearch$set_score()`

Sets the score for the search algorithm.

#### Usage

    CausalDiscoSearch$set_score(method, params = list())

#### Arguments

- `method`:

  A string specifying the type of score to use.

- `params`:

  A list of parameters to pass to the score function.

------------------------------------------------------------------------

### `CausalDiscoSearch$set_alg()`

Sets the algorithm for the search.

#### Usage

    CausalDiscoSearch$set_alg(method)

#### Arguments

- `method`:

  A string specifying the type of algorithm to use.

------------------------------------------------------------------------

### `CausalDiscoSearch$set_knowledge()`

Sets the background knowledge for the search with a `Knowledge` object.

#### Usage

    CausalDiscoSearch$set_knowledge(kn, directed_as_undirected = FALSE)

#### Arguments

- `kn`:

  A `Knowledge` object.

- `directed_as_undirected`:

  Logical; whether to treat directed edges in the knowledge as
  undirected. Default is `FALSE`. This is due to the nature of how pcalg
  handles background knowledge when using
  [`pcalg::skeleton()`](https://rdrr.io/pkg/pcalg/man/skeleton.html)
  under the hood in
  [`tpc()`](https://disco-coders.github.io/causalDisco/reference/tpc.md)
  and
  [`tfci()`](https://disco-coders.github.io/causalDisco/reference/tfci.md).

------------------------------------------------------------------------

### `CausalDiscoSearch$run_search()`

Runs the search algorithm on the data.

#### Usage

    CausalDiscoSearch$run_search(data = NULL, set_suff_stat = TRUE)

#### Arguments

- `data`:

  A `data.frame` or a `matrix` containing the data.

- `set_suff_stat`:

  Logical; whether to set the sufficient statistic

------------------------------------------------------------------------

### `CausalDiscoSearch$clone()`

The objects of this class are cloneable with this method.

#### Usage

    CausalDiscoSearch$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
# Generally, we do not recommend using the R6 classes directly, but rather
# use the disco() or any method function, for example pc(), instead.

data(tpc_example)

# background knowledge (tiered knowledge)
kn <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    old ~ starts_with("oldage")
  )
)

# Recommended (TPC example):
my_tpc <- tpc(engine = "causalDisco", test = "fisher_z", alpha = 0.05)
result <- disco(data = tpc_example, method = my_tpc, knowledge = kn)
plot(result)


# or
my_tpc <- my_tpc |>
  set_knowledge(kn)
result <- my_tpc(tpc_example)
plot(result)


# Using R6 class:

# --- Constraint-based: TPC ----------------------------------------------------
s_tpc <- CausalDiscoSearch$new()
s_tpc$set_params(list(verbose = FALSE))
s_tpc$set_test("fisher_z", alpha = 0.2)
s_tpc$set_alg("tpc")
s_tpc$set_knowledge(kn, directed_as_undirected = TRUE)
s_tpc$set_data(tpc_example)
res_tpc <- s_tpc$run_search()
print(res_tpc)
#> 
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: UNKNOWN
#> 
#> ── Edges ──
#> 
#>   from      edge  to       
#>   <chr>     <chr> <chr>    
#> 1 child_x1  ---   child_x2 
#> 2 child_x2  -->   oldage_x5
#> 3 child_x2  -->   youth_x4 
#> 4 oldage_x5 -->   oldage_x6
#> 5 youth_x3  -->   oldage_x5
#> 6 youth_x4  -->   oldage_x6
#> ── Nodes ──
#> 
#>   name     
#>   <chr>    
#> 1 child_x2 
#> 2 child_x1 
#> 3 youth_x4 
#> 4 youth_x3 
#> 5 oldage_x6
#> 6 oldage_x5
#> ── Knowledge object ────────────────────────────────────────────────────────────
#> 
#> ── Tiers ──
#> 
#>   tier 
#>   <chr>
#> 1 child
#> 2 youth
#> 3 old  
#> ── Variables ──
#> 
#>   var       tier 
#>   <chr>     <chr>
#> 1 child_x1  child
#> 2 child_x2  child
#> 3 youth_x3  youth
#> 4 youth_x4  youth
#> 5 oldage_x5 old  
#> 6 oldage_x6 old  

# Switch to TFCI on the same object (reuses suff_stat/test)
s_tpc$set_alg("tfci")
res_tfci <- s_tpc$run_search()
print(res_tfci)
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: UNKNOWN
#> 
#> ── Edges ──
#> 
#>   from      edge  to       
#>   <chr>     <chr> <chr>    
#> 1 child_x2  o-o   child_x1 
#> 2 child_x2  o->   oldage_x5
#> 3 child_x2  o->   youth_x4 
#> 4 oldage_x5 -->   oldage_x6
#> 5 youth_x3  o->   oldage_x5
#> 6 youth_x4  -->   oldage_x6
#> ── Nodes ──
#> 
#>   name     
#>   <chr>    
#> 1 child_x2 
#> 2 child_x1 
#> 3 youth_x4 
#> 4 youth_x3 
#> 5 oldage_x6
#> 6 oldage_x5
#> ── Knowledge object ────────────────────────────────────────────────────────────
#> 
#> ── Tiers ──
#> 
#>   tier 
#>   <chr>
#> 1 child
#> 2 youth
#> 3 old  
#> ── Variables ──
#> 
#>   var       tier 
#>   <chr>     <chr>
#> 1 child_x1  child
#> 2 child_x2  child
#> 3 youth_x3  youth
#> 4 youth_x4  youth
#> 5 oldage_x5 old  
#> 6 oldage_x6 old  

# --- Score-based: TGES --------------------------------------------------------
s_tges <- CausalDiscoSearch$new()
s_tges$set_score("tbic") # Gaussian temporal score
s_tges$set_alg("tges")
s_tges$set_data(tpc_example, set_suff_stat = FALSE) # suff stat not used for TGES
s_tges$set_knowledge(kn)
res_tges <- s_tges$run_search()
print(res_tges)
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: PDAG
#> 
#> ── Edges ──
#> 
#>   from      edge  to       
#>   <chr>     <chr> <chr>    
#> 1 child_x1  ---   child_x2 
#> 2 child_x2  -->   oldage_x5
#> 3 child_x2  -->   youth_x4 
#> 4 oldage_x5 -->   oldage_x6
#> 5 youth_x3  -->   oldage_x5
#> 6 youth_x4  -->   oldage_x6
#> ── Nodes ──
#> 
#>   name     
#>   <chr>    
#> 1 child_x2 
#> 2 child_x1 
#> 3 youth_x4 
#> 4 youth_x3 
#> 5 oldage_x6
#> 6 oldage_x5
#> ── Knowledge object ────────────────────────────────────────────────────────────

# --- Intentional error demonstrations ----------------------------------------

# run_search() without setting an algorithm
try(CausalDiscoSearch$new()$run_search(tpc_example))
#> Error : Test must be set before sufficient statistic.

# set_suff_stat() requires data and test first
s_err <- CausalDiscoSearch$new()
try(s_err$set_suff_stat()) # no data & no test
#> Error : Data must be set before sufficient statistic.
s_err$set_data(tpc_example, set_suff_stat = FALSE)
try(s_err$set_suff_stat()) # no test
#> Error : Test must be set before sufficient statistic.

# unknown test / score / algorithm
try(CausalDiscoSearch$new()$set_test("not_a_test"))
#> Error : Unknown method: not_a_test
try(CausalDiscoSearch$new()$set_score("not_a_score"))
#> Error : Unknown score type using causalDisco engine: not_a_score
try(CausalDiscoSearch$new()$set_alg("not_an_alg"))
#> Error : Unknown method type using causalDisco engine: not_an_alg

# set_knowledge() requires a `Knowledge` object
try(CausalDiscoSearch$new()$set_knowledge(list(not = "Knowledge")))
#> Error : Input must be a knowledge instance.
```
