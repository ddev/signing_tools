#!/usr/bin/env bats

# Run these tests from the repo root directory, for example
# `bats tests` or `make test`

CERTFILE=tests/testdata/certs/macos_signing_tool_test_certfile.p12
CERTNAME="Developer ID Application: DDEV Foundation (9HQ298V2BW)"
TARGET_BINARY=/tmp/macos_sign_bats_dummy

# SIGNING_TOOLS_SIGNING_PASSWORD must be set by test runner

setup() {
    load setup.sh
    rm -f ${TARGET_BINARY}
    go build -o ${TARGET_BINARY} tests/testdata/helloworld.go
}

@test "Sign a dummy binary" {
    run ./macos_sign.sh --signing-password="${SIGNING_TOOLS_SIGNING_PASSWORD}" --cert-file=${CERTFILE} --cert-name="${CERTNAME}" --target-binary="${TARGET_BINARY}"
    assert_success

    run codesign -vv ${TARGET_BINARY}
    assert_success

    run codesign -vv -d "${TARGET_BINARY}"
    assert_success
    assert_output --partial "${CERTNAME}"
}
