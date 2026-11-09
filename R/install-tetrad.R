#' Cache directory for a Tetrad version
#'
#' Each Tetrad version is cached in its own directory,
#' `tools::R_user_dir("causalDisco/tetrad_v<version>", which = "cache")`.
#' Setting the option `causalDisco.tetrad_cache` overrides this with a single
#' directory used for all versions (the JAR file names contain the version).
#' @param version Character. The Tetrad version.
#' @return The directory path (which need not exist).
#' @keywords internal
#' @noRd
tetrad_cache_dir <- function(
  version = getOption("causalDisco.tetrad.version")
) {
  override <- getOption("causalDisco.tetrad_cache")
  if (!is.null(override)) {
    return(override)
  }
  tools::R_user_dir(paste0("causalDisco/tetrad_v", version), which = "cache")
}

#' Directory holding the Tetrad JAR for a version
#'
#' Uses the `TETRAD_DIR` environment variable if it points to an existing
#' directory, otherwise the cache directory for `version`.
#' @param version Character. The Tetrad version.
#' @return The directory path, or `NULL` if it does not exist.
#' @keywords internal
#' @noRd
get_tetrad_dir <- function(version = getOption("causalDisco.tetrad.version")) {
  # user override
  env <- Sys.getenv("TETRAD_DIR", "")
  if (nzchar(env) && dir.exists(env)) {
    return(env)
  }

  # package cache (default)
  cache <- tetrad_cache_dir(version)
  if (!is.null(cache) && dir.exists(cache)) {
    return(cache)
  }

  NULL
}

#' @title Get Java Version
#' @description Retrieves the installed Java version.
#' @return A character string representing the Java version, or NA if Java is not found.
#' @keywords internal
#' @noRd
get_java_version <- function() {
  java <- Sys.which("java")

  # If java not found, try JAVA_HOME/bin
  if (!nzchar(java)) {
    java_home <- Sys.getenv("JAVA_HOME", "")
    java_bin <- file.path(java_home, "bin", "java.exe")
    if (file.exists(java_bin)) {
      java <- normalizePath(java_bin, winslash = "/")
    }
  }

  if (!nzchar(java) || !file.exists(java)) {
    return(NA_character_)
  }

  ver_lines <- tryCatch(
    system2(java, "-version", stdout = TRUE, stderr = TRUE),
    error = function(e) NA_character_
  )

  if (is.na(ver_lines[1])) {
    return(NA_character_)
  }

  ver_line <- ver_lines[1]
  m <- regmatches(ver_line, regexpr('"[0-9._]+"', ver_line))
  if (length(m) == 0) {
    return(NA_character_)
  }

  gsub('"', "", m)
}


#' Check Tetrad Installation
#' @param version Character. The version of Tetrad to check.
#'  Default is the value of `getOption("causalDisco.tetrad.version")`.
#' @return A list with elements:
#'  - `installed`: Logical, whether Tetrad is installed.
#'  - `version`: Character or NULL, the installed version if found.
#'  - `java_ok`: Logical, whether Java >= 21.
#'  - `java_version`: Character, the installed Java version.
#'  - `message`: Character, a message describing the status.
#' @examples
#' verify_tetrad()
#' @export
verify_tetrad <- function(
  version = getOption("causalDisco.tetrad.version")
) {
  tetrad_dir <- get_tetrad_dir(version)

  out <- function(installed, java_ok, java_version, message) {
    list(
      installed = installed,
      version = if (installed) version else NULL,
      java_ok = java_ok,
      java_version = java_version,
      message = message
    )
  }

  # ---- Java check ----
  java_version <- get_java_version()

  if (is.na(java_version)) {
    return(out(FALSE, FALSE, NULL, "Java not found. Install Java >= 21."))
  }

  java_major <- as.integer(sub("\\..*", "", java_version))
  java_ok <- !is.na(java_major) && java_major >= 21

  if (!java_ok) {
    return(out(
      FALSE,
      FALSE,
      java_version,
      paste0("Java >= 21 required (found ", java_version, ").")
    ))
  }

  # ---- Tetrad check ----
  if (is.null(tetrad_dir)) {
    return(out(
      FALSE,
      TRUE,
      java_version,
      "Tetrad not installed. Run install_tetrad()."
    ))
  }

  jar <- file.path(
    tetrad_dir,
    paste0("tetrad-gui-", version, "-launch.jar")
  )

  if (!file.exists(jar)) {
    return(out(
      FALSE,
      TRUE,
      java_version,
      "Tetrad not installed. Run install_tetrad()."
    ))
  }

  out(
    TRUE,
    TRUE,
    java_version,
    paste0("Tetrad version ", version, " is installed and ready to use.")
  )
}

