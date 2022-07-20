library(plumber)
# 
# library(ghql)
# library(qpcR)

`%>%` = magrittr::`%>%` 

# host <- "/Users/bajk/documents/Github/sustainability/"
# repo <- "dc_test/"

# setwd(stringr::str_c(host, repo))
# wd = getwd()

# wd <- ".."

setwd('..')
wd = getwd()

config <- yaml::read_yaml(stringr::str_c(wd, "/config.yml")) 

####################################################
#* @get /import_data
#* @param fconfig
function(fconfig = config){
  # import_data <- function(fconfig = config){
  fpath_transformed = fconfig$path$path_data_transformed
  ffiles_transformed = fconfig$pattern$files_transformed

  dc_prepared_data <-
    base::list.files(stringr::str_c(wd, fpath_transformed), ffiles_transformed) %>%
    stringr::str_c(stringr::str_c(wd, fpath_transformed), ., sep = .Platform$file.sep) %>%
    stringr::str_sort(decreasing = T) %>%
    .[[1]] %>%
    jsonlite::fromJSON(., flatten = FALSE) %>%
    dplyr::as_tibble() %>%
    dplyr::mutate(doc_id = seq.int(nrow(.))) %>%
    dplyr::ungroup() #%>%
    # utils::head(100)

  return(dc_prepared_data)
}

# # View(import_data())
# 

####################################################
#* @get /import_sdgs_from_git
#* @param sdg
#* @param list_with_posteriors
function(sdg = 1, list_with_posteriors = FALSE) {
# import_sdgs_from_git <- function(sdg = 1, list_with_posteriors = FALSE) {

  # sdg = 1
  # list_with_posteriors = FALSE

  # Loop over all sdgs
  prior_posterior_full_tibble <<-
    sdg %>%
    purrr::map(., function(x){
      # x = 1
      sdg_name <<- stringr::str_c("SDG", x)
      filename <- stringr::str_c("SDG", x, ".csv")
      if (list_with_posteriors == TRUE){
        type = "with_posterior"
      } else {
        type = "no_posterior"
      }
      RCurl::getURL(stringr::str_c("https://raw.githubusercontent.com/sustainability-zhaw/keywords/main/", type, "/", filename),
                    .encoding = "UTF-8") %>%
        read.csv(text = ., sep = ";", header = FALSE) %>%
        tidyr::as_tibble(.name_repair = "minimal")
    }) %>%
    do.call(rbind.data.frame, .)

    # extract priors, all languages and concatenate
    single_sdg_prior <-
      prior_posterior_full_tibble[,c(2,4,6,8)] %>%
      unlist() %>%
      stringr::str_replace_all("NA", "") %>%
      stringr::str_replace_na("") %>%
      stringr::str_replace_all("\\s{2,}", "") %>%
      stringr::str_trim(side = "both")%>%
      dplyr::tibble(prior = .)
    
    # extract posteriors, all languages and concatenate
    single_sdg_posterior <-
      prior_posterior_full_tibble[,c(3,5,7,9)] %>%
      unlist() %>%
      stringr::str_replace_all("NA", "") %>%
      stringr::str_replace_na("") %>%
      stringr::str_replace("\\s{2,}", "") %>%
      stringr::str_trim(side = "both")%>%
      dplyr::tibble(posterior = .)
    
    n <- max(length(single_sdg_prior), length(single_sdg_posterior))
    length(single_sdg_prior) <- n
    length(single_sdg_posterior) <- n
    
    return(list(sdg_name = sdg_name,
                value = cbind(prior = single_sdg_prior$prior,
                              posterior = single_sdg_posterior$posterior))
    )
}

# View(import_sdgs_from_git(1, FALSE))


