# ──────────────────────────────────────────────────────────────────────────────
# ges()
# ──────────────────────────────────────────────────────────────────────────────

test_that("ges(): constructor returns a disco_method and runs across engines", {
  skip_if_no_tetrad()
  data(num_data)

  for (engine in ges_registry$ges$engines) {
    m <- do.call(
      ges_registry$ges$fn,
      c(list(engine = engine), ges_args(engine))
    )

    expect_s3_class(m, c("ges", "disco_method", "function"))
    expect_error(
      m(1:3),
      "`data` must be a data frame or a `mids` object.",
      fixed = TRUE
    )

    res <- m(num_data)
    expect_s3_class(res, "Disco")
  }
})

test_that("ges(): set_knowledge returns a new method and injects knowledge", {
  skip_if_no_tetrad()
  data(num_data)
  kn <- toy_knowledge(num_data)

  for (engine in ges_registry$ges$engines) {
    m <- do.call(
      ges_registry$ges$fn,
      c(list(engine = engine), ges_args(engine))
    )

    res0 <- m(num_data)
    expect_s3_class(res0, "Disco")

    m2 <- set_knowledge(m, kn)
    expect_s3_class(m2, c("ges", "disco_method", "function"))

    if (engine == "pcalg") {
      # pcalg requires directed knowledge in both directions
      expect_error(m2(num_data), "asymmetric edges")
    } else {
      expect_s3_class(m2(num_data), "Disco")
    }

    expect_s3_class(m(num_data), "Disco")
  }
})

test_that("ges(): disco() injects knowledge and validates method type", {
  skip_if_no_tetrad()
  data(num_data)
  kn <- toy_knowledge(num_data)

  expect_error(
    disco(num_data, method = function(x) x),
    "The method must be a disco method object.",
    fixed = TRUE
  )

  for (engine in ges_registry$ges$engines) {
    m <- do.call(
      ges_registry$ges$fn,
      c(list(engine = engine), ges_args(engine))
    )

    if (engine == "pcalg") {
      # pcalg requires directed knowledge in both directions
      expect_error(
        disco(num_data, method = m, knowledge = kn),
        "asymmetric edges"
      )
    } else {
      res <- disco(num_data, method = m, knowledge = kn)
      expect_s3_class(res, "Disco")
    }
  }
})

test_that("ges(): disco() forwards knowledge errors from set_knowledge()", {
  skip_if_no_tetrad()
  data(num_data)

  for (engine in ges_registry$ges$engines) {
    m <- do.call(
      ges_registry$ges$fn,
      c(list(engine = engine), ges_args(engine))
    )

    expect_error(
      disco(num_data, method = m, knowledge = list(foo = "bar")),
      "Input must be a knowledge instance.",
      fixed = TRUE
    )
  }
})
