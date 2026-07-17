# Knowledge tests

# ──────────────────────────────────────────────────────────────────────────────
# Knowledge generation using mini-dsl
# ──────────────────────────────────────────────────────────────────────────────

test_that("Knowledge object is created correctly using mini-DSL", {
  kn <- knowledge(
    tier(
      1 ~ V1 + V2,
      2 ~ V3,
      3 ~ c(V4, V5)
    ),
    V1 %!-->% V3,
    V1 %-->% V2,
    V2 %-->% V3
  )
  expect_equal(
    kn$vars,
    tibble::tibble(
      var = c("V1", "V2", "V3", "V4", "V5"),
      tier = c("1", "1", "2", "3", "3")
    )
  )
  expect_equal(kn$frozen, FALSE)
  expect_equal(
    kn$edges,
    tibble::tibble(
      status = c("forbidden", "required", "required"),
      from = c("V1", "V1", "V2"),
      to = c("V3", "V2", "V3"),
      tier_from = c("1", "1", "1"),
      tier_to = c("2", "1", "2")
    )
  )
  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = c("1", "2", "3")
    )
  )
})

test_that("infix edges before tier() do not drop variables from tier() (no data frame)", {
  kn <- knowledge(
    A %-->% C,
    C %!-->% D,
    tier(
      1 ~ A + B,
      2 ~ C + D
    )
  )
  expect_equal(sort(kn$vars$var), c("A", "B", "C", "D"))
  expect_equal(kn$vars$tier[kn$vars$var == "B"], "1")
})

# seeding with data frame
test_that("seeding Knowledge object with a my_df, matrix, or tibble works", {
  my_df <- data.frame(X1 = 1, X2 = 2, X3 = 3, X4 = 4, check.names = FALSE)
  tbl <- tibble::as_tibble(my_df)
  mat <- as.matrix(my_df)
  kn <-
    knowledge(
      my_df,
      tier(1 ~ X1, 2 ~ X2 + X3),
      X1 %-->% X2
    )
  kn_tbl <- knowledge(
    tbl,
    tier(1 ~ X1, 2 ~ X2 + X3),
    X1 %-->% X2
  )
  kn_mat <- knowledge(
    mat,
    tier(1 ~ X1, 2 ~ X2 + X3),
    X1 %-->% X2
  )
  expect_equal(kn, kn_tbl)
  expect_equal(kn, kn_mat)
  expect_equal(kn$frozen, TRUE)
  expect_equal(
    kn$vars,
    tibble::tibble(
      var = c("X1", "X2", "X3", "X4"),
      tier = c("1", "2", "2", NA_character_)
    )
  )
})

# ──────────────────────────────────────────────────────────────────────────────
# Tiers
# ──────────────────────────────────────────────────────────────────────────────

test_that("tier generation with named tiers using character names", {
  kn <- knowledge(
    tier(
      "One" ~ V1 + V2,
      "Two" ~ V3,
      "Three" ~ V4 + V5
    ),
    V1 %!-->% V3,
    V1 %-->% V2,
    V2 %-->% V3
  )
  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = c("One", "Two", "Three")
    )
  )
})

test_that("tier generation with named tiers using symbols/expression", {
  kn <- knowledge(
    tier(
      One ~ V1 + V2,
      Two ~ V3,
      Three ~ V4 + V5
    ),
    V1 %!-->% V3,
    V1 %-->% V2,
    V2 %-->% V3
  )
  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = c("One", "Two", "Three")
    )
  )
})

test_that("tier generation with named tiers using mix of integers, chars, and symbols", {
  kn <- knowledge(
    tier(
      1 ~ V1 + V2,
      Two ~ V3,
      3 ~ V4 + V5,
      "Four" ~ V6,
      Five ~ V7 + V8 + V9
    ),
    V1 %!-->% V3,
    V1 %-->% V2,
    V2 %-->% V3
  )
  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = c("1", "Two", "3", "Four", "Five")
    )
  )
})

test_that("tier generation with negative numeric tiers errors", {
  expect_error(
    knowledge(
      tier(
        -1 ~ V1 + V2,
      )
    ),
    "`tier` must be a single non-empty label or a non-negative numeric literal.",
    fixed = TRUE
  )
})

######### Tier sorting works correctly ###########

test_that("tier sorts if all numeric", {
  kn <- knowledge(
    tier(
      3 ~ V1 + V2,
      1 ~ V3,
      2 ~ V4 + V5
    )
  )
  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = c("1", "2", "3")
    )
  )
  expect_equal(kn$vars$tier, c("1", "2", "2", "3", "3"))

  kn <- knowledge(
    tier(
      10 ~ V1 + V2,
      1 ~ V3,
      2 ~ V4 + V5
    )
  )
  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = c("1", "2", "10")
    )
  )
  expect_equal(kn$vars$tier, c("1", "2", "2", "10", "10"))
})

# ──────────────────────────────────────────────────────────────────────────────
# Tiers using verbs only
# ──────────────────────────────────────────────────────────────────────────────

