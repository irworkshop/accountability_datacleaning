# Kiernan Nicholls --------------------------------------
# Investigative Reporting Workshop ----------------------
# Fri Dec 13 12:01:30 2019 ------------------------------
library(tidyverse)
library(rvest)
library(httr)
library(glue)

# scrape id urls ----------------------------------------------------------

# list all the urls from the index page
base_url <- "http://www.cfboard.state.mn.us/lobby/"
lbatoz <- read_html(str_c(base_url, "lbatoz.html", sep = "/"))
index_url <- str_c(base_url, html_attr(html_nodes(lbatoz, "a"), "href"))

# for each letter scrape all name links
all_links <- character()
for (i in letters) {
  url <- glue("http://www.cfboard.state.mn.us/lobby/lbdetail/lbindex{i}.html")
  page <- read_html(url)
  nodes <- html_nodes(page, "a")
  names <- html_text(nodes)
  refs <- html_attr(nodes, "href")
  new_links <- str_c(dirname(url), refs, sep = "/")
  new_links <- str_subset(new_links, "/lb\\d+.html$")
  all_links <- append(all_links, new_links)
}
all_links <- unique(all_links)

# scrape lbdetail page ----------------------------------------------------

lb_list <- rep(list(NA), length(all_links))
for (i in seq_along(all_links)) {
  lb_detail <- read_html(all_links[i])
  lb_id <- str_extract(all_links[i], "lb\\d+(?=\\.\\w+$)")

  # get header text
  lb_header <- lb_detail %>%
    html_node("body") %>%
    html_text(trim = TRUE) %>%
    str_split("\r\n") %>%
    `[[`(1) %>%
    `[`(1:str_which(., "Registration Number"))

  # separate header
  lb_name <- html_text(html_node(lb_detail, "strong"))
  lb_email <- str_remove(str_subset(lb_header, "Email"), "Email:\\s")
  lb_tel <- str_remove(str_subset(lb_header, "Telephone"), "Telephone:\\s")
  lb_addr_index <- seq(
    from = str_which(lb_header, "Lobbyist") + 1,
    to = str_which(lb_header, "Telephone") - 1
  )
  lb_addr <- lb_header[lb_addr_index]
  if (length(lb_addr) > 2) {
    lb_comp <- lb_addr[1]
    lb_street <- lb_addr[2]
    lb_city <- lb_addr[3]
  } else {
    lb_comp <- NA_character_
    lb_street <- lb_addr[1]
    lb_city <- lb_addr[2]
  }

  # build 1 lob row
  lb_table <- tibble(
    lb_name,
    lb_id,
    lb_tel,
    lb_email,
    lb_comp,
    lb_street,
    lb_city
  )

  # separate lob address
  lb_table <- lb_table %>%
    separate(
      col = lb_city,
      into = c("lb_city", "zip_state"),
      sep = ",\\s(?=[:upper:]{2})",
      remove = TRUE
    ) %>%
    separate(
      col = zip_state,
      into = c("lb_zip", "lb_state"),
      sep = "\\s(?=\\d)"
    )

  # get represented clients from lbdetail
  rep_table <- lb_detail %>%
    html_node("table") %>%
    html_table(header = TRUE) %>%
    as_tibble() %>%
    na_if("") %>%
    na_if("&nbsp") %>%
    mutate_at(
      .vars = vars(DesignatedLobbyist),
      .funs = `==`, "Yes"
    ) %>%
    mutate_at(
      .vars = vars(ends_with("Date")),
      .funs = str_replace,
      "^Pre-1996$", "01/01/1970"
    ) %>%
    mutate_at(
      .vars = vars(ends_with("Date")),
      .funs = as.character
    ) %>%
    mutate_at(
      .vars = vars(ends_with("Date")),
      .funs = parse_date,
      "%m/%d/%Y"
    ) %>%
    set_names(nm = c(
      "a_name",
      "a_id",
      "reg_date",
      "term_date",
      "type",
      "designated"
    ))

  # get assoc info for each rep ---------------------------------------------

  a_list <- rep(list(NA), nrow(rep_table))
  for (k in seq_along(rep_table$a_id)) {
    # scrape page
    a_id <- rep_table$a_id[k]
    a_url <- glue("http://www.cfboard.state.mn.us/lobby/adetail/a{a_id}.html")
    a_detail <- read_html(a_url)

    # scrape header text
    a_header <- a_detail %>%
      html_node("body") %>%
      html_text(trim = TRUE) %>%
      str_split("\r\n") %>%
      `[[`(1) %>%
      `[`(1:str_which(., "Association Number"))

    # find which lines are address
    a_addr <- a_header[seq(
      from = str_which(a_header, "Association data") + 1,
      to = str_which(a_header, "Website") - 1
    )]

    # build a tibble row
    a_table <- tibble(
      a_id,
      a_name = html_text(html_node(a_detail, "strong")),
      a_website = str_remove(str_subset(a_header, "Website"), "Website:"),
      a_street = a_addr[length(a_addr) - 1],
      a_city = a_addr[length(a_addr)]
    )

    # separate the address lines
    a_table <- a_table %>%
      separate(
        col = a_city,
        into = c("a_city", "zip_state"),
        sep = ",\\s(?=[:upper:]{2})",
        remove = TRUE
      ) %>%
      separate(
        col = zip_state,
        into = c("a_zip", "a_state"),
        sep = "\\s(?=\\d)"
      )

    # save to list location
    a_list[[k]] <- a_table
  }

  # bind assoc back to rep --------------------------------------------------

  rep_table <- left_join(
    x = rep_table,
    y = bind_rows(a_list),
    by = c("a_name", "a_id")
  )

  # bind lb back to assoc
  lb_list[[i]] <- as_tibble(cbind(lb_table, rep_table))
  if (i %% 10 == 0) {
    cat(glue("{lb_id} completed: {i} = {scales::percent(i/length(all_links))}\n\n"))
  }
  # Sys.sleep(time = sample(x = 1:5, size = 1))
}

all_lb <- bind_rows(purrr::keep(lb_list, ~!all(is.na(.x))))
nrow(all_lb)
n_distinct(all_lb$lb_id)
write_csv(
  x = all_lb,
  path = "mn/lobby/data/processed/mn_lobbyists.csv",
  na = ""
)
