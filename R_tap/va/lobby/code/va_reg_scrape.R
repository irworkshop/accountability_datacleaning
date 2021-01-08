library(tidyverse)
library(scales)
library(rvest)
library(httr)

# initialize list
lob_ids <- seq(60000, 65000)
lob_list <- rep(list(NA), length(lob_ids))
# base url
url <- "http://ethicssearch.dls.virginia.gov/ViewFormBinary.aspx"
for (id in lob_ids) {
  # request the site content
  response <- POST(url, query = list(filingid = id, type = "LD"))
  # skip if the response is small
  if (length(response$content) < 1000) next()
  # read the page content
  page <- content(response, encoding = "UTF-8")
  # identify the span ids and names
  span_ids <- html_attr(html_nodes(page, "span"), "id")
  span_text <- html_text(html_nodes(page, "span"))
  # remove empty spans
  span_text <- span_text[which(!is.na(span_ids))]
  span_ids <- span_ids[which(!is.na(span_ids))]
  # convert to list
  names(span_text) <- span_ids
  lob_list[[which(id == lob_ids)]] <- as.list(span_text)
  # check the progress
  prog <- percent((id - 60000)/(65000 - 60000))
  message(id, " - done: ", prog)
  # wait some period of time
  Sys.sleep(time = rnorm(1, mean = 2))
}

# save list object
save(lob_list, file = "va_reg_list.RData")

# collpase the many lists
lob_df <- map_dfr(lob_list, as_tibble)

# write to disk
write_csv(
  x = lob_df,
  path = "va_reg_tab.csv",
  na = ""
)
