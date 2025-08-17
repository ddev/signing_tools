# macOS Code Signing Compatibility Fix - Product Requirements Document

## Problem Statement

The existing macOS code signing setup works on macOS 13 (Ventura) in CI but fails on macOS 15 (Sequoia) locally due to stricter certificate validation requirements. The current Apple Developer ID certificate, while valid, is not recognized by Sequoia's enhanced security model.

## Success Criteria

1. Successfully sign binaries on macOS 15 (Sequoia)
2. Maintain compatibility with existing CI workflows
3. Pass all existing tests on both macOS 13 and 15
4. Update CI to use a more recent macOS version
5. Secure secret management using 1Password

## Solution Components

### 1. Create New Apple Developer ID Certificate

**Objective**: Generate a new Developer ID certificate that's compatible with macOS 15 security requirements.

**Requirements**:
- Generate new private key using modern cryptographic standards
- Create Certificate Signing Request (CSR) 
- Submit CSR to Apple Developer Program
- Download new Developer ID Application certificate
- Export certificate and private key to PKCS#12 (.p12) format
- Verify certificate chain includes proper intermediate certificates

**Deliverables**:
- New private key file
- New .p12 certificate file with embedded private key
- Updated certificate password/passphrase
- Verification that certificate is recognized by `security find-identity -v -p codesigning`

### 2. Secure Secret Management with 1Password

**Objective**: Store all signing-related secrets securely in 1Password and document the setup.

**Requirements**:
- Create dedicated 1Password vault or item for signing tools secrets
- Store certificate password (`SIGNING_TOOLS_SIGNING_PASSWORD`)
- Store Apple ID credentials (`APPLE_ID`)
- Store app-specific password (`APP_SPECIFIC_PASSWORD`)
- Store Apple Team ID (`9HQ298V2BW`)
- Store certificate file (as secure note or attachment)
- Document secret locations and access procedures
- Create recovery documentation for secret rotation

**Deliverables**:
- 1Password vault with all signing secrets
- Documentation of secret storage structure
- Recovery procedures documentation
- Access control setup for team members

### 3. Local Binary Signing Verification

**Objective**: Verify that basic `codesign` operations work with the new certificate on macOS 15.

**Requirements**:
- Build test binary from `tests/testdata/helloworld.go`
- Successfully sign binary using: `codesign -s "Developer ID Application: [New Cert Name]" --timestamp --options runtime [binary]`
- Verify signature with: `codesign -vv [binary]`
- Confirm no `errSecInternalComponent` or chain validation errors

**Deliverables**:
- Working `codesign` command on macOS 15
- Signed test binary that passes verification

### 4. Update macos_sign.sh Script

**Objective**: Modify the signing script to work with the new certificate and macOS 15.

**Requirements**:
- Update certificate name parameter in script
- Update password/passphrase handling
- Test script execution: `./macos_sign.sh --signing-password=[password] --cert-file=[new.p12] --cert-name="[new cert name]" --target-binary=[binary]`
- Ensure cleanup function properly removes temporary keychains
- Verify script works on both macOS 13 and 15

**Deliverables**:
- Updated `macos_sign.sh` script
- Successful script execution on macOS 15
- Backward compatibility verification

### 5. Fix BATS Test Suite

**Objective**: Update test configuration to use new certificate and pass on macOS 15.

**Requirements**:
- Update `tests/01_macos_sign.bats` with new certificate details
- Update `CERTNAME` variable with new certificate name
- Replace test certificate file (`tests/testdata/certs/macos_signing_tool_test_certfile.p12`)
- Update `SIGNING_TOOLS_SIGNING_PASSWORD` environment variable
- Verify test passes: `bats tests/01_macos_sign.bats`

**Deliverables**:
- Updated test configuration
- Passing BATS tests on macOS 15
- Updated test certificate file

### 6. Update GitHub CI Configuration with 1Password Integration

