# Service Principal Workflows

This guide provides step-by-step workflows for common Service Principal management tasks in ScubaGear.

## Overview

The benefits of using the ScubaGear Service Principal module include:
- Automated configuration of all required ScubaGear permissions
- Built-in validation and auditing
- Reduced risk of misconfiguration

### Setup
- `New-ScubaGearServicePrincipal` - Creates a new service principal with all required permissions based on products being assessed

### Permission Management
- `Get-ScubaGearAppPermission` - Audits an existing service principal's permissions
- `Set-ScubaGearAppPermission` - Fixes missing or incorrect permissions

### Certificate Management
- `Get-ScubaGearAppCert` - Lists certificates for a service principal
- `New-ScubaGearAppCert` - Adds a new certificate to a service principal
- `Remove-ScubaGearAppCert` - Removes a certificate from a service principal

## Scope and Intended Use

> [!IMPORTANT]
> **This module is designed exclusively for ScubaGear.**
 - ✅ Creates a service principal for ScubaGear assessments
 - ✅ Manages ScubaGear product permissions (Entra, Exchange, SharePoint, Teams, Defender, Power Platform)
 - ✅ Handles certificate management
 - ✅ Audits and fixes ScubaGear Service Principal permission issues
 - ❌ NOT for general service principal management
 - ❌ NOT for other applications or custom permission sets

## Prerequisites

Before using the Service Principal module, ensure you have:

1. **ScubaGear module** installed (see [Installation Guide](../installation/github.md))
2. **Permissions Required** (Entra ID roles and Microsoft Graph API delegated permissions)

    > [!NOTE]
    > - **Entra ID roles**: You need only ONE of the listed roles. The **bold** role is the least privileged option.
    > - **Graph API scopes**: Functions automatically request these permissions when you run them. You must consent when prompted.

   | Function | Entra ID Role (any one of)  | Microsoft Graph API Scopes |
   |----------|-------------------------------|---------------------------|
   | `New-ScubaGearServicePrincipal` | **Application Administrator**<br><sup>Global Admin, Security Admin, or Cloud App Admin also work</sup> | `Application.ReadWrite.All`<br>`RoleManagement.ReadWrite.Directory`<br>`User.Read` |
   | `Get-ScubaGearAppPermission` | **Global Reader**<br><sup>Global Admin, Directory Writers, Hybrid Identity Admin, Security Admin, Cloud App Admin, or App Admin also work</sup> | `Application.Read.All`<br>`RoleManagement.Read.Directory` |
   | `Set-ScubaGearAppPermission` | **Privileged Role Administrator**<br><sup>Global Admin, Directory Writers, Hybrid Identity Admin, Identity Governance Admin, User Admin, Cloud App Admin, or App Admin also work</sup> | `Application.ReadWrite.All`<br>`AppRoleAssignment.ReadWrite.All`<br>`RoleManagement.ReadWrite.Directory` |
   | `Get-ScubaGearAppCert` | **Global Reader**<br><sup>Global Admin, Cloud App Admin, or App Admin also work</sup> | `Application.Read.All` |
   | `New-ScubaGearAppCert`<br>`Remove-ScubaGearAppCert` | **Application Administrator**<br><sup>Global Admin, Cloud App Admin, or App Developer* also work</sup> | `Application.ReadWrite.All` |

   <sup>*Application Developer can only manage applications they own</sup>

## Initial Setup Workflow

**Goal:** Create a new service principal with all necessary permissions for ScubaGear automation.

### Step 1: Plan Your Configuration

Before creating the service principal, determine:
- **Products to assess:** Choose from aad, exo, sharepoint, teams, defender, powerPlatform, or use `*` for all products
- **Environment:** commercial, gcc, gcchigh, or dod
- **Certificate validity:** Default 6 months, customizable up to 12 months maximum

### Step 2: Preview with WhatIf

Test the creation without making changes:

```powershell
New-ScubaGearServicePrincipal `
    -M365Environment commercial `
    -ProductNames 'aad', 'exo', 'sharepoint', 'teams', 'defender', 'powerplatform' `
    -WhatIf
