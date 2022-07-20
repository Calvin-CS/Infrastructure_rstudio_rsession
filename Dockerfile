FROM ubuntu:focal

LABEL maintainer="Chris Wieringa <cwieri39@calvin.edu>"

# Set versions and platforms
ARG UBUNTU_VERSION=2004
ARG UBUNTU_CODENAME=focal
ARG R_VERSION=4.2.0

# Start with base Ubuntu, and install all required dependencies
COPY inc/Rpackages.dep /root/Rpackages.dep
RUN apt update -y && \
    DEBIAN_FRONTEND=noninteractive xargs apt install -y < /root/Rpackages.dep && \
    rm -f /root/Rpackages.dep && \
    rm -rf /var/lib/apt/lists/*

# Install RStudio Workbench session components -------------------------------#

COPY inc/install-Rstudio.sh /root/install-Rstudio.sh
RUN apt update --fix-missing && \
    /root/install-Rstudio.sh && \
    rm -f /root/install-Rstudio.sh && \
    rm -rf /var/lib/apt/lists/* 

EXPOSE 8788/tcp

# Make NFS mount directories
RUN mkdir -p /home /opt/anaconda /opt/code-server /opt/python /opt/R /rprojects

# Install R -------------------------------------------------------------------#
# NOTE: skipped, as we will be including R via NFS mount.  However,
# add to the path
RUN ln -s /opt/R/${R_VERSION}/bin/R /usr/local/bin/R && \
    ln -s /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript

RUN rm -f /etc/rstudio/r-versions
COPY inc/r-versions /etc/rstudio/r-versions

# Install Python via Miniconda -------------------------------------------------#
# NOTE: skipped, as we will be including Python with Jupyter via NFS mount 

# Install VSCode code-server --------------------------------------------------#
# NOTE: skipped, as we will be including VSCode code-server via NFS mount 
#   however, we need to make sure we copy the conf files
COPY inc/vscode.conf /etc/rstudio/vscode.conf
COPY inc/vscode-user-settings.json /etc/rstudio/vscode-user-settings.json

# Debugging
RUN apt update -y && \
    DEBIAN_FRONTEND=noninteractive apt install -y netcat-openbsd \
    nmap \
    telnet && \
    rm -rf /var/lib/apt/lists/*

# Locale configuration --------------------------------------------------------#

RUN apt update -y && \
    DEBIAN_FRONTEND=noninteractive apt install -y locales && \
    rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
