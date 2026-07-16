# ──────────────────────────────────────────────────────────────────────────────
# Tests for constraint-based methods (pc, fci) across engines
# ──────────────────────────────────────────────────────────────────────────────

test_that("methods construct disco_method closures and run across engines", {
  skip_if_no_tetrad()
  data(num_data)

  for (method_name in names(method_registry_constraint)) {
    reg <- method_registry_constraint[[method_name]]
    for (engine in reg$engines) {
      args <- method_args(method_name, engine)
      m <- do.call(reg$fn, c(list(engine = engine), args))

      expect_s3_class(m, c(method_name, "disco_method", "function"))
      expect_error(
        m(1:3),
        "`data` must be a data frame or a `mids` object.",
        fixed = TRUE
      )

      res <- m(num_data)
      expect_s3_class(res, "Disco")
    }
  }
})

# ──────────────────────────────────────────────────────────────────────────────
# set_knowledge()
# ──────────────────────────────────────────────────────────────────────────────

test_that("set_knowledge returns a new method and injects knowledge (all engines)", {
  skip_if_no_tetrad()
  data(num_data)
  kn <- toy_knowledge(num_data)

  for (method_name in names(method_registry_constraint)) {
    reg <- method_registry_constraint[[method_name]]
    for (engine in reg$engines) {
      args <- method_args(method_name, engine)
      m <- do.call(reg$fn, c(list(engine = engine), args))

      res0 <- m(num_data)
      expect_s3_class(res0, "Disco")

      m2 <- set_knowledge(m, kn)
      expect_s3_class(m2, c(method_name, "disco_method", "function"))
      if (engine == "pcalg") {
        # pcalg requires directed knowledge in both directions
        expect_error(m2(num_data), "asymmetric edges")
      } else {
        expect_s3_class(m2(num_data), "Disco")
      }
      expect_s3_class(m(num_data), "Disco")
    }
  }
})

# ──────────────────────────────────────────────────────────────────────────────
# disco()
# ──────────────────────────────────────────────────────────────────────────────

test_that("disco() injects knowledge and validates method type (pc + fci)", {
  skip_if_no_tetrad()
  data(num_data)
  kn <- toy_knowledge(num_data)

  expect_error(
    disco(num_data, method = function(x) x),
    "The method must be a disco method object.",
    fixed = TRUE
  )
  for (method_name in names(method_registry_constraint)) {
    reg <- method_registry_constraint[[method_name]]
    for (engine in reg$engines) {
      args <- method_args(method_name, engine)
      m <- do.call(reg$fn, c(list(engine = engine), args))

      if (engine == "pcalg") {
        # pcalg requires directed knowledge in both directions
        expect_error(
          disco(num_data, method = m, knowledge = kn),
          "asymmetric edges"
        )
        next
      } else {
        if (engine == "tetrad" && method_name == "pc") {
          expect_warning(
            {
              res <- disco(num_data, method = m, knowledge = kn)
            },
            "Cannot mutate graph to class 'PDAG'.",
            fixed = TRUE
          )
        } else if (engine == "tetrad" && method_name == "fci") {
          expect_warning(
            {
              res <- disco(num_data, method = m, knowledge = kn)
            },
            "The Tetrad FCI-family",
            fixed = TRUE
          )
        } else {
          res <- disco(num_data, method = m, knowledge = kn)
        }
      }
      expect_s3_class(res, "Disco")
    }
  }
})

test_that("disco() forwards knowledge errors from set_knowledge() (pc + fci)", {
  skip_if_no_tetrad()
  data(num_data)

  for (method_name in names(method_registry_constraint)) {
    reg <- method_registry_constraint[[method_name]]
    for (engine in reg$engines) {
      args <- method_args(method_name, engine)
      m <- do.call(reg$fn, c(list(engine = engine), args))

      expect_error(
        disco(num_data, method = m, knowledge = list(foo = "bar")),
        "Input must be a knowledge instance.",
        fixed = TRUE
      )
    }
  }
})
