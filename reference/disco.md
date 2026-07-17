# Perform Causal Discovery

Apply a causal discovery method to a data frame to infer causal
relationships on observational data. Supports multiple algorithms and
optionally incorporates prior knowledge.

## Usage

``` r
disco(data, method, knowledge = NULL)
```

## Arguments

- data:

  A data frame.

- method:

  A `disco_method` object representing a causal discovery algorithm.
  Available methods are

  - [`boss()`](https://disco-coders.github.io/causalDisco/reference/boss.md) -
    BOSS algorithm,

  - [`boss_fci()`](https://disco-coders.github.io/causalDisco/reference/boss_fci.md) -
    BOSS-FCI algorithm,

  - [`fci()`](https://disco-coders.github.io/causalDisco/reference/fci.md) -
    FCI algorithm,

  - [`gfci()`](https://disco-coders.github.io/causalDisco/reference/gfci.md) -
    GFCI algorithm,

  - [`ges()`](https://disco-coders.github.io/causalDisco/reference/ges.md) -
    GES algorithm,

  - [`grasp()`](https://disco-coders.github.io/causalDisco/reference/grasp.md) -
    GRaSP algorithm,

  - [`grasp_fci()`](https://disco-coders.github.io/causalDisco/reference/grasp_fci.md) -
    GRaSP-FCI algorithm,

  - [`gs()`](https://disco-coders.github.io/causalDisco/reference/gs.md) -
    GS algorithm,

  - [`iamb()`](https://disco-coders.github.io/causalDisco/reference/iamb-family.md),
    [`iamb_fdr()`](https://disco-coders.github.io/causalDisco/reference/iamb-family.md),
    [`fast_iamb()`](https://disco-coders.github.io/causalDisco/reference/iamb-family.md),
    [`inter_iamb()`](https://disco-coders.github.io/causalDisco/reference/iamb-family.md) -
    IAMB algorithms,

  - [`pc()`](https://disco-coders.github.io/causalDisco/reference/pc.md) -
    PC algorithm,

  - [`sp_fci()`](https://disco-coders.github.io/causalDisco/reference/sp_fci.md) -
    SP-FCI algorithm,

  - [`tfci()`](https://disco-coders.github.io/causalDisco/reference/tfci.md) -
    TFCI algorithm,

  - [`tges()`](https://disco-coders.github.io/causalDisco/reference/tges.md) -
    TGES algorithm,

  - [`tpc()`](https://disco-coders.github.io/causalDisco/reference/tpc.md) -
    TPC algorithm.

- knowledge:

  A `Knowledge` object to be incorporated into the causal discovery
  algorithm. If `NULL` (default), the causal discovery algorithm is run
  without background knowledge. See
  [`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md)
  for how to create a `Knowledge` object.

## Value

A `Disco` object (a list) containing the following components:

- `knowledge` A `Knowledge` object with the background knowledge used in
  the causal discovery algorithm.

- `caugi` A [caugi::caugi](https://caugi.org/reference/caugi.html)
  object representing the learned causal graph from the causal discovery
  algorithm.

- `graph_type` A string with the semantic class of the learned graph
  (e.g. `"CPDAG"`, `"MPDAG"`, or `"PAG"`).

Constraint-based algorithms may output graphs that are not valid
CPDAGs/MPDAGs due to statistical errors in finite samples, violations of
faithfulness, or latent confounding. In that case `disco()` emits a
message and downgrades `graph_type`.

## Details

For specific details on the supported algorithms, scores, tests, and
parameters for each engine, see:

- [BnlearnSearch](https://disco-coders.github.io/causalDisco/reference/BnlearnSearch.md)
  for bnlearn,

- [CausalDiscoSearch](https://disco-coders.github.io/causalDisco/reference/CausalDiscoSearch.md)
  for causalDisco,

- [PcalgSearch](https://disco-coders.github.io/causalDisco/reference/PcalgSearch.md)
  for pcalg,

- [TetradSearch](https://disco-coders.github.io/causalDisco/reference/TetradSearch.md)
  for Tetrad.

## Examples

``` r
data(tpc_example)

# use pc with engine bnlearn and test fisher_z
my_pc <- pc(engine = "bnlearn", test = "fisher_z", alpha = 0.01)
pc_bnlearn <- disco(data = tpc_example, method = my_pc)
#> Warning: vstructure youth_x4 -> oldage_x6 <- oldage_x5 is not applicable, because one or both arcs are oriented in the opposite direction.
plot(pc_bnlearn)


# define tiered background knowledge
kn <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    old ~ starts_with("old")
  )
)

# use gs with engine bnlearn and test cor and tiered background knowledge
my_pc_tiered <- pc(engine = "bnlearn", test = "cor", alpha = 0.01)
pc_tiered_bnlearn <- disco(
  data = tpc_example,
  method = my_pc_tiered,
  knowledge = kn
)
#> Warning: vstructure youth_x4 -> oldage_x6 <- oldage_x5 is not applicable, because one or both arcs are oriented in the opposite direction.
plot(pc_tiered_bnlearn)
```
