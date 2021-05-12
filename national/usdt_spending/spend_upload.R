library(tidyverse)
library(aws.s3)
library(cli)
library(fs)

csv_dir <- "/media/kiernan/My Passport/kiernan/us_spending/csv/"

bulk_names <- read_csv(
  file = "us/spending/bulk_aws_names.csv",
  col_types = cols(
    fy = col_integer(),
    zip_name = col_character(),
    zip_size = col_character(), # col_bytes
    csv_name = col_character(),
    csv_size = col_character(), # col_bytes
    aws_name = col_character()
  )
)

bulk_names <- mutate(bulk_names, across(ends_with("size"), fs_bytes))

for (i in seq_along(bulk_names$csv_name)) {
  # identify csv and aws names
  csv <- path(csv_dir, bulk_names$csv_name[i])
  aws <- bulk_names$aws_name[i]
  cli_h2("UPLOAD {.path {aws}} FILE {i}/{nrow(bulk_names)}")
  if (file_exists(csv)) {
    cli_alert_success("FILE EXISTS")
    # try to upload file
    put_try <- tryCatch(
      # return null from trycatch
      error = function(e) return(NULL),
      expr = {
        put_object(
          file = csv,
          object = aws,
          bucket = "publicaccountability",
          acl = "public-read",
          show_progress = TRUE,
          multipart = TRUE
        )
      }
      # repeat if failed
      if (is.null(put_try)) {
        # if trycatch returned null from error
        cli_alert_danger("UPLOAD FAILED, RETRY LOOP")
        repeat
      } else {
        # if object does not exist on server
        if (object_exists(aws, "publicaccountability")) {
          cli_alert_success("UPLOAD SUCCESS")
        } else {
          cli_alert_danger("OBJECT DOES NOT EXIST, RETRY LOOP")
          repeat
        }
      }
    )
  }
}
