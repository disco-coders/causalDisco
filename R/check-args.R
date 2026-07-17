#' @title Argument Checking and Dispatching
#'
#' @description
#' This function checks if the provided arguments are valid for the specified
#' engine and algorithm, and distributes them accordingly.
#'
#' @param search An object of class \code{TetradSearch}
#' (required if engine is "tetrad").
#' @param args A named list of arguments to be checked and distributed.
#' @param engine The engine to be used
#' (e.g., "tetrad", "pcalg", "bnlearn", "causalDisco").
#' @param alg The algorithm to be used
#' (e.g., "pc", "fci", "ges", etc.).
#' @param test The independence test to be used (if applicable).
#' @param score The scoring method to be used (if applicable).
#' @returns A list containing the distributed arguments for the algorithm, test,
#' and score.
#'
#' @example inst/roxygen-examples/check_args-example.R
#'
#' @noRd
#' @keywords internal
check_args_and_distribute_args <- function(
  search,
  args,
  engine,
  alg,
  test = NULL,
  score = NULL
) {
  # Check if the engine is supported
  if (!(engine %in% engine_registry)) {
    stop(
      "Engine ",
      paste(engine),
      " is not supported. Supported engines are: ",
      paste(engine_registry, collapse = ", "),
      call. = FALSE
    )
  }

  if (is.null(search) && engine == "tetrad") {
    stop(
      "TetradSearch object must be provided for Tetrad engine.",
      call. = FALSE
    )
  }
  switch(
    engine,
    tetrad = check_args_and_distribute_args_tetrad(
      search,
      args,
      alg,
      test,
      score
    ),
    pcalg = check_args_and_distribute_args_pcalg(
      args,
      alg,
      test,
      score
    ),
    bnlearn = check_args_and_distribute_args_bnlearn(
      args,
      alg
    ),
    causalDisco = check_args_and_distribute_args_causalDisco(
      args,
      alg,
      test,
      score
    )
  )
}

#' Check arguments and distribute them to TetradSearch class functions
#'
#' @keywords internal
#' @noRd
check_args_and_distribute_args_tetrad <- function(
  search,
  args,
  alg,
  test = NULL,
  score = NULL
) {
  if (tolower(alg) %in% names(tetrad_alg_registry)) {
    return(list(
      alg_args = args$alg %||% args,
      test_args = args$test %||% list(),
      score_args = args$score %||% list()
    ))
  }

  if (is.null(test) && is.null(score)) {
    stop("Neither test or score is specified.", call. = FALSE)
  }

  # Verbose will be passed directly to TetradSearch class.
  if ("verbose" %in% names(args)) {
    search$set_verbose(args[["verbose"]])
    args$verbose <- NULL
  }

  engine_args_test <- c()
  engine_args_score <- c()
  if (!is.null(test)) {
    engine_args_test <- search$get_parameters_for_function(test, test = TRUE)
  }
  if (!is.null(score)) {
    engine_args_score <- search$get_parameters_for_function(score, score = TRUE)
  }
  engine_args_alg <- search$get_parameters_for_function(alg, alg = TRUE)

  args_to_pass_to_engine_alg <- args[names(args) %in% engine_args_alg]
  args_to_pass_to_engine_score <- args[names(args) %in% engine_args_score]
  args_to_pass_to_engine_test <- args[names(args) %in% engine_args_test]

  args_not_in_engine_args <- setdiff(
    names(args),
    c(engine_args_alg, engine_args_test, engine_args_score)
  )
  if (length(args_not_in_engine_args) > 0) {
    stop(
      "The following arguments are not used in Tetrad algorithm, test, or score: ",
      paste(args_not_in_engine_args, collapse = ", "),
      call. = FALSE
    )
  }
  list(
    alg_args = args_to_pass_to_engine_alg,
    test_args = args_to_pass_to_engine_test,
    score_args = args_to_pass_to_engine_score
  )
}

