# Setup an AAD app to run the Functional Test Orchestrator

This section describes how to setup an AAD application in the tenant when you want to run the test orchestrator using a **service principal (non interactive login)**. Setup for user interactive login is documented in a separate section.

Go to Azure AD > App Registrations and click New registration
![image](https://github.com/cisagov/ScubaGear/assets/107076927/ad9f7a2b-587b-4c06-b08a-8075e68c7df4)

Enter the name "Scuba Functional Test Orchestrator"
Under Who can use this application or API select Single tenant
Click Register
![image](https://github.com/cisagov/ScubaGear/assets/107076927/835d9eff-911b-4f3c-beda-ca0c65286ead)
![image](https://github.com/cisagov/ScubaGear/assets/107076927/cbd602c0-998e-435a-b621-621aee0a9aff)

Click on the API permissions page
Click Add a permission then select Microsoft Graph in the popup page. Note some of the permissions are not Graph so pay attention to special instructions below for those.
![image](https://github.com/cisagov/ScubaGear/assets/107076927/2640bf0b-4ebb-48a2-9f46-29f942f648fd)

Select Application permissions and then add all of the required permissions in the list below which are required for AAD. Once you have selected all of the permissions, click the Add permissions button.

## Microsoft Graph API permissions

- Directory.Read.All
- GroupMember.Read.All
- Organization.Read.All
- Policy.Read.All
- RoleManagement.Read.Directory
- User.Read.All
- PrivilegedEligibilitySchedule.Read.AzureADGroup
- PrivilegedAccess.Read.AzureADGroup
- RoleManagementPolicy.Read.AzureADGroup

## Office 365 Exchange Online API permissions (select from APIs my organization users)

- Exchange.ManageAsApp (so the application can run cmdlets in Exchange Online)

## Sharepoint API permissions (select from Microsoft APIs)

- Sites.FullControl.All (so the application can update Sharepoint settings)

![image](https://github.com/cisagov/ScubaGear/assets/107076927/998d4549-d31f-49a0-8d39-e75858dc8ae8)
![image](https://github.com/cisagov/ScubaGear/assets/107076927/8ead310d-4d66-4bab-a476-72e373c73cd1)
![image](https://github.com/cisagov/ScubaGear/assets/107076927/d51ccbc5-4c76-4989-9708-2a7b058e2244)
![image](https://github.com/cisagov/ScubaGear/assets/107076927/e4d2a461-6486-4666-970f-c94a24a5717d)
![image](https://github.com/cisagov/ScubaGear/assets/107076927/d6246581-483b-4cfb-8def-cdbc42589e36)
![image](https://github.com/cisagov/ScubaGear/assets/107076927/6d6081d3-b1a9-4d5b-abb1-41fa8ecc4005)

Click the Grant admin consent button on the API permissions page and click Yes in the popup
![image](https://github.com/cisagov/ScubaGear/assets/107076927/f5bcf13d-1cc4-4fa6-8750-1d7059f0ec6b)

The permissions page should now show that admin consent was granted for each of the permissions
![image](https://github.com/cisagov/ScubaGear/assets/107076927/6065fcba-f3c3-4a37-944f-f19c4c7e0e7a)

## Assigning user roles to the Scuba Functional Test Orchestrator application

Some of the products also need an AAD user role assigned to the application in order for it to be able to update the tenant settings when executing the functional tests.

## Assign the following user roles to the "Scuba Functional Test Orchestrator" application using the AAD role assignments page.  Note that these should be active assignments in tenants that include PIM

- Exchange Administrator (for EXO and most of the Defender cmdlets except for the compliance ones)
- Compliance Data Administrator (for Defender since it uses Purview compliance center cmdlets such as Set-DlpCompliancePolicy, Set-DlpComplianceRule, Set-ProtectionAlert)
- Teams Administrator

Here is an example screenshot that shows the service principal assigned to the Exchange Administrator role

![image](https://github.com/cisagov/ScubaGear/assets/107076927/6b90524a-0888-4201-80b1-0216bec5a503)

To complete the setup for PowerPlatform you must also execute the code below to register the service principal with Power Platform:

``` PowerShell
Add-PowerAppsAccount -Endpoint prod -TenantID $tenantId # use -Endpoint usgov for gcc tenants
New-PowerAppManagementApp -ApplicationId $appId
