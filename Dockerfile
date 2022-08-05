FROM ubuntu:focal
LABEL maintainer="Chris Wieringa <cwieri39@calvin.edu>"

# Set versions and platforms
ARG UBUNTU_VERSION=2004
ARG UBUNTU_CODENAME=focal
ARG R_VERSION=4.2.0
ARG S6_OVERLAY_VERSION=3.1.1.2
ARG BUILDDATE=20220804-01

# Do all run commands with bash
SHELL ["/bin/bash", "-c"] 

# Start with base Ubuntu, add a few system packages
RUN apt update -y && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
    sssd \
    sssd-ad \
    sssd-krb5 \
    sssd-tools \
    libnfsidmap2 \
    libsss-idmap0 \
    libsss-nss-idmap0 \
    libnss-myhostname \
    libnss-mymachines \
    libnss-ldap \
    krb5-user \
    sssd-krb5 \
    unburden-home-dir && \
    rm -rf /var/lib/apt/lists/*

COPY inc/bashrc-unburden /root/bashrc-unburden
COPY inc/unburden-home-dir.conf /etc/unburden-home-dir
COPY inc/unburden-home-dir.list /etc/unburden-home-dir.list
COPY inc/unburden-home-dir /etc/default/unburden-home-dir
RUN cat /root/bashrc-unburden >> /etc/bash.bashrc && \
    rm -f /root/bashrc-unburden

# add CalvinAD trusted root certificate
COPY inc/CalvinCollege-ad-CA.crt /etc/ssl/certs/CalvinCollege-ad-CA.crt
RUN ln -s -f /etc/ssl/certs/CalvinCollege-ad-CA.crt /etc/ssl/certs/ddbc78f4.0

# Add all packages needed for R, and install all required dependencies
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_r_server/main/Rpackages.dep /root
RUN apt update -y && \
    DEBIAN_FRONTEND=noninteractive xargs apt install -y < /root/Rpackages.dep && \
    rm -f /root/Rpackages.dep && \
    rm -rf /var/lib/apt/lists/*

# Install RStudio Workbench session components -------------------------------#

ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_r_server/main/install-Rstudio.sh /root
RUN apt update -y --fix-missing && \
    /bin/sh /root/install-Rstudio.sh && \
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
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_r_server/main/r-versions /etc/rstudio
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_r_server/main/r-versions /var/lib/rstudio-server
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_r_server/main/rsession-profile /etc/rstudio

# Install Python via Miniconda -------------------------------------------------#
# NOTE: skipped, as we will be including Python with Jupyter via NFS mount 

# Install VSCode code-server --------------------------------------------------#
# NOTE: skipped, as we will be including VSCode code-server via NFS mount 
#   however, we need to make sure we copy the conf files
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_r_server/main/vscode.conf /etc/rstudio
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_r_server/main/vscode-user-settings.json /etc/rstudio

# Locale configuration --------------------------------------------------------#
RUN apt update -y && \
    DEBIAN_FRONTEND=noninteractive apt install -y locales && \
    rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Debugging
#RUN apt update -y && \
#    DEBIAN_FRONTEND=noninteractive apt install -y netcat-openbsd \
#    nmap \
#    telnet \
#    iputils-ping \
#    bind9-dnsutils && \
#    rm -rf /var/lib/apt/lists/*

# Drop all inc/ configuration files
# krb5.conf, sssd.conf, idmapd.conf
COPY inc/krb5.conf /etc/krb5.conf
COPY inc/nsswitch.conf /etc/nsswitch.conf
COPY inc/sssd.conf /etc/sssd/sssd.conf
RUN chmod 600 /etc/sssd/sssd.conf
RUN chown root:root /etc/sssd/sssd.conf
COPY inc/idmapd.conf /etc/idmapd.conf

# pam configs
COPY inc/common-auth /etc/pam.d/common-auth
COPY inc/common-session /etc/pam.d/common-session

# use the secrets to edit sssd.conf appropriately
RUN --mount=type=secret,id=LDAP_BIND_USER \
    source /run/secrets/LDAP_BIND_USER && \
    sed -i 's@%%LDAP_BIND_USER%%@'"$LDAP_BIND_USER"'@g' /etc/sssd/sssd.conf
RUN --mount=type=secret,id=LDAP_BIND_PASSWORD \
    source /run/secrets/LDAP_BIND_PASSWORD && \
    sed -i 's@%%LDAP_BIND_PASSWORD%%@'"$LDAP_BIND_PASSWORD"'@g' /etc/sssd/sssd.conf
RUN --mount=type=secret,id=DEFAULT_DOMAIN_SID \
    source /run/secrets/DEFAULT_DOMAIN_SID && \
    sed -i 's@%%DEFAULT_DOMAIN_SID%%@'"$DEFAULT_DOMAIN_SID"'@g' /etc/sssd/sssd.conf

# Setup multiple stuff going on in the container instead of just single access  -------------------------#
# S6 overlay from https://github.com/just-containers/s6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && \
    rm -f /tmp/s6-overlay-*.tar.xz

ENV S6_CMD_WAIT_FOR_SERVICES=1 S6_CMD_WAIT_FOR_SERVICES_MAXTIME=5000

ENTRYPOINT ["/init"]
COPY s6-overlay/ /etc/s6-overlay
