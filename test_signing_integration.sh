#!/usr/bin/env bash

# Runs the real signing and notarization tests with credentials read from
# 1Password. Nothing is written to the repository; the certificate lives in a
# private temporary directory for the duration of this process only.

set -euo pipefail
umask 077

for command in op bats; do
    if ! command -v "$command" >/dev/null; then
        echo "This test requires '$command' on PATH." >&2
        exit 1
    fi
done

CERTIFICATE_REF="${CERTIFICATE_REF:-op://ddev-signing/2prggopnzml4kqotzzs3dgcsr4/ddev-developer-id-2026.p12}"
CERTIFICATE_PASSWORD_REF="${CERTIFICATE_PASSWORD_REF:-op://ddev-signing/2prggopnzml4kqotzzs3dgcsr4/certificate_password}"
APP_SPECIFIC_PASSWORD_REF="${APP_SPECIFIC_PASSWORD_REF:-op://test-secrets/SIGNING_TOOLS_APP_SPECIFIC_PASSWORD/credential}"
export CERTNAME="${CERTNAME:-Developer ID Application: DDEV Foundation (9HQ298V2BW)}"
export TEAM_ID="${TEAM_ID:-9HQ298V2BW}"

if [ -z "${APPLE_ID:-}" ]; then
    echo "Set APPLE_ID to the DDEV notarization Apple ID before running this test." >&2
    exit 1
fi

cert_dir=$(mktemp -d "${TMPDIR:-/tmp}/ddev-signing-cert.XXXXXXXX")
trap 'rm -rf "$cert_dir"' EXIT
export CERTFILE="$cert_dir/ddev-developer-id-2026.p12"

op read --out-file "$CERTFILE" "$CERTIFICATE_REF"
chmod 600 "$CERTFILE"
export SIGNING_TOOLS_SIGNING_PASSWORD="$(op read "$CERTIFICATE_PASSWORD_REF")"
export APP_SPECIFIC_PASSWORD="${APP_SPECIFIC_PASSWORD:-$(op read "$APP_SPECIFIC_PASSWORD_REF")}"

bats --verbose-run --show-output-of-passing-tests tests
