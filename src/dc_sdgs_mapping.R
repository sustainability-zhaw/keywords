library(plumber)

`%>%` = magrittr::`%>%` 

setwd('..')
wd = getwd()

# import config parameters
config <- yaml::read_yaml(stringr::str_c(wd, "/config.yml")) 

####################################################
import_data <- function(fconfig = config){
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

# View(import_data())


####################################################
import_sdgs_from_git <- 
  function(sdg, list_with_posteriors) {
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

# View(import_sdgs_from_git(1, FALSE))

####################################################
mapping_data <- function(dataIn, sdgIn, fconfig) {
  fpath_transformed = fconfig$path$path_data_transformed
  fpath_repo = fconfig$path$path_data_raw
  fpath_data = fconfig$path$path_data
  frepo_sdg = fconfig$path$repo_sdgs
  ffiles_transformed = fconfig$pattern$files_transformed
  ffiles_sdg = fconfig$pattern$files_sdg

  # prepare the text to become the corpus
  text2analyse <-
    dataIn$for_data_analysis[] %>%
    stringr::str_replace_all("\\t", " ")

  # Basic corpus creation
  corp <- quanteda::corpus(text2analyse,
                           meta = list())

  # split the corpus into sentenses
  corp <- quanteda::corpus_reshape(corp, to = "sentences", remove_punct = FALSE)

  # empty dataframe
  sdg_match = matrix(ncol = 0, nrow = 0) %>%
    dplyr::as_tibble() %>%
    dplyr::mutate(doc_id = as.numeric("0"))

  # # Christians super simples beispiel um alle SDG Dateien von GH zu laden
  # tidyr::tibble(
  #   sdg = 1:16,
  #   priorT = TRUE,
  #   priorF = FALSE) %>%
  #   tidyr::pivot_longer(startsWith("prior")) %>%
  #   dplyr::group_by(sdg, name) %>%
  #   dplyr::mutate(
  #     data = import_sdgs_from_git(sdg, value) %>% list(),) %>%
  #   dplyr::ungroup()

  # Main mapping routine
  # sdgIn %>%
  # purrr::map(., function(prior_posterior_list) {
  # prior_posterior_list <- sdgIn # for debug

  # Version with only one selectable sdg 
  prior_posterior_list <- sdgIn

  # Extract the sdg name
  sdg_name <<-
    prior_posterior_list$sdg_name

  # Extract the prior - posterior tibble
  prior_posterior_tibble <-
    prior_posterior_list$value %>%
    dplyr::as_tibble() %>%
    dplyr::select(1,2)

  # extract the prior vector
  sdg_prior <-
    prior_posterior_tibble$prior

  # extract the posterior vector
  sdg_posterior <-
    prior_posterior_tibble$posterior

  # detect all expression excluding sdgs
  sdg_prior_NOT_priors <-
    prior_posterior_tibble[sdg_prior %>%
                             stringr::str_starts(pattern = "NOT ", negate = FALSE),]

  # detect all expression excluding sdgs
  sdg_prior_NOT_prior <-
    sdg_prior_NOT_priors %>%
    dplyr::pull(prior) %>%
    stringr::str_remove_all("^NOT") %>%
    stringr::str_trim() %>%
    as.list() %>%
    unlist(., recursive = TRUE, use.names = TRUE) %>%
    c("")

  # create a matching excluding n-gram for all keywords
  prior_ngram_NOT <-
    quanteda::kwic(corp,
                   pattern = quanteda::phrase(sdg_prior_NOT_prior),
                   separator = " ",
                   case_insensitive = FALSE)


  text_prior_by_not_reduced <-
    dplyr::anti_join(quanteda::convert(corp, to = "data.frame"),
                     prior_ngram_NOT,
                     by = c("doc_id" = "docname"))

  # wranggled corpus creation
  corp <-
    quanteda::corpus(text_prior_by_not_reduced, meta = list())

  # split the corpus into sentenses
  corp <-
    quanteda::corpus_reshape(corp, to = "sentences", remove_punct = FALSE)

  # detect all expression excluding sdgs
  sdg_prior_NOT_posterior <-
    prior_posterior_tibble %>%
    dplyr::mutate(
      posterior = prior_posterior_tibble$posterior %>%
        as.logical(.)
    ) %>%
    dplyr::filter(posterior != "")


  sdg_prior_NOT_posterior_prior <-
    sdg_prior_NOT_posterior %>%
    dplyr::pull(prior) %>%
    as.list() %>%
    unlist(., recursive = TRUE, use.names = TRUE)

  # detect all textblockes where the posterior starts with "NOT"
  sdg_prior_NOT_posterior_posterior <-
    sdg_prior_NOT_posterior %>%
    dplyr::pull(posterior) %>%
    stringr::str_remove_all("^NOT") %>%
    stringr::str_trim() %>%
    as.list() %>%
    unlist(., recursive = TRUE, use.names = TRUE)

  # name the created excluding sdg matrix
  sdg_prior_NOT_posterior_tibble <-
    dplyr::tibble(prior = sdg_prior_NOT_posterior_prior,
                  posterior = sdg_prior_NOT_posterior_posterior)

  if (length(sdg_prior_NOT_posterior_prior) > 0 && all(!is.na(sdg_prior_NOT_posterior_prior))) {
    # create a matching excluding n-gram for all keywords
    prior_ngram_NOT <-
      quanteda::kwic(corp,
                     pattern = quanteda::phrase(sdg_prior_NOT_posterior_prior),
                     separator = " ",
                     case_insensitive = FALSE)

    # convert the found exccluding priors to a tibble
    prior_ngram_NOT_tibble <-
      prior_ngram_NOT %>%
      dplyr::tibble() %>%
      dplyr::select(doc_id = docname,
                    prior = keyword) %>%
      dplyr::distinct() %>%
      dplyr::mutate(doc_id = doc_id %>%
                      stringr::str_remove("\\.[0-9]+$") %>%
                      stringr::str_remove("^[a-z]*") %>%
                      as.numeric()
      )
  } else{
    prior_ngram_NOT_tibble = dplyr::tibble(doc_id = "", prior = "")
  }

  if (length(sdg_prior_NOT_posterior_posterior) > 0 && all(!is.na(sdg_prior_NOT_posterior_posterior))) {
    # create a matching excluding n-gram for all keywords
    posterior_ngram_exclude <-
      quanteda::kwic(corp,
                     pattern = quanteda::phrase(sdg_prior_NOT_posterior_posterior),
                     separator = " ",
                     case_insensitive = FALSE)

    # convert the found excluding priors to a tibble
    posterior_ngram_exclude_tibble <-
      posterior_ngram_exclude %>%
      dplyr::tibble() %>%
      dplyr::select(doc_id = docname,
                    prior = keyword) %>%
      dplyr::distinct() %>%
      dplyr::mutate(doc_id = doc_id %>%
                      stringr::str_remove("\\.[0-9]+$") %>%
                      stringr::str_remove("^[a-z]*") %>%
                      as.numeric()
      )
  } else{
    posterior_ngram_exclude_tibble = dplyr::tibble(doc_id = "", prior = "")
  }

  # Inner join the matching excluding priors and posteriors from the sdgs having a posterior
  posterior_excluded_joined <-
    dplyr::inner_join(prior_ngram_NOT_tibble,
                      posterior_ngram_exclude_tibble,
                      by = "doc_id") %>%
    dplyr::distinct() %>%
    dplyr::mutate(doc_id = as.character(doc_id))

  # text reduction by all prior-posterior combinations to be excluded.
  text_exclusion <-
    dplyr::anti_join(quanteda::convert(corp,
                                       to = "data.frame"),
                     posterior_excluded_joined,
                     by = "doc_id")

  # wranggled corpus creation
  corp <-
    quanteda::corpus(text_exclusion, meta = list())

  # split the corpus into sentenses
  corp <-
    quanteda::corpus_reshape(corp, to = "sentences", remove_punct = FALSE)

  # create the prior list having no posterior
  sdg_prior_no_posterior <-
    prior_posterior_tibble %>%
    dplyr::filter(posterior == "") %>%
    dplyr::pull(prior) %>%
    as.list() %>%
    unlist(recursive = TRUE, use.names = TRUE) %>%
    c("")

  # create a matching n-gram for all keywords
  prior_ngram <-
    quanteda::kwic(corp,
                   pattern = quanteda::phrase(sdg_prior_no_posterior),
                   separator = " ",
                   case_insensitive = FALSE)

  # convert the found priors to a tibble
  prior_ngram_tibble <-
    prior_ngram %>%
    dplyr::tibble() %>%
    dplyr::select(doc_id = docname,
                  prior = keyword) %>%
    dplyr::distinct() %>%
    dplyr::mutate(doc_id = doc_id %>%
                    stringr::str_remove("\\.[0-9]+$") %>%
                    stringr::str_remove("^[a-z]*") %>%
                    as.numeric(),
                  # posterior_prior = NA %>% as.character()
                  posterior_prior = NA
    ) %>%
    dplyr::distinct()

  sdg_prior_and_posterior <-
    prior_posterior_tibble %>%
    dplyr::filter(posterior != "")

  # cummulated list of all priors
  sdg_prior_and_posterior_prior <-
    sdg_prior_and_posterior %>%
    dplyr::pull(prior) %>%
    as.list() %>%
    unlist(recursive = TRUE, use.names = TRUE)

  # creating a tibble just containing the doc_id and the posteriors
  sdg_prior_and_posterior_posterior <-
    sdg_prior_and_posterior %>%
    dplyr::pull(posterior) %>%
    as.list() %>%
    unlist(recursive = TRUE, use.names = TRUE)

  if (length(sdg_prior_and_posterior_posterior) > 0) {

    # create a matching n-gram for all conditions
    posterior_prior_ngram <-
      quanteda::kwic(corp,
                     pattern = quanteda::phrase(sdg_prior_and_posterior_prior),
                     separator = " ",
                     case_insensitive = FALSE)

    # convert the found posteriors to a tibble
    posterior_prior_tibble <-
      posterior_prior_ngram %>%
      dplyr::tibble() %>%
      dplyr::select(doc_id = docname, prior = keyword) %>%
      dplyr::mutate(doc_id = doc_id %>%
                      stringr::str_remove("\\.[0-9]+$") %>%
                      stringr::str_remove("^[a-z]*") %>%
                      as.numeric()
      ) %>%
      dplyr::distinct()

    # create a matchin n-gram for all conditions
    posterior_posterior_ngram <-
      quanteda::kwic(corp,
                     pattern = quanteda::phrase(sdg_prior_and_posterior_posterior),
                     separator = " ",
                     case_insensitive = FALSE)

    # creating a list containing posteriors only
    posterior_posterior_tibble <-
      posterior_posterior_ngram %>%
      dplyr::tibble() %>%
      dplyr::select(doc_id = docname, posterior = keyword) %>%
      dplyr::mutate(doc_id = doc_id %>%
                      stringr::str_remove("\\.[0-9]+$") %>%
                      stringr::str_remove("^[a-z]*") %>%
                      as.numeric()
      ) %>%
      dplyr::distinct()


    # Inner join the matching priors and posteriors from the sdgs having a posterior
    posterior_joined <-
      dplyr::inner_join(posterior_prior_tibble,
                        posterior_posterior_tibble,
                        by = "doc_id") %>%
      dplyr::distinct()

    prior_posterior_joined <-
      dplyr::full_join(prior_ngram_tibble %>% dplyr::as_tibble(),
                       posterior_joined %>% dplyr::as_tibble(),
                       by = c("doc_id", "prior")) %>%
      dplyr::select("doc_id", "prior", "posterior")

    # prior_posterior_joined[is.na(prior_posterior_joined)] <- 0

  } else {
    prior_posterior_joined <-
      prior_ngram_tibble %>%
      dplyr::mutate(posterior = NA)
  }

  # Convert the quanteda Corpus to a dataframe
  corp_df <-
    quanteda::convert(corp, to = "data.frame")

  # join all documents, splitted into sentences, to the found prior/posterior combinations of a specific sdg
  prior_posterior_full_tibble <-
    dplyr::tibble(corp_df)%>%
    dplyr::mutate(doc_id = doc_id %>%
                    stringr::str_remove("\\.[0-9]+$") %>%
                    stringr::str_remove("^[a-z]*") %>%
                    as.integer()
    ) %>%
    merge(., prior_posterior_joined,
          by=c("doc_id")) %>%
    dplyr::select("doc_id", "prior", "posterior") %>%
    dplyr::distinct()

  # Prepare the sdg matching result for export
  prior_posterior_match_tibble  <-
    prior_posterior_full_tibble %>%
    dplyr::group_by(doc_id) %>%
    dplyr::summarise(prior = prior, posterior,
                     "{base::as.symbol(sdg_name)}" := 1,) %>%
    dplyr::ungroup() %>%
    dplyr::as_tibble() %>%
    dplyr::arrange(doc_id) %>%
    dplyr::distinct()

  sdg_match <- prior_posterior_match_tibble

  data_matched_result <-
    dplyr::inner_join(dataIn,
                      sdg_match,
                      by = "doc_id" )

  return(data_matched_result)
}

##################################################
export_data <- function(data = data_mapped, output) {
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
           return(stringr::str_c(wd,"/data/dc_",sdg_name,".json"))
         },
         console={
           return(data)
         })
  }

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
  data_mapped <- mapping_data(dataIn = import_data(),
                              sdgIn = import_sdgs_from_git(sdg, list_with_posteriors),
                              fconfig
                              )
  export_data(data = data_mapped, output)
}

#* @get /test
function() {
  return("code preparation succeded")
}
