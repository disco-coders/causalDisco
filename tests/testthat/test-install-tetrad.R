test_that("get_tetrad_dir returns the cache directory", {
  cache <- withr::local_tempdir()
  withr::local_options(causalDisco.tetrad_cache = cache)

  expect_equal(get_tetrad_dir(), cache)
})

test_that("get_tetrad_dir ignores the TETRAD_DIR environment variable", {
  # Regression: older versions of install_tetrad() wrote TETRAD_DIR to
  # ~/.Renviron, and a stale value shadowed the cache, so verify_tetrad()
  # reported Tetrad as not installed.
  env_dir <- withr::local_tempdir()
  file.create(file.path(env_dir, "tetrad-gui-1.0-launch.jar"))
  cache <- withr::local_tempdir()
  withr::local_envvar(TETRAD_DIR = env_dir)
  withr::local_options(causalDisco.tetrad_cache = cache)

  expect_equal(get_tetrad_dir("1.0"), cache)
})

test_that("get_tetrad_dir returns NULL when the cache directory does not exist", {
  withr::local_options(causalDisco.tetrad_cache = NULL)

  expect_null(get_tetrad_dir("0.0.0-not-installed"))
})

test_that("get_java_version returns NA when java executable not found", {
  # Stub Sys.which to return empty
  mockery::stub(get_java_version, "Sys.which", function(cmd) "")

  # Stub file.exists to always return FALSE
  mockery::stub(get_java_version, "file.exists", function(path) FALSE)

  expect_identical(get_java_version(), NA_character_)
})


test_that("get_java_version returns NA when system2 errors", {
  # Fake java path
  mockery::stub(get_java_version, "Sys.which", function(cmd) "/usr/bin/java")

  # system2 throws an error
  mockery::stub(get_java_version, "system2", function(...) stop("boom"))

  expect_identical(get_java_version(), NA_character_)
})


test_that("get_java_version returns NA when system2 returns NA in first line", {
  mockery::stub(get_java_version, "Sys.which", function(cmd) "/usr/bin/java")

  # system2 returns NA vector
  mockery::stub(get_java_version, "system2", function(...) NA_character_)

  expect_identical(get_java_version(), NA_character_)
})


test_that("get_java_version returns NA when output has no quoted version", {
  mockery::stub(get_java_version, "Sys.which", function(cmd) "/usr/bin/java")

  mockery::stub(get_java_version, "system2", function(...) {
    c(
      "java version nonsense without quotes",
      "other info"
    )
  })

  expect_identical(get_java_version(), NA_character_)
})


test_that("get_java_version extracts version correctly when present", {
  mockery::stub(get_java_version, "Sys.which", function(cmd) "/usr/bin/java")

  # Ensure the file.exists check passes
  mockery::stub(get_java_version, "file.exists", function(path) TRUE)

  # Stub system2 to return a fake java version
  mockery::stub(get_java_version, "system2", function(...) {
    c('java version "17.0.9"', "more lines")
  })

  expect_equal(get_java_version(), "17.0.9")
})

# ---- Branch 1: Java not found ----
test_that("Returns message when Java is missing", {
  mockery::stub(verify_tetrad, "get_java_version", function() {
    NA_character_
  })

  out <- verify_tetrad("1.0")
  expect_output_list(out)

  expect_false(out$installed)
  expect_false(out$java_ok)
  expect_null(out$java_version)
  expect_match(out$message, "Java not found. Install Java >= 21.")
})


# ---- Branch 2: Java < 21 ----
test_that("Returns message when Java version is too old", {
  mockery::stub(verify_tetrad, "get_java_version", function() "17.0.9")

  out <- verify_tetrad("1.0")
  expect_output_list(out)

  expect_false(out$installed)
  expect_false(out$java_ok)
  expect_equal(out$java_version, "17.0.9")
  expect_match(out$message, "Java >= 21 required")
})


