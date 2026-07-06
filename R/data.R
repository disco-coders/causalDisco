#' Simulated Life-Course Data
#'
#' A small simulated data example intended to showcase the TPC algorithm. Note that the variable name
#' prefixes defines which period they are related to ("child", "youth" or "oldage").
#'
#' @format A data.frame with 200 rows and 6 variables.
#' \describe{
#'  \item{child_x1}{Structural equation: \eqn{X_1 := \epsilon_1} with \eqn{\epsilon_1 \sim \mathrm{Unif}\{0,1\}}}
#'  \item{child_x2}{Structural equation: \eqn{X_2 := 2 \cdot X_1 + \epsilon_2} with \eqn{\epsilon_2 \sim N(0,1)}}
#'  \item{youth_x3}{Structural equation: \eqn{X_3 := \epsilon_3} with \eqn{\epsilon_3 \sim \mathrm{Unif}\{0, 1\}}}
#'  \item{youth_x4}{Structural equation: \eqn{X_4 := X_2 + \epsilon_4} with \eqn{\epsilon_4  \sim  N(0,1)}}
#'  \item{oldage_x5}{Structural equation: \eqn{X_5 := X_3^2 + X_3 - 3 \cdot X_2 + \epsilon_5} with \eqn{\epsilon_5 \sim N(0,1)}}
#'  \item{oldage_x6}{Structural equation: \eqn{X_6 := X_4^3 + X_4^2 + 2 \cdot X_5 + \epsilon_6} with \eqn{\epsilon_6 \sim N(0,1)}}
#'  }
#'
#' @references Petersen, AH; Osler, M and Ekstrøm, CT (2021): Data-Driven Model Building for Life-Course Epidemiology,
#'  American Journal of Epidemiology.
#'
#' @examples
#' data(tpc_example)
#' head(tpc_example)
#' @concept dataset
"tpc_example"

#' Simulated Numerical Data
#'
#' @format A data.frame with 1000 rows and 5 variables.
#' \describe{
#'  \item{X1}{Structural equation: \eqn{X_1 := \sqrt{Z} + \epsilon_1} with \eqn{\epsilon_1 \sim \mathrm{Unif}[0, 2]}}
#'  \item{X2}{Structural equation: \eqn{X_2 := 2 \cdot X_3 - \epsilon_2} with \eqn{\epsilon_2 \sim N(5, 1)}}
#'  \item{X3}{Structural equation: \eqn{X_3 := \epsilon_3} with \eqn{\epsilon_3 \sim \mathrm{Unif}[5, 10]}}
#'  \item{Z}{Structural equation: \eqn{Z := |\epsilon_4|} with \eqn{\epsilon_4 \sim N(10, 1)}}
#'  \item{Y}{Structural equation: \eqn{Y := X_1^2 + X_2 - X_3 - Z + \epsilon_5} with \eqn{\epsilon_5 \sim N(10, 1)}}
#' }
#'
#' @details
#' The R code used to generate this dataset is as follows:
#'
#' ```R
#' set.seed(1405)
#' n <- 1000
#' Z <- abs(rnorm(n, mean = 10))
#' X1 <- sqrt(Z) + runif(n, min = 0, max = 2)
#' X3 <- runif(n, min = 5, max = 10)
#' X2 <- 2 * X3 - rnorm(n, mean = 5)
#' Y  <- X1^2 + X2 - X3 - Z + rnorm(n, mean = 10)
#' num_data <- data.frame(X1, X2, X3, Z, Y)
#' ```
#'
#' @examples
#' data(num_data)
#' head(num_data)
#' @concept dataset
"num_data"

