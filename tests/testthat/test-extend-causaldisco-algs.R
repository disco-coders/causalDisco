test_that("new_disco_method creates a valid disco method", {
  builder <- function(knowledge = NULL) {
    list(
      set_knowledge = function(k) NULL,
      run = function(data) NULL
    )
  }

  method <- new_disco_method(
    builder = builder,
    name = "test_alg",
    engine = "bnlearn",
    graph_class = "PDAG"
  )

  # S3 class
  expect_true(inherits(method, "disco_method"))
  expect_identical(class(method)[1], "test_alg")

  # attributes
  expect_identical(attr(method, "engine"), "bnlearn")
  expect_identical(attr(method, "graph_class"), "PDAG")

  # callable
  expect_type(method, "closure")
})

test_that("new_disco_method uses the builder to run the algorithm", {
  ran <- FALSE

  builder <- function(knowledge = NULL) {
    list(
      set_knowledge = function(k) NULL,
      run = function(data) {
        ran <<- TRUE
        data
      }
    )
  }

  method <- new_disco_method(
    builder = builder,
    name = "test_alg",
    engine = "bnlearn",
    graph_class = "PDAG"
  )

  df <- data.frame(x = 1)
  out <- method(df)

  expect_true(ran)
  expect_identical(out, df)
})


test_that("distribute_engine_args delegates to check_args_and_distribute_args", {
  fake_return <- list(a = 1, b = 2)

  search <- list()
  args <- list(x = 1)
  engine <- "bnlearn"
  alg <- "hpc"

  with_mocked_bindings(
    check_args_and_distribute_args = function(s, a, e, al) {
      expect_identical(s, search)
      expect_identical(a, args)
      expect_identical(e, engine)
      expect_identical(al, alg)
      fake_return
    },
    {
      out <- distribute_engine_args(search, args, engine, alg)
      expect_identical(out, fake_return)
    }
  )
})

test_that("distribute_engine_args propagates errors", {
  with_mocked_bindings(
    check_args_and_distribute_args = function(...) {
      stop("boom", call. = FALSE)
    },
    {
      expect_error(
        distribute_engine_args(list(), list(), "bnlearn", "hpc"),
        "boom"
      )
    }
  )
})

test_that("register_tetrad_algorithm registers a new algorithm", {
  reset_tetrad_alg_registry()

  setup_fun <- function(search, param1 = 1) {
    search$set_alg("custom_alg")
    search$set_param1(param1)
  }

  register_tetrad_algorithm("custom_alg", setup_fun)

  registered_fun <- tetrad_alg_registry[["custom_alg"]]
  expect_identical(registered_fun, setup_fun)
  reset_tetrad_alg_registry()
})

test_that("register_tetrad_algorithm errors if not a function", {
  reset_tetrad_alg_registry()

  expect_error(
    register_tetrad_algorithm("not_a_function", "I am not a function"),
    "must be a function"
  )
})

# ──────────────────────────────────────────────────────────────────────────────
# register_engine
# ──────────────────────────────────────────────────────────────────────────────

test_that("register_engine registers a new engine, visible via list_registered_engines", {
  reset_engine_registry()
  on.exit(reset_engine_registry())

  expect_identical(list_registered_engines(), character(0))

  runner_fn <- function(alg, ...) NULL
  register_engine("my_engine", runner_fn, pkgs = "stats")

  expect_identical(list_registered_engines(), "my_engine")
  expect_identical(
    engine_registry_env[["my_engine"]],
    list(make_runner_fn = runner_fn, pkgs = "stats")
  )
})

test_that("register_engine defaults pkgs to an empty character vector", {
  reset_engine_registry()
  on.exit(reset_engine_registry())

  register_engine("my_engine", function(alg, ...) NULL)

  expect_identical(engine_registry_env[["my_engine"]]$pkgs, character(0))
})

test_that("register_engine errors if make_runner_fn is not a function", {
  reset_engine_registry()
  on.exit(reset_engine_registry())

  expect_error(
    register_engine("my_engine", "not a function"),
    "must be a function"
  )
})

test_that("register_engine errors if name is a built-in engine name", {
  reset_engine_registry()
  on.exit(reset_engine_registry())

  expect_error(
    register_engine("bnlearn", function(alg, ...) NULL),
    "'bnlearn' is a built-in engine name and cannot be overridden"
  )
})

test_that("reset_engine_registry clears all registered engines", {
  reset_engine_registry()

  register_engine("my_engine", function(alg, ...) NULL)
  expect_identical(list_registered_engines(), "my_engine")

  reset_engine_registry()
  expect_identical(list_registered_engines(), character(0))
})
