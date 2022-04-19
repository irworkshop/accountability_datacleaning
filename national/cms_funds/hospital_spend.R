# Wed Mar 24 09:37:02 2021 ------------------------------------------------

library(tidyverse)
library(campfin)
library(here)
library(fs)

# extract text files ------------------------------------------------------

name_file <- here("us", "spending", "bulk_names.csv")
if (!file_exists(name_file)) {
  stop("Bulk files not requested from API, see `spend_history.R`")
} else {
  bulk_names <- read_csv(
    file = name_file,
    col_types = cols(
      year = col_double(),
      name = col_character()
    )
  )
}

zip_dir <- here("us", "spending", "data")
csv_dir <- dir_create(path(zip_dir, "csv"))
fy_zip <- path(zip_dir, bulk_names$name[bulk_names$year >= 2020])
all(file_exists(fy_zip))

fy_csv <- dir_ls(csv_dir, glob = "*.csv")
if (FALSE && length(fy_csv) < 40) {
  fy_csv <- rep(list(NA), length(fy_zip))
  for (i in seq_along(fy_zip)) {
    fy_csv[[i]] <- unzip(
      zipfile = fy_zip[i],
      exdir = csv_dir,
      overwrite = FALSE
    )
  }
  fy_csv <- unlist(fy_csv)
}

us_cols <- read_csv(
  file = here("us", "spending", "spend_cols.csv"),
  col_types = cols(
    is_con = col_logical(),
    is_sub = col_logical(),
    column = col_character(),
    type = col_character()
  )
)

# save prime contracts ----------------------------------------------------

con_csv <- str_subset(fy_csv, "All_Contracts_PrimeTransactions")
con_spec <- paste(us_cols$type[us_cols$is_con & !us_cols$is_sub], collapse = "")
con_file <- here("us", "hospital_covid", "hospital_covid_contracts.csv")
for (i in seq_along(con_csv)) {
  message(sprintf("Contract %i/%i", i, length(con_csv)))
  con <- read_delim(
    file = con_csv[i],
    delim = ",",
    escape_double = TRUE,
    na = "",
    col_types = con_spec,
    guess_max = 0,
    progress = TRUE
  )

  # keep only covid spending
  if (all(is.na(con$disaster_emergency_fund_codes_for_overall_award))) {
    rm(con)
    message("No COVID disaster spending")
    Sys.sleep(5)
    flush_memory()
    next
  } else {
    con <- filter(con, !is.na(disaster_emergency_fund_codes_for_overall_award))
    flush_memory()
  }

  # filter for hospital NAICS code
  con <- filter(con, naics_code == 622110)
  if (nrow(con) == 0) {
    message("No hospital spending")
    rm(con)
    flush_memory()
    next
  }

  con <- con %>%
    mutate(
      covid_code = str_extract_all(
        string = disaster_emergency_fund_codes_for_overall_award,
        pattern = "[:upper:]{1}(?=\\:)"
      )
    ) %>%
    rowwise() %>%
    mutate(n_code = length(covid_code))

  con2 <- con %>%
    mutate(
      non_profit = nonprofit_organization | other_not_for_profit_organization
    ) %>%
    select(
      award_id = award_id_piid,
      agency_name = awarding_agency_name,
      sub_agency = awarding_sub_agency_name,
      action_date,
      mod_date = last_modified_date,
      mod_number = modification_number,
      fed_obligate = federal_action_obligation,
      covid_outlay = `outlayed_amount_funded_by_COVID-19_supplementals_for_overall_aw`,
      covid_obligate = `obligated_amount_funded_by_COVID-19_supplementals_for_overall_a`,
      covid_code,
      n_code,
      recipient = recipient_name,
      city = recipient_city_name,
      state = recipient_state_code,
      place_zip = primary_place_of_performance_zip_4,
      non_profit,
      hospital_flag,
      naics_description,
      award_type,
      award_desc = award_description,
      permalink = usaspending_permalink
    ) %>%
    mutate(file = basename(con_csv[i]))

  con2$covid_code <- map_chr(con2$covid_code, paste, collapse = "|")

  write_csv(
    x = con2,
    file = con_file,
    append = file_exists(con_file)
  )

  message(sprintf("Saved: %i", nrow(con2)))
  rm(con2, con)
  Sys.sleep(5)
  flush_memory()
}

