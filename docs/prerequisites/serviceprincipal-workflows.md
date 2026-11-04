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
- `Set-ScubaGearAppPermission` - Adds required permissions, and removes unneeded permissions and role assignments

### Certificate Management
- `Get-ScubaGearAppCert` - Lists certificates for a service principal
- `New-ScubaGearAppCert` - Adds a new certificate to a service principal
- `Remove-ScubaGearAppCert` - Removes a certificate from a service principal

## Scope and Intended Use

> [!IMPORTANT]
> **This module is designed exclusively for ScubaGear.**
 - ✅ Creates a service principal for ScubaGear assessments
 - ✅ Manages ScubaGear product permissions and registrations (Entra, Exchange, SharePoint, Teams, SecuritySuite, Power Platform, and Power BI read-only Admin API access)
 - ✅ Handles certificate management
 - ✅ Audits and fixes ScubaGear Service Principal permission issues
 - ❌ NOT for general service principal management
 - ❌ NOT for other applications or custom permission sets

## Prerequisites

Before using the Service Principal module, ensure you have:

1. **ScubaGear module** installed (see [Installation Guide](../installation/github.md))
2. **Permissions Required** (Entra ID roles and Microsoft Graph API delegated permissions)

    > [!NOTE]
    > - **Entra ID roles**: Required roles vary by operation. Global Administrator satisfies the role requirements listed in the table.
    > - **Graph API scopes**: Functions automatically request these permissions when you run them. You must consent when prompted.

   | Function | Entra ID role | Microsoft Graph API Scopes |
   |----------|-------------------------------|---------------------------|
   | `New-ScubaGearServicePrincipal` | **Application Administrator** and **Privileged Role Administrator**<br><sup>Global Administrator works too</sup> | `Application.ReadWrite.All`<br>`AppRoleAssignment.ReadWrite.All`<br>`RoleManagement.ReadWrite.Directory`<br>`User.Read`<br>`Group.ReadWrite.All` |
   | `Get-ScubaGearAppPermission` | **Global Reader**<br><sup>Global Admin, Directory Writers, Hybrid Identity Admin, Security Admin, Cloud App Admin, or App Admin also work</sup> | `Application.Read.All`<br>`RoleManagement.Read.Directory`<br>`Group.Read.All` |
   | `Set-ScubaGearAppPermission` | **Application Administrator** and **Privileged Role Administrator**<br><sup>Global Administrator has both</sup> | `Application.ReadWrite.All`<br>`AppRoleAssignment.ReadWrite.All`<br>`RoleManagement.ReadWrite.Directory`<br>`Group.ReadWrite.All` |
   | `Get-ScubaGearAppCert` | **Global Reader**<br><sup>Global Admin, Cloud App Admin, or App Admin also work</sup> | `Application.Read.All` |
   | `New-ScubaGearAppCert`<br>`Remove-ScubaGearAppCert` | **Application Administrator**<br><sup>Global Admin, Cloud App Admin, or App Developer* also work</sup> | `Application.ReadWrite.All` |

   <sup>*Application Developer can only manage applications they own</sup>

   > [!NOTE]
   > `Get-ScubaGearAppPermission` checks Power BI and Power Platform registration
   > on every run, even when those products are not in `ProductNames`.
   > The audit (and standalone `Set-ScubaGearAppPermission`, which runs an audit)
   > can request delegated sign-ins to those admin APIs. The account needs the
   > Fabric Administrator role for Power BI tenant settings and the Power
   > Platform Administrator or Global Administrator role for Power Platform
   > registration. These are separate from the Microsoft Graph scopes
   > in the table above.
   >
   > When Power BI setup or remediation changes group membership, the account
   > also needs permission to manage that security group, such as being a group
   > owner or a Groups Administrator.

## Initial Setup Workflow

**Goal:** Create a new service principal with all necessary permissions for ScubaGear automation.

### Step 1: Plan Your Configuration

Before creating the service principal, determine:
- **Products to assess:** Choose from aad, exo, sharepoint, teams, securitysuite, powerplatform, powerbi, or use `*` for all products
- **Environment:** commercial, gcc, gcchigh, or dod
- **Certificate validity:** Default 6 months, customizable up to 12 months maximum

### Step 2: Preview with WhatIf

Test the creation without making changes:

```powershell
New-ScubaGearServicePrincipal `
    -M365Environment commercial `
    -ProductNames 'aad', 'exo', 'sharepoint', 'teams', 'securitysuite', 'powerplatform', 'powerbi' `
    -WhatIf
