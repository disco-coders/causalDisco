# ──────────────────────────────────────────────────────────────────────────────
# init_java()
# ──────────────────────────────────────────────────────────────────────────────

test_that("init_java errors when no Tetrad JARs are found", {
  java_ok <- verify_tetrad()$java_ok
  if (!java_ok) {
    skip("Java not available; skipping init_java tests")
  }

  with_mock_rjava({
    pkg <- "causalDisco"
    ns <- asNamespace(pkg)
    orig <- get("get_tetrad_dir", envir = ns)
    withr::defer(assignInNamespace("get_tetrad_dir", orig, pkg))

    assignInNamespace("get_tetrad_dir", function(...) character(), pkg)

    expect_error(
      init_java(heap = "2g"),
      "No Tetrad JAR found",
      fixed = TRUE
    )
  })
})

test_that("init_java loads only the JAR for the configured version", {
  skip_if_not_installed("rJava")
  td <- file.path(tempdir(), "init_java_two_jars")
  dir.create(td, showWarnings = FALSE)
  withr::defer(unlink(td, recursive = TRUE))
  file.create(file.path(td, "tetrad-gui-7.6.10-launch.jar"))
  file.create(file.path(td, "tetrad-gui-8.0.0-launch.jar"))

  withr::local_options(
    causalDisco.tetrad_cache = td,
    causalDisco.tetrad.version = "8.0.0"
  )
  withr::local_envvar(TETRAD_DIR = "")

  with_mock_rjava({
    init_java(heap = "2g")
    expect_identical(
      .j_state$class_path,
      file.path(td, "tetrad-gui-8.0.0-launch.jar")
    )
  })
})

test_that("init_java errors on several JARs when none matches the version", {
  skip_if_not_installed("rJava")
  td <- file.path(tempdir(), "init_java_ambiguous")
  dir.create(td, showWarnings = FALSE)
  withr::defer(unlink(td, recursive = TRUE))
  file.create(file.path(td, "tetrad-a.jar"))
  file.create(file.path(td, "tetrad-b.jar"))

  withr::local_options(
    causalDisco.tetrad_cache = td,
    causalDisco.tetrad.version = "8.0.0"
  )
  withr::local_envvar(TETRAD_DIR = "")

  with_mock_rjava({
    expect_error(init_java(heap = "2g"), "Found several Tetrad JARs")
  })
})
