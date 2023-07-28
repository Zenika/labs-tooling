#!/bin/bash

GCE_PROJECT_VALUE="#########"
DOMAIN_VALUE="#########"
ACME_EMAIL_ADDRESS="#########"

# Get the parent directory of the script
PARENT_DIRECTORY=$(git rev-parse --show-toplevel)
CI_CD_FOLDER_NAME=ci-cd-platform-deployment
# Perform multiple replacements using a single sed command
sed -e "s/\[GCE_PROJECT\]/$GCE_PROJECT_VALUE/g" \
    -e "s/\[DOMAIN\]/$DOMAIN_VALUE/g" \
    -e "s/\[ACME_EMAIL_ADDRESS\]/$ACME_EMAIL_ADDRESS/g" \
    "$PARENT_DIRECTORY/$CI_CD_FOLDER_NAME/traefik.yaml" > "$PARENT_DIRECTORY/$CI_CD_FOLDER_NAME/traefik-apply.yaml"
