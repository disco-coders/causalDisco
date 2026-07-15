#' Test for Vanishing Partial Correlations
#'
#' This function simply calls the [pcalg::gaussCItest()] function from the \pkg{pcalg} package.
#'
#' @param x Index of x variable.
#' @param y Index of y variable.
#' @param conditioning_set Index vector of conditioning variable(s), possibly `NULL`.
#' @param suff_stat Sufficient statistic; A list with two elements, "C" and "n",
#' corresponding to the correlation matrix and number of observations.
#' @return A numeric, which is the p-value of the test.
#'
#' @export
cor_test <- function(x, y, conditioning_set, suff_stat) {
  .check_if_pkgs_are_installed(
    pkgs = c("pcalg"),
    function_name = "cor_test"
  )
  pcalg::gaussCItest(x, y, conditioning_set, suff_stat)
}


#' Regression-based Information Loss Test
#'
#' Test whether \code{x} and \code{y} are associated, given
#' \code{conditioning_set} using a generalized linear model.
#'
#' @details All included variables should be either numeric or binary. If
#' \code{y} is binary, a logistic regression model is fitted. If \code{y} is numeric,
#' a linear regression model is fitted. \code{x} and \code{conditioning_set} are included as
#' explanatory variables. Any numeric variables among \code{x} and \code{conditioning_set} are
#' modeled with spline expansions (natural splines, 3 df). This model is tested
#' against a numeric where \code{x} (including a possible spline expansion) has
#' been left out using a likelihood ratio test.
#' The model is fitted in both directions (interchanging the roles
#' of \code{x} and \code{y}). The final p-value is the maximum of the two
#' obtained p-values.
#' @param suff_stat List with data, binary variables and order.
# #' @param suff_stat `r lifecycle::badge('deprecated')`. Use `data_info` instead.
#' @inheritParams cor_test
#'
#' @return A numeric, which is the p-value of the test.
#'
#' @examples
#' # Use via disco() and method functions (recommended):
#' data(tpc_example)
#' my_tpc <- tpc(engine = "causalDisco", test = "reg", alpha = 0.05)
#' result <- disco(data = tpc_example, method = my_tpc)
#'
#' @export
reg_test <- function(x, y, conditioning_set, suff_stat) {
  p1 <- reg_test_each_dir(x, y, conditioning_set, suff_stat)
  p2 <- reg_test_each_dir(y, x, conditioning_set, suff_stat)

  max(p1, p2)
}

############################################################################
## Not exported below ######################################################
############################################################################

reg_test_each_dir <- function(x, y, conditioning_set, suff_stat) {
  .check_if_pkgs_are_installed(
    pkgs = c(
      "splines",
      "stats"
    ),
    function_name = "reg_test_each_dir"
  )

  dfs <- 3
  df_string <- paste(", df = ", dfs, ")", sep = "")

  data <- suff_stat$data
  binary <- suff_stat$binary
  vnames <- names(data)

  # Restrict data to only complete cases of x, y, conditioning_set (test-wise deletion)
  data <- stats::na.omit(data[, c(x, y, conditioning_set)])

  # Choose exponential family according to ys type
  if (binary[y]) {
    fam <- "binomial"
  } else {
    fam <- "gaussian"
  }

  # Store info: is x binary?
  binx <- binary[x]

  # Store info: which conditioning_set are binary?
  bin_conditioning_set <- intersect(conditioning_set, which(binary))
  num_conditioning_set <- setdiff(conditioning_set, bin_conditioning_set)

  # extract variable names
  x <- vnames[x]
  y <- vnames[y]
  conditioning_set_bin <- vnames[bin_conditioning_set]
  conditioning_set_num <- vnames[num_conditioning_set]

  # add spline to num x, factor to binary x
  if (!binx) {
    if (dfs > 0) x <- paste("splines::ns(", x, df_string, sep = "")
  } else {
    x <- paste("factor(", x, ")", sep = "")
  }

  # add spline to num_conditioning_set, factor to binary conditioning_set_bin
  if (length(conditioning_set_num) > 0) {
    conditioning_set_num <- paste(
      "splines::ns(",
      conditioning_set_num,
      df_string,
      sep = ""
    )
  }
  if (length(conditioning_set_bin) > 0) {
    conditioning_set_bin <- paste(
      "factor(",
      conditioning_set_bin,
      ")",
      sep = ""
    )
  }
  conditioning_set <- c(conditioning_set_bin, conditioning_set_num, "1")

  # wrap factor around binary f
  if (fam == "binomial") {
    y <- paste("factor(", y, ")", sep = "")
  }

  # make formulas
  f1 <- stats::as.formula(paste(
    y,
    "~",
    paste(conditioning_set, collapse = " + ")
  ))
  f2 <- stats::update(f1, stats::as.formula(paste(". ~ . + ", x, sep = "")))

  # fit models
  m1 <- suppressWarnings(stats::glm(f1, data = data, family = fam))
  m2 <- suppressWarnings(stats::glm(f2, data = data, family = fam))

  # if convergence fails, output 0 (corresponds to no sep)
  if (!m1$converged || !m2$converged) {
    return(0)
  }

  # test
  stats::anova(m1, m2, test = "LRT")$`Pr(>Chi)`[2]
}