**Objective**: Upgrade CI to use macOS 15, new certificate, and 1Password for secret management.

**Requirements**:
- Update `.github/workflows/test.yml` from `macos-13` to `macos-15` (or latest available)
- Replace GitHub Secrets with 1Password Secret References
- Configure 1Password Service Account for GitHub Actions
- Set up 1Password GitHub Action for secret retrieval
- Update workflow to pull secrets from 1Password at runtime
- Test notarization workflow with new certificate and secret management

**GitHub Actions 1Password Integration**:
```yaml
- name: Load secrets from 1Password
  uses: 1password/load-secrets-action@v1
  with:
    export-env: true
  env:
    SIGNING_TOOLS_SIGNING_PASSWORD: op://signing-tools/apple-certs/signing-password
    APPLE_ID: op://signing-tools/apple-certs/apple-id
    APP_SPECIFIC_PASSWORD: op://signing-tools/apple-certs/app-specific-password
```

**Deliverables**:
- Updated GitHub Actions workflow with 1Password integration
- 1Password Service Account configured for CI
- Successful CI run on macOS 15 with 1Password secrets
- Working notarization pipeline
- Removal of hardcoded GitHub Secrets

## Implementation Plan

### Phase 1: Certificate Generation (Estimated: 1-2 days)
1. Generate new private key and CSR
2. Submit to Apple Developer Program
3. Download and configure new certificate
4. Create new .p12 file

### Phase 2: Secret Management Setup (Estimated: 1 day)
1. Create 1Password vault and items
2. Store all signing-related secrets
3. Document secret structure and access procedures
4. Set up 1Password Service Account for CI

### Phase 3: Local Testing (Estimated: 1 day)
1. Test basic codesign functionality
2. Update and test macos_sign.sh script
3. Verify local BATS tests pass

### Phase 4: CI Updates (Estimated: 1 day)
1. Update GitHub workflow with 1Password integration
2. Configure 1Password GitHub Action
3. Test CI pipeline with new certificate and secret management
4. Verify notarization still works

## Risk Mitigation

- **Apple Developer Account Access**: Ensure access to Apple Developer Program for certificate generation
- **Certificate Validation Time**: Apple certificate approval can take time - plan accordingly
- **Backward Compatibility**: Test on macOS 13 to ensure new certificate doesn't break existing workflows
- **1Password Access**: Ensure proper 1Password account and permissions for secret management
- **Service Account Security**: Properly configure 1Password Service Account with minimal required permissions
- **Secret Rotation**: Plan for future certificate and password updates

## Security Considerations

- **Secret Storage**: All sensitive data stored in encrypted 1Password vault
- **Access Control**: Limit 1Password access to necessary team members only
- **Audit Trail**: 1Password provides audit logs for secret access
- **CI Security**: Service Account has read-only access to specific secrets only
- **Certificate Security**: .p12 files stored securely in 1Password, not in repository

## Acceptance Criteria

- [ ] New Apple Developer ID certificate generated and exported to .p12
- [ ] All signing secrets stored and documented in 1Password
- [ ] 1Password Service Account configured for GitHub Actions
- [ ] `codesign` command works on macOS 15 with new certificate
- [ ] `./macos_sign.sh` script executes successfully on macOS 15
- [ ] `bats tests/01_macos_sign.bats` passes on macOS 15
- [ ] GitHub CI updated to macOS 15 with 1Password secret management
- [ ] All GitHub Secrets removed and replaced with 1Password references
- [ ] Notarization workflow remains functional
- [ ] Secret management documentation complete
- [ ] Recovery procedures documented and tested

## Documentation Requirements

- [ ] 1Password vault structure and secret locations
- [ ] Certificate generation and renewal procedures
- [ ] GitHub Actions 1Password integration setup
- [ ] Troubleshooting guide for certificate issues
- [ ] Emergency access procedures for secrets
- [ ] Secret rotation schedule and procedures