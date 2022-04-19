library(tidyverse)
library(magrittr)
library(rvest)
library(httr)
library(glue)
library(fs)

# lobbyists pages ---------------------------------------------------------

# find all lobbyist page links
lb_links <- character()
for (l in letters) {
  url <- glue("http://www.cfboard.state.mn.us/lobby/lbdetail/lbindex{l}.html")
  page <- read_html(url)
  nodes <- html_nodes(page, "a")
  names <- html_text(nodes)
  refs <- html_attr(nodes, "href")
  new_links <- str_c(dirname(url), refs, sep = "/")
  new_links <- str_subset(new_links, "/lb\\d+.html$")
  lb_links <- unique(append(lb_links, new_links))
  Sys.sleep(time = sample(1:3, 1))
}

lb <- rep(x = list(NA), length.out = length(lb_links))
# scrape every page
for (i in seq_along(lb_links)) {
  # read the pahe html
  lb_detail <- read_html(lb_links[i])

  # scrape the header text
  lb_header <- lb_detail %>%
    html_node("body") %>%
    html_text(trim = TRUE) %>%
    str_split("\r\n") %>%
    `[[`(1) %>%
    `[`(1:str_which(., "Registration Number"))

  lb_tel <- str_remove(str_subset(lb_header, "Telephone"), "Telephone:\\s")
  if (length(lb_tel) == 0) lb_tel <- NA_character_
  lb_email <- str_remove(str_subset(lb_header, "Email"), "Email:\\s")
  if (length(lb_email) == 0) lb_email <- NA_character_

  lb_addr <- lb_header[seq(
    from = str_which(lb_header, "Lobbyist") + 1,
    to = min(str_which(lb_header, "Telephone|Email")) - 1
  )]

  lb_city <- lb_addr[length(lb_addr)]
  lb_street <- lb_addr[length(lb_addr) - 1]
  lb_company <- if (length(lb_addr) > 2) lb_addr[1] else NA_character_

  lb_table <-
    tibble(
      lb_id = str_extract(lb_links[i], "\\d+(?=\\.\\w+$)"),
      lb_name = html_text(html_node(lb_detail, "strong")),
      lb_tel,
      lb_email,
      lb_company,
      lb_street,
      lb_city
    ) %>%
    separate(
      col = lb_city,
      into = c("lb_city", "zip_state"),
      sep = ",\\s",
      remove = TRUE
    ) %>%
    separate(
      col = zip_state,
      into = c("lb_state", "lb_zip"),
      sep = "\\s(?=\\d)"
    )

  # scrape clients table from page
  lb_clients <- lb_detail %>%
    html_node("table") %>%
    html_table(header = TRUE) %>%
    as_tibble() %>%
    na_if("") %>% na_if("&nbsp") %>%
    mutate_at(
      .vars = vars(DesignatedLobbyist),
      .funs = `==`, "Yes"
    ) %>%
    mutate_at(
      .vars = vars(ends_with("Date")),
      .funs = str_replace, "Pre-1996", "1/1/1970"
    ) %>%
    mutate_at(
      .vars = vars(ends_with("Date")),
      .funs = parse_date,
      "%m/%d/%Y"
    ) %>%
    set_names(value = c(
      "a_name",
      "a_id",
      "start",
      "end",
      "type",
      "designated"
    ))

  # combine lob and clients
  # fill lob rows down for every client
  lb[[i]] <- as_tibble(cbind(lb_table, lb_clients))
  cat(glue("{i} of {length(lb_links)} ({scales::percent(i/length(lb_links))})"), sep = "\n")
  Sys.sleep(time = sample(1:3, 1))
}

# bind list of tibbles
lb <- bind_rows(lb)
lb$a_id <- as.character(lb$a_id)

# association pages -------------------------------------------------------

# repeat for associations
a_links <- character()
for (a in c(1:5, letters)) {
  url <- glue("http://www.cfboard.state.mn.us/lobby/adetail/aindex{a}.html")
  page <- read_html(url)
  nodes <- html_nodes(page, "a")
  names <- html_text(nodes)
  refs <- html_attr(nodes, "href")
  new_links <- str_c(dirname(url), refs, sep = "/")
  new_links <- str_subset(new_links, "/a\\d+.html$")
  a_links <- unique(append(a_links, new_links))
  Sys.sleep(time = sample(1:3, 1))
}

a <- rep(x = list(NA), length.out = length(a_links))
for (i in seq_along(a_links)) {
  a_detail <- read_html(a_links[i])
  a_header <- a_detail %>%
    html_node("body") %>%
    html_text(trim = TRUE) %>%
    str_split("\r\n") %>%
    `[[`(1) %>%
    `[`(1:str_which(., "Lobbyists Registered") - 1)
  a_website <- str_remove(str_subset(a_header, "Website"), "Website:")
  if (length(a_website) == 0) a_website <- NA_character_
  addr_to <- str_which(a_header, "[:upper:]{2}\\s\\d+")
  if (length(addr_to) == 0) {
    a_city <- NA_character_
    a_street <- NA_character_
    a_contact <- NA_character_
  } else {
    a_addr <- a_header[seq(
      from = min(str_which(a_header, "Association")) + 2,
      to = max(addr_to)
    )]
    a_city <- a_addr[length(a_addr)]
    a_street <- a_addr[length(a_addr) - 1]
    a_contact <- a_header[min(str_which(a_header, "Association")) + 1]
  }
  a_table <-
    tibble(
      a_id = str_extract(a_links[i], "\\d+(?=\\.\\w+$)"),
      a_name = html_text(html_node(a_detail, "strong")),
      a_website,
      a_contact,
      a_street,
      a_city
    ) %>%
    separate(
      col = a_city,
      into = c("a_city", "zip_state"),
      sep = ",\\s",
      remove = TRUE
    ) %>%
    separate(
      col = zip_state,
      into = c("a_state", "a_zip"),
      sep = "\\s(?=\\d)"
    )
  a[[i]] <- a_table
  cat(glue("{i} of {length(a_links)} ({scales::percent(i/length(a_links))})"), sep = "\n")
  Sys.sleep(time = sample(1:3, 1))
}

# bind list of tibbles
a <- bind_rows(a)

# combine tables ----------------------------------------------------------

mnlr <- left_join(lb, a, by = c("a_name", "a_id"))
head(mnlr)
tail(mnlr)
glimpse(sample_frac(mnlr))

dir_create("mn/lobby/data/raw")
write_csv(mnlr, path = "mn/lobby/data/raw/lob_scrape.csv", na = "")
