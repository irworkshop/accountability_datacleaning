## ----setup, include=FALSE------------------------------------------------
library(knitr)
opts_chunk$set(
  echo = TRUE,
  warning = FALSE,
  message = FALSE,
  error = FALSE,
  comment = "#>",
  fig.path = "../plots/",
  fig.width = 10,
  dpi = 300
)
options(width = 99)


## ----p_load, message=FALSE, warning=FALSE, error=FALSE-------------------
# install.packages("pacman")
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # date strings
  magrittr, # pipe opperators
  janitor, # data cleaning
  zipcode, # clean and compare
  refinr, # cluster and merge
  vroom, # read files fast
  rvest, # scrape web pages
  knitr, # knit documents
  httr, # acess web API
  here, # navigate local storage
  fs # search local storage 
)


## ----pre_download, collapse=TRUE-----------------------------------------
response <- GET("https://www.elec.state.nj.us/download/Data/Gubernatorial/All_GUB_Text.zip")
utils:::format.object_size(as.numeric(headers(response)[["Content-Length"]]), "auto")
httr::headers(response)[["last-modified"]]


## ------------------------------------------------------------------------
nj_zip_urls <- c(
  "https://www.elec.state.nj.us/download/Data/Gubernatorial/All_GUB_Text.zip", # (5.7 MB)
  "https://www.elec.state.nj.us/download/Data/Legislative/All_LEG_Text.zip", # (9.7 MB)
  "https://www.elec.state.nj.us/download/Data/Countywide/All_CW_Text.zip", # (3.5 MB)
  "https://www.elec.state.nj.us/download/Data/PAC/All_PAC_Text.zip" # (6.2 MB)
)


## ----download_files, collapse=TRUE---------------------------------------
# create a direcory for download
dir_create(here("nj_contribs", "data", "raw"))

# file date wrapper function
any_old_files <- function(path, type) {
  path %>%
    dir_ls(type = "file", glob = type) %>% 
    file_info() %>% 
    pull(modification_time) %>% 
    floor_date("day") %>% 
    equals(today()) %>% 
    not() %>% 
    any()
}

# download each file in the vector
if (any_old_files(here("nj_contribs", "data", "raw"), "*.zip")) {
  for (url in nj_zip_urls) {
    download.file(
      url = url,
      destfile = here(
        "nj_contribs",
        "data",
        basename(url)
      )
    )
  }
}


## ----view_zip------------------------------------------------------------
nj_zip_files <- dir_ls(
  path = here("nj_contribs", "data"),
  type = "file",
  glob = "*.zip",
)

nj_zip_files %>% 
  map(unzip, list = TRUE) %>% 
  bind_rows(.id = "zip") %>%
  mutate(zip = basename(zip)) %>% 
  set_names(c("zip", "file", "bytes", "date")) %>%
  sample_n(10) %>% 
  print()


## ----unzip---------------------------------------------------------------
if (any_old_files(here("nj_contribs", "data", "raw"), "*.txt")) {
  map(
    nj_zip_files,
    unzip,
    exdir = here("nj_contribs", "data"),
    overwrite = TRUE
  )
}


## ----make_names----------------------------------------------------------
nj_names <-
  here("nj_contribs", "data", "raw") %>%
  dir_ls(type = "file", glob = "*.txt") %>%
  extract(1) %>%
  read.table(nrows = 1, sep = "\t", header = FALSE) %>%
  as_vector() %>%
  make_clean_names()


## ----vroom_read----------------------------------------------------------
nj <-
  here("nj_contribs", "data", "raw") %>%
  dir_ls(type = "file", glob = "*.txt") %>%
  vroom(
    delim = NULL,
    col_names = nj_names,
    col_types = cols(.default = "c"),
    id = "source_file",
    skip = 1,
    trim_ws = TRUE,
    locale = locale(tz = "US/Eastern"),
    progress = FALSE
  ) %>%
  # parse non-character cols
  mutate(
    source_file = basename(source_file) %>% str_remove("\\.txt$"),
    cont_date   = parse_date(cont_date, "%m/%d/%Y"),
    cont_amt    = parse_number(cont_amt)
  )


