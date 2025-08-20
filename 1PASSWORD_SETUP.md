# 1Password Secret Management Setup for Signing Tools

## Overview
This document outlines the secure storage and management of signing-related secrets using 1Password for the DDEV Foundation Signing Tools project.

## 1Password Vault Structure

### Recommended Vault Name: `test-secrets`
*Note: Following DDEV's established pattern of using the "test-secrets" vault for all testing/CI secrets*

### Items to Create:

#### 1. **Apple Developer Credentials (APPLE_ID)**
- **Item Type**: Login  
- **Title**: `SIGNING_TOOLS_APPLE_ID`
- **Username**: `[APPLE_ID from GitHub secrets]`
- **Notes**: `Apple ID for DDEV Foundation signing tools`

#### 2. **App Specific Password**
- **Item Type**: Password
- **Title**: `SIGNING_TOOLS_APP_SPECIFIC_PASSWORD`
- **Password**: `[APP_SPECIFIC_PASSWORD from GitHub secrets]`
- **Notes**: `App-specific password for notarization`

#### 3. **Certificate Password**
- **Item Type**: Password
- **Title**: `SIGNING_TOOLS_SIGNING_PASSWORD`
- **Password**: `p9rnqSpjLmcf`
- **Notes**: `Password for macos_signing_tool_test_certfile.p12`

#### 4. **Certificate Files**
- **Item Type**: Secure Note
- **Title**: `Signing Tools Certificates`
- **Attachments**:
  - `macos_signing_tool_test_certfile.p12` (original)
  - `ddev_signing_tools.p12` (new DDEV Foundation cert)
  - `ddev_signing_tools_private_key.pem`
  - `ddev_signing_tools_cert.pem`
- **Notes**: 
  ```
  Certificate Details:
  - Original: Developer ID Application: DDEV Foundation (9HQ298V2BW)
  - New: Developer ID Application: DDEV Foundation (9HQ298V2BW)
  - Both use password: p9rnqSpjLmcf
  - Project-specific certificates (signing_tools only)
  ```

## 1Password Secret References

For GitHub Actions integration, use these reference paths:

```yaml
env:
  APPLE_ID: op://test-secrets/SIGNING_TOOLS_APPLE_ID/username
  APP_SPECIFIC_PASSWORD: op://test-secrets/SIGNING_TOOLS_APP_SPECIFIC_PASSWORD/credential
  SIGNING_TOOLS_SIGNING_PASSWORD: op://test-secrets/SIGNING_TOOLS_SIGNING_PASSWORD/credential
```

## Service Account Setup

### 1. Create 1Password Service Account
1. Go to 1Password Business/Team settings
2. Create new Service Account: `ddev-signing-tools-ci`
3. Grant **read-only** access to `test-secrets` vault
4. Save the service account token securely

### 2. GitHub Repository Setup
1. Add GitHub Repository Secret: `TESTS_SERVICE_ACCOUNT_TOKEN`
2. Value: `[Service Account Token from step 1]`
3. Add GitHub Repository Secret: `OP_SERVICE_ACCOUNT_TOKEN` 
4. Value: `[Same Service Account Token from step 1]`

*Note: `OP_SERVICE_ACCOUNT_TOKEN` is the fixed name required by 1Password's GitHub Action. We set its value to the same token as `TESTS_SERVICE_ACCOUNT_TOKEN` to follow DDEV's naming convention while satisfying 1Password's requirements.*

## GitHub Actions Integration

Update `.github/workflows/test.yml` to use 1Password:

```yaml
- name: Load 1Password secrets for signing tools
  if: ${{ env.TESTS_SERVICE_ACCOUNT_TOKEN != '' }}
  uses: 1password/load-secrets-action@v2
  with:
    export-env: true
  env:
    OP_SERVICE_ACCOUNT_TOKEN: "${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}"
    APPLE_ID: "op://test-secrets/SIGNING_TOOLS_APPLE_ID/username"
    APP_SPECIFIC_PASSWORD: "op://test-secrets/SIGNING_TOOLS_APP_SPECIFIC_PASSWORD/credential"
    SIGNING_TOOLS_SIGNING_PASSWORD: "op://test-secrets/SIGNING_TOOLS_SIGNING_PASSWORD/credential"
```

## Security Benefits

### Current State (GitHub Secrets)
- ❌ Secrets scattered across GitHub repository settings
- ❌ No audit trail for secret access
- ❌ Limited access control granularity
- ❌ No secret rotation tracking

### With 1Password
- ✅ Centralized secret management
- ✅ Detailed audit logs and access tracking
- ✅ Granular access control per vault/item
- ✅ Secret rotation and version history
- ✅ Team member access management
- ✅ Service account with minimal permissions

## Access Control

### Team Access
- **Admin Access**: Project maintainers
- **Read Access**: Developers who need to run signing locally
- **CI Access**: Service account (read-only, specific vault)

### Recovery Procedures
1. **Service Account Token Rotation**:
   - Generate new service account token in 1Password
   - Update `OP_SERVICE_ACCOUNT_TOKEN` in GitHub secrets
   - Revoke old token

2. **Certificate Password Change**:
   - Update password in 1Password vault
   - No GitHub secrets changes needed (pulled automatically)

3. **Emergency Access**:
   - Admin users can access vault directly through 1Password
   - Service account can be temporarily granted broader access if needed

## Implementation Checklist

### Phase 1: Setup
- [ ] Access existing 1Password vault: `test-secrets`
- [ ] Create secret items in test-secrets vault:
  - [ ] `SIGNING_TOOLS_APPLE_ID` (Login item)
  - [ ] `SIGNING_TOOLS_APP_SPECIFIC_PASSWORD` (Password item)
  - [ ] `SIGNING_TOOLS_SIGNING_PASSWORD` (Password item)
- [ ] Create service account: `ddev-signing-tools-ci`
- [ ] Set vault permissions for service account

### Phase 2: GitHub Integration
- [ ] Add `TESTS_SERVICE_ACCOUNT_TOKEN` to GitHub repository secrets
- [ ] Set `TESTS_SERVICE_ACCOUNT_TOKEN` value to the service account token from Phase 1
- [ ] Move `APPLE_ID` from GitHub secrets to GitHub environment variables
- [ ] Set `APPLE_ID` environment variable to `notarizer@ddev.com`
- [ ] Update `.github/workflows/test.yml` with 1Password action
- [ ] Test CI workflow with 1Password secrets
- [ ] Verify all secrets are loaded correctly

### Phase 3: Cleanup (After Merge)
- [ ] Remove old GitHub repository secrets:
  - `APPLE_ID` (moved to GitHub environment variable)
  - `APP_SPECIFIC_PASSWORD` (now loaded from 1Password)
  - `SIGNING_TOOLS_SIGNING_PASSWORD` (now loaded from 1Password)
- [ ] Confirm service account uses both token names correctly
- [ ] Document team access procedures
- [ ] Schedule periodic secret rotation review

## Future Certificate Management

When creating new certificates for other DDEV projects:
1. Create separate 1Password vault (e.g., `DDEV Project X Signing`)
2. Use separate service accounts for each project
3. Follow same structure and documentation pattern
4. Maintain project-specific certificate isolation

## Support and Documentation

- **1Password GitHub Action**: https://github.com/1Password/load-secrets-action
- **Service Account Setup**: https://developer.1password.com/docs/service-accounts/
- **Secret Reference Format**: https://developer.1password.com/docs/cli/secret-references/

---

**Created**: August 17, 2025  
**Project**: DDEV Foundation Signing Tools  
**Purpose**: Secure secret management for code signing workflow