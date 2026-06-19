# R6 Interface to pcalg Search Algorithms

A wrapper that lets you drive pcalg algorithms within the causalDisco
framework. For arguments to the test, score, and algorithm, see the
pcalg documentation, which we link to in the respective sections below.

## Public fields

- `data`:

  A `data.frame` holding the data set currently attached to the search
  object. Can be set with `set_data()`.

- `score`:

  A function that will be used to build the score, when data is set. Can
  be set with `$set_score()`. Recognized values are:

  - `"sem_bic"` - BIC score for Gaussian observed data. See
    [pcalg::GaussL0penObsScore](https://rdrr.io/pkg/pcalg/man/GaussL0penObsScore-class.html).

  - `"sem_bic_int"` - BIC score for Gaussian data from jointly
    interventional and observational Gaussian data. See
    [pcalg::GaussL0penIntScore](https://rdrr.io/pkg/pcalg/man/GaussL0penIntScore-class.html).

- `test`:

  A function that will be used to test independence. Can be set with
  `$set_test()`. Recognized values are:

  - `"fisher_z"` - Fisher Z test for Gaussian data. See
    [`pcalg::gaussCItest()`](https://rdrr.io/pkg/pcalg/man/condIndFisherZ.html).

  - `"fisher_z_twd"` - Fisher Z test for Gaussian data with test-wise
    deletion. See
    [`micd::gaussCItwd()`](https://rdrr.io/pkg/micd/man/gaussCItwd.html).

  - `"fisher_z_mi"` - Fisher Z test for Gaussian data with multiple
    imputation. See
    [`micd::gaussCItestMI()`](https://rdrr.io/pkg/micd/man/gaussMItest.html).

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

  - `"fci"` - FCI algorithm. See
    [`fci()`](https://disco-coders.github.io/causalDisco/reference/fci.md)
    and the underlying
    [`pcalg::fci()`](https://rdrr.io/pkg/pcalg/man/fci.html).

  - `"ges"` - GES algorithm. See
    [`ges()`](https://disco-coders.github.io/causalDisco/reference/ges.md)
    and the underlying
    [`pcalg::ges()`](https://rdrr.io/pkg/pcalg/man/ges.html).

  - `"pc"` - PC algorithm. See
    [`pc()`](https://disco-coders.github.io/causalDisco/reference/pc.md)
    and the underlying
    [`pcalg::pc()`](https://rdrr.io/pkg/pcalg/man/pc.html).

  - `"rfci"` - RFCI algorithm. See
    [`rfci()`](https://disco-coders.github.io/causalDisco/reference/rfci.md)
    and the underlying
    [`pcalg::rfci()`](https://rdrr.io/pkg/pcalg/man/rfci.html).

- `params`:

  A list of parameters for the test and algorithm. Can be set with
  `$set_params()`. The parameters are passed to the test and algorithm
  functions.

- `suff_stat`:

  Sufficient statistic. The format and contents of the sufficient
  statistic depends on which test is being used.

- `continuous`:

  Logical; whether the sufficient statistic is for a continuous test. If
  both continuous and discrete are `TRUE`, the sufficient statistic is
  build for a mixed test.

- `discrete`:

  Logical; whether the sufficient statistic is for a discrete test. If
  both continuous and discrete are `TRUE`, the sufficient statistic is
  build for a mixed test.

- `knowledge`:

  A list of fixed constraints for the search algorithm. Note, that pcalg
  only works with symmetric knowledge. Thus, the only allowed types of
  knowledge is forbidden edges in both directions.

- `adapt_df`:

  Logical; whether to adapt the degrees of freedom for discrete tests.

## Methods

### Public methods

- [`PcalgSearch$new()`](#method-PcalgSearch-initialize)

- [`PcalgSearch$set_params()`](#method-PcalgSearch-set_params)

- [`PcalgSearch$set_data()`](#method-PcalgSearch-set_data)

- [`PcalgSearch$set_suff_stat()`](#method-PcalgSearch-set_suff_stat)

- [`PcalgSearch$set_test()`](#method-PcalgSearch-set_test)

- [`PcalgSearch$set_score()`](#method-PcalgSearch-set_score)

- [`PcalgSearch$set_alg()`](#method-PcalgSearch-set_alg)

- [`PcalgSearch$set_knowledge()`](#method-PcalgSearch-set_knowledge)

- [`PcalgSearch$run_search()`](#method-PcalgSearch-run_search)

- [`PcalgSearch$clone()`](#method-PcalgSearch-clone)

------------------------------------------------------------------------

### `PcalgSearch$new()`

Constructor for the `PcalgSearch` class.

#### Usage

    PcalgSearch$new()

------------------------------------------------------------------------

### `PcalgSearch$set_params()`

Sets the parameters for the test and algorithm.

#### Usage

    PcalgSearch$set_params(params)

#### Arguments

- `params`:

  A list of parameters to set.

------------------------------------------------------------------------

### `PcalgSearch$set_data()`

Sets the data for the search algorithm.

#### Usage

    PcalgSearch$set_data(data, set_suff_stat = TRUE)

#### Arguments

- `data`:

  A `data.frame` or a `matrix` containing the data.

- `set_suff_stat`:

  Logical; whether to set the sufficient statistic. for the data.

------------------------------------------------------------------------

### `PcalgSearch$set_suff_stat()`

Sets the sufficient statistic for the data.

#### Usage

    PcalgSearch$set_suff_stat()

------------------------------------------------------------------------

### `PcalgSearch$set_test()`

Sets the test for the search algorithm.

#### Usage

    PcalgSearch$set_test(method, alpha = 0.05, suff_stat_fun = NULL, args = NULL)

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

### `PcalgSearch$set_score()`

Sets the score for the search algorithm.

#### Usage

    PcalgSearch$set_score(method, params = list())

#### Arguments

- `method`:

  A string specifying the type of score to use.

- `params`:

  A list of parameters to pass to the score function.

------------------------------------------------------------------------

### `PcalgSearch$set_alg()`

Sets the algorithm for the search.

#### Usage

    PcalgSearch$set_alg(method)

#### Arguments

- `method`:

  A string specifying the type of algorithm to use.

------------------------------------------------------------------------

### `PcalgSearch$set_knowledge()`

Sets the knowledge for the search algorithm. Due to the nature of pcalg,
we cannot set knowledge before we run it on data. So we set the function
that will be used to build the fixed constraints, but it can first be
done when data is provided.

#### Usage

    PcalgSearch$set_knowledge(knowledge_obj, directed_as_undirected = FALSE)

#### Arguments

- `knowledge_obj`:

  A `Knowledge` object that contains the fixed constraints.

- `directed_as_undirected`:

  Logical; whether to treat directed edges as undirected.

------------------------------------------------------------------------

### `PcalgSearch$run_search()`

Runs the search algorithm on the data.

#### Usage

    PcalgSearch$run_search(data = NULL, set_suff_stat = TRUE)

#### Arguments

- `data`:

  A `data.frame` or a `matrix` containing the data.

- `set_suff_stat`:

  Logical; whether to set the sufficient statistic

------------------------------------------------------------------------

### `PcalgSearch$clone()`

The objects of this class are cloneable with this method.

#### Usage

    PcalgSearch$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
### pcalg_search R6 class examples ###

# Generally, we do not recommend using the R6 classes directly, but rather
# use the disco() or any method function, for example pc(), instead.

# Load data
data(num_data)

# Recommended:
my_pc <- pc(engine = "pcalg", test = "fisher_z")
my_pc(num_data)
#> 
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: PDAG
#> 
#> ── Edges ──
#> 
#>   from  edge  to   
#>   <chr> <chr> <chr>
#> 1 X1    -->   Y    
#> 2 X1    ---   Z    
#> 3 X2    ---   X3   
#> 4 X2    -->   Y    
#> 5 X3    -->   Y    
#> 6 Z     -->   Y    
#> ── Nodes ──
#> 
#>   name 
#>   <chr>
#> 1 X1   
#> 2 X2   
#> 3 X3   
#> 4 Z    
#> 5 Y    
#> ── Knowledge object ────────────────────────────────────────────────────────────

# or
disco(data = num_data, method = my_pc)
#> 
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: PDAG
#> 
#> ── Edges ──
#> 
#>   from  edge  to   
#>   <chr> <chr> <chr>
#> 1 X1    -->   Y    
#> 2 X1    ---   Z    
#> 3 X2    ---   X3   
#> 4 X2    -->   Y    
#> 5 X3    -->   Y    
#> 6 Z     -->   Y    
#> ── Nodes ──
#> 
#>   name 
#>   <chr>
#> 1 X1   
#> 2 X2   
#> 3 X3   
#> 4 Z    
#> 5 Y    
#> ── Knowledge object ────────────────────────────────────────────────────────────

# Example with detailed settings:
my_pc2 <- pc(
  engine = "pcalg",
  test = "fisher_z",
  alpha = 0.01,
  m.max = 4,
  skel.method = "original"
)

disco(data = num_data, method = my_pc2)
#> 
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: PDAG
#> 
#> ── Edges ──
#> 
#>   from  edge  to   
#>   <chr> <chr> <chr>
#> 1 X1    -->   Y    
#> 2 X2    ---   X3   
#> 3 X2    -->   Y    
#> 4 X3    -->   Y    
#> 5 Z     -->   X1   
#> ── Nodes ──
#> 
#>   name 
#>   <chr>
#> 1 X1   
#> 2 X2   
#> 3 X3   
#> 4 Z    
#> 5 Y    
#> ── Knowledge object ────────────────────────────────────────────────────────────

# With knowledge

kn <- knowledge(
  num_data,
  X1 %!-->% X2,
  X2 %!-->% X1
)

disco(data = num_data, method = my_pc2, knowledge = kn)
#> 
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: PDAG
#> 
#> ── Edges ──
#> 
#>   from  edge  to   
#>   <chr> <chr> <chr>
#> 1 X1    -->   Y    
#> 2 X2    ---   X3   
#> 3 X2    -->   Y    
#> 4 X3    -->   Y    
#> 5 Z     -->   X1   
#> ── Nodes ──
#> 
#>   name 
#>   <chr>
#> 1 X1   
#> 2 X2   
#> 3 X3   
#> 4 Z    
#> 5 Y    
#> ── Knowledge object ────────────────────────────────────────────────────────────
#> 
#> ── Variables ──
#> 
#>   var   tier 
#>   <chr> <chr>
#> 1 X1    NA   
#> 2 X2    NA   
#> 3 X3    NA   
#> 4 Y     NA   
#> 5 Z     NA   
#> ── Edges ──
#> 
#>  ✖  X1 → X2
#>  ✖  X2 → X1

# Using R6 class:
s <- PcalgSearch$new()

s$set_test(method = "fisher_z", alpha = 0.05)
s$set_data(tpc_example)
s$set_alg("pc")

g <- s$run_search()

print(g)
#> ── caugi graph ─────────────────────────────────────────────────────────────────
#> Graph class: PDAG
#> 
#> ── Edges ──
#> 
#>   from      edge  to       
#>   <chr>     <chr> <chr>    
#> 1 child_x1  ---   child_x2 
#> 2 child_x2  -->   oldage_x5
#> 3 child_x2  ---   youth_x4 
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
```
