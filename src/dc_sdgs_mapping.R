library(plumber)

`%>%` = magrittr::`%>%` 

# host <- "/Users/bajk/documents/Github/sustainability/"
# repo <- "keywords/"

# setwd(stringr::str_c(host, repo))
# setwd(stringr::str_c(getwd(), "../")
# wd = here::here()
wd = here::set_here(path='..')

#* @get /wd
#* @param workdir
function(workdir=wd) {
  return(workdir)
}

config <- yaml::read_yaml(stringr::str_c(wd, "/config.yml"))#* @get /wd

#* @param cf
function(cf = config) {
  return(cf)
}