```

**What to look for:**
- App registration will be created
- Permissions to be granted
- Roles to be assigned
- Power BI read-only Admin API access setup, when `powerbi` is selected
- Certificate details

### Step 3: Create the Service Principal

Create the Service Principal:

```powershell
$NewSP = New-ScubaGearServicePrincipal `
    -M365Environment commercial `
    -ProductNames 'aad', 'exo', 'sharepoint', 'teams', 'securitysuite', 'powerplatform', 'powerbi' `
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

> [!NOTE]
> When `powerbi` is selected, the setup command enables the service principal access to Power BI
> **read-only admin APIs** tenant settings and
> associates the service principal with an allowed Entra security group. If
> existing allowed groups are configured, you can select one or create/use
> ScubaGear's dedicated group. The [manual Power BI setup steps](noninteractive.md#power-bi-tenant-setting)
> remain available when configuring a service principal without the ScubaGear
> helper commands.

> [!TIP]
> If the Power BI read-only Admin API tenant setting is already enabled for
> specific groups, but your service principal is not a member of any of them,
> `Get-ScubaGearAppPermission` shows that the service principal needs Power BI
> access. When you create the service principal or apply the suggested fix
> interactively, you can add it to an existing allowed group or create or use
> ScubaGear's dedicated group.
>
> ScubaGear's dedicated group is named `ScubaGear PowerBI Service Principals`;
> it is not a built-in Entra group. ScubaGear reuses an existing group with
> that name or creates one if needed, adds the service principal to it, and
> includes it in the tenant setting while preserving existing allowed groups.
> The group-selection prompt appears only when applying changes with
> `New-ScubaGearServicePrincipal` or `Set-ScubaGearAppPermission`, not when using
> `-WhatIf`. `Get-ScubaGearAppPermission` is read-only and does not support
> `-WhatIf`.
>
> Power BI can still list a group in the **Service principals can access
> read-only admin APIs** tenant setting after the group has been deleted from
> Entra ID. When ScubaGear encounters a group it cannot find in Entra ID during
> setup, it warns you and excludes that group from selection. Before configuring
> access, interactive setup asks whether to remove the stale entry from the
> Power BI tenant setting. This removes only the Power BI reference, not an
> Entra group. Declining or pressing Enter stops Power BI configuration without
> changing group membership or the tenant setting.
>
> If valid allowed groups remain, interactive setup lets you select one and,
> when the dedicated group is not already listed, offers to create or reuse
> `ScubaGear PowerBI Service Principals` instead. If no valid allowed groups
> remain, setup proceeds with that dedicated-group workflow without a
> group-selection prompt.
>
> Confirmed cleanup and the selected or new group's access are saved in one
> tenant-setting update; other allowed groups are preserved.
> Unattended setup does not approve stale-entry removal automatically. Remove
> stale entries from the Power BI tenant setting manually first.

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
    -ProductNames 'aad', 'exo', 'sharepoint', 'teams', 'securitysuite', 'powerplatform', 'powerbi'
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
- `ExtraRoles` - Direct Entra directory role assignments not required by the selected products; remediation removes them
- `DelegatedPermissions` - Delegated permissions to remove (ScubaGear requires application permissions only for non-interactive execution)
- `PowerPlatformRegistered` - Whether Power Platform is properly registered
- `PowerBIRegistered` - Whether Power BI read-only Admin API access is configured
- `PowerBIGroupMembership` - Whether the service principal belongs to a Power BI allowed security group
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
- Roles to be removed
- Power Platform registration changes
- Power BI allowed-group membership changes

> [!WARNING]
> Remediation can remove any directory role directly assigned to the service
> principal that is not required by the selected products, including roles
> assigned manually and high-privilege roles. Review `ExtraRoles` and the
> `-WhatIf` output before applying changes.

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
    -ProductNames $Audit.ProductNames
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
Invoke-Scuba `
    -AppID "your-app-id-here" `
    -CertificateThumbprint $NewCert.Thumbprint `
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

### Scenario 2: Add Power BI

**Example:** You need the service principal to assess Power BI in addition to
its currently configured products.

#### Step 1: Audit with Power BI selected

```powershell
$Audit = Get-ScubaGearAppPermission `
    -AppID "your-app-id-here" `
    -M365Environment commercial `
    -ProductNames 'aad', 'exo', 'sharepoint', 'teams', 'securitysuite', 'powerplatform', 'powerbi'
```

#### Step 2: Configure Power BI access

Review the proposed changes before applying them:

```powershell
$Audit | Set-ScubaGearAppPermission -WhatIf
```

If Power BI access is missing, apply the remediation:

```powershell
$Audit | Set-ScubaGearAppPermission
```

The setup adds the service principal to a selected or dedicated Entra security
group and configures the Power BI read-only Admin API tenant setting. Verify
with a new `Get-ScubaGearAppPermission` audit using the same product selection.

### Scenario 3: Remove Unused Products

**Example:** You no longer need Teams and SecuritySuite permissions, but still
need Power Platform and Power BI.

#### Step 1: Audit with Reduced Products

```powershell
$Audit = Get-ScubaGearAppPermission `
    -AppID "your-app-id-here" `
    -M365Environment commercial `
    -ProductNames 'aad', 'exo', 'sharepoint', 'powerplatform', 'powerbi'
```

**Expected result:** Shows extra permissions for Teams and SecuritySuite.
Power Platform registration and Power BI allowed-group membership are retained
because those products remain selected.

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
- **Configuration:** See [Parameters Reference](../configuration/parameters.md) for Invoke-Scuba parameters
