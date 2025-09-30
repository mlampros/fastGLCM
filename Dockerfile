FROM rocker/rstudio:devel
LABEL maintainer='Lampros Mouselimis'

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Update package lists
RUN apt-get -y update

# Install base development tools
RUN apt-get install -y \
    libssl-dev \
    zlib1g-dev \
    python3 \
    python3-dev \
    pandoc \
    make \
    sudo

# Install scientific libraries
RUN apt-get install -y \
    libfftw3-dev \
    libicu-dev \
    libcurl4-openssl-dev \
    libpng-dev \
    python3-pip

# Install linear algebra libraries
RUN apt-get install -y \
    libarmadillo-dev \
    libblas-dev \
    liblapack-dev \
    gfortran

# Install OpenCV dependencies
RUN apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgomp1 || true

# Clean up
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN python3 -m pip install --break-system-packages --no-cache-dir --upgrade pip

# Install numpy first (required by others)
RUN pip3 install --break-system-packages --no-cache-dir numpy

# Install other Python packages one by one
RUN pip3 install --break-system-packages --no-cache-dir opencv-python-headless
RUN pip3 install --break-system-packages --no-cache-dir matplotlib
RUN pip3 install --break-system-packages --no-cache-dir scikit-image

# Install R packages
RUN R -e "install.packages(c('Rcpp', 'R6', 'rlang', 'OpenImageR', 'utils', 'RcppArmadillo', 'reticulate', 'covr', 'knitr', 'rmarkdown', 'testthat', 'remotes'), repos = 'https://cloud.r-project.org/')"

ADD http://www.random.org/strings/?num=10&len=8&digits=on&upperalpha=on&loweralpha=on&unique=on&format=plain&rnd=new uuid
ARG BUILD_DATE
RUN echo "$BUILD_DATE"
RUN R -e "remotes::install_github('mlampros/fastGLCM', upgrade = 'never', dependencies = FALSE, repos = 'https://cloud.r-project.org/')"

ENV USER=rstudio
