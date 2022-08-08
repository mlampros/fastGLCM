FROM rocker/rstudio


LABEL maintainer='Lampros Mouselimis'


RUN export DEBIAN_FRONTEND=noninteractive; apt-get -y update && \
 apt-get install -y libssl-dev zlib1g-dev python pandoc pandoc-citeproc make libfftw3-dev libicu-dev libcurl4-openssl-dev libpng-dev && \
 apt-get install -y sudo && \
 pip3 install -U numpy && \
 pip3 install -U opencv-python && \
 apt-get install -y libarmadillo-dev && \
 apt-get install -y libblas-dev && \
 apt-get install -y liblapack-dev && \
 apt-get install -y libarpack++2-dev && \
 apt-get install -y gfortran && \
 R -e "install.packages(c( 'Rcpp', 'R6', 'rlang', 'OpenImageR', 'utils', 'RcppArmadillo', 'reticulate', 'covr', 'knitr', 'rmarkdown', 'testthat', 'remotes' ), repos =  'https://cloud.r-project.org/' )" && \
 R -e "Sys.setenv(GITHUB_PAT = 'f21ffbec9bdd69532ea7b11fea25fbdda6d4c37d'); remotes::install_github('mlampros/fastGLCM', upgrade = 'never', dependencies = FALSE, repos = 'https://cloud.r-project.org/')" && \
 apt-get autoremove -y && \
 apt-get clean


ENV USER rstudio


