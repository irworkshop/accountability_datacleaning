library(tidyverse)
library(rvest)
library(httr)
library(fs)

# get years from form -----------------------------------------------------

apoc <- "https://aws.state.ak.us/ApocReports/CampaignDisclosure/CDIncome.aspx"
cd_search <- GET(apoc)
cd_years <- content(cd_search) %>%
  html_node("#M_C_sCDTransactions_csfFilter_ddlReportYear") %>%
  html_nodes("option") %>%
  html_text(trim = TRUE) %>%
  str_subset("\\d") %>%
  parse_integer()

rpt_year <- cd_years[13] # 2011

# search for contributions ------------------------------------------------

ak_search <- POST(
  url = apoc,
  set_cookies(ASP.NET_SessionId = "mcrv2jo1nx3tfwfnjvns3zwj"),
  encode = "form",
  body = list(
    `M$ctl19` = "M$UpdatePanel|M$C$sCDTransactions$csfFilter$btnSearch",
    `M$C$sCDTransactions$csfFilter$ddlNameType` = "CandidateName",
    `M$C$sCDTransactions$csfFilter$ddlField` = "IncomeTypes",
    `M$C$sCDTransactions$csfFilter$ddlReportYear` = "2011",
    `M$C$sCDTransactions$csfFilter$ddlStatus` = "Complete",
    `M$C$sCDTransactions$csfFilter$txtBeginDate` = "",
    `M$C$sCDTransactions$csfFilter$txtEndDate` = "",
    `M$C$sCDTransactions$csfFilter$txtName` = "",
    `M$C$sCDTransactions$csfFilter$ddlValue` = "-1",
    M_C_sCDTransactions_grid_rghcMenu_ClientState = "",
    M_C_sCDTransactions_grid_ClientState = "",
    `__EVENTTARGET` = "",
    `__EVENTARGUMENT` = "",
    `__LASTFOCUS` = "",
    `__VIEWSTATE` = "",
    `__VIEWSTATEGENERATOR` = "74D64E26",
    `__ASYNCPOST` = "true",
    `M$C$sCDTransactions$csfFilter$btnSearch` = "Search"
  )
)

# export contributions ----------------------------------------------------

ak_export <- POST(
  url = apoc,
  set_cookies(ASP.NET_SessionId = "mcrv2jo1nx3tfwfnjvns3zwj"),
  encode = "form",
  body = list(
    `M$ctl19` = "M$UpdatePanel|M$C$sCDTransactions$csfFilter$btnExport",
    `M$C$sCDTransactions$csfFilter$ddlNameType` = "CandidateName",
    `M$C$sCDTransactions$csfFilter$ddlField` = "IncomeTypes",
    `M$C$sCDTransactions$csfFilter$ddlReportYear` = "2011",
    `M$C$sCDTransactions$csfFilter$ddlStatus` = "Complete",
    `M$C$sCDTransactions$csfFilter$txtBeginDate` = "",
    `M$C$sCDTransactions$csfFilter$txtEndDate` = "",
    `M$C$sCDTransactions$csfFilter$txtName` = "",
    `M$C$sCDTransactions$csfFilter$ddlValue` = "-1",
    `M$C$sCDTransactions$grid$ctl00$ctl03$ctl01$PageSizeComboBox` = "20",
    `M_C_sCDTransactions_grid_ctl00_ctl03_ctl01_PageSizeComboBox_ClientState` = "",
    `M_C_sCDTransactions_grid_rghcMenu_ClientState` = "",
    `M_C_sCDTransactions_grid_ClientState` = "",
    `__EVENTTARGET` = "",
    `__EVENTARGUMENT` ="",
    `__LASTFOCUS` ="",
    `__VIEWSTATE` = "",
    `__VIEWSTATEGENERATOR` = "74D64E26",
    `__ASYNCPOST` = "true",
    `M$C$sCDTransactions$csfFilter$btnExport` = "Export"
  )
)

# save export as tsv ------------------------------------------------------

tmp <- file_temp(ext = "TXT")
ak_save <- GET(
  url = apoc,
  write_disk(path = tmp),
  progress(type = "down"),
  query = list(
    exportAll = "True",
    exportFormat = "TXT",
    isExport = "True",
    pageSize = "20",
    pageIndex = "0"
  )
)

file_size(tmp)
