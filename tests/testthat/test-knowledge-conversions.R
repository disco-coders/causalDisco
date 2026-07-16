# ──────────────────────────────────────────────────────────────────────────────
# as_tetrad_knowledge()
# ──────────────────────────────────────────────────────────────────────────────

test_that("as_tetrad_knowledge() passes tiers and edges to the Java proxy", {
  skip_if_no_tetrad()

  kn <- knowledge(
    tibble::tibble(X = 1, Y = 2, Z = 3),
    tier(1 ~ X),
    tier(2 ~ Y + Z),
    Y %!-->% X,
    X %-->% Z
  )

  fake <- rlang::env(
    tiers = list(),
    forbidden = list(),
    required = list()
  )

  new_stub <- function(class) {
    list(
      addToTier = function(i, v) {
        fake$tiers <- append(fake$tiers, list(c(i, v)))
      },
      setForbidden = function(f, t) {
        fake$forbidden <- append(fake$forbidden, list(c(f, t)))
      },
      setRequired = function(f, t) {
        fake$required <- append(fake$required, list(c(f, t)))
      }
    )
  }

  mockery::stub(
    as_tetrad_knowledge,
    "requireNamespace",
    function(pkg, quietly = FALSE) pkg == "rJava"
  )
  mockery::stub(as_tetrad_knowledge, "rJava::.jinit", function(...) NULL)
  mockery::stub(as_tetrad_knowledge, "rJava::.jnew", new_stub)

  j <- as_tetrad_knowledge(kn)
  expect_type(j, "list")

  expect_equal(
    fake$tiers |> purrr::map_chr(~ paste(.x, collapse = ":")),
    c("1:X", "2:Y", "2:Z")
  )
  expect_equal(
    fake$forbidden |> purrr::map_chr(~ paste(.x, collapse = ">")),
    "Y>X"
  )
  expect_equal(
    fake$required |> purrr::map_chr(~ paste(.x, collapse = ">")),
    "X>Z"
  )
})


# ──────────────────────────────────────────────────────────────────────────────
# as_bnlearn_knowledge()
# ──────────────────────────────────────────────────────────────────────────────

test_that("as_bnlearn_knowledge() returns correct whitelist and blacklist", {
  kn <- knowledge(
    tibble::tibble(A = 1, B = 2),
    tier(1 ~ A),
    tier(2 ~ B),
    A %-->% B
  )

  # tier rule makes B -> A a forbidden edge
  out <- as_bnlearn_knowledge(kn)

  expect_type(out, "list")
  expect_named(out, c("whitelist", "blacklist"))

  expect_equal(
    out$whitelist,
    data.frame(from = "A", to = "B", stringsAsFactors = FALSE)
  )

  expect_true(
    any(out$blacklist$from == "B" & out$blacklist$to == "A")
  )
})

# ──────────────────────────────────────────────────────────────────────────────
# as_pcalg_constraints()
# ──────────────────────────────────────────────────────────────────────────────

test_that("errors if any tiers are present", {
  kn <- knowledge(tier(1 ~ X1 + X2))
  expect_error(
    as_pcalg_constraints(kn, labels = c("X1", "X2")),
    "Tiered background knowledge cannot be utilised"
  )
})

test_that("errors on asymmetric edges", {
  kn <- knowledge(
    data.frame(X1 = 1, X2 = 2),
    X1 %!-->% X2 # only one direction
  )
  expect_error(
    as_pcalg_constraints(kn, labels = c("X1", "X2")),
    "no symmetrical counterpart"
  )
})

test_that("directed_as_undirected is deprecated and ignored", {
  kn <- knowledge(
    data.frame(X1 = 1, X2 = 2, Y = 3),
    X1 %!-->% X2,
    Y %-->% X1
  )
  lifecycle::expect_deprecated(
    try(
      as_pcalg_constraints(
        kn,
        labels = c("X1", "X2", "Y"),
        directed_as_undirected = TRUE
      ),
      silent = TRUE
    )
  )
  # the flag no longer mirrors, so asymmetric edges still error
  expect_error(
    suppressWarnings(
      as_pcalg_constraints(
        kn,
        labels = c("X1", "X2", "Y"),
        directed_as_undirected = TRUE
      )
    ),
    "no symmetrical counterpart"
  )
})

