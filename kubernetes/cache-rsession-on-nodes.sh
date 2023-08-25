#!/bin/bash
# Author: Chris Wieringa <cwieri39@calvin.edu>
# Date: 2023-08-25
# Purpose: pull down to cache the rsession-daily image on all rstudio kubernetes nodes.
#    Meant to be run in cron every few hours. Logs to /tmp/cache-rsession-log-$DATETIME.txt

export LOGNAME=/tmp/cache-rsession-log-`date +%Y%m%d%k%M%S`.txt

{
    for NODE in $(/snap/bin/kubectl get nodes | /usr/bin/grep rstudio | /usr/bin/awk '{print $1;}')
    do
        
        # first generate a unique time for this run
        export DATETIME=`date +%Y%m%d%k%M%S%N`
        
        # use helm to deploy on the specified node
        echo "Installing rsession-daily on node ${NODE}"
        /snap/bin/helm upgrade --install --create-namespace --atomic --wait --namespace rstudio rsession-${DATETIME} ./rsession --set kubernetes.node=${NODE}
        /usr/bin/sleep 5
        echo " -- uninstalling now!"
        /snap/bin/helm uninstall rsession-${DATETIME} --namespace rstudio

    done
} > $LOGNAME