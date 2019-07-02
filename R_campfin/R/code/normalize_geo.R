# Normalize geographic values

# addresses ----------------------------------------------------------------------------------

normalize_address <- function(address, abbs = NULL, na = c("")) {

  address_clean <- address %>%
    str_to_upper() %>%
    str_replace("-", " ") %>%
    str_remove_all("[[:punct:]]") %>%
    str_trim() %>%
    str_squish() %>%
    str_replace("P\\sO", "PO")

  if (!is.null(abbs)) {
    abbs <- as.data.frame(abbs)
    for (i in seq_along(abbs[, 1])) {
      address_clean <- str_replace(
        string = address_clean,
        pattern = str_c("\\b", abbs[i, 1], "\\b"),
        replacement = abbs[i, 2]
      )
    }
  }

  address_clean[which(address_clean %in% na)] <- NA

  return(address_clean)
}

# zip codes ----------------------------------------------------------------------------------

normalize_zip <- function(zip, na = c("")) {

  zip_clean <- zip %>%
    str_remove_all("\\D") %>%
    str_pad(width = 5, side = "left", pad = "0") %>%
    str_sub(start = 1, end = 5)

  return(zip_clean)
}

# state abbs ---------------------------------------------------------------------------------

normalize_state <- function(state, valid = NULL, na = c("")) {

  state_clean <- state %>%
    str_to_upper() %>%
    str_remove("[^A-z]") %>%
    str_sub(start = 1, end = 2)

  if (!is.null(valid)) {
    state_clean[which(state_clean %in% na)] <- NA
    state_clean[!(state_clean %in% valid)] <- NA
  }

  state_clean[which(state_clean %in% na)] <- NA

  return(state_clean)
}

# cities -------------------------------------------------------------------------------------

normalize_city <- function(city, geo_abbs = NULL, state_abbs = NULL, na = c("")) {

  city_clean <- city %>%
    str_to_upper() %>%
    str_replace("-", " ") %>%
    str_remove_all("[[:punct:]]") %>%
    str_remove("\\d+") %>%
    str_trim() %>%
    str_squish() %>%
    na_if("")

  if (!is.null(geo_abbs)) {
    geo_abbs <- as.data.frame(geo_abbs)
    for (i in seq_along(geo_abbs[, 1])) {
      address_clean <- str_replace(
        string = address_clean,
        pattern = str_c("\\b", geo_abbs[i, 1], "\\b"),
        replacement = geo_abbs[i, 2]
      )
    }
  }

  if (!is.null(state_abbs)) {
    for (i in seq_along(state_abbs)) {
      city_clean <- str_remove(city_clean, str_c("\\s", state_abbs[i], "$"))
    }
  }

  city_clean[which(city_clean %in% na)] <- NA

  return(city_clean)
}
