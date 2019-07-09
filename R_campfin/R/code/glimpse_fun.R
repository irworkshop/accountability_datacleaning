glimpse_fun <- function(data, fun) {
  data %>%
    map(fun) %>%
    unlist() %>%
    enframe(name = "var", value = "n") %>%
    mutate(p = n / nrow(data)) %>%
    mutate(type = format(map(data, pillar::new_pillar_type))) %>%
    select(var, type, n, p) %>%
    print(n = length(data))
}

count_na <- function(x) {
  sum(is.na(x))
}
