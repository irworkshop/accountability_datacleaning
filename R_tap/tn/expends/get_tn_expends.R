# TN Expenditures
# Kiernan Nicholls, Julia Ingram
# Investigative Reporting Workshop
# Wed Jan  5 11:12:08 2022

if (!require("pacman")) {
  install.packages("pacman")
}

pacman::p_load(
  tidyverse,
  lubridate,
  janitor,
  campfin,
  aws.s3,
  refinr,
  scales,
  rvest,
  here,
  httr,
  cli,
  fs
)

tn_dir <- dir_create(here("tn", "expends", "data", "raw"))
tn_csv <- dir_ls(tn_dir, glob = "*.csv")
tn_yrs <- as.numeric(unique(str_extract(tn_csv, "\\d{4}")))

for (y in 2000:2021) {
  if (y %in% tn_yrs) {
    message("Files for year already saved")
    next
  }
  cli_h2("Year: {y}")
  # request data ------------------------------------------------------------

  # visit home page for session ID cookies
  search_home <- GET("https://apps.tn.gov/tncamp-app/public/cesearch.htm")

  sesh_id <- cookies(search_home)
  sesh_id <- setNames(sesh_id$value, sesh_id$name)

  # submit POST request for all FROM for year Y
  search_post <- POST(
    url = "https://apps.tn.gov/tncamp-app/public/cesearch.htm",
    set_cookies(sesh_id),
    body = list(
      searchType = "expenditures",
      toType = "both", # to both candidates and committees
      toCandidate = TRUE, # from all types
      toPac = TRUE,
      toOther = TRUE,
      electionYearSelection = "",
      yearSelection = y, # for given year
      recipientName = "", # no name filters
      contributorName = "",
      employer = "",
      occupation = "",
      zipCode = "",
      candName = "",
      vendorName = "",
      vendorZipCode = "",
      purpose = "",
      typeOf = "all",
      amountSelection = "equal",
      amountDollars = "",
      amountCents = "",
      typeField = TRUE, # add all available fields
      adjustmentField = TRUE,
      amountField = TRUE,
      dateField = TRUE,
      electionYearField = TRUE,
      reportNameField = TRUE,
      candidatePACNameField = TRUE,
      vendorNameField = TRUE,
      vendorAddressField = TRUE,
      purposeField = TRUE,
      candidateForField = TRUE,
      soField = TRUE,
      `_continue` = "Continue",
      `_continue` = "Search"
    )
  )


  # read search results -----------------------------------------------------
  search_get <- GET(
    url = "https://apps.tn.gov/tncamp-app/public/ceresults.htm",
    set_cookies(sesh_id)
  )

  search_list <- content(search_get)

  # find csv export link at bottom of page
  csv_link <- search_list %>%
    html_element(".exportlinks > a") %>%
    html_attr("href")

  csv_link <- str_c("https://apps.tn.gov", csv_link)

  # set initial loop numbers
  more_loop <- 1
  n_all <- 0

  # find initial number of results
  n_row <- parse_number(html_text(html_element(search_list, ".pagebanner")))
  n_all <- n_all + n_row
  cli_h3("First results: {n_row} results")

  # define first file name
  csv_path <- path(tn_dir, sprintf("tn_expend_%i-%i.csv", y, more_loop))

  # download the first list of results as CSV
  csv_get <- GET(csv_link, write_disk(csv_path), progress("down"))

  # check for the "More" button
  has_more <- !is.na(html_element(search_list, ".btn-blue"))

  while (has_more) {
    Sys.sleep(runif(1, 1, 3))
    cli_alert_warning("More records available")
    more_loop <- more_loop + 1 # increment loop number
    more_get <- GET( # follow the more button link
      url = "https://apps.tn.gov/tncamp-app/public/ceresultsnext.htm",
      set_cookies(sesh_id)
    )
    more_list <- content(more_get)

    # find number of more results found
    n_row <- parse_number(html_text(html_element(more_list, ".pagebanner")))
    n_all <- n_all + n_row
    cli_h3("More results page {more_loop}: {n_row} results")

    # create new path and save CSV file
    csv_path <- path(tn_dir, sprintf("tn_expend_%i-%i.csv", y, more_loop))
    csv_get <- GET(csv_link, write_disk(csv_path), progress("down"))

    # check for more button
    has_more <- !is.na(html_element(more_list, ".btn-blue"))
  }
  # finish when button disappears
  cli_alert_success("No more results this year")

  Sys.sleep(runif(1, 10, 30))
}

tn_csv <- dir_ls(tn_dir, glob = "*.csv")

# read together -----------------------------------------------------------

tne <- map_df(
  .x = tn_csv,
  .f = function(x) {
    with_edition(
      edition = 1,
      code = read_delim(
        file = x,
        delim = ",",
        escape_backslash = FALSE,
        escape_double = FALSE,
        col_types = cols(
          .default = col_character(),
          `Amount` = col_number(),
          # 09/0/2008, 55/21/2013, 06/31/2020
          # `Date` = col_date("%m/%d/%Y"),
          `Election Year` = col_integer()
        )
      )
    )
  }
)

