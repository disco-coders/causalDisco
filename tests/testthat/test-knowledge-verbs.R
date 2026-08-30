# ──────────────────────────────────────────────────────────────────────────────
# add_vars()
# ──────────────────────────────────────────────────────────────────────────────

test_that("add_vars adds new vars and ignores existing ones (unfrozen)", {
  kn <- knowledge()
  kn <- add_vars(kn, c("A", "B"))
  expect_equal(
    kn$vars,
    tibble::tibble(var = c("A", "B"), tier = NA_character_)
  )

  kn2 <- add_vars(kn, c("A", "B")) # duplicates supplied again
  expect_equal(nrow(kn2$vars), 2L)
})

test_that("add_vars respects frozen Knowledge objects", {
  kn_frozen <- knowledge(data.frame(A = 1, B = 2, check.names = FALSE))

  expect_silent(add_vars(kn_frozen, c("A"))) # existing var is OK
  expect_error(
    add_vars(kn_frozen, c("A", "C")), # new var should fail
    "Unknown variable(s): [C]",
    fixed = TRUE
  )
})

test_that("add_vars validates input types", {
  expect_error(add_vars("not_kn", c("X")), "knowledge")
  expect_error(add_vars(knowledge(), X))
})

# ──────────────────────────────────────────────────────────────────────────────
# forbidden and required
# ──────────────────────────────────────────────────────────────────────────────

test_that("forbid_edge() and require_edge() add single edges", {
  kn <- knowledge()
  kn_f <- forbid_edge(kn, V1 ~ V2)
  expect_equal(
    kn_f$edges,
    tibble::tibble(
      status = "forbidden",
      from = "V1",
      to = "V2",
      tier_from = NA_character_,
      tier_to = NA_character_
    )
  )

  kn_r <- require_edge(kn, V1 ~ V2)
  expect_equal(kn_r$edges$status, "required")
  expect_equal(kn_r$edges$from, "V1")
  expect_equal(kn_r$edges$to, "V2")
})

test_that("forbid_edge() and require_edge() need two-sided formulas", {
  kn <- knowledge()
  expect_error(forbid_edge(kn), "needs at least one")
  expect_error(forbid_edge(kn, V1), "two-sided formula")
  expect_error(require_edge(kn, 1), "two-sided formula")
})

test_that("forbid_edge()/require_edge() respect tidy-select on either side", {
  kn <- knowledge(
    tier(
      T1 ~ Y,
      T2 ~ X1 + X2
    )
  )
  kn <- forbid_edge(
    kn,
    starts_with("X") ~ Y # X1 → Y, X2 → Y
  )
  expect_equal(
    dplyr::arrange(kn$edges, from)$from,
    c("X1", "X2")
  )
  expect_true(all(kn$edges$to == "Y"))

  kn2 <- require_edge(kn, Y ~ matches("^X[12]$"))
  expect_equal(
    sort(kn2$edges$status),
    c("forbidden", "forbidden", "required", "required")
  )
})

test_that("forbidden and required inside knowledge() create edges", {
  kn <- knowledge(
    tier(
      A ~ V1,
      B ~ V2,
      C ~ Y
    ),
    starts_with("V") %!-->% Y,
    V1 %-->% V2
  )
  expect_equal(
    kn$edges$status,
    c("forbidden", "forbidden", "required")
  )
  expect_equal(
    kn$edges$from,
    c("V1", "V2", "V1")
  )
  expect_equal(
    kn$edges$to,
    c("Y", "Y", "V2")
  )
  kn <- knowledge(
    tier(
      A ~ V1,
      B ~ V2,
      C ~ V3
    ),
    starts_with("V") %!-->% V3, # will not forbid self loop
    V1 %-->% V2
  )
  expect_equal(
    kn$edges$status,
    c("forbidden", "forbidden", "required")
  )
  expect_equal(
    kn$edges$from,
    c("V1", "V2", "V1")
  )
  expect_equal(
    kn$edges$to,
    c("V3", "V3", "V2")
  )
})

