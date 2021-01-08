# Kiernan Nicholls
# Fix the misspelled city names in WA Contributions
# Using OpenRefine alogrithm in R
# Manually confirm changes before join

pacman::p_load(refinr)

### Run docs/wa_diary.Rmd to make prelim changes

# create a table of fixed records ------------------------------------------------------------

wa_city_fix <- wa %>%
  # prepare for refine by removing common nonsense
  mutate(city_prep = city_clean %>%
           # regex matches surrounded by start, space, or end
           str_remove_all("(^|\\b)WA(\\b|$)") %>%
           str_remove_all("(^|\\b)OR(\\b|$)") %>%
           str_remove_all("(^|\\b)ID(\\b|$)") %>%
           str_remove_all("(^|\\b)BC(\\b|$)") %>%
           str_remove_all("(^|\\b)W(\\b|$)") %>%
           str_remove_all("(^|\\b)N(\\b|$)") %>%
           str_remove_all("(^|\\b)NORTH(\\b|$)") %>%
           str_remove_all("(^|\\b)SOUTH(\\b|$)") %>%
           str_remove_all("(^|\\b)EAST(\\b|$)") %>%
           str_remove_all("(^|\\b)WEST(\\b|$)") %>%
           str_remove_all("[:punct:]") %>%
           str_remove_all("\\d+") %>%
           str_trim()) %>%
  # fix spelling with openrefine algorithm
  mutate(city_fix = city_prep %>% key_collision_merge() %>% n_gram_merge()) %>%
  # create logical change variable
  mutate(fixed = city_prep != city_fix) %>%
  # keep only changed records
  filter(fixed) %>%
  # grou by fixes
  arrange(city_fix) %>%
  rename(city_original = city_clean) %>%
  select(
    id,
    address_clean,
    state_clean,
    zip5_clean,
    city_original, # original
    city_prep, # prepared
    city_fix # refined
  )

sample_n(wa_city_fix, 10)

# number of changes made
nrow(wa_city_fix)
# reducing distinct values in half
n_distinct(wa_city_fix$city_original)
n_distinct(wa_city_fix$city_fix)

# split up fixes -----------------------------------------------------------------------------

# this data set contains all zips with city and state
data("zipcode")
zipcode <- zipcode %>%
  as_tibble() %>%
  mutate(city = str_to_upper(city)) %>%
  select(city, state, zip)

n_distinct(zipcode$zip)
# there are only 20000 US cities and 16000 townships (USCB)
n_distinct(zipcode$city) # this data set good start

# good fixes, with correct spelled city AND matching state + zip
good_fix <- wa_city_fix %>%
  ungroup() %>%
  select(-id, -address_clean) %>%
  distinct() %>%
  inner_join(
    y = zipcode,
    by = c(
      "zip5_clean" = "zip",
      "city_fix" = "city",
      "state_clean" = "state"
    )
  )

nrow(good_fix)

# changes where fix doesn't match with a city, state + zip combo
# these changes need to be dobule-checked before accepting w/ join
bad_fix <- wa_city_fix %>%
  ungroup() %>%
  select(-id, -address_clean) %>%
  distinct() %>%
  anti_join(
    y = zipcode,
    by = c(
      "zip5_clean" = "zip",
      "city_fix" = "city",
      "state_clean" = "state"
    )
  )

nrow(bad_fix)

# add in the city for the original zip to compare
bad_fix_zip_match <- bad_fix %>%
  left_join(zipcode, by = c("zip5_clean" = "zip")) %>%
  drop_na() %>%
  rename(
    city_real = city,
    state_real = state
  ) %>%
  select(
    zip5_clean,
    state_clean,
    state_real,
    city_original,
    city_prep,
    city_fix,
    city_real
  )

sample_n(bad_fix_zip_match, 10)
n_distinct(bad_fix_zip_match$city_fix)

# correct bad fixes --------------------------------------------------------------------------

