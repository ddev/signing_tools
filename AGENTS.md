# AGENTS.md

Guidance for agents working on DDEV signing tools. This is the canonical
project instruction file.

## Scope

This repository provides macOS signing and notarization scripts for command-line
binaries. The signing identity is a shared DDEV Developer ID identity stored in
1Password; never add a certificate, private key, password, token, or other
credential to Git.

`ddev/ddev` downloads `macos_sign.sh` and `macos_notarize.sh` from this
repository's `main` branch. Preserve their command-line interfaces unless the
DDEV migration has been coordinated and tested. In particular, keep support for
the existing `--signing-password`, `--cert-file`, `--cert-name`, and
`--target-binary` arguments.

## Git workflow

Commit locally when asked. **Never run `git push`, `docker push`, or any other
publish command.** Do not offer to push. Report the local commit and leave
pushing to the maintainer.

Use branch names in the form `YYYYMMDD_<username>_<short_description>`. Create
new independent work from `upstream/main` when possible; preserve the current
branch when the work intentionally depends on unpushed commits.

Use Conventional Commit messages:

```text
<type>[optional scope]: <description>
```

Valid types are `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`,
`refactor`, `style`, and `test`.

## Testing and CI

Run the narrowest relevant validation:

```bash
bash -n macos_sign.sh macos_notarize.sh windows_sign.sh test_signing_integration.sh
actionlint .github/workflows/test.yml
```

The full signing/notarization integration test accesses 1Password and submits a
test artifact to Apple. Run it only when needed or requested:

```bash
APPLE_ID='notarizer@localdev.foundation' make signing-integration-test
```

It requires an authenticated `op` CLI and access to the `ddev-signing` and
`test-secrets` vaults. It retrieves the certificate into a temporary directory
and deletes it at exit.

Fork pull requests run PR-safe validation only. Same-repository pull requests
may run signing after approval through the `signing` environment. Scheduled
runs use the unattended `signing-automation` environment, restricted to `main`.

## Task Master

Task Master configuration is present locally under `.taskmaster/`. Do not run
`task-master init`; the project is already initialized. Use the existing Task
Master workflow only when the task calls for it.

## Working style

- Make small, compatible changes.
- Keep comments focused on why, rather than repeating code.
- Do not expose secret values in commands, logs, documentation, commits, or PR
  text.
- Use the project README and `1PASSWORD_SETUP.md` as the source of truth for
  signing setup and rotation.