test_that("tier generation using verbs only", {
  kn <- knowledge() |>
    add_tier(1) |>
    add_tier(2, after = 1) |>
    add_tier(3, after = 2) |>
    add_to_tier(2 ~ V3)

  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = c("1", "2", "3")
    )
  )
})

test_that("tier generation using verbs only", {
  kn <- knowledge() |>
    add_tier(One) |>
    add_tier(Two, after = One) |>
    add_tier(Three, after = Two) |>
    add_to_tier(Two ~ V3)

  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = c("One", "Two", "Three")
    )
  )
})

test_that("tier generation using verbs only", {
  kn <- knowledge() |>
    add_tier(One) |>
    add_tier(Three, after = One) |>
    add_tier(Two, before = Three) |>
    add_to_tier(Two ~ V3)

  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = c("One", "Two", "Three")
    )
  )
})

test_that("tier generation using verbs only", {
  kn <- knowledge() |>
    add_tier(One) |>
    add_tier(2, after = One) |>
    add_tier(Three, after = 2) |>
    add_to_tier(Three ~ V3)

  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = c("One", "2", "Three")
    )
  )
})

test_that("tier generation with verbs works", {
  kn <- knowledge() |>
    add_tier(1) |>
    add_tier(3, after = 1) |>
    add_tier(Two, before = 3) |>
    add_tier(Two_and_a_Half, after = Two) |>
    add_tier(2.75, before = 3)
  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = c("1", "Two", "Two_and_a_Half", "2.75", "3")
    )
  )
})

# ──────────────────────────────────────────────────────────────────────────────
# Tiers using verbs and mini-DSL
# ──────────────────────────────────────────────────────────────────────────────

test_that("tier generation with mixing DSL and verbs", {
  kn <- knowledge(
    tier(
      1 ~ V1,
      2 ~ V2
    )
  ) |>
    add_tier(3, after = 2) |>
    add_to_tier(3 ~ V3)

  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = c("1", "2", "3")
    )
  )
})

test_that("tier generation with mixing DSL and verbs with symbols", {
  kn <- knowledge(
    tier(
      1 ~ V1,
      2 ~ V2
    )
  ) |>
    add_tier(Three, after = 2) |>
    add_to_tier(Three ~ V3)

  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = c("1", "2", "Three")
    )
  )
})

test_that("tier generation with mixing DSL and verbs with symbols and chars", {
  kn <- knowledge(
    tier(
      "One" ~ V1,
      Three ~ V2
    )
  ) |>
    add_tier(Two, before = "Three") |>
    add_to_tier("Two" ~ V3)

  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = c("One", "Two", "Three")
    )
  )
})

test_that("tier generation with mixing DSL and verbs with symbols and chars", {
  kn <- knowledge(
    tier(
      "One" ~ V1,
      Three ~ V2
    )
  ) |>
    add_tier(2, after = One) |>
    add_to_tier(2 ~ V3)

  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = c("One", "2", "Three")
    )
  )
})

test_that("tier generation with mixing DSL and verbs with symbols and chars", {
  kn <- knowledge(
    tier(
      "One" ~ V1,
      Three ~ V2
    )
  ) |>
    add_tier(2, after = One) |>
    add_to_tier(2 ~ V3)

  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = c("One", "2", "Three")
    )
  )
})

test_that("tier generation with mixing DSL and verbs with symbols and chars", {
  kn <- knowledge(
    tier(
      "One" ~ V1,
      Three ~ V2
    )
  ) |>
    add_tier(Two, before = Three) |>
    add_to_tier(Two ~ V3)

  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = c("One", "Two", "Three")
    )
  )
})

test_that("tier tidyselect helpers works with +", {
  kn1 <- knowledge(
    tpc_example,
    tier(
      young ~ starts_with(c("child", "youth")),
      old ~ starts_with("old")
    )
  )
  kn2 <- knowledge(
    tpc_example,
    tier(
      young ~ starts_with("child") + starts_with("youth"),
      old ~ starts_with("old")
    )
  )
  expect_equal(kn1, kn2)

  kn3 <- knowledge(
    tpc_example,
    tier(
      young ~ starts_with("child") + ends_with(c("3", "4")),
      old ~ starts_with("old")
    )
  )

  expect_equal(kn1, kn3)
})

# ──────────────────────────────────────────────────────────────────────────────
# Tiers using seq_tiers
# ──────────────────────────────────────────────────────────────────────────────

test_that("tier generation using seq_tiers", {
  my_df <- as.data.frame(
    matrix(
      runif(10), # 10 random numbers in (0,1)
      nrow = 1,
      ncol = 10,
      byrow = TRUE
    )
  )

  names(my_df) <- paste0("X_", 1:10) # label the columns X_1 … X_10

  kn <- knowledge(
    my_df,
    tier(
      seq_tiers(
        1:10,
        ends_with("_{i}")
      )
    ),
    X_1 %-->% X_2
  )
  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = 1:10 |> as.character()
    )
  )
  expect_equal(
    kn$vars,
    tibble::tibble(
      var = paste0("X_", 1:10),
      tier = 1:10 |> as.character()
    )
  )
})

