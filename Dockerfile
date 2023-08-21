FROM ubuntu:focal
LABEL maintainer="Chris Wieringa <cwieri39@calvin.edu>"

# Set versions and platforms
ARG R_VERSION=4.2.2
ARG PYTHON_VERSION=3.9.12
ARG BUILDDATE=20230818-3
ARG LIBSSL3_VERSION=0.1-1
ARG BUILDDATE=20230821-1

# Do all run commands with bash
SHELL ["/bin/bash", "-c"] 


# Start with some base packages
RUN apt update -y && \
    DEBIAN_FRONTEND=noninteractive apt install -y tar wget curl liblzma5 xz-utils && \
    rm -rf /var/lib/apt/lists/*

# Start with base Ubuntu
# Set timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo "$TZ" > /etc/timezone

# add CalvinAD trusted root certificate
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_configs/main/auth/CalvinCollege-ad-CA.crt /etc/ssl/certs/
RUN chmod 0644 /etc/ssl/certs/CalvinCollege-ad-CA.crt
RUN ln -s -f /etc/ssl/certs/CalvinCollege-ad-CA.crt /etc/ssl/certs/ddbc78f4.0

# Locale configuration --------------------------------------------------------#
RUN apt update -y && \
    DEBIAN_FRONTEND=noninteractive apt install -y locales && \
    rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV TERM xterm-256color
ENV TZ=US/Michigan

# Force set the TZ variable
COPY --chmod=0755 inc/timezone.sh /etc/profile.d/timezone.sh

# First, need to get the ubuntu-toolchain-r PPA
RUN apt update -y && \
    DEBIAN_FRONTEND=noninteractive apt install -y software-properties-common && \
    DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
    apt update -y && \
    apt dist-upgrade -y 

# Add all packages needed for R, and install all required dependencies
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_r_server/main/Rpackages.dep /root
RUN apt update -y && \
    DEBIAN_FRONTEND=noninteractive xargs apt install -y < /root/Rpackages.dep && \
    rm -f /root/Rpackages.dep && \
    rm -rf /var/lib/apt/lists/*

# add cpscadmin repo version of libssl3 for focal
ADD https://cpscadmin.cs.calvin.edu/repos/cpsc-ubuntu/dists/focal/main/packages/libssl3_${LIBSSL3_VERSION}_all.deb /root
RUN DEBIAN_FRONTEND=noninteractive apt install -y /root/libssl3_${LIBSSL3_VERSION}_all.deb && \
    rm -rf /var/lib/apt/lists/*

# Install cmdstan
#COPY --chmod=0755 inc/install-cmdstan.sh /root
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_r_server/main/install-cmdstan.sh /root
RUN chmod 0755 /root/install-cmdstan.sh && \
    /root/install-cmdstan.sh && \
    rm -f /root/install-cmdstan.sh

# Install RStudio Workbench session components -------------------------------#

ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_r_server/main/install-Rstudio.sh /root
RUN apt update -y --fix-missing && \
    /bin/sh /root/install-Rstudio.sh && \
    rm -f /root/install-Rstudio.sh && \
    chmod 0777 /usr/lib/rstudio-server/resources/terminal/bash && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 8788/tcp

# Install Quarto components ---------------------------------------------------#

ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_r_server/main/install-Quarto.sh /root
RUN apt update -y --fix-missing && \
    /bin/sh /root/install-Quarto.sh && \
    rm -f /root/install-Quarto.sh && \
    rm -rf /var/lib/apt/lists/*

# Make NFS mount directories
RUN mkdir -p /home /opt/anaconda /opt/code-server /opt/python /opt/R /opt/passwd

# Install R -------------------------------------------------------------------#
# NOTE: skipped, as we will be including R via NFS mount.  However,
# add to the path
RUN ln -s /opt/R/${R_VERSION}/bin/R /usr/local/bin/R && \
    ln -s /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript

RUN rm -f /etc/rstudio/r-versions
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_r_server/main/r-versions /etc/rstudio
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_r_server/main/r-versions /var/lib/rstudio-server
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_r_server/main/rsession-profile /etc/rstudio
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_r_server/main/rserver-minimal.conf /etc/rstudio/rserver.conf
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_r_server/main/rsession-minimal.conf /etc/rstudio/rsession.conf
RUN chmod 0644 /etc/rstudio/r-versions && \
    chmod 0644 /var/lib/rstudio-server/r-versions && \
    chmod 0644 /etc/rstudio/rsession-profile && \
    chmod 0644 /etc/rstudio/rserver.conf && \
    chmod 0644 /etc/rstudio/rsession.conf

# Install Python via Miniconda -------------------------------------------------#
# NOTE: skipped, as we will be including Python with Jupyter via NFS mount 

# Install VSCode code-server --------------------------------------------------#
# NOTE: skipped, as we will be including VSCode code-server via NFS mount 
#   however, we need to make sure we copy the conf files
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_r_server/main/vscode.conf /etc/rstudio
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_r_server/main/vscode-user-settings.json /etc/rstudio
RUN chmod 0644 /etc/rstudio/vscode.conf && \
    chmod 0644 /etc/rstudio/vscode-user-settings.json

# add unburden
RUN apt update -y && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
    unburden-home-dir && \
    rm -rf /var/lib/apt/lists/*

# add unburden config files
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_configs/main/auth/bashprofile-unburden /etc/profile.d/unburden.sh
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_configs/main/auth/unburden-home-dir.conf /etc/unburden-home-dir
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_configs/main/auth/unburden-home-dir.list /etc/unburden-home-dir.list
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_configs/main/auth/unburden-home-dir /etc/default/unburden-home-dir
RUN chmod 0755 /etc/profile.d/unburden.sh && \
    chmod 0644 /etc/unburden-home-dir && \
    chmod 0644 /etc/unburden-home-dir.list && \
    chmod 0644 /etc/default/unburden-home-dir

# Final fixup for PATH issues
RUN mkdir -p /export && \
    ln -s /opt/anaconda /export/anaconda && \
    ln -s /opt/python /export/python

# Cleanups
RUN rm -f /var/log/dpkg.log /var/log/lastlog /var/log/apt/* /var/log/*.log /var/log/fontconfig.log /var/log/faillog

# final entrypoint
CMD ["/usr/lib/rstudio-server/bin/rserver-launcher"]
