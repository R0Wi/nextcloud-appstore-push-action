#!/bin/bash
set -eo pipefail

# Used environment-variables:
#   APP_NAME
#   APPSTORE_TOKEN
#   APPSTORE_USERNAME
#   APPSTORE_PASSWORD
#   APPSTORE_URL
#   NIGHTLY
#   DOWNLOAD_URL
#   APP_PRIVATE_KEY_FILE

script_dir="$(dirname "$0")"

. "${script_dir}/functions.sh"

echo "Downloading app tarball for signing"
wget "$DOWNLOAD_URL" -O "${APP_NAME}.tar.gz"

echo "Creating signature for app release"
sign="`createsign ${APP_PRIVATE_KEY_FILE} ${APP_NAME}.tar.gz`"

echo "Creating new app release in Nextcloud appstore (nightly=${NIGHTLY})"

if [ ! -z $APPSTORE_TOKEN ]
then
    echo "Using token authentication"
    curl -s --fail-with-body --show-error -X POST $APPSTORE_URL -H "Authorization: Token ${APPSTORE_TOKEN}" -H "Content-Type: application/json" -d "{\"download\": \"${DOWNLOAD_URL}\", \"signature\": \"${sign}\", \"nightly\": ${NIGHTLY} }"
elif [ ! -z $APPSTORE_USERNAME  ] && [ ! -z $APPSTORE_PASSWORD ]
then
    echo "Using username password authentication"
    curl -s --fail-with-body --show-error -X POST $APPSTORE_URL -u "${APPSTORE_USERNAME}:${APPSTORE_PASSWORD}" -H "Content-Type: application/json" -d "{\"download\": \"${DOWNLOAD_URL}\", \"signature\": \"${sign}\", \"nightly\": ${NIGHTLY} }"
else
    echo "Authentication cannot be done. Please provide 'appstore_token' or 'appstore_username' and 'appstore_password' input variables."
    exit 1
fi