test_that("tier generation using seq_tiers with labels", {
  my_df <- data.frame(
    X_1 = 1,
    X_2 = 2,
    tier3_A = 3,
    Y5_ok = 4,
    check.names = FALSE
  )

  kn <- knowledge(
    my_df,
    tier(
      seq_tiers(1:2, ends_with("_{i}")), # X_1, X_2
      seq_tiers(3, starts_with("tier{i}")), # tier3_…
      seq_tiers(5, matches("Y{i}_")) # exact match
    )
  )
  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = c("1", "2", "3", "5")
    )
  )
  expect_equal(
    kn$vars,
    tibble::tibble(
      var = c("X_1", "X_2", "tier3_A", "Y5_ok"),
      tier = c(1, 2, 3, 5) |> as.character()
    )
  )
})

# ──────────────────────────────────────────────────────────────────────────────
# Tiers using 1:n
# ──────────────────────────────────────────────────────────────────────────────

test_that("tier generation using 1:n", {
  my_df <- as.data.frame(
    matrix(
      runif(10), # 10 random numbers in (0,1)
      nrow = 1,
      ncol = 10,
      byrow = TRUE
    )
  )

  names(my_df) <- paste0("X_", 1:10) # label the columns X_1 … X_10

  kn <-
    knowledge(
      my_df,
      tier(
        1:10
      )
    )
  expect_equal(
    kn$tiers,
    tibble::tibble(
      label = 1:10 |> as.character()
    )
  )
  expect_equal(
    kn$vars,
    tibble::tibble(
      var = paste0("X_", 1:10),
      tier = 1:10 |> as.character()
    )
  )
})


# ──────────────────────────────────────────────────────────────────────────────
# Infix operators errors if my_df and variables don't match
# ──────────────────────────────────────────────────────────────────────────────
test_that("%-->% and %!-->% errors if my_df and variables don't match", {
  my_df <- data.frame(V1 = 1, V2 = 2, check.names = FALSE)
  expect_error(
    knowledge(my_df, 1 %-->% V2),
    "Required edge: no variables matched '1' from the left-hand side.",
    fixed = TRUE
  )
  expect_error(
    knowledge(my_df, V2 %-->% 1),
    "Required edge: no variables matched '1' from the right-hand side.",
    fixed = TRUE
  )

  expect_error(
    knowledge(my_df, 1 %!-->% V2),
    "Forbidden edge: no variables matched '1' from the left-hand side.",
    fixed = TRUE
  )
  expect_error(
    knowledge(my_df, V2 %!-->% 1),
    "Forbidden edge: no variables matched '1' from the right-hand side.",
    fixed = TRUE
  )
})

test_that("forbidden and required errors when no from vars matched", {
  my_df <- data.frame(V1 = 1, V2 = 2, check.names = FALSE)
  expect_error(
    knowledge(
      my_df,
      1 %!-->% V1
    ),
    "Forbidden edge: no variables matched '1' from the left-hand side.",
    fixed = TRUE
  )
  expect_error(
    knowledge(
      my_df,
      1 %-->% V1
    ),
    "Required edge: no variables matched '1' from the left-hand side.",
    fixed = TRUE
  )
})

test_that("forbidden and required errors when no to vars matched", {
  my_df <- data.frame(V1 = 1, V2 = 2, check.names = FALSE)
  expect_error(
    knowledge(
      my_df,
      V1 %!-->% 1
    ),
    "Forbidden edge: no variables matched '1' from the right-hand side.",
    fixed = TRUE
  )
  expect_error(
    knowledge(
      my_df,
      V1 %-->% 1
    ),
    "Required edge: no variables matched '1' from the right-hand side.",
    fixed = TRUE
  )
})

# ──────────────────────────────────────────────────────────────────────────────
# Tier errors
# ──────────────────────────────────────────────────────────────────────────────
test_that("tier() errors if no formulas are supplied", {
  my_df <- tibble::tibble(V1 = 1, V2 = 2)

  expect_error(
    knowledge(my_df, tier()),
    "tier() needs at least one two-sided formula.",
    fixed = TRUE
  )
})

test_that("add_tier() errors for an empty tier label", {
  kn <- knowledge()

  expect_error(
    add_tier(kn, ""), # invalid label
    "`tier` must be a non-empty label.",
    fixed = TRUE
  )
})

test_that("add_tier() errors when the label already exists", {
  kn <- knowledge() |> add_tier(1) # creates tier "1"

  expect_error(
    add_tier(kn, 1), # duplicate
    "Tier label `1` already exists.",
    fixed = TRUE
  )
})

test_that("add_tier() errors if the anchor tier is missing", {
  kn <- knowledge() |> add_tier("first") # only one tier so far

  expect_error(
    add_tier(kn, "second", after = "ghost"), # bad anchor
    "`ghost` does not refer to an existing tier.",
    fixed = TRUE
  )
})