bad_fix_zip_match$city_fix <- bad_fix_zip_match$city_fix %>%
  str_replace_all("^ADELPHI$", "PHILADELPHIA") %>%
  str_replace_all("^ANANCORTES$", "ANACORTES") %>%
  str_replace_all("^ABBOT PARK ROAD$", "ABBOT PARK") %>%
  str_replace_all("^AINBRIDGE ISLAND$", "BAINBRIDGE ISLAND") %>%
  str_replace_all("^ARLINGTON HTS$", "ARLINGTON HEIGHTS") %>%
  str_replace_all("^ACCOMAC$", "TACOMA") %>%
  str_replace_all("^ALSEA$", "SEATTLE") %>%
  str_replace_all("^ARLETA$", "ARLETTA") %>%
  str_replace_all("^AUBUR$", "AUBURN") %>%
  str_replace_all("^ALLENDALE$", "ELLENDALE") %>%
  str_replace_all("^BELLEVILLE$", "BELLEVUE") %>%
  str_replace_all("^BOTELL$", "BOTHELL") %>%
  str_replace_all("^BAINBRIDGE$", "BAINBRIDGE ISLAND") %>%
  str_replace_all("^BAINBRIDGE ISL$", "BAINBRIDGE ISLAND") %>%
  str_replace_all("^BATTLE GROUD$", "BATTLE GROUND") %>%
  str_replace_all("^BATTLE GROUNE$", "BATTLE GROUND") %>%
  str_replace_all("^BATTLE GROUNF$", "BATTLE GROUND") %>%
  str_replace_all("^BATTLE GROUNF$", "BATTLE GROUND") %>%
  str_replace_all("^BATTLE RGROUND$", "BATTLE GROUND") %>%
  str_replace_all("^BATTLE GORUND$", "BATTLE GROUND") %>%
  str_replace_all("^BATTLE GOUND$", "BATTLE GROUND") %>%
  str_replace_all("^BELLINGHAM WA$", "BELLINGHAM") %>%
  str_replace_all("^BELLINGHAM 98225$", "BELLINGHAM") %>%
  str_replace_all("^BELLINGHAN$", "BELLINGHAM") %>%
  str_replace_all("^BELLINGHMA$", "BELLINGHAM") %>%
  str_replace_all("^BELINGHAM$", "BELLINGHAM") %>%
  str_replace_all("^BELKINGHAM$", "BELLINGHAM") %>%
  str_replace_all("^BREMERETON$", "BREMERTON") %>%
  str_replace_all("^BREMERTOM$", "BREMERTON") %>%
  str_replace_all("^BRMERTON$", "BREMERTON") %>%
  str_replace_all("^BELFAIR$", "BELLAIRE") %>%
  str_replace_all("^BURREN$", "BURIEN") %>%
  str_replace_all("^BELLEVEU$", "BELLEVUE") %>%
  str_replace_all("^BELLEVUE ISLADN$", "BELLEVUE ISLAND") %>%
  str_replace_all("^BELLEVUE ISLANE$", "BELLEVUE ISLAND") %>%
  str_replace_all("^BELLVUE$", "BELLEVUE") %>%
  str_replace_all("^BELVIEW$", "BELLEVUE") %>%
  str_replace_all("^BENNETT$", "BENNET") %>%
  str_replace_all("^BRUSH PRAIRE$", "BRUSH PRAIRIE") %>%
  str_replace_all("^BUCKEY$", "BUCKEYE") %>%
  str_replace_all("^CALABASAS HILL$", "CALABASAS HILLS") %>%
  str_replace_all("^CENTRAILA$", "CENTRALIA") %>%
  str_replace_all("^CHEWLAH$", "CHEWELAH") %>%
  str_replace_all("^CLE EUM$", "CLE ELUM") %>%
  str_replace_all("^DE SOTO$", "DESOTO") %>%
  str_replace_all("^DELAND$", "LANDER") %>%
  str_replace_all("^DENTON$", "ODENTON") %>%
  str_replace_all("^DOW$", "WOODINVILLE") %>%
  str_replace_all("^EATTLE$", "SEATTLE") %>%
  str_replace_all("^ELBE$", "BELL") %>%
  str_replace_all("^EDMONS$", "EDMONDS") %>%
  str_replace_all("^EL MONTE$", "ELMONT") %>%
  str_replace_all("^ELLEVUE$", "BELLEVUE") %>%
  str_replace_all("^MERCER$", "BELLEVUE") %>%
  str_replace_all("^ESAT WENATCHEE$", "WENATCHEE") %>%
  str_replace_all("^EVWERETT$", "EVERETT") %>%
  str_replace_all("^FIRCEST$", "FIRCREST") %>%
  str_replace_all("^FIRECREST$", "FIRCREST") %>%
  str_replace_all("^FRIDAY HARBRO$", "FRIDAY HARBOR") %>%
  str_replace_all("^FRRIDAY$", "FRIDAY HARBOR") %>%
  str_replace_all("^GG HARBOR$", "GIG HARBOR") %>%
  str_replace_all("^GI HARBOR$", "FRIDAY HARBOR") %>%
  str_replace_all("^GIG HARBORT$", "FRIDAY HARBOR") %>%
  str_replace_all("^GIG HARBORW$", "FRIDAY HARBOR") %>%
  str_replace_all("^GIG HORBOR$", "FRIDAY HARBOR") %>%
  str_replace_all("^GIG HARBORT$", "FRIDAY HARBOR") %>%
  str_replace_all("^GLENDALE$", "GLENN DALE") %>%
  str_replace_all("^GREEANACES$", "GREENACRES") %>%
  str_replace_all("^HASLET$", "HASLETT") %>%
  str_replace_all("^ISAAQUAH$", "ISSAQUAH") %>%
  str_replace_all("^ITHICA$", "ITHACA") %>%
  str_replace_all("^KEMORE$", "KENMORE") %>%
  str_replace_all("^KENNEWID$", "KENNEWICK") %>%
  str_replace_all("^KENNWICK$", "KENNEWICK") %>%
  str_replace_all("^KILLEEN$", "KILLEN") %>%
  str_replace_all("^KINGTSON$", "KINGSTON") %>%
  str_replace_all("^KIRKAND$", "KIRKLAND") %>%
  str_replace_all("^KIRKAND$", "KIRKLAND") %>%
  str_replace_all("^KIRLAND$", "KIRKLAND") %>%
  str_replace_all("^LA CONNOR$", "LA CONNER") %>%
  str_replace_all("^LA GRANGE$", "LAGRANGE") %>%
  str_replace_all("^LAK STEVES$", "LAKE STEVENS") %>%
  str_replace_all("^LAKE FOREST PK$", "LAKE FOREST PARK") %>%
  str_replace_all("^LAKERIDGE$", "LAKE RIDGE") %>%
  str_replace_all("^LANTANA$", "ATLANTA") %>%
  str_replace_all("^LENOX$", "LENNOX") %>%
  str_replace_all("^LYNMWOOD$", "LYNNWOOD") %>%
  str_replace_all("^LYNNWOO$", "LYNNWOOD") %>%
  str_replace_all("^LYNNWOODD$", "LYNNWOOD") %>%
  str_replace_all("^MALVERN$", "MALVERNE") %>%
  str_replace_all("^MAPLY VALLEY$", "MAPLE VALLEY") %>%
  str_replace_all("^MECER ISLAND$", "MERCER ISLAND") %>%
  str_replace_all("^MED$", "MEAD") %>%
  str_replace_all("^MEDIANA$", "MEDINA") %>%
  str_replace_all("^MERCER ISLADN$", "MERCER ISLAND") %>%
  str_replace_all("^ERCER ISLAND$", "MERCER ISLAND") %>%
  str_replace_all("^MERCER ISLANE$", "MERCER ISLAND") %>%
  str_replace_all("^MERICER ISLAND$", "MERCER ISLAND") %>%
  str_replace_all("^MONTLAKE TERRACE$", "MOUNTLAKE TERRACE") %>%
  str_replace_all("^MOSE LAKE$", "MOOSE LAKE") %>%
  str_replace_all("^MOUNTLAKE TER$", "MOUNTLAKE TERRACE") %>%
  str_replace_all("^MOUNTLAKE TERRANCE$", "MOUNTLAKE TERRACE") %>%
  str_replace_all("^MT LAKE TERRACE$", "MOUNTLAKE TERRACE") %>%
  str_replace_all("^MT LK TERRACE$", "MOUNTLAKE TERRACE") %>%
  str_replace_all("^MIRMAR$", "MIRAMAR") %>%
  str_replace_all("^MUKITEO$", "MUKILTEO") %>%
  str_replace_all("^MUKILTE$", "MUKILTEO") %>%
  str_replace_all("^MNT VERNON$", "MOUNT VERNON") %>%
  str_replace_all("^MUKILTE$", "MUKILTEO") %>%
  str_replace_all("^MONRE$", "MONROE") %>%
  str_replace_all("^MOOSE LAKE$", "MOSE LAKE") %>%
  str_replace_all("^MOUNTLAKE TERRACERACE$", "MOUNTLAKE TERRACE") %>%
  str_replace_all("^MT VERNON$", "MOUNT VERNON") %>%
  str_replace_all("^MUKILTEOO$", "MUKILTEO") %>%
  str_replace_all("^NE TH AVE$", "SEATTLE") %>%
  str_replace_all("^NEW BERN$", "NEWBERN") %>%
  str_replace_all("^NEW MARKET$", "NEWMARKET") %>%
  str_replace_all("^OLLALA$", "OLALLA") %>%
  str_replace_all("^OLYMPAIA$", "OLYMPIA") %>%
  str_replace_all("^ORTIN$", "ORTING") %>%
  str_replace_all("^O FALLON$", "FALLON") %>%
  str_replace_all("^OAK HARBOE$", "OAK HARBOR") %>%
  str_replace_all("^OCEAN$", "OCEANO") %>%
  str_replace_all("^OKANOGNA$", "OKANOGAN") %>%
  str_replace_all("^OLYMPAI$", "OLYMPIA") %>%
  str_replace_all("^OLYMPIAQ$", "OLYMPIA") %>%
  str_replace_all("^ONLASKA$", "ONALASKA") %>%
  str_replace_all("^ORONDA$", "RONDA") %>%
  str_replace_all("^OUNT VERNON$", "MOUNT VERNON") %>%
  str_replace_all("^OUYALLUP$", "PUYALLUP") %>%
  str_replace_all("^OVERLAND PARK KS$", "OVERLAND PARK") %>%
  str_replace_all("^OYMPIA$", "OLYMPIA") %>%
  str_replace_all("^PACCO$", "PASCO") %>%
  str_replace_all("^PACIFIC$", "PACIFICA") %>%
  str_replace_all("^PHILADEPHIA$", "PHILADELPHIA") %>%
  str_replace_all("^PHILIDELPHIA$", "PHILADELPHIA") %>%
  str_replace_all("^PT HADLOCK$", "PORT HADLOCK") %>%
  str_replace_all("^PT ROBERTS$", "POINT ROBERTS") %>%
  str_replace_all("^PUALLUP$", "PUYALLUP") %>%
  str_replace_all("^PULLALLUP$", "PUYALLUP") %>%
  str_replace_all("^PULSBO$", "POULSBO") %>%
  str_replace_all("^RAINER$", "RAINIER") %>%
  str_replace_all("^RANDALL$", "RANDLE") %>%
  str_replace_all("^REDMONDQ$", "REDMOND") %>%
  str_replace_all("^REDONDO$", "REDMOND") %>%
  str_replace_all("^RENTON$", "TRENTON") %>%
  str_replace_all("^RENO$", "RENTON") %>%
  str_replace_all("^RENTEN$", "RENTON") %>%
  str_replace_all("^RIIDGEFIELD PARK$", "RIDGEFIELD PARK") %>%
  str_replace_all("^SAEATTLE$", "SEATTLE") %>%
  str_replace_all("^SAETTLE$", "SEATTLE") %>%
  str_replace_all("^SEATRLE$", "SEATTLE") %>%
  str_replace_all("^SEATTE$", "SEATTLE") %>%
  str_replace_all("^SEATTEL$", "SEATTLE") %>%
  str_replace_all("^SEATTLED$", "SEATTLE") %>%
  str_replace_all("^SEATTLEW$", "SEATTLE") %>%
  str_replace_all("^SEATTLTE$", "SEATTLE") %>%
  str_replace_all("^SETTLE$", "SEATTLE") %>%
  str_replace_all("^SECRO WOOLLEY$", "SEDRO WOOLLEY") %>%
  str_replace_all("^SEDR WOOLEY$", "SEDRO WOOLLEY") %>%
  str_replace_all("^SEDRO WOOLLEE$", "SEDRO WOOLLEY") %>%
  str_replace_all("^SEDRO WOOLLELY$", "SEDRO WOOLLEY") %>%
  str_replace_all("^SENDROWOOLLEY$", "SEDRO WOOLLEY") %>%
  str_replace_all("^SNOHMISH$", "SNOHOMISH") %>%
  str_replace_all("^SNOQUALIE$", "SNOQUALMIE") %>%
  str_replace_all("^SNOQUALMI$", "SNOQUALMIE") %>%
  str_replace_all("^SPANAWY$", "SPANAWAY") %>%
  str_replace_all("^SPOKAN$", "SPOKANE") %>%
  str_replace_all("^SPRING$", "COLORADO SPRINGS") %>%
  str_replace_all("^SS$", "SEATTLE") %>%
  str_replace_all("^ST", "SAINT") %>%
  str_replace_all("^STEILCOOM$", "STEILACOOM") %>%
  str_replace_all("^TH AVE$", "GRAHAM") %>%
  str_replace_all("^TUCKWILA$", "TUKWILA") %>%
  str_replace_all("^VACOUVER$", "VANCOUVER") %>%
  str_replace_all("^VALANCI$", "VALENCIA") %>%
  str_replace_all("^VALLEY CENTER$", "CENTER VALLEY") %>%
  str_replace_all("^VANCOUVE$", "VANCOUVER") %>%
  str_replace_all("^VANCOUVR$", "VANCOUVER") %>%
  str_replace_all("^VNCOUVER$", "VANCOUVER") %>%
  str_replace_all("^WENACHEE$", "WENATCHEE") %>%
  str_replace_all("^WOODINVILE$", "WOODINVILLE") %>%
  na_if("WWW") %>%
  na_if("XXX") %>%
  na_if("ANONYMOUS")

city_fix_table <- bad_fix_zip_match %>%
  select(state_clean, zip5_clean, city_original, city_fix) %>%
  bind_rows(good_fix %>% select(-city_prep)) %>%
  rename(city_clean = city_original) %>%
  arrange(city_fix)

rm(bad_fix, good_fix, wa_city_fix, bad_fix_zip_match)
