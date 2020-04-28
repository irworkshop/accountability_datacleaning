# if not installed, use install.libraries("jsonlite") and such
# this website can't be scraped directly because it's powered by JS and loaded dynamically when we visit the URL
#jsonlite is the library accessing and transforming json data into R objects like dfs.
library(jsonlite)
# you'll use the network tool from the "developer tool" in Chrome and its counterparts like Firefox and such.
# look for XHR (XML HTTP Request) and you'll see this file that is most likely the stuff we're looking for
json_url <- "https://data.vermont.gov/api/views/69uf-6qeu.json"
# convert raw json to a list
json_list <- fromJSON(json_url)
# the useful meta data about the table is from JSON
json_cols <- json_list$columns
# get the second to 6th columns of this dictionary
dictionary <- json_cols[,2:6]
# kable will convert df to markdown tables
kable(dictionary)