# save prime assistance ---------------------------------------------------

ast_csv <- str_subset(fy_csv, "All_Assistance_PrimeTransactions")
ast_spec <- paste(us_cols$type[!us_cols$is_con & !us_cols$is_sub], collapse = "")
ast_file <- here("us", "hospital_covid", "hospital_covid_assist.csv")
for (i in seq_along(ast_csv)) {
  message(sprintf("Assistance %i/%i", i, length(ast_csv)))

  ast <- read_delim(
    file = ast_csv[i],
    delim = ",",
    escape_double = TRUE,
    na = "",
    col_types = ast_spec,
    guess_max = 0,
    progress = TRUE
  )

  # keep only covid spending
  if (all(is.na(ast$disaster_emergency_fund_codes_for_overall_award))) {
    rm(ast)
    message("No COVID disaster spending")
    Sys.sleep(5)
    flush_memory()
    next
  } else {
    ast <- filter(ast, !is.na(disaster_emergency_fund_codes_for_overall_award))
    flush_memory()
  }

  # filter for hospital key words
  ast <- ast %>%
    filter(
      str_detect(recipient_name, "(HOSPITAL\\b)|(MEDICAL CENTER)"),
      str_detect(recipient_name, "VETERINARY|ANIMAL", negate = TRUE)
    )
  if (nrow(ast) == 0) {
    message("No hospital spending")
    rm(ast)
    flush_memory()
    next
  }

  ast <- ast %>%
    mutate(
      covid_code = str_extract_all(
        string = disaster_emergency_fund_codes_for_overall_award,
        pattern = "[:upper:]{1}(?=\\:)"
      )
    ) %>%
    rowwise() %>%
    mutate(n_code = length(covid_code))

  ast2 <- ast %>%
    select(
      award_id = award_id_fain,
      agency_name = awarding_agency_name,
      sub_agency = awarding_sub_agency_name,
      action_date,
      mod_date = last_modified_date,
      mod_number = modification_number,
      fed_obligate = federal_action_obligation,
      loan_value = face_value_of_loan,
      covid_outlay = `outlayed_amount_funded_by_COVID-19_supplementals_for_overall_aw`,
      covid_obligate = `obligated_amount_funded_by_COVID-19_supplementals_for_overall_a`,
      covid_code,
      n_code,
      recipient = recipient_name,
      city = recipient_city_name,
      state = recipient_state_code,
      place_zip = primary_place_of_performance_zip_4,
      biz_code = business_types_code,
      biz_desc = business_types_description,
      assist_type = assistance_type_description,
      award_desc = award_description,
      cfda_number,
      cfda_title,
      permalink = usaspending_permalink
    ) %>%
    mutate(file = basename(ast_csv[i]))

  ast2$covid_code <- map_chr(ast2$covid_code, paste, collapse = "|")

  write_csv(
    x = ast2,
    file = ast_file,
    append = file_exists(ast_file)
  )

  message(sprintf("Saved: %i", nrow(ast2)))
  rm(ast2, ast)
  Sys.sleep(5)
  flush_memory()
}

# analyze contracts -------------------------------------------------------

con <- read_csv(
  file = con_file,
  col_types = cols(
    .default = col_character(),
    action_date = col_date(format = ""),
    mod_date = col_datetime(format = ""),
    fed_obligate = col_double(),
    covid_outlay = col_double(),
    covid_obligate = col_double(),
    n_code = col_double(),
    non_profit = col_logical(),
    hospital_flag = col_logical()
  )
)

con %>%
  count(award_type, sort = TRUE)

# most common recipients
con %>%
  count(recipient, non_profit, hospital_flag, sort = TRUE)

# % hospital / nonprofit
mean(con$hospital_flag)
mean(con$non_profit)

# % conditional on each other
mean(con$hospital_flag[con$non_profit])
mean(con$non_profit[con$hospital_flag])

# most common hospitals
con %>%
  filter(hospital_flag) %>%
  count(recipient, sort = TRUE)

# count of hospital covid contracts by agency
# 96% by DOJ and DOD
con %>%
  count(agency_name, sub_agency, sort = TRUE) %>%
  add_prop() %>%
  mutate(p2 = cumsum(p))

# total awarded by agency
con %>%
  group_by(sub_agency, recipient) %>%
  summarise(
    n = n(),
    total = sum(fed_obligate)
  ) %>%
  arrange(desc(n))