#' Check arguments and distribute them to pcalg class functions
#'
#' @keywords internal
#' @noRd
check_args_and_distribute_args_pcalg <- function(
  args,
  alg,
  test = NULL,
  score = NULL
) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "methods",
      "pcalg"
    ),
    function_name = "check_args_and_distribute_args_pcalg"
  )

  # Note that the pcalg package does not have args that are sent
  # directly to the test itself, but it is rather sent to the algorithm.
  engine_args_alg <- switch(
    alg,
    pc = names(formals(pcalg::pc)),
    fci = names(formals(pcalg::fci)),
    ges = names(formals(pcalg::ges)),
    rfci = names(formals(pcalg::rfci)),
    stop("Unsupported algorithm: ", alg, call. = FALSE)
  )

  wrapper_args <- c("suff_stat_fun", "args")
  wrapper_args_out <- args[names(args) %in% wrapper_args]

  args_to_pass_to_engine_alg <- args[
    names(args) %in% engine_args_alg & !(names(args) %in% wrapper_args)
  ]
  engine_args_score <- list()
  if (!is.null(score)) {
    engine_args_score <- methods::getRefClass("GaussL0penIntScore")$methods(
      "initialize"
    ) |>
      methods::formalArgs()
    args_to_pass_to_engine_score <- args[names(args) %in% engine_args_score]
  } else {
    args_to_pass_to_engine_score <- list()
  }
  # Check if any arguments are not in pcalg::
  args_not_in_engine_args <- setdiff(
    names(args),
    c(
      names(args_to_pass_to_engine_alg),
      engine_args_score,
      wrapper_args
    )
  )
  # If '...' in given algorithm/test is an argument, it will throw a warning
  # rather than an error.
  if (length(args_not_in_engine_args) > 0) {
    if ("..." %in% c(engine_args_alg, engine_args_score)) {
      warning(
        paste0("The following arguments are not used in pcalg::", alg, ": "),
        paste(args_not_in_engine_args, collapse = ", "),
        call. = FALSE
      )
    } else {
      stop(
        paste0("The following arguments are not used in pcalg::", alg, ": "),
        paste(args_not_in_engine_args, collapse = ", "),
        call. = FALSE
      )
    }
  }
  list(
    alg_args = args_to_pass_to_engine_alg,
    score_args = args_to_pass_to_engine_score,
    wrapper_args = wrapper_args_out
  )
}

#' Check arguments and distribute them to causalDisco class functions
#'
#' @keywords internal
#' @noRd
check_args_and_distribute_args_causalDisco <- function(
  args,
  alg,
  test = NULL,
  score = NULL
) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "methods",
      "pcalg"
    ),
    function_name = "check_args_and_distribute_args_causalDisco"
  )

  # Note that the causalDisco package does not have args that are sent
  # directly to the test itself
  # Determine main algorithm function and corresponding _run function
  switch(
    alg,
    tpc = {
      engine_fun <- tpc
      engine_run_fun <- tpc_run
    },
    tfci = {
      engine_fun <- tfci
      engine_run_fun <- tfci_run
    },
    tges = {
      engine_fun <- tges
      engine_run_fun <- tges_run
    },
    stop("Unsupported algorithm: ", alg, call. = FALSE)
  )

  wrapper_args <- c("suff_stat_fun", "args")
  wrapper_args_out <- args[names(args) %in% wrapper_args]

  # Get arguments of the top-level function
  engine_args_alg <- names(formals(engine_fun))

  # Initialize list of args to pass
  args_to_pass_to_engine_alg <- args[
    names(args) %in% engine_args_alg & !(names(args) %in% wrapper_args)
  ]

  # If ... is in top-level args, we need to also check _run function args
  if ("..." %in% engine_args_alg) {
    engine_args_run <- names(formals(engine_run_fun))
    extra_args <- args[
      !(names(args) %in% engine_args_alg) &
        (names(args) %in% engine_args_run)
    ]
    args_to_pass_to_engine_alg <- c(args_to_pass_to_engine_alg, extra_args)
  }

  # Score-related args
  engine_args_score <- list()
  if (!is.null(score)) {
    score <- tolower(score)

    score <- switch(
      score,
      tbic = "TemporalBIC",
      tbdeu = "TemporalBDeu",
      stop("Unsupported score: ", score, call. = FALSE)
    )

    engine_args_score <- methods::getRefClass(score)$methods("initialize") |>
      methods::formalArgs()
    args_to_pass_to_engine_score <- args[names(args) %in% engine_args_score]
  } else {
    args_to_pass_to_engine_score <- list()
  }

  # Check for unused arguments
  args_not_in_engine_args <- setdiff(
    names(args),
    c(
      names(args_to_pass_to_engine_alg),
      engine_args_score,
      wrapper_args
    )
  )

  # If '...' in given algorithm/test is an argument, it will throw a warning
  # rather than an error.
  if (length(args_not_in_engine_args) > 0) {
    if ("..." %in% c(engine_args_alg, engine_args_score)) {
      warning(
        paste0(
          "The following arguments are not used in causalDisco::",
          alg,
          ": "
        ),
        paste(args_not_in_engine_args, collapse = ", "),
        call. = FALSE
      )
    } else {
      # extra precaution, cannot be hit with current algorithms in causalDisco
      # nocov start
      stop(
        paste0(
          "The following arguments are not used in causalDisco::",
          alg,
          ": "
        ),
        paste(args_not_in_engine_args, collapse = ", "),
        call. = FALSE
      )
      # nocov end
    }
  }
  list(
    alg_args = args_to_pass_to_engine_alg,
    score_args = args_to_pass_to_engine_score,
    wrapper_args = wrapper_args_out
  )
}

