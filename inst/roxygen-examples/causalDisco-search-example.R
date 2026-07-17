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

# Switch to TFCI on the same object (reuses suff_stat/test)
s_tpc$set_alg("tfci")
res_tfci <- s_tpc$run_search()
print(res_tfci)

# --- Score-based: TGES --------------------------------------------------------
s_tges <- CausalDiscoSearch$new()
s_tges$set_score("tbic") # Gaussian temporal score
s_tges$set_alg("tges")
s_tges$set_data(tpc_example, set_suff_stat = FALSE) # suff stat not used for TGES
s_tges$set_knowledge(kn)
res_tges <- s_tges$run_search()
print(res_tges)

# --- Custom (user-defined) algorithm: constraint-based -----------------------
my_alg <- function(data, knowledge, suff_stat) {
  tpc_run(
    data = data,
    knowledge = knowledge,
    suff_stat = suff_stat,
    test = reg_test
  )
}

s_custom <- CausalDiscoSearch$new()
s_custom$set_test("reg")
s_custom$set_knowledge(kn)
s_custom$set_alg(my_alg) # type = "constraint" by default
s_custom$set_data(tpc_example)
res_custom <- s_custom$run_search()
print(res_custom)

# --- Intentional error demonstrations ----------------------------------------

# run_search() without setting an algorithm
try(CausalDiscoSearch$new()$run_search(tpc_example))

# set_suff_stat() requires data and test first
s_err <- CausalDiscoSearch$new()
try(s_err$set_suff_stat()) # no data & no test
s_err$set_data(tpc_example, set_suff_stat = FALSE)
try(s_err$set_suff_stat()) # no test

# unknown test / score / algorithm
try(CausalDiscoSearch$new()$set_test("not_a_test"))
try(CausalDiscoSearch$new()$set_score("not_a_score"))
try(CausalDiscoSearch$new()$set_alg("not_an_alg"))

# set_knowledge() requires a `Knowledge` object
try(CausalDiscoSearch$new()$set_knowledge(list(not = "Knowledge")))
