library(plumber)
# 
# library(ghql)
library(qpcR)

`%>%` = magrittr::`%>%` 

host <- "/Users/bajk/documents/Github/sustainability/"
repo <- "keywords/"

setwd(stringr::str_c(host, repo))
wd = getwd()

# wd <- ".."

config <- yaml::read_yaml(stringr::str_c(wd, "/config.yml")) 

#* @get /config
function() {
  return(config)
}

#* @get /wd
function() {
  return(wd)
}