tne <- clean_names(tne, case = "snake")
n_distinct(na.omit(tne$type)) == 3

bad_dates <- which(is.na(mdy(tne$date)) & !is.na(tne$date))
munge_dt <- str_replace(
  string = tne$date[bad_dates],
  pattern = "(\\d+)/(\\d+)/(\\d+)",
  replacement = "\\3-\\1-\\2"
)

# fix dates with lubridate
# invalid dates with be removed
tne <- mutate(tne, across(date, mdy))

# split address -----------------------------------------------------------

x3 <- tne %>%
  distinct(vendor_address) %>%
  separate(
    col = vendor_address,
    into = c("addr_city", "state_zip"),
    sep = "\\s,\\s(?=[^,]*,[^,]*$)",
    remove = FALSE,
    extra = "merge",
    fill = "left"
  ) %>%
  separate(
    col = state_zip,
    into = c("state", "zip"),
    sep = ",\\s(?=\\d)",
    extra = "merge",
    fill = "left"
  )

good_split <- filter(x3, state %in% valid_abb)
bad_split <- filter(x3, state %out% valid_abb)

# fix split ---------------------------------------------------------------

# mising something in the middle, move and re-split
no_zip <- bad_split %>%
  filter(is.na(state) & is.na(addr_city) & str_detect(zip, "\\s\\w{2}$")) %>%
  select(-addr_city, -state) %>%
  separate(
    col = zip,
    into = c("addr_city", "state"),
    sep = "\\s?,\\s?(?=[^,]*$)",
    extra = "merge",
    fill = "right"
  )

# remove fixed from bad
bad_split <- bad_split %>%
  filter(vendor_address %out% no_zip$vendor_address)

# no zip, city-state moved to end, split-merge city into addr
no_zip <- bad_split %>%
  filter(!is.na(addr_city) & is.na(state) & str_detect(zip, "\\s\\w{2}$")) %>%
  separate(
    col = zip,
    into = c("city", "state"),
    sep = "\\s+,\\s"
  ) %>%
  unite(
    col = addr_city,
    ends_with("city"),
    sep = ", "
  ) %>%
  bind_rows(no_zip)

bad_split <- bad_split %>%
  filter(vendor_address %out% no_zip$vendor_address)

# no state, addr moved to state, move to addr and remove state
no_state <- bad_split %>%
  filter(is.na(addr_city) & !is.na(state) & str_detect(zip, "^\\d{5,}")) %>%
  select(-addr_city) %>%
  rename(addr_city = state)

bad_split <- bad_split %>%
  filter(vendor_address %out% no_state$vendor_address)

# combine everything and extract states
full_bad <- bad_split %>%
  filter(is.na(state) | nchar(state) != 2) %>%
  unite(
    -vendor_address,
    col = addr_city,
    sep = ", ",
    na.rm = TRUE
  ) %>%
  mutate(
    state = str_extract(addr_city, "^[A-Z]{2}$"),
    addr_city = na_if(str_remove(addr_city, "^[A-Z]{2}$"), "")
  )

bad_split <- bad_split %>%
  filter(vendor_address %out% full_bad$vendor_address)

# remaining just have bad states in general
bad_split %>%
  count(state, sort = TRUE)

# recombine fixes and fill with empty cols
bad_fix <- bind_rows(no_zip, no_state, full_bad, bad_split)
bad_fix <- mutate(bad_fix, across(.fns = str_squish))

sample_n(bad_fix, 20)

# recombine with good splits
tn_addr <- bind_rows(good_split, bad_fix)
tn_addr <- mutate(tn_addr, across(everything(), str_squish))

# wrangle address ---------------------------------------------------------

# trim zip codes
tn_addr <- tn_addr %>%
  mutate(across(zip, normal_zip)) %>%
  rename(zip_norm = zip)

# state already very good
prop_in(tn_addr$state, valid_state)
tn_addr <- rename(tn_addr, state_norm = state)

# split address on last comma
tn_addr <- separate(
  data = tn_addr,
  col = addr_city,
  into = c("addr_sep", "city_sep"),
  sep = ",\\s?(?=[^,]*$)",
  remove = TRUE,
  extra = "merge",
  fill = "left"
)

# normalize city
tn_city <- tn_addr %>%
  distinct(city_sep, state_norm, zip_norm) %>%
  mutate(
    city_norm = normal_city(
      city = city_sep,
      abbs = usps_city,
      states = c("TN", "DC"),
      na = invalid_city,
      na_rep = TRUE
    )
  )

tn_city <- tn_city %>%
  # match city against zip expect
  left_join(
    y = zipcodes,
    by = c(
      "state_norm" = "state",
      "zip_norm" = "zip"
    )
  ) %>%
  rename(city_match = city) %>%
  # swap with expect if similar
  mutate(
    match_abb = is_abbrev(city_norm, city_match),
    match_dist = str_dist(city_norm, city_match),
    city_swap = if_else(
      condition = !is.na(match_dist) & (match_abb | match_dist == 1),
      true = city_match,
      false = city_norm
    )
  ) %>%
  select(
    -city_match,
    -match_dist,
    -match_abb
  )