test_that("add_to_tier() errors when adding existing variable to another tier", {
  expect_error(
    knowledge(
      tier(
        One ~ V1 + V2,
        2 ~ V3 + V4,
        "Three" ~ V5
      )
    ) |>
      add_to_tier(One ~ V3 + V4),
    "Cannot reassign variable(s) [V3, V4] to tier `One` using add_to_tier().",
    fixed = TRUE
  )
  expect_error(
    knowledge(
      tier(
        One ~ V1 + V2,
        2 ~ V3 + V4,
        "Three" ~ V5
      )
    ) |>
      add_to_tier(2 ~ V3 + V1),
    "Cannot reassign variable(s) [V1] to tier `2` using add_to_tier().",
    fixed = TRUE
  )
})

test_that("add_to_tier() errors if no formulas are supplied", {
  kn <- knowledge()

  expect_error(
    add_to_tier(kn), # no ...
    "add_to_tier() needs at least one two-sided formula.",
    fixed = TRUE
  )
})

test_that("add_to_tier() errors when a non-formula argument is given", {
  kn <- knowledge()

  expect_error(
    add_to_tier(kn, "oops"), # not a formula
    "Each argument must be a two-sided formula.",
    fixed = TRUE
  )
})

test_that("add_to_tier() errors when the target tier does not exist", {
  kn <- knowledge() # no tiers yet

  expect_error(
    add_to_tier(kn, ghost ~ V1), # lhs tier unknown
    "Tier `ghost` does not exist. Create it first with add_tier().",
    fixed = TRUE
  )
})

test_that("add_to_tier() errors when RHS matches no variables", {
  kn <- knowledge() |> add_tier("T1") # create tier

  # tidyselect call that matches nothing because kn$vars is still empty
  expect_error(
    add_to_tier(kn, T1 ~ starts_with("foo")),
    "matched no variables",
    fixed = FALSE
  )
})

test_that("tier throws error for one variable in two tiers", {
  expect_error(
    knowledge(
      tier(
        1 ~ V1 + V2,
        Two ~ V1,
      )
    ),
    "Tier specification Two ~ V1 tries to re-assign variable(s) [V1] to a new tier.",
    fixed = TRUE
  )
})

test_that("tier throws error for using numeric vector without my_df", {
  expect_error(
    knowledge(
      tier(
        1:10
      )
    ),
    "Using tier(<numeric vector>) needs the data-frame columns first.",
    fixed = TRUE
  )
})

test_that("tier() errors when numeric vector length != ncol(my_df)", {
  my_df <- data.frame(X1 = 1, X2 = 2, X3 = 3, X4 = 4, check.names = FALSE)
  expect_error(
    knowledge(
      my_df,
      tier(
        1:10
      )
    ),
    "Tier vector length (10) must equal number of variables (4).",
    fixed = TRUE
  )
})

test_that("numeric-vector tier() errors on duplicate indices", {
  my_df <- data.frame(A = 1, B = 2, C = 3, check.names = FALSE)

  expect_error(
    knowledge(
      my_df,
      tier(1:3), # first time: creates tiers 1,2,3
      tier(1:3) # second time: should detect 1,2,3 already exist
    ),
    "Tier index(es) 1, 2, 3 already exist.",
    fixed = TRUE
  )
})

test_that("tier() throws error when mispecifying tier", {
  my_df <- data.frame(A = 1, B = 2, C = 3, check.names = FALSE)

  expect_error(
    knowledge(
      my_df,
      tier(2 ~ 1)
    ),
    "Tier specification 2 ~ 1 matched no variables.",
    fixed = TRUE
  )
  expect_error(
    knowledge(
      my_df,
      tier(2 ~ X)
    ),
    "Unknown variable(s): [X]
They are not present in the data frame provided to this Knowledge object.",
    fixed = TRUE
  )

  expect_error(
    knowledge(
      data.frame(V1 = 1, V2 = 2, check.names = FALSE),
      tier(
        1 ~ V1,
        "V2"
      )
    ),
    "Each tier() argument must be a two-sided formula.",
    fixed = TRUE
  )
  # this throws some evaluation error
  expect_error(
    knowledge(
      tier(
        1 ~ V1,
        V4
      )
    )
  )
  my_df <- data.frame(A = 1, B = 2, check.names = FALSE)

  expect_error(
    knowledge(
      my_df,
      tier(
        1 ~ starts_with("Z")
      )
    ),
    "Tier specification 1 ~ starts_with(\"Z\") matched no variables.",
    fixed = TRUE
  )
})

test_that("numeric-vector tier() errors on duplicate indices", {
  my_df <- data.frame(A = 1, B = 2, C = 3, check.names = FALSE)

  expect_error(
    knowledge(
      my_df,
      tier(1:3), # first time: creates tiers 1,2,3
      tier(1:3) # second time: should detect 1,2,3 already exist
    ),
    "Tier index(es) 1, 2, 3 already exist.",
    fixed = TRUE
  )
})

test_that("seq_tiers() in tier() errors when no variables match the pattern", {
  my_df <- data.frame(A = 1, B = 2, C = 3, check.names = FALSE)

  expect_error(
    knowledge(
      my_df,
      tier(
        # build a bundle that will match no columns
        seq_tiers(1, starts_with("zzz"))
      )
    ),
    # literal match of the error message
    "Pattern starts_with(\"zzz\") matched no variables.",
    fixed = TRUE
  )
})