#' Simulated Categorical Data
#'
#' A dataset created by discretizing the continuous `num_data` into 5 categorical levels per variable.
#'
#' @format A data.frame with 1000 rows and 5 variables.
#' \describe{
#'  \item{X1}{Categorical version of `num_data$X1`, with 5 levels a–e.}
#'  \item{X2}{Categorical version of `num_data$X2`, with 5 levels a–e.}
#'  \item{X3}{Categorical version of `num_data$X3`, with 5 levels a–e.}
#'  \item{Z}{Categorical version of `num_data$Z`, with 5 levels a–e.}
#'  \item{Y}{Categorical version of `num_data$Y`, with 5 levels a–e.}
#' }
#'
#' @details
#' The R code used to generate this dataset is as follows:
#'
#' ```R
#' data(num_data)
#' cat_data <- as.data.frame(
#'   lapply(num_data, function(x) cut(x, breaks = 5, labels = letters[1:5]))
#' )
#' ```
#'
#' @examples
#' data(cat_data)
#' head(cat_data)
#'
#' @seealso [num_data]
#' @concept dataset
"cat_data"

#' Simulated Ordered Categorical Data
#'
#' A dataset created by discretizing the continuous `num_data` into 5 ordered categorical levels per variable.
#'
#' @format A data.frame with 1000 rows and 5 variables.
#' \describe{
#'  \item{X1}{Categorical version of `num_data$X1`, with 5 ordered levels a–e.}
#'  \item{X2}{Categorical version of `num_data$X2`, with 5 ordered levels a–e.}
#'  \item{X3}{Categorical version of `num_data$X3`, with 5 ordered levels a–e.}
#'  \item{Z}{Categorical version of `num_data$Z`, with 5 ordered levels a–e.}
#'  \item{Y}{Categorical version of `num_data$Y`, with 5 ordered levels a–e.}
#' }
#'
#' @details
#' The R code used to generate this dataset is as follows:
#'
#' ```R
#' data(num_data)
#' cat_ord_data <- as.data.frame(
#'   lapply(num_data, function(x) cut(x, breaks = 5, labels = letters[1:5], ordered_result = TRUE))
#' )
#' ```
#'
#' @examples
#' data(cat_ord_data)
#' head(cat_ord_data)
#'
#' @seealso [num_data]
#' @concept dataset
"cat_ord_data"

#' Simulated Mixed Data
#'
#' A dataset combining continuous and categorical variables. The first three variables are replaced
#' with categorical versions from `cat_data`.
#'
#' @format A data.frame with 1000 rows and 5 variables.
#' \describe{
#'  \item{X1}{Categorical, from `cat_data$X1`.}
#'  \item{X2}{Categorical, from `cat_data$X2`.}
#'  \item{X3}{Categorical, from `cat_data$X3`.}
#'  \item{Z}{Numeric, same as `num_data$Z`.}
#'  \item{Y}{Numeric, same as `num_data$Y`.}
#' }
#'
#' @details
#' The R code used to generate this dataset is as follows:
#'
#' ```R
#' data(num_data)
#' data(cat_data)
#' mix_data <- num_data
#' mix_data$X1 <- cat_data$X1
#' mix_data$X2 <- cat_data$X2
#' mix_data$X3 <- cat_data$X3
#' ```
#'
#' @examples
#' data(mix_data)
#' head(mix_data)
#'
#' @seealso [num_data], [cat_data]
#' @concept dataset
"mix_data"

#' Simulated Categorical Data with MCAR
#'
#' A dataset based on `cat_data` where some values are randomly removed to simulate MCAR.
#'
#' @format A data.frame with 1000 rows and 5 variables.
#' \describe{
#'  \item{X1}{Categorical, 100 values set to NA (MCAR).}
#'  \item{X2}{Categorical, 50 values set to NA (MCAR).}
#'  \item{X3}{Categorical, 200 values set to NA (MCAR).}
#'  \item{Z}{Categorical, no missing values.}
#'  \item{Y}{Categorical, no missing values.}
#' }
#'
#' @details
#' The R code used to generate this dataset is as follows:
#'
#' ```R
#' data(cat_data)
#' cat_data_mcar <- cat_data
#' n <- nrow(cat_data_mcar)
#' set.seed(1405)
#' cat_data_mcar$X1[sample(1:n, 100)] <- NA
#' cat_data_mcar$X2[sample(1:n, 50)] <- NA
#' cat_data_mcar$X3[sample(1:n, 200)] <- NA
#' ```
#'
#' @examples
#' data(cat_data_mcar)
#' head(cat_data_mcar)
#'
#' @seealso [cat_data]
#' @concept dataset
"cat_data_mcar"

