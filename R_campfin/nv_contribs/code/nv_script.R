## ----p_load, message=FALSE, warning=FALSE, error=FALSE-------------------
# install.packages("pacman")
pacman::p_load(
  tidyverse, # data manipulation
  magrittr, # pipe opperators
  janitor, # data cleaning
  refinr, # cluster and merge
  vroom, # read files fast
  rvest, # scrape web pages
  knitr, # knit documents
  here, # navigate local storage
  fs # search local storage 
)


## ----read_html, echo=FALSE, warning=FALSE--------------------------------
here("nv_contribs", "data") %>% 
  dir_ls(glob = "*.html") %>% 
  read_html() %>% 
  html_nodes("table") %>% 
  html_table(fill = TRUE) %>% 
  map(as_tibble) %>% 
  extract(seq(3, 18, by = 3)) %>% 
  map(slice, -1) %>% 
  map(set_names, c("col", "col_type", "position")) %>%
  map(separate, 
      col, 
      sep = "\\s\\(",
      into = c("col", "key"),
      extra = "drop"
  ) %>% 
  map(mutate, key = str_remove(key, "\\)")) %>%
  map(select, -position) %>% 
  set_names(c(
    "candidates", 
    "groups",
    "reports",
    "payees",
    "contributions",
    "expenses"
  ))


## ----unzip_list, echo=FALSE----------------------------------------------
here("nv_contribs", "data") %>% 
  dir_ls(, glob = "*.zip") %>% 
  unzip(list = TRUE) %>% 
  clean_names()


## ----unzip---------------------------------------------------------------
dir_create(here("nv_contribs", "data"))
here("nv_contribs", "data") %>% 
  dir_ls(glob = "*.zip") %>% 
  unzip(exdir = here("nv_contribs", "data"))


## ----read_candidates-----------------------------------------------------
nv_candidates <- vroom(
  file = here("nv_contribs", "data", "CampaignFinance.Cnddt.43898.060419073713.csv"),
  delim = ",",
  col_names = TRUE,
  na = "",
  quote = "\"",
  escape_double = TRUE,
  .name_repair = make_clean_names,
  col_types = cols(
    `CandidateID` = col_character(),
    `First Name` = col_character(),
    `Last Name` = col_character(),
    `Party` = col_character(),
    `Office` = col_character(),            
    `Jurisdiction` = col_character()
  )
)

print(nv_candidates)


## ----read_groups---------------------------------------------------------
nv_groups <- vroom(
  file = here("nv_contribs", "data", "CampaignFinance.Grp.43898.060419073713.csv"),
  delim = ",",
  col_names = TRUE,
  na = "",
  quote = "\"",
  escape_double = TRUE,
  .name_repair = make_clean_names,
  col_types = cols(
    `GroupID` = col_character(),
    `Group Name` = col_character(),
    `Group Type` = col_character(),
    `Contact Name` = col_character(),            
    `Active` = col_logical(),
    `City` = col_character()
  )
)

print(nv_groups)


## ----read_reports--------------------------------------------------------
nv_reports <- vroom(
  file = here("nv_contribs", "data", "CampaignFinance.Rpr.43898.060419073713.csv"),
  delim = ",",
  col_names = TRUE,
  na = "",
  quote = "\"",
  escape_double = TRUE,
  .name_repair = make_clean_names,
  col_types = cols(
    `ReportID` = col_character(),
    `CandidateID` = col_character(),
    `GroupID` = col_character(),
    `Report Name` = col_character(),
    `Election Cycle` = col_number(),
    `Filing Due Date` = col_date("%m/%d/%Y"),
    `Filed Date` = col_date("%m/%d/%Y"),
    `Amended` = col_logical(),
    `Superseded` = col_logical()
  )
)

print(nv_reports)


