FROM rocker/rstudio:devel
LABEL maintainer='Lampros Mouselimis'

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Update and install system dependencies
RUN apt-get -y update && \
    apt-get install -y \
    libssl-dev \
    zlib1g-dev \
    python3 \
    pandoc \
    make \
    libfftw3-dev \
    libicu-dev \
    libcurl4-openssl-dev \
    libpng-dev \
    sudo \
    python3-pip \
    libarmadillo-dev \
    libblas-dev \
    liblapack-dev \
    libarpack++2-dev \
    gfortran && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN python3 -m pip install --no-cache-dir -U pip && \
    pip3 install --no-cache-dir -U \
    numpy \
    opencv-python \
    matplotlib \
    scikit-image

# Install R packages
RUN R -e "install.packages(c('Rcpp', 'R6', 'rlang', 'OpenImageR', 'utils', 'RcppArmadillo', 'reticulate', 'covr', 'knitr', 'rmarkdown', 'testthat', 'remotes'), repos = 'https://cloud.r-project.org/')"

ADD http://www.random.org/strings/?num=10&len=8&digits=on&upperalpha=on&loweralpha=on&unique=on&format=plain&rnd=new uuid
ARG BUILD_DATE
RUN echo "$BUILD_DATE"
RUN R -e "remotes::install_github('mlampros/fastGLCM', upgrade = 'never', dependencies = FALSE, repos = 'https://cloud.r-project.org/')"

ENV USER=rstudio
