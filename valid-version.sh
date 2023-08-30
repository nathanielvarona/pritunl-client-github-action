#!/bin/bash

###
## Pritunl Client Valid Version File Generator
###

OUTPUT_FILE="valid-version.txt"
CLIENT_REPO="pritunl/pritunl-client-electron"
RELEASES_API_URL="https://api.github.com/repos/$CLIENT_REPO/releases"

# File Information
cat <<EOF > $OUTPUT_FILE
##
## Pritunl Client Valid Version File
##
## This file is generated using \`$(basename "$0")\` script,
## and only applicable if GitHub action input \`client-version\` is used.
##
EOF

# Fetch the releases data using the API endpoint
PAGE=1
while true; do
  PAGE_URL="${RELEASES_API_URL}?page=${PAGE}"
  RESPONSE=$(curl -s "$PAGE_URL" | jq -r '.[] | .tag_name')

  # Break the loop if the response is empty
  if [ -z "$RESPONSE" ]; then
    break
  fi

  # Write the filtered response to the file
  echo "$RESPONSE" >> "$(dirname "$0")/$OUTPUT_FILE"
  PAGE=$((PAGE + 1))
done
