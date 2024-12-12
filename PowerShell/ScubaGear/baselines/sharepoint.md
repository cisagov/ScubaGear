**`TLP:CLEAR`**
# CISA M365 Secure Configuration Baseline for SharePoint Online and OneDrive

Microsoft 365 (M365) SharePoint Online is a web-based collaboration and document management platform. It is primarily used to collaborate on documents and communicate information in projects. M365 OneDrive is a cloud-based file storage system primarily used to store a user's personal files, but it can also be used to share documents with others. This secure configuration baseline (SCB) provides specific policies to strengthen the security of both services.

The Secure Cloud Business Applications (SCuBA) project, run by the Cybersecurity and Infrastructure Security Agency (CISA), provides guidance and capabilities to secure federal civilian executive branch (FCEB) agencies’ cloud business application environments and protect federal information that is created, accessed, shared, and stored in those environments.

The CISA SCuBA SCBs for M365 help secure federal information assets stored within M365 cloud business application environments through consistent, effective, and manageable security configurations. CISA created baselines tailored to the federal government’s threats and risk tolerance with the knowledge that every organization has different threat models and risk tolerance. While use of these baselines will be mandatory for civilian Federal Government agencies, organizations outside of the Federal Government may also find these baselines to be useful references to help reduce risks.

For non-Federal users, the information in this document is being provided “as is” for INFORMATIONAL PURPOSES ONLY. CISA does not endorse any commercial product or service, including any subjects of analysis. Any reference to specific commercial entities or commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply endorsement, recommendation, or favoritism by CISA. Without limiting the generality of the foregoing, some controls and settings are not available in all products; CISA has no control over vendor changes to products offerings or features.  Accordingly, these SCuBA SCBs for M365 may not be applicable to the products available to you. This document does not address, ensure compliance with, or supersede any law, regulation, or other authority. Entities are responsible for complying with any recordkeeping, privacy, and other laws that may apply to the use of technology. This document is not intended to, and does not, create any right or benefit for anyone against the United States, its departments, agencies, or entities, its officers, employees, or agents, or any other person.

> This document is marked TLP:CLEAR. Recipients may share this information without restriction. Information is subject to standard copyright rules. For more information on the Traffic Light Protocol, see https://www.cisa.gov/tlp.

## License Compliance and Copyright