## ----glimpse_all---------------------------------------------------------
glimpse(sample_frac(nj))


## ----filter_date, collapse=TRUE------------------------------------------
sum(nj$cont_date < "2008-01-01", na.rm = TRUE) / nrow(nj)
min(nj$cont_date, na.rm = TRUE)
max(nj$cont_date, na.rm = TRUE)


## ----plot_n_year, echo=FALSE---------------------------------------------
nj %>% 
  group_by(year = year(cont_date)) %>% 
  count() %>% 
  ggplot(mapping = aes(x = year, y = n)) +
  geom_col() +
  coord_cartesian(xlim = c(1978, 2015)) +
  scale_x_continuous(breaks = 1978:2015) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(
    title = "Number of Records Over Time",
    subtitle = "New Jersey ELEC Contribution Files",
    x = "Contribution Year",
    y = "Number of Records"
  )


## ------------------------------------------------------------------------
nj <- nj %>% 
  filter(year(cont_date) > 2008)


## ----count_distinct------------------------------------------------------
nj %>% 
  map(n_distinct) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_distinct") %>% 
  mutate(prop_distinct = round(n_distinct / nrow(nj), 4)) %>%
  print(n = length(nj))


## ----tabyls_function, echo=FALSE-----------------------------------------
print_tabyl <- function(data, ...) {
  as_tibble(arrange(tabyl(data, ...), desc(n)))
}


## ----print_tabyls--------------------------------------------------------
print_tabyl(nj, source_file)
print_tabyl(nj, party)
print_tabyl(nj, election_year) %>% arrange(election_year)
print_tabyl(nj, cont_type)
print_tabyl(nj, receipt_type)
print_tabyl(nj, office)
print_tabyl(nj, cont_state)
print_tabyl(nj, occupation)
print_tabyl(nj, election_type)


## ----plot_non_log, echo=FALSE, fig.height=10-----------------------------
nj %>% 
  filter(party != "OTHER (ANY COMBINATION OF DEM/REP/IND)") %>% 
  ggplot(aes(cont_amt)) +
  geom_histogram(aes(fill = party)) +
  scale_fill_manual(values = c("blue", "forestgreen", "purple", "red")) +
  theme(legend.position = "none") +
  facet_wrap(~party) +
  labs(
    title = "Contribution Distribution",
    subtitle = "by political Party",
    y = "Number of Contributions",
    x = "Amount ($USD)"
  )


## ----plot_amt_party, echo=FALSE, fig.height=10---------------------------
nj %>% 
  filter(party != "OTHER (ANY COMBINATION OF DEM/REP/IND)") %>% 
  ggplot(aes(cont_amt)) +
  geom_histogram(aes(fill = party)) +
  scale_x_log10() +
  scale_y_log10() +
  scale_fill_manual(values = c("blue", "forestgreen", "purple", "red")) +
  theme(legend.position = "none") +
  facet_wrap(~party) +
  labs(
    title = "Contribution Distribution",
    subtitle = "by political Party",
    y = "Number of Contributions",
    x = "Amount ($USD)"
  )


## ----plot_amt_year, echo=FALSE-------------------------------------------
nj %>% 
  filter(election_year > 2008) %>% 
  filter(party != "OTHER (ANY COMBINATION OF DEM/REP/IND)") %>% 
  group_by(election_year, party) %>% 
  summarize(sum = sum(cont_amt)) %>% 
  ggplot(aes(x = election_year, y = sum)) +
  geom_col(aes(fill = party)) +
  scale_fill_manual(values = c("blue", "forestgreen", "purple", "red"))


