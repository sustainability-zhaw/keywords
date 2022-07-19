# FROM docker
# COPY --from=docker/buildx-bin:latest /buildx /usr/libexec/docker/cli-plugins/docker-buildx
# RUN docker buildx version

# start from rstudio/plumber image 
FROM rstudio/plumber:latest

# general update check, additional installation needed 
RUN apt-get update -qq \
  && apt-get install -y \ 
     libssl-dev \ 
     libcurl4-gnutls-dev \ 
  && rm -rf /var/lib/apt/lists/*

# R packages needed by the services 
RUN R -e 'install.packages(c("magrittr", "yaml", "plumber", "qpcR", "forcats", "dplyr", "stringr", "jsonlite", "readr", "tidyr", "quanteda", "openxlsx"))' \
 && rm -rf /tmp/*

# set the container work directory 
WORKDIR /usr

# Volume definition on the host and within the container 
COPY config.yml /usr
COPY /data/. /usr/data 
COPY /src/. /usr/src 

# VOLUME ["/usr/src"]
# CMD Rscript plumber.R

RUN R -e "install.packages('libcurl:latest')"

# launch the plumbered R file 
CMD ["Rscript src/dc_sdgs_mapping.R"]
# CMD ["Rscript src/hello.R"]
