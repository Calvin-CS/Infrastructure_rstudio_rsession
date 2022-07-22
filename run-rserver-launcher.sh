#!/bin/bash
docker run -it -p 8787:8787 -p 5559:5559 rsession /init /usr/lib/rstudio-server/bin/rserver-launcher --server-user rstudio-server -server-project-sharing 0 --server-shared-storage-path /var/lib/rstudio-server/shared-storage --pam-sessions-enabled 0 --stdin --rserver-address https://r.cs.calvin.edu:8787 --session-use-file-storage 1 --log-stderr --forward-environment 1 
