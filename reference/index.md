# Package index

## Overview

Package overview

- [`causalDisco`](https://disco-coders.github.io/causalDisco/reference/causalDisco-package.md)
  [`causalDisco-package`](https://disco-coders.github.io/causalDisco/reference/causalDisco-package.md)
  : causalDisco: Causal Discovery in R

## Causal Discovery Interface

High-level interface for running causal discovery.

- [`disco()`](https://disco-coders.github.io/causalDisco/reference/disco.md)
  : Perform Causal Discovery
- [`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md)
  : Define Background Knowledge

## Causal Discovery Algorithms

Core search algorithms implemented or wrapped by causalDisco.

- [`boss()`](https://disco-coders.github.io/causalDisco/reference/boss.md)
  : BOSS Algorithm for Causal Discovery
- [`boss_fci()`](https://disco-coders.github.io/causalDisco/reference/boss_fci.md)
  : BOSS-FCI Algorithm for Causal Discovery
- [`fci()`](https://disco-coders.github.io/causalDisco/reference/fci.md)
  : FCI Algorithm for Causal Discovery
- [`ges()`](https://disco-coders.github.io/causalDisco/reference/ges.md)
  : GES Algorithm for Causal Discovery
- [`gfci()`](https://disco-coders.github.io/causalDisco/reference/gfci.md)
  : GFCI Algorithm for Causal Discovery
- [`grasp()`](https://disco-coders.github.io/causalDisco/reference/grasp.md)
  : GRaSP Algorithm for Causal Discovery
- [`grasp_fci()`](https://disco-coders.github.io/causalDisco/reference/grasp_fci.md)
  : GRaSP-FCI Algorithm for Causal Discovery
- [`gs()`](https://disco-coders.github.io/causalDisco/reference/gs.md) :
  GS Algorithm for Causal Discovery
- [`iamb()`](https://disco-coders.github.io/causalDisco/reference/iamb-family.md)
  [`iamb_fdr()`](https://disco-coders.github.io/causalDisco/reference/iamb-family.md)
  [`fast_iamb()`](https://disco-coders.github.io/causalDisco/reference/iamb-family.md)
  [`inter_iamb()`](https://disco-coders.github.io/causalDisco/reference/iamb-family.md)
  : IAMB Family of Causal Discovery Algorithms
- [`pc()`](https://disco-coders.github.io/causalDisco/reference/pc.md) :
  PC Algorithm for Causal Discovery
- [`rfci()`](https://disco-coders.github.io/causalDisco/reference/rfci.md)
  : RFCI Algorithm for Causal Discovery
- [`sp_fci()`](https://disco-coders.github.io/causalDisco/reference/sp_fci.md)
  : SP-FCI Algorithm for Causal Discovery
- [`tfci()`](https://disco-coders.github.io/causalDisco/reference/tfci.md)
  : TFCI Algorithm for Causal Discovery
- [`tges()`](https://disco-coders.github.io/causalDisco/reference/tges.md)
  : TGES Algorithm for Causal Discovery
- [`tpc()`](https://disco-coders.github.io/causalDisco/reference/tpc.md)
  : TPC Algorithm for Causal Discovery

## R6 Classes

- [`BnlearnSearch`](https://disco-coders.github.io/causalDisco/reference/BnlearnSearch.md)
  : R6 Interface to bnlearn Search Algorithms
- [`CausalDiscoSearch`](https://disco-coders.github.io/causalDisco/reference/CausalDiscoSearch.md)
  : R6 Interface to causalDisco Search Algorithms
- [`PcalgSearch`](https://disco-coders.github.io/causalDisco/reference/PcalgSearch.md)
  : R6 Interface to pcalg Search Algorithms
- [`TetradSearch`](https://disco-coders.github.io/causalDisco/reference/TetradSearch.md)
  : R6 Interface to Tetrad Search Algorithms

## Setup for Tetrad Engine

Functions for installing and verifying the Tetrad Java backend.

- [`install_tetrad()`](https://disco-coders.github.io/causalDisco/reference/install_tetrad.md)
  : Install Tetrad GUI
- [`verify_tetrad()`](https://disco-coders.github.io/causalDisco/reference/verify_tetrad.md)
  : Check Tetrad Installation

## causalDisco Algorithm Run Functions

Low-level functions that execute causalDisco search algorithms and
detail their parameters.

- [`tfci_run()`](https://disco-coders.github.io/causalDisco/reference/tfci_run.md)
  : Run the TFCI Algorithm for Causal Discovery
- [`tges_run()`](https://disco-coders.github.io/causalDisco/reference/tges_run.md)
  : Run the TGES Algorithm for Causal Discovery
- [`tpc_run()`](https://disco-coders.github.io/causalDisco/reference/tpc_run.md)
  : Run the TPC Algorithm for Causal Discovery

## Tests for TPC

Test functions implemented for use in the TPC algorithm.

- [`cor_test()`](https://disco-coders.github.io/causalDisco/reference/cor_test.md)
  : Test for Vanishing Partial Correlations
- [`reg_test()`](https://disco-coders.github.io/causalDisco/reference/reg_test.md)
  : Regression-based Information Loss Test

## Simulation

- [`sim_dag()`](https://disco-coders.github.io/causalDisco/reference/sim_dag.md)
  : Simulate a Random DAG
- [`sim_data()`](https://disco-coders.github.io/causalDisco/reference/sim_data.md)
  : Generate Synthetic Data from a Linear Gaussian DAG

## Example Datasets

Small simulated datasets to illustrate causalDisco workflows.

- [`cat_data`](https://disco-coders.github.io/causalDisco/reference/cat_data.md)
  : Simulated Categorical Data
- [`cat_data_mcar`](https://disco-coders.github.io/causalDisco/reference/cat_data_mcar.md)
  : Simulated Categorical Data with MCAR
- [`cat_ord_data`](https://disco-coders.github.io/causalDisco/reference/cat_ord_data.md)
  : Simulated Ordered Categorical Data
- [`mix_data`](https://disco-coders.github.io/causalDisco/reference/mix_data.md)
  : Simulated Mixed Data
- [`nlsy97`](https://disco-coders.github.io/causalDisco/reference/nlsy97.md)
  : US National Longitudinal Survey of Youth 1997
- [`num_data`](https://disco-coders.github.io/causalDisco/reference/num_data.md)
  : Simulated Numerical Data
- [`num_data_latent`](https://disco-coders.github.io/causalDisco/reference/num_data_latent.md)
  : Simulated Numerical Data with Latent Variable
- [`tpc_example`](https://disco-coders.github.io/causalDisco/reference/tpc_example.md)
  : Simulated Life-Course Data

## Printing, Summarizing, and Plotting Objects

- [`print(`*`<Disco>`*`)`](https://disco-coders.github.io/causalDisco/reference/print.Disco.md)
  : Print a Disco Object
- [`print(`*`<Knowledge>`*`)`](https://disco-coders.github.io/causalDisco/reference/print.Knowledge.md)
  : Print a Knowledge Object
- [`summary(`*`<Disco>`*`)`](https://disco-coders.github.io/causalDisco/reference/summary.Disco.md)
  **\[deprecated\]** : Summarize a Disco Object
- [`summary(`*`<Knowledge>`*`)`](https://disco-coders.github.io/causalDisco/reference/summary.Knowledge.md)
  **\[deprecated\]** : Summarize a Knowledge Object
- [`plot(`*`<Disco>`*`)`](https://disco-coders.github.io/causalDisco/reference/plot.Disco.md)
  : Plot a Disco Object
- [`plot(`*`<Knowledge>`*`)`](https://disco-coders.github.io/causalDisco/reference/plot.Knowledge.md)
  : Plot a Knowledge Object
- [`plot`](https://disco-coders.github.io/causalDisco/reference/plot.md)
  : Plot Method for causalDisco Objects
- [`make_tikz()`](https://disco-coders.github.io/causalDisco/reference/make_tikz.md)
  : Generate TikZ Code from a Causal Graph

## Graph Metrics

- [`confusion()`](https://disco-coders.github.io/causalDisco/reference/confusion.md)
  : Confusion Matrix
- [`evaluate()`](https://disco-coders.github.io/causalDisco/reference/evaluate.md)
  : Evaluate Causal Graph Estimates
- [`f1_score()`](https://disco-coders.github.io/causalDisco/reference/f1_score.md)
  : F1 score
- [`false_omission_rate()`](https://disco-coders.github.io/causalDisco/reference/false_omission_rate.md)
  : False Omission Rate
- [`fdr()`](https://disco-coders.github.io/causalDisco/reference/fdr.md)
  : False Discovery Rate
- [`g1_score()`](https://disco-coders.github.io/causalDisco/reference/g1_score.md)
  : G1 score
- [`npv()`](https://disco-coders.github.io/causalDisco/reference/npv.md)
  : Negative Predictive Value
- [`precision()`](https://disco-coders.github.io/causalDisco/reference/precision.md)
  : Precision
- [`recall()`](https://disco-coders.github.io/causalDisco/reference/recall.md)
  : Recall
- [`specificity()`](https://disco-coders.github.io/causalDisco/reference/specificity.md)
  : Specificity
- [`reexports`](https://disco-coders.github.io/causalDisco/reference/reexports.md)
  [`shd`](https://disco-coders.github.io/causalDisco/reference/reexports.md)
  [`hd`](https://disco-coders.github.io/causalDisco/reference/reexports.md)
  [`aid`](https://disco-coders.github.io/causalDisco/reference/reexports.md)
  : Objects exported from other packages

## Knowledge helpers

- [`add_exogenous()`](https://disco-coders.github.io/causalDisco/reference/add_exogenous.md)
  [`add_exo()`](https://disco-coders.github.io/causalDisco/reference/add_exogenous.md)
  : Add Exogenous Variables to Knowledge
- [`add_tier()`](https://disco-coders.github.io/causalDisco/reference/add_tier.md)
  : Add a Tier to Knowledge
- [`add_to_tier()`](https://disco-coders.github.io/causalDisco/reference/add_to_tier.md)
  : Add Variables to a Tier in Knowledge
- [`add_vars()`](https://disco-coders.github.io/causalDisco/reference/add_vars.md)
  : Add Variables to Knowledge
- [`as_bnlearn_knowledge()`](https://disco-coders.github.io/causalDisco/reference/as_bnlearn_knowledge.md)
  : Convert Knowledge to bnlearn Knowledge
- [`as_pcalg_constraints()`](https://disco-coders.github.io/causalDisco/reference/as_pcalg_constraints.md)
  : Convert Knowledge to pcalg Knowledge
- [`as_tetrad_knowledge()`](https://disco-coders.github.io/causalDisco/reference/as_tetrad_knowledge.md)
  : Convert Knowledge to Tetrad Knowledge
- [`convert_tiers_to_forbidden()`](https://disco-coders.github.io/causalDisco/reference/convert_tiers_to_forbidden.md)
  : Convert Tiered Knowledge to Forbidden Knowledge
- [`deparse_knowledge()`](https://disco-coders.github.io/causalDisco/reference/deparse_knowledge.md)
  : Deparse a Knowledge Object into Knowledge DSL Code
- [`forbid_edge()`](https://disco-coders.github.io/causalDisco/reference/forbid_edge.md)
  : Add Forbidden Edges to Knowledge
- [`get_tiers()`](https://disco-coders.github.io/causalDisco/reference/get_tiers.md)
  : Get Tiers from Knowledge
- [`knowledge()`](https://disco-coders.github.io/causalDisco/reference/knowledge.md)
  : Define Background Knowledge
- [`knowledge_to_caugi()`](https://disco-coders.github.io/causalDisco/reference/knowledge_to_caugi.md)
  : Convert Knowledge to Caugi
- [`` `+`( ``*`<Knowledge>`*`)`](https://disco-coders.github.io/causalDisco/reference/plus-.Knowledge.md)
  : Merge Knowledge Objects
- [`remove_edge()`](https://disco-coders.github.io/causalDisco/reference/remove_edge.md)
  : Remove an Edge from Knowledge
- [`remove_tiers()`](https://disco-coders.github.io/causalDisco/reference/remove_tiers.md)
  : Remove Tiers from Knowledge
- [`remove_vars()`](https://disco-coders.github.io/causalDisco/reference/remove_vars.md)
  : Remove Variables from Knowledge
- [`reorder_tiers()`](https://disco-coders.github.io/causalDisco/reference/reorder_tiers.md)
  : Reorder Tiers in Knowledge
- [`reposition_tier()`](https://disco-coders.github.io/causalDisco/reference/reposition_tier.md)
  : Move a Tier Relative to Another in Knowledge
- [`require_edge()`](https://disco-coders.github.io/causalDisco/reference/require_edge.md)
  : Add Required Edges to Knowledge
- [`seq_tiers()`](https://disco-coders.github.io/causalDisco/reference/seq_tiers.md)
  : Generate a Bundle of Tier–Variable Formulas
- [`set_knowledge()`](https://disco-coders.github.io/causalDisco/reference/set_knowledge.md)
  : Set Background Knowledge to Disco Method
- [`unfreeze()`](https://disco-coders.github.io/causalDisco/reference/unfreeze.md)
  : Unfreeze a Knowledge Object.

## Extend causalDisco

Functions for extending causalDisco with new algorithms from the
available engines.

- [`as_disco()`](https://disco-coders.github.io/causalDisco/reference/as_disco.md)
  : Wrap a Graph as a Disco Object
- [`distribute_engine_args()`](https://disco-coders.github.io/causalDisco/reference/distribute_engine_args.md)
  : Distribute and Validate Engine Arguments
- [`list_registered_engines()`](https://disco-coders.github.io/causalDisco/reference/list_registered_engines.md)
  : List Registered Engines
- [`list_registered_tetrad_algorithms()`](https://disco-coders.github.io/causalDisco/reference/list_registered_tetrad_algorithms.md)
  : List Registered Tetrad Algorithms
- [`make_method()`](https://disco-coders.github.io/causalDisco/reference/make_method.md)
  **\[experimental\]** : Create a Custom Causal Discovery Method
- [`make_runner()`](https://disco-coders.github.io/causalDisco/reference/make_runner.md)
  **\[experimental\]** : Create a Custom Runner for a Causal Discovery
  Algorithm
- [`new_disco_method()`](https://disco-coders.github.io/causalDisco/reference/new_disco_method.md)
  : Add a New causalDisco Method
- [`register_engine()`](https://disco-coders.github.io/causalDisco/reference/register_engine.md)
  : Register a New Engine
- [`register_tetrad_algorithm()`](https://disco-coders.github.io/causalDisco/reference/register_tetrad_algorithm.md)
  : Register a New Tetrad Algorithm
- [`reset_engine_registry()`](https://disco-coders.github.io/causalDisco/reference/reset_engine_registry.md)
  : Reset the Engine Registry
- [`reset_tetrad_alg_registry()`](https://disco-coders.github.io/causalDisco/reference/reset_tetrad_alg_registry.md)
  : Reset the Tetrad Algorithm Registry
