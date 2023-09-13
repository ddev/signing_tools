#!/usr/bin/env bash

set -eu -o pipefail

OS=$(uname -s)
if [ ${OS} = "Darwin" ]; then PATH="$(brew --prefix)/opt/gnu-getopt/bin:$PATH"; fi
if [ ${OS} = "Darwin" ] && [ ! -f "$(brew --prefix)/opt/gnu-getopt/bin/getopt" ]; then
    echo "This script requires 'brew install gnu-getopt'" && exit 1
fi

! getopt --test > /dev/null
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo '`getopt --test` failed in this environment.'
    exit 1
fi

if ! command -v jq >/dev/null ; then
    echo "jq is required for this script, please install jq to get it: 'brew install jq'"
    exit 2
fi

OPTS=-h
LONGOPTS=app-specific-password:,apple-id:,team-id:,primary-bundle-id:,target-binary:,help

! PARSED=$(getopt --options=$OPTS --longoptions=$LONGOPTS --name "$0" -- "$@" )
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    printf "\n\nFailed parsing options:\n"
    getopt --longoptions=$LONGOPTS --name "$0" -- "$@"
    exit 3
fi

eval set -- "$PARSED"

while true; do
    case "$1" in
    --app-specific-password)
        APP_SPECIFIC_PASSWORD=$2
        shift 2
        ;;
    --apple-id)
        APPLE_ID=$2
        shift 2
        ;;
    --team-id)
        TEAM_ID=$2
        shift 2
        ;;
    --primary-bundle-id)
        PRIMARY_BUNDLE_ID=$2
        shift 2
        ;;
    --target-binary)
        TARGET_BINARY=$2
        shift 2
        ;;
    -h|--help)
        echo "Usage: $0 --app-specific-password=<apple_app_specific_password> --apple-id=<apple_id_email> --team-id=<team_id> --primary-bundle-id=<java-style-bundle-id> --target-binary=<TARGET_BINARY_FULLPATH>"
        echo "Example: $0 --app-specific-password=\$DDEV_MACOS_APP_PASSWORD --apple-id=accounts@localdev.foundation --team-id=9HQ298V2BW --primary-bundle-id=com.ddev.ddev --target-binary=.gotmp/bin/darwin_amd64/ddev"
        exit 0
        ;;
    --)
        break;
    esac
done

if ! codesign -v ${TARGET_BINARY} ; then
    echo "${TARGET_BINARY} is not signed"
    exit 4
fi

/usr/bin/ditto -c -k --keepParent ${TARGET_BINARY} ${TARGET_BINARY}.zip ;

# Submit the zipball and wait for response
xcrun notarytool submit -f json --apple-id ${APPLE_ID} --team-id ${TEAM_ID}  --password ${APP_SPECIFIC_PASSWORD} --wait ${TARGET_BINARY}.zip 2>&1 | tee /tmp/notarization_info.json

status=$(jq -r .status </tmp/notarization_info.json)
id=$(jq -r .id </tmp/notarization_info.json)
#echo ${SUBMISSION_INFO} | jq -r

echo "status=${status} id=${id}"

xcrun notarytool log --apple-id ${APPLE_ID} --team-id ${TEAM_ID}  --password ${APP_SPECIFIC_PASSWORD} ${id} -f json >/tmp/notarization_log.json

issues=$(jq -r .issues </tmp/notarization_log.json)
if [ "$issues" != "null" ]; then
    printf "There are issues with the notarization (${issues})\n"
    printf "=== Log output === \n$(cat /tmp/notarization_log.json)\n"
    exit 7;
fi;

