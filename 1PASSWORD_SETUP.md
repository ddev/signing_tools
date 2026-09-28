# 1Password setup for DDEV signing

The shared DDEV Developer ID identity is production signing material. Its `.p12`
contains a private key and must never be committed to this repository or exposed
to pull-request workflows.

## Signing vault and item

Store the identity in the `ddev-signing` vault in a Secure Note named
`DDEV Developer ID Application`.

Attach `ddev-developer-id-2026.p12` and add these fields:

| Field | Value |
| --- | --- |
| `certificate_password` | Password used to export the `.p12` |
| `certificate_name` | `Developer ID Application: DDEV Foundation (9HQ298V2BW)` |
| `team_id` | `9HQ298V2BW` |
| `expires_at` | Certificate expiry in ISO 8601 format |
| `sha256_fingerprint` | Certificate SHA-256 fingerprint |
| `purpose` | Shared DDEV releases and signing_tools protected integration test |
| `rotation_owner` | Maintainer responsible for certificate rotation |

The current identity expires on 2031-09-17. The attachment name and item UUID
are part of the CI contract and are referenced as:

```text
op://ddev-signing/2prggopnzml4kqotzzs3dgcsr4/ddev-developer-id-2026.p12
```

## CI service account

Create a dedicated service account called `ddev-signing-tools-ci` with read-only
access to the `ddev-signing` vault. Store its token in the protected GitHub
environment named `signing` under the name `OP_SERVICE_ACCOUNT_TOKEN`.

Configure the `signing` environment with required reviewers and prevent
self-approval. Same-repository pull requests queue the signing job for this
approval; fork pull requests cannot access signing credentials.

Keep the token's recovery record in a separate administrator-only infrastructure
vault, not in `ddev-signing`. Do not share this token with other repositories;
give each repository its own service account for independent audit and revocation.

The workflow uses `1password/load-secrets-action@v4` to load
`certificate_password` and `op read` to write the attachment to a temporary,
owner-readable file. The file is removed at the end of the job.

## Local integration test

Maintainers with 1Password access can validate the full signing and notarization
path locally with:

```bash
make signing-integration-test
```

This requires an authenticated `op` CLI, Bats, read access to `ddev-signing` and
`test-secrets`, and `APPLE_ID` set to the same non-secret notarization address
configured in GitHub Actions. The command retrieves the `.p12` into a private
temporary directory and deletes it when the test exits. It does not create a
local, long-lived certificate copy.

## Rollout to ddev/ddev

`ddev/ddev` currently downloads `macos_sign.sh` from this repository's `master`
branch and supplies its own certificate file, password, and certificate name.
Keep the command-line interface of `macos_sign.sh` unchanged until DDEV has
migrated. In particular, it must continue to accept `--signing-password`,
`--cert-file`, `--cert-name`, and `--target-binary` for the existing Localdev
Foundation identity.

Roll out in this order:

1. Merge and manually run this repository's protected signing-integration
   workflow with the new identity.
2. Update `ddev/ddev` to retrieve the new `.p12` and its password from
   1Password, pass the new DDEV Foundation certificate name, and validate a
   signed/notarized build.
3. Pin DDEV's downloaded signing-tools revision to the tested commit or a tagged
   release instead of following `master` directly.
4. Only then make separately tested behavior changes to the signing scripts.

## Notarization credentials

Notarization currently uses the existing `test-secrets` service account to load
`SIGNING_TOOLS_APP_SPECIFIC_PASSWORD`. Move this credential to a dedicated
least-privilege notarization vault as a follow-up, or replace it with an App
Store Connect team API key after validating the required role.

## Rotation

1. Create a new private key and CSR on a maintainer-controlled Mac.
2. Create a new Developer ID Application certificate using the G2 Sub-CA.
3. Export it as a password-protected `.p12`, and record its identity and
   fingerprint in 1Password.
4. Update the attachment and metadata in the signing item.
5. Run the protected signing-integration workflow and verify signing and
   notarization before changing any DDEV release workflow.
6. Allow superseded test-only certificates to expire unless revocation is needed
   for a compromise.