## ----plot_amt_cont, echo=FALSE, fig.height=10----------------------------
nj %>% 
  ggplot(aes(cont_amt)) +
  geom_histogram() +
  scale_x_log10() +
  scale_y_log10() +
  facet_wrap(~cont_type) +
  labs(
    title = "Contribution Distribution",
    subtitle = "by Contribution Type",
    y = "Number of Contributions",
    x = "Amount ($USD)"
  )


## ----plot_amt_rec, echo=FALSE, fig.height=10-----------------------------
nj %>% 
  ggplot(aes(cont_amt)) +
  geom_histogram() +
  scale_x_log10() +
  scale_y_log10() +
  facet_wrap(~receipt_type) +
  labs(
    title = "Contribution Distribution",
    subtitle = "by Recipient Type",
    y = "Number of Contributions",
    x = "Amount ($USD)"
  )


## ----plot_amt_elec, echo=FALSE, fig.height=10----------------------------
nj %>% 
  ggplot(aes(cont_amt)) +
  geom_histogram() +
  scale_x_log10() +
  scale_y_log10() +
  facet_wrap(~election_type) +
  labs(
    title = "Contribution Distribution",
    subtitle = "by Election Type",
    y = "Number of Contributions",
    x = "Amount ($USD)"
  )


## ----plot_amt_state, fig.height=14---------------------------------------
nj %>% 
  group_by(cont_state) %>% 
  summarize(mean_cont = median(cont_amt)) %>%
  filter(cont_state %in% c(state.abb, "DC")) %>% 
  ggplot(aes(x = reorder(cont_state, -mean_cont), mean_cont)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Median Contribution Amount",
    subtitle = "by Contributor's State",
    x = "State",
    y = "Mean Amount ($USD)"
  )


## ----n_distinct, collapse=TRUE-------------------------------------------
nrow(distinct(nj)) - nrow(nj)


## ----get_dupes-----------------------------------------------------------
# create dupes df
nj_dupes <- nj %>% 
  get_dupes() %>%
  distinct() %>% 
  mutate(dupe_flag = TRUE)

# show dupes
nj_dupes %>% 
  mutate(rec = coalesce(rec_lname, rec_non_ind_name)) %>% 
  select(
    cont_lname,
    cont_amt,
    cont_date,
    rec,
    dupe_count,
    dupe_flag
  )


## ----flag_dupes, warning=FALSE, message=FALSE, error=FALSE---------------
nj <- nj %>% 
  left_join(nj_dupes) %>% 
  mutate(
    dupe_count = ifelse(is.na(dupe_count), 1, dupe_count),
    dupe_flag  = !is.na(dupe_flag)
    )


## ----rownames_to_column, collapse=TRUE-----------------------------------
nj <- nj %>%
  # unique row num id
  rownames_to_column(var = "id") %>% 
  # make all same width
  mutate(id = str_pad(
    string = id, 
    width = max(nchar(id)), 
    side = "left", 
    pad = "0")
  )

# distinct for every row
n_distinct(nj$id) == nrow(nj)


## ----mutually_exclusive, collapse=TRUE-----------------------------------
# prop NA each sum to 1
mean(is.na(nj$rec_lname)) + mean(is.na(nj$rec_non_ind_name))


## ----count_na------------------------------------------------------------
nj %>% 
  map(function(var) sum(is.na(var))) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_na") %>% 
  mutate(prop_na = n_na / nrow(nj)) %>% 
  print(n = length(nj))


## ----mutate_year---------------------------------------------------------
# extract year variable
nj <- nj %>% 
  mutate(cont_year = year(cont_date))


## ----year_vars_diff, collapse=TRUE---------------------------------------
mean(nj$cont_year == nj$election_year)


## ----view_future, echo=FALSE---------------------------------------------
# view futures contribs
nj %>% 
  filter(cont_date > today()) %>% 
  arrange(cont_date) %>% 
  mutate(cont = coalesce(cont_lname, cont_non_ind_name)) %>% 
  mutate(rec = coalesce(rec_lname, rec_non_ind_name)) %>% 
  select(cont_date, cont, cont_amt, rec, source_file) %>% 
  print()


