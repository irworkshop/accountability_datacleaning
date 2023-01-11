# Kiernan Nicholls
# Parse LDA files to CSV
# https://lda.senate.gov/api/
# Fri Oct 29 13:41:24 2021 ------------------------------

suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(aws.s3))
suppressPackageStartupMessages(library(here))
suppressPackageStartupMessages(library(cli))
suppressPackageStartupMessages(library(fs))

# structure ---------------------------------------------------------------

# Each JSON file contains 4 components with `results` containing filings
# There are 250 results in each file, 1 per row when converted to frame
# Each filing contains 6 additional nested data frames:
#   1. Registrants
#   2. Clients
#   3. Lobbying activity
#       3a. Lobbyists
#       3b. Government Entities
#   4. Conviction disclosures
#   5. Foreign entities
#   6. Affiliated organizations

# convert nested JSON to flat CSV by filing
csv_dir <- here("national", "lda_filings", "data", "csv")

fil_csv <- path(csv_dir, "lda_client-firm.csv")
lob_csv <- path(csv_dir, "lda_firm-lobbyist.csv")
con_csv <- path(csv_dir, "lda_convict-lobbyist.csv")
for_csv <- path(csv_dir, "lda_client-foreign.csv")
org_csv <- path(csv_dir, "lda_client-affiliate.csv")

# text file containing the files already converted
prog_txt <- file_create(here("national", "lda_filings", "data", "prog_list.txt"))
done_json <- fs_path(read_lines(prog_txt))

# list the json files and remove those already done
json_dir <- here("national", "lda_filings", "data", "json")
lob_json <- dir_ls(json_dir, glob = "*.json")
lob_json <- lob_json[lob_json %out% done_json]

n <- length(lob_json)
# loop through each json and write to existing csv
for (i in seq_along(lob_json)) {
  message(paste(i, n, sep = "/"))

  x <- fromJSON(
    # txt = lob_json[length(lob_json) - 1],
    txt = lob_json[i],
    simplifyDataFrame = TRUE,
    flatten = TRUE
  )

  # filings ---------------------------------------------------------------

  # the relationship between firm and hired client
  # filing id, firm, client, date, income, expense

  lda_filings <- as_tibble(x$results)
  lda_filings <- lda_filings %>%
    select(-ends_with("_display"), -contains("ppb_")) %>%
    mutate(across(dt_posted, ymd_hms))

  lda_other <- lda_filings %>% select(filing_uuid, where(is.list))
  lda_filings <- select(lda_filings, -where(is.list))

  write_csv(
    x = lda_filings,
    file = fil_csv,
    na = "",
    append = file_exists(fil_csv),
    progress = FALSE
  )

  # lobbyists -------------------------------------------------------------

  # the relationship between a firm and the lobbyists they hire for issues

  just_reg <- lda_filings %>%
    select(
      filing_uuid, dt_posted, registrant.id, registrant.name,
      registrant.address_1, registrant.address_2,
      registrant.city, registrant.state, registrant.zip
    )

  all_lob <- lda_other %>%
    select(filing_uuid, lobbying_activities) %>%
    unnest(lobbying_activities)

  no_lob <- map_lgl(all_lob$lobbyists, is_empty)
  all_lob$lobbyists[no_lob] <- rep(list(data.frame()), sum(no_lob))

  all_lob <- unnest(all_lob, lobbyists)

  lob_issue <- all_lob %>%
    group_by(filing_uuid, lobbyist.id) %>%
    summarise(
      all_issues = paste(general_issue_code_display, collapse = ", "),
      .groups = "drop_last"
    )

  all_lob <- all_lob %>%
    select(
      filing_uuid,
      starts_with("lobbyist."),
      -lobbyist.prefix,
      -lobbyist.suffix
    ) %>%
    rename(
      lobbyist.prefix = lobbyist.prefix_display,
      lobbyist.suffix = lobbyist.suffix_display
    ) %>%
    distinct()

  all_lob <- inner_join(
    x = all_lob,
    y = lob_issue,
    by = c("filing_uuid", "lobbyist.id")
  )

  lob_out <- right_join(
    x = just_reg,
    y = all_lob,
    by = "filing_uuid"
  )

  write_csv(
    x = lob_out,
    file = lob_csv,
    na = "",
    append = file_exists(lob_csv),
    progress = FALSE
  )

  # convictions -----------------------------------------------------------

  con_lob <- lda_other %>%
    select(filing_uuid, conviction_disclosures) %>%
    unnest(conviction_disclosures)

  if (nrow(con_lob) > 1) {
    con_out <- right_join(
      x = just_reg,
      y = con_lob,
      by = "filing_uuid"
    )

    write_csv(
      x = con_out,
      file = con_csv,
      na = "",
      append = file_exists(con_csv),
      progress = FALSE
    )
  }

  # foreign entities ------------------------------------------------------

  just_client <- lda_filings %>%
    select(
      filing_uuid, dt_posted, client.id, client.name, client.state,
    )

  has_fe <- any(!map_lgl(lda_other$foreign_entities, is_empty))
  if (has_fe) {
    names(lda_other$foreign_entities) <- lda_filings$filing_uuid
    foreign_entity <- bind_rows(lda_other$foreign_entities, .id = "filing_uuid")
    foreign_entity <- as_tibble(foreign_entity) %>%
      select(-ends_with("_display"), -contains("ppb_")) %>%
      rename_with(~paste0("entity.", .), -1)

    for_out <- inner_join(
      x = just_client,
      y = foreign_entity,
      by = "filing_uuid"
    )

    write_csv(
      x = for_out,
      file = for_csv,
      na = "",
      append = file_exists(for_csv),
      progress = FALSE
    )

  }

  # affiliated orgs -------------------------------------------------------

  has_ao <- any(!map_lgl(lda_other$affiliated_organizations, is_empty))
  if (has_ao) {
    names(lda_other$affiliated_organizations) <- lda_filings$filing_uuid
    affiliated_org <- bind_rows(
      lda_other$affiliated_organizations,
      .id = "filing_uuid"
    )
    affiliated_org <- as_tibble(affiliated_org) %>%
      select(-ends_with("_display"), -contains("ppb_")) %>%
      rename_with(~paste0("org.", .), -1)

    org_out <- inner_join(
      x = just_client,
      y = affiliated_org,
      by = "filing_uuid"
    )

    write_csv(
      x = org_out,
      file = org_csv,
      na = "",
      append = file_exists(org_csv),
      progress = FALSE
    )
  }

  # write progress to text file
  write_lines(lob_json[i], prog_txt, append = TRUE)

}

# date files --------------------------------------------------------------

all_csv <- dir_ls(csv_dir, glob = "*.csv")

# find date of last file update
aws_ls <- get_bucket_df(bucket = "publicaccountability", prefix = "csv")

last_dt <- aws_ls$Key %>%
  str_subset("lda") %>%
  str_extract_all("\\d{8}") %>%
  unlist() %>%
  as.Date(format = "%Y%m%d") %>%
  max()

date_stamp <- sprintf(
  "_%s-%s.csv",
  str_remove_all(last_dt + 1, "-"),
  str_remove_all(Sys.Date(), "-")
)

new_csv <- all_csv %>%
  str_replace("\\.csv", date_stamp)

file_move(all_csv, new_csv)
