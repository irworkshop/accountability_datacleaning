prep_city <- function(cities, abbs = NULL, na = c("NA", "")) {
  cities <- cities %>%
    # prepare string
    str_to_upper() %>%
    str_replace("-", " ") %>%
    str_remove_all("[:punct:]") %>%
    str_remove_all("`") %>%
    str_remove_all("\\d+")

  cities <- cities %>%
    # expand directional abbs
    str_replace("(^|\\b)N(\\b|$)",   "NORTH") %>%
    str_replace("(^|\\b)S(\\b|$)",   "SOUTH") %>%
    str_replace("(^|\\b)W(\\b|$)",   "WEST") %>%
    str_replace("(^|\\b)E(\\b|$)",   "EAST") %>%
    str_replace("(^|\\b)NO(\\b|$)",  "NORTH") %>%
    str_replace("(^|\\b)SO(\\b|$)",  "SOUTH")

  cities <- cities %>%
    # expand location abbs
    str_replace("(^|\\b)LK(\\b|$)", "LAKE") %>%
    str_replace("(^|\\b)MT(\\b|$)", "MOUNT") %>%
    str_replace("(^|\\b)ST(\\b|$)", "SAINT") %>%
    str_replace("(^|\\b)PT(\\b|$)", "PORT") %>%
    str_replace("(^|\\b)PL(\\b|$)", "PLACE") %>%
    str_replace("(^|\\b)FT(\\b|$)", "FORT") %>%
    str_replace("(^|\\b)PK(\\b|$)", "PARK") %>%
    str_replace("(^|\\b)IS(\\b|$)", "PARK") %>%
    str_replace("(^|\\b)ISL(\\b|$)", "PARK") %>%
    str_replace("(^|\\b)VLY(\\b|$)", "VALLEY") %>%
    str_replace("(^|\\b)VLG(\\b|$)", "VILLAGE") %>%
    str_replace("(^|\\b)BCH(\\b|$)", "BEACH") %>%
    str_replace("(^|\\b)STA(\\b|$)", "STATION") %>%
    str_replace("(^|\\b)MTN(\\b|$)", "MOUNTAIN") %>%
    str_replace("(^|\\b)TWP(\\b|$)", "TOWNSHIP") %>%
    str_replace("^NYC$", "NEW YORK") %>%
    str_replace("(^|\\b)A F B(\\b|$)", "AIR FORCE BASE") %>%
    str_replace("(^|\\b)USAF(\\b|$)", "UNITED STATES AIR FORCE") %>%
    str_replace("(^|\\b)U S A F(\\b|$)", "UNITED STATES AIR FORCE")

  cities <- cities %>%
    # remove bad white space
    str_squish() %>%
    str_trim() %>%
    na_if("")

  # remove every abb from end of string
  if (!is.null(abbs)) {
    for (i in seq_along(abbs)) {
      cities <- str_remove(cities, str_c("\\s", abbs[i], "$"))
    }
  }

  # make NA if in list
  cities[which(cities %in% na)] <- NA
  # make NA if only 1 char
  cities[which(str_detect(cities, "^.$"))] <- NA

  return(cities)
}
