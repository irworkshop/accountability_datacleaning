raw_dir <- dir_create(here("state", "mo", "licenses", "data", "raw"))

GET2 <- function(url) {
  with_config(
    config = config(ssl_verifypeer = 0L),
    expr = GET(url = url)
  )
}

front_paste <- function(x, y, ...) {
  paste(y, x, ...)
}

type_list <- GET2("https://pr.mo.gov/listings.asp")

type_a <- type_list %>%
  content(as = "parsed", encoding = "UTF-8") %>%
  html_element("#main-content > table:nth-child(3)") %>%
  html_elements("a")

type_pg <- tibble(
  a = html_text(type_a),
  href = paste0("https://pr.mo.gov/", html_attr(type_a, "href"))
)

for (i in seq_along(type_pg$href)) {
  sub_pg <- GET2(type_pg$href[i])
  sub_url <- sub_pg %>%
    content(as = "parsed", encoding = "UTF-8") %>%
    html_elements("#main-content a") %>%
    html_attr("href") %>%
    str_subset("\\.ZIP$") %>%
    front_paste("https://pr.mo.gov", sep = "/")
  map(
    .x = sub_url,
    .f = function(x) {
      y <- path(raw_dir, basename(x))
      if (!file_exists(y)) {
        Sys.sleep(runif(1, 3, 5))
        download.file(
          url = x,
          destfile = y,
          method = "curl",
          extra = "--insecure"
        )
      } else {
        message("File already saved")
      }
    }
  )
}
