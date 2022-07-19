library(plumber)
library(qpcR)

`%>%` = magrittr::`%>%` 

host <- "/Users/bajk/documents/Github/sustainability/"
repo <- "dc_test/"

setwd(stringr::str_c(host, repo))
wd = getwd()

config <- yaml::read_yaml(stringr::str_c(wd, "/config.yml"))

# 
#* @get /hello
function() {
  return("Hello World2")
}


#* @get /config
function() {
  return("config")
}

#* @get /wd
#* @param workdir
function(workdir = getwd()) {
  return(workdir)
}

#* @get /wdir
#* @param workdir
function(workdir = wd) {
  return(workdir)
}