Portions of this document are adapted from documents in Microsoft’s [M365](https://github.com/MicrosoftDocs/microsoft-365-docs/blob/public/LICENSE) and [Azure](https://github.com/MicrosoftDocs/azure-docs/blob/main/LICENSE) GitHub repositories. The respective documents are subject to copyright and are adapted under the terms of the Creative Commons Attribution 4.0 International license. Source are linked throughout this document. The United States government has adapted selections of these documents to develop innovative and scalable configuration standards to strengthen the security of widely used cloud-based software services.

## Assumptions
The **License Requirements** sections of this document assume the organization is using an [M365 E3](https://www.microsoft.com/en-us/microsoft-365/compare-microsoft-365-enterprise-plans) or [G3](https://www.microsoft.com/en-us/microsoft-365/government) license level at a minimum. Therefore, only licenses not included in E3/G3 are listed.

## Key Terminology
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

# Baseline Policies

## 1. External Sharing

This section helps reduce security risks related to sharing files with users external to the agency. This includes guest users, users who use a verification code, and users who access an Anyone link.


### Policies
#### MS.SHAREPOINT.1.1v1
External sharing for SharePoint SHALL be limited to Existing guests or Only people in your organization.

<!--Policy: MS.SHAREPOINT.1.1v1; Criticality: SHALL -->
- _Rationale:_ Sharing information outside the organization via SharePoint increases the risk of unauthorized access. By limiting external sharing, administrators decrease the risk of access to information.
- _Last modified:_ June 2023
- _MITRE ATT&CK TTP Mapping:_
  - [T1048: Exfiltration Over Alternative Protocol](https://attack.mitre.org/techniques/T1048/)
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
    - [T1213.002: Sharepoint](https://attack.mitre.org/techniques/T1213/002/)

#### MS.SHAREPOINT.1.2v1
External sharing for OneDrive SHALL be limited to Existing guests or Only people in your organization.

<!--Policy: MS.SHAREPOINT.1.2v1; Criticality: SHALL -->
- _Rationale:_ Sharing files outside the organization via OneDrive increases the risk of unauthorized access. By limiting external sharing, administrators decrease the risk of unauthorized unauthorized access to information.
- _Last modified:_ June 2023
- _MITRE ATT&CK TTP Mapping:_
  - [T1048: Exfiltration Over Alternative Protocol](https://attack.mitre.org/techniques/T1048/)
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
    - [T1213.002: Sharepoint](https://attack.mitre.org/techniques/T1213/002/)
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)

#### MS.SHAREPOINT.1.3v1
External sharing SHALL be restricted to approved external domains and/or users in approved security groups per interagency collaboration needs.

<!--Policy: MS.SHAREPOINT.1.3v1; Criticality: SHALL -->
- _Rationale:_ By limiting sharing to domains or approved security groups used for interagency collaboration purposes, administrators help prevent sharing with unknown organizations and individuals.
- _Last modified:_ June 2023
- _Note:_ This policy is only applicable if the external sharing slider on the admin page is set to any value other than **Only people in your organization**.
- _MITRE ATT&CK TTP Mapping:_
  - [T1048: Exfiltration Over Alternative Protocol](https://attack.mitre.org/techniques/T1048/)
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
    - [T1213.002: Sharepoint](https://attack.mitre.org/techniques/T1213/002/)
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)

#### MS.SHAREPOINT.1.4v1
Guest access SHALL be limited to the email the invitation was sent to.

<!--Policy: MS.SHAREPOINT.1.4v1; Criticality: SHALL -->
- _Rationale:_ Email invitations allow external guests to access shared information. By requiring guests to sign in using the same account where the invite was sent, administrators help ensure only the intended guest can use the invite.
- _Last modified:_ June 2023
- _Note:_ This policy is only applicable if the external sharing slider on the admin page is set to any value other than **Only People in your organization**.
- _MITRE ATT&CK TTP Mapping:_
  - [T1048: Exfiltration Over Alternative Protocol](https://attack.mitre.org/techniques/T1048/)
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
    - [T1213.002: Sharepoint](https://attack.mitre.org/techniques/T1213/002/)
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)

### Resources

- [Overview of external sharing in SharePoint and OneDrive in Microsoft 365 \| Microsoft Documents](https://learn.microsoft.com/en-us/sharepoint/external-sharing-overview)

- [Manage sharing settings for SharePoint and OneDrive in Microsoft 365 \| Microsoft Documents](https://learn.microsoft.com/en-us/sharepoint/turn-external-sharing-on-or-off)

### License Requirements

- N/A

### Implementation

#### MS.SHAREPOINT.1.1v1 Instructions

1. Sign in to the **SharePoint admin center**.

2.  Select **Policies** \> **Sharing**.

3.  Adjust external sharing slider for SharePoint to **Existing guests** or **Only people in your organization**.

4. Select **Save**.

#### MS.SHAREPOINT.1.2v1 Instructions


1.  Sign in to the **SharePoint admin center**.

2.  Select **Policies** \> **Sharing**.

3.  Adjust external sharing slider for OneDrive to **Existing Guests** or **Only people in your organization**.

4. Select **Save**.

#### MS.SHAREPOINT.1.3v1 Instructions

Note: If SharePoint external sharing is set to its most restrictive setting of "Only people in your organization", then no external sharing is allowed and no implementation changes are required for this policy item.

1.  Sign in to the **SharePoint admin center**.

2.  Select **Policies** \> **Sharing**.

3.  Expand **More external sharing settings**.

4.  Select **Limit external sharing by domain**.

5.  Select **Add domains**.

6.  Add each approved external domain users are allowed to share files with.

7.  Select **Manage security groups**

8. Add each approved security group. Members of these groups will be allowed to share files externally.

9.  Select **Save**.

#### MS.SHAREPOINT.1.4v1 Instructions

Note: If SharePoint external sharing is set to its most restrictive setting of "Only people in your organization", then no external sharing is allowed and no implementation changes are required for this policy item.

1.  Sign in to the **SharePoint admin center**.

2.  Select **Policies** \> **Sharing**.

3.  Expand **More external sharing settings**.

4. Select **Guests must sign in using the same account to which sharing invitations are sent**.

5. Select **Save**.

## 2. File and Folder Default Sharing Settings

This section provides policies to set the scope and permissions for sharing links to secure default values.

### Policies

#### MS.SHAREPOINT.2.1v1
File and folder default sharing scope SHALL be set to Specific people (only the people the user specifies).

<!--Policy: MS.SHAREPOINT.2.1v1; Criticality: SHALL -->
- _Rationale:_ By making the default sharing the most restrictive, administrators prevent accidentally sharing information too broadly.
- _Last modified:_ June 2023
- _MITRE ATT&CK TTP Mapping:_
  - [T1048: Exfiltration Over Alternative Protocol](https://attack.mitre.org/techniques/T1048/)
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
    - [T1213.002: Sharepoint](https://attack.mitre.org/techniques/T1213/002/)
  - [T1565: Data Manipulation](https://attack.mitre.org/techniques/T1565/)
    - [T1565.001: Stored Data Manipulation](https://attack.mitre.org/techniques/T1565/001/)

#### MS.SHAREPOINT.2.2v1
File and folder default sharing permissions SHALL be set to View.

<!--Policy: MS.SHAREPOINT.2.2v1; Criticality: SHALL -->
- _Rationale:_ Edit access to files and folders could allow a user to make unauthorized changes.  By restricting default permissions to **View**, administrators prevent unintended or malicious modification.
- _Last modified:_ June 2023
- _MITRE ATT&CK TTP Mapping:_
  - [T1080: Taint Shared Content](https://attack.mitre.org/techniques/T1080/)
  - [T1565: Data Manipulation](https://attack.mitre.org/techniques/T1565/)
    - [T1565.001: Stored Data Manipulation](https://attack.mitre.org/techniques/T1565/001/)

### Resources

- [File and folder links \| Microsoft
  Documents](https://learn.microsoft.com/en-us/sharepoint/turn-external-sharing-on-or-off#file-and-folder-links)

### License Requirements

- N/A

### Implementation

#### MS.SHAREPOINT.2.1v1 Instructions

1.  Sign in to the **SharePoint admin center**.

2.  Select **Policies** \> **Sharing**

3.  Under **File and folder links**, set the default link type to **Specific people (only the people the user specifies)**

4.  Select **Save**

#### MS.SHAREPOINT.2.2v1 Instructions

1.  Sign in to the **SharePoint admin center**.

2. Select **Policies** \> **Sharing**.

3. Under **File and folder links**, set the permission that is selected by default for sharing links to **View**.

4. Select **Save**.

## 3. Securing Anyone Links and Verification Code Users

Sharing files with external users via the usage of **Anyone links** or **Verification codes** is strongly discouraged because it provides access to data within a tenant with weak or no authentication. If these features are used, this section details some access restrictions that could provide limited security risk mitigations.

**Note**: The settings in this section are only applicable if an agency is using **Anyone links** or **Verification code** sharing. See each policy below for details.

### Policies
#### MS.SHAREPOINT.3.1v1
Expiration days for Anyone links SHALL be set to 30 days or less.

<!--Policy: MS.SHAREPOINT.3.1v1; Criticality: SHALL -->
- _Rationale:_ Links may be used to provide access to information for a short period of time. Without expiration, however, access is indefinite. By setting expiration timers for links, administrators prevent unintended sustained access to information.
- _Last modified:_ June 2023
- _Note:_ This policy is only applicable if the external sharing slider on the admin center sharing page is set to **Anyone**.
- _MITRE ATT&CK TTP Mapping:_
  - [T1048: Exfiltration Over Alternative Protocol](https://attack.mitre.org/techniques/T1048/)
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
    - [T1213.002: Sharepoint](https://attack.mitre.org/techniques/T1213/002/)
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)

#### MS.SHAREPOINT.3.2v1
The allowable file and folder permissions for links SHALL be set to View only.

<!--Policy: MS.SHAREPOINT.3.2v1; Criticality: SHALL -->
- _Rationale:_ Unauthorized changes to files can be made if permissions allow editing by anyone.  By restricting permissions on links to **View** only, administrators prevent anonymous file changes.
- _Last modified:_ June 2023
- _Note:_ This policy is only applicable if the external sharing slider on the admin center sharing page is set to **Anyone**.
- _MITRE ATT&CK TTP Mapping:_
  - [T1080: Taint Shared Content](https://attack.mitre.org/techniques/T1080/)
  - [T1565: Data Manipulation](https://attack.mitre.org/techniques/T1565/)
    - [T1565.001: Stored Data Manipulation](https://attack.mitre.org/techniques/T1565/001/)

#### MS.SHAREPOINT.3.3v1
Reauthentication days for people who use a verification code SHALL be set to 30 days or less.

<!--Policy: MS.SHAREPOINT.3.3v1; Criticality: SHALL -->
- _Rationale:_ A verification code may be given out to provide access to information for a short period of time. By setting expiration timers for verification code access, administrators prevent  unintended sustained access to information.
- _Last modified:_ June 2023
- _Note:_ This policy is only applicable if the external sharing slider on the admin center sharing page is set to **Anyone** or **New and existing guests**.
- _MITRE ATT&CK TTP Mapping:_
  - [T1080: Taint Shared Content](https://attack.mitre.org/techniques/T1080/)
  - [T1565: Data Manipulation](https://attack.mitre.org/techniques/T1565/)
    - [T1565.001: Stored Data Manipulation](https://attack.mitre.org/techniques/T1565/001/)

### License Requirements

- N/A

### Resources

- [Secure external sharing recipient experience \| Microsoft
  Documents](https://learn.microsoft.com/en-us/sharepoint/what-s-new-in-sharing-in-targeted-release)

### Implementation

#### MS.SHAREPOINT.3.1v1 Instructions

1.  Sign in to the **SharePoint admin center**.

2.  Select **Policies** \> **Sharing**.

3.  Scroll to the section **Choose expiration and permissions options for Anyone links**.

4.  Select the checkbox **These links must expire within this many days**.

5.  Enter **30** days or less.

6.  Select **Save**.

#### MS.SHAREPOINT.3.2v1 Instructions

1.  Sign in to the **SharePoint admin center**.

2.  Select **Policies** \> **Sharing**.

3.  Scroll to the section **Choose expiration and permissions options for Anyone links**.

4.  Set the configuration items in the section **These links can give these permissions**.

5.  Set the **Files** option to **View**.

6.  Set the **Folders** option to **View**.

7.  Select **Save**.

#### MS.SHAREPOINT.3.3v1 Instructions

1.  Sign in to the **SharePoint admin center**.

2.  Select **Policies** \> **Sharing**.

3.  Expand **More external sharing settings**.

4. Select **People who use a verification code must reauthenticate after this many days**.

5.  Enter **30** days or less.

6. Select **Save**.

**`TLP:CLEAR`**