```

**What to look for:**
- App registration will be created
- Permissions to be granted
- Roles to be assigned
- Certificate details

### Step 3: Create the Service Principal

Create the Service Principal:

```powershell
$NewSP = New-ScubaGearServicePrincipal `
    -M365Environment commercial `
    -ProductNames 'aad', 'exo', 'sharepoint', 'teams', 'defender', 'powerplatform' `
    -ServicePrincipalName "ScubaGear-Production"
```

**Save the output:** The `$NewSP` variable contains critical information:
- `AppID` - Application (client) ID
- `CertThumbprint` - Certificate thumbprint for authentication

### Step 4: Verify Configuration

Confirm everything was set up correctly:

```powershell
Get-ScubaGearAppPermission `
    -AppID $NewSP.AppID `
    -M365Environment $NewSP.M365Environment `
    -ProductNames $NewSP.ProductNames
```

**Expected result:** Status should show "No action needed - service principal is correctly configured."

### Step 5: Document Credentials

- **Application ID:** `$NewSP.AppID`
- **Tenant ID:** Your Microsoft 365 tenant ID
- **Certificate Thumbprint:** `$NewSP.CertThumbprint`
- **Certificate Location:** `Cert:\CurrentUser\My\$($NewSP.CertThumbprint)`

### Step 6: Test Authentication

Verify the service principal can authenticate:

```powershell
Invoke-Scuba `
    -AppID $NewSP.AppID `
    -CertificateThumbprint $NewSP.CertThumbprint `
    -M365Environment $NewSP.M365Environment `
    -ProductNames $NewSP.ProductNames `
    -Organization 'example.onmicrosoft.com'
```

## Audit Existing Service Principal

**Goal:** Check if an existing service principal has correct permissions for ScubaGear.

### Step 1: Run Permission Audit

```powershell
$Audit = Get-ScubaGearAppPermission `
    -AppID "your-app-id-here" `
    -M365Environment commercial `
    -ProductNames 'aad', 'exo', 'sharepoint', 'teams', 'defender', 'powerPlatform'
```

### Step 2: Review Audit Results

Check the output properties:

```powershell
$Audit
```

**Look for:**
- `MissingPermissions` - Permissions that need to be added
- `ExtraPermissions` - Permissions that should be removed
- `MissingRoles` - Directory roles that need assignment
- `DelegatedPermissions` - Delegated permissions to remove (ScubaGear requires application permissions only for non-interactive execution)
- `PowerPlatformRegistered` - Whether Power Platform is properly registered
- `FixPermissionIssues` - Command to fix issues
- `Status` - Summary of issues found

### Step 3: Review Fix Command

If issues are found, check the suggested fix:

```powershell
$Audit.FixPermissionIssues
```

This shows you the exact command to remediate all issues.

## Fix Permission Issues

**Goal:** Automatically remediate permission problems identified during audit.

### Step 1: Review Changes with WhatIf

See what changes will be made:

```powershell
# Pipeline mode (recommended)
$Audit | Set-ScubaGearAppPermission -WhatIf

# Standalone mode
Set-ScubaGearAppPermission -AppID $Audit.AppID -M365Environment $Audit.M365Environment -ProductNames $Audit.ProductNames -WhatIf
```

**Review the output:**
- Permissions to be added
- Permissions to be removed
- Roles to be assigned
- Power Platform registration changes

### Step 2: Apply Remediation

Execute the fixes:

```powershell
$Audit | Set-ScubaGearAppPermission
```

### Step 3: Verify Remediation

Confirm all issues were resolved:

```powershell
Get-ScubaGearAppPermission `
    -AppID $Audit.AppID `
    -M365Environment $Audit.M365Environment `
    -ProductNames 'aad', 'exo', 'sharepoint', 'teams', 'defender', 'powerPlatform'
```

**Expected result:** Status should now show "No action needed."

## Certificate Rotation Workflow

**Goal:** Replace an expiring or expired certificate with a new one.

### Step 1: Check Certificate Status

Review current certificates:

