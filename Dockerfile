FROM docker
COPY --from=docker/buildx-bin:latest /buildx /usr/libexec/docker/cli-plugins/docker-buildx
RUN docker buildx version

# start from rstudio/plumber image 
FROM rstudio/plumber AS builder 

# general update check, additional installation needed 
RUN apt-get update -qq \
  && apt-get install -y \ 
     libssl-dev \ 
     libcurl4-gnutls-dev \ 
  && rm -rf /var/lib/apt/lists/*

# R packages needed by the services 
RUN R -e 'install.packages(c("magrittr", "yaml", "plumber", "forcats", "dplyr", "stringr", "jsonlite", "readr", "tidyr", "quanteda", "openxlsx", "qpcR")' \
  && rm -rf /tmp/* 

# Volume definition on the host and withing the container 
COPY config.yml /usr
COPY /data/. /usr/data 
COPY /src/. /usr/src 

# set the container work directory 
WORKDIR /usr

# VOLUME ["/usr/src"]
# CMD Rscript plumber.R

# launch the plumbered R file 
CMD ["src/dc_sdgs_mapping.R"]