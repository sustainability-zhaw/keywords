library(plumber)
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
      dplyr::filter(doc_id %in% c(371, 1076, 1506, 1960, 4057))
  
    return(dc_prepared_data)
}

# import_data()$for_data_analysis


####################################################
import_sdgs_from_git <- 
  function(sdg, list_with_posteriors, fconfig = config) {
    
    sdg = 1
    list_with_posteriors = TRUE
    fconfig = config
    
    fpath_git = fconfig$path$repo_git
    fpath_sdgs = fconfig$path$repo_sdgs
    fpath_git_sdg = stringr::str_c(fpath_git,fpath_sdgs)
    
    # Loop over all sdgs
    prior_posterior_full_tibble <<-
      sdg %>%
      purrr::map(., function(x){
        sdg_name <<- stringr::str_c("SDG", x)
        filename <- stringr::str_c("SDG", x, ".csv")
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
      prior_posterior_full_tibble[,c(2,4,6,8)] %>%
      unlist() %>%
      stringr::str_replace_all("NA", "na") %>%
      stringr::str_replace_na("na") %>%
      stringr::str_replace_all("\\s{2,}", "") %>%
      stringr::str_trim(side = "both")%>%
      dplyr::tibble(prior = .)

    # extract posteriors, all languages and concatenate
    single_sdg_posterior <-
      prior_posterior_full_tibble[,c(3,5,7,9)] %>%
      unlist() %>%
      stringr::str_replace_all("NA", "na") %>%
      stringr::str_replace_na("na") %>%
      stringr::str_replace("\\s{2,}", "") %>%
      stringr::str_trim(side = "both")%>%
      dplyr::tibble(posterior = .)

    # Adjusting two dataframes to the same dimensions
    n <- max(length(single_sdg_prior),
             length(single_sdg_posterior))
    length(single_sdg_prior) <- n
    length(single_sdg_posterior) <- n

    return(list(sdg_name = sdg_name,
                value = cbind(prior = single_sdg_prior$prior,
                              posterior = single_sdg_posterior$posterior))
    )
}

# import_sdgs_from_git(1, TRUE)

####################################################
mapping_data <-
  function(dataIn, sdgIn, fconfig) {
    fpath_transformed = fconfig$path$path_data_transformed
    fpath_repo = fconfig$path$path_data_raw
    fpath_data = fconfig$path$path_data
    frepo_sdg = fconfig$path$repo_sdgs
    ffiles_transformed = fconfig$pattern$files_transformed
    ffiles_sdg = fconfig$pattern$files_sdg
    
    ##################
    dataIn = import_data()
    sdgIn = import_sdgs_from_git(sdg = 1, list_with_posteriors = TRUE)
    fconfig = config
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
    text2analyse_as_tibble <- text2analyse %>% 
      dplyr::tibble(text = .) %>%
      dplyr::mutate(doc_id = 1:dplyr::n())
    
    # Basic corpus creation
    corp <- quanteda::corpus(text2analyse,
                             meta = list())
  
    # split the corpus into sentenses
    corp <- quanteda::corpus_reshape(corp, 
                                     to = "sentences", 
                                     remove_punct = FALSE)
    
    # convert the created curpus to a tibble with a reduced rownumber format
    text_as_tibble <<- quanteda::convert(corp, 
                            to = c("data.frame", "json"), 
                            pretty = FALSE) %>% 
      tibble::as.tibble() %>%
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
      dplyr::as_tibble() %>%
      dplyr::select(1,2)  
    
    # # View(prior_posterior_tibble)
    # prior_posterior_tibble <- prior_posterior_tibble[21,]
    # prior_posterior_tibble$posterior %>% stringr::str_replace_all(",","|")
    # 
    # # prior_posterior_tibble$posterior  %>% stringr::str_flatten()
    # x <- prior_posterior_tibble$posterior  %>% strsplit(",") %>% purrr::pluck(1)
    # 
    # x[x %>% stringr::str_detect("\\^")] %>% toString()
    # 
    # stringr::str_flatten() %>% stringi::stri_detect_regex("//^")
    # 
    # 
    # grepl("\\^", prior_posterior_tibble)
    # 
    # typeof(prior_posterior_tibble$posterior)
    # stringr::str_split(",", co) %>% list() %>% stringi::stri_detect_fixed("^")
    # 
    # %>% stringr::str_trim("both")
    # prior_posterior_tibble$posterior[prior_posterior_tibble$posterior %>%
    #                                    stringi::stri_detect_fixed("^")]

    
    # transform priors and posteriors into an OR'd search string
    # searchIt <- stringr::str_c(prior_posterior_tibble$prior, 
    #                        ".*", 
    #                        prior_posterior_tibble$posterior, collapse='|') %>%
    #   stringr::str_replace_all("\\.\\*\\|", "|")
    
    
    # searchIt_posterior_na <- stringr::str_c(prior_posterior_tibble$prior[prior_posterior_tibble$posterior %>%
    #                                                                   stringr::str_detect("na")], 
    #                                    collapse='|') %>%
    #   stringr::str_replace_all("\\.\\*\\|", "|")
    # 
    # 
    # searchIt_posterior_positiv <- stringr::str_c("^(?=.*(",
    #                            prior_posterior_tibble$posterior[prior_posterior_tibble$posterior %>%
    #                                                               stringr::str_detect("[^\\^|na]")],
    #                            ")).*", 
    #                            prior_posterior_tibble$prior[prior_posterior_tibble$posterior %>%
    #                                                           stringr::str_detect("[^\\^|na]")], 
    #                            collapse='|') %>%
    #   stringr::str_replace_all("\\.\\*\\|", "|")
    # 
    # 
    # searchIt_posterior_negativ <- stringr::str_c("^(?!.*(",
    #                            prior_posterior_tibble$posterior[prior_posterior_tibble$posterior %>%
    #                                                               stringr::str_detect("\\^")] %>%
    #                              stringr::str_remove_all("\\^"),
    #                            ")).*", 
    #                            prior_posterior_tibble$prior[prior_posterior_tibble$posterior %>%
    #                                                           stringr::str_detect("\\^")], 
    #                            collapse='|') %>%
    #   stringr::str_replace_all("\\.\\*\\|", "|")
    # 
    # searchIt <- stringr::str_c(searchIt_posterior_na, searchIt_posterior_positiv, searchIt_posterior_negativ)
    # searchIt <- searchIt_posterior_na
    # searchIt <- searchIt_posterior_positiv
    # searchIt <- searchIt_posterior_negativ
    # searchIt <- "^(?=.*poverty).*financial aid"
    
    
    matchIt <- 
      stringr::str_c("(?=.*",
                     prior_posterior_tibble$posterior %>% 
                       stringr::str_replace_all(",", "|"),
                     ").*", 
                     prior_posterior_tibble$prior, 
                     collapse='|') %>%
      stringr::str_replace_all("\\.\\*\\|", "|") %>%
      stringr::str_replace_all("\\(\\?=\\.\\*na\\)\\.\\*", "")
    
    
    # # map a list of text strings to a list of patterns
    match_full_list <- 
      text_as_tibble %>%
      dplyr::mutate(
        keyword = stringr::str_extract(text, pattern = matchIt)) %>% 
      dplyr::filter(!is.na(keyword))
    
    View(match_full_list)
    
    # create a tibble and count the sentences containing the same keyword (prior and posterior)
    match_full_counts <-
      match_full_list %>% 
      dplyr::add_count(doc_id) %>% 
      dplyr::select(doc_id, keyword, counts = n) %>% 
      dplyr::distinct() 
    
    # create final resulting tibble for regular matches, not taking into account NOT
    data_matched_result <-
      dplyr::inner_join(text2analyse_as_tibble,
                      match_full_counts,
                      by = "doc_id") %>%
    dplyr::distinct() %>%
    dplyr::mutate(doc_id = as.character(doc_id))
    
      
    return(data_matched_result)
  }
      
 #    # # map a list of text strings to a list of patterns and getting only the positive result
 #    # match_extraction <- text_as_tibble %>% 
 #    #   dplyr::filter(stringr::str_detect(text_as_tibble$text, searchIt))
 #    
 # # View(match_extraction)
 #    
 #    
 #    posterior_prior_tibble <-
 #      posterior_prior_ngram %>%
 #      dplyr::tibble() %>%
 #      dplyr::select(doc_id = doc_id, keyword) %>%
 #      dplyr::mutate(doc_id = doc_id %>%
 #                      stringr::str_remove("\\.[0-9]+$") %>%
 #                      stringr::str_remove("^[a-z]*") %>%
 #                      as.numeric()
 #      ) %>%
 #      dplyr::distinct()
 #    
 #    
 #    
 #    
 #       
 #    # empty dataframe
 #    sdg_match = matrix(ncol = 0, nrow = 0) %>%
 #      dplyr::as_tibble() %>%
 #      dplyr::mutate(doc_id = as.numeric("0"))
 # 
 #  # # Christians super simples beispiel um alle SDG Dateien von GH zu laden
 #  # tidyr::tibble(
 #  #   sdg = 1:16,
 #  #   priorT = TRUE,
 #  #   priorF = FALSE) %>%
 #  #   tidyr::pivot_longer(startsWith("prior")) %>%
 #  #   dplyr::group_by(sdg, name) %>%
 #  #   dplyr::mutate(
 #  #     data = import_sdgs_from_git(sdg, value) %>% list(),) %>%
 #  #   dplyr::ungroup()
 # 
 #  # Main mapping routine
 #  # sdgIn %>%
 #  #   purrr::map(., function(prior_posterior_list) {
 #  #     prior_posterior_list <- sdgIn # for debug
 #      
 # 
 # 
 #      # extract the prior vector
 #      sdg_prior <-
 #        prior_posterior_tibble$prior
 # 
 #      # extract the posterior vector
 #      sdg_posterior <-
 #        prior_posterior_tibble$posterior
 # 
 #      # detect all expression excluding sdgs
 #      sdg_prior_NOT_priors <-
 #        prior_posterior_tibble[sdg_prior %>%
 #                                 stringr::str_starts(pattern = "NOT ", negate = FALSE),]
 # 
 #      # detect all expression excluding sdgs
 #      sdg_prior_NOT_prior <-
 #        sdg_prior_NOT_priors %>%
 #        dplyr::pull(prior) %>%
 #        stringr::str_remove_all("^NOT") %>%
 #        stringr::str_trim() %>%
 #        as.list() %>%
 #        unlist(., recursive = TRUE, use.names = TRUE) %>%
 #        c("")
 # 
 #      # create a matching excluding n-gram for all keywords
 #      prior_ngram_NOT <-
 #        quanteda::kwic(corp,
 #                       pattern = quanteda::phrase(sdg_prior_NOT_prior),
 #                       separator = " ",
 #                       case_insensitive = FALSE)
 # 
 # 
 #      text_prior_by_not_reduced <-
 #        dplyr::anti_join(quanteda::convert(corp, to = "data.frame"),
 #                         prior_ngram_NOT,
 #                         by = c("doc_id" = "docname"))
 # 
 #      # wranggled corpus creation
 #      corp <-
 #        quanteda::corpus(text_prior_by_not_reduced, meta = list())
 #    
 #      # split the corpus into sentenses
 #      corp <-
 #        quanteda::corpus_reshape(corp, to = "sentences", remove_punct = FALSE)
 # 
 #      # detect all expression excluding sdgs
 #      sdg_prior_NOT_posterior <-
 #        prior_posterior_tibble %>%
 #        dplyr::mutate(
 #          posteriorNot = prior_posterior_tibble$posterior %>% stringr::str_starts("NOT ")
 #            # as.logical(.)
 #        ) %>%
 #        dplyr::filter(posteriorNot == TRUE)
 #      
 #      sdg_prior_NOT_posterior_prior <-
 #        sdg_prior_NOT_posterior %>%
 #        # dplyr::select(c(""))
 #        dplyr::pull(prior) %>%
 #        as.list() %>%
 #        unlist(., recursive = TRUE, use.names = TRUE)
 # 
 #      # detect all textblockes where the posterior starts with "NOT"
 #      sdg_prior_NOT_posterior_posterior <-
 #        sdg_prior_NOT_posterior %>%
 #        dplyr::pull(posterior) %>%
 #        stringr::str_remove_all("^NOT") %>%
 #        stringr::str_trim() %>%
 #        as.list() %>%
 #        unlist(., recursive = TRUE, use.names = TRUE)
 #    
 #      # name the created excluding sdg matrix
 #      sdg_prior_NOT_posterior_tibble <-
 #        dplyr::tibble(prior = sdg_prior_NOT_posterior_prior,
 #                      posterior = sdg_prior_NOT_posterior_posterior)
 # 
 #      if (length(sdg_prior_NOT_posterior_prior) > 0 && all(!is.na(sdg_prior_NOT_posterior_prior))) {
 #        # create a matching excluding n-gram for all keywords
 #        prior_ngram_NOT <-
 #          quanteda::kwic(corp,
 #                         pattern = quanteda::phrase(sdg_prior_NOT_posterior_prior),
 #                         separator = " ",
 #                         case_insensitive = FALSE)
 #    
 #        # convert the found excluding priors to a tibble
 #        prior_ngram_NOT_tibble <-
 #          prior_ngram_NOT %>%
 #          dplyr::tibble() %>%
 #          dplyr::select(doc_id = docname,
 #                        prior = keyword) %>%
 #          dplyr::distinct() %>%
 #          dplyr::mutate(doc_id = doc_id %>%
 #                          stringr::str_remove("\\.[0-9]+$") %>%
 #                          stringr::str_remove("^[a-z]*") %>%
 #                          as.numeric()
 #          ) %>%
 #          dplyr::distinct()
 #      } else{
 #          prior_ngram_NOT_tibble = dplyr::tibble(doc_id = "", prior = "")
 #      }
 #      
 #  
 #      if (length(sdg_prior_NOT_posterior_posterior) > 0 && all(!is.na(sdg_prior_NOT_posterior_posterior))) {
 #        # create a matching excluding n-gram for all keywords
 #        posterior_ngram_exclude <-
 #          quanteda::kwic(corp,
 #                         pattern = quanteda::phrase(sdg_prior_NOT_posterior_posterior[prior_ngram_NOT_tibble$doc_id]),
 #                         separator = " ",
 #                         case_insensitive = FALSE)
 #    
 #        # convert the found excluding priors to a tibble
 #        posterior_ngram_exclude_tibble <-
 #          posterior_ngram_exclude %>%
 #          dplyr::tibble() %>%
 #          dplyr::select(doc_id = docname,
 #                        prior = keyword) %>%
 #          dplyr::distinct() %>%
 #          dplyr::mutate(doc_id = doc_id %>%
 #                          stringr::str_remove("\\.[0-9]+$") %>%
 #                          stringr::str_remove("^[a-z]*") %>%
 #                          as.numeric()
 #          ) %>%
 #          dplyr::distinct()
 #      } else{
 #        posterior_ngram_exclude_tibble = dplyr::tibble(doc_id = "", prior = "")
 #      }
 # 
 #      # Inner join the matching excluding priors and posteriors from the sdgs having a posterior
 #      posterior_excluded_joined <-
 #        dplyr::inner_join(prior_ngram_NOT_tibble,
 #                          posterior_ngram_exclude_tibble,
 #                          by = "doc_id") %>%
 #        dplyr::distinct() %>%
 #        dplyr::mutate(doc_id = as.character(doc_id))
 #    
 #      # text reduction by all prior-posterior combinations to be excluded.
 #      text_exclusion <-
 #        dplyr::anti_join(quanteda::convert(corp,
 #                                           to = "data.frame"),
 #                         posterior_excluded_joined,
 #                         by = "doc_id")
 #    
 #      
 #      # wranggled corpus creation
 #      corp <-
 #        quanteda::corpus(text_exclusion, meta = list())
 # 
 #      # split the corpus into sentenses
 #      corp <-
 #        quanteda::corpus_reshape(corp, to = "sentences", remove_punct = FALSE)
 #    
 #      # create the prior list having no posterior
 #      sdg_prior_no_posterior <-
 #        prior_posterior_tibble %>%
 #        dplyr::filter(posterior == "") %>%
 #        dplyr::pull(prior) %>%
 #        as.list() %>%
 #        unlist(recursive = TRUE, use.names = TRUE) %>%
 #        c("")
 #    
 #      # create a matching n-gram for all keywords
 #      prior_ngram <-
 #        quanteda::kwic(corp,
 #                       pattern = quanteda::phrase(sdg_prior_no_posterior),
 #                       separator = " ",
 #                       case_insensitive = FALSE)
 #    
 #      # convert the found priors to a tibble
 #      prior_ngram_tibble <-
 #        prior_ngram %>%
 #        dplyr::tibble() %>%
 #        dplyr::select(doc_id = docname,
 #                      prior = keyword) %>%
 #        dplyr::distinct() %>%
 #        dplyr::mutate(doc_id = doc_id %>%
 #                        stringr::str_remove("\\.[0-9]+$") %>%
 #                        stringr::str_remove("^[a-z]*") %>%
 #                        as.numeric(),
 #                      # posterior_prior = NA %>% as.character()
 #                      posterior_prior = NA
 #        ) %>%
 #        dplyr::distinct()
 # 
 #      sdg_prior_and_posterior <-
 #        prior_posterior_tibble %>%
 #        dplyr::filter(posterior != "")
 #    
 #      # cummulated list of all priors
 #      sdg_prior_and_posterior_prior <-
 #        sdg_prior_and_posterior %>%
 #        dplyr::pull(prior) %>%
 #        as.list() %>%
 #        unlist(recursive = TRUE, use.names = TRUE)
 #    
 #      # creating a tibble just containing the doc_id and the posteriors
 #      sdg_prior_and_posterior_posterior <-
 #        sdg_prior_and_posterior %>%
 #        dplyr::pull(posterior) %>%
 #        as.list() %>%
 #        unlist(recursive = TRUE, use.names = TRUE)
 #    
 #      if (length(sdg_prior_and_posterior_posterior) > 0) {
 #    
 #        # create a matching n-gram for all conditions
 #        posterior_prior_ngram <-
 #          quanteda::kwic(corp,
 #                         pattern = quanteda::phrase(sdg_prior_and_posterior_prior),
 #                         separator = " ",
 #                         case_insensitive = FALSE)
 #    
 #        # convert the found posteriors to a tibble
 #        posterior_prior_tibble <-
 #          posterior_prior_ngram %>%
 #          dplyr::tibble() %>%
 #          dplyr::select(doc_id = docname, prior = keyword) %>%
 #          dplyr::mutate(doc_id = doc_id %>%
 #                          stringr::str_remove("\\.[0-9]+$") %>%
 #                          stringr::str_remove("^[a-z]*") %>%
 #                          as.numeric()
 #          ) %>%
 #          dplyr::distinct()
 #    
 #        # create a matchin n-gram for all conditions
 #        posterior_posterior_ngram <-
 #          quanteda::kwic(corp,
 #                         pattern = quanteda::phrase(sdg_prior_and_posterior_posterior),
 #                         separator = " ",
 #                         case_insensitive = FALSE)
 #    
 #        # creating a list containing posteriors only
 #        posterior_posterior_tibble <-
 #          posterior_posterior_ngram %>%
 #          dplyr::tibble() %>%
 #          dplyr::select(doc_id = docname, posterior = keyword) %>%
 #          dplyr::mutate(doc_id = doc_id %>%
 #                          stringr::str_remove("\\.[0-9]+$") %>%
 #                          stringr::str_remove("^[a-z]*") %>%
 #                          as.numeric()
 #          ) %>%
 #          dplyr::distinct()
 #    
 #    
 #        # Inner join the matching priors and posteriors from the sdgs having a posterior
 #        posterior_joined <-
 #          dplyr::inner_join(posterior_prior_tibble,
 #                            posterior_posterior_tibble,
 #                            by = "doc_id") %>%
 #          dplyr::distinct()
 #    
 #        prior_posterior_joined <-
 #          dplyr::full_join(prior_ngram_tibble %>% dplyr::as_tibble(),
 #                           posterior_joined %>% dplyr::as_tibble(),
 #                           by = c("doc_id", "prior")) %>%
 #          dplyr::select("doc_id", "prior", "posterior")
 #    
 #        # prior_posterior_joined[is.na(prior_posterior_joined)] <- 0
 #    
 #      } else {
 #        prior_posterior_joined <-
 #          prior_ngram_tibble %>%
 #          dplyr::mutate(posterior = NA)
 #      }
 # 
 #      # Convert the quanteda Corpus to a dataframe
 #      corp_df <-
 #        quanteda::convert(corp, to = "data.frame")
 #    
 #      # join all documents, splitted into sentences, to the found prior/posterior combinations of a specific sdg
 #      prior_posterior_full_tibble <-
 #        dplyr::tibble(corp_df)%>%
 #        dplyr::mutate(doc_id = doc_id %>%
 #                        stringr::str_remove("\\.[0-9]+$") %>%
 #                        stringr::str_remove("^[a-z]*") %>%
 #                        as.integer()
 #        ) %>%
 #        merge(., prior_posterior_joined,
 #              by=c("doc_id")) %>%
 #        dplyr::select("doc_id", "prior", "posterior") %>%
 #        dplyr::distinct()
 #    
 #      # Prepare the sdg matching result for export
 #      prior_posterior_match_tibble  <-
 #        prior_posterior_full_tibble %>%
 #        dplyr::group_by(doc_id) %>%
 #        dplyr::summarise(prior = prior, posterior,
 #                         "{base::as.symbol(sdg_name)}" := 1,) %>%
 #        dplyr::ungroup() %>%
 #        dplyr::as_tibble() %>%
 #        dplyr::arrange(doc_id) %>%
 #        dplyr::distinct()
 #    
 #      sdg_match <- prior_posterior_match_tibble
 #    
 #      data_matched_result <-
 #        dplyr::inner_join(dataIn,
 #                          sdg_match,
 #                          by = "doc_id" )
    
      # return(data_matched_result)
# }

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
mapdata <- function(sdg = 1,
         dataIn = import_data(),
         list_with_posteriors = TRUE,
         sdgIn = import_sdgs_from_git(sdg, list_with_posteriors),
         output = "console",
         fconfig = config) {
  
  data_mapped <- mapping_data(dataIn, 
                              sdgIn, 
                              fconfig)
  
  return(data_mapped)
}
  
z <- mapdata()
# export_data(output = "json")

#* @get /dc_mapping
#* @param sdg
#* @param list_with_posteriors
#* @param output
  function(sdg = 1,
           dataIn = import_data(),
           list_with_posteriors = FALSE,
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
