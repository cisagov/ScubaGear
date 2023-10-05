# CISA M365 Security Configuration Baseline for Power BI

Power BI is the Software as a Service (SaaS) offering from Microsoft that facilitates self-service business intelligence dashboards, reports, datasets, and visualizations. Power BI can connect to multiple, different data sources, combine and shape data from those connections, then create reports and dashboards to share with others. This Secure Configuration Baseline (SCB) provides specific policies to strengthen Power BI security.

The Secure Cloud Business Applications (SCuBA) project run by the Cybersecurity and Infrastructure Security Agency (CISA) provides guidance and capabilities to secure federal civilian executive branch (FCEB) agencies’ cloud business application environments and protect federal information that is created, accessed, shared, and stored in those environments. 

The CISA SCuBA SCBs for M365 help secure federal information assets stored within M365 cloud business application environments through consistent, effective, and manageable security configurations. CISA created baselines tailored to the federal government’s threats and risk tolerance with the knowledge that every organization has different threat models and risk tolerance. Non-governmental organizations may also find value in applying these baselines to reduce risks.

The information in this document is being provided “as is” for INFORMATIONAL PURPOSES ONLY. CISA does not endorse any commercial product or service, including any subjects of analysis. Any reference to specific commercial entities or commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply endorsement, recommendation, or favoritism by CISA.

