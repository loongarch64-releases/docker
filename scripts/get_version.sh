#!/bin/bash
set -eou pipefail

UPSTREAM_OWNER=moby
UPSTREAM_REPO=moby

curl -s https://api.github.com/repos/"$UPSTREAM_OWNER"/"$UPSTREAM_REPO"/releases/latest \
     | jq -r ".tag_name" \
     | grep -E '^docker-v.*' \
     | sed 's/docker-v//g'
