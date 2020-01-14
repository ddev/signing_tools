#!/usr/bin/env bats

# Run these tests from the repo root directory, for example
# `bats tests` or `make test`

CERTFILE=tests/testdata/certs/macos_signing_tool_test_certfile.p12
CERTNAME="Developer ID Application: DRUD Technology, LLC (3BAN66AG5M)"
TARGET_BINARY=/tmp/macos_sign_bats_dummy

# SIGNING_TOOLS_SIGNING_PASSWORD must be set by test runner

function setup {
    rm -f ${TARGET_BINARY}
    go build -o ${TARGET_BINARY} tests/testdata/helloworld.go
}

@test "Sign a dummy binary" {
    ./macos_sign.sh --signing-password="${SIGNING_TOOLS_SIGNING_PASSWORD}" --cert-file=${CERTFILE} --cert-name="${CERTNAME}" --target-binary="${TARGET_BINARY}"
    codesign -vv ${TARGET_BINARY}
    codesign -vv -d ${TARGET_BINARY} 2>&1 | grep "$CERTNAME"
}


