FROM ubuntu:focal

LABEL maintainer="Chris Wieringa <cwieri39@calvin.edu>"

# Set versions and platforms
ARG UBUNTU_VERSION=2004
ARG UBUNTU_CODENAME=focal
ARG R_VERSION=4.2.0
ARG MINICONDA_VERSION=py39_4.11.0
ARG PYTHON_VERSION=3.9.7
ARG DRIVERS_VERSION=2021.10.0

# Start with base Ubuntu

# Install RStudio Workbench session components -------------------------------#

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    wget \
    krb5-user \
    libcurl4-gnutls-dev \
    libssl1.1 \
    libssl-dev \
    libuser \
    libuser1-dev \
    libpq-dev \
    rrdtool \
    libtirpc3 && \
    rm -rf /var/lib/apt/lists/*

ARG RSW_VERSION=2022.02.2+485.pro2
ARG RSW_NAME=rstudio-workbench
ARG RSW_DOWNLOAD_URL=https://s3.amazonaws.com/rstudio-ide-build/server/bionic/amd64
RUN apt-get update --fix-missing \
    && apt-get install -y gdebi-core \
    && RSW_VERSION_URL=`echo -n "${RSW_VERSION}" | sed 's/+/-/g'` \
    && curl -o rstudio-workbench.deb ${RSW_DOWNLOAD_URL}/${RSW_NAME}-${RSW_VERSION_URL}-amd64.deb \
    && gdebi --non-interactive rstudio-workbench.deb \
    && rm rstudio-workbench.deb \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/rstudio-server/r-versions

EXPOSE 8788/tcp

# Install additional system packages ------------------------------------------#

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    bzip2-doc \
    fontconfig \
    fontconfig-config \
    fonts-dejavu-core \
    gfortran \
    gfortran-9 \
    icu-devtools \
    libblas-dev \
    libblas3 \
    libbz2-dev \
    libcairo2 \
    libdatrie1 \
    libfontconfig1 \
    libgdal-dev \
    libgfortran-9-dev \
    libgfortran5 \
    libgraphite2-3 \
    libharfbuzz0b \
    libice6 \
    libicu-dev \
    libjbig0 \
    libjpeg-turbo8 \
    libjpeg-turbo8-dev \
    libjpeg8 \
    liblapack-dev \
    liblapack3 \
    libmysqlclient-dev \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libpangoft2-1.0-0 \
    libpaper-utils \
    libpaper1 \
    libpcre2-16-0 \
    libpcre2-32-0 \
    libpcre2-dev \
    libpcre2-posix2 \
    libpng-dev \
    libpixman-1-0 \
    libsm6 \
    libtcl8.6 \
    libthai-data \
    libthai0 \
    libtiff5 \
    libtk8.6 \
    libwebp6 \
    libxcb-render0 \
    libxcb-shm0 \
    libxft2 \
    libxrender1 \
    libxss1 \
    libxt6 \
    unzip \
    x11-common \
    zip \
    zlib1g-dev \
    git \
    libssl1.1 \
    libuser \
    libxml2-dev \
    subversion && \
    rm -rf /var/lib/apt/lists/*

# Calvin system packages
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    net-tools && \
    rm -rf /var/lib/apt/lists/*


# Install R -------------------------------------------------------------------#
# NOTE: skipped, as we will be including R via NFS mount 

#RUN curl -O https://cdn.rstudio.com/r/ubuntu-${UBUNTU_VERSION}/pkgs/r-${R_VERSION}_1_amd64.deb && \
#    apt-get update && \
#    DEBIAN_FRONTEND=noninteractive gdebi --non-interactive r-${R_VERSION}_1_amd64.deb && \
#    rm -rf r-${R_VERSION}_1_amd64.deb && \
#    rm -rf /var/lib/apt/lists/*
#
#RUN ln -s /opt/R/${R_VERSION}/bin/R /usr/local/bin/R && \
#    ln -s /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript

# Install Python via Miniconda -------------------------------------------------#
# NOTE: skipped, as we will be including Python with Jupyter via NFS mount 

#ARG MINICONDA_DOWNLOAD_URL=https://repo.anaconda.com/miniconda
#RUN curl -o miniconda.sh ${MINICONDA_DOWNLOAD_URL}/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
#    bash miniconda.sh -bp /opt/python/${PYTHON_VERSION} && \
#    /opt/python/${PYTHON_VERSION}/bin/conda install -y python==${PYTHON_VERSION} && \
#    rm -rf miniconda.sh
#
#ENV PATH="/opt/python/${PYTHON_VERSION}/bin:${PATH}"
#
## Install Jupyter Notebook and RSW/RSC Notebook Extensions and Packages -------#
#
#RUN /opt/python/${PYTHON_VERSION}/bin/pip install \
#    jupyter \
#    jupyterlab \
#    rsp_jupyter \
#    rsconnect_jupyter \
#    rsconnect_python
#
#RUN /opt/python/${PYTHON_VERSION}/bin/jupyter-nbextension install --sys-prefix --py rsp_jupyter && \
#    /opt/python/${PYTHON_VERSION}/bin/jupyter-nbextension enable --sys-prefix --py rsp_jupyter && \
#    /opt/python/${PYTHON_VERSION}/bin/jupyter-nbextension install --sys-prefix --py rsconnect_jupyter && \
#    /opt/python/${PYTHON_VERSION}/bin/jupyter-nbextension enable --sys-prefix --py rsconnect_jupyter && \
#    /opt/python/${PYTHON_VERSION}/bin/jupyter-serverextension enable --sys-prefix --py rsconnect_jupyter

# Install VSCode code-server --------------------------------------------------#

RUN rstudio-server install-vs-code /opt/code-server/

# Locale configuration --------------------------------------------------------#

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y locales && \
    rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
