#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "No username supplied"
else
  docker run -it -p 8787:8787 -p 5559:5559 rsession sudo -u $1 /bin/bash
fi
