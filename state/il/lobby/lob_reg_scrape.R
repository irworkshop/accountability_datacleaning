library(tidyverse)
library(rvest)
library(magrittr)

base <- "https://secure.in.gov"
pri_list <- read_html(paste0(base, "/apps/ilrc/registration/browse/lobbyistList?type=emp"))
front_urls <- pri_list %>%
  html_node("#lobbyistList") %>%
  html_nodes("a") %>%
  html_attr("href") %>%
  str_c(base, .)

n_distinct(front_urls)
length(front_urls)

lob_id <- str_extract(front_urls[1], "(?<=lobbyistId=)\\d+")
pri_test <- read_html(front_urls[1])
# pri_table <- pri_test %>%
#   html_node("#regTable") %>%
#   html_table() %>%
#   as_tibble(.name_repair = "unique") %>%
#   select(
#     year = 1,
#     name = 3,
#     ec = 4,
#     confirm = 6
#   )

next_urls <- pri_test %>%
  html_node("tbody") %>%
  html_nodes("tr") %>%
  html_attr("onclick") %>%
  str_extract("(?<=\\').*(?=\\')") %>%
  str_c(base, .)

data <- read_html(next_urls[1])
data %>%
  html_node("table") %>%
  html_node("table") %>%
  html_node("table") %>%
  html_table() %>%
  as_vector()

find_sec <- data %>%
  html_nodes("table") %>%
  html_text() %>%
  map_lgl(str_detect, "Section A") %>%
  which() %>%
  max()

data %>%
  html_nodes("table") %>%
  extract(find_sec + 2) %>%
  html_table()


# -------------------------------------------------------------------------

base <- "https://secure.in.gov/apps/ilrc/registration/browse/employerRegistration/readOnly/"
lob <- 10725
url <- paste0(base, lob)

html <- read_html(url)
text <- html_text(html)

get_between <- function(text, a, b) {
  str_extract(text, glue::glue("(?<={a})(.+)(?={b})"))
}

confirm_num <- get_between(text, "\t\tConfirmation number:\\s", "\n\t")
legal_name <- get_between(text, "1. Full legal name of employer lobbyist:\n\t\t", "\n\t")
biz_type <- get_between(text, "2. Type of business:\n\t\t", "\n\t")

html %>%
  html_nodes("table") %>%
  extract(3) %>%
  html_table() %>%
  unlist()

html %>%
  html_nodes("table") %>%
  extract(4) %>%
  html_table(fill = TRUE)

x <- text %>%
  str_split("\n") %>%
  extract2(1) %>%
  str_trim() %>%
  na_if("") %>%
  na.omit() %>%
  as.vector()

x <- x[str_which(x, "Confirmation number"):str_which(x, "Section E")-1]

confirm_num = str_remove(x[1], "(.*):\\s")
confirm_type = str_remove(x[2], "(.*):\\s")
start_date = str_remove(x[10], "(.*):\\s")

biz <- list(
  biz_name = x[str_which(x, "1. Full legal name of employer lobbyist:") + 1],
  biz_type = x[str_which(x, "2. Type of business:") + 1],
  biz_addr = x[
    seq(
      from = str_which(x, "3. Complete business address:") + 1,
      to = str_which(x, "4. Business phone number and email:") - 1
    )
    ],
  biz_phone = x[str_which(x, "4. Business phone number and email:") + 1]
)

y <- "/html/body/div/center/table/tbody/tr/td/table[2]/tbody/tr[21]/td/table"
html %>%
  html_nodes(xpath = y)

items <- as.vector(t(html_table(html_node(html, css))))
checks <- x %>%
  html_node(xpath = y) %>%
  html_nodes("img") %>%
  as.character() %>%
  str_which("no_ptaszek", negate = TRUE)

subjects <- items[checks]

# -------------------------------------------------------------------------

x <- read_html("~/Desktop/Lobbyist Employer Registration.html")
y <- "/html/body/div/center/table/tbody/tr/td/table[2]/tbody/tr[17]/td/table/tbody/tr[1]/td/table"

items <- as.vector(t(html_table(html_node(x, xpath = y))))
checks <- x %>%
  html_node(xpath = y) %>%
  html_nodes("img") %>%
  as.character() %>%
  str_which("no_ptaszek", negate = TRUE)

subjects <- items[checks]