test_that("tier() errors when two seq_tiers patterns overlap", {
  my_df <- data.frame(
    A = 1,
    B = 2,
    C = 3,
    check.names = FALSE
  )

  expect_error(
    knowledge(
      my_df,
      tier(
        # seq_tiers(1:2, everything()) produces two formulas
        # 1 ~ everything(), 2 ~ everything()
        # so every column is matched twice -> should throw
        seq_tiers(1:2, everything())
      )
    ),
    "Some variables matched by two patterns: A, B, C",
    fixed = TRUE
  )
})

test_that("seq_tiers() placeholder validation and numeric default branch", {
  expect_error(
    seq_tiers(1:2, foo), # no placeholder
    "`vars` must contain the placeholder `i`",
    fixed = TRUE
  )

  fml <- seq_tiers(1:2, c(i, 42))

  expect_length(fml, 2)
  rhs_txt <- rlang::expr_text(rlang::f_rhs(fml[[1]]))

  expect_true(grepl("\\b1\\b", rhs_txt)) # i → "1"
  expect_true(grepl("\\b42\\b", rhs_txt)) # 42 unchanged
})


test_that("add_tier() errors when both `before` and `after` are supplied", {
  expect_error(
    knowledge() |>
      add_tier(2, before = 3, after = 1),
    "Cannot supply both `before` and `after`.",
    fixed = TRUE
  )
})

test_that("add_tier() errors when both `before` and `after` are supplied for a labelled tier", {
  expect_error(
    knowledge() |>
      add_tier(1) |>
      add_tier(dumb_tier, before = 1, after = 1),
    "Cannot supply both `before` and `after`.",
    fixed = TRUE
  )
})

test_that("add_tier() errors when either `before` or `after` is given but is not in kn$tiers", {
  expect_error(
    knowledge() |>
      add_tier(One, before = Two),
    "`before`/`after` cannot be used when there are no existing tiers.",
    fixed = TRUE
  )
})

test_that("add_to_tier() errors when tier input is bad", {
  expect_error(
    knowledge() |>
      add_tier(NA),
    "`tier` must be a single non-empty label or a non-negative numeric literal.",
    fixed = TRUE
  )
  expect_error(
    knowledge() |>
      add_tier(NULL),
    "`tier` must be a single non-empty label or a non-negative numeric literal.",
    fixed = TRUE
  )
})

test_that("add_tier() errors when no before or after is provided", {
  expect_error(
    knowledge() |>
      add_tier(1) |>
      add_tier(Two),
    "Once the Knowledge object already has tiers, supply exactly one of `before` or `after`.",
    fixed = TRUE
  )
  expect_error(
    knowledge() |>
      add_tier(1) |>
      add_tier(Two, after = 1) |>
      add_tier("Three"),
    "Once the Knowledge object already has tiers, supply exactly one of `before` or `after`.",
    fixed = TRUE
  )
})

test_that("tier() attaches to an existing tier label", {
  my_df <- tibble::tibble(V1 = 1, V2 = 2)

  kn <- knowledge(
    my_df,
    tier(1 ~ V1), # creates tier "1" and assigns V1
    tier(1 ~ V2) # same label, should hit the 'add_to_tier' path
  )

  # only one tier row exists and it is labelled "1"
  expect_equal(kn$tiers$label, "1")

  # both variables now belong to that tier
  expect_setequal(
    kn$vars |> dplyr::filter(tier == "1") |> dplyr::pull(var),
    c("V1", "V2")
  )
})

# ──────────────────────────────────────────────────────────────────────────────
# Tier violations
# ──────────────────────────────────────────────────────────────────────────────

test_that("reordering respects tier-violation rules", {
  # only forbidden edge → any reorder is fine
  kn <- knowledge(
    tier(One ~ V1, Two ~ V2, Three ~ V3),
    V2 %!-->% V3
  )
  expect_silent(reorder_tiers(kn, c("Three", "One", "Two")))
  expect_silent(reposition_tier(kn, Three, before = One))

  # required edge → illegal uphill move must error
  kn2 <- knowledge(
    tier(One ~ V1, Two ~ V2, Three ~ V3),
    V2 %-->% V3 # V2 must stay *before* V1
  )

  expect_error(
    reposition_tier(kn2, Three, after = One),
    "Edge(s) violate tier ordering: V2 --> V3",
    fixed = TRUE
  )

  expect_error(
    reorder_tiers(kn2, c("One", "Three", "Two")),
    "Edge(s) violate tier ordering: V2 --> V3",
    fixed = TRUE
  )
})

test_that("adding tier after required edge is provided will trigger tier violation error", {
  expect_error(
    knowledge(
      V2 %-->% V1
    ) |>
      add_tier(1) |>
      add_tier(2, after = 1) |>
      add_to_tier(2 ~ V2) |>
      add_to_tier(1 ~ V1),
    "Edge(s) violate tier ordering: V2 --> V1",
    fixed = TRUE
  )
})

