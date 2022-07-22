#!/bin/bash

# Note: this relies on Docker secrets to build, but that secret is not stored in Git.  This build script looks up one directory for rsession.env
# For github actions, should rely on the secrets stuff

docker build -t rsession:latest --secret id=sssd,src=../rsession.env .
