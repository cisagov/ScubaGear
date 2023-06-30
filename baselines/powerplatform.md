# Introduction

The Microsoft Power Platform is a group of applications involving
low-code application development, business intelligence, a custom chat
bot creator, and app connectivity software. The following summarizes the
Power Platform applications and other applications frequently used by
Power Platform.

**Power Apps**: This is a low-code application development software used
to create custom business applications. The apps can be used as desktop,
mobile, and web apps. Three different types of Power Apps can be
created:

1.  [**Canvas Apps**](https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/): These are drag and drop style developed apps, where
    users drag and add User Interface (UI) components to the screen.
    Users can then connect the components to data sources to display
    data in the canvas app.

2.  [**Model-Driven Apps**](https://learn.microsoft.com/en-us/power-apps/maker/model-driven-apps/): These apps are developed from an existing
    data source. They can be thought of as the inverse of a Canvas App.
    For those familiar with the Model-View-Controller design pattern,
    Model-Driven apps revolve around building the view and controller on
    top of the model.

3.  [**Power Pages**](https://learn.microsoft.com/en-us/power-pages/): These apps are created to function as either internal or external facing websites.

[**Power Automate**](https://learn.microsoft.com/en-us/power-automate/): This is an online tool within the Microsoft 365
applications and add-ins used to create automated workflows between apps
and services to synchronize files, get notifications, and collect data.

[**Power Virtual Agents**](https://learn.microsoft.com/en-us/power-virtual-agents/): These are custom chat bots for use in the
stand-alone Power Virtual Agents web app or in a Microsoft Teams
channel.

[**Connectors**](https://learn.microsoft.com/en-us/connectors/connector-reference/): These are proxies or wrappers around an API that allow the underlying service to be accessed from Power Automate Workflows, Power Apps, or Azure Logic Apps.

[**Microsoft Dataverse**](https://learn.microsoft.com/en-us/power-apps/maker/data-platform/): This is a cloud database management system most
often used to store data in SQL-like tables. A Power App would then use
a connector to connect to the Dataverse table and perform create, read,
update, and delete (CRUD) operations.

## Assumptions

The **License Requirements** sections of this document assume the
organization is using an [M365
E3](https://www.microsoft.com/en-us/microsoft-365/compare-microsoft-365-enterprise-plans)
or [G3](https://www.microsoft.com/en-us/microsoft-365/government)
license level. Therefore, only licenses not included in E3/G3 are
listed.

## Resources

**<u>License Compliance and Copyright</u>**

Portions of this document are adapted from documents in Microsoft’s
[Microsoft
365](https://github.com/MicrosoftDocs/microsoft-365-docs/blob/public/LICENSE)
and
[Azure](https://github.com/MicrosoftDocs/azure-docs/blob/main/LICENSE)
GitHub repositories. The respective documents are subject to copyright
and are adapted under the terms of the Creative Commons Attribution 4.0
International license. Source documents are linked throughout this
document. The United States Government has adapted selections of these
documents to develop innovative and scalable configuration standards to
strengthen the security of widely used cloud-based software services.

# Baseline

Baselines in this section are for administrative controls that apply to
all Power Platform applications at either the Power Platform tenant or
environment level. Additional Power Platform security settings can be
implemented at the app level, connector level, or Dataverse table level.
Refer to Microsoft Learn documentation for those additional controls.

## 1. Creation of Power Platform Environments

Power Platform environments are used to group together, manage, and
store Power Apps or Power Virtual Agents. By default, any user in the
Azure AD Tenant can create additional environments. Enabling this
control will restrict the creation of new environments to users with the
following admin roles: Global admins, Dynamics 365 admins, and Power
Platform admins.

### Policy

#### MS.POWERPLATFORM.1.1v1
The ability to create production and sandbox environments SHALL be restricted to admins.
- _Rationale:_ Users creating additional Power Platform environments may inadvertently bypass DLP policy settings or misconfigure the security settings of their environment.
- _Last Modified:_ June 2023
- Note: This control restricts the creation of environments to users with Global admin, Dynamics 365 service admin, Power Platform Service admins, or Delegated admin roles.

#### MS.POWERPLATFORM.1.2v1
The ability to create trial environments SHALL be restricted to admins.
- _Rationale:_ Users creating additional Power Platform environments may inadvertently bypass DLP policy settings or misconfigure the security settings of their environment.
- _Last Modified:_ June 2023
- Note: This control restricts the creation of environments to users with Global admin, Dynamics 365 service admin, Power Platform Service admins, or Delegated admin roles.

### Resources

- [Control who can create and manage environments in the Power Platform
  admin center \| Microsoft
  Documents](https://docs.microsoft.com/en-us/power-platform/admin/control-environment-creation)

- [Environment Administrator \| Digital Transformation Agency of
  Australia](https://desktop.gov.au/blueprint/office-365.html#power-platform)

- [Microsoft Technical Documentation \| Power
  Apps](https://docs.microsoft.com/en-us/power-apps/)

### License Requirements

- N/A

### Implementation

#### MS.POWERPLATFORM.1.1v1 instructions:
1.  Sign in to your tenant environment's respective [Power Platform admin
    center](https://learn.microsoft.com/en-us/power-platform/admin/powerapps-us-government#power-apps-us-government-service-urls).

2.  In the upper-right corner of the Microsoft Power Platform site,
    select the **Gear icon** (Settings icon).

3.  Select **Power Platform settings**.

4.  Under **Who can create production and sandbox environments**, select
    **Only specific admins.**

#### MS.POWERPLATFORM.1.2v1 instructions:
1.  Follow the instructions in the previous policy up to step **3**.

2.  Under **Who can create trial environments**, select **Only specific admins.**

## 2. Power Platform Data Loss Prevention Policies

To secure Power Platform environments, Data Loss Prevention (DLP)
policies can be created to restrict the connectors that can be used with
Power Apps created in an environment. A DLP policy can be created to
affect all or some environments or exclude certain environments. The
narrower policy will be enforced when there is a clash.

Connectors can be separated by creating a DLP policy that assigns them
to one of three groups: Business, Non-Business, and Blocked. Connectors
in different groups cannot be used in the same Power App. Connectors in
the Blocked group cannot be used at all. Note that some M365 connectors
cannot be blocked (e.g., Teams and SharePoint connectors).

In the DLP policy, connectors can also be configured to restrict read
and write permissions to the data source/service. Connectors that cannot
be blocked also cannot be configured. Agencies should evaluate the
connectors and configure them to fit with agency needs and security
requirements. The agency should then create a DLP policy to only allow
those connectors to be used in Power Platform.

When the Azure AD tenant is created, by default, a Power Platform
environment is created in Power Platform. This Power Platform
environment will bear the name of the tenant. There is no way to
restrict users in the Azure AD tenant from creating Power Apps in the
default Power Platform environment. Admins can restrict users from
creating apps in all other created environments.

### Policy

#### MS.POWERPLATFORM.2.1v1
A DLP policy SHALL be created to restrict connector access in the
default Power Platform environment.
- _Rationale:_ All users in the tenant have access to the default Power Platform environment. Those users may inadvertently use connectors that share sensitive information with others who should not have access to it. Users with a Power Apps need should be directed to conduct development in other Power Platform environments with DLP connector policies customized to suit the user's needs while maintaining the agency's security posture.
- _Last Modified:_ June 2023

#### MS.POWERPLATFORM.2.2v1
Non-default environments SHOULD have at least one DLP policy that
  affects them.
- _Rationale:_ Users may inadvertently use connectors that share sensitive information with others who should not have access to it. Data loss prevention (DLP) policies provide a way for agencies to detect and prevent unauthorized disclosures.
- _Last Modified:_ June 2023

#### MS.POWERPLATFORM.2.3v1
All connectors except those listed below SHOULD be added to the
Blocked category in the default environment policy:

  - Approvals

  - Dynamics 365 Customer Voice

  - Excel Online (Business)

  - Microsoft Dataverse

  - Microsoft Dataverse (legacy)

  - Microsoft Teams

  - Microsoft To-Do (Business)

  - Office 365 Groups

  - Office 365 Outlook

  - Office 365 Users

  - OneDrive for Business

  - OneNote (Business)

  - Planner

  - Power Apps Notification

  - Power BI

  - SharePoint

  - Shifts for Microsoft Teams

  - Yammer.

- _Rationale:_ All users in the tenant have access to the default Power Platform environment. Blocking all connectors in the default environment prevents inadvertent or malicious use of connectors by users in the agency's tenant.
- _Last modified:_ June 2023

### Resources

- [Data Policies for Power Automate and Power Apps \| Digital
  Transformation Agency of
  Australia](https://desktop.gov.au/blueprint/office-365.html#power-apps-and-power-automate)

- [Create a data loss prevention (DLP) policy \| Microsoft
  Docs](https://docs.microsoft.com/en-us/power-platform/admin/create-dlp-policy)

### License Requirements

- N/A

### Implementation

#### MS.POWERPLATFORM.2.1v1 instructions:
1.  Sign in to your tenant environment's respective [Power Platform admin
    center](https://learn.microsoft.com/en-us/power-platform/admin/powerapps-us-government#power-apps-us-government-service-urls).

2.  On the left pane, select **Policies** \> **Data Policies.**

3.  Select the **+ New Policy** icon to create a new policy.

4.  Give the policy a suitable agency name and click **Next.**

5.  At the **Prebuilt connectors** section, select the connectors that
fit the agency’s needs.

6.  Select a connector and click **Move to Business.**

7.  If necessary (and possible) for the connector, click **Configure
connector** at the top of the screen to change connector
permissions.

8.  Refer to Table 1 for those connectors to move which **Business/Non-Business** category.

9.  For the default environment, move all connectors that cannot be
blocked to the **Blocked** category.

10.  At the bottom of the screen, select **Next** to move on.

11.  Add a customer connector pattern that fit the agency’s needs. Click
**Next**.

12.  Define the scope of the policy. To use this policy for all environments including
ones created in the future select **Add all environments**.

13.  Otherwise for the default environment, select **Add multiple environments** and add the default environment.

14.  Select the environments over which to add the policy and click **Add
to policy** at the top.

15.  Select **Next**-\> **Create Policy** to finish.

#### MS.POWERPLATFORM.2.2v1 instructions:
1.  Repeat the steps above but for step **13** select the non-default environment you wish to enforce a DLP policy upon.

#### MS.POWERPLATFORM.2.3v1 instructions:
1.  Refer to steps **8** and **9** in the **MS.POWERPLATFORM.2.3v1** instructions to meet this policy.

## 3. Power Platform Tenant Isolation

Power Platform tenant isolation is different from Azure AD-wide tenant
restriction. It does not impact Azure AD-based access outside of Power
Platform. Power Platform tenant isolation only works for connectors
using Azure AD-based authentication, such as Office 365 Outlook or
SharePoint. The default configuration in Power Platform is with tenant
isolation set to **Off**, which allows for cross-tenant connections to
be established. A user from tenant A using a Power App with a connector
can seamlessly establish a connection to tenant B if using appropriate
Azure AD credentials.

If admins want to allow only a select set of tenants to establish
connections to or from their tenant, they can turn on tenant isolation.
Once tenant isolation is turned on, inbound (connections to the tenant
from external tenants) and outbound (connections from the tenant to
external tenants) cross-tenant connections are blocked by Power Platform
even if the user presents valid credentials to the Azure AD-secured data
source.

### Policies

#### MS.POWERPLATFORM.3.1v1
Power Platform tenant isolation SHALL be enabled.
- _Rationale:_ Provides an additional tenant isolation control on top of AAD tenant isolation specifically for Power Platform applications to prevent accidental or malicious cross tenant information sharing.
- _Last modified:_ June 2023

#### MS.POWERPLATFORM.3.2v1
An inbound/outbound connection allowlist SHOULD be configured.
- _Rationale:_ Depending on agency needs an allowlist can be configured to allow cross tenant collaboration via connectors.
- _Last modified:_ June 2023
- Note: The allowlist may be empty if the agency has no need for cross tenant collaboration.

### Resources

- [Enable tenant isolation and configure allowlist \| Microsoft
  Docs](https://docs.microsoft.com/en-us/power-platform/admin/cross-tenant-restrictions#enable-tenant-isolation-and-configure-allowlist)

### License Requirements

- N/A

### Implementation

#### MS.POWERPLATFORM.3.1v1 instructions:
1.  Sign in to your tenant environment's respective [Power Platform admin
    center](https://learn.microsoft.com/en-us/power-platform/admin/powerapps-us-government#power-apps-us-government-service-urls).

2.  On the left pane, select **Policies -\> Tenant Isolation**.

3.  Set the slider in the center of the screen to **On** then click **Save**
    on the bottom of the screen.

#### MS.POWERPLATFORM.3.2v1 instructions:
1.  Follow steps **1-2** in **MS.POWERPLATFORM.3.1v1 instructions** to
arrive at the same page.

2.  The tenant isolation allowlist can be configured by clicking **New tenant rule**
on the Tenant Isolation page.

3.  Select the **Direction** of the rule and add the **Tenant Domain or ID** this rule applies to.

4.  If Tenant Isolation is switched **Off**, these rules won't be enforced until tenant
isolation is turned **On**.

## 4. Power Apps Content Security Policy

Content Security Policy (CSP) is an added security layer that helps
to detect and mitigate certain types of attacks, including Cross-Site
Scripting (XSS), clickjacking, and data injection attacks. When enabled, this setting can apply to all
current Canvas Apps and Model-driven apps at the Power Platform environment level.

###  Policy

#### MS.POWERPLATFORM.4.1v1
Content Security Policy SHALL be enforced for Model-driven and Canvas Power Apps.
- _Rationale:_ Adds CSP as a defense mechanism for Power Apps against common website attacks.
- _Last Modified:_ June 2023

### Resources

- [Content Security Policy \| Microsoft
  Docs](https://docs.microsoft.com/en-us/power-platform/admin/content-security-policy)

### License Requirements

- N/A

### Implementation

#### MS.POWERPLATFORM.4.1v1 instructions:
1.  Sign in to your tenant environment's respective [Power Platform admin
center](https://learn.microsoft.com/en-us/power-platform/admin/powerapps-us-government#power-apps-us-government-service-urls).

2.  On the left-hand pane click on **Environments** and then select an environment from the list.

3.  Select the **Settings** icon that appears at the top of the page.

4.  Click on **Product** then click on **Privacy + Security** from the options that appear.

5.  At the bottom of the page under the **Content security policy** section, turn the slider **On** for **Model-driven** and **Canvas**

6.  Repeat steps 2 - 5 for all active Power Platform environments.

7.  At the same location set **Enable reporting**  to **On** and add an appropriate endpoint that CSP violations can be reported to.

## 5 Power Pages Creation

Power Pages formerly known as Power Portals are Power Apps specifically designed to act as external facing websites. By default by any user in the tenant can create a Power Page. Admins are able to restrict the creation of new Power Pages to just admins.

###  Policy

#### MS.POWERPLATFORM.5.1v1
The ability to create Power Pages sites SHOULD be restricted to admins.
- _Rationale:_ Users may unintentionally misconfigure their Power Pages to expose sensitive information or leave the website in a vulnerable state.
- _Last Modified:_ June 2023

### Resources
- [Control Portal Creation \| Microsoft
  Docs](https://learn.microsoft.com/en-us/power-apps/maker/portals/control-portal-creation)

### License Requirements

- N/A

### Implementation

#### MS.POWERPLATFORM.5.1v1 instructions:
1.  This setting currently can only be enabled through the [Power Apps PowerShell modules](https://learn.microsoft.com/en-us/power-platform/admin/powerapps-powershell#installation).

2. After installing the Power Apps PowerShell modules, run `Add-PowerAppsAccount -Endpoint $YourTenantsEndpoint`. To authenticate to your tenant's Power Platform.
Discover the valid endpoint parameter [here](https://learn.microsoft.com/en-us/powershell/module/microsoft.powerapps.administration.powershell/add-powerappsaccount?view=pa-ps-latest#-endpoint). Commercial tenants use `-Endpoint prod`, GCC tenants use `-Endpoint usgov` and so on.

3. Then run the following PowerShell command to disable the creation of Power Pages sites by non-administrative users.
```
Set-TenantSettings -RequestBody @{ "disablePortalsCreationByNonAdminUsers" = $true }
```


# Acknowledgements

In addition to acknowledging the important contributions of a diverse
team of Cybersecurity and Infrastructure Security Agency (CISA) experts,
CISA thanks the following federal agencies and private sector
organizations that provided input during the development of the Secure
Business Cloud Application’s security configuration baselines in
response to Section 3 of [Executive Order (EO) 14028, *Improving the
Nation’s
Cybersecurity*](https://www.federalregister.gov/documents/2021/05/17/2021-10460/improving-the-nations-cybersecurity):

- Consumer Financial Protection Bureau (CFPB)

- Department of the Interior (DOI)

- National Aeronautics and Space Administration (NASA)

- Sandia National Laboratories (Sandia)

- U.S. Census Bureau (USCB)

- U.S. Geological Survey (USGS)

- U.S. Office of Personnel Management (OPM)

- U.S. Small Business Administration (SBA)

The cross-agency collaboration and partnerships developed during this
initiative serve as an example for solving complex problems faced by the
federal government.

**Cybersecurity Innovation Tiger Team (CITT) Leadership**

Beau Houser (USCB), Sanjay Gupta (SBA), Michael Witt (NASA), James
Saunders (OPM), Han Lin (Sandia), Andrew Havely (DOI).

**CITT Authors**

Trafenia Salzman (SBA), Benjamin McChesney (OPM), Robert Collier (USCB),
Matthew Snitchler (Sandia), Darryl Purdy (USCB), Brandon Frankens
(NASA), Brandon Goss (NASA), Nicole Bogeajis (DOI/USGS), Kevin Kelly
(DOI), Adnan Ehsan (CFPB), Michael Griffin (CFPB), Vincent Urias
(Sandia), Angela Calabaza (Sandia).

**CITT Contributors**

Dr. Mukesh Rohatgi (MITRE), Lee Szilagyi (MITRE), Nanda Katikaneni
(MITRE), Ted Kolovos (MITRE), Thomas Comeau (MITRE), Karen Caraway
(MITRE), Jackie Whieldon (MITRE), Jeanne Firey (MITRE), Kenneth Myers
(General Services Administration).