## ----read_payees---------------------------------------------------------
nv_payees <- vroom(
  file = here("nv_contribs", "data", "CampaignFinance.Cntrbtrs-.43898.060419073713.csv"),
  delim = ",",
  col_names = TRUE,
  na = "",
  quote = "\"",
  escape_double = TRUE,
  .name_repair = make_clean_names,
  col_types = cols(
    `ContactID` = col_character(),
    `First Name` = col_character(),
    `Middle Name` = col_character(),
    `Last Name` = col_character()
  )
)

print(nv_payees)


## ----read_contribs-------------------------------------------------------
nv_contributions <- vroom(
  file = here("nv_contribs", "data", "CampaignFinance.Cntrbt.43898.060419073713.csv"),
  delim = ",",
  col_names = TRUE,
  na = "",
  quote = "\"",
  escape_double = TRUE,
  .name_repair = make_clean_names,
  col_types = cols(
    `ContributionID` = col_character(),
    `ReportID` = col_character(),
    `CandidateID` = col_character(),
    `GroupID` = col_character(),
    `Contribution Date` = col_date("%m/%d/%Y"),
    `Contribution Amount`	= col_number(),
    `Contribution Type` = col_character(),
    `ContributorID` = col_character()
  )
)

print(nv_contributions)


## ----read_expenses, eval=FALSE-------------------------------------------
#> nv_expenses <- vroom(
#>   file = here("nv_contribs", "data", "CampaignFinance.Cntrbt.43898.060419073713.csv"),
#>   delim = ",",
#>   col_names = TRUE,
#>   na = "",
#>   quote = "\"",
#>   escape_double = TRUE,
#>   .name_repair = make_clean_names,
#>   col_types = cols(
#>     `ExpenseID` = col_character(),
#>     `ReportID` = col_character(),
#>     `CandidateID` = col_character(),
#>     `GroupID` = col_character(),
#>     `Expense Date` = col_date("%m/%d/%Y"),
#>     `Expense Amount`	= col_number(),
#>     `Expense Type` = col_character(),
#>     `Payee ID` = col_character()
#>   )
#> )


## ----join, collapse=TRUE-------------------------------------------------
nv <- nv_contributions %>%
  # join with relational tables
  left_join(nv_reports, by = c("report_id", "candidate_id", "group_id")) %>%
  left_join(nv_candidates, by = "candidate_id") %>% 
  left_join(nv_groups, by = "group_id") %>%
  left_join(nv_payees, by = c("contributor_id" = "contact_id")) %>% 
  # add origin table info to ambiguous variables
  rename(
    candidate_first = first_name.x,
    candidate_last = last_name.x,
    candidate_party = party,
    seeking_office = office,
    report_amended = amended, 
    report_superseded = superseded,
    group_contact = contact_name,
    group_active = active,
    group_city = city,
    payee_first = first_name.y,
    payee_middle = middle_name,
    payee_last = last_name.y
  )

# all rows preserved
nrow(nv) == nrow(nv_contributions)

# all cols includes
length(nv_contributions) %>% 
  add(length(nv_reports)) %>% 
  add(length(nv_candidates)) %>% 
  add(length(nv_groups)) %>% 
  add(length(nv_payees)) %>% 
  subtract(6) %>% # shared key cols
  equals(length(nv))


## ----no_geo--------------------------------------------------------------
nv %>% 
  filter(report_id == "6991") %>% 
  select(
    report_id, 
    filed_date, 
    payee_last, 
    candidate_last
  )


## ----glimpse_all---------------------------------------------------------
glimpse(sample_frac(nv))


## ----count_distinct------------------------------------------------------
nv %>% 
  map(n_distinct) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_distinct") %>% 
  mutate(prop_distinct = round(n_distinct / nrow(nv), 4)) %>%
  print(n = length(nv))


## ----distinct_id, collapse=TRUE------------------------------------------
n_distinct(nv_payees$contact_id)/nrow(nv_payees)
n_distinct(nv_groups$group_id)/nrow(nv_groups)