#' Simulated Numerical Data with Latent Variable
#'
#' A dataset similar to `num_data` but with the variable `Z` treated as a latent variable and thus omitted.
#'
#' @format A data.frame with 1000 rows and 4 variables.
#' \describe{
#'  \item{X1}{Structural equation: \eqn{X_1 := \sqrt{Z} + \epsilon_1} with \eqn{\epsilon_1 \sim \mathrm{Unif}[0, 2]}}
#'  \item{X2}{Structural equation: \eqn{X_2 := 2 \cdot X_3 - \epsilon_2} with \eqn{\epsilon_2 \sim N(5, 1)}}
#'  \item{X3}{Structural equation: \eqn{X_3 := \epsilon_3} with \eqn{\epsilon_3 \sim \mathrm{Unif}[5, 10]}}
#'  \item{Z}{Structural equation: \eqn{Z := |\epsilon_4|} with \eqn{\epsilon_4 \sim N(10, 1)}}
#'  \item{Y}{Structural equation: \eqn{Y := X_1^2 + X_2 - X_3 - Z + \epsilon_5} with \eqn{\epsilon_5 \sim N(10, 1)}}
#' }
#'
#' @details
#' The R code used to generate this dataset is as follows:
#'
#' ```R
#' data(num_data)
#' num_data_latent <- num_data[, c("X1", "X2", "X3", "Y")]
#' ```
#'
#' @examples
#' data(num_data_latent)
#' head(num_data_latent)
#'
#' @seealso [num_data]
#' @concept dataset
"num_data_latent"

#' US National Longitudinal Survey of Youth 1997
#'
#' A subset of data from the US National Longitudinal Survey of Youth 1997 (NLSY97).
#' Several ordinal variables were dichotomized for analysis purposes, and all survey-specific missing value codes were
#' recoded to NA.
#'
#' See source code on GitHub in data-raw/ for the raw data, the corresponding RNUM, and code showing how it has been
#' cleaned.
#'
#' @format
#' A tibble with 8,974 rows and 9 columns:
#' \describe{
#'   \item{r1_hhchildren}{Number of household members younger than 18. Measured in Round 1, 1997.}
#'   \item{r1_mcollege}{Did biological mother attend college? Binary factor (levels: No, Yes). Measured in Round 1, 1997.}
#'   \item{r1_rural_urban}{Residence in an urban or a rural area. Binary factor (levels: Rural, Urban). Measured in Round 1, 1997.}
#'   \item{r6_depressed}{Depressive feelings during the last month. Binary factor derived from 4-point scale (levels: Any = 1–3, None = 4). Measured in Round 6, 2002.}
#'   \item{r6_docvisits}{Number of doctor’s visits during the last year. Measured in Round 6, 2002.}
#'   \item{r6_exercise}{Days with 30+ minutes exercise / week. Measured in Round 6, 2002.}
#'   \item{r12_depressed}{Depressive feelings during the last month. Binary factor derived from 4-point scale (levels: Any = 1–3, None = 4). Measured in Round 12, 2008.}
#'   \item{r12_docvisits}{Number of doctor’s visits during the last year. Measured in Round 12, 2008.}
#'   \item{r12_health}{Perception of own health. Binary factor derived from 5-point scale (levels: Good = 1–3, Poor = 4–5). Measured in Round 12, 2008.}
#' }
#' @source <https://www.nlsinfo.org/investigator/pages/search?s=NLSY97>
#'@concept dataset
"nlsy97"
