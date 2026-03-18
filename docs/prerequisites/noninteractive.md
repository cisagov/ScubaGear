# Non-interactive Permissions

Running ScubaGear in a non-interactive (automated) fashion requires an application with a service principal identity that has been assigned various permissions and roles, depending upon which M365 products are being tested, and associated with a certificate.

> [!NOTE]
> While there are many ways to authenticate with a service principal, ScubaGear only authenticates via a certificate identified by its certificate thumbprint.<br>

## Overview

The table below lists the minimum permissions and roles required for ScubaGear to read configuration data for each supported product.

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
| Power Platform          | Registration required <sup>2</sup>                                     |               |                                       |                                       |
| SharePoint Online       | Sites.FullControl.All                           |               | SharePoint<sup>1</sup>                            | 00000003-0000-0ff1-ce00-000000000000  |
| Microsoft Teams         |                                                 | Global Reader |                                       |                                       |

> [!NOTE]
> Additional details necessary for GCC High non-interactive authentication are detailed in [this section](#additional-gcc-high-details).<sup>1</sup><br>
> Power Platform service principals require an additional one-time registration step via interactive login, detailed in [this section](#power-platform-registration).<sup>2</sup>

## Service Principal Setup

ScubaGear supports two setup approaches:
- **Automated**: Custom PowerShell functions handle all configuration automatically
- **Manual**: You configure permissions, certificates, and roles yourself

### 1. Automated Setup (Recommended)
> [!NOTE]
> The custom PowerShell functions were **created exclusively for ScubaGear**. They configure service principals with the exact permissions and roles needed for ScubaGear assessments.

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

Continue to the [Power Platform Registration](#power-platform-registration) section below if you're assessing Power Platform.

## Power Platform Registration

> [!NOTE]
> This section applies to **manual setup methods**. Power Platform requires an additional one-time registration step regardless of how you created your service principal.<br>
> If you used the automated setup, you can skip to the verification step at the end of this section [Verify Registration](#step-3-verify-registration).

The Service Principal must be registered with Power Platform using interactive authentication **before** running ScubaGear. This is a [limitation of Power Platform service principals](https://learn.microsoft.com/en-us/power-platform/admin/powershell-create-service-principal#limitations-of-service-principals).

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
# Should return your AppID under 'applicationId'
Get-PowerAppManagementApp -ApplicationId "your-app-id"
```

## Additional GCC High details

This section contains additional, non-interactive authentication details that are required to successfully run ScubaGear against a GCC High tenant.

### Defender in GCC High

When running ScubaGear to assess Defender for Office 365 in a GCC High tenant, the `Exchange.ManageAsApp` must be added as an application permission from both the `Microsoft Exchange Online Protection` and the `Office 365 Exchange Online`  APIs. This is mentioned in a GCC High application manifest writer's note in this section of the [Exchange Online App Only Auth MS Learn documentation](https://learn.microsoft.com/en-us/powershell/exchange/app-only-auth-powershell-v2?view=exchange-ps#modify-the-app-manifest-to-assign-api-permissions).

### SharePoint in GCC High

When running ScubaGear to assess SharePoint Online in a GCC High tenant, the `Sites.FullControl.All` application permission must be added from the GCC High-unique `Office 365 SharePoint Online` API rather than the commercial-unique `SharePoint` API located in commercial/government community cloud tenants.