# ──────────────────────────────────────────────────────────────────────────────
# Misc errors
# ──────────────────────────────────────────────────────────────────────────────
test_that("unfreeze() clears the frozen flag", {
  my_df <- tibble::tibble(A = 1, B = 2)

  kn_frozen <- knowledge(my_df) # passing a data frame sets frozen = TRUE
  expect_true(kn_frozen$frozen)

  kn_unfrozen <- unfreeze(kn_frozen)
  expect_false(kn_unfrozen$frozen)
})

test_that("unfreeze() allows adding new variables", {
  my_df <- tibble::tibble(A = 1, B = 2)
  kn <- knowledge(my_df) |> unfreeze() # thaw the object

  # add a new variable that wasn't in the original data frame
  kn2 <- add_vars(kn, "C")

  expect_setequal(kn2$vars$var, c("A", "B", "C"))
  expect_false(kn2$frozen) # flag stays FALSE
})
test_that("knowledge() throws error when using another a not defined function", {
  my_df <- data.frame(V1 = 1, V2 = 2, check.names = FALSE)
  expect_error(
    knowledge(
      my_df,
      musthave(V1 ~ 1)
    ),
    "Only tier(), exogenous(), and infix edge operators (%-->%, %!-->%) are allowed.",
    fixed = TRUE
  )
  expect_error(
    knowledge(
      makingmistakes(V1 ~ 1)
    ),
    "Only tier(), exogenous(), and infix edge operators (%-->%, %!-->%) are allowed.",
    fixed = TRUE
  )
})

test_that("print.Knowledge() snapshot", {
  local_edition(3) # enable v3 snapshotting

  withr::with_options(
    list(
      crayon.enabled = FALSE, # strip colour codes
      cli.num_colors = 1
    ),
    {
      kn <- knowledge(
        tibble::tibble(V1 = 1, V2 = 2),
        tier(1 ~ V1),
        tier(2 ~ V2),
        V1 %!-->% V2
      )

      expect_snapshot_output(print(kn), cran = FALSE)
    }
  )
})

test_that(".edge_verb() validates formula structure and matches", {
  kn <- knowledge() # empty, so no vars are known yet

  # not required or forbidden
  expect_error(
    .edge_verb(kn, "unknown", rlang::quo(V1 ~ V2)),
    "`status` (edge type) must be 'required' or 'forbidden' for ",
    fixed = TRUE
  )
  # not a two-sided formula
  expect_error(
    .edge_verb(kn, "forbidden", rlang::quo(V1)),
    "Edge specification must be a two-sided formula",
    fixed = TRUE
  )

  # both sides match zero vars: specific error branch
  expect_error(
    .edge_verb(
      kn,
      "forbidden",
      rlang::quo(starts_with("Z") ~ starts_with("W"))
    ),
    "Formula `starts_with(\"Z\") ~ starts_with(\"W\")` matched no variables.",
    fixed = TRUE
  )
})


test_that(".vars_from_spec() handles c(...) and symbol fallback paths", {
  kn <- knowledge(tibble::tibble(V1 = 1, V2 = 2))

  # unsupported argument inside c()
  expect_error(
    .vars_from_spec(kn, quote(c(V1, 42))),
    "Unsupported argument in c\\(\\):",
    perl = TRUE
  )

  # symbol resolves to a user-supplied character vector
  local_vec <- c("V1", "V2")
  expect_equal(
    .vars_from_spec(kn, quote(local_vec)),
    local_vec
  )
})

# ──────────────────────────────────────────────────────────────────────────────
# + operator
# ──────────────────────────────────────────────────────────────────────────────

test_that("merge of numeric-looking tiers preserves left order", {
  kn1 <- knowledge(tier(`1` ~ V1, `3` ~ V3))
  kn2 <- knowledge(tier(`1` ~ V4, `2` ~ V2, `3` ~ V5))

  kn12 <- kn1 + kn2

  expect_equal(
    kn12$tiers,
    tiers_tbl("1", "3", "2") # order: left first, new labels appended
  )

  ## duplicated variable: e1 wins because it’s listed first
  kn1a <- knowledge(tier(`1` ~ V1))
  kn2a <- knowledge(tier(`1` ~ V1_new))
  expect_equal(
    (kn1a + kn2a)$vars$var[1],
    "V1" # takes first definition from kn1a
  )
})

test_that("merge of arbitrary labels concatenates e1 order then new from e2", {
  kn1 <- knowledge(tier(A ~ V1, AA ~ V3))
  kn2 <- knowledge(tier(A ~ V4, B ~ V2))

  kn12 <- kn1 + kn2

  expect_equal(
    kn12$tiers,
    tiers_tbl("A", "AA", "B") # "B" appended after all of kn1’s labels
  )
})

test_that("merge errors if resulting tiers violate required-edge order", {
  kn_left <- knowledge(tier(One ~ V1))
  kn_right <- knowledge(
    tier(Two ~ V2),
    V2 %-->% V1
  )

  expect_error(
    kn_left + kn_right,
    "Edge(s) violate tier ordering",
    fixed = TRUE
  )
})

test_that("merge errors if tiers overlap", {
  kn1 <- knowledge(tier(One ~ V1, Two ~ V2))
  kn2 <- knowledge(tier(Three ~ V2, Three ~ V3))
  expect_error(
    kn1 + kn2,
    "Tier conflict detected for 1 variable",
    fixed = TRUE
  )
})

