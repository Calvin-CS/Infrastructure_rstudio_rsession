FROM calvincs.azurecr.io/base-sssdunburden:latest
LABEL maintainer="Chris Wieringa <cwieri39@calvin.edu>"

# Set versions and platforms
ARG R_VERSION=4.2.1
ARG PYTHON_VERSION=3.9.12
ARG BUILDDATE=20220822-02

# Do all run commands with bash
SHELL ["/bin/bash", "-c"] 

ENTRYPOINT ["/init"]

# Update s6
COPY s6-overlay/ /etc/s6-overlay

# s6-wait change to sssd-blocker check script
COPY --chmod=0755 inc/sssd-blocker* /root
RUN sed -i "s@%%PYTHON_VERSION%%@${PYTHON_VERSION}@" /root/sssd-blocker.sh

# Access control
RUN echo "ldap_access_filter = memberOf=CN=CS-Rights-rstudio,OU=Groups,OU=CalvinCS,DC=ad,DC=calvin,DC=edu" >> /etc/sssd/sssd.conf

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
    chmod 0777 /usr/lib/rstudio-server/resources/terminal/bash && \
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

