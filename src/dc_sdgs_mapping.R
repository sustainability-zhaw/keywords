library(plumber)

`%>%` = magrittr::`%>%` 

# host <- "/Users/bajk/documents/Github/sustainability/"
# repo <- "keywords/"

# setwd(stringr::str_c(host, repo))
wd = getwd()
setwd(..)

#* @get /wd
#* @param workdir
function(workdir=wd) {
  return(workdir)
}

# config <- yaml::read_yaml(stringr::str_c(wd, "/config.yml"))