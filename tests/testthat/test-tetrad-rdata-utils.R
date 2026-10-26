test_that("r_data_to_tetrad numeric", {
  skip_if_no_tetrad()
  # Create numeric vectors
  var1 <- c(1.2, 2.3, 3.1, 4.5)
  var2 <- c(5.1, 6.2, 7.3, 8.4)

  # Create data frame
  my_df <- data.frame(var1, var2)

  tetrad_data <- rdata_to_tetrad(my_df)
  expect_equal(class(tetrad_data)[1], "jobjRef")
})

test_that("rdata_to_tetrad factor", {
  skip_if_no_tetrad()
  # Create vectors
  color <- factor(c("red", "blue", "red", "green"))
  shape <- factor(c("circle", "square", "triangle", "circle"))

  # Create data frame
  my_df <- data.frame(color, shape)

  tetrad_data <- rdata_to_tetrad(my_df)
  expect_equal(class(tetrad_data)[1], "jobjRef")
})
