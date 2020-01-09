library(tidyverse)
library(pdftools)
library(campfin)
backup_options <- options()
options(dplyr.print_min = 30)

# read and wrangle --------------------------------------------------------

# read the x/y coord of every word
pages <- pdf_data("https://www.leg.state.nv.us/Session/79th2017/Lobbyist/Reports/Lobbyists.pdf")

# trim header and footer
pages <- map(pages, ~filter(., between(y, 62, 740)))

# create running y increasing per page
for (i in seq_along(pages)[-length(pages)]) {
  pages[[i + 1]]$y <- pages[[i + 1]]$y + max(pages[[i]]$y)
}

# bind into a single frame
data <- bind_rows(pages, .id = "page")

# list split --------------------------------------------------------------

sections <- data %>%
  # lob left of x 274 and pri to right
  mutate(lob = x < 274, id = row_number()) %>%
  # collapse x line by column
  group_by(y, lob) %>%
  mutate(line = str_c(text, collapse = " ")) %>%
  # keep only one collapsed line
  slice(1) %>%
  arrange(id) %>%
  ungroup() %>%
  # remove original word cols
  select(page, id, lob, line) %>%
  # identify new row section by lob text
  mutate(
    section = line %>%
      # look ahead
      lead(default = FALSE) %>%
      # look for consistent text
      str_detect("^(Non-Paid|Paid)") %>%
      # sum previous TRUEs
      cumsum()
  ) %>%
  # split frame into lists
  group_split(section)

# functions ----------------------------------------------------------------------------------

# create two functions to transform sections to tidy tibbles
#   1. convert lobbyist lines to 1 row w/ many cols
#   2. convert client lines to 2 cols per

frame_lob <- function(section) {
  # work through the lobbyist lines
  # six lines most typical
  #   1. name
  #   2. type
  #   3. address
  #   4. city, state, zip
  #   5. phone
  #   6. email
  # sometimes a corp before address
  # sometimes no phone, email
  # sometimes any line can overflow

  # lines from lob left side
  a <- section$line[section$lob]

  # first line is always a name
  lob_name <- a[1]

  # lob type -----------------------------------------------------------------------------------

  # collapse lob type overflow
  if (a[2] == "Non-Paid Military Veteran" | a[3] == "Lobbyist") {
    a[2] <- str_c(a[2], a[3], sep = " ")
    a <- a[-3]
  }
  lob_type <- a[2]

  # lob email ----------------------------------------------------------------------------------

  # now work from end with regex for tel and email
  # collapse lob email overflow
  # look for lack of @ in last AND @ in second to last
  if (!str_detect(a[length(a)], "@") & str_detect(a[length(a) - 1], "@")) {
    # collapse and replace if email has overflowed
    a[length(a) - 1] <- str_c(a[(length(a)-1):length(a)], collapse = "")
    # replace into single line
    a <- a[-length(a)]
  }

  # check line before @ for non tel or zip
  where_email <- str_which(a, "@")
  pre_email <- a[where_email - 1]
  rx_phone2 <- "\\d{3}\\)\\s\\d{3}-\\d{4}"
  rx_zip2 <- "(\\d+|\\d+-\\d+)"
  if (any(str_detect(a, "@"))) {
    if (!str_detect(pre_email, str_c(rx_phone, rx_phone2, sep = "|")) & !str_detect(pre_email, rx_zip2)) {
      a[where_email - 1] <- str_c(pre_email, a[where_email], collapse = "")
      a <- a[-where_email]
      where_email <- where_email - 1
    }
    lob_email <- a[where_email]
  } else {
    # if no email part detected
    lob_email <- NA_character_
  }

  # lob phone ----------------------------------------------------------------------------------

  # first tel is lob tel

  lob_phone <- str_subset(a, sprintf("^%s$", str_c(rx_phone, rx_phone2, sep = "|")))[1]
  # if not, replace with NA
  if (length(lob_phone) == 0) {
    lob_phone <- NA_character_
  }

  # lob zip ------------------------------------------------------------------------------------

  # the zip is on the line before email and phone
  # check for both, none, or either of these to find zip
  if (is.na(lob_email) & is.na(lob_phone)) {
    # missing email AND phone, zip last
    where_zip <- length(a)
  } else if (!is.na(lob_email) & !is.na(lob_phone)) {
    # missing neither, zip 3rd last
    where_zip <- length(a) - 2
  } else if (!is.na(lob_email) | !is.na(lob_phone)) {
    # if missing 1, zip 2nd last
    where_zip <- length(a) - 1
  }

  # after finding zip, collapse if overflow
  if (str_detect(a[where_zip], "^(\\d+|\\d+-\\d+)$")) {
    a[where_zip - 1] <- str_c(a[where_zip - 1], a[where_zip], collapse = "")
    a <- a[-where_zip]
    # update zip location
    where_zip <- where_zip - 1
  }
  lob_geo <- a[where_zip]

  # lob address --------------------------------------------------------------------------------

  # before the line with zip is street address
  where_addr <- where_zip - 1
  # if too many lines and previous starts with nums
  if (where_addr > 3 & str_detect(a[where_addr - 1], "^(\\d|PO)")) {
    # collapse overflow and replace
    a[where_addr - 1] <- str_c(a[where_addr - 1], a[where_addr], sep = " ")
    a <- a[-where_addr]
    # update addr location
    where_addr <- where_addr - 1
  }
  lob_addr <- a[where_addr]

  # frame lob parts ----------------------------------------------------------------------------

  lob <- tibble(
    lob_name,
    lob_type,
    lob_addr,
    lob_geo,
    lob_phone,
    lob_email
  )
  lob <- lob %>%
    separate(
      col = lob_name,
      into = c("lob_first", "lob_last"),
      sep = ",\\s",
      extra = "merge"
    ) %>%
    separate(
      col = lob_geo,
      into = c("lob_city", "lob_geo"),
      sep = ",\\s"
    ) %>%
    separate(
      col = lob_geo,
      into = c("lob_state", "lob_zip"),
      sep = "(\\s)|(?<=\\D)(?=\\d)",
      extra = "merge"
    ) %>%
    mutate_all(str_trim)
  return(lob)
}

