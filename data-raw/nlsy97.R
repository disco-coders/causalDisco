library(readr)
library(dplyr)

# Downloaded from https://www.nlsinfo.org/investigator/pages/search?s=NLSY97
# with the RNUM codes shown below

nlsy97_raw <- read_csv("data-raw/nlsy97-raw.csv")

# Following missing codes:
# Refusal(-1)
# Don't Know(-2)
# Invalid Skip(-3)
# VALID SKIP(-4)
# NON-INTERVIEW(-5)
# UNGRADED(-6) (see r1_mcollege)
# UNKNOWN(-7) (see r1_rural_urban)

na_codes <- -7:-1

nlsy97 <- nlsy97_raw |>
  select(
    -R0000100, # respondent ID

    r1_hhchildren = R1205500,
    r1_mcollege = R1302500,
    r1_rural_urban = R1217500,

    r6_depressed = S0921200,
    r6_docvisits = S1240000,
    r6_exercise = S1225300,

    r12_depressed = T2783000,
    r12_docvisits = T3155500,
    r12_health = T3144600
  ) |>

  # -----------------------------
  # NA recodes + special recodes
  # -----------------------------
  mutate(
    r1_mcollege = if_else(r1_mcollege == 95, -6, r1_mcollege),
    r1_rural_urban = if_else(r1_rural_urban == 2, -7, r1_rural_urban)
  ) |>

  # Handle all NA codes the same (might want to do something more sophisticated)
  mutate(across(everything(), ~ replace(.x, .x %in% na_codes, NA))) |>

  # -----------------------------
  # Recode doctor visits
  # -----------------------------
  mutate(
    r6_docvisits = r6_docvisits - 1,
    r12_docvisits = r12_docvisits - 1
  ) |>

  mutate(
    r1_mcollege = factor(
      if_else(r1_mcollege >= 13, 1, 0),
      levels = c(0, 1),
      labels = c("No", "Yes")
    ),

    r1_rural_urban = factor(
      r1_rural_urban,
      levels = c(0, 1),
      labels = c("Rural", "Urban")
    ),

    r6_depressed = factor(
      # 4 is `None`, 1, 2, 3 are respectively `All`, `Most`, `Sometimes`
      if_else(r6_depressed == 4, 0, 1),
      levels = c(0, 1),
      labels = c("No", "Any")
    ),

    r12_depressed = factor(
      if_else(r12_depressed == 4, 0, 1),
      levels = c(0, 1),
      labels = c("No", "Any")
    ),

    r12_health = factor(
      # 1, 2, and are respectively `Execellent`, `Very good` and `Good`
      # 4 and 5 are respectively `Fair` and `Poor`
      if_else(r12_health <= 3, 1, 0),
      levels = c(0, 1),
      labels = c("Poor", "Good")
    )
  )

# Complete case analysis
nlsy97 <- nlsy97[complete.cases(nlsy97), ]

usethis::use_data(nlsy97, overwrite = TRUE)
