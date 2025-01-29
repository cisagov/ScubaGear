# Non-interactive Permissions

Running ScubaGear in a non-interactive (automated) fashion requires an application with a service principal identity that has been assigned various permissions and roles, depending upon which M365 products are being tested, and associated with a certificate.

> **Note**: While there are many ways to authenticate with a service principal, ScubaGear only authenticates via a certificate identified by its certificate thumbprint.

## Overview

These are the following steps that must be completed:

* Create a service principal
* Create a certificate
* Associate the certificate with the service principal
* Determining the thumbprint of the certificate

## Service Principal

Configuring a service principal is beyond the scope of these instructions, but Microsoft has documentation that may help:

* [Create a service principal](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal) in the Azure console.  
* Associate a [certificate with a service principal](https://learn.microsoft.com/en-us/cli/azure/azure-cli-sp-tutorial-3)

> **Note**: Take note of the AppId and the name of your tenant, as these values will be required to execute ScubaGear in non-interactive mode.

The minimum permissions and roles that must be assigned to the service principal are listed in the table below.

| ScubaGear Product       | API Permissions                                 | Role          | API Name                              | API APPID                             |
| ----------------------- | ----------------------------------------------- | ------------- | ------------------------------------- | ------------------------------------- |
| Entra ID (aad)          | User.Read.All                                   |               | Microsoft.Graph                       | 00000003-0000-0000-c000-000000000000  |
|                         | Directory.Read.All                              |               |                                       |                                       |
|                         | Policy.Read.All                                 |               |                                       |                                       |
|                         | PrivilegedEligibilitySchedule.Read.AzureADGroup |               |                                       |                                       |
|                         | PrivilegedAccess.Read.AzureADGroup              |               |                                       |                                       |
|                         | RoleAssignmentSchedule.Read.Directory           |               |                                       |                                       |
|                         | RoleEligibilitySchedule.Read.Directory          |               |                                       |                                       |
|                         | RoleManagementPolicy.Read.Directory             |               |                                       |                                       |
|                         | RoleManagementPolicy.Read.AzureADGroup          |               |                                       |                                       |
| Defender                |                                                 | Global Reader |                                       |                                       |
| Exchange (exo)          | Exchange.ManageAsApp                            | Global Reader | Office 365 Exchange Online            | 00000002-0000-0ff1-ce00-000000000000  |
|                         | Exchange.ManageAsApp                            |               | **Microsoft Exchange Online Protection**<sup>1</sup>| **00000007-0000-0ff1-ce00-000000000000**<sup>1</sup> |
| Power Platform          | (see below)                                     |               |                                       |                                       |
| SharePoint              | Sites.FullControl.All                           |               | SharePoint                            | 00000003-0000-0ff1-ce00-000000000000  |
| Microsoft Teams (teams) |                                                 | Global Reader |                                       |                                       |


> [!IMPORTANT]
> Required for Azure Government and DOD Tenants only (GCCH / DoD) [^1]

## Certificate Thumbprint

Microsoft has documentation that shows how to get the [thumbprint of a certificate](https://learn.microsoft.com/en-us/graph/applications-how-to-add-certificate?tabs=http#prerequisites) using PowerShell.

Once the service principal and certificate thumbprint have been created, ScubaGear's [dependencies](dependencies.md) can be installed.

## Power Platform

Power Platform requires additional, one-time setup.

### Registration

The application associated with the service principal must be [manually registered](https://learn.microsoft.com/en-us/power-platform/admin/powershell-create-service-principal#registering-an-admin-management-application) to Power Platform via interactive authentication with an administrative account before ScubaGear is executed. Microsoft explains the [limitations of service principals](https://learn.microsoft.com/en-us/power-platform/admin/powershell-create-service-principal#limitations-of-service-principals) with Power Platform.

To register the service principal, execute these commands:

```powershell
# Login interactively with a tenant admin for Power Platform
Add-PowerAppsAccount `
  -Endpoint prod `
  -TenantID 22f22c70-de09-4d21-b82f-af8ad73391d9
```

> **Note**: When testing [GCC tenants](https://learn.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/gcc), use `-Endpoint usgov`.

```powershell
# Register the service principal, giving it the 
# same permissions as a tenant admin
New-PowerAppManagementApp -ApplicationId abcdef0123456789abcde01234566789 
```

> **Note**:  These commands must be run from an account with the Power Platform Administrator or Global Administrator roles.

### Certificate Location

It's helpful to note the following details:

* Power Platform has a [hardcoded expectation](https://github.com/microsoft/Microsoft365DSC/issues/2781) that the certificate is located in `Cert:\CurrentUser\My`.

* MS Graph has an expectation that the certificate at least be located in one of the local client's certificate stores.
