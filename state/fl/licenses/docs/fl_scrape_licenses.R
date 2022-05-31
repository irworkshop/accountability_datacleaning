library(tidyverse)
library(rvest)

ipr <- read_html("http://www.myfloridalicense.com/dbpr/instant-public-records/")

# scrape table text and hyperlinks
reg_cells <- html_elements(ipr, "table td")
reg_types <- tibble(
  type = html_text(reg_cells),
  href = html_attr(html_element(reg_cells, "a"), "href")
)

# remove header row
reg_types <- reg_types[-1, ]

a <- reg_types$href[2]
b <- read_html(a)
pan_box <- html_element(b, ".vc_tta-container")
pan_heads <- html_elements(pan_box, ".vc_tta-panel .vc_tta-panel-heading")
pan_heads <- html_text(pan_heads)
which_lic <- str_which(pan_heads, regex("license", ignore_case = TRUE))

pan_sub <- pan_box %>%
  html_elements(".vc_tta-panel")

length(pan_sub) == length(pan_heads)

pan_sub[[which_lic]] %>%
  html_elements("table td a") %>%
  html_attr("href")
