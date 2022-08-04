#!/bin/bash

# install Rstudio
export RSW_VERSION=2022.07.1-554.pro3
export RSW_NAME=rstudio-workbench
export RSW_DOWNLOAD_URL=https://s3.amazonaws.com/rstudio-ide-build/server/bionic/amd64

export RSW_VERSION_URL=`echo -n "${RSW_VERSION}" | sed 's/+/-/g'`
curl -O ${RSW_DOWNLOAD_URL}/${RSW_NAME}-${RSW_VERSION_URL}-amd64.deb
gdebi -n ${RSW_NAME}-${RSW_VERSION_URL}-amd64.deb
rm ${RSW_NAME}-${RSW_VERSION_URL}-amd64.deb
apt autoremove -y
apt clean
rm -f /var/lib/rstudio-server/r-versions

# drop conf files
cp -f r-versions /var/lib/rstudio-server/
cp -f r-versions /etc/rstudio/
cp -f rsession-profile /etc/rstudio/
