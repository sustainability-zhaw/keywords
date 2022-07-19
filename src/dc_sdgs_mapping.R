library(plumber)

`%>%` = magrittr::`%>%` 

# host <- "/Users/bajk/documents/Github/sustainability/"
# repo <- "keywords/"

# setwd(stringr::str_c(host, repo))
# setwd(stringr::str_c(getwd(), "../")
# wd = here::here()
wd = here::set_here(path='..')
# wd = getwd()

#* @get /wd
#* @param workdir
function(workdir=wd) {
  # s = stringr::str_c("../", getwd(), "/config.yml")
  # s = stringr::str_c(workdir, "/config.yml")
  return(workdir)
}

# config <- yaml::read_yaml(stringr::str_c(wd, "../config.yml"))