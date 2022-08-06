library(plumber)

# Switch off warnings
options(warn=-1)

`%>%` = magrittr::`%>%` 

# setwd("/Users/bajk/Dropbox/Mac/Documents/GitHub/sustainability/keywords") # when used locally
setwd('..') # when used for Git
wd = getwd()

# import config parameters
config <- yaml::read_yaml(stringr::str_c(wd, "/config.yml")) 

####################################################
import_data <- 
  function(fconfig = config){
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
      dplyr::ungroup()

    return(dc_prepared_data)
  }

####################################################
import_sdgs_from_git <- 
  function(sdg = 1) {

    fconfig = config

    fpath_git = fconfig$path$repo_git
    fpath_sdgs = fconfig$path$repo_sdgs
    fpath_git_sdg = stringr::str_c(fpath_git,fpath_sdgs)
    
    # Loop over all sdgs
    prior_posterior_full_tibble <-
      sdg %>%
      purrr::map(., function(x){
        sdg_name <<- stringr::str_c("SDG", x)
        filename <- stringr::str_c("SDG", x, "_dev.csv")
        RCurl::getURL(stringr::str_c(fpath_git_sdg, filename),
                      .encoding = "UTF-8") %>%
          read.csv(text = ., sep = ";", header = FALSE, na = c("","na","NA")) %>%
          tidyr::as_tibble(.name_repair = "minimal")
      }) %>%
      do.call(rbind.data.frame, .)
    
    # Fill up empty columns
    for (i in (prior_posterior_full_tibble %>% length() + 1):13){
      prior_posterior_full_tibble <- 
        prior_posterior_full_tibble %>% 
        tibble::add_column(V = NA, .name_repair = "minimal")
    }
    names(prior_posterior_full_tibble) <- c("V1", "V2","V3","V4","V5","V6","V7","V8","V9","V10","V11","V12","V13")
    
    # extract priors, all languages and concatenate
    single_sdg_prior <-
      prior_posterior_full_tibble[,c("V2","V5","V8","V11")] %>%
      # prior_posterior_full_tibble[,"V2"] %>%
      unlist() %>%
      stringr::str_trim(side = "both") %>%
      dplyr::tibble(prior = .) %>%
      tidyr::drop_na()
    
    # extract posteriors, all languages and concatenate
    single_sdg_posterior <-
      prior_posterior_full_tibble[,c("V3","V6","V9","V12")] %>%
      # prior_posterior_full_tibble[,"V3"] %>%
      unlist() %>%
      stringr::str_trim(side = "both")%>%
      dplyr::tibble(posterior = .) %>%
      dplyr::slice_head(n = single_sdg_prior %>% nrow())
    
    # extract posteriors, all languages and concatenate
    single_sdg_posterior_NOT <-
      prior_posterior_full_tibble[,c("V4","V7","V10","V13")] %>%
      # prior_posterior_full_tibble[,"V4"] %>%
      unlist() %>%
      stringr::str_trim(side = "both") %>%
      dplyr::tibble(posteriorNOT = .) %>%
      dplyr::slice_head(n = single_sdg_prior %>% nrow())
    
    # Adjusting two dataframes to the same dimensions
    n <- max(length(single_sdg_prior),
             length(single_sdg_posterior),
             length(single_sdg_posterior_NOT))
    length(single_sdg_prior) <- n
    length(single_sdg_posterior) <- n
    length(single_sdg_posterior_NOT) <- n
    
    return(list(sdg_name = sdg_name,
                value = cbind(prior = single_sdg_prior$prior,
                              posterior = single_sdg_posterior$posterior,
                              posteriorNOT = single_sdg_posterior_NOT$posteriorNOT)
        )
    )
}

