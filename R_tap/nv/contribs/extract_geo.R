## Extract a tibble of geographic information from an NVSOS C&E report HTML page
extract_geo <- function(html) {

  nv <- xml2::read_html(html)

  table_col_one <- nv %>%
    html_node("#ctl04_mobjContributions_dgContributions") %>%
    html_nodes(".CUserData") %>%
    html_nodes("td:nth-child(1)")

  name <- html_text(html_nodes(table_col_one, "a"))
  geo <- nv %>%
    html_node("#ctl04_mobjContributions_dgContributions") %>%
    html_nodes(".CUserData") %>%
    as.character() %>%
    str_extract_all("(?<=<br>).*(?=<)", simplify = TRUE) %>%
    str_subset(".") %>%
    str_replace_all("<br>", "~") %>%
    str_replace_all("~(?=.*~)", " ")

  name_geo <- extract(
    data = tibble(name, geo),
    col = geo,
    into = c("addr", "city", "state", "zip"),
    regex = "(.*)~(.*), (\\w{2}) (\\d+)"
  )

  nv %>%
    html_node("#ctl04_mobjContributions_dgContributions") %>%
    html_table(fill = TRUE, header = TRUE) %>%
    set_names(nm = letters[1:12]) %>%
    as_tibble() %>%
    filter(!stringr::str_detect(a, "\\d{2}/\\d{2}/\\d{4}$")) %>%
    filter(!stringr::str_detect(a, "\\$")) %>%
    mutate(
      b = base::ifelse(
        test = stringr::str_length(b) > 10,
        yes = c,
        no = b
      ) %>% readr::parse_date("%m/%d/%Y"),
      c = base::ifelse(
        test = !stringr::str_detect(c, "\\$"),
        yes = f,
        no = c
      ) %>% readr::parse_number()
    ) %>%
    select(b, c) %>%
    set_names(c("date", "amount"))

  df <- geo %>%
    dplyr::mutate(name = names) %>%
    dplyr::mutate_if(is.character, str_to_upper) %>%
    dplyr::select(name, address, city, state, zip) %>%
    tidyr::drop_na() %>%
    dplyr::bind_cols(date_amount)

  return(df)
}