test_that("knowledge() errors on forbidden + required clash", {
  expect_error(
    knowledge(
      V1 %!-->% V2,
      V1 %-->% V2
    ),
    "appear as both forbidden and required",
    fixed = TRUE
  )
})

test_that("knowledge() errors when required edges are bidirectional", {
  expect_error(
    knowledge(
      V1 %-->% V2,
      V2 %-->% V1
    ),
    "required in both directions",
    fixed = TRUE
  )
})

test_that("knowledge() rejects unknown top-level calls", {
  expect_error(
    knowledge(foo(V1)),
    "Only tier(), exogenous(), max_lag(), and infix edge operators (%-->%, %!-->%) are allowed.",
    fixed = TRUE
  )
})

test_that("require_edge() errors when called with no formulas", {
  kn <- knowledge() # empty Knowledge object

  expect_error(
    require_edge(kn), # no ... arguments
    "require_edge() needs at least one two-sided formula.",
    fixed = TRUE
  )
})

# ──────────────────────────────────────────────────────────────────────────────
# exogenous() or exo()
# ──────────────────────────────────────────────────────────────────────────────

test_that("exogenous() creates a variable that has all ingoing nodes forbidden", {
  kn <- knowledge(
    data.frame(A = 1, B = 2, C = 3),
    exogenous(A)
  )

  expect_equal(kn$vars$var, c("A", "B", "C"))
  expect_equal(kn$edges$status, c("forbidden", "forbidden"))
  expect_equal(kn$edges$from, c("B", "C"))
  expect_equal(kn$edges$to, c("A", "A"))
})

test_that("exogenous() can take a list of variables", {
  kn <- knowledge(
    data.frame(A = 1, B = 2, C = 3),
    exogenous(c(A, B))
  )

  expect_equal(kn$vars$var, c("A", "B", "C"))
  expect_equal(
    kn$edges$status,
    c("forbidden", "forbidden", "forbidden", "forbidden")
  )
  expect_equal(kn$edges$from, c("A", "B", "C", "C"))
  expect_equal(kn$edges$to, c("B", "A", "A", "B"))
})

test_that("exo() is an alias for exogenous()", {
  kn1 <- knowledge(
    data.frame(A = 1, B = 2, C = 3),
    exo(A)
  )

  kn2 <- knowledge(
    data.frame(A = 1, B = 2, C = 3),
    exogenous(A)
  )

  expect_equal(kn1, kn2)
})

test_that("exogenous() works with multiple variables specified in different ways", {
  my_df <- data.frame(X1 = 1, X11 = 2, Y = 3)
  kn1 <- knowledge(
    my_df,
    exo(c(X1, X11))
  )

  kn2 <- knowledge(
    my_df,
    exo(X1, X11)
  )

  kn3 <- knowledge(
    my_df,
    exo(starts_with("X"))
  )

  kn4 <- knowledge(
    my_df,
    exo(ends_with("1"))
  )
  expect_equal(kn1, kn2)
  expect_equal(kn1, kn3)
  expect_equal(kn1, kn4)
})

test_that("exogenous() with no variables errors", {
  expect_error(
    knowledge(
      data.frame(A = 1, B = 2, C = 3),
      exogenous()
    ),
    "exogenous() needs at least one variable specification.",
    fixed = TRUE
  )
})

test_that("exogenous() gives error for non-existent variables", {
  expect_error(
    knowledge(
      data.frame(A = 1, B = 2, C = 3),
      exogenous(D)
    ),
    "Unknown variable(s): [D]",
    fixed = TRUE
  )
})

test_that("exogenous() handles duplicate variables gracefully", {
  kn1 <- knowledge(
    data.frame(A = 1, B = 2, C = 3),
    exogenous(c(A, A))
  )

  kn2 <- knowledge(
    data.frame(A = 1, B = 2, C = 3),
    exogenous(A)
  )

  expect_equal(kn1, kn2)
})