# ####################################################
# import_sdg_xlsx <- function(fwd = wd, fconfig = config) {
#   
#   # fwd = wd
#   # fconfig = config
#   
#   base::tryCatch({
#     sdgs_xmlsx <- 
#       stringr::str_c(stringr::str_c(fwd,
#                                     fconfig$path$repo_sdgs,
#                                     "/",
#                                     base::list.files(stringr::str_c(fwd, 
#                                                                     fconfig$path$repo_sdgs), 
#                                                      fconfig$pattern$files_sdg))) #%>%
#     
#       # sdg_xlsx <- dgs_xmlsx
# 
#     sdgs_xmlsx %>%
#       purrr::map(., function(sdg_xlsx) {
#         
#         # extract the sdg name
#         sdg_name <<-
#           stringr::str_split(sdg_xlsx, pattern = "/") %>%
#           base::unlist() %>%
#           utils::tail(1) %>%
#           stringr::str_split(pattern = "\\.") %>%
#           base::unlist() %>%
#           utils::head(1) %>%
#           base::tolower()
#     
#         # read each sdg excel file and extract the in the excel sheet consolidated list od sdgs
#       single_sdg_prior <<-
#           c(2,4,6,8) %>%
#           purrr::map(., function(col) {
#             openxlsx::read.xlsx(
#               xlsxFile = sdg_xlsx,
#               sheet = "all",
#               na.strings = "na",
#               colNames = FALSE,
#               startRow = 1,
#               skipEmptyRows = FALSE,
#               # cols = 1)
#               cols = col)
#           }) %>%
#           base::unlist() %>%
#           stringr::str_replace("NA", "") %>%
#           stringr::str_replace("\\s{2,}", "") %>%
#           stringr::str_trim(side = "both")%>%
#           dplyr::tibble(prior = .)
#     
#         # read all postriors from the SDG containing Excel file
#       single_sdg_posterior <<-
#           c(3,5,7,9) %>%
#           purrr::map(., function(col) {
#             openxlsx::read.xlsx(
#               xlsxFile = sdg_xlsx,
#               sheet = "all",
#               na.strings = "na",
#               colNames = FALSE,
#               startRow = 1,
#               skipEmptyRows = FALSE,
#               cols = col)
#           }) %>%
#           base::unlist() %>%
#           stringr::str_replace("NA", "") %>%
#         stringr::str_replace("\\s{2,}", "") %>%
#         stringr::str_trim(side = "both")%>%
#           dplyr::tibble(posterior = .)
#       
#         n <- max(length(single_sdg_prior), length(single_sdg_posterior))
#         length(single_sdg_prior) <- n                      
#         length(single_sdg_posterior) <- n
# 
#         return(list(sdg_name = sdg_name,
#                     value = cbind(prior = single_sdg_prior$prior,
#                                             posterior = single_sdg_posterior$posterior))
#              # value = qpcR:::cbind.na(prior = single_sdg_prior$prior,
#              #                         posterior = single_sdg_posterior$posterior))
#         )
#       })
#         
#     },
#     error = function(cond) {
#       base::message(stringr::str_c("import_sdg{} error message: ",
#                                    cond))
#       return(NA)
#     }
#   )
# }
# 
# # debug
# import_sdg_xlsx()
# 
# 

####################################################
#* @get /dc_mapping
#* @param dataIn
#* @param sdgIn
#* @param fconfig
function(dataIn = import_data(), 
         sdgIn = import_sdgs_from_git(1, FALSE), 
         fconfig = config) {
# mapping_data <- function(dataIn, sdgIn, fconfig) {

  # dataIn = import_data()
  # sdgIn = import_sdgs_from_git(1, FALSE)
  # # sdgIn = import_sdg_xlsx()
  # fconfig = config
  return(config)
}

  # fpath_transformed = fconfig$path$path_data_transformed
  # fpath_repo = fconfig$path$path_data_raw
  # fpath_data = fconfig$path$path_data
  # frepo_sdg = fconfig$path$repo_sdgs
  # ffiles_transformed = fconfig$pattern$files_transformed
  # ffiles_sdg = fconfig$pattern$files_sdg
  



# test <- function(dataIn = import_data(),
#                  sdg = 1,
#                  list_with_posteriors = FALSE,
#                  output = "console",
#                  fconfig = config){
#
#   mapping_data(dataIn, sdgIn = import_sdgs_from_git(sdg, list_with_posteriors), fconfig)
# }
#
# View(test())


export_data <- function(data = data_mapped, output = "console") {
   #  # # Export the resulting data
  output = tolower(output)
  switch(output,
         csv={
           write.table(data, file = stringr::str_c(wd,"/data/dc_",sdg_name,".csv"), row.names = F, col.names = F, sep = '\t')
           },
         json={
           data %>%
             base::as.data.frame() %>%
             jsonlite::toJSON()  %>%
             base::write(x = ., file = stringr::str_c(wd,"/data/dc_",sdg_name,".json"))
         },
         console={
           return(data)
         })
  }

# export_data(output = "json")



 #  function(sdg = 1, list_with_posteriors = FALSE, output = "console", fconfig = config){
 #  # # data_mapped <- mapping_data(import_data(), sdgIn = import_sdg_xlsx(), config)
 #  data_mapped <- mapping_data(dataIn = import_data(),
 #                              sdgIn = import_sdgs_from_git(sdg, list_with_posteriors),
 #                              fconfig
 #                              )
 #  
 # # export_data(data = data_mapped, output)
}

#* @get /hello2
function() {
  return("Hello World2")
}