test_that("merge errors if required and forbidden edges overlap", {
  kn1 <- knowledge(
    V1 %!-->% V2,
    V2 %!-->% V3
  )
  kn2 <- knowledge(
    V1 %-->% V2,
    V2 %-->% V3
  )

  expect_error(
    kn1 + kn2,
    "Edge(s) appear as both forbidden and required: V1 --> V2, V2 --> V3",
    fixed = TRUE
  )
})

# ──────────────────────────────────────────────────────────────────────────────
# deparse_knowledge()
# ──────────────────────────────────────────────────────────────────────────────

test_that("deparse_knowledge() emits minimal code for empty knowledge", {
  kn <- knowledge()
  code <- deparse_knowledge(kn)
  expected <- "knowledge(\n)"
  expect_equal(code, expected)
})

test_that("deparse_knowledge() includes data-frame name when provided", {
  my_df <- data.frame(A = 1, B = 2)
  kn <- knowledge(my_df, tier(1 ~ A, 2 ~ B))
  code <- deparse_knowledge(kn, "my_df")
  expected <- paste0(
    "knowledge(my_df,",
    "\n  tier(",
    "\n    1 ~ A,",
    "\n    2 ~ B",
    "\n  )",
    "\n)"
  )
  expect_equal(code, expected)
})

test_that("deparse_knowledge() groups multiple tiers into one tier() call", {
  my_df <- data.frame(X = 1, Y = 2, Z = 3)
  kn <- knowledge(
    my_df,
    tier(first ~ X + Y, second ~ Z)
  )
  code <- deparse_knowledge(kn, "my_df")
  expect_true(grepl("tier\\(\\s*first ~ X \\+ Y,\\s*second ~ Z\\s*\\)", code))
})

test_that("deparse_knowledge() collapses forbidden edges by source", {
  my_df <- data.frame(A = 1, B = 2, C = 3, D = 4)
  kn <- knowledge(
    my_df,
    A %!-->% C,
    A %!-->% D,
    B %!-->% C
  )
  code <- deparse_knowledge(kn, "my_df")
  # Should convert to
  #   A %!-->% c(C, D),
  #   B %!-->% C
  expected_pattern <- "knowledge(my_df,\n  A %!-->% c(C, D),\n  B %!-->% C\n)"

  expect_equal(code, expected_pattern)
})

test_that("deparse_knowledge() collapses required edges by source", {
  my_df <- data.frame(P = 1, Q = 2, R = 3)
  kn <- knowledge(
    my_df,
    P %-->% Q,
    P %-->% R
  )
  code <- deparse_knowledge(kn, "my_df")

  expected_pattern <- "knowledge(my_df,\n  P %-->% c(Q, R)\n)"
  expect_equal(code, expected_pattern)
})

test_that("deparse_knowledge() round-trips: eval(parse(code)) equals original", {
  my_df <- data.frame(A = 1, B = 2, C = 3)
  kn <- knowledge(
    my_df,
    tier(1 ~ A + B, 2 ~ C),
    A %!-->% C,
    B %-->% A
  )
  code <- deparse_knowledge(kn, "my_df")

  kn2 <- eval(parse(text = code))
  expect_equal(kn2, kn)
})

test_that("print and summary method for knowledge", {
  my_df <- data.frame(A = 1, B = 2, C = 3, D = 4, E = 5, F = 6)
  kn <- knowledge(
    my_df,
    tier(1 ~ A + B, 2 ~ C),
    A %!-->% C,
    B %-->% A
  )
  print(kn)
  print(kn, wide = TRUE)
  print(kn, compact = TRUE)
  print(kn, wide = TRUE, compact = TRUE)
  lifecycle::expect_deprecated(summary(kn))
  expect_true(TRUE)
})

test_that("print and summary method for empty knowledge works", {
  kn <- knowledge()
  print(kn)
  print(kn, wide = TRUE)
  print(kn, compact = TRUE)
  print(kn, wide = TRUE, compact = TRUE)
  lifecycle::expect_deprecated(summary(kn))
  expect_true(TRUE)
})

test_that("print and summary method for no tier knowledge works", {
  kn <- knowledge(A %-->% B)
  print(kn)
  print(kn, wide = TRUE)
  print(kn, compact = TRUE)
  print(kn, wide = TRUE, compact = TRUE)
  lifecycle::expect_deprecated(summary(kn))
  expect_true(TRUE)
})

# ──────────────────────────────────────────────────────────────────────────────
# + syntax for infix edge operators
# ──────────────────────────────────────────────────────────────────────────────

test_that("+ on RHS of %-->% is equivalent to c()", {
  kn_plus <- knowledge(V1 %-->% V2 + V3)
  kn_c <- knowledge(V1 %-->% c(V2, V3))
  expect_equal(kn_plus$edges, kn_c$edges)
})

