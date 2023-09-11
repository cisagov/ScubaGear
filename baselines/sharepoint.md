# CISA M365 Security Configuration Baseline for SharePoint Online and OneDrive

SharePoint Online is a web-based collaboration and document management platform. It is primarily used to collaborate on documents and communicate information in project teams. OneDrive is a cloud-based file storage system primarily used to store a user's personal files but it can also be used to share documents with others. This Secure Configuration Baseline (SCB) provides specific policies to strengthen the security of both of these services.

The Secure Cloud Business Applications (SCuBA) project run by the Cybersecurity and Infrastructure Security Agency (CISA) provides guidance and capabilities to secure federal civilian executive branch (FCEB) agencies’ cloud business application environments and protect federal information that is created, accessed, shared, and stored in those environments. 

The CISA SCuBA SCBs for M365 help secure federal information assets stored within M365 cloud business application environments through consistent, effective, and manageable security configurations. CISA created baselines tailored to the federal government’s threats and risk tolerance with the knowledge that every organization has different threat models and risk tolerance. Non-governmental organizations may also find value in applying these baselines to reduce risks.

The information in this document is being provided “as is” for INFORMATIONAL PURPOSES ONLY. CISA does not endorse any commercial product or service, including any subjects of analysis. Any reference to specific commercial entities or commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply endorsement, recommendation, or favoritism by CISA.

## License Compliance and Copyright