## ----flag_dates----------------------------------------------------------
# flag future contribs
nj <- nj %>% 
  mutate(date_flag = cont_date > today())


## ------------------------------------------------------------------------
data("zipcode")

zipcode <- zipcode %>% 
  as_tibble() %>% 
  select(city, state, zip) %>% 
  mutate(city = str_to_upper(city))

zipcode %>% sample_n(10)


## ----mutate_zip5, collapse=TRUE------------------------------------------
nj <- nj %>% mutate(zip5 = clean.zipcodes(cont_zip))

nj$zip5 <- nj$zip5 %>% 
  na_if("0") %>% 
  na_if("000000") %>% 
  na_if("999999")

n_distinct(nj$cont_zip)
n_distinct(nj$zip5)


## ------------------------------------------------------------------------
nj_bad_zip <- nj %>% 
  filter(nchar(zip5) != 5) %>% 
  select(id, cont_street1, cont_city, cont_state, cont_zip, zip5) %>% 
  left_join(zipcode, by = c("cont_city" = "city", "cont_state" = "state")) %>% 
  rename(clean_zip = zip5, valid_zip = zip)

print(nj_bad_zip)


## ----zip_fix_manual, collapse=TRUE---------------------------------------
nj$zip5[nj$id %in% nj_bad_zip$id] <- c(
  "07083", # (070083) valid union
  "08816", # (008816) valid NJ
  "08302", # (080302) valid bridgeton
  "63105", # (631053) valid stl
  "08077", # (089077) valid cinnaminson
  "08691", # (086914) valid hamilton
  "08872", # (088872) valid sayreville
  "10013", # (100313) valid nyc
  "83713", # (083713) valid boise
  "07932", # (079325) valid florham
  "08028", # (08)     valid glassboro
  "08902", # (008902) valid n brunswick
  "07666", # (076666) valid teaneck
  "07047", # (07)     valid jersey city
  "84201", # (084201) valid ogden
  "08902"  # (008902) valid n brunswick
)

n_distinct(nj$zip5)
sum(nchar(nj$zip5) != 5, na.rm = TRUE)


## ----can_abbs, collapse=TRUE---------------------------------------------
canadian_abbs <-
  read_html("https://en.Wikipedia.org/wiki/Provinces_and_territories_of_Canada") %>%
  html_node("table.wikitable:nth-child(12)") %>% 
  html_table(fill = TRUE) %>% 
  as_tibble(.name_repair = make_clean_names) %>% 
  slice(-1, -nrow(.)) %>% 
  select(postalabbrev, capital_1, largestcity_2) %>%
  rename(state = postalabbrev,
         capital = capital_1, 
         queen = largestcity_2) %>% 
  gather(-state, capital, queen,
         key = type,
         value = city) %>% 
  select(-type) %>% 
  distinct()


## ----valid_abb-----------------------------------------------------------
zipcode <- zipcode %>% 
  bind_rows(canadian_abbs) %>%
  mutate(city = str_to_upper(city))

valid_abb <- sort(unique(zipcode$state))
setdiff(valid_abb, state.abb)


## ----view_bad_abbs, echo=FALSE-------------------------------------------
nj %>% 
  filter(!(cont_state %in% valid_abb)) %>% 
  select(id, cont_city, cont_state, cont_zip) %>% 
  filter(!is.na(cont_state)) %>% 
  left_join(
    y = zipcode %>% select(zip, city, state), 
    by = c("cont_zip" = "zip")
  )


## ----clean_abbs, collapse=TRUE-------------------------------------------
sum(!(na.omit(nj$cont_state) %in% valid_abb))
n_distinct(nj$cont_state)

nj$state_clean <- nj$cont_state %>% 
  str_replace_all(pattern = "MJ", replacement = "NJ") %>% 
  str_replace_all("^N$", "NJ") %>% 
  str_replace_all("NK",  "NJ") %>% 
  str_replace_all("TE",  "TN") %>% 
  str_replace_all("^P$", "PA") %>% 
  str_replace_all("^7$", "PA")

