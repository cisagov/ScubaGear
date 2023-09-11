# CISA M365 Security Configuration Baseline for Power Platform

Microsoft Power Platform is a group of applications comprised of alow-code application development toolkit, business intelligence software, a custom chat bot creator, and app connectivity software.  This Secure Configuration Baseline (SCB) provides specific policies to help secure Power Platform security.

The Secure Cloud Business Applications (SCuBA) project run by the Cybersecurity and Infrastructure Security Agency (CISA) provides guidance and capabilities to secure federal civilian executive branch (FCEB) agencies’ cloud business application environments and protect federal information that is created, accessed, shared, and stored in those environments. 

The CISA SCuBA SCBs for M365 help secure federal information assets stored within M365 cloud business application environments through consistent, effective, and manageable security configurations. CISA created baselines tailored to the federal government’s threats and risk tolerance with the knowledge that every organization has different threat models and risk tolerance. Non-governmental organizations may also find value in applying these baselines to reduce risks.

The information in this document is being provided “as is” for INFORMATIONAL PURPOSES ONLY. CISA does not endorse any commercial product or service, including any subjects of analysis. Any reference to specific commercial entities or commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply endorsement, recommendation, or favoritism by CISA.

## License Compliance and Copyright

Portions of this document are adapted from documents in Microsoft’s [Microsoft 365](https://github.com/MicrosoftDocs/microsoft-365-docs/blob/public/LICENSE) and [Azure](https://github.com/MicrosoftDocs/azure-docs/blob/main/LICENSE) GitHub repositories. The respective documents are subject to copyright and are adapted under the terms of the Creative Commons Attribution 4.0 International license. Source documents are linked throughout this document. The United States Government has adapted selections of these documents to develop innovative and scalable configuration standards to strengthen the security of widely used cloud-based software services.

## Assumptions

The **License Requirements** sections of this document assume the organization is using an [M365 E3](https://www.microsoft.com/en-us/microsoft-365/compare-microsoft-365-enterprise-plans) or [G3](https://www.microsoft.com/en-us/microsoft-365/government) license level at a minimum. Therefore, only licenses not included in E3/G3 are listed.

## Key Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

The following section summarizes the various Power Platform applications referenced in this baseline:

1. **Power Apps**: Low-code application development software used
to create custom business applications. The apps can be developed as desktop,
mobile, and even web apps. Three different types of Power Apps can be
created:

   1. [**Canvas Apps**](https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/): These are drag and
    drop style developed apps, where
    users drag and add User Interface (UI) components to the screen.
    Users can then connect the components to data sources to display
    data in the canvas app.

   2. [**Model-Driven Apps**](https://learn.microsoft.com/en-us/power-apps/maker/model-driven-apps/): These are apps developed from an existing
    data source. They can be thought of as the inverse of a Canvas App.
    Since, you build the app from the source rather than building the UI and then connecting to the source like
    Canvas apps.

   3. [**Power Pages**](https://learn.microsoft.com/en-us/power-pages/): These apps that are developed to function as either internal or external facing websites.

2. [**Power Automate**](https://learn.microsoft.com/en-us/power-automate/): This is an online tool within Microsoft 365 and add-ins used to create automated workflows between apps
and services to synchronize files, get notifications, and collect data.

3. [**Power Virtual Agents**](https://learn.microsoft.com/en-us/power-virtual-agents/): These are custom chat bots for use in the stand-alone Power Virtual Agents web app or in a Microsoft Teams
channel.

4. [**Connectors**](https://learn.microsoft.com/en-us/connectors/connector-reference/): These are proxies or wrappers around an API that allow the underlying service to be accessed from Power Automate Workflows, Power Apps, or Azure Logic Apps.

5. [**Microsoft Dataverse**](https://learn.microsoft.com/en-us/power-apps/maker/data-platform/): This is a cloud database management system most
often used to store data in SQL-like tables. A Power App would then use
a connector to connect to the Dataverse table and perform create, read,
update, and delete (CRUD) operations.

# Baseline Policies

Baseline Policies in this document are targeted towards administrative controls that apply to
Power Platform applications at either the tenant or Power Platform
environment level. Additional Power Platform security settings can be
implemented at the app level, connector level, or Dataverse table level.
Refer to [Power Platform Microsoft Learn documentation](https://learn.microsoft.com/en-us/power-platform/) for those additional controls.

## 1. Creation of Power Platform Environments

By default, any user in the Azure Active Directory (AAD) Tenant can create additional environments. Enabling these controls will restrict the creation of new environments to users with the following admin roles: Global admins, Dynamics 365 admins, and Power Platform admins.

### Policies

#### MS.POWERPLATFORM.1.1v1
The ability to create production and sandbox environments SHALL be restricted to admins.

<!--Policy: MS.POWERPLATFORM.1.1v1; Criticality: SHALL -->
- _Rationale:_ Users creating new Power Platform environments may inadvertently bypass data loss prevention (DLP) policy settings or misconfigure the security settings of their environment.
- _Last Modified:_ June 2023
- Note: This control restricts creating environments to users with Global admin, Dynamics 365 service admin, Power Platform Service admins, or Delegated admin roles.

#### MS.POWERPLATFORM.1.2v1
The ability to create trial environments SHALL be restricted to admins.

<!--Policy: MS.POWERPLATFORM.1.2v1; Criticality: SHALL -->
- _Rationale:_ Users creating new Power Platform environments may inadvertently bypass DLP policy settings or misconfigure the security settings of their environment.
- _Last Modified:_ June 2023
- Note: This control restricts creating environments to users with Global admin, Dynamics 365 service admin, Power Platform Service admins, or Delegated admin roles.

### Resources

- [Control who can create and manage environments in the Power Platform
  admin center \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-platform/admin/control-environment-creation)

- [Power Platform \| Digital Transformation Agency of
  Australia](https://desktop.gov.au/blueprint/office-365.html#power-platform)

- [Microsoft Power Apps Documentation \| Power
  Apps](https://learn.microsoft.com/en-us/power-apps/)

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
1.  Follow the instructions the MS.POWERPLATFORM.1.1v1 instructions up to step **3**.

2.  Under **Who can create trial environments**, select **Only specific admins.**

## 2. Power Platform Data Loss Prevention Policies

To secure Power Platform environments, DLP
policies can be created to restrict the connectors used with
Power Apps created in an environment. A DLP policy can be created to
affect all or some environments or exclude certain environments. The
narrower policy will be enforced when there is a conflict.

Connectors can be separated by creating a DLP policy assigning them
to one of three groups: Business, Non-Business, and Blocked. Connectors
in different groups cannot be used in the same Power App. Connectors in
the Blocked group cannot be used at all. Note: Some M365 connectors
cannot be blocked (e.g., Teams and SharePoint connectors).

In the DLP policy, connectors can be configured to restrict read
and write permissions to the data source/service. Connectors that cannot
be blocked cannot be configured. Agencies should evaluate the
connectors and configure them to fit agency needs and security
requirements. The agency should then create a DLP policy to only allow
those connectors to be used in Power Platform.

When the Azure AD tenant is created, by default, a Power Platform
environment is created in Power Platform. This Power Platform
environment will bear the name of the tenant. There is no way to
restrict users in the Azure AD tenant from creating Power Apps in the
default Power Platform environment. Admins can restrict users from
creating apps in all other created environments.

### Policies

#### MS.POWERPLATFORM.2.1v1
A DLP policy SHALL be created to restrict connector access in the default Power Platform environment.

<!--Policy: MS.POWERPLATFORM.2.1v1; Criticality: SHALL -->
- _Rationale:_ All users in the tenant have access to the default Power Platform environment. Those users may inadvertently use connectors that share sensitive information with others who should not have access to it. Users requiring Power Apps should be directed to conduct development in other Power Platform environments with DLP connector policies customized to suit the user's needs while maintaining the agency's security posture.
- _Last Modified:_ June 2023
- _Note:_ The following connectors drive core Power Platform functionality and enable core Office customization scenarios: Approvals, Dynamics 365 Customer Voice, Excel Online (Business), Microsoft DataverseMicrosoft Dataverse (legacy), Microsoft Teams, Microsoft To-Do (Business), Office 365 Groups, Office 365 Outlook, Office 365 Users, OneDrive for Business, OneNote (Business), Planner, Power Apps Notification, Power BI, SharePoint, Shifts for Microsoft Teams, and Yammer; as such they remain non-blockable to ensure core user scenarios remain fully functional.

#### MS.POWERPLATFORM.2.2v1
Non-default environments SHOULD have at least one DLP policy affecting them.

<!--Policy: MS.POWERPLATFORM.2.2v1; Criticality: SHOULD -->
- _Rationale:_ Users may inadvertently use connectors that share sensitive information with others who should not have access to it. DLP policies provide a way for agencies to detect and prevent unauthorized disclosures.
- _Last Modified:_ June 2023

### Resources

- [Data Policies for Power Automate and Power Apps \| Digital
  Transformation Agency of
  Australia](https://desktop.gov.au/blueprint/office-365.html#power-apps-and-power-automate)

- [Create a data loss prevention (DLP) policy \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-platform/admin/create-dlp-policy)

- [DLP connector classification \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-platform/admin/dlp-connector-classification?source=recommendations)

- [DLP for custom connectors \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-platform/admin/dlp-custom-connector-parity?WT.mc_id=ppac_inproduct_datapol)
  
### License Requirements

- N/A

### Implementation

#### MS.POWERPLATFORM.2.1v1 instructions:
1.  Sign in to your tenant environment's respective [Power Platform admin
    center](https://learn.microsoft.com/en-us/power-platform/admin/powerapps-us-government#power-apps-us-government-service-urls).

2.  On the left pane, select **Policies** \> **Data Policies.**

3.  Select the **+ New Policy** icon to create a new policy.

4.  Give the policy a suitable agency name and click **Next.**

5.  At the **Prebuilt connectors** section, search and select the connectors currently in the **Non-business | default** tab containing sensitive data that can be utilized to create flows and apps.

6.  Click **Move to Business.** Connectors added to this group can not share data with connectors in other groups because connectors can reside in only one data group at a time. 

7.  If necessary (and possible) for the connector, click **Configure connector** at the top of the screen to change connector permissions. This allows greater flexibility for the agency to allow and block certain connector actions for additional customization. 

8.  For the default environment, move all other connectors to the **Blocked** category. For non-blockable connectors noted above, the Block action will be grayed out and a warning will appear.

9.  At the bottom of the screen, select **Next** to move on.

10.  Add a custom connector pattern. Custom connectors allow admins to specify an ordered list of Allow and Deny URL patterns for custom connectors.  View [DLP for custom connectors \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-platform/admin/dlp-custom-connector-parity?WT.mc_id=ppac_inproduct_datapol) for more information.

11.  Click **Next**.

12.  At the **Scope** section for the default environment, select **Add multiple environments** and add the default environment.

13.  Select **Next**-\> **Create Policy** to finish.

#### MS.POWERPLATFORM.2.2v1 instructions:
1.  Repeat steps 1 - 11 in the MS.POWERPLATFORM.2.1v1 instructions.

2.  At the **Scope** section for the default environment, select **Add multiple environments** and select the non-default environments you wish to enforce a DLP policy upon. If you wish to apply the DLP policy for all environments including environments created in the future select **Add all environments**.

4.  Select **Next**-\> **Create Policy** to finish.


## 3. Power Platform Tenant Isolation

Power Platform tenant isolation is different from Azure AD-wide tenant
restriction. It does not impact Azure AD-based access outside of Power
Platform. Power Platform tenant isolation only works for connectors
using Azure AD-based authentication, such as Office 365 Outlook or
SharePoint. The default configuration in Power Platform has tenant
isolation set to **Off**, allowing for cross-tenant connections to
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

<!--Policy: MS.POWERPLATFORM.3.1v1; Criticality: SHALL -->
- _Rationale:_ Provides an additional tenant isolation control on top of AAD tenant isolation specifically for Power Platform applications to prevent accidental or malicious cross tenant information sharing.
- _Last modified:_ June 2023

#### MS.POWERPLATFORM.3.2v1
An inbound/outbound connection allowlist SHOULD be configured.

<!--Policy: MS.POWERPLATFORM.3.2v1; Criticality: SHOULD -->
- _Rationale:_ Depending on agency needs an allowlist can be configured to allow cross tenant collaboration via connectors.
- _Last modified:_ June 2023
- Note: The allowlist may be empty if the agency has no need for cross tenant collaboration.

### Resources

- [Enable tenant isolation and configure allowlist \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-platform/admin/cross-tenant-restrictions#enable-tenant-isolation-and-configure-allowlist)

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

4.  If Tenant Isolation is switched **Off**, these rules will not be enforced until tenant
isolation is turned **On**.

## 4. Power Apps Content Security Policy

Content Security Policy (CSP) is an added security layer that helps
to detect and mitigate certain types of attacks, including Cross-Site
Scripting (XSS), clickjacking, and data injection attacks. When enabled, this setting can apply to all
current Canvas Apps and Model-driven apps at the Power Platform environment level.

###  Policies

#### MS.POWERPLATFORM.4.1v1
Content Security Policy SHALL be enforced for Model-driven and Canvas Power Apps.

<!--Policy: MS.POWERPLATFORM.4.1v1; Criticality: SHALL -->
- _Rationale:_ Adds CSP as a defense mechanism for Power Apps against common website attacks.
- _Last Modified:_ June 2023

### Resources

- [Content Security Policy \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-platform/admin/content-security-policy)

### License Requirements

- N/A

### Implementation

#### MS.POWERPLATFORM.4.1v1 instructions:
1.  Sign in to your tenant environment's respective [Power Platform admin
center](https://learn.microsoft.com/en-us/power-platform/admin/powerapps-us-government#power-apps-us-government-service-urls).

2.  On the left-hand pane click on **Environments** and then select an environment from the list.

3.  Select the **Settings** icon at the top of the page.

4.  Click on **Product** then click on **Privacy + Security** from the options that appear.

5.  At the bottom of the page under the **Content security policy** section, turn the slider **On** for **Model-driven** and **Canvas**.

6.  At the same location set **Enable reporting**  to **On** and add an appropriate endpoint CSP violations can be reported to.

7.  Repeat steps 2 - 6 for all active Power Platform environments.

## 5. Power Pages Creation

Power Pages formerly known as Power Portals are Power Apps specifically designed to act as external facing websites. By default any user in the tenant can create a Power Page. Admins can restrict the creation of new Power Pages to just admins.

###  Policies

#### MS.POWERPLATFORM.5.1v1
The ability to create Power Pages sites SHOULD be restricted to admins.

<!--Policy: MS.POWERPLATFORM.5.1v1; Criticality: SHOULD -->
- _Rationale:_ Users may unintentionally misconfigure their Power Pages to expose sensitive information or leave the website in a vulnerable state.
- _Last Modified:_ June 2023

### Resources
- [Control Portal Creation \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-apps/maker/portals/control-portal-creation)

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

- The MITRE Corporation
- Sandia National Laboratories (Sandia)

The SCBs were informed by materials produced by the following organizations: 


- Center for Internet Security (CIS)
- Internet Engineering Task Force (IETF)
- Mandiant
- Microsoft
- U.S. Defense Information Systems Agency (DISA)
- U.S. National Institute of Standards (NIST)
- U.S. Office of Management and Budget (OMB)

The cross-agency collaboration and partnerships developed during this initiative serve as an example for solving complex problems faced by the federal government. CISA also thanks the Cybersecurity Innovation Tiger Team (CITT) for its leadership and the following federal agencies that provided input during the development of the baselines:

- Consumer Financial Protection Bureau (CFPB)
- Department of the Interior (DOI)
- National Aeronautics and Space Administration (NASA)
- U.S. Office of Personnel Management (OPM)
- U.S. Small Business Administration (SBA)
- U.S. Census Bureau (USCB)
- U.S. Geological Survey (USGS)
