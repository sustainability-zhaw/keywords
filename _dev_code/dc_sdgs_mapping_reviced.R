library(plumber)
# library(tictoc)
library(doParallel) 
# cl <- makeCluster(4)
cl <- makePSOCKcluster(4)
# cl <- parallel::makeCluster(4, setup_timeout = 0.5)
registerDoParallel(cl)

# getDoParWorkers(c1)
stopCluster(cl)


`%>%` = magrittr::`%>%` 

setwd("/Users/bajk/Dropbox/Mac/Documents/GitHub/sustainability/keywords")

# setwd('..')
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
      dplyr::ungroup() %>%
      dplyr::filter(doc_id  %in% c(350:2000))
      # dplyr::filter(doc_id %in% c(371, 1076, 1506, 1960, 4057))
  
    return(dc_prepared_data)
}

# import_data()$for_data_analysis


####################################################
import_sdgs_from_git <- 
  function(sdg, list_with_posteriors, fconfig = config) {
    # 
    # sdg = 1
    # list_with_posteriors = TRUE
    # fconfig = config
    
    fpath_git = fconfig$path$repo_git
    fpath_sdgs = fconfig$path$repo_sdgs
    fpath_git_sdg = stringr::str_c(fpath_git,fpath_sdgs)
    
    # Loop over all sdgs
    prior_posterior_full_tibble <<-
      sdg %>%
      purrr::map(., function(x){
        sdg_name <<- stringr::str_c("SDG", x)
        # filename <- stringr::str_c("SDG", x, ".csv")
        filename <- stringr::str_c("SDG", x, "_dev.csv")
        if (list_with_posteriors == TRUE){
          type = "with_posterior"
        } else {
          type = "no_posterior"
        }
        RCurl::getURL(stringr::str_c(fpath_git_sdg, type, "/", filename),
                      .encoding = "UTF-8") %>%
        read.csv(text = ., sep = ";", header = FALSE) %>%
        tidyr::as_tibble(.name_repair = "minimal")
    }) %>%
    do.call(rbind.data.frame, .)

    # extract priors, all languages and concatenate
    single_sdg_prior <-
      # prior_posterior_full_tibble[,c(2,4,6,8)] %>%
      prior_posterior_full_tibble[,c(2)] %>%
      unlist() %>%
      stringr::str_replace_all("NA", "na") %>%
      stringr::str_replace_na("na") %>%
      stringr::str_replace_all("\\s{2,}", "") %>%
      stringr::str_trim(side = "both")%>%
      dplyr::tibble(prior = .)

    # extract posteriors, all languages and concatenate
    single_sdg_posterior <-
      # prior_posterior_full_tibble[,c(3,5,7,9)] %>%
      prior_posterior_full_tibble[,c(3)] %>%
      unlist() %>%
      stringr::str_replace_all("NA", "na") %>%
      stringr::str_replace_na("na") %>%
      stringr::str_replace("\\s{2,}", "") %>%
      stringr::str_trim(side = "both")%>%
      dplyr::tibble(posterior = .)
    
    # extract posteriors, all languages and concatenate
    single_sdg_posterior_NOT <-
      # prior_posterior_full_tibble[,c(3,5,7,9)] %>%
      prior_posterior_full_tibble[,c(4)] %>%
      unlist() %>%
      stringr::str_replace_all("NA", "na") %>%
      stringr::str_replace_na("na") %>%
      stringr::str_replace("\\s{23,}", "") %>%
      stringr::str_trim(side = "both")%>%
      dplyr::tibble(posteriorNOT = .)

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
                              posteriorNOT = single_sdg_posterior_NOT$posteriorNOT))
    )
}

