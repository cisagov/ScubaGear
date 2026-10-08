**`TLP:CLEAR`**

# CISA M365 Secure Configuration Baseline for Power BI

Microsoft 365 (M365) Power BI is a cloud-based product that facilitates self-service business intelligence dashboards, reports, datasets, and visualizations. Power BI can connect to multiple different data sources, combine and shape data from those connections, then create reports and dashboards to share with others. This secure configuration baseline (SCB) provides specific policies to strengthen Power BI security.

The Cybersecurity and Infrastructure Security Agency’s (CISA) Secure Cloud Business Applications (SCuBA) project provides guidance and capabilities to secure federal civilian executive branch (FCEB) agencies’ cloud business application environments and protect federal information that is created, accessed, shared, and stored in those environments.

The CISA SCuBA SCBs for M365 help secure federal information assets stored within M365 cloud business application environments through consistent, effective, and manageable security configurations. CISA created baselines tailored to the federal government’s threats and risk tolerance with the knowledge that every organization has different threat models and risk tolerance. While use of these baselines will be mandatory for civilian federal government agencies, organizations outside of the federal government may also find these baselines to be useful references to help reduce risks.

For non-federal users, the information in this document is being provided “as is” for INFORMATIONAL PURPOSES ONLY. CISA does not endorse any commercial product or service, including any subjects of analysis. Any reference to specific commercial entities or commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply endorsement, recommendation, or favoritism by CISA. Without limiting the generality of the foregoing, some controls and settings are not available in all products. CISA has no control over vendor changes to products offerings or features. Accordingly, these SCuBA SCBs for M365 may not be applicable to the products available to you. This document does not address, ensure compliance with, or supersede any law, regulation, or other authority. Entities are responsible for complying with any recordkeeping, privacy, and other laws that may apply to the use of technology. This document is not intended to, and does not, create any right or benefit for anyone against the United States, its departments, agencies, or entities, its officers, employees, or agents, or any other person.

> This document is marked TLP:CLEAR. Recipients may share this information without restriction. Information is subject to standard copyright rules. For more information on the Traffic Light Protocol, see https://www.cisa.gov/tlp.


## License Compliance and Copyright
Portions of this document are adapted from documents in Microsoft's [M365](https://github.com/MicrosoftDocs/microsoft-365-docs/blob/public/LICENSE) and [Azure](https://github.com/MicrosoftDocs/azure-docs/blob/main/LICENSE) GitHub repositories. The respective documents are subject to copyright and are adapted under the terms of the Creative Commons Attribution 4.0 International license. Sources are linked throughout this document. The United States government has adapted selections of these documents to develop innovative and scalable configuration standards to strengthen the security of widely used cloud-based software services.