sum(!(na.omit(nj$state_clean) %in% valid_abb))
n_distinct(nj$state_clean)


## ----tabyl_state---------------------------------------------------------
nj %>% 
  tabyl(state_clean) %>% 
  arrange(desc(n)) %>% 
  as_tibble() %>% 
  mutate(cum_percent = cumsum(percent))


## ------------------------------------------------------------------------
nj_muni <- 
  read_tsv(
    file = "https://www.nj.gov/infobank/muni.dat", 
    col_names = c("muni", "county", "old_code", "tax_code", "district", "fed_code", "county_code"),
    col_types = cols(.default = col_character())
  ) %>% 
  mutate(
    county = str_to_upper(county),
    muni   = str_to_upper(muni)
  )

nj_valid_muni <- sort(unique(nj_muni$muni))


## ------------------------------------------------------------------------
nj_without_suffix <- nj_valid_muni %>% 
  str_remove("[:punct:]") %>% 
  str_remove("\\b(\\w+)$") %>% 
  str_trim()

nj_no_punct <- nj_valid_muni %>% 
  str_remove_all("[:punct:]")

nj_full_suffix <- nj_valid_muni %>% 
  str_replace("TWP\\.$", "TOWNSHIP")

all_valid_muni <- sort(unique(c(
  # variations on valid NJ munis
  nj_valid_muni,
  nj_without_suffix, 
  nj_no_punct,
  nj_full_suffix,
  # valid cities outside NJ
  zipcode$city,
  # very common valid unincorperated places
  "WHITEHOUSE STATION",
  "MCAFEE",
  "GLEN MILLS",
  "KINGS POINT"
)))


## ------------------------------------------------------------------------
nj_bad_city <- nj %>%
  filter(!(cont_city %in% all_valid_muni)) %>% 
  filter(!is.na(cont_city)) %>% 
  select(id, cont_street1, state_clean, zip5, cont_city)


## ----view_bad------------------------------------------------------------
nj_bad_city %>% 
  group_by(cont_city, state_clean) %>% 
  count() %>% 
  ungroup() %>% 
  arrange(desc(n)) %>% 
  mutate(
    prop = n / sum(n),
    cumsum = cumsum(n),
    cumprop = cumsum(prop)
  )


## ----city_prep, collapse=TRUE--------------------------------------------
nj_city_fix <- nj %>%  
  rename(city_original = cont_city) %>%
  select(
    id,
    cont_street1,
    state_clean,
    zip5,
    city_original
  ) %>% 
  mutate(city_prep = city_original %>%
           str_to_upper() %>%
           str_replace_all("(^|\\b)N(\\b|$)",  "NORTH") %>%
           str_replace_all("(^|\\b)S(\\b|$)",  "SOUTH") %>%
           str_replace_all("(^|\\b)E(\\b|$)",  "EAST") %>%
           str_replace_all("(^|\\b)W(\\b|$)",  "WEST") %>%
           str_replace_all("(^|\\b)MT(\\b|$)", "MOUNT") %>%
           str_replace_all("(^|\\b)ST(\\b|$)", "SAINT") %>%
           str_replace_all("(^|\\b)PT(\\b|$)", "PORT") %>%
           str_replace_all("(^|\\b)FT(\\b|$)", "FORT") %>%
           str_replace_all("(^|\\b)PK(\\b|$)", "PARK") %>%
           str_replace_all("(^|\\b)JCT(\\b|$)", "JUNCTION") %>%
           str_replace_all("(^|\\b)TWP(\\b|$)", "TOWNSHIP") %>%
           str_replace_all("(^|\\b)TWP\\.(\\b|$)", "TOWNSHIP") %>%
           str_remove("(^|\\b)NJ(\\b|$)") %>%
           str_remove("(^|\\b)NY(\\b|$)") %>%
           str_remove_all(fixed("\\")) %>%
           str_replace_all("\\s\\s", " ") %>% 
           str_trim() %>% 
           na_if("")
  )

