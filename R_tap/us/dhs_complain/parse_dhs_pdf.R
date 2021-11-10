# Kiernan Nicholls
# Investigative Reporting Workshop
# Thu Oct 28 16:07 2021

library(tidyverse)
library(pdftools)
library(campfin)

# Functions ---------------------------------------------------------------

# combine strings sep by space
back_concat <- function(dat) {
  i <- 1
  while (i < nrow(dat)) {
    if (dat$space[i]) {
      dat$text[i] <- paste(dat$text[i], dat$text[i + 1])
      dat <- dat[-(i + 1), ]
    }
    i <- i + 1
  }
  return(dat)
}

# Read PDF ----------------------------------------------------------------

# read the entire pdf as a list of data frames by page
all_pg <- pdf_data("~/Documents/2021-CRFO-00058 - Interim Records 1.pdf")

pg <- all_pg[[1]]

# trim header
pg <- pg[pg$y > 64, ]

# Row ---------------------------------------------------------------------

# find the "Row" numbers in the leftmost column
border_char <- c("L__", "I", "'")
pg_row <- pg[pg$x < 60 * pg$text %out% border_char, ]
pg_row <- pg_row[order(pg_row$y), ]

# save each row start height
y <- pg_row$y

pg_row <- as.integer(pg_row$text)

# Number ------------------------------------------------------------------

# find and combine complaint ID number
pg_num <- pg[pg$x == 63, ]
pg_num <- paste0(pg_num$text[pg_num$width == 15], pg_num$text[pg_num$width == 7])

# Master Complaint Number -------------------------------------------------


# Investigation Type ------------------------------------------------------

pg_type <- pg[between(pg$x, 123, 132), ]
pg_type <- paste(pg_type$text[pg_type$space], pg_type$text[!pg_type$space])

# Current Activity --------------------------------------------------------

pg_act <- pg[between(pg$x, 155, 164), ]
pg_act <- back_concat(pg_act)

out <- character(length(y))
for (i in seq_along(y)) {
  if (y[i] != max(y)) {
    which_y <- pg_act$y >= y[i] & pg_act$y < y[i + 1]
  } else {
    which_y <- pg_act$y >= y[i]
  }

  out[i] <- paste(pg_act$text[y_betwix], collapse = " ")
}

# Last Activity Date ------------------------------------------------------


# Closed ------------------------------------------------------------------


# Method of Receipt -------------------------------------------------------


# Source ------------------------------------------------------------------


# Date to DHS -------------------------------------------------------------


# Date to CRCL ------------------------------------------------------------


# Summary of Allegation ---------------------------------------------------


# Component Referenced ----------------------------------------------------


# Components Involved -----------------------------------------------------


# Special Process ---------------------------------------------------------


# Special Process Type ----------------------------------------------------


# Complaint Issue ---------------------------------------------------------


# Issue Basis -------------------------------------------------------------


# Situation ---------------------------------------------------------------


# Situation Basis ---------------------------------------------------------


# Incident Location -------------------------------------------------------


# Incident Date -----------------------------------------------------------


# City --------------------------------------------------------------------


# State -------------------------------------------------------------------