# total awarded to hospitals
con %>%
  filter(hospital_flag) %>%
  group_by(sub_agency, recipient) %>%
  summarise(
    n = n(),
    total = sum(fed_obligate)
  ) %>%
  arrange(desc(n))

# total awarded to non-profits
con %>%
  filter(non_profit) %>%
  group_by(sub_agency, recipient) %>%
  summarise(
    n = n(),
    total = sum(fed_obligate)
  ) %>%
  arrange(desc(n))

con %>%
  count(covid_code, sort = TRUE)

# split into list column
# con$covid_code <- str_split(con$covid_code, "\\|")

# count of covid codes by agency
con %>%
  select(sub_agency, covid_code, fed_obligate) %>%
  group_by(sub_agency, covid_code) %>%
  summarise(n = n()) %>%
  arrange(desc(n)) %>%
  pivot_wider(
    values_from = n,
    names_from = covid_code
  )

# total dollars obligated by agency
con %>%
  select(sub_agency, covid_code, fed_obligate) %>%
  group_by(sub_agency, covid_code) %>%
  summarise(total = sum(fed_obligate)) %>%
  arrange(desc(total)) %>%
  pivot_wider(
    values_from = total,
    names_from = covid_code
  )

con %>%
  group_by(agency_name, sub_agency, recipient, non_profit,
           hospital = hospital_flag) %>%
  summarise(
    n_row = n(),
    n_award = n_distinct(award_id),
    sum_row = sum(fed_obligate, na.rm = TRUE)
  ) %>%
  arrange(desc(n_row)) %>%
  write_csv(
    file = here("us", "hospital_covid", "hospital_covid_contracts_total.csv")
  )

# analyze assistance ------------------------------------------------------

ast <- read_csv(
  file = ast_file,
  col_types = cols(
    .default = col_character(),
    action_date = col_date(format = ""),
    mod_date = col_datetime(format = ""),
    fed_obligate = col_double(),
    loan_value = col_double(),
    covid_outlay = col_double(),
    covid_obligate = col_double(),
    n_code = col_double()
  )
)

ast %>%
  count(assist_type, sort = TRUE) %>%
  add_prop()

ast <- ast %>%
  mutate(assist_code = str_extract(assist_type, "(?<=\\()[:upper:](?=\\))"))

ast %>%
  group_by(assist_type) %>%
  summarise(total = sum(any_amount))

ast %>%
  count(biz_code, biz_desc, sort = TRUE)

# most common recipients
ast %>%
  count(recipient, biz_code, sort = TRUE)

# count of hospital covid contracts by agency
# 96% by DOJ and DOD
ast %>%
  count(agency_name, sub_agency, sort = TRUE) %>%
  add_prop() %>%
  mutate(p2 = cumsum(p))

# total awarded by agency and type
ast %>%
  group_by(sub_agency, assist_code, recipient) %>%
  summarise(
    n = n(),
    total = sum(any_amount)
  ) %>%
  arrange(desc(n))

ast %>%
  count(covid_code, sort = TRUE)

# split into list column
# con$covid_code <- str_split(con$covid_code, "\\|")

# count of covid codes by agency
ast %>%
  select(sub_agency, covid_code, any_amount) %>%
  group_by(sub_agency, covid_code) %>%
  summarise(n = n()) %>%
  arrange(desc(n)) %>%
  pivot_wider(
    values_from = n,
    names_from = covid_code
  )

# total dollars obligated by agency
ast %>%
  select(sub_agency, covid_code, any_amount) %>%
  group_by(sub_agency, covid_code) %>%
  summarise(total = sum(any_amount)) %>%
  arrange(desc(total)) %>%
  pivot_wider(
    values_from = total,
    names_from = covid_code
  )


ast %>%
  mutate(
    fed_obligate = na_if(fed_obligate, 0),
    any_amount = coalesce(fed_obligate, loan_value)
  ) %>%
  group_by(agency_name, sub_agency, recipient, assist_type, biz_code) %>%
  summarise(
    n_row = n(),
    n_award = n_distinct(award_id),
    sum_row = sum(any_amount, na.rm = TRUE),
  ) %>%
  arrange(desc(n_row)) %>%
  write_csv(
    file = here("us", "hospital_covid", "hospital_covid_assist_total.csv")
  )