## ----tabyls_function, echo=FALSE-----------------------------------------
print_tabyl <- function(data, ...) {
  as_tibble(arrange(tabyl(data, ...), desc(n)))
}


## ----tabyls--------------------------------------------------------------
print_tabyl(nv, contribution_type)
print_tabyl(nv, candidate_party)
print_tabyl(nv, seeking_office)
print_tabyl(nv, jurisdiction)
print_tabyl(nv, election_cycle)
print_tabyl(nv, report_amended)
print_tabyl(nv, report_superseded)
print_tabyl(nv, group_type)
print_tabyl(nv, group_active)
print_tabyl(nv, group_city)


## ----ranges--------------------------------------------------------------
summary(nv$contribution_date)
summary(nv$contribution_amount)
summary(nv$filing_due_date)
summary(nv$filed_date)


## ----max_amt-------------------------------------------------------------
nv %>% 
  filter(contribution_amount == max(contribution_amount)) %>% 
  glimpse()


## ----plot_amt_type, echo=FALSE-------------------------------------------
nv %>%
  ggplot(aes(contribution_amount)) +
  geom_histogram(aes(fill = contribution_type), bins = 30) +
  scale_x_continuous(labels = scales::dollar, trans = "log10") +
  scale_y_log10() +
  theme(legend.position = "none") +
  facet_wrap(~contribution_type) +
  labs(
    title = "Contribution Distribution",
    subtitle = "by Contribution Type",
    caption = "Source: NVSOS",
    y = "Number of Contributions",
    x = "Amount (USD)"
  )


## ----plot_amt_party, echo=FALSE------------------------------------------
top_party <- c("Democratic Party", "Independent", "Nonpartisan", "Republican Party", "Unspecified")
nv %>%
  mutate(candidate_party = ifelse(candidate_party %in% top_party, candidate_party, "Other")) %>% 
  ggplot(aes(contribution_amount)) +
  geom_histogram(aes(fill = candidate_party), bins = 30) +
  scale_x_continuous(labels = scales::dollar, trans = "log10") +
  scale_y_log10() +
  scale_fill_manual(values = c("blue", "forestgreen", "purple", "black", "red", "#999999")) +
  theme(legend.position = "none") +
  facet_wrap(~candidate_party) +
  labs(
    title = "Contribution Distribution",
    subtitle = "by Political Party",
    caption = "Source: NVSOS",
    y = "Number of Contributions",
    x = "Amount (USD)"
  )


## ----plot_amt_group, echo=FALSE------------------------------------------
nv %>%
  filter(!is.na(group_type)) %>% 
  ggplot(aes(contribution_amount)) +
  geom_histogram(aes(fill = group_type), bins = 30) +
  scale_x_continuous(labels = scales::dollar, trans = "log10") +
  scale_y_log10() +
  theme(legend.position = "none") +
  facet_wrap(~group_type) +
  labs(
    title = "Contribution Distribution",
    subtitle = "to groups, by type",
    caption = "Source: NVSOS",
    y = "Number of Contributions",
    x = "Amount (USD)"
  )


## ----mutually_exclusive, collapse=TRUE-----------------------------------
# prop NA each sum to 1
mean(is.na(nv$candidate_id)) + mean(is.na(nv$group_id))
mean(is.na(nv$candidate_last)) + mean(is.na(nv$group_name))


## ----count_na------------------------------------------------------------
nv %>% 
  map(function(var) sum(is.na(var))) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_na") %>% 
  mutate(prop_na = n_na / nrow(nv)) %>% 
  print(n = length(nv))


## ----get_dupes, collapse=TRUE--------------------------------------------
nrow(get_dupes(nv_contributions))


## ----str_to_upper--------------------------------------------------------
nv <- nv %>% 
  mutate_if("is.character", "str_to_upper")


## ----mutate_year---------------------------------------------------------
nv <- nv %>% 
  mutate(year_clean = lubridate::year(contribution_date))