test_that("multiple calls of exogenous() accumulate correctly", {
  kn <- knowledge(
    data.frame(A = 1, B = 2, C = 3),
    exogenous(A),
    exogenous(B)
  )

  expect_equal(
    kn$edges$status,
    c("forbidden", "forbidden", "forbidden", "forbidden")
  )
  expect_setequal(kn$edges$from, c("B", "C", "A", "C"))
  expect_setequal(kn$edges$to, c("A", "A", "B", "B"))
})

test_that("exogenous() is invariant to order of variables", {
  kn1 <- knowledge(
    data.frame(A = 1, B = 2, C = 3),
    exogenous(c(A, B))
  )

  kn2 <- knowledge(
    data.frame(A = 1, B = 2, C = 3),
    exogenous(c(B, A))
  )

  expect_equal(kn1, kn2)
})

test_that("exogenous() errors when it conflicts with required", {
  expect_error(
    knowledge(
      data.frame(A = 1, B = 2),
      B %-->% A,
      exogenous(A)
    ),
    "appear as both forbidden and required"
  )
})

test_that("exogenous() is idempotent", {
  kn1 <- knowledge(data.frame(A = 1, B = 2, C = 3), exogenous(A))
  kn2 <- knowledge(data.frame(A = 1, B = 2, C = 3), exogenous(c(A, A)))
  expect_equal(kn1, kn2)
})

test_that("exogenous() on unknown var errors when frozen", {
  kn <- knowledge(data.frame(A = 1, B = 2))
  expect_error(
    add_exo(kn, C),
    "Unknown variable"
  )
})

# ──────────────────────────────────────────────────────────────────────────────
# remove functions
# ──────────────────────────────────────────────────────────────────────────────

test_that("remove_edge() drops forbidden and required edges", {
  kn <- knowledge(
    data.frame(A = 1, B = 2, C = 3, D = 4),
    tier(1 ~ A + B, 2 ~ C, 3 ~ D),
    A %!-->% C,
    B %!-->% D,
    B %-->% C,
    C %-->% D
  )
  # check edges present
  expect_true(any(
    kn$edges$status == "forbidden" & kn$edges$from == "A" & kn$edges$to == "C"
  ))
  expect_true(any(
    kn$edges$status == "required" & kn$edges$from == "C" & kn$edges$to == "D"
  ))
  # remove a forbidden edge
  kn2 <- remove_edge(kn, A, C)
  expect_false(any(kn2$edges$from == "A" & kn2$edges$to == "C"))
  # remove a required edge
  kn3 <- remove_edge(kn, C, D)
  expect_false(any(kn3$edges$from == "C" & kn3$edges$to == "D"))
  # other edges remain
  expect_true(any(kn3$edges$from == "B" & kn3$edges$to == "D"))
})

test_that("remove_edge() warns if no edges matched", {
  kn <- knowledge(
    data.frame(A = 1, B = 2),
    A %!-->% B
  )
  expect_error(
    remove_edge(kn, B, C),
    "Edge from",
    fixed = TRUE
  )
})

test_that("remove_vars() drops vars and associated edges", {
  kn <- knowledge(
    data.frame(A = 1, B = 2, C = 3),
    A %!-->% B,
    B %-->% C
  )
  expect_true("B" %in% kn$vars$var)
  expect_true(any(kn$edges$to == "B" | kn$edges$from == "B"))
  kn2 <- remove_vars(kn, B)
  expect_false("B" %in% kn2$vars$var)
  expect_false(any(kn2$edges$from == "B" | kn2$edges$to == "B"))
})

test_that("remove_vars() accepts tidyselect and character vector", {
  kn <- knowledge(
    data.frame(foo = 1, bar = 2, baz = 3),
    foo %!-->% bar,
    bar %!-->% baz
  )
  kn2 <- remove_vars(kn, starts_with("ba"))
  expect_false(any(grepl("^ba", kn2$vars$var)))
  kn3 <- remove_vars(kn, c("foo", "baz"))
  expect_false(any(kn3$vars$var %in% c("foo", "baz")))
})

test_that("remove_vars() errors on no matches", {
  kn <- knowledge(data.frame(A = 1, B = 2))
  expect_error(
    remove_vars(kn, X),
    "matched no variables"
  )
})