sum(nj_city_fix$city_original != nj_city_fix$city_prep, na.rm = TRUE)


## ----refine, collapse=TRUE-----------------------------------------------
nj_city_fix <- nj_city_fix %>% 
  # refine the prepared variable
  mutate(city_fix = city_prep %>%
           # edit to match valid munis
           key_collision_merge(dict = all_valid_muni) %>%
           n_gram_merge()) %>%
  # create logical change variable
  mutate(fixed = city_prep != city_fix) %>%
  # keep only changed records
  filter(fixed) %>%
  # group by fixes
  arrange(city_fix) %>% 
  select(-fixed)

nrow(nj_city_fix)
nj_city_fix %>% 
  select(city_original, city_fix) %>% 
  distinct() %>% 
  nrow()


## ----good_fix------------------------------------------------------------
good_fix <- nj_city_fix %>%
  inner_join(
    y = zipcode,
    by = c(
      "zip5" = "zip",
      "city_fix" = "city",
      "state_clean" = "state"
    )
  )

nrow(good_fix) # total changes made
n_distinct(good_fix$city_fix) # distinct changes
print(good_fix)


## ----bad_fix-------------------------------------------------------------
bad_fix <- nj_city_fix %>%
  filter(!(id %in% good_fix$id))

nrow(bad_fix)
print(bad_fix)

# these 6 erroneous changes account for 4/5 bad fixes
bad_fix$city_fix <- bad_fix$city_fix %>% 
  str_replace_all("^DOUGLASVILLE", "DOUGLASSVILLE") %>% 
  str_replace_all("^FOREST LAKE", "LAKE FOREST") %>% 
  str_replace_all("^GLENN MILLS", "GLEN MILLS") %>% 
  str_replace_all("^LAKE SPRING", "SPRING LAKE") %>% 
  str_replace_all("^WHITE HOUSE STATION", "WHITEHOUSE STATION") %>% 
  str_replace_all("^WINSTON SALEM", "WINSTON-SALEM")

# last 25 changes
bad_fix %>% 
  filter(city_original != city_fix) %>% 
  filter(!(city_fix %in% all_valid_muni)) %>% 
  print(n = nrow(.))

bad_fix$city_fix <- bad_fix$city_fix %>% 
  str_replace_all("^AVENTURA", "VENTURA") %>% 
  str_replace_all("^BERARDSVILLE", "BERNARDSVILLE") %>% 
  str_replace_all("^FOREST HILL", "FOREST HILLS") %>% 
  str_replace_all("^FOREST RIVER", "RIVER FOREST") %>% 
  str_replace_all("^MALVERN", "MALVERN") %>% 
  str_replace_all("^MC AFEE", "MCAFEE") %>% 
  str_replace_all("^NARBETH", "NARBERTH") %>% 
  str_replace_all("^ORRISTOWN", "MORRISTOWN") %>% 
  str_replace_all("^NMORRISTOWN", "MORRISTOWN") %>% 
  str_replace_all("^KINGSPOINT", "KINGS POINT") %>% 
  str_replace_all("^MILLSTONE BOROUGH", "MILLSTONE BORO") %>% 
  str_replace_all("^PLAINFEILD", "PLAINFIELD") %>% 
  str_replace_all("^RIVERVIEW", "RIVERVIEW") %>% 
  str_replace_all("^ROLLING HILL ESTATES$", "ROLLING HILLS ESTATES") %>% 
  str_replace_all("^SHARK RIVER HILL", "SHARK RIVER HILLS") %>% 
  str_replace_all("^TAREYTOWN", "TARRYTOWN") %>% 
  str_replace_all("^WELLSLEY HILLS", "WELLESLEY HILLS")


