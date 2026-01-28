# Non-interactive Permissions

Running ScubaGear in a non-interactive (automated) fashion requires an application with a service principal identity that has been assigned various permissions and roles, depending upon which M365 products are being tested, and associated with a certificate.

> [!NOTE]
> While there are many ways to authenticate with a service principal, ScubaGear only authenticates via a certificate identified by its certificate thumbprint.<br>
> **GCC High users:** See [Additional GCC High Configuration](#additional-gcc-high-configuration) for environment-specific requirements before beginning setup.

### Table of Contents

- [Overview](#overview)
- [Service Principal Setup](#service-principal-setup)
  - [Automated Setup (Recommended)](#1-automated-setup-recommended)
  - [Manual Setup (Alternative)](#2-manual-setup-alternative)
  - [Power Platform Registration](#power-platform-registration)
- [Additional GCC High Configuration](#additional-gcc-high-configuration)

## Overview

ScubaGear supports two setup approaches:
- **Automated**: Functions handle all configuration automatically
- **Manual**: You configure permissions, certificates, and roles yourself

The minimum permissions and roles that must be assigned to the service principal are listed in the table below.

> [!IMPORTANT]
> Permissions that have "write" privileges are included in the [Power Platform](https://learn.microsoft.com/en-us/power-platform/admin/powershell-create-service-principal#limitations-of-service-principals) and [SharePoint](https://learn.microsoft.com/en-us/graph/permissions-selected-overview?tabs=http#what-permissions-do-i-need-to-manage-permissions) permissions list below. Those permissions are the minimum required by ScubaGear to be able to read admin center configurations for those two services and is a limitation of the underlying APIs of these services.<br> ScubaGear itself **never uses these write privileges** for its assessments.

| Product                 | API Permissions                                 | Role          | API Name                              | API APPID                             |
| ----------------------- | ----------------------------------------------- | ------------- | ------------------------------------- | ------------------------------------- |
| Entra ID                | Directory.Read.All                              |               | Microsoft.Graph                       | 00000003-0000-0000-c000-000000000000  |
|                         | Policy.Read.All                                 |               |                                       |                                       |
|                         | PrivilegedAccess.Read.AzureADGroup              |               |                                       |                                       |
|                         | PrivilegedEligibilitySchedule.Read.AzureADGroup |               |                                       |                                       |
|                         | RoleManagement.Read.Directory                   |               |                                       |                                       |
|                         | RoleManagementPolicy.Read.AzureADGroup          |               |                                       |                                       |
|                         | User.Read.All                                   |               |                                       |                                       |
| Defender for Office 365 |                                                 | Global Reader |                                       |                                       |
| Exchange Online         | Exchange.ManageAsApp                            | Global Reader | Office 365 Exchange Online<sup>1</sup>            | 00000002-0000-0ff1-ce00-000000000000  |
| Power Platform          | **Registration required** <sup>2</sup>                                     |               |                                       |                                       |
| SharePoint Online       | Sites.FullControl.All                           |               | SharePoint<sup>1</sup>                            | 00000003-0000-0ff1-ce00-000000000000  |
| Microsoft Teams         |                                                 | Global Reader |                                       |                                       |

> [!NOTE]
> Additional details necessary for GCC High non-interactive authentication are detailed in [this section](#additional-gcc-high-configuration).<sup>1</sup>
> Power Platform service principals require an additional one-time registration step via interactive login, detailed in [this section](#power-platform-registration).<sup>2</sup>

## Service Principal Setup

> [!IMPORTANT]
> ScubaGear offers both automated and manual service principal setup. We strongly recommend the automated approach for most users.

### 1. Automated Setup (Recommended)
> [!NOTE]
> The automated functions were **created exclusively for ScubaGear**. They configure service principals with the exact permissions and roles needed for ScubaGear assessments.

**Get started with automated setup:**
- [Service Principal Workflows](serviceprincipal-workflows.md/#initial-setup-workflow) - Step-by-step guide
- [Service Principal Troubleshooting](serviceprincipal-troubleshooting.md) - Solutions to common issues

---

### 2. Manual Setup (Alternative)

#### Step 1: Create the Service Principal

Microsoft provides documentation for manual service principal creation:
* [Create a service principal](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal) in the Microsoft Entra admin center.

#### Step 2: Assign Permissions

Assign the API permissions and roles listed in the [table above](#overview) based on which products you plan to assess.

> [!IMPORTANT]
> Ensure you grant admin consent for all API permissions after adding them.

#### Step 3: Configure Certificate Authentication
> [!IMPORTANT]
> Certificates must be stored in `Cert:\CurrentUser\My` due to Power Platform requirements.

1. Generate a certificate or use an existing one
   ```powershell
    # Example: Create a self-signed certificate for ScubaGear
    $cert = New-SelfSignedCertificate -Subject "CN=ScubaGear-$(Get-Date -Format 'yyyyMMdd')" -CertStoreLocation "Cert:\CurrentUser\My" -KeyExportPolicy Exportable -KeyLength 2048 -NotAfter (Get-Date).AddDays(180)
    ```
2. [Associate the certificate with the service principal](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal#option-2-testing-only-create-and-upload-a-self-signed-certificate)
3. Get the certificate thumbprint:
   ```powershell
   # List certificates in the correct location
   Get-ChildItem Cert:\CurrentUser\My | Where-Object {$_.Subject -like "*ScubaGear*"} | Select-Object Thumbprint,Subject,NotBefore,NotAfter
   ```

#### Step 4: Note Required Values

Save these values for running ScubaGear:
- **Application (client) ID**
- **Certificate thumbprint**

> [!NOTE]
> Continue to the [Power Platform Registration](#power-platform-registration) section below if you're assessing Power Platform.

## Power Platform Registration

> [!NOTE]
> This section applies to **both automated and manual setup methods**. Power Platform requires an additional one-time registration step regardless of how you created your service principal.<br>
> If you used the automated setup, you can skip to the verification step at the end of this section [Verify Registration](#step-3-verify-registration).

Power Platform requires the service principal to be manually registered via interactive authentication before ScubaGear can assess it. This is a [limitation of Power Platform service principals](https://learn.microsoft.com/en-us/power-platform/admin/powershell-create-service-principal#limitations-of-service-principals).

### Registration Steps

#### Step 1: Interactive Login

```powershell
# Login interactively with a Power Platform admin account
Add-PowerAppsAccount -Endpoint prod -TenantID "your-tenant-id"
```

> [!NOTE]
> **For GCC tenants:** Use `-Endpoint usgov`<br>
> **For GCC High tenants:** Use `-Endpoint usgovhigh`

#### Step 2: Register the Service Principal

```powershell
# Register the service principal with Power Platform admin permissions
New-PowerAppManagementApp -ApplicationId "your-app-id"
```

> [!IMPORTANT]
> - Replace `your-app-id` with your actual Application ID
> - This command requires **Power Platform Administrator** or **Global Administrator** role
> - This registration only needs to be done once per service principal

#### Step 3: Verify Registration

After registration, verify Power Platform permissions:

```powershell
# If using automated setup:
Get-ScubaGearAppPermission -AppID "your-app-id" -M365Environment "commercial" -ProductNames 'powerplatform'
```

## Additional GCC High Configuration

> [!NOTE]
> This section applies to **both automated and manual setup methods** when assessing GCC High tenants.

GCC High tenants require additional API permissions beyond the standard configuration due to differences in the GCC High environment.

### Defender for Office 365 in GCC High

When assessing Defender for Office 365 in GCC High:

**Required Permission:** `Exchange.ManageAsApp` must be added as an application permission from **both**:
1. `Microsoft Exchange Online Protection` API
2. `Office 365 Exchange Online` API

**Reference:** [Exchange Online App-Only Auth Documentation](https://learn.microsoft.com/en-us/powershell/exchange/app-only-auth-powershell-v2?view=exchange-ps#modify-the-app-manifest-to-assign-api-permissions) (see GCC High note)

**For automated setup:**
```powershell
# Use -M365Environment gcchigh when creating service principal
New-ScubaGearServicePrincipal `
    -M365Environment gcchigh `
    -ProductNames 'defender' `
    -ServicePrincipalName "ScubaGear-GCCHigh"
```

**For manual setup:**
1. In Entra Admin Center, go to your app registration
2. Select **API Permissions**
3. Add `Exchange.ManageAsApp` from both APIs listed above
4. Grant admin consent

### SharePoint Online in GCC High

When assessing SharePoint Online in GCC High:

**Required Permission:** `Sites.FullControl.All` must be added from the **GCC High-specific** API:
- Use: `Office 365 SharePoint Online` API (GCC High)
- NOT: `SharePoint` API (used in commercial tenants)

**For automated setup:**
```powershell
# Use -M365Environment gcchigh
New-ScubaGearServicePrincipal `
    -M365Environment gcchigh `
    -ProductNames 'sharepoint' `
    -ServicePrincipalName "ScubaGear-GCCHigh"
```

**For manual setup:**
1. In Entra Admin Center, go to your app registration
2. Select **API Permissions**
3. Add **Office 365 SharePoint Online** (NOT "SharePoint")
4. Add `Sites.FullControl.All` permission
5. Grant admin consent

### Verifying GCC High Configuration

```powershell
# Verify all permissions are correct for GCC High
Get-ScubaGearAppPermission `
    -AppID "your-app-id" `
    -M365Environment gcchigh `
    -ProductNames 'defender', 'sharepoint'
```