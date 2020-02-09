library(tidyverse)
library(rvest)
library(httr)

# GET something from server (take off & symbols, make a list), look to see if HTML
r <- GET(
  # we're writing GET(originURL, query)
  url = "http://opencheckbook.maine.gov/transparency/application.html",
  query = list(
    # query parameters
    advanced = 0,
    govLevel = "STATE",
    entityId = 2,
    transType = 3,
    fiscalYear = "2018",
    postingStart = "",
    postingEnd = "",
    lastModifiedStart = "",
    lastModifiedEnd = "",
    transDesc = "",
    transactionId = "",
    referenceId = "",
    contractDescription = "",
    contractNumber = "",
    dollarLowerLimit = "",
    dollarUpperLimit = "",
    positionTitle = "",
    hourlyRateLowerLimit = "",
    hourlyRateUpperLimit = ""
  )
)

# r = response
results_table <- content(r) %>%
  html_node(".results_table") %>%
  html_table() %>%
  as_tibble() %>%
  set_names(c("name", "dollar"))

# from the content (whole HTML page):
tr_nodes <- content(r) %>%
  # finding the table (node = one table)
  html_node(".results_table") %>%
  # from that table, we find all the nodes that are "tr" (makes a list)
  html_nodes("tr") %>%
  # turn each node (list element) into a char string
  as.character()


me_salary <- rep(list(NA), nrow(results_table))
for (i in seq(1, nrow(results_table))) {
  org_id <- tr_nodes[i] %>%
    str_extract("organization(.*)\\)") %>%
    str_extract("\\d+")
  agency <- results_table$name[i]
  # dollar <- results_table$dollar[i]
  loop_table <- tibble()
  for (k in 0:100) {
    p <- POST(
      url = "http://opencheckbook.maine.gov/transparency/functions/results_vendor.html",
      query = list(
        vendorName = "",
        linename = agency,
        node = 1,
        num = 11,
        from = 1,
        to = 10,
        context = "vendor",
        catid = "",
        fundid = "",
        orgid = org_id,
        vendorid = "",
        page = k
      )
    )
    page <- content(p)
    if (nchar(as.character(page)) < 10000) {
      break()
    } else {
      loop_table <- page %>%
        # finding the table (node = one table)
        html_node(".results_table") %>%
        # from that table, we find all the nodes that are "tr" (makes a list)
        html_table() %>%
        as_tibble() %>%
        # giving a vector to the name argument, not 2 separate arguments
        # c = concatenates multiple things into 1 vector
        set_names(nm = c("name", "salary")) %>%
        mutate(salary = parse_number(salary)) %>%
        separate(
          col = name,
          into = c("name", "title"),
          sep = "\\s\\(",
          extra = "merge"
        ) %>%
        mutate(title = str_remove(title, "\\)$")) %>%
        mutate(agency = agency) %>%
        select(agency, everything()) %>%
        bind_rows(loop_table)
    }
  }
  me_salary[[i]] <- loop_table
}

me_salary <- bind_rows(me_salary)
write_csv(
  x = me_salary,
  path = "Desktop/me_salaries_Scrape.csv"
)

mean(1:10)
sum(1:3)