frame_pri <- function(section) {

  # lines from pri right side
  z <- s$line[!s$lob]

  # pri phone ----------------------------------------------------------------------------------

  for (i in seq_along(z)) {
    # look for only nums or tel num
    rx_tel <- c(
      "\\(\\d{3}\\)\\s\\d{3}-\\d{4}", # whole tel
      "\\d+", # just nums
      "-\\d+",
      "\\d+-\\d+"
    )
    rx_tel <- sprintf("^(%s)$", str_c(rx_tel, collapse = "|"))
    if (str_detect(z[i], rx_tel)) {
      # combine with previous line
      z[i-1] <- str_c(z[i-1], z[i], sep = " ")
      # remove overflow
      z[i] <- NA_character_
    }
  }

  # omit removed lines
  z <- na.omit(z)

  # alternating to side by side
  pri <- tibble(
    pri_name = z[c(TRUE, FALSE)], # odd elements name
    pri_addr = z[c(FALSE, TRUE)] # even address
  )

  # split the pri addr
  pri <- pri %>%
    separate(
      col = pri_addr,
      into = c("pri_addr", "two"),
      sep = ",\\s"
    ) %>%
    separate(
      col = two,
      into = c("pri_state", "three"),
      sep = "\\s",
      extra = "merge"
    ) %>%
    separate(
      col = three,
      into = c("pri_zip", "pri_phone"),
      sep = "\\s(?=\\()"
    ) %>%
    mutate(
      pri_zip = normal_zip(pri_zip),
      pri_phone = normal_phone(pri_phone)
    )

  pri_city <- rep(NA_character_, nrow(pri))
  # look for city at end
  for (i in seq_along(pri$pri_addr)) {
    for (city in zipcodes$city[which(zipcodes$state == pri$pri_state[i])]) {
      check <- sprintf("(?<=\\s)(%s)(?=$)", str_to_title(city))
      if (str_detect(pri$pri_addr[i], check)) {
        pri_city[i] <- str_extract(pri$pri_addr[i], check)
        pri$pri_addr[i] <- str_trim(str_remove(pri$pri_addr[i], check))
        break()
      }
    }
  }
  pri <- pri %>%
    mutate(pri_city) %>%
    select(
      pri_name,
      pri_addr,
      pri_city,
      pri_state,
      pri_zip,
      pri_phone
    )

  return(pri)
}

# create function to call both per
frame_section <- function(section) {
  lob <- frame_lob(section)
  pri <- frame_pri(section)
  as_tibble(cbind(lob, pri))
}

nvlr <- map_df(sections, frame_section)

write_csv(
  x = nvlr,
  path = "2017_nv_lobbyists.csv",
  na = ""
)
