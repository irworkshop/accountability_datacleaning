# Clean TX contributions
# Accountability Project
# Kiernan Nicholls
# Fri Sep 3 2021

if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  tidyverse, # data manipulation
  campfin, # campaign finance
  janitor, # clean data frames
  campfin, # custom irw tools
  refinr, # cluster & merge
  scales, # number format
  here, # project paths
  cli, # command line
  fs # local storage
)

cli_h1("Clean Texas Contributions")

# identify the zip file with all records
raw_dir <- dir_create(here("tx", "contribs", "data", "raw"))
zip_url <- "https://www.ethics.state.tx.us/data/search/cf/TEC_CF_CSV.zip"
zip_path <- path(raw_dir, basename(zip_url))

# find contribution files
zip_con <- unzip(zip_path, list = TRUE)[[1]]
raw_csv <- path(raw_dir, str_subset(zip_con, "contribs_\\d{2}"))

# read the previously identified duplicate IDs
dupe_file <- here("tx", "contribs", "data", "dupes.txt")
tx_dupes <- tibble(
  contribution_info_id = as.integer(read_lines(dupe_file)),
  dupe_flag = TRUE
)

yes_no <- function(x) x == "Y"

# where cleaned files will be saved
tmp_dir <- dir_create(here("ny", "contribs", "data", "tmp"))

for (i in seq_along(raw_csv)) {
  cli_h2(basename(raw_csv[i]))
  cli_h3("reading file")
  txc <- read_delim(
    file = raw_csv[i],
    delim = ",",
    escape_backslash = FALSE,
    escape_double = FALSE,
    col_types = cols(
      .default = col_character(),
      reportInfoIdent = col_integer(),
      receivedDt = col_date("%Y%m%d"),
      contributionInfoId = col_integer(),
      contributionDt = col_date("%Y%m%d"),
      contributionAmount = col_double()
    )
  )
  txc <- clean_names(txc, case = "snake")
  txc <- mutate(txc, across(ends_with("_flag"), yes_no))
  n <- nrow(txc)
  cli_alert_success("Read {comma(n)} rows")
  # flag na ---------------------------------------------------------------
  cli_h3("Flag missing values")
  txc <- txc %>%
    mutate(
      contributor_name_any = coalesce(
        contributor_name_organization,
        contributor_name_last,
        contributor_name_first
      )
    ) %>%
    flag_na(
      contribution_dt,
      contributor_name_any,
      contribution_amount,
      filer_name
    ) %>%
    select(-contributor_name_any)
  cli_alert_success("Flagged {sum(txc$na_flag)} rows")
  # flag dupes ------------------------------------------------------------
  txc <- left_join(txc, tx_dupes, by = "contribution_info_id")
  txc <- mutate(txc, dupe_flag = !is.na(dupe_flag))
  sum(txc$dupe_flag)
  # dates -----------------------------------------------------------------
  cli_h3("Add 4 digit calendar year")
  txc <- mutate(txc, contribution_yr = year(contribution_dt))
  cli_alert_success("{n_distinct(txc$contribution_yr)} different years")
 # zip -------------------------------------------------------------------
  cli_h3("Normalize ZIP code")
  txc <- txc %>%
    mutate(
      zip_norm = normal_zip(
        zip = contributor_street_postal_code,
        na_rep = TRUE
      )
    )
  p_zip <- percent(prop_in(txc$zip_norm, valid_zip), 0.1)
  cli_alert_success("{p_zip} valid ZIP codes")
  # state -----------------------------------------------------------------
  cli_h3("Normalize state code")
  st_norm <- txc %>%
    distinct(contributor_street_state_cd) %>%
    mutate(
      state_norm = normal_state(
        state = contributor_street_state_cd,
        abbreviate = TRUE,
        na_rep = TRUE,
        valid = NULL
      )
    )
  txc <- left_join(txc, st_norm, by = "contributor_street_state_cd")
  rm(st_norm)
  Sys.sleep(3)
  flush_memory()
  p_st <- percent(prop_in(txc$state_norm, valid_state), 0.1)
  cli_alert_success("{p_st} valid ZIP codes")
  # city norm -------------------------------------------------------------
  cli_h3("Normalize city names")
  norm_city <- txc %>%
    distinct(contributor_street_city, state_norm, zip_norm) %>%
    mutate(
      city_norm = normal_city(
        city = contributor_street_city,
        abbs = usps_city,
        states = c("TX", "DC", "TEXAS"),
        na = invalid_city,
        na_rep = TRUE
      )
    )
  cli_h3("Swap city names")
  n_norm <- comma(sum(norm_city[[1]] != norm_city$city_norm, na.rm = TRUE))
  cli_alert_success("{n_norm} city names normalized")
  # city swap -------------------------------------------------------------
  norm_city <- norm_city %>%
    left_join(
      y = zipcodes,
      by = c(
        "state_norm" = "state",
        "zip_norm" = "zip"
      )
    ) %>%
    rename(city_match = city) %>%
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
    ) %>%
    distinct()
  txc <- left_join(txc, norm_city)
  n_swap <- comma(sum(norm_city$city_norm != norm_city$city_swap, na.rm = TRUE))
  cli_alert_success("{n_swap} city names swapped")
  rm(norm_city)
  Sys.sleep(5)
  flush_memory()
  # city refine -----------------------------------------------------------
  cli_h3("Refine city names")
  good_refine <- txc %>%
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
  txc <- txc %>%
    left_join(good_refine, by = names(.)) %>%
    mutate(city_refine = coalesce(city_refine, city_swap))

  # write -----------------------------------------------------------------
  cli_h3("Write cleaned version")
  tmp_path <- path(tmp_dir, basename(raw_csv[i]))
  write_csv(txc, tmp_path, na = "")
  tmp_size <- as.character(file_size(tmp_path))
  cli_alert_success("{tmp_size} file saved")
}