## ----all_fix-------------------------------------------------------------
if (nrow(good_fix) + nrow(bad_fix) == nrow(nj_city_fix)) {
  nj_city_fix <- 
    bind_rows(good_fix, bad_fix) %>% 
    select(id, city_original, city_fix) %>% 
    filter(city_original != city_fix)
}

print(nj_city_fix)


## ----fix_city_join, collapse=TRUE----------------------------------------
nj <- nj %>% 
  left_join(nj_city_fix, by = "id") %>% 
  mutate(city_clean = ifelse(is.na(city_fix), cont_city, city_fix)) %>% 
  select(-city_original, -city_fix)

n_distinct(nj$cont_city)
n_distinct(nj$city_clean)

nj %>% 
  filter(cont_city != city_clean) %>% 
  select(id, cont_city, city_clean, state_clean) %>% 
  sample_frac()


## ----key_vars, collapse=TRUE---------------------------------------------
nj_key_vars <- nj %>%
  replace_na(
    list(
      cont_lname  = "",
      cont_fname  = "",
      cont_mname  = "",
      cont_suffix = ""
    )
  ) %>% 
  # unite first and last names
  unite(cont_fname, cont_mname, cont_lname, cont_suffix,
        col = cont_full_name,
        sep = " ") %>%
  # remove empty unites
  mutate(cont_full_name = na_if(str_trim(cont_full_name), "")) %>% 
  # repeat for non-individual contributors
  replace_na(
    list(
      cont_non_ind_name  = "",
      cont_non_ind_name2  = ""
    )
  ) %>% 
  unite(cont_non_ind_name, cont_non_ind_name2,
        col = cont_non_ind_name,
        sep = " ") %>%
  mutate(cont_non_ind_name = na_if(str_trim(cont_non_ind_name), "")) %>% 
  # coalesce ind and non-ind united names into single variable
  mutate(cont = coalesce(cont_full_name, cont_non_ind_name)) %>% 
  # repeat for recipients
  replace_na(
    list(
      rec_lname  = "",
      rec_fname  = "",
      rec_mname  = "",
      rec_suffix = ""
    )
  ) %>% 
  # unite first and last names
  unite(rec_fname, rec_mname, rec_lname, rec_suffix,
        col = rec_full_name,
        sep = " ") %>%
  # remove empty unites
  mutate(rec_full_name = na_if(str_trim(rec_full_name), "")) %>% 
  # repeat for non-individual contributors
  replace_na(
    list(
      rec_non_ind_name  = "",
      rec_non_ind_name2  = ""
    )
  ) %>% 
  unite(rec_non_ind_name, rec_non_ind_name2,
        col = rec_non_ind_name,
        sep = " ") %>%
  mutate(rec_non_ind_name = na_if(str_trim(rec_non_ind_name), "")) %>% 
  # coalesce ind and non-ind united names into single variable
  mutate(rec = coalesce(rec_full_name, rec_non_ind_name)) %>% 
  # select key vars
  select(id, cont_date, cont_type, cont_amt, cont, rec)


print(nj_key_vars)
nrow(nj_key_vars)
nrow(distinct(nj_key_vars))
nrow(drop_na(nj_key_vars))


## ------------------------------------------------------------------------
nj_key_vars %>% 
  map(function(var) sum(is.na(var))) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_na")

nj <- nj %>% 
  mutate(na_flag = id %in% nj_key_vars$id[is.na(nj_key_vars$cont)])


## ------------------------------------------------------------------------
nj %>% 
  select(
    id,
    cont_date, 
    cont_type, 
    cont_amt,
    ends_with("clean"),
    ends_with("flag")
  )


## ----write_csv, eval=FALSE-----------------------------------------------
## nj %>%
##   # remove unclean cols
##   select(
##     -cont_city,
##     -cont_state,
##     -cont_zip
##   ) %>%
##   # write to disk
##   write_csv(
##     path = here("nj_contribs", "data", "nj_contribs_clean.csv"),
##     na = ""
##   )

