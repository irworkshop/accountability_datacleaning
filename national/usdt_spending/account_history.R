library(tidyverse)
library(jsonlite)
library(httr)

# FY2020Q1-P12_All_FA_AccountBreakdownByAward_2021-05-13_H14M44S47380097.zip

a_post <- POST(
  user_agent("https://publicaccountability.org/"), # identify to server
  url = "https://api.usaspending.gov/api/v2/download/accounts/",
  encode = "json", # send post body as json
  body = list(
    account_level = "treasury_account", 
    filters = list(
      budget_function = "all", 
      agency = "all", 
      submission_types = I("award_financial"), 
      fy = "2020", 
      period = "12"
    ),
    # CSV with double escape
    # can also be TSV or PIPE
    file_format = "csv"
  )
)

content(a_post)
