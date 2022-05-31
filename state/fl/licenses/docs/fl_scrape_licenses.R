suppressMessages(library(tidyverse))
suppressMessages(library(janitor))
suppressMessages(library(rvest))
suppressMessages(library(here))
suppressMessages(library(cli))
suppressMessages(library(fs))

raw_dir <- dir_create(here("state", "fl", "licenses", "data", "raw"))

cli_list <- function(x) {
  cli_ol()
  cli_li(col_blue(x))
  cli_end()
}

ipr <- read_html("http://www.myfloridalicense.com/dbpr/instant-public-records/")

# scrape table text and hyperlinks
reg_cells <- html_elements(ipr, "table td")
reg_types <- tibble(
  type = html_text(reg_cells),
  href = html_attr(html_element(reg_cells, "a"), "href")
)

# remove header row
reg_types <- reg_types[-1, ]
sub_dirs <- dir_create(path(raw_dir, make_clean_names(reg_types$type)))

for (i in seq_along(reg_types$href)) {
  cli_h2(paste(i, reg_types$type[i]))

  if (length(dir_ls(sub_dirs[i])) > 0) {
    next
  }

  # read the sub-page and look for info box
  pg <- read_html(reg_types$href[i])
  pan_box <- html_element(pg, ".vc_tta-container")
  pan_sub <- html_elements(pan_box, ".vc_tta-panel")
  pan_heads <- html_text(html_elements(pan_box, ".vc_tta-panel .vc_tta-panel-heading"))

  # make sure we have 1 heading per info box
  if (length(pan_sub) == length(pan_heads)) {
    cli_alert_success("Box found for each {length(pan_heads)} header")
  }

  # look for a heading where licenses data is found
  which_lic <- str_which(pan_heads, regex("^license", ignore_case = TRUE))
  if (length(which_lic) == 1) {
    cli_alert_success("Found header '{pan_heads[which_lic]}'")
  } else {
    cli_alert_danger("No license header found")
    next
  }

  # get all the urls from the data info box
  raw_urls <- pan_sub[[which_lic]] %>%
    html_elements("table td a") %>%
    html_attr("href")

  if (length(raw_urls) > 0) {
    cli_alert_success("Found {length(raw_urls)} file URL{?s}")
    cli_list(basename(raw_urls))
  }

  # prepare the file to save to
  raw_csv <- path(sub_dirs[i], basename(raw_urls))

  # look for box with bullet point list of columns
  which_layout <- pan_box %>%
    html_elements(".vc_tta-panel-body .vc_toggle_title") %>%
    html_text() %>%
    str_which(regex("layout", ignore_case = TRUE))

  # pull the bullet points as a vector
  if (length(which_layout) == 1) {
    cli_alert_success("Found file layout list")
    pan_list <- pan_box %>%
      html_elements(".vc_toggle") %>%
      pluck(which_layout) %>%
      html_element("ul")

    if (is.na(pan_list)) {
      cli_alert_danger("Could not read column header list")
    } else {
      col_heads <- pan_box %>%
        html_elements("ul") %>%
        pluck(which_layout) %>%
        html_elements("li") %>%
        html_text()
      # write col headers line into CSV line
      col_line <- paste(sprintf('"%s"', col_heads), collapse = ",")
      write_lines(col_line, raw_csv)
    }
  } else {
    cli_alert_warning("No layout list found or needed")
  }

  for (j in seq_along(raw_urls)) {
    download.file(raw_urls[j], raw_csv[j], mode = "a")
  }
}
