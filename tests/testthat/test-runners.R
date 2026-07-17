# ──────────────────────────────────────────────────────────────────────────────
# make_runner() dispatch
# ──────────────────────────────────────────────────────────────────────────────

test_that("make_runner errors with an informative message for an unknown engine", {
  reset_engine_registry()

  expect_error(
    make_runner(engine = "not-an-engine", alg = "pc"),
    paste0(
      "Unknown engine: 'not-an-engine'. Supported engines are: ",
      "causalDisco, pcalg, bnlearn, tetrad. ",
      "Use register_engine\\(\\) to add support for a new engine\\."
    )
  )
})

test_that("make_runner lists registered engines in the unknown-engine error", {
  reset_engine_registry()
  register_engine("my_engine", function(alg, ...) NULL)
  on.exit(reset_engine_registry())

  expect_error(
    make_runner(engine = "still-not-an-engine", alg = "pc"),
    "Supported engines are: causalDisco, pcalg, bnlearn, tetrad, my_engine",
    fixed = TRUE
  )
})

test_that("make_runner dispatches to a registered engine's make_runner_fn", {
  reset_engine_registry()

  captured <- NULL
  register_engine(
    "my_engine",
    function(
      alg,
      test = NULL,
      alpha = NULL,
      score = NULL,
      ...,
      directed_as_undirected_knowledge = FALSE
    ) {
      captured <<- list(
        alg = alg,
        test = test,
        alpha = alpha,
        score = score,
        dots = list(...),
        directed_as_undirected_knowledge = directed_as_undirected_knowledge
      )
      list(
        set_knowledge = function(knowledge) NULL,
        run = function(data) "ran"
      )
    }
  )
  on.exit(reset_engine_registry())

  runner <- make_runner(
    engine = "my_engine",
    alg = "my_alg",
    test = "my_test",
    alpha = 0.01,
    extra_arg = "value",
    directed_as_undirected_knowledge = TRUE
  )

  expect_identical(captured$alg, "my_alg")
  expect_identical(captured$test, "my_test")
  expect_identical(captured$alpha, 0.01)
  expect_identical(captured$dots, list(extra_arg = "value"))
  expect_true(captured$directed_as_undirected_knowledge)
  expect_identical(runner$run(data.frame()), "ran")
})

test_that("make_runner checks required packages for a registered engine", {
  reset_engine_registry()
  register_engine(
    "my_engine",
    function(alg, ...) {
      list(set_knowledge = function(k) NULL, run = function(d) NULL)
    },
    pkgs = "not.a.real.package.xyz"
  )
  on.exit(reset_engine_registry())

  expect_error(
    make_runner(engine = "my_engine", alg = "my_alg"),
    "not.a.real.package.xyz"
  )
})

# ──────────────────────────────────────────────────────────────────────────────
# End-to-end: a registered engine works through make_method() + disco()
# ──────────────────────────────────────────────────────────────────────────────

test_that("a registered engine can be driven end-to-end via make_method() and disco()", {
  reset_engine_registry()
  on.exit(reset_engine_registry())

  always_empty_runner <- function(alg, ...) {
    kn <- knowledge()
    list(
      set_knowledge = function(knowledge) kn <<- knowledge,
      run = function(data) {
        cg <- caugi::caugi(
          from = character(0),
          edge = character(0),
          to = character(0),
          nodes = names(data),
          class = "PDAG"
        )
        as_disco(cg, kn)
      }
    )
  }
  register_engine("always_empty", always_empty_runner)

  empty_alg <- function(engine = "always_empty", ...) {
    engine <- match.arg(engine)
    make_method(
      method_name = "empty_alg",
      engine = engine,
      engine_fns = list(
        always_empty = function(...) {
          make_runner(engine = "always_empty", alg = "empty_alg", ...)
        }
      ),
      graph_class = "PDAG",
      ...
    )
  }

  df <- data.frame(x = rnorm(20), y = rnorm(20))
  result <- disco(df, empty_alg())

  expect_true(is_disco(result))
  expect_identical(caugi::nodes(result$caugi)$name, c("x", "y"))
  expect_identical(nrow(caugi::edges(result$caugi)), 0L)
})
