#!/bin/bash

## Pritunl Client Valid Version Generator
## Generates `valid-version.txt` file

header_info=$(cat <<EOF
##
## Pritunl client valid versions.
## File generated using '$(basename "$0")' script.
##
EOF
)

echo "$header_info" > $(dirname "$0")/valid-version.txt

curl -s "https://api.github.com/repos/pritunl/pritunl-client-electron/tags" \
    | jq -r '.[].name' >> $(dirname "$0")/valid-version.txt