```powershell
$CertStatus = Get-ScubaGearAppCert `
    -AppID "your-app-id-here" `
    -M365Environment commercial

# View summary
$CertStatus.CertificatesSummary
```

**Look for:**
- `HasExpiredCerts: True` - Expired certificates present
- `HasExpiringSoon: True` - Certificates expiring within 30 days
- Individual certificate expiration dates

### Step 2: Create New Certificate

Add a new certificate before removing the old one (zero-downtime rotation):

```powershell
$NewCert = New-ScubaGearAppCert `
    -AppID "your-app-id-here" `
    -M365Environment commercial `
    -CertValidityMonths 6
```

**Save the new thumbprint:** `$NewCert.Thumbprint`

### Step 3: Test New Certificate

Test ScubaGear execution with the new certificate:

```powershell
# Test with new certificate
Invoke-ScubaGear `
    -AppID "your-app-id-here" `
    -CertificateThumbprint $NewCert.Thumbprint `
    -M365Environment commercial `
    -ProductNames 'aad'
```

### Step 4: Remove Old Certificate

Once verified, remove the old certificate:

```powershell
# Identify the old certificate thumbprint
$OldThumbprint = 'OldCertificateThumbprintHere'

# Remove it
Remove-ScubaGearAppCert `
    -AppID "your-app-id-here" `
    -M365Environment commercial `
    -CertThumbprint $OldThumbprint
```

### Step 5: Verify Final State

Confirm only the new certificate remains:

```powershell
Get-ScubaGearAppCert `
    -AppID "your-app-id-here" `
    -M365Environment commercial
```

## Adjust Product Permissions

**Goal:** Add or remove product permissions from an existing service principal.

### Scenario 1: Add Additional Products

**Example:** You initially set up for AAD only, now need to add Exchange and SharePoint.

#### Step 1: Audit with New Products

```powershell
$Audit = Get-ScubaGearAppPermission `
    -AppID "your-app-id-here" `
    -M365Environment commercial `
    -ProductNames 'aad', 'exo', 'sharepoint'
```

**Expected result:** Shows missing permissions for Exchange and SharePoint.

#### Step 2: Add Missing Permissions

```powershell
$Audit | Set-ScubaGearAppPermission
```

### Scenario 2: Remove Unused Products

**Example:** You no longer need Teams and Defender permissions.

#### Step 1: Audit with Reduced Products

```powershell
$Audit = Get-ScubaGearAppPermission `
    -AppID "your-app-id-here" `
    -M365Environment commercial `
    -ProductNames 'aad', 'exo', 'sharepoint'
```

**Expected result:** Shows extra permissions for Teams and Defender.

#### Step 2: Remove Extra Permissions

```powershell
$Audit | Set-ScubaGearAppPermission
```

**Result:** Removes unnecessary permissions.

## Quick Reference

### Common Commands

| Task | Command |
|------|---------|
| Create service principal | `New-ScubaGearServicePrincipal` |
| Audit permissions | `Get-ScubaGearAppPermission` |
| Fix issues | `Set-ScubaGearAppPermission` |
| Check certificates | `Get-ScubaGearAppCert` |
| Add certificate | `New-ScubaGearAppCert` |
| Remove certificate | `Remove-ScubaGearAppCert` |

### Pipeline Workflows

```powershell
# Audit and fix in one step
Get-ScubaGearAppPermission -AppID $AppID -M365Environment commercial -ProductNames '*' |
    Set-ScubaGearAppPermission

# Find expired certificates
(Get-ScubaGearAppCert -AppID $AppID -M365Environment commercial).CertificatesSummary | Where-Object{$_.Status -eq 'Expired'}

# Export audit results, Can view with [Import-Clixml]
Get-ScubaGearAppPermission -AppID $AppID -M365Environment commercial -ProductNames '*' |
    Export-Clixml "audit-results.xml"
```

## Next Steps

- **Troubleshooting:** See [Service Principal Troubleshooting](serviceprincipal-troubleshooting.md) for common issues
- **Configuration:** See [Parameters Reference](../configuration/parameters.md) for Invoke-ScubaGear parameters