# rejoin to address
tn_addr <- left_join(tn_addr, tn_city)

good_refine <- tn_addr %>%
  mutate(
    city_refine = city_swap %>%
      key_collision_merge() %>%
      n_gram_merge(numgram = 1)
  ) %>%
  filter(city_refine != city_swap) %>%
  inner_join(
    y = zipcodes,
    by = c(
      "city_refine" = "city",
      "state_norm" = "state",
      "zip_norm" = "zip"
    )
  )

# add refined cities back
tn_addr <- tn_addr %>%
  left_join(good_refine, by = names(.)) %>%
  mutate(city_refine = coalesce(city_refine, city_swap))

# normalize address with usps standard
tn_addr <- tn_addr %>%
  mutate(
    .keep = "unused",
    .before = city_sep,
    addr_norm = normal_address(
      address = addr_sep,
      abbs = usps_street,
      na = invalid_city,
      na_rep = TRUE
    )
  )

tn_addr <- distinct(tn_addr)

# add back all split and cleaned addresses
tne <- left_join(
  x = tne,
  y = tn_addr,
  by = "vendor_address"
)

many_city <- c(valid_city, extra_city)
many_city <- c(many_city, "RESEARCH TRIANGLE PARK", "FARMINGTON HILLS")

progress_table(
  tne$city_sep,
  tne$city_norm,
  tne$city_swap,
  tne$city_refine,
  compare = many_city
)

# remove intermediary columns
tne <- tne %>%
  select(
    -city_sep,
    -city_norm,
    -city_swap
  ) %>%
  # consistent rename and reorder
  rename(city_norm = city_refine) %>%
  relocate(city_norm, .after = addr_norm) %>%
  rename_with(~str_replace(., "_norm", "_clean"))

# explore -----------------------------------------------------------------

glimpse(tne)

# flag NA values
col_stats(tne, count_na)
key_vars <- c("date", "candidate_pac_name", "amount", "vendor_name")
tne <- flag_na(tne, all_of(key_vars))
sum(tne$na_flag)
tne %>%
  filter(na_flag) %>%
  select(all_of(key_vars)) %>%
  sample_n(10)

# count distinct values
col_stats(tne, n_distinct)

# count/plot discrete
count(tne, type)
count(tne, adj)
explore_plot(tne, report_name) + scale_x_wrap()

# flag duplicate values
tne <- flag_dupes(tne, everything())
mean(tne$dupe_flag)
tne %>%
  filter(dupe_flag) %>%
  select(all_of(key_vars)) %>%
  arrange(candidate_pac_name)

# amounts -----------------------------------------------------------------

summary(tne$amount)
sum(tne$amount <= 0)

# min and max to and from same people?
glimpse(tne[c(which.max(tne$amount), which.min(tne$amount)), ])

tne %>%
  filter(amount >= 1) %>%
  ggplot(aes(amount)) +
  geom_histogram(fill = dark2["purple"], bins = 30) +
  scale_y_continuous(labels = scales::comma) +
  scale_x_continuous(
    breaks = c(1 %o% 10^(0:6)),
    labels = scales::dollar,
    trans = "log10"
  ) +
  labs(
    title = "Tennessee Expenditures Amount Distribution",
    caption = "Source: TN Online Campaign Finance",
    x = "Amount",
    y = "Count"
  )

# dates -------------------------------------------------------------------

tne <- mutate(tne, year = year(date))

min(tne$date, na.rm = TRUE)
sum(tne$year < 2000, na.rm = TRUE)
max(tne$date, na.rm = TRUE)
sum(tne$date > today(), na.rm = TRUE)

tne %>%
  filter(between(year, 2004, 2021)) %>%
  count(year) %>%
  mutate(even = is_even(year)) %>%
  ggplot(aes(x = year, y = n)) +
  geom_col(aes(fill = even)) +
  scale_fill_brewer(palette = "Dark2") +
  scale_y_continuous(labels = scales::comma) +
  scale_x_continuous(breaks = seq(2004, 2021, by = 2)) +
  theme(legend.position = "bottom") +
  labs(
    title = "Tennessee Expenditures by Year",
    caption = "Source: TN Online Campaign Finance",
    fill = "Election Year",
    x = "Year Made",
    y = "Count"
  )

# -------------------------------------------------------------------------

tne$date <- as.character(tne$date)
tne$date[bad_dates] <- munge_dt

# export ------------------------------------------------------------------

clean_dir <- dir_create(here("tn", "expends", "data", "clean"))
clean_path <- path(clean_dir, "tn_expends_2004-20211231.csv")
write_csv(tne, clean_path, na = "")
(clean_size <- file_size(clean_path))

# upload ------------------------------------------------------------------

aws_path <- path("csv", basename(clean_path))
if (!object_exists(aws_path, "publicaccountability")) {
  put_object(
    file = clean_path,
    object = aws_path,
    bucket = "publicaccountability",
    acl = "public-read",
    show_progress = TRUE,
    multipart = TRUE
  )
}
aws_head <- head_object(aws_path, "publicaccountability")
(aws_size <- as_fs_bytes(attr(aws_head, "content-length")))
unname(aws_size == clean_size)