# ---- Branch 3: Java OK but no Tetrad directory ----
test_that("Returns message when tetrad directory is missing", {
  mockery::stub(verify_tetrad, "get_java_version", function() "21.0.1")
  mockery::stub(verify_tetrad, "get_tetrad_dir", function(...) NULL)

  out <- verify_tetrad("1.0")
  expect_output_list(out)

  expect_false(out$installed)
  expect_true(out$java_ok)
  expect_equal(out$java_version, "21.0.1")
  expect_match(out$message, "Tetrad not installed.")
})


# ---- Branch 4: Java OK, tetrad dir exists, JAR missing ----
test_that("Returns message when Tetrad JAR does not exist", {
  mockery::stub(verify_tetrad, "get_java_version", function() "21.0.1")
  td <- withr::local_tempdir()
  mockery::stub(verify_tetrad, "get_tetrad_dir", function(...) td)

  out <- verify_tetrad("1.0")
  expect_output_list(out)

  expect_false(out$installed)
  expect_true(out$java_ok)
  expect_equal(out$java_version, "21.0.1")
  expect_match(out$message, "Tetrad not installed.")
})


# ---- Branch 5: Java OK, several JARs but none for the version ----
test_that("Returns message when the Tetrad JAR is ambiguous", {
  mockery::stub(verify_tetrad, "get_java_version", function() "21.0.1")
  td <- withr::local_tempdir()
  file.create(file.path(td, c("tetrad-a.jar", "tetrad-b.jar")))
  mockery::stub(verify_tetrad, "get_tetrad_dir", function(...) td)

  out <- verify_tetrad("1.0")
  expect_output_list(out)

  expect_false(out$installed)
  expect_match(out$message, "Found several Tetrad JARs")
})


# ---- Branch 6: Java OK, tetrad dir exists, JAR exists -> SUCCESS ----
test_that("Successful detection when Java and Tetrad are OK", {
  mockery::stub(verify_tetrad, "get_java_version", function() "22.1.0")
  td <- withr::local_tempdir()
  file.create(file.path(td, "tetrad-gui-2.0-launch.jar"))
  mockery::stub(verify_tetrad, "get_tetrad_dir", function(...) td)

  out <- verify_tetrad("2.0")
  expect_output_list(out)

  expect_true(out$installed)
  expect_true(out$java_ok)
  expect_equal(out$version, "2.0")
  expect_equal(out$java_version, "22.1.0")
  expect_match(
    out$message,
    "Tetrad version 2.0 is installed and ready to use."
  )
})


test_that("verify_tetrad accepts a single differently named JAR", {
  # Matches init_java(), which loads such a JAR.
  mockery::stub(verify_tetrad, "get_java_version", function() "21.0.1")
  td <- withr::local_tempdir()
  file.create(file.path(td, "tetrad-gui-7.6.5-launch.jar"))
  withr::local_options(causalDisco.tetrad_cache = td)

  expect_true(verify_tetrad("7.6.10")$installed)
})


test_that("verify_tetrad finds a JAR installed by install_tetrad despite TETRAD_DIR", {
  mockery::stub(verify_tetrad, "get_java_version", function() "21.0.1")
  env_dir <- withr::local_tempdir()
  cache <- withr::local_tempdir()
  file.create(file.path(cache, "tetrad-gui-1.0-launch.jar"))
  withr::local_envvar(TETRAD_DIR = env_dir)
  withr::local_options(causalDisco.tetrad_cache = cache)

  expect_true(verify_tetrad("1.0")$installed)
})


test_that("install_tetrad runs works", {
  td <- tempdir()
  version <- "1.0.0"

  jar_name <- paste0("tetrad-gui-", version, "-launch.jar")
  checksum_name <- paste0(jar_name, ".sha256")

  fake_download <- function(url, destfile, mode = "wb", quiet = FALSE) {
    if (grepl("\\.sha256$", destfile)) {
      writeLines("jarcontent", destfile)
    } else {
      writeBin(charToRaw("jarcontent"), destfile)
    }
    0
  }

  fake_digest <- function(file, algo = "sha256") {
    "jarcontent"
  }

  local_mocked_bindings(
    download.file = fake_download,
    digest = fake_digest
  )

  res <- install_tetrad(
    version = version,
    dir = td,
    quiet = TRUE
  )

  expect_true(file.exists(res))
  expect_match(basename(res), "tetrad-gui-1.0.0-launch.jar")
})