test_that("+ on RHS of %!-->% is equivalent to c()", {
  kn_plus <- knowledge(V1 %!-->% V2 + V3)
  kn_c <- knowledge(V1 %!-->% c(V2, V3))
  expect_equal(kn_plus$edges, kn_c$edges)
})

test_that("+ on LHS of %-->% is equivalent to c()", {
  kn_plus <- knowledge(V1 + V2 %-->% V3)
  kn_c <- knowledge(c(V1, V2) %-->% V3)
  expect_equal(kn_plus$edges, kn_c$edges)
})

test_that("+ on LHS of %!-->% is equivalent to c()", {
  kn_plus <- knowledge(V1 + V2 %!-->% V3)
  kn_c <- knowledge(c(V1, V2) %!-->% V3)
  expect_equal(kn_plus$edges, kn_c$edges)
})

test_that("+ on both sides of %-->% is equivalent to c()", {
  kn_plus <- knowledge(V1 + V2 %-->% V3 + V4)
  kn_c <- knowledge(c(V1, V2) %-->% c(V3, V4))
  expect_equal(kn_plus$edges, kn_c$edges)
})

test_that("+ on both sides of %!-->% is equivalent to c()", {
  kn_plus <- knowledge(V1 + V2 %!-->% V3 + V4)
  kn_c <- knowledge(c(V1, V2) %!-->% c(V3, V4))
  expect_equal(kn_plus$edges, kn_c$edges)
})

test_that("+ syntax with data and multiple edge lines matches c() syntax", {
  kn_plus <- knowledge(
    tpc_example,
    child_x1 + youth_x4 %-->% child_x2 + youth_x3,
    child_x2 %!-->% youth_x3 + oldage_x5
  )
  kn_c <- knowledge(
    tpc_example,
    c(child_x1, youth_x4) %-->% c(child_x2, youth_x3),
    child_x2 %!-->% c(youth_x3, oldage_x5)
  )
  expect_equal(kn_plus$edges, kn_c$edges)
})

# ──────────────────────────────────────────────────────────────────────────────
# tidyselect helpers in edge operators
# ──────────────────────────────────────────────────────────────────────────────

test_that("tidyselect helpers select on both sides of edge operators", {
  df <- data.frame(child_x1 = 1, child_x2 = 2, youth_x3 = 3, youth_x4 = 4)

  kn_sel <- knowledge(df, starts_with("child") %!-->% starts_with("youth"))
  kn_expl <- knowledge(
    df,
    child_x1 + child_x2 %!-->% youth_x3 + youth_x4
  )
  expect_equal(kn_sel$edges, kn_expl$edges)
})

test_that("tidyselect helpers mix with bare names and + in edge operators", {
  df <- data.frame(child_x1 = 1, child_x2 = 2, youth_x3 = 3, old_x5 = 5)

  kn_sel <- knowledge(df, starts_with("child") + old_x5 %-->% youth_x3)
  kn_expl <- knowledge(df, child_x1 + child_x2 + old_x5 %-->% youth_x3)
  expect_equal(kn_sel$edges, kn_expl$edges)
})

test_that("tidyselect set operations (! and &) work in edge operators", {
  df <- data.frame(child_x1 = 1, child_x2 = 2, youth_x3 = 3, youth_x4 = 4)

  # Negation: child_x1 -> everything that is not a "child" variable.
  kn_neg <- knowledge(df, child_x1 %-->% !starts_with("child"))
  kn_neg_expl <- knowledge(df, child_x1 %-->% youth_x3 + youth_x4)
  expect_equal(kn_neg$edges, kn_neg_expl$edges)

  # Intersection: only youth_x3 matches both selectors.
  kn_and <- knowledge(
    df,
    child_x1 %-->% (starts_with("youth") & ends_with("x3"))
  )
  kn_and_expl <- knowledge(df, child_x1 %-->% youth_x3)
  expect_equal(kn_and$edges, kn_and_expl$edges)
})

test_that("edge operator errors when a tidyselect helper matches nothing", {
  df <- data.frame(child_x1 = 1, youth_x3 = 3)
  expect_error(
    knowledge(df, child_x1 %-->% starts_with("nope")),
    "no variables matched"
  )
})

test_that("required edges that form a directed cycle are rejected", {
  df <- data.frame(A = 1, B = 1, C = 1)
  expect_error(
    knowledge(df, A %-->% B, B %-->% A),
    "required in both directions"
  )
  # 3-cycle
  expect_error(
    knowledge(df, A %-->% B, B %-->% C, C %-->% A),
    "directed cycle"
  )
  # longer cycle
  df2 <- data.frame(A = 1, B = 1, C = 1, D = 1)
  expect_error(
    knowledge(df2, A %-->% B, B %-->% C, C %-->% D, D %-->% A),
    "directed cycle"
  )
})

test_that("acyclic required edges and forbidden cycles are accepted", {
  df <- data.frame(A = 1, B = 1, C = 1)
  # an acyclic chain of required edges is fine
  expect_no_error(knowledge(df, A %-->% B, B %-->% C))
  # forbidden edges impose no orientation, so a "cycle" of forbidden edges is fine
  expect_no_error(knowledge(df, A %!-->% B, B %!-->% C, C %!-->% A))
})
