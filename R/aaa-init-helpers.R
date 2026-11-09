#' @title Default heap size for Java Virtual Machine
#'
#' @description
#' This function retrieves the default heap size for the Java Virtual Machine.
#' The standard size is 2 gigabytes.
#'
#' @example inst/roxygen-examples/default_heap-example.R
#' @noRd
#' @keywords internal
default_heap <- function() {
  heap <- getOption(
    "java.heap.size",
    Sys.getenv("JAVA_HEAP_SIZE", unset = NA)
  )

  if (is.na(heap)) "2g" else heap
}

# nocov start

#' @title Read a line from the console
#'
#' @description
#' Only written so we can mock for testing
#'
#' @example inst/roxygen-examples/dot-read_line-example.R
#' @noRd
#' @keywords internal
.read_line <- function(prompt) {
  readline(prompt)
}

# nocov end

#' @title Ask for Java heap size
#'
#' @description
#' This function prompts the user to specify the Java heap size if the heap
#' size is not set in the options or environment variables. Is only used in
#' interactive sessions.
#'
#' @example inst/roxygen-examples/ask_heap_size-example.R
#' @noRd
#' @keywords internal
ask_heap_size <- function() {
  prompt <- paste(
    "How many GB should the Java heap use?",
    "Press <Return> for the default (2):"
  )
  repeat {
    answer <- .read_line(prompt)
    if (!nzchar(answer)) {
      return("2g")
    }
    if (grepl("^[1-9][0-9]*$", answer)) {
      return(paste0(answer, "g"))
    }
    message("Please enter a positive integer such as 4, 8, 16, etc.")
  }
}

#' @title Initialize Java Virtual Machine for causalDisco
#' @description
#' Initializes the JVM and sets heap size and classpath based on the
#' Tetrad JAR installed via `install_tetrad()`. If the JVM is already initialized,
#' adds the JAR to the classpath if needed.
#' @param heap A string specifying the JVM heap size (e.g., "2g" for 2 GB).
#' @noRd
#' @keywords internal
init_java <- function(heap = default_heap()) {
  .check_if_pkgs_are_installed(
    pkgs = "rJava",
    function_name = "init_java"
  )

  version <- getOption("causalDisco.tetrad.version")
  dir <- get_tetrad_dir(version)
  jar <- character(0)
  if (length(dir)) {
    # Load only the JAR for the requested version: putting several Tetrad JARs
    # on the classpath makes the loaded classes depend on file order.
    jar <- file.path(dir, paste0("tetrad-gui-", version, "-launch.jar"))
    if (!file.exists(jar)) {
      # Fall back to a single, differently named JAR (e.g. in `TETRAD_DIR`).
      files_in_dir <- list.files(dir, full.names = TRUE)
      jar <- files_in_dir[grepl(
        "tetrad.*\\.jar$",
        files_in_dir,
        ignore.case = TRUE
      )]
      if (length(jar) > 1L) {
        stop(
          "Found several Tetrad JARs in ",
          dir,
          " but none named tetrad-gui-",
          version,
          "-launch.jar. Keep only one, or set ",
          "`options(causalDisco.tetrad.version)` to match one of them.",
          call. = FALSE
        )
      }
    }
  }
  if (!length(jar)) {
    stop("No Tetrad JAR found for version ", version)
  }

  if (rJava::.jniInitialized) {
    if (!(jar %in% rJava::.jclassPath())) {
      rJava::.jaddClassPath(jar)
    }
  } else {
    rJava::.jinit(parameters = paste0("-Xmx", heap), classpath = jar)
  }
}

#' @title Parse heap size string
#'
#' @description
#' This function parses a heap size string and returns the size in gigabytes.
#'
#' @param x A string representing the heap size, e.g., "4g" or "4096m".
#' @returns A numeric value representing the heap size in gigabytes.
#'
#' @example inst/roxygen-examples/parse_heap_gb-example.R
#' @noRd
#' @keywords internal
parse_heap_gb <- function(x) {
  checkmate::assert_character(x, len = 1, any.missing = FALSE)

  x <- tolower(trimws(as.character(x)))

  # Match decimal numbers for GB
  if (grepl("^\\d+(\\.\\d+)?g(b)?$", x)) {
    return(as.double(sub("g(b)?$", "", x)))
  }

  # Match decimal numbers for MB
  if (grepl("^\\d+(\\.\\d+)?m(b)?$", x)) {
    return(as.double(sub("m(b)?$", "", x)) / 1024)
  }

  stop(
    "Heap string \"",
    x,
    "\" not recognised. ",
    "Specify a number (integer or decimal) followed by 'g' (gigabytes) ",
    "or 'm' (megabytes), e.g. \"4g\" or \"4096m\"."
  )
}


#' @title Get current Java heap size in gigabytes
#'
#' @description
#' This function retrieves the current Java heap size in gigabytes (based on
#' rough calculation).
#'
#' @returns A numeric value representing the current heap size in gigabytes.
#'
#' @example inst/roxygen-examples/current_heap_gb-example.R
#' @noRd
#' @keywords internal
current_heap_gb <- function() {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "rJava"
    ),
    function_name = "current_heap_gb"
  )
  rt <- rJava::.jcall("java/lang/Runtime", "Ljava/lang/Runtime;", "getRuntime")
  (rJava::.jcall(rt, "J", "maxMemory") / 1e9) |> round()
}

#' @title Check if required packages are installed
#'
#' @description
#' Used in functions and classes in causalDisco to check if required packages
#' are installed with a more informative error message.
#'
#' @param pkgs Character vector of package names to check.
#' @param function_name Name of the function requiring the packages (string).
#' @param class_name Name of the R6 class requiring the packages (string).
#'
#' @returns Invisibly returns TRUE if all packages are installed,
#'   otherwise stops or warns.
#'
#' @example inst/roxygen-examples/dot-check_if_pkgs_are_installed-example.R
#' @keywords internal
#' @noRd
.check_if_pkgs_are_installed <- function(
  pkgs,
  function_name = NULL,
  class_name = NULL
) {
  checkmate::assert_character(pkgs, min.len = 1)

  if (is.null(function_name) && is.null(class_name)) {
    stop(
      "Either function_name or class_name must be provided for ",
      ".check_if_pkgs_are_installed()",
      call. = FALSE
    )
  }
  not_installed <- pkgs[
    !vapply(
      pkgs,
      requireNamespace,
      quietly = TRUE,
      FUN.VALUE = logical(1)
    )
  ]

  if (!is.null(function_name)) {
    if (length(not_installed) > 0) {
      msg <- paste0(
        "The following packages are required for `",
        function_name,
        "()` but are not installed: \n       [",
        paste(not_installed, collapse = ", "),
        "].\n       Please install them with install.packages()."
      )
      stop(msg, call. = FALSE)
    }
  } else if (!is.null(class_name)) {
    if (length(not_installed) > 0) {
      msg <- paste0(
        "The following packages are required for the R6 class `",
        class_name,
        "` but are not installed: \n       [",
        paste(not_installed, collapse = ", "),
        "].\n       Please install them with install.packages()."
      )
      stop(msg, call. = FALSE)
    }
  }
  invisible(TRUE)
}