#' Install Tetrad GUI
#'
#' @description
#' Downloads and installs the Tetrad GUI JAR file from
#' [Maven Central](https://repo1.maven.org/maven2/io/github/cmu-phil/tetrad-gui/).
#' It downloads the specified version of the Tetrad GUI JAR and its corresponding SHA256 checksum file, and saves them
#' in the specified directory (or cache). If the JAR already exists and `force = FALSE`, it will skip downloading.
#'
#' @param version Character; the Tetrad version to install. Default is
#'   `getOption("causalDisco.tetrad.version")`.
#' @param dir Character; the directory where the JAR should be installed. If
#'   `NULL` (default), the JAR is installed in the cache directory for
#'   `version`, i.e.
#'   `tools::R_user_dir("causalDisco/tetrad_v<version>", which = "cache")`, or
#'   in `getOption("causalDisco.tetrad_cache")` if that option is set. The
#'   directory will be created if it does not exist.
#' @param force Logical; if `TRUE`, forces re-download even if the JAR already
#'   exists. Default is `FALSE`.
#' @param quiet Logical; if `FALSE`, shows progress and messages about
#'   downloading and checksum verification. Default is `FALSE`.
#' @param temp_dir Logical; if `TRUE`, installs the JAR in a temporary directory
#'   instead of the cache. Default is `FALSE`.
#'
#' @return Invisibly returns the full path to the installed Tetrad JAR.
#'
#' @details
#' In line with [CRAN policies](https://cran.r-project.org/web/packages/policies.html) this function will only
#' return messages and not throw warnings/errors if the installation fails (e.g. due to no internet connection),
#' and return `NULL`.
#'
#' @examples
#' \dontrun{
#' # Install default version in cache directory
#' install_tetrad()
#'
#' # Install a specific version and force re-download
#' install_tetrad(version = "7.6.10", force = TRUE)
#'
#' # Install in a temporary directory
#' install_tetrad(temp_dir = TRUE)
#'
#' # Install quietly (suppress messages)
#' install_tetrad(quiet = TRUE)
#' }
#'
#' @importFrom utils download.file
#' @importFrom digest digest
#'
#' @export
install_tetrad <- function(
  version = getOption("causalDisco.tetrad.version"),
  dir = NULL,
  force = FALSE,
  quiet = FALSE,
  temp_dir = FALSE
) {
  checkmate::assert_logical(force)
  checkmate::assert_logical(quiet)
  checkmate::assert_logical(temp_dir)

  old_options <- options()
  on.exit(options(old_options), add = TRUE)
  options(timeout = max(300, getOption("timeout")))

  if (temp_dir) {
    dir <- tempdir()
  } else if (is.null(dir)) {
    dir <- tetrad_cache_dir(version)
  }

  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  dir <- normalizePath(dir, winslash = "/", mustWork = TRUE)

  base <- "https://repo1.maven.org/maven2/io/github/cmu-phil/tetrad-gui"
  jar_name <- paste0("tetrad-gui-", version, "-launch.jar")
  checksum_name <- paste0(jar_name, ".sha256")

  jar_url <- paste0(base, "/", version, "/", jar_name)
  checksum_url <- paste0(base, "/", version, "/", checksum_name)

  jar_path <- file.path(dir, jar_name)
  checksum_path <- file.path(dir, checksum_name)

  jar_tmp <- paste0(jar_path, ".tmp")
  checksum_tmp <- paste0(checksum_path, ".tmp")

  cleanup_install <- function() {
    unlink(jar_path, force = TRUE)
    unlink(checksum_path, force = TRUE)
    unlink(jar_tmp, force = TRUE)
    unlink(checksum_tmp, force = TRUE)
  }

  maybe_clean_old_versions <- function(current_version, dir, quiet = FALSE) {
    all_jars <- list.files(
      dir,
      pattern = "tetrad-gui-.*-launch\\.jar$",
      full.names = TRUE
    )
    old <- all_jars[!grepl(current_version, all_jars, fixed = TRUE)]
    if (!length(old)) {
      return()
    }

    if (interactive()) {
      ans <- readline(
        paste0(
          "Found ",
          length(old),
          " old Tetrad version(s). Remove them? [y/N] "
        )
      )
      if (tolower(ans) == "y") {
        unlink(old, recursive = TRUE, force = TRUE)
        if (!quiet) message("Old versions removed.")
      }
    } else if (!quiet) {
      message(
        "Found ",
        length(old),
        " old Tetrad version(s) in cache. Run `unlink()` manually to remove."
      )
    }
  }

  need_download <- force ||
    !file.exists(jar_path) ||
    !file.exists(checksum_path)

  if (need_download) {
    cleanup_install()
    if (!quiet) {
      message("Downloading Tetrad ", version, " ...")
    }

    download_ok <- {
      success <- FALSE

      suppressWarnings({
        tryCatch(
          {
            download.file(jar_url, jar_tmp, mode = "wb", quiet = quiet)
            download.file(
              checksum_url,
              checksum_tmp,
              mode = "wb",
              quiet = quiet
            )

            if (!file.exists(jar_tmp) || !file.exists(checksum_tmp)) {
              if (!quiet) {
                message("Download incomplete. Removing corrupted files.")
              }
              cleanup_install()
            } else {
              file.rename(jar_tmp, jar_path)
              file.rename(checksum_tmp, checksum_path)
              success <- TRUE
            }
          },
          error = function(e) {
            if (!quiet) {
              message(
                "Unable to download Tetrad from ",
                jar_url,
                ". Removing corrupted files."
              )
            }
            cleanup_install()
            success <- FALSE
          }
        )
      })

      success
    }

    if (!download_ok) {
      return(NULL)
    }

    maybe_clean_old_versions(version, dir, quiet)
  } else {
    if (!quiet) message("Using cached Tetrad.")
  }

  if (!file.exists(jar_path) || !file.exists(checksum_path)) {
    if (!quiet) {
      message(
        "Incomplete Tetrad installation detected. Removing corrupted files."
      )
    }
    cleanup_install()
    return(NULL)
  }

  if (!quiet) {
    message("Verifying sha256 checksum...")
  }
  expected <- tryCatch(
    trimws(readLines(checksum_path, warn = FALSE)[1]),
    error = function(e) NA_character_
  )
  actual <- tryCatch(
    digest(file = jar_path, algo = "sha256"),
    error = function(e) NA_character_
  )

  if (
    is.na(expected) || is.na(actual) || tolower(expected) != tolower(actual)
  ) {
    if (!quiet) {
      message("Checksum verification failed. Removing corrupted installation.")
      message("Expected: ", expected)
      message("Actual:   ", actual)
    }
    cleanup_install()
    return(NULL)
  }

  if (!quiet) {
    message("Checksum confirmed. Cached at: ", jar_path)
    message(
      "Please note: Tetrad is distributed under its own license. ",
      "See license and copyright details at https://github.com/cmu-phil/tetrad"
    )
  }

  invisible(jar_path)
}