####################################################
mapping_data <-
  function(dataIn, sdgIn, fconfig, sentence_based = FALSE) {
    fpath_transformed = fconfig$path$path_data_transformed
    fpath_repo = fconfig$path$path_data_raw
    fpath_data = fconfig$path$path_data
    frepo_sdg = fconfig$path$repo_sdgs
    ffiles_transformed = fconfig$pattern$files_transformed
    ffiles_sdg = fconfig$pattern$files_sdg
    
    # ##################
    # dataIn = import_data()
    # sdgIn = import_sdgs_from_git(sdg = 1, list_with_posteriors = TRUE)
    # fconfig = config
    # sentence_based = FALSE
    # fpath_transformed = fconfig$path$path_data_transformed;
    # fpath_repo = fconfig$path$path_data_raw;
    # fpath_data = fconfig$path$path_data;
    # frepo_sdg = fconfig$path$repo_sdgs;
    # ffiles_transformed = fconfig$pattern$files_transformed;
    # ffiles_sdg = fconfig$pattern$files_sdg;
    ###################

    # prepare the text to become the corpus
    text2analyse <-
      dataIn$for_data_analysis[] %>%
      stringr::str_replace_all("\\t", " ") %>% 
      stringr::str_replace_all("\\.(?=[:upper:])", "\\. ") # unify end of sentence
    
    # used for later to bind the found sdgs to the corresponding text body
    text2analyse_as_tibble <<- 
      text2analyse %>% 
      dplyr::tibble(text = .,) %>%
      dplyr::mutate(doc_id = dataIn$doc_id)
    # dplyr::mutate(doc_id = 1:dplyr::n())
    
    # Basic corpus creation
    corp <- quanteda::corpus(text2analyse_as_tibble,
                             meta = list()
                             )
  
    if( sentence_based == TRUE){
      # split the corpus into sentenses
      corp <- quanteda::corpus_reshape(corp,
                                       to = "sentences",
                                       remove_punct = FALSE)
    }
  
      # # convert the created curpus to a tibble with a reduced rownumber format
      text2analyse_as_tibble <<- quanteda::convert(corp,
                              to = c("data.frame", "json"),
                              pretty = FALSE) %>%
        dplyr::as_tibble() %>%
          dplyr::mutate(
            doc_id = stringr::str_remove(doc_id, "\\.[0-9]+$")%>%
              stringr::str_remove("^[a-z]*") %>%
              as.numeric())
    
    # assign sdgIn list to a variable
    prior_posterior_list <- sdgIn
    
    # Extract the sdg name
    sdg_name <<-
      prior_posterior_list$sdg_name %>% tolower()
    
    # Extract the prior - posterior tibble
    prior_posterior_tibble <-
      prior_posterior_list$value %>%
      dplyr::as_tibble() 
    
    
    prior_sdg <- prior_posterior_tibble$prior %>% stringr::str_replace_all(",", "|")
    posterior_sdg <- prior_posterior_tibble$posterior %>% stringr::str_replace_all(",", "|")
    posteriorNOT_sdg <- prior_posterior_tibble$posteriorNOT %>% stringr::str_replace_all(",", "|")

    ptime <<- system.time({
      match_full_list <<-
          text2analyse_as_tibble$text %>%
            purrr::map(.,
                       function(i) {
                         # i <- text2analyse_as_tibble$text[1]
              pr <- stringr::str_detect(i, pattern = prior_sdg)
              
              pos <- stringr::str_detect(i, pattern = posterior_sdg) %>% 
                stringr::str_replace_na(TRUE) %>% as.logical()
              
              posNOT <- stringr::str_detect(i, pattern = posteriorNOT_sdg, negate=TRUE) %>% 
                stringr::str_replace_na(TRUE) %>% as.logical()
              
              # combine prior, posterior and NOT posterior keyword settings
              pr & pos & posNOT
            }) %>%
        
            dplyr::tibble()%>%
            cbind(text2analyse_as_tibble["doc_id"], .) %>%
            dplyr::rename(keywords_match = 2)
      })[3]

  # ptime

  sdg_match <- match_full_list %>%
    dplyr::tibble() %>%
    dplyr::transmute(
      doc_id = doc_id,
      kw = keywords_match %>% purrr::map(., function(x){
        which(purrr::map_lgl(x, isTRUE)) %>%
        prior_posterior_tibble[.,]})
    ) 

  notEmpty <- sdg_match$kw  %>%
    purrr::map(., function(x){
      nrow(x) %>% as.logical() 
      }) %>%
    unlist()

    data_matched_result <- 
      dplyr::inner_join(dataIn, 
                        cbind(sdg_match, notEmpty) %>%
                          dplyr::filter(notEmpty == TRUE), 
                 by="doc_id") %>%
    dplyr::select(handle, authors, for_data_analysis, doc_id, {{sdg_name}} := kw)
    
  
    # View(data_matched_result)
    
    return(data_matched_result)
  }


##################################################
export_data <-
  function(data, fwd, fsdg, foutput, list_with_posteriors) {
   #  # # Export the resulting data
    
    data = data_mapped
    fwd = wd
    fsdg = sdg
    foutput = "json" # c("console", "json")
    list_with_posteriors

    posterior_mapping_path = ""
    if (list_with_posteriors == TRUE){
      posterior_mapping_path = "sdgs_with_posterior/"}
    else{
      posterior_mapping_path = "sdgs_no posterior/"
    }

  foutput = tolower(foutput)
  sdg_name = stringr::str_c("sdg_", fsdg)
  
  switch(output,
         csv={
           write.table(data, file = stringr::str_c(wd,"/data/mapped/", posterior_mapping_path, "dc_",sdg_name,".csv"), row.names = F, col.names = F, sep = '\t')
           },
         json={
           data %>%
             # base::as.data.frame() %>%
             jsonlite::toJSON()  %>%
             base::write(x = ., file = stringr::str_c(wd,"/data/mapped/", posterior_mapping_path, "dc_",sdg_name,".json"))
           return(stringr::str_c(wd,"/data/mapped/", posterior_mapping_path, "dc_",sdg_name,".json"))
         },
         console={
           return(data)
         })
  }