## License Compliance and Copyright 
Portions of this document are adapted from documents in Microsoft’s [Microsoft 365](https://github.com/MicrosoftDocs/microsoft-365-docs/blob/public/LICENSE) and [Azure](https://github.com/MicrosoftDocs/azure-docs/blob/main/LICENSE) GitHub repositories. The respective documents are subject to copyright and are adapted under the terms of the Creative Commons Attribution 4.0 International license. Source documents are linked throughout this document. The United States Government has adapted selections of these documents to develop innovative and scalable configuration standards to strengthen the security of widely used cloud-based software services.

## Assumptions
The **License Requirements** sections of this document assume the organization is using an [M365 E3](https://www.microsoft.com/en-us/microsoft-365/compare-microsoft-365-enterprise-plans) or [G3](https://www.microsoft.com/en-us/microsoft-365/government) license level at a minimum. Therefore, only licenses not included in E3/G3 are listed.


Agencies using Power BI have a data classification scheme in place for
  the data entering Power BI.

- Agencies may connect more than one data source to their Power BI
  tenant.

- All data sources use a secure connection for data transfer to and from
  the Power BI tenant; the agency disallows non-secure connections.

## Key Terminology
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

Access to PowerBI can be controlled by the user type. In this baseline,
the types of users are defined as follows (Note: these terms vary in use
across Microsoft documentation):

1.  **Internal users**: members of the agency’s M365 tenant.
2.  **External users**: members of a different M365 tenant.
3.  **Business to Business (B2B) guest users**: external users that are
  formally invited to view and/or edit Power BI workspace content and
  are added to the agency’s AAD as guest users. These users authenticate
  with their home organization/tenant and are granted access to Power BI
  content by virtue of being listed as guest users in the tenant’s AAD.


# Baseline Policies

## 1. Publish to Web

Power BI has a capability to publish reports and content to the web.
This capability creates a publicly accessible web URL that does not
require authentication or status as an Azure AD user to view it. While this
may be needed for a specific use case or collaboration scenario, it is a
best practice to keep this setting off by default to prevent unintended
and potentially sensitive data exposure.

If it is deemed necessary to make an exception and enable the feature,
administrators should limit the ability to publish to the web to only
specific security groups, instead of allowing the entire agency to
publish data to the web.

### Policies
#### MS.POWERBI.1.1v1
The Publish to Web feature SHOULD be disabled unless the agency mission requires the capability.

- _Rationale:_ Having a publicly accessible web URL means there is no way to control who is viewing information. By following this policy there will be no sensitive information published to the public web that could be accessed by a malicious actor.
- _Last modified:_ June 2023

### Resources

- [Power BI Tenant settings \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/admin/service-admin-portal-about-tenant-settings)

- [Power BI Security Baseline v2.0 \| Microsoft benchmarks GitHub
  repo](https://github.com/MicrosoftDocs/SecurityBenchmarks/blob/master/Azure%20Offer%20Security%20Baselines/2.0/power-bi-security-baseline-v2.0.xlsx)

### License Requirements

- N/A


### Implementation 
#### MS.POWERBI.1.1v1 instructions:

1. Navigate to the **PowerBI Admin Portal**

2. Click on **Tenant Settings**

3. Scroll to **Export and sharing settings**

4. Click **Publish to web** set to **Disabled**

## 2. Power BI Guest Access

This section provides policies helping reduce guest user access risks related to Power BI data and resources. An agency with externally shareable Power BI resources and data must consider its unique risk tolerance when granting access to guest users.

### Policies
#### MS.POWERBI.2.1v1
Guest user access to the Power BI tenant SHOULD be disabled unless the agency mission requires the capability.

- _Rationale:_ By disabling Power BI external access, this helps keep guest users from accessing potentially risky data/APIs. If an agency needs to allow guest access, it can be limited to users in specific security groups to help limit risk.
- _Last modified:_ June 2023

### Resources

- [Power BI Tenant settings \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/admin/service-admin-portal-about-tenant-settings)

- [Power BI Security Baseline v2.0 \| Microsoft benchmarks GitHub
  repo](https://github.com/MicrosoftDocs/SecurityBenchmarks/blob/master/Azure%20Offer%20Security%20Baselines/2.0/power-bi-security-baseline-v2.0.xlsx)

### License Requirements

- N/A

### Implementation
#### MS.POWERBI.2.1v1 instructions:
**TO DISABLE COMPLETELY**
1. Navigate to the **PowerBI Admin Portal**

2. Click on **Tenant Settings**

3. Scroll to **Export and sharing settings**

4. Click on **Allow Azure Active Directory guest users to edit and manage content in the organization** and set to **Disabled**

**TO ENABLE WITH SECURITY GROUP(S)**
1. Navigate to the **PowerBI Admin Portal**

2. Click on **Tenant Settings**

3. Scroll to **Export and sharing settings**

4. Click on **Allow Azure Active Directory guest users to edit and manage content in the organization** and set to **Enabled**

5. Select the security group(s) you want to have access to the PowerBI tenant. **Note**: you may need to create a security group for this specific case.

## 3. Power BI External Invitations

This section provides policies helping reduce guest user invitation risks related to Power BI data and resources.
The settings in this section control whether Power BI allows inviting external users to
the agency’s organization through Power BI’s sharing workflows and
experiences. After an external user accepts the invite, they become an
AAD B2B guest user in the organization. They will then appear in user
pickers throughout the Power BI user experience.

### Policies
#### MS.POWERBI.3.1v1
The Invite external users to your organization feature SHOULD be disabled unless agency mission requires the capability.

- _Rationale:_ Disabling this feature keeps internal users from inviting guest users. Therefore guest users can be limited from accessing potentially risky data/APIs. If an agency needs to allow guest access, the invitation feature can be limited to users in specific security groups to help limit risk.
- _Last modified:_ June 2023
- _Note:_ If this feature is disabled, existing guest users in the tenant continue to have access to Power BI items they already had access to and continue to be listed in user picker experiences. After it is disabled, an external user who is not already a guest user cannot be added to the tenant through Power BI.

### Resources

- [Power BI Tenant settings \| Microsoft
  Docs](https://learn.microsoft.com/en-us/power-bi/admin/service-admin-portal-about-tenant-settings)

- [Distribute Power BI content to external guest users with AAD B2B \|
  Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/enterprise/service-admin-azure-ad-b2b)

- [Power BI Security Baseline v2.0 \| Microsoft benchmarks GitHub
  repo](https://github.com/MicrosoftDocs/SecurityBenchmarks/blob/master/Azure%20Offer%20Security%20Baselines/2.0/power-bi-security-baseline-v2.0.xlsx)

### License Requirements

- N/A


### Implementation
#### MS.POWERBI.3.1v1 instructions:
**TO DISABLE COMPLETELY**
1. Navigate to the **PowerBI Admin Portal**

2. Click on **Tenant Settings**

3. Scroll to **Export and sharing settings**

4. Click on **Invite external users to your organization** and set to **Disabled**

**TO ENABLE WITH SECURITY GROUP(S)**
1. Navigate to the **PowerBI Admin Portal**

2. Click on **Tenant Settings**

3. Scroll to **Export and sharing settings**

4. Click on **Invite external users to your organization** and set to **Enabled**

5. Select the security group(s) needed. **Note**: You may need to make a specific security group(s)

## 4. Power BI Service Principals

Power BI supports using service principals to manage application
identities. Service principals can use application programming
interfaces (APIs) to access tenant-level features, controlled
by Power BI service administrators and enabled for the entire agency or for
agency security groups. Accessing service principals can be controlled
by creating dedicated security groups for them and using these groups in
any Power BI tenant level-settings. If service principals are employed
for Power BI, it is recommended service principal credentials used
for encrypting or accessing Power BI be stored in a Key Vault, with
properly assigned access policies and regularly reviewed access
permissions.

**Several high-level use cases for service principals:**

- There will be some cases where it is not possible to access
  a data source using service principals in Power BI. (e.g., Azure Table Storage).

- A user’s service principal for accessing the Power BI Service (e.g.,
  app.powerbi.com, app.powerbigov.us).

- Power BI Embedded and other users of the Power BI REST APIs to
  interact with PBI content.

### Policies
#### MS.POWERBI.4.1v1
Service Principals with access to APIs SHOULD be restricted to specific security groups.
- _Rationale:_ With unrestricted Service Principals there is possibility of unwanted access to APIs. By allowing Service Principals, through security groups, only where necessary, this will mitigate that risk. 
- _Last modified:_ June 2023

#### MS.POWERBI.4.2v1
Service Principals creating and using profiles SHOULD be restricted to specific security groups.
- _Rationale:_ With unrestricted Service Principals creating/using profiles there is a risk of an unauthorized user using a profile with more permissions than they have. By allowing Service Principals, through security groups, only where necessary, this will mitigate that risk. 
- _Last modified:_ June 2023

### Resources

- [Automate Premium workspace and dataset tasks with service principal
  \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/enterprise/service-premium-service-principal)

- [Embed Power BI content with service principal and an application
  secret \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/developer/embedded/embed-service-principal)

- [Embed Power BI content with service principal and a certificate \|
  Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/developer/embedded/embed-service-principal-certificate)

- [Enable service principal authentication for read-only admin APIs \|
  Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/enterprise/read-only-apis-service-principal-authentication)

- [Microsoft Power BI Embedded Developer Code Samples \| Microsoft
  GitHub](https://github.com/microsoft/PowerBI-Developer-Samples/blob/master/Python/Encrypt%20credentials/README.md)

- [Microsoft Power BI Security Baseline, Baseline Statement IM-2 \|
  Microsoft
  Learn](https://learn.microsoft.com/en-us/security/benchmark/azure/baselines/power-bi-security-baseline)

### License Requirements

- N/A


### Implementation
#### MS.POWERBI.4.1v1 instructions:
1. Navigate to the **PowerBI Admin Portal**

2. Click on **Tenant settings**

3. Scroll to **Developer settings**

4. Click on **Allow service principals to use Power BI APIs** set to **Enabled**.
Choose a specific security group allowed to use service principles for the APIs.


#### MS.POWERBI.4.2v1 instructions:
1. Navigate to the **PowerBI Admin Portal**

2. Click on **Tenant settings**

3. Scroll to **Developer settings**
   
4. Then, click on **Allow service principals to create and use profiles** set to **Enabled**.
Choose a specific security group allowed to use service principles to create and use profiles


## 5. Power BI ResourceKey Authentication


This setting pertains to the security and development of Power BI
embedded content. The Power BI tenant states “For extra security,
block using resource key-based authentication.” This baseline statement
recommends, but does not mandate, setting ResourceKey-based
authentication to the blocked state.

For streaming datasets created using the Power BI service user
interface, the dataset owner receives a URL including a resource
key. This key authorizes the requestor to push data into the dataset
without using an AAD OAuth bearer token, so please keep in mind the
implications of having a secret key in the URL when working with this
type of dataset and method.

This setting applies to streaming and PUSH datasets. If ResourceKey-based authentication is blocked, users will not be allowed to send data
to streaming and PUSH datasets using the API with a Resource-Key.
However, if developers have an approved need to leverage this feature,
an exception to the policy can be investigated.


### Policies
#### MS.POWERBI.5.1v1
ResourceKey Authentication SHOULD be blocked unless a specific use case (e.g., streaming and/or PUSH datasets) merits its use. <!--- remove the examples in the policy statement? -->

- _Rationale:_ By allowing resource keys someone can move data without AAD OAuth bearer token, causing possibly malicious or junk data to be stored. By disabling this, there is less risk an unauthorized individual will make changes. 
- _Last modified:_ June 2023

### Resources

- [Power BI Tenant settings \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/admin/service-admin-portal-about-tenant-settings)

- [Real-time streaming in Power BI \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/connect-data/service-real-time-streaming)

### License Requirements

- N/A


### Implementation
#### MS.POWERBI.5.1v1 instructions:
1. Navigate to the **PowerBI Admin Portal**

2. Click on **Tenant settings**

3. Scroll to **Developer settings**

4. Click on **Block ResourceKey Authentication** set to **Enabled**

## 6. Python and R Visual Sharing

Power BI can interact with Python and R scripts to integrate
visualizations from these languages. Python visuals are created from
Python scripts, which could contain code with security or privacy risks.
When attempting to view or interact with a Python visual for the first
time, a user is presented with a security warning message. Python and R
visuals should only be enabled if the author and source are trusted, or
after a code review of the Python/R script(s) in question is conducted
and deems the scripts free of security risks.


### Policies
#### MS.POWERBI.6.1v1
R and Python interactions SHOULD be disabled.

- _Rationale:_ External code poses a security and privacy risk as there is no good way to regulate what is done with the data or integrations. Disabling this will reduce the risk of a data leak or malicious actor. 
- _Last modified:_ June 2023

### Resources

- [Power BI Visuals and Python \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-python-visuals)

### License Requirements

- N/A


### Implementation
#### MS.POWERBI.6.1v1 instructions:
1. Navigate to the **PowerBI Admin Portal**

2. Click on **Tenant settings**

3. Scroll to **R and Python Visuals Settings**

4. Click on **Interact with and share R and Python visuals** set to **Disabled**

## 7. Power BI Sensitive Data

There are multiple ways to secure sensitive information, such as warning
users, encryption, or blocking attempts to share. Use Microsoft
Information Protection sensitivity labels on Power BI reports,
dashboards, datasets, and dataflows to guard sensitive content against
unauthorized data access and leakage. This can also guard against
unwanted aggregation and commingling.

**Note**: At this baseline’s time of writing, data loss prevention (DLP)
profiles are in preview status for Power BI. Once released for general
availability and government, DLP profiles represent another available
tool for securing power Power BI datasets. Refer to the *Defender for
Office 365 Minimum Viable Secure Configuration Baseline* for more on
DLP.

### Policies
#### MS.POWERBI.7.1v1
Sensitivity labels SHOULD be enabled for Power BI and employed for sensitive data per enterprise data protection policies.

- _Rationale:_ Without sensitivity labels it is possible for someone to open a document unknowingly, potentially reading information they are not supposed to access. This policy will help organize and classify data making it easier to keep data out of the wrong hands.   
- _Last modified:_ June 2023
### Resources

- [Enable sensitivity labels in Power BI \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/enterprise/service-security-enable-data-sensitivity-labels)

- [Data loss prevention policies for Power BI \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/enterprise/service-security-dlp-policies-for-power-bi-overview)

- [Data Protection in Power BI \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/enterprise/service-security-data-protection-overview)

- [Power BI Security Baseline v2.0 \| Microsoft benchmarks GitHub
  repo](https://github.com/MicrosoftDocs/SecurityBenchmarks/blob/master/Azure%20Offer%20Security%20Baselines/2.0/power-bi-security-baseline-v2.0.xlsx)

### License Requirements

- An Azure Information Protection Premium P1 or Premium P2 license is
  required to apply or view Microsoft Information Protection sensitivity
  labels in Power BI. Azure Information Protection can be purchased
  either standalone or through one of the Microsoft licensing suites.
  See [Azure Information Protection
  pricing](https://azure.microsoft.com/services/information-protection/) for
  detail.

- Azure Information Protection sensitivity labels need to be migrated to
  the Microsoft Information Protection Unified Labeling platform to be
  used in Power BI.

- To apply labels to Power BI content and files, a user must
  have a Power BI Pro or Premium Per User (PPU) license in addition to
  one of the previously mentioned Azure Information Protection licenses.

- Before enabling sensitivity labels on the agency’s tenant, ensure sensitivity labels have been defined and published for relevant
  users and groups. See [Create and configure sensitivity labels and
  their
  policies](https://learn.microsoft.com/en-us/purview/create-sensitivity-labels)
  for detail.


### Implementation 
#### MS.POWERBI.7.1v1 instructions:
1. Navigate to the **PowerBI Admin Portal**

2. Click on **Tenant settings**

3. Scroll to **Information protection**

4. Click on **Allow users to apply sensitivity labels for content** set to **Enabled**
   Define who can apply and change sensitivity labels in Power BI assets.

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

# Appendix A: Implementation Considerations

## Information Protection Considerations

Several best practices and approaches are available to protect sensitive
data in Power BI.

- Leverage sensitivity labels via Microsoft Information Protection.

- Power BI allows service users to bring their own key to protect data
  at rest.

- Customers have the option to keep data sources on-premises and
  leverage Direct Query or Live Connect with an on-premises data gateway
  to minimize data exposure to the cloud service.

- Implement Row Level Security in Power BI datasets.

**Implementation Steps:**

**Apply sensitivity labels from data sources to their data in Power BI**

When this setting is enabled, Power BI datasets that connect to
sensitivity-labeled data in supported data sources can inherit those
labels, so the data remains classified and secure when brought into
Power BI. For details about sensitivity label inheritance from data
sources, see Sensitivity label inheritance from data sources (preview).

***To enable sensitivity label inheritance from data sources:***

1.  Navigate to the Power BI tenant settings.

2. Select **Information protection** -\> **Apply sensitivity labels
    from data sources to their data in Power BI (preview).**

3. Enable **Restrict content with protected labels from being shared
    via link with everyone in your agency**.

When this setting is enabled, users can't generate a sharing link for
people in the agency for content with protection settings in the
sensitivity label.

Sensitivity labels with protection settings include encryption or
content markings. For example, the agency may have a "Highly
Confidential" label that includes encryption and applies a "Highly
Confidential" watermark to content with this label. Therefore, when this
tenant setting is enabled and a report has a sensitivity label with
protection settings, then users can't create sharing links for people in
the agency.

**Information Protection Prerequisites Specific to Power BI**

- An Azure Information Protection Premium P1 or Premium P2 license is
  required to apply or view Microsoft Information Protection sensitivity
  labels in Power BI. Azure Information Protection can be purchased
  either standalone or through one of the Microsoft licensing suites.
  See [Azure Information Protection
  pricing](https://azure.microsoft.com/services/information-protection/) for
  detail.

- Azure Information Protection sensitivity labels need to be migrated to
  the Microsoft Information Protection Unified Labeling platform in
  order for them to be used in Power BI.

- To be able to apply labels to Power BI content and files, a user must
  have a Power BI Pro or Premium Per User (PPU) license in addition to
  one of the previously mentioned Azure Information Protection licenses.

- Before enabling sensitivity labels on the agency’s tenant, make sure
  that sensitivity labels have been defined and published for relevant
  users and groups. See [Create and configure sensitivity labels and
  their
  policies](https://learn.microsoft.com/en-us/purview/create-sensitivity-labels)
  for detail.

**High-Level Steps to Use Bring Your Own Key (BYOK) Feature in Power
BI**

First, confirm having the latest Power BI Management cmdlet. Install the
latest version by running Install-Module -Name MicrosoftPowerBIMgmt.
More information about the Power BI cmdlet and its parameters is
available in [Power BI PowerShell cmdlet
module](https://learn.microsoft.com/en-us/powershell/power-bi/overview?view=powerbi-ps).

Follow steps in [Bring Your Own (encryption) Keys for Power BI](https://learn.microsoft.com/en-us/power-bi/enterprise/service-encryption-byok).

**Row Level Security Implementation**

Row Level Security (RLS) involves several configuration steps, which
should be completed in the following order.

1.  Create a report in Microsoft Power BI Desktop.

2.  Import the data.

3.  Confirm the data model between both tables.

4.  Create the report visuals.

5. Create RLS roles in Power BI Desktop by using DAX.

6. Test the roles in Power BI Desktop.

7. Deploy the report to Microsoft Power BI service.

8. Add members to the role in Power BI service.

9. Test the roles in Power BI service.

- Reference Microsoft Power BI documentation for additional detail on
  [Row Level Security
  configuration](https://learn.microsoft.com/en-us/power-bi/enterprise/service-admin-rls).

**Related Resources**

- [Sensitivity labels in Power BI \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/enterprise/service-security-sensitivity-label-overview)

- [Bring your own encryption keys for Power BI \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/enterprise/service-encryption-byok)

- [What is an on-premises data gateway? \| Microsoft
  Learn](https://learn.microsoft.com/en-us/data-integration/gateway/service-gateway-onprem)

- [Row-level security (RLS) with Power BI \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/enterprise/service-admin-rls)

- [Power BI PowerShell cmdlets and modules references \| Microsoft
 Learn](https://learn.microsoft.com/en-us/powershell/power-bi/overview?view=powerbi-ps)

## Source Code and Credential Security Considerations

Exposure of secrets via collaboration spaces is a security concern when
using Power BI.

For Power BI embedded applications, it is recommended to implement a
source code scanning solution to identify credentials within the code of
any app housing embedded Power BI report(s). A source code scanner can
also encourage moving discovered credentials to more secure locations,
such as Azure Key Vault.

Store encryption keys or service principal credentials used for
encrypting or accessing Power BI in a Key Vault, assign proper access
policies to the vault and regularly review access permissions.

For regulatory or other compliance reasons, some agencies may need to
bring their own keys (BYOK), which is supported by Power BI. By default,
Power BI uses Microsoft-managed keys to encrypt the data. In Power BI
Premium, users can use their own keys for data at-rest that is imported
into a dataset (see [Data source and storage
considerations](https://learn.microsoft.com/en-us/power-bi/enterprise/service-encryption-byok#data-source-and-storage-considerations)
for more information).

- For Power BI embedded applications, a best practice is to implement a
  source code scanning solution to identify credentials within the code
  of the app housing the embedded Power BI report(s).

- If required under specific regulations, agencies need a strategy for
  maintaining control and governance of their keys. The bring your own
  key (BYOK) functionality is one option.

**Prerequisites**

- Implementers must do their own due diligence in selecting a source
  code scanner that integrates with their specific environment.
  Microsoft documentation [provides a
  link](https://owasp.org/www-community/Source_Code_Analysis_Tools) to
  third-party scanners at the Open Web Application Security Project
  (OWASP). This baseline does not endorse or advise on the selection or
  use of any specific third-party tool.

- If BYOK is deemed to be a requirement:

- Power BI Premium is required for BYOK.

- To use BYOK, the Power BI tenant admin must upload data to the Power
  BI service from a Power BI Desktop (PBIX) file.

- RSA keys must be 4096-bit.

- Enable BYOK in the tenant.

**BYOK Implementation High-Level Steps**

Enable BYOK at the tenant level via PowerShell by first introducing the
encryption keys created and stored in Azure Key Vault to the Power BI
tenant.

Then assign these encryption keys per Premium capacity for encrypting
content in the capacity.

To enable bringing the agency’s key for Power BI, the high-level
configuration steps are as follows:

1.  Add the Power BI service as a service principal for the key vault,
    with wrap and unwrap permissions.

2. Create an RSA key with a 4096-bit length (or use an existing key of
    this type), with wrap and unwrap permissions.

3. To turn on BYOK, Power BI Tenant administrators must use a set of
    Power BI [Admin PowerShell
    Cmdlets](https://learn.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.admin/?view=powerbi-ps)
    added to the Power BI Admin Cmdlets.

    Follow [detailed
    steps](https://learn.microsoft.com/en-us/power-bi/enterprise/service-encryption-byok)
    from Microsoft.

**Related Resources:**

- [Bring your own encryption keys for Power BI \| Microsoft
 Learn](https://learn.microsoft.com/en-us/power-bi/enterprise/service-encryption-byok)

- [Microsoft Source Code Analysis Developer Frequently Asked
  Questions](https://learn.microsoft.com/en-us/previous-versions/azure/security/develop/security-code-analysis-faq)

- For GitHub, the agency can use the native secret scanning feature to
  identify credentials or other form of secrets within code at [About
  secret scanning \| GitHub
  docs](https://docs.github.com/en/code-security/secret-scanning/about-secret-scanning)

- [Announcing General Availability of Bring Your Own Key (BYOK) for
  Power BI
  Premium](https://powerbi.microsoft.com/en-us/blog/announcing-general-availability-of-bring-your-own-key-byok-for-power-bi-premium/)

## File Export and Visual Artifact Considerations

Exporting data from Power BI to image files and comma-separated value
(.csv) file format has data security implications. For example, if
row-level security (RLS) features are in use in Power BI, an export to
image or .csv could allow a user to inadvertently decouple that setting
and expose data to a party who does not have permissions or a need to
know that previously secured data. A similar scenario applies for
information protection sensitivity labels.

A message regarding this condition is provided in the Power BI tenant
settings for the particular types of exports.

In contrast to this, Power BI applies these protection settings (RLS,
sensitivity labels) when the report data leaves Power BI via a supported
export method, such as export to Excel, PowerPoint, or PDF, download to
.pbix, and Save (Desktop). In this case, only authorized users will be
able to open protected files.

**Copy and Paste Visuals:**

Power BI can allow users to copy and paste visuals from Power BI reports
as static images into external applications. This could represent a data
security risk in some contexts. The agency must evaluate whether this
represents risk for its data artifacts and whether to turn this off in
the Export and Sharing Settings.

**Related Resources:**

- [Sensitivity labels in Power BI \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/enterprise/service-security-sensitivity-label-overview)

- [Say No to Export Data, Yes to Analyze in
  Excel](https://radacad.com/say-no-to-export-data-yes-to-analyze-in-excel-power-bi-and-excel-can-talk)

- [Power BI Governance – Why you should consider disabling Export to
  Excel](https://data-marc.com/2020/04/13/power-bi-governance-why-you-should-consider-to-disable-export-to-excel/)

**Implementation settings:**

1.  In the **Power BI tenant** settings, under **Export and sharing
    settings**, administrators can opt to toggle off both **Export reports as
    image files** and **Export to .csv**.

2. In the **Power BI tenant** settings, under **Export and sharing
    settings**, administrators can opt to toggle off **Copy and paste visuals**.

**Establishing Private Network Access Connections Using Azure Private Link:**

When connecting to Azure services intended to supply Power BI datasets,
agencies should consider connecting their Power BI tenant to an Azure
Private Link endpoint and disable public internet access.

In this configuration, Azure Private Link and Azure Networking private
endpoints are used to send data traffic privately using Microsoft's
backbone network infrastructure. The data travels the Microsoft private
network backbone instead of going across the Internet.

Using private endpoints with Power BI ensures that traffic will flow
over the Azure backbone to a private endpoint for Azure cloud-based
resources.

Within this configuration, there is also the capability to disable
public access to Power BI datasets.

**High-Level Implementation Steps**

Note: It is imperative that the VNET and VM are configured before
disabling public internet access.

1.  Enable private endpoints for Power BI.

2. Create a Power BI resource in the Azure portal.

3. Create a virtual network.

4. Create a virtual machine (VM).

5. Create a private endpoint.

6. Connect to a VM using Remote Desktop (RDP).

7. Access Power BI privately from the virtual machine.

8. Disable public access for Power BI.

**Related Resources:**

- [Private endpoints for accessing Power BI \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/enterprise/service-security-private-links)

- [Microsoft Power BI Security Baseline, Baseline Statement NS-3 \|
  Microsoft
  Learn](https://learn.microsoft.com/en-us/security/benchmark/azure/baselines/power-bi-security-baseline)

## Best Practices for Service Principals:

- Evaluate whether certificates or secrets are a more secure option for
  the implementation. Note that Microsoft recommends certificates over
  secrets.

- Use the principle of least privilege in implementing service
  principals; only provide the ability to create app registrations to
  entities that require it.

- Instead of enabling service principals for the entire agency,
  implement for a dedicated security group.

**Note**: This policy is only applicable if the setting **Allow service principals to use Power BI APIs** is enabled
