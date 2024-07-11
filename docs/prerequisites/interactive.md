# Interactive Permissions

ScubaGear requires certain certain user permissions, and depending upon the M365 products tested, it may require certain application permissions as well.

## User Permissions

ScubaGear queries various M365 APIs to gather information about their security settings. To allow this, ScubaGear can authenticate with a user account that has the following minimum user roles for each M365 product.

| Product                 | Role                                                                    |
| ----------------------- | ----------------------------------------------------------------------- |
| Entra ID                | Global Reader                                                           |
| Defender for Office 365 | Global Reader (or Exchange Administrator)                               |
| Exchange Online         | Global Reader (or Exchange Administrator)                               |
| Power Platform          | Power Platform Administrator with a "Power Apps for Office 365" license |
| Sharepoint Online       | SharePoint Administrator                                                |
| Microsoft Teams         | Global Reader (or Teams Administrator)                                  |

> **Note**: Users with the Global Administrator role always have the necessary user permissions to run the tool.

[This article](https://learn.microsoft.com/en-us/microsoft-365/admin/add-users/assign-admin-roles?view=o365-worldwide) explains how to assign user roles in M365.

## Application Permissions

Testing the configurations of Entra ID and Sharepoint require the use of [Microsoft Graph PowerShell SDK](https://learn.microsoft.com/en-us/powershell/microsoftgraph/get-started?view=graph-powershell-1.0). If you are not testing these products, you can ignore this section.

To enable ScubaGear to run successfully, you must allow Graph to have a set of API permissions to run on your behalf. ScubaGear will attempt to configure the required API permissions needed by the Microsoft Graph PowerShell module, if they have not already been configured in the target tenant. Depending on the Entra ID roles assigned to the user running ScubaGear and how the application consent settings are configured in the target tenant, the process may vary slightly.

This workflow-like process is sometimes referred to as the _application consent process_, as an Administrator must _consent_ for the Microsoft Graph PowerShell application to access the tenant and the necessary Graph APIs to extract the configuration data.  To understand the application consent process, read [this article](https://learn.microsoft.com/en-us/azure/active-directory/develop/application-consent-experience) from Microsoft.

The following API permissions are required for Microsoft Graph Powershell:

- Directory.Read.All
- GroupMember.Read.All
- Organization.Read.All
- Policy.Read.All
- PrivilegedEligibilitySchedule.Read.AzureADGroup
- PrivilegedAccess.Read.AzureADGroup
- RoleManagement.Read.Directory
- RoleManagementPolicy.Read.AzureADGroup
- User.Read.All

> **Note**: Microsoft Graph PowerShell SDK appears as "unverified" on the AAD application consent screen. This is a long-standing [known issue](https://github.com/microsoftgraph/msgraph-sdk-powershell/issues/482).

Once the user and application permissions have been set, ScubaGear can be [executed](../execution/execution.md) in interactive mode.