install.packages("zipcode")
library(tidyverse)
library(zipcode)
data("zipcode")
source("R/code/normalize_geo.R")

geo <-
  as_tibble(zipcode) %>%
  mutate(city= normalize_city(city)) %>%
  select(city, state, zip)

print(geo)

dir.create("R/data")
write_csv(geo, "R/data/geo.csv")
