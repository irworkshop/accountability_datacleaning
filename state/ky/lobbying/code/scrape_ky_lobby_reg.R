library(tidyverse)
library(textreadr)
lob_url <- "https://klec.ky.gov/Reports/Reports/Agents.rtf"


kylr <- read_rtf(file = lob_url)

df <- kylr %>%
  enframe(name = "line", value = "text") %>%
  slice(-c(1:3)) %>%
  separate(
    col = text,
    into = c("name", "phone", "contact", "address"),
    sep = "\t"
  )

indent <- which(is.na(df$address))

df <- mutate(df, address = coalesce(address, contact))
df$contact[indent] <- NA

df <- df %>%
  mutate(
    lob_name = if_else(
      condition = is.na(contact),
      true = name,
      false = NA_character_
    ),
    lob_phone = if_else(
      condition = is.na(contact),
      true = phone,
      false = NA_character_
    ),
    lob_address = if_else(
      condition = is.na(contact),
      true = address,
      false = NA_character_
    )
  ) %>%
  fill(starts_with("lob")) %>%
  mutate_if(is_character, str_trim) %>%
  filter(!is.na(contact)) %>%
  rename(
    pri_name = name,
    pri_phone = phone,
    pri_contact = contact,
    pri_address = address
  ) %>%
  select(
    starts_with("lob"),
    starts_with("pri")
  ) %>%
  select(lob_address) %>%
  separate(
    col = lob_address,
    into = c("lob_org", "lob_addr1", "lob_addr2", "lob_extra"),
    sep = ",\\s",
    fill = "left",
    extra = "merge"
  ) %>%
  na_if("") %>%
  unite(
    starts_with("lob_addr"),
    col = "lob_addr",
    na.rm = TRUE
  ) %>%
  separate(
    col = lob_extra,
    into = c("lob_city_state", "lob_zip"),
    sep = "\\s(?=\\d)",
    fill = "left",
    extra = "merge"
  ) %>%
  separate(
    col = lob_city_state,
    into = c("lob_city", "lob_state"),
    sep = "\\s(?=[:upper:]{2})",
    fill = "left",
    extra = "merge"
  ) %>%
  distinct() %>%
  sample_frac()