## Assumptions
The **License Requirements** sections of this document assume the organization is using an [M365 E3](https://www.microsoft.com/en-us/microsoft-365/compare-microsoft-365-enterprise-plans) or [G3](https://www.microsoft.com/en-us/microsoft-365/government) license level at a minimum. Therefore, only licenses not included in E3/G3 are listed.


Agencies using Power BI may have a data classification scheme in place for
  the data entering Power BI.

- Agencies may connect more than one data source to their Power BI
  tenant.
- All data sources use a secure connection for data transfer to and from
  the Power BI tenant. The agency disallows non-secure connections.

## Key Terminology
The key words "MUST," "MUST NOT," "REQUIRED," "SHALL," "SHALL NOT," "SHOULD," "SHOULD NOT," "RECOMMENDED," "MAY," and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

Access to Power BI can be controlled by user type. In this baseline,
the types of users are defined as follows:

1.  **Internal users**: Members of the agency's M365 tenant
2.  **External users**: Members of a different M365 tenant
3.  **Business to Business (B2B) guest users**: External users that are
  formally invited to view and/or edit Power BI workspace content and
  are added to the agency's Microsoft Entra ID as guest users. These users authenticate with their home organization/tenant and are granted access to Power BI
  content by virtue of being listed as guest users in the tenant's Microsoft Entra ID.

> Note:
> These terms vary in use across Microsoft documentation.

**BOD 25-01 Requirement**: This indicator means that the policy is required under [CISA BOD 25-01](https://www.cisa.gov/news-events/directives/bod-25-01-implementing-secure-practices-cloud-services).

**Automated Check**: This indicator means that the policy can be automatically checked via ScubaGear. See the [Quick Start Guide](../../../README.md#quick-start-guide) for help getting started.

**Configurable**: This indicator means that the policy can be customized via a configuration file.

**Requires Configuration**: This indicator means that ScubaGear requires configuration via configuration file in order to check the policy.

**Manual**: This indicator means that the policy requires manual verification of configuration settings.

# Baseline Policies

## 1. Publish to Web

Power BI has the capability to publish reports and content to the web.
This capability creates a publicly accessible web URL that does not
require authentication or Microsoft Entra ID user status to view. While this
may be needed for a specific use case or collaboration scenario, it is
best practice to keep this setting off by default to prevent unintended
and potentially sensitive data exposure.

If it is deemed necessary to make an exception and enable the feature,
administrators should limit the ability to publish to the web to "only
specific security groups," instead of allowing the entire agency to
publish data to the web.

### Policies
#### MS.POWERBI.1.1v1
The "Publish to Web" feature SHOULD be disabled unless the agency mission requires the capability.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.POWERBI.1.1v1; Criticality: SHOULD -->
- _Rationale:_ A publicly accessible web URL can be accessed by everyone, including malicious actors. This policy limits information available on the public web that is not specifically allowed to be published.
- _Last modified:_ June 2023
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ CM-7, SC-7(10)(a)
- _MITRE ATT&CK TTP Mapping:_
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)

### Resources

- [About Power BI Tenant settings \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/admin/service-admin-portal-about-tenant-settings)

- [Power BI Security Baseline v2.0 \| Microsoft benchmarks GitHub
  repo](https://github.com/MicrosoftDocs/SecurityBenchmarks/blob/master/Azure%20Offer%20Security%20Baselines/2.0/power-bi-security-baseline-v2.0.xlsx)

### License Requirements

- N/A


### Implementation
#### MS.POWERBI.1.1v1 Instructions

1. Navigate to the **Power BI admin portal**.

2. Click on **Tenant settings**.

3. Scroll to **Export and sharing settings**.

4. Click **Publish to web** and set it to **Disabled**.

## 2. Power BI Guest Access

This section provides policies to help reduce guest user access risks related to Power BI data and resources. An agency with externally shareable Power BI resources and data must consider its unique risk tolerance when granting access to guest users.

### Policies
#### MS.POWERBI.2.1v1
Guest user access to the Power BI tenant SHOULD be disabled unless the agency mission requires the capability.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.POWERBI.2.1v1; Criticality: SHOULD -->
- _Rationale:_ Disabling external access to Power BI helps keep guest users from accessing potentially risky data and application programming interfaces (APIs). If an agency needs to allow guest access, this can be limited to users in specific security groups to curb risk.
- _Last modified:_ April 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ CM-7, AC-6
- _MITRE ATT&CK TTP Mapping:_
  - [T1485: Data Destruction](https://attack.mitre.org/techniques/T1485/)
  - [T1565: Data Manipulation](https://attack.mitre.org/techniques/T1565/)
    - [T1565.001: Stored Data Manipulation](https://attack.mitre.org/techniques/T1565/001/)
  - [T1078: Valid Accounts](https://attack.mitre.org/techniques/T1078/)
    - [T1078.001: Default Accounts](https://attack.mitre.org/techniques/T1078/001/)

### Resources

- [About Power BI Tenant settings \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/admin/service-admin-portal-about-tenant-settings)

- [Power BI Security Baseline v2.0 \| Microsoft benchmarks GitHub
  repo](https://github.com/MicrosoftDocs/SecurityBenchmarks/blob/master/Azure%20Offer%20Security%20Baselines/2.0/power-bi-security-baseline-v2.0.xlsx)

### License Requirements

- N/A

### Implementation
#### MS.POWERBI.2.1v1 Instructions
To disable completely:
1. Navigate to the **Power BI admin portal**.

2. Click on **Tenant settings**.

3. Scroll to **Export and sharing settings**.

4. For **commercial** tenants, click on **Guest users can access Microsoft Fabric** and set it to **Disabled**.

5. For **GCC, GCC High and DoD** tenants, click on **Allow Azure Active Directory guest users to access Power BI** and set it to **Disabled**.

To enable with security group(s):
1. Navigate to the **Power BI admin portal**.

2. Click on **Tenant settings**.

3. Scroll to **Export and sharing settings**.

4. For **commercial** tenants, click on **Guest users can access Microsoft Fabric** and set it to **Enabled**.

5. For **GCC, GCC High and DoD** tenants, click on **Allow Azure Active Directory guest users to access Power BI** and set it to **Enabled**.

6. Select the security group(s) you want to have access to the Power BI tenant.
> Note:
> You may need to make a specific security group(s).

## 3. Power BI External Invitations

This section provides policies that help reduce guest user invitation risks related to Power BI data and resources.
The settings in this section control whether Power BI allows inviting external users to
the agency's organization through Power BI's sharing workflows and
experiences. After an external user accepts the invite, they become a
Microsoft Entra ID B2B guest user in the organization. They will then appear in user
pickers throughout the Power BI user experience.

### Policies
#### MS.POWERBI.3.1v1
The "Invite external users to your organization" feature SHOULD be disabled unless agency mission requires the capability.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.POWERBI.3.1v1; Criticality: SHOULD -->
- _Rationale:_ Disabling this feature prevents internal users from inviting guest users, helping limit guest user access to potentially risky data/APIs. If an agency needs to allow guest access, the agency can limit the invitation feature to users in specific security groups to help limit risk.
- _Last modified:_ April 2026
> Note:
> If this feature is disabled, existing guest users in the tenant will continue to have access to Power BI items they already had access to and will continue to be listed in user picker experiences. After the feature is disabled, external users who are not already guest users cannot be added to the tenant through Power BI.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ CM-7, AC-6
- _MITRE ATT&CK TTP Mapping:_
  - [T1485: Data Destruction](https://attack.mitre.org/techniques/T1485/)
  - [T1565: Data Manipulation](https://attack.mitre.org/techniques/T1565/)
    - [T1565.001: Stored Data Manipulation](https://attack.mitre.org/techniques/T1565/001/)
  - [T1078: Valid Accounts](https://attack.mitre.org/techniques/T1078/)
    - [T1078.001: Default Accounts](https://attack.mitre.org/techniques/T1078/001/)
  - [T1199: Trusted Relationship](https://attack.mitre.org/techniques/T1199/)

### Resources

- [About Power BI Tenant settings \| Microsoft
  Docs](https://learn.microsoft.com/en-us/power-bi/admin/service-admin-portal-about-tenant-settings)

- [Distribute Power BI content to external guest users with Microsoft Entra B2B \|
  Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/enterprise/service-admin-azure-ad-b2b)

- [Power BI Security Baseline v2.0 \| Microsoft benchmarks GitHub
  repo](https://github.com/MicrosoftDocs/SecurityBenchmarks/blob/master/Azure%20Offer%20Security%20Baselines/2.0/power-bi-security-baseline-v2.0.xlsx)

### License Requirements

- N/A


### Implementation
#### MS.POWERBI.3.1v1 Instructions
To disable completely:
1. Navigate to the **Power BI admin portal**.

2. Click on **Tenant settings**.

3. Scroll to **Export and sharing settings**.

4. Click on **Users can invite guest users to collaborate through item sharing and permissions** and set it to **Disabled**.

To enable with security groups:
1. Navigate to the **Power BI admin portal**.

2. Click on **Tenant settings**.

3. Scroll to **Export and sharing settings**.

4. Click on **Users can invite guest users to collaborate through item sharing and permissions** and set it to **Enabled**.

5. Select the security group(s) needed.
> Note:
> You may need to make a specific security group(s).

## 4. Power BI Service Principals

Service principals can be used as an authentication method to let a Microsoft Entra ID application access Power BI service content and APIs. Power BI supports using service principals to manage application identities. Service principals use APIs to access tenant-level features, controlled by Power BI service administrators and enabled for the entire agency or for agency security groups. Access to service principals can be controlled by creating dedicated security groups for them and using these groups in any Power BI tenant level-settings. If service principals are employed for Power BI, it is recommended that service principal credentials used for encrypting or accessing Power BI be stored in a key vault with properly assigned access policies and regularly reviewed access permissions.

High-level use cases for service principals:

- Not possible to access a data source using service principals in Power BI (e.g., Azure Table storage)

- A user's service principal for accessing the Power BI service (e.g., app.powerbi.com and app.powerbigov.us)

- Power BI Embedded and other users of the Power BI REST APIs to interact with Power BI content

### Policies
#### MS.POWERBI.4.1v1
Service principals with access to APIs SHOULD be restricted to specific security groups.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.POWERBI.4.1v1; Criticality: SHOULD -->
- _Rationale:_ Unwanted access to APIs is possible if service principals are unrestricted. Allowing service principals through security groups (where necessary) mitigates this risk.
- _Last modified:_ April 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-4, AC-6(5)
- _MITRE ATT&CK TTP Mapping:_
  - [T1059: Command and Scripting Interpreter](https://attack.mitre.org/techniques/T1059/)
    - [T1059.009: Cloud API](https://attack.mitre.org/techniques/T1059/009/)

#### MS.POWERBI.4.2v1
Service principals' ability to create and use profiles SHOULD be restricted to specific security groups.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.POWERBI.4.2v1; Criticality: SHOULD -->
- _Rationale:_ When unrestricted service principals create or use profiles, there is risk of an unauthorized user using a profile with more permissions than should be allowed. Restricting service principals through security groups can mitigate this risk.
- _Last modified:_ June 2023
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-4, AC-6(5)
- _MITRE ATT&CK TTP Mapping:_
  - [T1098: Account Manipulation](https://attack.mitre.org/techniques/T1098/)
    - [T1098.003: Additional Cloud Roles](https://attack.mitre.org/techniques/T1098/003/)

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

- [Azure security baseline for Power BI \|
  Microsoft
  Learn](https://learn.microsoft.com/en-us/security/benchmark/azure/baselines/power-bi-security-baseline)

### License Requirements

- N/A


### Implementation
#### MS.POWERBI.4.1v1 Instructions
Organizations with service principals needing to access Power BI APIs can configure the settings per the instructions below.
If there is not a need to grant service principals access, configure the setting to **Disabled**.

1. Navigate to the **Power BI admin portal**.

2. Click on **Tenant settings**.

3. Scroll to **Developer settings**.

4. Click on **Service principals can call Fabric public APIs**.

5. If there are not service principals needing access to Power BI APIs, configure the setting to **Disabled**. Otherwise, go to step 6.

6. If there are service principals needing access to Power BI APIs, configure the setting to **Enabled**.

7. Select the specific security groups that contain the service principals authorized to call the APIs.


#### MS.POWERBI.4.2v1 Instructions
1. Navigate to the **Power BI admin portal**.

2. Click on **Tenant settings**.

3. Scroll to **Developer settings**.

4. Click on **Allow service principals to create and use profiles**.

5. If there are not service principals needing to create and use profiles, then configure the setting to **Disabled**. Otherwise, go to step 6.

6. If there are service principals needing to create and use profiles, then configure the setting to **Enabled**.

7. Select the specific security groups that contain the service principals authorized to create and use profiles.


## 5. Power BI Resource Key Authentication


This setting pertains to the security and development of Power BI
Embedded content. The Power BI tenant states, "For extra security,
block using ResourceKey-based authentication." This baseline statement
recommends, but does not mandate, setting ResourceKey-based
authentication to the blocked state.

For streaming datasets created using the Power BI service user interface, the dataset owner receives a URL including a resource key. This key authorizes the requestor to push data into the dataset without using a Microsoft Entra ID OAuth bearer token. Keep in mind the implications of having a secret key in the URL when working with this type of dataset and method.

This setting applies to streaming and "push" datasets. If ResourceKey-based authentication is blocked, users with a resource key will not be allowed to send data to stream and "push" datasets using the API. However, if developers have an approved need to leverage this feature, an exception to the policy can be investigated.


### Policies
#### MS.POWERBI.5.1v1
ResourceKey-based authentication SHOULD be blocked unless a specific use case (e.g., streaming and/or "push" datasets) merits its use.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.POWERBI.5.1v1; Criticality: SHOULD -->
- _Rationale:_ If resource keys are allowed, a user could move data without a Microsoft Entra ID OAuth bearer token, potentially storing malicious or junk data. Disabling resource keys reduces the risk that an unauthorized individual will make changes.
- _Last modified:_ June 2023
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ CM-7, IA-5g
- _MITRE ATT&CK TTP Mapping:_
  - [T1134: Access Token Manipulation](https://attack.mitre.org/techniques/T1134/)
    - [T1134.001: Token Impersonation/Theft](https://attack.mitre.org/techniques/T1134/001/)
    - [T1134.003: Make and Impersonate Token](https://attack.mitre.org/techniques/T1134/003/)


### Resources

- [Power BI Tenant settings \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/admin/service-admin-portal-about-tenant-settings)

- [Real-time streaming in Power BI \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/connect-data/service-real-time-streaming)

### License Requirements

- N/A


### Implementation
#### MS.POWERBI.5.1v1 Instructions
1. Navigate to the **Power BI admin portal**.

2. Click on **Tenant settings**.

3. Scroll to **Developer settings**.

4. Click on **Block ResourceKey authentication** and set it to **Enabled**.

## 6. Python and R Visual Sharing

Power BI can interact with Python and R scripts to integrate
visualizations from these languages. Python visuals are created from
Python scripts, which could contain code with security or privacy risks.
When attempting to view or interact with a Python visual for the first
time, a user is presented with a security warning message. Python and R
visuals should only be enabled if the author and source are trusted, or
after a code review of the Python/R script(s) in question is conducted
and the scripts are deemed free of security risks.


### Policies
#### MS.POWERBI.6.1v1
Python and R interactions SHOULD be disabled.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.POWERBI.6.1v1; Criticality: SHOULD -->
- _Rationale:_ External code poses a security and privacy risk as there are limited ways to regulate use of data or integrations. Disabling this feature reduces the risk of a data leak or malicious threat activity.
- _Last modified:_ June 2023
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ CM-7, SI-3
- _MITRE ATT&CK TTP Mapping:_
  - [T1059: Command and Scripting Interpreter](https://attack.mitre.org/techniques/T1059/)
    - [T1059.009: Cloud API](https://attack.mitre.org/techniques/T1059/009/)
  - [T1048: Exfiltration Over Alternative Protocol](https://attack.mitre.org/techniques/T1048/)
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)

### Resources

- [Create Power BI visuals with Python \| Microsoft
  Learn](https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-python-visuals)

### License Requirements

- N/A


### Implementation
#### MS.POWERBI.6.1v1 Instructions
1. Navigate to the **Power BI admin portal**.

2. Click on **Tenant settings**.

3. Scroll to **R and Python visuals settings**.

4. Click on **Interact with and share R and Python visuals** and set it to **Disabled**.

## 7. Power BI Sensitive Data

There are multiple ways to secure sensitive information, such as user
warnings, encryption, or blocking share attempts. Using Microsoft
Information Protection sensitivity labels on Power BI reports,
dashboards, datasets, and dataflows helps guard sensitive content against
unauthorized data access and leakage. This can also guard against
unwanted aggregation and commingling.

> Note:
> Currently, data loss prevention (DLP)
profiles are in preview status for Power BI. Once released for general
availability and government use, DLP profiles will represent another available
tool for securing Power BI datasets. Refer to the [*Security Suite
Minimum Viable Secure Configuration Baseline*](securitysuite.md) for more on
DLP profiles.

### Policies
#### MS.POWERBI.7.1v1
Sensitivity labels SHOULD be enabled for Power BI and employed for sensitive data per enterprise data protection policies.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.POWERBI.7.1v1; Criticality: SHOULD -->
- _Rationale:_ A document without sensitivity labels may be opened unknowingly, potentially exposing data to someone who is not supposed to have access. This policy will help organize and classify data, making it easier to keep data away from unauthorized users.
- _Last modified:_ June 2023
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-21b, SC-7(10)(a)
- _MITRE ATT&CK TTP Mapping:_
  - [T1048: Exfiltration Over Alternative Protocol](https://attack.mitre.org/techniques/T1048/)
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
    - [T1213.002: SharePoint](https://attack.mitre.org/techniques/T1213/002/)
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
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

- A Microsoft Purview Information Protection Premium P1 or Premium P2 license is required to apply or view
  Microsoft Information Protection sensitivity labels in Power BI. Azure Information Protection can be purchased either standalone or through one of the Microsoft licensing suites. See [Microsoft Purview Information Protection
  service description](https://azure.microsoft.com/services/information-protection/) for
  details.

- Microsoft Purview Information Protection sensitivity labels need to be migrated to
  the Microsoft Information Protection Unified Labeling platform to be
  used in Power BI.

- To apply labels to Power BI content and files, a user must
  have a Power BI Pro or Premium Per User (PPU) license, in addition to
  one of the previously mentioned Azure Information Protection licenses.

- Before enabling sensitivity labels on the agency's tenant, ensure sensitivity labels have been defined and published for relevant
  users and groups. See [Create and configure sensitivity labels and
  their
  policies](https://learn.microsoft.com/en-us/purview/create-sensitivity-labels)
  for details.


### Implementation
#### MS.POWERBI.7.1v1 Instructions
1. Navigate to the **Power BI admin portal**.

2. Click on **Tenant settings**.

3. Scroll to **Information protection**.

4. Click on **Allow users to apply sensitivity labels for content** and set it to **Enabled**. Define who can apply and change sensitivity labels in Power BI assets.

**`TLP:CLEAR`**
