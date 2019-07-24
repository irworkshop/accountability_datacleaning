## Extract a tibble of geographic information from an NVSOS C&E report HTML page
extract_geo <- function(html) {

  nv <- xml2::read_html(html)

  table_col_one <- nv %>%
    rvest::html_node("#ctl04_mobjContributions_dgContributions") %>%
    rvest::html_nodes(".CUserData") %>%
    rvest::html_nodes("td:nth-child(1)") %>%
    base::as.character()

  names <- table_col_one %>%
    str_extract(">(.*?)</a>") %>%
    str_remove(">") %>%
    str_remove("</a>") %>%
    str_replace("&amp;", "&")

  geo <- table_col_one %>%
    stringr::str_extract("<br>(.*?)</td>") %>%
    stringr::str_remove("<br>") %>%
    stringr::str_remove("</td>") %>%
    stringr::str_replace("<br>(.*?)<br>", "<br>") %>%
    tibble::enframe(NULL) %>%
    tidyr::separate(value, c("address", "city_state_zip"), "<br>") %>%
    tidyr::separate(city_state_zip, c("city", "state_zip"), ",\\s") %>%
    tidyr::separate(state_zip, c("state", "zip"), "\\s")

  date_amount <- nv %>%
    rvest::html_node("#ctl04_mobjContributions_dgContributions") %>%
    rvest::html_table(fill = TRUE, header = TRUE) %>%
    tibble::as_tibble(.name_repair = "unique") %>%
    magrittr::set_names(letters[1:(length(.))]) %>%
    dplyr::filter(!stringr::str_detect(a, "../../....$")) %>%
    dplyr::filter(!stringr::str_detect(a, "\\$")) %>%
    dplyr::mutate(
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
    dplyr::select(b, c) %>%
    magrittr::set_names(c("date", "amount"))

  df <- geo %>%
    dplyr::mutate(name = names) %>%
    dplyr::mutate_if(is.character, str_to_upper) %>%
    dplyr::select(name, address, city, state, zip) %>%
    tidyr::drop_na() %>%
    dplyr::bind_cols(date_amount)

  return(df)
}