test_that("remove_tiers() drops tier and resets vars", {
  kn <- knowledge(
    data.frame(A = 1, B = 2, C = 3),
    tier("alpha" ~ A + B, "beta" ~ C)
  )
  expect_true("alpha" %in% kn$tiers$label)
  expect_equal(kn$vars$tier[kn$vars$var == "A"], "alpha")
  kn2 <- remove_tiers(kn, "alpha")
  expect_false("alpha" %in% kn2$tiers$label)
  expect_true(is.na(kn2$vars$tier[kn2$vars$var == "A"]))
})

test_that("remove_tiers() accepts numeric index", {
  kn <- knowledge(
    data.frame(A = 1, B = 2, C = 3),
    tier(1 ~ A, 2 ~ B, 3 ~ C)
  )
  # remove second tier (label "2")
  kn2 <- remove_tiers(kn, 2)
  expect_false("2" %in% kn2$tiers$label)
  expect_true(is.na(kn2$vars$tier[kn2$vars$var == "B"]))
})

test_that("remove_tiers() no-op if no match", {
  kn <- knowledge(
    data.frame(X = 1, Y = 2),
    tier("t1" ~ X, "t2" ~ Y)
  )
  kn2 <- remove_tiers(kn, "none")
  expect_identical(kn2, kn)
})

test_that("chaining remove_* works together", {
  kn <- knowledge(
    data.frame(A = 1, B = 2, C = 3, D = 4),
    tier(1 ~ A + B, 2 ~ C, 3 ~ D),
    A %!-->% C,
    B %-->% D
  )
  kn2 <- kn |>
    remove_edge(A, C) |>
    remove_vars(D) |>
    remove_tiers(3)
  expect_false(any(kn2$edges$from == "A" & kn2$edges$to == "C"))
  expect_false("D" %in% kn2$vars$var)
  expect_false("3" %in% kn2$tiers$label)
})

# ──────────────────────────────────────────────────────────────────────────────
#   forbid_tier_violations()
# ──────────────────────────────────────────────────────────────────────────────

test_that("forbid_tier_violations() adds exactly the uphill edges", {
  kn <- knowledge(
    tier(
      1 ~ V1 + V2,
      2 ~ V3,
      3 ~ V4 + V5
    )
  )

  expect_equal(nrow(kn$edges), 0) # sanity: no edges yet

  kn2 <- forbid_tier_violations(kn)

  edges <- dplyr::filter(kn2$edges, status == "forbidden")

  # 8 total
  expect_equal(nrow(edges), 8)

  # every forbidden edge must go *downhill*
  expect_true(all(edges$tier_from > edges$tier_to))

  # spot–check one edge from each block
  expect_true(any(edges$from == "V4" & edges$to == "V1"))
  expect_true(any(edges$from == "V3" & edges$to == "V1"))
})

test_that("calling it again is a no-op (no duplicate edges)", {
  kn <- knowledge(tier(1 ~ V1, 2 ~ V2))
  kn1 <- forbid_tier_violations(kn)
  kn2 <- forbid_tier_violations(kn1)

  expect_equal(nrow(kn1$edges), nrow(kn2$edges))
})

test_that("single-tier or untiered variables add no edges", {
  # single tier
  kn_single <- knowledge(tier(1 ~ V1 + V2 + V3))
  kn_single <- forbid_tier_violations(kn_single)
  expect_equal(nrow(kn_single$edges), 0)

  # untiered variables
  my_df <- data.frame(V1 = 1, V2 = 1, V3 = 1)
  kn_mixed <- knowledge(my_df, tier(1 ~ V1 + V2)) # V3 has tier NA
  kn_mixed <- forbid_tier_violations(kn_mixed)
  expect_equal(nrow(kn_mixed$edges), 0) # NA tiers ignored
})

test_that("function errors on non-Knowledge objects", {
  expect_error(forbid_tier_violations(list()), "knowledge")
})

# ──────────────────────────────────────────────────────────────────────────────
#   max_lag
# ──────────────────────────────────────────────────────────────────────────────