#* @get /dc_dataIn
function() {
  dataIn = import_data()
  return(dataIn)
}

#* @get /dc_sdg_git
#* @param sdg
  function(sdg=1) {
 
sdg = 1
fconfig = config

fpath_git = fconfig$path$repo_git
fpath_sdgs = fconfig$path$repo_sdgs
fpath_git_sdg = stringr::str_c(fpath_git,fpath_sdgs)

# Loop over all sdgs
prior_posterior_full_tibble <-
  sdg %>%
  purrr::map(., function(x){
    sdg_name <<- stringr::str_c("SDG", x)
    filename <- stringr::str_c("SDG", x, "_dev.csv")
    RCurl::getURL(stringr::str_c(fpath_git_sdg, filename),
                  .encoding = "UTF-8") %>%
      read.csv(text = ., sep = ";", header = FALSE, na = c("","na","NA")) %>%
      tidyr::as_tibble(.name_repair = "minimal") #%>%
  }) %>%
  do.call(rbind.data.frame, .)

  # Fill up empty columns
  for (i in (prior_posterior_full_tibble %>% length() + 1):13){
    prior_posterior_full_tibble <- 
      prior_posterior_full_tibble %>% 
      tibble::add_column(V = NA, .name_repair = "minimal")
  }
  names(prior_posterior_full_tibble) <- c("V1", "V2","V3","V4","V5","V6","V7","V8","V9","V10","V11","V12","V13")
 
  # extract priors, all languages and concatenate
  single_sdg_prior <-
    prior_posterior_full_tibble[,c("V2","V5","V8","V11")] %>%
    # prior_posterior_full_tibble[,"V2"] %>%
    unlist() %>%
    stringr::str_trim(side = "both") %>%
    dplyr::tibble(prior = .) %>%
    tidyr::drop_na()

  # extract posteriors, all languages and concatenate
  single_sdg_posterior <-
    prior_posterior_full_tibble[,c("V3","V6","V9","V12")] %>%
    # prior_posterior_full_tibble[,"V3"] %>%
    unlist() %>%
    stringr::str_trim(side = "both")%>%
    dplyr::tibble(posterior = .) %>%
    dplyr::slice_head(n = single_sdg_prior %>% nrow())

  # extract posteriors, all languages and concatenate
  single_sdg_posterior_NOT <-
    prior_posterior_full_tibble[,c("V4","V7","V10","V13")] %>%
    # prior_posterior_full_tibble[,"V4"] %>%
    unlist() %>%
    stringr::str_trim(side = "both") %>%
    dplyr::tibble(posteriorNOT = .) %>%
    dplyr::slice_head(n = single_sdg_prior %>% nrow())

  # Adjusting two dataframes to the same dimensions
  n <- max(length(single_sdg_prior),
           length(single_sdg_posterior),
           length(single_sdg_posterior_NOT))
  length(single_sdg_prior) <- n
  length(single_sdg_posterior) <- n
  length(single_sdg_posterior_NOT) <- n

  return(list(sdg_name = sdg_name,
              value = cbind(prior = single_sdg_prior$prior,
                            posterior = single_sdg_posterior$posterior,
                            posteriorNOT = single_sdg_posterior_NOT$posteriorNOT)
              )
         )

  # return(single_sdg_prior)
  }


#* @get /dc_mapping
#* @param sdg
#* @param sentence_based
#* @param output
  function(sdg = 1,
           sentence_based = FALSE,
           output = "console") {

    fconfig = config
    dataIn = import_data()
    sdgIn = import_sdgs_from_git(sdg)
    data_mapped <- mapping_data(dataIn,
                                sdgIn,
                                fconfig,
                                sentence_based)
    
    return(data_mapped)
    
    
    # export_data(data = data_mapped,
    #             fwd = wd,
    #             fsdg = sdg,
    #             foutput = "json", # c("console", "json")
    #             list_with_posteriors)
  }

#* @get /test
function() {
  return(stringr::str_c("code preparation succeded: wd = ", wd))
}

#* @get /mapping
function() {
  import <- import_sdgs_from_git()
  return(import)
}

# Offline debug
# dc <- function(sdg = 1,
#          list_with_posteriors = TRUE,
#          sentence_based = FALSE,
#          output = "console") {
#   
#   fconfig = config
#   dataIn = import_data()
#   sdgIn = import_sdgs_from_git(sdg, list_with_posteriors)
#   data_mapped <- mapping_data(dataIn,
#                               sdgIn,
#                               fconfig,
#                               sentence_based)
#   
#   return(data_mapped)
# }
# dc()
