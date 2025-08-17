#!/usr/bin/env bats

# Run these tests from the repo root directory, for example
# `bats tests` or `bats tests/macos_notarize.bats` or `make test`

# SIGNING_TOOLS_SIGNING_PASSWORD must be set by test runner
# APP_SPECIFIC_PASSWORD must be set by test runner

CERTFILE=tests/testdata/certs/macos_signing_tool_test_certfile.p12
CERTNAME="Developer ID Application: DDEV Foundation (9HQ298V2BW)"
TARGET_BINARY=/tmp/macos_notarize_dummy
APPLE_ID=notarizer@ddev.com
TEAM_ID="9HQ298V2BW"

function setup {
    rm -f ${TARGET_BINARY}
    go build -o ${TARGET_BINARY} tests/testdata/helloworld.go
    ./macos_sign.sh --signing-password="${SIGNING_TOOLS_SIGNING_PASSWORD}" --cert-file=${CERTFILE} --cert-name="${CERTNAME}" --target-binary="${TARGET_BINARY}"
}

@test "Notarize a signed dummy binary" {
    ./macos_notarize.sh  --app-specific-password=${APP_SPECIFIC_PASSWORD} --apple-id=${APPLE_ID} --team-id=${TEAM_ID} --primary-bundle-id=com.ddev.test-signing-tools --target-binary=${TARGET_BINARY}
}