#' @title Check arguments for BnlearnSearch class functions
#'
#' @keywords internal
#' @noRd
check_args_and_distribute_args_bnlearn <- function(
  args,
  alg,
  allow_dots = FALSE
) {
  .check_if_pkgs_are_installed(
    pkgs = "bnlearn",
    function_name = "check_args_and_distribute_args_bnlearn"
  )

  # Convert algorithm name to match bnlearn function naming convention (e.g., "fast_iamb" to "fast.iamb")
  alg_period <- gsub("_", ".", alg)

  if (!exists(alg_period, envir = asNamespace("bnlearn"))) {
    stop("Unsupported algorithm: ", alg, call. = FALSE)
  }

  bn_fun <- get(alg_period, envir = asNamespace("bnlearn"))
  alg_formals <- names(formals(bn_fun))
  dots_allowed <- "..." %in% alg_formals

  unclaimed <- setdiff(names(args), alg_formals)

  if (length(unclaimed) > 0) {
    if (!dots_allowed) {
      stop(
        "The following arguments are not valid for bnlearn::",
        alg,
        ": ",
        paste(unclaimed, collapse = ", "),
        call. = FALSE
      )
    }

    # ---- bnlearn has B, fun, and args as the only ... arguments for constraint based algorithms (passed to tests) ----
    allowed_dot_args_tests <- c("B", "fun", "args")

    # ---- bnlearn has iss, iss.mu, iss.w, nu, l, exp, k, gamma, prior, beta, newdata, fun, args as the only ...
    # arguments for score based algorithms (passed to scores) ----
    allowed_dot_args_scores <- c(
      "iss",
      "iss.mu",
      "iss.w",
      "nu",
      "l",
      "exp",
      "k",
      "gamma",
      "prior",
      "beta",
      "newdata",
      "fun",
      "args"
    )
    # TODO: Fix this to it actually checks the namespace for the specific alg instead
    allowed_dot_args_algs <- c("max.sx", "debug", "undirected")
    allowed_dot_args <- c(
      allowed_dot_args_tests,
      allowed_dot_args_scores,
      allowed_dot_args_algs
    )
    truly_unrecognised <- setdiff(unclaimed, allowed_dot_args)

    if (!allow_dots && length(truly_unrecognised) > 0) {
      stop(
        "bnlearn::",
        alg,
        " has a '...' formal, but these arguments are not recognised: ",
        paste(truly_unrecognised, collapse = ", "),
        ". Allowed dot-arguments are: ",
        paste(allowed_dot_args, collapse = ", "),
        ". Set allow_dots = TRUE to forward arbitrary extras.",
        call. = FALSE
      )
    }
  }
  args
}