import_sdgs_from_git(1, TRUE)

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
    dataIn = import_data()
    sdgIn = import_sdgs_from_git(sdg = 1, list_with_posteriors = TRUE)
    fconfig = config
    sentence_based = FALSE
    fpath_transformed = fconfig$path$path_data_transformed;
    fpath_repo = fconfig$path$path_data_raw;
    fpath_data = fconfig$path$path_data;
    frepo_sdg = fconfig$path$repo_sdgs;
    ffiles_transformed = fconfig$pattern$files_transformed;
    ffiles_sdg = fconfig$pattern$files_sdg;
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
      prior_posterior_list$sdg_name
    
    # Extract the prior - posterior tibble
    prior_posterior_tibble <-
      prior_posterior_list$value %>%
      dplyr::as_tibble() 
    
    # matchIt <-
    #   stringr::str_c("(?=.*",
    #                  prior_posterior_tibble$posterior %>%
    #                    stringr::str_replace_all(",", "|"),
    #                  ").*",
    #                  prior_posterior_tibble$prior,
    #                  collapse='|') %>%
    #   stringr::str_replace_all("\\.\\*\\|", "|") %>%
    #   stringr::str_replace_all("\\(\\?=\\.\\*na\\)\\.\\*", "")
    
    #### NEW!
    
    prior_sdg <- prior_posterior_tibble$prior %>% stringr::str_replace_all(",", "|") #%>% dplyr::tibble()
    posterior_sdg <- prior_posterior_tibble$posterior %>% stringr::str_replace_all(",", "|") #%>% dplyr::tibble()
    posteriorNOT_sdg <- prior_posterior_tibble$posteriorNOT %>% stringr::str_replace_all(",", "|")# %>% dplyr::tibble()

    # t = "Children’s understandings of group vulnerable and mental illness, well-being; Well-being; Vulnerability; Qualitative Forschung; Kindheitsforschung; Kinder- und Jugendhilfe; Heimerziehung;  Psychologie;  Jugendhilfe; Der Beitrag thematisiert anhand empirischer Einblicke, wie Kinder und Jugendliche Wohlbefinden und Vulnerabilität verstehen und wo/was sie verletzlich oder unsicher macht."
    
    # pr <- stringr::str_detect(t, pattern = prior_sdg)
    # pos <- stringr::str_detect(t, pattern = posterior_sdg)
    # posNOT <- stringr::str_detect(t, pattern = posteriorNOT_sdg, negate=TRUE)
    # 
    # # combine prior, posterior and NOT posterior keyword settings
    # pr & pos & posNOT
    
    matchIt <-
      stringr::str_c("(?=.*",
                     prior_posterior_tibble$posterior %>%
                       stringr::str_replace_all(",", "|"),
                     ").*",
                     prior_posterior_tibble$prior,
                     collapse='|') %>%
      stringr::str_replace_all("\\.\\*\\|", "|") %>%
      stringr::str_replace_all("\\(\\?=\\.\\*na\\)\\.\\*", "")
    
  # cl <- makePSOCKcluster(2)
  # registerDoParallel(cl)
    
  # matchIt <- "vulnerable|extreme poverty|poverty alleviation|poverty eradication|poverty reduction|international poverty line|financial empowerment|distributional effect*|child labo*r|development aid|social protection system*|micro*financ*|resilience of the poor|food bank*"  
  # text2analyse_as_tibble[1,]$text
  
    ptime <<- system.time({
      match_full_list <<-
        # foreach(i = text2analyse_as_tibble, .combine='cbind') %dopar% {
          # stringr::str_extract(i$text, pattern = matchIt)
          # i = text2analyse_as_tibble[5,]
          text2analyse_as_tibble$text %>%
            purrr::map(.,
                       function(i) {
              pr <- stringr::str_detect(i, pattern = prior_sdg)
              pos <- stringr::str_detect(i, pattern = posterior_sdg)
              posNOT <- stringr::str_detect(i, pattern = posteriorNOT_sdg, negate=TRUE) #%>% stringr::str_replace_all("NA", "FALSE")
              
              # combine prior, posterior and NOT posterior keyword settings
              pr & pos & posNOT %>% dplyr::as_tibble()
            }) %>%
            dplyr::tibble()%>%
            cbind(text2analyse_as_tibble["doc_id"], .) %>%
            dplyr::rename(keywords_match = 2)
          
          # if(pr & pos & posNOT == TRUE){
          #   "not empty"}
          #   stringr::str_c(prior_sdg, " AND (", posterior_sdg %>% stringr::str_replace_all("\\|", " OR ") , ") but NOT (", posteriorNOT_sdg %>% stringr::str_replace_all("\\|", " OR "), ")")
           # } else{
          #   "empty"
            # }

        # } #%>%
        # cbind(text2analyse_as_tibble["doc_id"], .) %>%
        # 
        # dplyr::rename(keywords = 2) %>%
        # dplyr::filter(!is.na(keywords))
    })[3]
  ptime
  match_full_list
  # stopCluster(cl)

    # create a tibble and count the sentences containing the same keyword (prior and posterior)
    match_full_counts <-
      match_full_list %>%
      dplyr::add_count(doc_id) %>%
      # dplyr::select(doc_id, keyword, counts = n) %>%
      dplyr::distinct()


    # # create final resulting tibble for regular matches, not taking into account NOT
    data_matched_result <-
      dplyr::inner_join(match_full_counts,
                        text2analyse_as_tibble,
                      by = "doc_id") %>%
    dplyr::distinct() %>%
    dplyr::mutate(doc_id = as.character(doc_id))
    
    
    if(sentence_based == FALSE){
      data_matched_result <-
      data_matched_result %>%
      dplyr::mutate(
        n = text %>% 
          tolower() %>% 
          stringr::str_count(pattern = keywords))
    }
    
    View(data_matched_result)
    
    return(data_matched_result)
  }


##################################################
export_data <-
  function(data, fwd, fsdg, foutput, list_with_posteriors) {
   #  # # Export the resulting data

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
             base::as.data.frame() %>%
             jsonlite::toJSON()  %>%
             base::write(x = ., file = stringr::str_c(wd,"/data/mapped/", posterior_mapping_path, "dc_",sdg_name,".json"))
           return(stringr::str_c(wd,"/data/mapped/", posterior_mapping_path, "dc_",sdg_name,".json"))
         },
         console={
           return(data)
         })
  }
#debug
mapdata <- 
  function(sdg = 1,
         dataIn = import_data(),
         list_with_posteriors = TRUE,
         sdgIn = import_sdgs_from_git(sdg, list_with_posteriors),
         output = "console",
         fconfig = config) {
  
  data_mapped <- 
    mapping_data(dataIn, 
                 sdgIn, 
                 fconfig)
  
  return(data_mapped)
}
  
res <- mapdata(sdg = 1)

#* @get /dc_mapping
#* @param sdg
#* @param list_with_posteriors
#* @param output
  function(sdg = 1,
           dataIn = import_data(),
           sentence_based = FALSE,
           list_with_posteriors = TRUE,
           sdgIn = import_sdgs_from_git(sdg, list_with_posteriors),
           output = "console",
           fconfig = config) {

    data_mapped <- mapping_data(dataIn, 
                                sdgIn, 
                                fconfig)
    
    return(data_mapped)
    
    # export_data(data = data_mapped, 
    #             fwd = wd, 
    #             fsdg = sdg, 
    #             foutput = output, 
    #             list_with_posteriors)
  }

#* @get /test
function() {
  return("code preparation succeded")
}
