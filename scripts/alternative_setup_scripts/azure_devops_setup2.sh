#!/bin/bash

# Using REST API to upload secure file
DEVOPS_PAT="YOUR_PERSONAL_ACCESS_TOKEN"  # Generate from dev.azure.com
ORG="YOUR_ORG"
PROJECT="YOUR_PROJECT"
SSH_KEY_PATH="$HOME/.ssh/id_rsa"

# Upload secure file
curl -X POST "https://dev.azure.com/$ORG/$PROJECT/_apis/distributedtask/securefiles" \
  -H "Authorization: Basic $(echo -n ":$DEVOPS_PAT" | base64)" \
  -H "Content-Type: multipart/form-data" \
  -F "name=id_rsa" \
  -F "file=@$SSH_KEY_PATH"