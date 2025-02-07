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

> **Important**: Permissions that have "write" privileges are included in the Power Platform and SharePoint application permissions. Those permissions are the minimum required by ScubaGear to be able to read admin center configuration settings. The mix of read and write privileges instead of fine-grained read-only privileges is an unfortunate access limitation of the underlying configuration setting APIs for these services. ScubaGear itself does not exercise the use of the write privileges for its assessments.

| Product                 | API Permissions                                 | Role          |
| ----------------------- | ----------------------------------------------- | ------------- |
| Entra ID                | Directory.Read.All, GroupMember.Read.All,       |               |
|                         | Organization.Read.All, Policy.Read.All,         |               |
|                         | RoleManagement.Read.Directory, User.Read.All    |               |
|                         | PrivilegedEligibilitySchedule.Read.AzureADGroup |               |
|                         | PrivilegedAccess.Read.AzureADGroup              |               |
|                         | RoleManagementPolicy.Read.AzureADGroup          |               |
| Defender for Office 365 | Exchange.ManageAsApp                            | Global Reader |
| Exchange Online         | Exchange.ManageAsApp                            | Global Reader |
| Power Platform          | (see below)                                     |               |
| SharePoint Online       | Sites.FullControl.All, Organization.Read.All    |               |
| Microsoft Teams         |                                                 | Global Reader |

> **Note** Additional details necessary for specifically GCC High non-interactive authentication are detailed in [this section](#additional-gcc-high-details) below.

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

## Certificate Location

It's helpful to note the following details:

* Power Platform has a [hardcoded expectation](https://github.com/microsoft/Microsoft365DSC/issues/2781) that the certificate is located in `Cert:\CurrentUser\My`.

* [MS Graph has an expectation](https://learn.microsoft.com/en-us/powershell/microsoftgraph/authentication-commands?view=graph-powershell-1.0#use-client-credential-with-a-certificate) that the certificate is located either in the client's `Cert:\CurrentUser\My` or `Cert:\LocalMachine\My` certificate stores.

## Additional GCC High details

This section is to note specific additional non-interactive authentication details to successfully run ScubaGear against a GCC High tenant.

### Defender in GCC High

Additional details for running ScubaGear to assess Defender for Office 365 in a GCC High tenant.

`Exchange.ManageAsApp` must be added as an application permission from BOTH the `Microsoft Exchange Online Protection` and the `Office 365 Exchange Online` APIs.
This is touched upon briefly in a GCC High application manifest writer's note in this section of the [Exchange Online App Only Auth MS Learn documentation](https://learn.microsoft.com/en-us/powershell/exchange/app-only-auth-powershell-v2?view=exchange-ps#modify-the-app-manifest-to-assign-api-permissions).

### SharePoint in GCC High

Additional details for running ScubaGear to assess SharePoint Online in a GCC High tenant.

The `Sites.FullControl.All` application permission must be added from the GCC High unique `Office 365 SharePoint Online` API rather than the commercial unique `SharePoint` API located in commercial/government community cloud tenants.