library(plumber)

`%>%` = magrittr::`%>%` 

# host <- "/Users/bajk/documents/Github/sustainability/"
# repo <- "keywords/"

# setwd(stringr::str_c(host, repo))
wd = getwd()

config <- yaml::read_yaml(stringr::str_c(wd, "/config.yml"))