test_that("install_tetrad handles all branches", {
  td <- tempdir()
  version <- "1.0.0"

  jar_name <- paste0("tetrad-gui-", version, "-launch.jar")
  checksum_name <- paste0(jar_name, ".sha256")

  # Fake download always succeeds
  fake_download <- function(url, destfile, mode = "wb", quiet = FALSE) {
    if (grepl("\\.sha256$", destfile)) {
      writeLines("jarcontent", destfile)
    } else {
      writeBin(charToRaw("jarcontent"), destfile)
    }
    0
  }

  # Fake digest
  fake_digest <- function(file, algo = "sha256") {
    "jarcontent"
  }

  # Simulate interactive yes for removing old versions
  fake_interactive <- function() TRUE
  fake_readline <- function(prompt = "") "y"

  # Simulate file.exists to test force download and checksum failure
  file_state <- new.env()
  file_state$exists <- TRUE
  fake_file_exists <- function(path) {
    TRUE
  }

  local_mocked_bindings(
    download.file = fake_download,
    digest = fake_digest,
    interactive = fake_interactive,
    readline = fake_readline,
    file.exists = fake_file_exists
  )

  # Test with force = TRUE
  res <- install_tetrad(version = version, dir = td, force = TRUE, quiet = TRUE)
  expect_match(basename(res), jar_name)

  # Test with missing files triggers download
  file_state$exists <- FALSE
  res2 <- install_tetrad(
    version = version,
    dir = td,
    force = FALSE,
    quiet = TRUE
  )
  expect_true(file.exists(res2))

  # Test checksum failure
  fake_digest_fail <- function(file, algo = "sha256") "wrong"
  local_mocked_bindings(digest = fake_digest_fail)
  res3 <- install_tetrad(
    version = version,
    dir = td,
    force = TRUE,
    quiet = TRUE
  )
  expect_null(res3)

  # Test dir = NULL (installs in the cache dir, here redirected to a temp dir)
  withr::local_options(causalDisco.tetrad_cache = file.path(td, "cache"))
  res4 <- suppressWarnings(install_tetrad(
    version = version,
    quiet = TRUE
  ))
  expect_null(res4)
})

test_that("tetrad_cache_dir gives each version its own directory", {
  withr::local_options(causalDisco.tetrad_cache = NULL)

  dir_a <- tetrad_cache_dir("7.6.10")
  dir_b <- tetrad_cache_dir("8.0.0")
  expect_match(dir_a, "tetrad_v7.6.10", fixed = TRUE)
  expect_match(dir_b, "tetrad_v8.0.0", fixed = TRUE)

  # Follows the version option instead of being fixed at load time.
  withr::local_options(causalDisco.tetrad.version = "8.0.0")
  expect_identical(tetrad_cache_dir(), dir_b)
})

test_that("tetrad_cache_dir uses the causalDisco.tetrad_cache override for all versions", {
  td <- file.path(tempdir(), "override_cache")
  withr::local_options(causalDisco.tetrad_cache = td)
  expect_identical(tetrad_cache_dir("7.6.10"), td)
  expect_identical(tetrad_cache_dir("8.0.0"), td)
})

test_that("install_tetrad installs a non-default version in that version's directory", {
  withr::local_options(causalDisco.tetrad_cache = NULL)
  cache_root <- file.path(tempdir(), "versioned_cache")
  withr::defer(unlink(cache_root, recursive = TRUE))
  mockery::stub(
    install_tetrad,
    "tetrad_cache_dir",
    function(version) file.path(cache_root, paste0("tetrad_v", version))
  )
  local_mocked_bindings(
    download.file = function(url, destfile, mode = "wb", quiet = FALSE) {
      writeLines("jarcontent", destfile)
      0
    },
    digest = function(file, algo = "sha256") "jarcontent"
  )

  res <- install_tetrad(version = "9.9.9", quiet = TRUE)
  expect_identical(
    normalizePath(dirname(res)),
    normalizePath(file.path(cache_root, "tetrad_v9.9.9"))
  )
})
