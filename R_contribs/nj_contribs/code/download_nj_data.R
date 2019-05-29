pacman::p_load(
  tidyverse,
  lubridate,
  magrittr,
  janitor,
  here
)

# get gubernatorial data ---------------------------------------------------------------------

download.file(
  url = "https://www.elec.state.nj.us/download/Data/Gubernatorial/All_GUB_Text.zip",
  destfile = here("nj_contribs", "data", "All_GUB_Text.zip")
)

unzip(
  zipfile = here("nj_contribs", "data", "All_GUB_Text.zip"),
  overwrite = TRUE,
  exdir = here("nj_contribs", "data", "All_GUB")
)

nj_gub_files <- list.files(
  path = here("nj_contribs", "data", "All_GUB"),
  full.names = TRUE
)

nj_gub_tsv <- map(
  nj_gub_files[-c(8, 16, 24)],
  read_delim,
  delim = "\t",
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_datetime("%m/%d/%Y"),
    CONT_AMT = col_double()
  )
)

nj_gub_csv <- map(
  nj_gub_files[c(8, 16, 24)],
  read_delim,
  delim = ",",
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_datetime("%m/%d/%Y"),
    CONT_AMT = col_double()
  )
)

nj_gub <- bind_rows(nj_gub_tsv, nj_gub_csv)

rm(nj_gub_files, nj_gub_tsv, nj_gub_csv)

#  get legislative data ----------------------------------------------------------------------

download.file(
  url = "https://www.elec.state.nj.us/download/Data/Legislative/All_LEG_Text.zip",
  destfile = here("nj_contribs", "data", "All_LEG_Text.zip")
)

unzip(
  zipfile = here("nj_contribs", "data", "All_LEG_Text.zip"),
  overwrite = TRUE,
  exdir = here("nj_contribs", "data", "All_LEG")
)

nj_leg_files <- list.files(
  path = here("nj_contribs", "data", "All_LEG"),
  full.names = TRUE
)

nj_leg_tsv <- map(
  nj_leg_files[-c(16:18, 31:33)],
  read_delim,
  delim = "\t",
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_datetime("%m/%d/%Y"),
    CONT_AMT = col_double()
  )
)

nj_leg_csv <- map(
  nj_leg_files[c(16:18, 31:33)],
  read_delim,
  delim = ",",
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_datetime("%m/%d/%Y"),
    CONT_AMT = col_double()
  )
)

nj_leg <- bind_rows(nj_leg_tsv, nj_leg_csv)

rm(nj_leg_files, nj_leg_tsv, nj_leg_csv)

# get local data -----------------------------------------------------------------------------

download.file(
  url = "https://www.elec.state.nj.us/download/Data/Countywide/All_CW_Text.zip",
  destfile = here("nj_contribs", "data", "All_CW_Text.zip")
)

unzip(
  zipfile = here("nj_contribs", "data", "All_CW_Text.zip"),
  overwrite = TRUE,
  exdir = here("nj_contribs", "data", "All_CW")
)

nj_cw_files <- list.files(
  path = here("nj_contribs", "data", "All_CW"),
  full.names = TRUE
)

nj_cw_tsv <- map(
  nj_cw_files[-c(5:9, 14:18)],
  read_delim,
  delim = "\t",
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_datetime("%m/%d/%Y"),
    CONT_AMT = col_number()
  )
)

nj_cw_csv <- map(
  nj_cw_files[c(5:9, 14:18)],
  read_delim,
  delim = ",",
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_datetime("%m/%d/%Y"),
    CONT_AMT = col_double()
  )
)

nj_cw <- bind_rows(nj_cw_tsv, nj_cw_csv)

rm(nj_cw_files, nj_cw_tsv, nj_cw_csv)


# get committees -----------------------------------------------------------------------------

download.file(
  url = "https://www.elec.state.nj.us/download/Data/PAC/All_PAC_Text.zip",
  destfile = here("nj_contribs", "data", "All_PAC_Text.zip")
)

unzip(
  zipfile = here("nj_contribs", "data", "All_PAC_Text.zip"),
  overwrite = TRUE,
  exdir = here("nj_contribs", "data", "All_PAC")
)

nj_pac_files <- list.files(
  path = here("nj_contribs", "data", "All_PAC"),
  full.names = TRUE
)

nj_pac_tsv <- map(
  nj_pac_files[-c(19, 21, 22)],
  read_delim,
  delim = "\t",
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_datetime("%m/%d/%Y"),
    CONT_AMT = col_number()
  )
)

nj_pac_csv <- map(
  nj_pac_files[c(19, 21, 22)],
  read_delim,
  delim = ",",
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_datetime("%m/%d/%Y"),
    CONT_AMT = col_double()
  )
)

nj_pac <- bind_rows(nj_pac_tsv, nj_pac_csv)

rm(nj_pac_files, nj_pac_tsv, nj_pac_csv)

# combine all data ---------------------------------------------------------------------------

nj <-
  bind_rows(nj_gub, nj_leg, nj_cw, nj_pac, .id = "source") %>%
  clean_names() %>%
  arrange(desc(election_year)) %>%
  mutate(source = source %>%
           recode(
             "1" = "gub",
             "2" = "leg",
             "3" = "cw",
             "4" = "pac"
           )
  )

rm(nj_gub, nj_leg, nj_cw, nj_pac)