test_that("works when forbidden edges are fully symmetric via DSL", {
  kn <- knowledge(
    data.frame(X1 = 1, X2 = 2, Y = 3),
    X1 %!-->% X2,
    X2 %!-->% X1
  )

  cons <- as_pcalg_constraints(
    kn,
    labels = c("X1", "X2", "Y")
  )

  # fixed_gaps should have exactly the two symmetric entries
  expect_true(cons$fixed_gaps["X1", "X2"])
  expect_true(cons$fixed_gaps["X2", "X1"])
  # no other forbidden pairs
  expect_equal(sum(cons$fixed_gaps), 2)

  # fixed_edges should be entirely FALSE
  expect_false(any(cons$fixed_edges))
})

test_that("result has correct dimnames and dimensions", {
  labels <- c("A", "B", "C", "D")
  kn <- knowledge(
    data.frame(A = 1, B = 2, C = 3, D = 4),
    A %!-->% B,
    B %!-->% A,
    C %!-->% D,
    D %!-->% C
  )
  cons <- as_pcalg_constraints(kn, labels = labels)
  expect_equal(dim(cons$fixed_gaps), c(4L, 4L))
  expect_equal(dimnames(cons$fixed_gaps), list(labels, labels))
  expect_equal(dim(cons$fixed_edges), c(4L, 4L))
  expect_equal(dimnames(cons$fixed_edges), list(labels, labels))
})
test_that("create pcalg cons without providing labels", {
  kn <- knowledge(
    data.frame(A = 1, B = 2, C = 3, D = 4),
    A %!-->% B,
    B %!-->% A,
    C %!-->% D,
    D %!-->% C
  )
  labels <- kn$vars$var
  expect_equal(
    as_pcalg_constraints(kn),
    as_pcalg_constraints(kn, labels = labels)
  )
})

test_that("labels errors are thrown for pcalg constraints conversion", {
  kn <- knowledge(
    data.frame(A = 1, B = 2, C = 3, D = 4),
    A %!-->% B,
    C %-->% D
  )
  labels <- NULL
  expect_error(
    as_pcalg_constraints(kn, labels = labels),
    "`labels` must be a non-empty character vector."
  )
  labels <- c("A", "A", "A", "A")
  expect_error(
    as_pcalg_constraints(kn, labels = labels),
    "labels` must be unique."
  )
  labels <- c("A", "B")
  expect_error(
    as_pcalg_constraints(kn, labels = labels),
    "The following is missing: \\[C, D\\]"
  )
  labels <- c("A", "B", "C", "D", "E")
  expect_error(
    as_pcalg_constraints(kn, labels = labels),
    "`labels` contained variables that were not in the Knowledge object: [E]",
    fixed = TRUE
  )
})

test_that("as_pcalg_constraints() detects edges that reference unknown vars", {
  kn_forb <- knowledge(
    tibble::tibble(A = 1, B = 2),
    A %!-->% B,
    B %!-->% A
  )
  # X not in vars or labels; edit both rows to keep the pair symmetric
  kn_forb$edges$to[1] <- "X"
  kn_forb$edges$from[2] <- "X"

  expect_error(
    as_pcalg_constraints(kn_forb, labels = c("A", "B")),
    "Forbidden edge refers to unknown variable",
    fixed = FALSE
  )

  # knowledge() cannot express a symmetric required pair, so flip statuses
  # on a forbidden pair to exercise the required-edge guard
  kn_req <- knowledge(
    tibble::tibble(A = 1, B = 2),
    A %!-->% B,
    B %!-->% A
  )
  kn_req$edges$status <- "required"
  kn_req$edges$to[1] <- "Y"
  kn_req$edges$from[2] <- "Y"

  expect_error(
    as_pcalg_constraints(kn_req, labels = c("A", "B")),
    "Required edge refers to unknown variable",
    fixed = FALSE
  )
})