test_that("set_max_lag() requires tiers to exist first", {
  kn <- knowledge()
  expect_error(set_max_lag(kn, 1), "tiers to be defined first")
})

test_that("set_max_lag() warns when max_lag has no effect", {
  kn <- knowledge(tier(1 ~ V1, 2 ~ V2, 3 ~ V3))
  expect_warning(set_max_lag(kn, 5), "has no effect")
})

test_that("max_lag() inside knowledge() stores kn$max_lag", {
  kn <- knowledge(tier(1 ~ V1, 2 ~ V2, 3 ~ V3, 4 ~ V4), max_lag(2))
  expect_identical(kn$max_lag, 2L)
})

test_that("set_max_lag() forbids too-far edges immediately, visible in kn$edges", {
  kn <- knowledge(
    tier(1 ~ V1, 2 ~ V2, 3 ~ V3, 4 ~ V4),
    max_lag(1)
  )

  edges <- dplyr::filter(kn$edges, status == "forbidden")
  has_edge <- function(f, t) any(edges$from == f & edges$to == t)

  # within max_lag: untouched
  expect_false(has_edge("V1", "V2"))
  expect_false(has_edge("V2", "V3"))

  # skips more than max_lag:
  expect_true(has_edge("V1", "V3"))
  expect_true(has_edge("V1", "V4"))
  expect_true(has_edge("V2", "V4"))

  # backward edges are governed by tier order:
  expect_false(has_edge("V4", "V1"))
})

test_that("convert_tiers_to_forbidden() clears max_lag after materializing tier order", {
  kn <- knowledge(tier(1 ~ V1, 2 ~ V2, 3 ~ V3), max_lag(1))
  kn2 <- convert_tiers_to_forbidden(kn)

  expect_true(any(kn2$edges$from == "V1" & kn2$edges$to == "V3"))
  expect_true(is.na(kn2$max_lag))
})

test_that("variables added to a tier after set_max_lag() are not retroactively covered", {
  kn <- knowledge(tier(1 ~ V1, 2 ~ V2, 3 ~ V3, 4 ~ V4), max_lag(1))
  kn <- add_to_tier(kn, "1" ~ V5)

  edges <- dplyr::filter(kn$edges, status == "forbidden")
  expect_false(any(edges$from == "V5" & edges$to == "V3"))
})

test_that("convert tiers to forbidden works", {
  kn <- knowledge(
    tier(
      1 ~ V1 + V2,
      2 ~ V3,
      3 ~ V4 + V5
    )
  )

  kn_converted <- convert_tiers_to_forbidden(kn)
  expect_equal(kn_converted$vars$tier, rep((NA_character_), 5))
  expect_equal(
    dplyr::arrange(kn_converted$edges, from, to),
    tibble::tibble(
      status = rep("forbidden", 8),
      from = c("V3", "V3", "V4", "V4", "V4", "V5", "V5", "V5"),
      to = c("V1", "V2", "V1", "V2", "V3", "V1", "V2", "V3"),
      tier_from = rep(NA_character_, 8),
      tier_to = rep(NA_character_, 8)
    )
  )
})

# ──────────────────────────────────────────────────────────────────────────────
# Add to tier verb
# ──────────────────────────────────────────────────────────────────────────────

test_that("add_to_tier() works as expected", {
  kn <- knowledge() |>
    add_tier(One) |>
    add_to_tier(One ~ V1 + V2)
  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = c("One")
    )
  )
  expect_equal(
    kn$vars,
    tibble::tibble(
      var = c("V1", "V2"),
      tier = c("One", "One")
    )
  )
})

test_that("add_to_tier() works as expected with mini-DSL", {
  kn <- knowledge(
    tier(
      One ~ V1 + V2,
      2 ~ V3 + V4,
      "Three" ~ V5
    )
  ) |>
    add_to_tier(One ~ V6)
  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = c("One", "2", "Three")
    )
  )
  expect_equal(
    kn$vars,
    tibble::tibble(
      var = c("V1", "V2", "V6", "V3", "V4", "V5"),
      tier = c("One", "One", "One", "2", "2", "Three")
    )
  )
})