## ----clean_group_city----------------------------------------------------
nv$group_city_clean <- nv$group_city %>% 
  str_remove("[:punct:]") %>% 
  na_if("ALKDJF")


## ----clean_jurisditction-------------------------------------------------
nv$jurisdiction_clean <- na_if(nv$jurisdiction, "UNKNOWN")


## ----clean_party---------------------------------------------------------
nv_candidates %>% 
  filter(party == "Test Party Name 5")
nv$party_clean <- nv$candidate_party %>% 
  str_replace_all("TEST PARTY NAME 5", "REPUBLICAN PARTY")


## ----payee_name, collapse=TRUE-------------------------------------------
n_distinct(nv_payees$last_name[is.na(nv_payees$first_name)])

payee_fix <- nv %>%
  filter(is.na(payee_first)) %>%
  mutate(payee_prep = payee_last %>% 
           str_remove_all(fixed("\""))) %>% 
  select(contribution_id, payee_last, payee_prep) %>% 
  mutate(payee_fix = payee_prep %>%
           key_collision_merge() %>%
           n_gram_merge()) %>% 
  mutate(fixed = payee_last != payee_fix) %>% 
  select(-payee_prep)

# total changed records
sum(payee_fix$fixed, na.rm = TRUE)

# distinct changes made
payee_fix %>% 
  filter(fixed) %>% 
  select(-contribution_id) %>% 
  distinct() %>%
  nrow()

# reduced distinct names
n_distinct(payee_fix$payee_last)
n_distinct(payee_fix$payee_fix)

# percent change
n_distinct(payee_fix$payee_last) %>% 
  subtract(n_distinct(payee_fix$payee_fix)) %>% 
  divide_by(n_distinct(payee_fix$payee_last))


## ----most_changed--------------------------------------------------------
# number of each fix
payee_fix %>% 
  filter(fixed) %>% 
  count(payee_last, payee_fix) %>% 
  arrange(desc(n))


## ----join_fix------------------------------------------------------------
nv <- nv %>% 
  left_join(payee_fix, by = c("contribution_id", "payee_last")) %>%
  mutate(fixed = !is.na(fixed)) %>% 
  mutate(payee_clean = ifelse(fixed, payee_fix, payee_last)) %>% 
  mutate(payee_clean = na_if(payee_clean, "NONE"))


## ----check_na, echo=FALSE------------------------------------------------
nv %>%
  # select key cols
  select(
    contribution_id,
    contribution_amount,
    candidate_last,
    group_name,
    payee_first,
    payee_clean
  ) %>% 
  # coalesce recipient types into one col
  mutate(recipient = coalesce(candidate_last, group_name)) %>% 
  select(-candidate_last, -group_name) %>%
  mutate(contributor = coalesce(payee_first, payee_clean)) %>%
  select(-payee_first, -payee_clean) %>% 
# count NA in each col
  map(function(var) sum(is.na(var))) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_na")


## ----show_check----------------------------------------------------------
nv %>%
  # select key cols
  select(
    candidate_last,
    group_name,
    payee_first,
    payee_clean
  ) %>% 
  # coalesce recipient types into one col
  mutate(recipient = coalesce(candidate_last, group_name)) %>% 
  select(-candidate_last, -group_name) %>%
  # repeat for contributors
  mutate(contributor = coalesce(payee_first, payee_clean)) %>%
  select(-payee_first, -payee_clean) %>% 
  # filter for NA
  filter(is.na(contributor) | is.na(recipient)) %>% 
  distinct()


## ----na_flag-------------------------------------------------------------
nv <- nv %>% 
  mutate(na_flag = is.na(payee_first) & is.na(payee_clean))


## ----write_csv-----------------------------------------------------------
nv %>% 
  select(
    -jurisdiction,
    -candidate_party,
    -payee_last
  ) %>% 
  mutate_if(is.character, str_replace_all, "\"", "\'") %>% 
  write_csv(
    path = here("nv_contribs", "data", "nv_contribs_clean.csv"),
    na = ""
  )

