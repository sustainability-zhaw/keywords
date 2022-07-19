library(plumber)

`%>%` = magrittr::`%>%` 

# host <- "/Users/bajk/documents/Github/sustainability/"
# repo <- "keywords/"

setwd('..')
wdir = getwd()

#* @get /wd
#* @param workdir
function(workdir=wdir) {
  # s = stringr::str_c("../", getwd(), "/config.yml")
  # s = stringr::str_c(workdir, "/config.yml")
  return(workdir)
}

# config <- yaml::read_yaml(stringr::str_c(wd, "/config.yml"))

#* @get /conf
#* @param wd
function(wd=wdir) {
  # s = stringr::str_c(wd, "/config.yml")
  # s = yaml::read_yaml(stringr::str_c(wd, "/config.yml"))
  return(wd)
}