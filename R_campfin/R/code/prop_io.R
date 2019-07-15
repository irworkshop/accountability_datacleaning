prop_in <- function(x, y, na.rm = FALSE) {
  if (na.rm) {
    prop <- mean(na.omit(x) %in% y)
  } else {
    prop <- mean(x %in% y)
  }
  return(prop)
}

prop_out <- function(x, y, na.rm = FALSE) {
  if (na.rm) {
    prop <- mean(!(na.omit(x) %in% y))
  } else {
    prop <- mean(!(x %in% y))
  }
  return(prop)
}
