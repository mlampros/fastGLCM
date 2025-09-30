FROM rocker/rstudio:devel
LABEL maintainer='Lampros Mouselimis'

RUN export DEBIAN_FRONTEND=noninteractive; apt-get -y update && \
 apt-get install -y libssl-dev zlib1g-dev python pandoc make libfftw3-dev libicu-dev libcurl4-openssl-dev libpng-dev && \
 apt-get install -y sudo && \
 apt-get install -y python3-pip && \
 python3 -m pip install -U pip && \
 pip3 install -U numpy && \
 pip3 install -U opencv-python && \
 pip3 install -U matplotlib && \
 pip3 install -U scikit-image && \
 apt-get install -y libarmadillo-dev && \
 apt-get install -y libblas-dev && \
 apt-get install -y liblapack-dev && \
 apt-get install -y libarpack++2-dev && \
 apt-get install -y gfortran && \
 R -e "install.packages(c( 'Rcpp', 'R6', 'rlang', 'OpenImageR', 'utils', 'RcppArmadillo', 'reticulate', 'covr', 'knitr', 'rmarkdown', 'testthat', 'remotes' ), repos =  'https://cloud.r-project.org/' )" && \
 apt-get autoremove -y && \
 apt-get clean && \
 rm -rf /var/lib/apt/lists/*

ADD http://www.random.org/strings/?num=10&len=8&digits=on&upperalpha=on&loweralpha=on&unique=on&format=plain&rnd=new uuid

ARG BUILD_DATE
RUN echo "$BUILD_DATE"

RUN R -e "remotes::install_github('mlampros/fastGLCM', upgrade = 'never', dependencies = FALSE, repos = 'https://cloud.r-project.org/')"

ENV USER=rstudio