Portions of this document are adapted from documents in Microsoft’s [Microsoft 365](https://github.com/MicrosoftDocs/microsoft-365-docs/blob/public/LICENSE) and [Azure](https://github.com/MicrosoftDocs/azure-docs/blob/main/LICENSE) GitHub repositories. The respective documents are subject to copyright and are adapted under the terms of the Creative Commons Attribution 4.0 International license. Source documents are linked throughout this document. The United States Government has adapted selections of these documents to develop innovative and scalable configuration standards to strengthen the security of widely used cloud-based software services.

## Assumptions
The **License Requirements** sections of this document assume the organization is using an [M365 E3](https://www.microsoft.com/en-us/microsoft-365/compare-microsoft-365-enterprise-plans) or [G3](https://www.microsoft.com/en-us/microsoft-365/government) license level at a minimum. Therefore, only licenses not included in E3/G3 are listed.

## Key Terminology
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

# Baseline Policies

## 1. External Sharing

This section helps reduce security risks related to sharing files with users external to the agency. This includes guest users, users who use a verification code, and users who access an Anyone link.


### Policies
#### MS.SHAREPOINT.1.1v1
External sharing for SharePoint SHALL be limited to Existing Guests or Only People in your Organization.

<!--Policy: MS.SHAREPOINT.1.1v1; Criticality: SHALL -->
- _Rationale:_ Sharing information outside the organization via SharePoint increases the risk of unauthorized access. By limiting external sharing, administrators decrease the risk of access to information.
- _Last modified:_ June 2023

#### MS.SHAREPOINT.1.2v1
External sharing for OneDrive SHALL be limited to Existing Guests or Only People in your Organization.

<!--Policy: MS.SHAREPOINT.1.2v1; Criticality: SHALL -->
- _Rationale:_ Sharing files outside the organization via OneDrive increases the risk of unauthorized access. By limiting external sharing, administrators decrease the risk of unauthorized unauthorized access to information.
- _Last modified:_ June 2023

#### MS.SHAREPOINT.1.3v1
External sharing SHALL be restricted to approved external domains and/or users in approved security groups per interagency collaboration needs. 

<!--Policy: MS.SHAREPOINT.1.3v1; Criticality: SHALL -->
- _Rationale:_ By limiting sharing to domains or approved security groups used for interagency collaboration purposes, administrators prevent sharing with unknown organizations and individuals.
- _Last modified:_ June 2023
- _Note:_ This policy is only applicable if the external sharing slider on the admin page is set to any value other than Only People in your Organization.

#### MS.SHAREPOINT.1.4v1
Guest access SHALL be limited to the email the invitation was sent to.

<!--Policy: MS.SHAREPOINT.1.4v1; Criticality: SHALL -->
- _Rationale:_ Email invitations allow external guests to access shared information. By requiring guests to sign in using the same account where the invite was sent, administrators ensure only the intended guest can use the invite.
- _Last modified:_ June 2023
- _Note:_ This policy is only applicable if the external sharing slider on the admin page is set to any value other than Only People in your Organization.

### Resources

- [Overview of external sharing in SharePoint and OneDrive in Microsoft 365 \| Microsoft Documents](https://learn.microsoft.com/en-us/sharepoint/external-sharing-overview)

- [Manage sharing settings for SharePoint and OneDrive in Microsoft 365 \| Microsoft Documents](https://learn.microsoft.com/en-us/sharepoint/turn-external-sharing-on-or-off)

### License Requirements

- N/A

### Implementation

#### MS.SHAREPOINT.1.1v1 instructions:

1. Sign in to the **SharePoint admin center**.

2.  Select **Policies** \> **Sharing**.

3.  Adjust external sharing slider for SharePoint to **Existing Guests** or **Only people in your organization**.

4. Select **Save**.

#### MS.SHAREPOINT.1.2v1 instructions:


1.  Sign in to the **SharePoint admin center**.

2.  Select **Policies** \> **Sharing**.

3.  Adjust external sharing slider for OneDrive to **Existing Guests** or **Only people in your organization**.

4. Select **Save**.

#### MS.SHAREPOINT.1.3v1 instructions:

Note: If SharePoint external sharing is set to its most restrictive setting of "Only people in your organization", then no external sharing is allowed and no implementation changes are required for this policy item.

1.  Sign in to the **SharePoint admin center**.

2.  Select **Policies** \> **Sharing**.

3.  Expand **More external sharing settings**.

4.  Select **Limit external sharing by domain**.

5.  Select **Add domains**.

6.  Add each approved external domain users are allowed to share files with.

7.  Select **Manage security groups**

8. Add each approved security group - members of these groups will be allowed to share files externally

9.  Select **Save**.

#### MS.SHAREPOINT.1.4v1 instructions:

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
File and folder default sharing scope SHALL be set to Specific People (only the people the user specifies).

<!--Policy: MS.SHAREPOINT.2.1v1; Criticality: SHALL -->
- _Rationale:_ By making the default sharing the most restrictive, administrators prevent accidentally sharing information too broadly.
- _Last modified:_ June 2023

#### MS.SHAREPOINT.2.2v1
File and folder default sharing permissions SHALL be set to View only.

<!--Policy: MS.SHAREPOINT.2.2v1; Criticality: SHALL -->
- _Rationale:_ Edit access to files and folders could allow a user to make unauthorized changes.  By restricting default permissions to View only, administrators prevent unintended or malicious modification.
- _Last modified:_ June 2023

### Resources

- [File and folder links \| Microsoft
  Documents](https://learn.microsoft.com/en-us/sharepoint/turn-external-sharing-on-or-off#file-and-folder-links)

### License Requirements

- N/A

### Implementation

#### MS.SHAREPOINT.2.1v1 instructions:

1.  Sign in to the **SharePoint admin center**.

2.  Select **Policies** \> **Sharing**

3.  Under **File and folder links**, set the default link type to **Specific people (only the people the user specifies)**

4.  Select **Save**

#### MS.SHAREPOINT.2.2v1 instructions:

1.  Sign in to the **SharePoint admin center**.

2. Select **Policies** \> **Sharing**.

3. Under **File and folder links**, set the permission that's selected by default for sharing links to **View**.

4. Select **Save**.

## 3. Securing Anyone Links and Verification Code Users

Sharing files with external users via the usage of Anyone links or Verification codes is strongly discouraged because it provides access to data within a tenant with weak or no authentication. If these features are used, this section provides some access restrictions that could provide limited security risk mitigations. 

**Note**: The settings in this section are only applicable if an agency is using Anyone links or verification code sharing. See each policy below for details.

### Policies
#### MS.SHAREPOINT.3.1v1
Expiration days for anyone links SHALL be set to 30 days or less.

<!--Policy: MS.SHAREPOINT.3.1v1; Criticality: SHALL -->
- _Rationale:_ Anyone links may be used to provide access to information for a short period of time. Without expiration, however, access is indefinite. By setting expiration timers for anyone links, administrators prevent unintended sustained access to information.
- _Last modified:_ June 2023
- _Note:_ This policy is only applicable if the external sharing slider on the admin center sharing page is set to Anyone.

#### MS.SHAREPOINT.3.2v1
The allowable file and folder permissions for anyone links SHALL be set to View only.

<!--Policy: MS.SHAREPOINT.3.1v1; Criticality: SHALL -->
- _Rationale:_ Unauthorized changes to files can be made if permissions allow editing by anyone.  By restricting permissions on anyone links to View only, administrators prevent anonymous file changes.
- _Last modified:_ June 2023
- _Note:_ This policy is only applicable if the external sharing slider on the admin center sharing page is set to Anyone.

#### MS.SHAREPOINT.3.3v1
Reauthentication days for people who use a verification code SHALL be set to 30 days or less.

<!--Policy: MS.SHAREPOINT.3.1v1; Criticality: SHALL -->
- _Rationale:_ A verification code may be given out to provide access to information for a short period of time. Without expiration, however, access is indefinite. By setting expiration timers for verification code access, administrators prevent  unintended sustained access to information.
- _Last modified:_ June 2023
- _Note:_ This policy is only applicable if the external sharing slider on the admin center sharing page is set to Anyone or New and Existing Guests.

### License Requirements

- N/A

### Resources

- [Secure external sharing recipient experience \| Microsoft
  Documents](https://learn.microsoft.com/en-us/sharepoint/what-s-new-in-sharing-in-targeted-release)

### Implementation

#### MS.SHAREPOINT.3.1v1 instructions:

1.  Sign in to the **SharePoint admin center**.

2.  Select **Policies** \> **Sharing**.

3.  Scroll to the section **Choose expiration and permissions options for Anyone links**.

4.  Select the checkbox **These links must expire within this many days**.

5.  Enter **30** days or less.

6.  Select **Save**.

#### MS.SHAREPOINT.3.2v1 instructions:

1.  Sign in to the **SharePoint admin center**.

2.  Select **Policies** \> **Sharing**.

3.  Scroll to the section **Choose expiration and permissions options for Anyone links**.

4.  Set the configuration items in the section **These links can give these permissions**.

5.  Set the **Files** option to **View**.

6.  Set the **Folders** option to **View**.

7.  Select **Save**.

#### MS.SHAREPOINT.3.3v1 instructions:

1.  Sign in to the **SharePoint admin center**.

2.  Select **Policies** \> **Sharing**.

3.  Expand **More external sharing settings**.

4. Select **People who use a verification code must reauthenticate after this many days**.

5.  Enter **30** days or less.

6. Select **Save**.

## 4. Custom Scripts

This section provides policies for restricting custom scripts execution.

#### MS.SHAREPOINT.4.1v1
Users SHALL be prevented from running custom scripts on personal sites (aka OneDrive).

<!--Policy: MS.SHAREPOINT.4.1v1; Criticality: SHALL -->
- _Rationale:_ Scripts in OneDrive folders run in the context of the user visiting the site and have access to everything the user can access. By preventing custom scripts on personal sites, administrators block a path for potentially malicious code execution.
- _Last modified:_ June 2023

#### MS.SHAREPOINT.4.2v1
Users SHALL be prevented from running custom scripts on self-service created sites.

<!--Policy: MS.SHAREPOINT.4.2v1; Criticality: SHALL -->
- _Rationale:_ Scripts on SharePoint sites run in the context of the user visiting the site and have access to everything the user can access. By preventing custom scripts on self-service created sites, administrators block a path for potentially malicious code execution.
- _Last modified:_ June 2023

### Resources

- [Allow or prevent custom script \| Microsoft
  Documents](https://docs.microsoft.com/en-us/sharepoint/allow-or-prevent-custom-script)

### License Requirements

- N/A

### Implementation

#### MS.SHAREPOINT.4.1v1 instructions:

1.  Sign in to the **SharePoint admin center**.

2.  Select **Settings**.

3.  Scroll down and select **classic settings page**.

4.  Scroll to the **Custom Script** section.

5.  Select **Prevent users from running custom script on personal sites**.

6.  Select **Ok**.

#### MS.SHAREPOINT.4.2v1 instructions:

1.  Sign in to the **SharePoint admin center**.

2.  Select **Settings**.

3.  Scroll down and select **classic settings page**.

4.  Scroll to the **Custom Script** section.

5.  Select **Prevent users from running custom script on self-service created sites**.

6.  Select **Ok**.


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
