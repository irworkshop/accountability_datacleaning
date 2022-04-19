# load necessary packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load_gh("irworkshop/campfin")
pacman::p_load(
  tidyverse, # data manipulation
  pdftools, # pdf file info
  janitor, # clean data frames
  pbapply, # timer progress bar
  rvest, # html scraping
  glue, # combine strings
  here, # relative paths
  httr, # http requests
  fs # local storage
)

# save data to text file lookup table by ID
detail_file <- here("sd", "contracts", "data", "vendor_details.csv")
if (file_exists(detail_file)) {
  done_ids <- read_csv(detail_file)$id
} else {
  write_lines(paste(names(sdd), collapse = ","), detail_file)
  done_ids <- ""
}

# read list of unique contract IDs
id_file <- here("sd", "contracts", "data", "contract_ids.txt")
sd_ids <- read_lines(id_file)
sd_ids <- sd_ids[which(sd_ids %out% done_ids)]

sdd <- list( # initialize empty text file
  id = NA_character_, # lookup by ID
  created = as.Date(NA), modified = as.Date(NA), # dates from PDF
  city = NA_character_, state = NA_character_, # geo from HTML
  solicit = NA_character_, type = NA_character_
)

pb <- timerProgressBar(max = length(sd_ids), style = 5, char = "[=-]")
for (i in seq_along(sd_ids)) { # check page for every ID
  a <- GET( # make HTTP request using unique ID
    url = "https://open.sd.gov/contractsDocShow.aspx",
    query = list(DocID = sdd$id <- sd_ids[i])
  )
  b <- content(a)
  c <- html_node(b, "#contractsdetail")
  if (status_code(a) != 200 | is.na(c)) {
    next() # skip if bad page or no table
  } else { # otherwise save parts to details
    # download PDF for document date ----------------------------------------
    pdf_url <- c %>%
      html_nodes("a") %>%
      html_attr("href") %>%
      str_subset("pdf$") %>%
      str_extract("(?<=Document\\=)(.*)")
    pdf_url <- pdf_url[1]
    if (length(pdf_url) != 0 & isFALSE(is.na(pdf_url))) {
      pdf_get <- GET(pdf_url) # store pdf binary in memory
      if (pdf_get$headers[["content-type"]] == "application/pdf") {
        pdf_dates <- pdf_info(content(pdf_get)) # read doc metadata
        sdd$created <- pdf_dates$created  # save doc dates
        sdd$modified <- pdf_dates$modified
      }
    }
    # read html table for details -------------------------------------------
    d <- distinct(html_table(c))
    e <- d[[2]]
    names(e) <- make_clean_names(str_extract(d[[1]], "(.*)(?=:)"))
    sdd$city <- unname(e["city"])[1]
    sdd$state <- unname(e["state"])[1]
    sdd$solicit <- unname(e["solicitation_type"])[1]
    sdd$type <- str_to_lower(str_remove_all(d[1, 1], "\\W"))
  }
  # write data to new line in text file
  write_csv(as_tibble(sdd), detail_file, append = TRUE)
  setTimerProgressBar(pb, value = i)
}
