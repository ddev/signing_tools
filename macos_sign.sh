#!/usr/bin/env bash

set -o errexit

OS=$(uname -s)
if [ ${OS} = "Darwin" ]; then PATH="/usr/local/opt/gnu-getopt/bin:$PATH"; fi
if [ ${OS} = "Darwin" ] && [ ! -f "/usr/local/opt/gnu-getopt/bin/getopt" ]; then
    echo "This script requires 'brew install gnu-getopt'" && exit 1
fi

! getopt --test > /dev/null
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo '`getopt --test` failed in this environment.'
    exit 1
fi

OPTS=-h
LONGOPTS=signing-password:,cert-file:,cert-name:,target-binary:,help

! PARSED=$(getopt --options=$OPTS --longoptions=$LONGOPTS --name "$0" -- "$@"  )
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    printf "\n\nFailed parsing options:\n"
    getopt --longoptions=$LONGOPTS --name "$0" -- "$@"
    exit 2
fi

eval set -- "$PARSED"


while true; do
    case "$1" in
    --signing-password)
        SIGNING_PASSWORD=$2
        shift 2
        ;;
    --cert-name)
        CERT_NAME=$2
        shift 2
        ;;
    --cert-file)
        CERT_FILE=$2
        shift 2
        ;;
    --target-binary)
        TARGET_BINARY=$2
        shift 2
        ;;
    -h|--help)
        echo "Usage: $0 --signing-password=<cert_password> --cert-name='<name_of_cert>' --cert-file=<path-to-certfile> --target-binary=<TARGET_BINARY>"
        echo "Example: $0 --signing-password=\$DDEV_MACOS_SIGNING_PASSWORD --cert-file=../../../certfiles/ddev_developer_id_cert.p12 --cert-name='Developer ID Application: DRUD Technology, LLC (3BAN66AG5M)' --target-binary=ddev"
        exit 0
        ;;
    --)
        break;
    esac
done

set -o nounset pipefail

function cleanup {
    if [ ! -z "${default_keychain}" ]; then
        security default-keychain -s "$default_keychain" && security list-keychains -s "$default_keychain"
    fi
    security delete-keychain buildagent || true
}
trap cleanup EXIT

echo "Signing ${TARGET_BINARY}"
security create-keychain -p "${SIGNING_PASSWORD}" buildagent
security unlock-keychain -p "${SIGNING_PASSWORD}" buildagent
default_keychain=$(security default-keychain | xargs)
security list-keychains -s buildagent && security default-keychain -s buildagent
security import ${CERT_FILE} -k buildagent -P "${SIGNING_PASSWORD}" -T /usr/bin/codesign >/dev/null
security set-key-partition-list -S apple-tool:,apple: -s -k "${SIGNING_PASSWORD}" buildagent >/dev/null
codesign --keychain buildagent -s "${CERT_NAME}" --timestamp --options runtime ${TARGET_BINARY}
codesign -vv -d ${TARGET_BINARY}
echo "Signed ${TARGET_BINARY} with ${CERT_NAME}"
