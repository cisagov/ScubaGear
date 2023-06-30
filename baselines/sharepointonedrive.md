# CISA M365 Security Configuration Baseline for SharePoint Online and OneDrive

SharePoint Online is a web-based collaboration and document management
platform. It is primarily used to collaborate on documents and communicate information in project teams. OneDrive is a cloud-based file storage system primarily used to store a user's personal files but it can also be used to share documents with others. This security baseline provides policies to help secure both of these services.

## License Compliance and Copyright

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

## Assumptions

The **License Requirements** sections of this document assume the
organization is using an [M365
E3](https://www.microsoft.com/en-us/microsoft-365/compare-microsoft-365-enterprise-plans)
or [G3](https://www.microsoft.com/en-us/microsoft-365/government)
license level. Therefore, only licenses not included in E3/G3 are
listed.

# Baseline Policies

## 1. External Sharing

This section helps reduce security risks related to the sharing of files with users external to the agency. This includes guest users, users who use a verification code and users who access an Anyone link.

### Policies
#### MS.SHAREPOINT-ONEDRIVE.1.1v1
External sharing for SharePoint SHALL be limited to Existing Guests or Only People in your Organization.
- _Rationale:_ Sharing information outside the organization increases the risk of unauthorized disclosure. By limiting external sharing, administrators decrease the risk of unauthorized disclosure.
- _Last modified:_ June 2023

#### MS.SHAREPOINT-ONEDRIVE.1.2v1
External sharing for OneDrive SHALL be limited to Existing Guests or Only People in your Organization.
- _Rationale:_ Sharing files outside the organization increases the risk of unauthorized disclosure. By limiting external sharing, administrators decrease the risk of unauthorized disclosure.
- _Last modified:_ June 2023

#### MS.SHAREPOINT-ONEDRIVE.1.3v1
External sharing SHALL be restricted to approved external domains per interagency collaboration needs.
- _Rationale:_ By limiting sharing to domains used for interagency collaboration purposes, administrators prevent sharing with unknown organizations and individuals.
- _Last modified:_ June 2023
- _Note:_ This policy is only applicable if the external sharing slider on the admin page is set to any value other than Only People in your Organization.

#### MS.SHAREPOINT-ONEDRIVE.1.4v1
Only users in approved security groups SHALL be allowed to share externally.
- _Rationale:_ By limiting sharing to approved security groups based on interagency collaboration needs, administrators ensure only approved users can use share information outside the organization.
- _Last modified:_ June 2023
- _Note:_ This policy is only applicable if the external sharing slider on the admin page is set to any value other than Only People in your Organization.

#### MS.SHAREPOINT-ONEDRIVE.1.5v1
Guest access SHALL be limited to the email the invitation was sent to.
- _Rationale:_ Email invitations allow external guests to access shared information. By requiring guests to sign in using the same account where the invite was sent, administrators ensure only the intended guest can use the invite.
- _Last modified:_ June 2023
- _Note:_ This policy is only applicable if the external sharing slider on the admin page is set to any value other than Only People in your Organization.

### Resources

- [Overview of external sharing in SharePoint and OneDrive in Microsoft 365 \| Microsoft Documents](https://learn.microsoft.com/en-us/sharepoint/external-sharing-overview)

- [Manage sharing settings for SharePoint and OneDrive in Microsoft 365 \| Microsoft Documents](https://docs.microsoft.com/en-us/sharepoint/turn-external-sharing-on-or-off)

### License Requirements

- N/A

### Implementation

All of the settings in this section are configured in the **SharePoint admin center**.

#### MS.SHAREPOINT-ONEDRIVE.1.1v1 instructions:

1.  Select **Policies** \> **Sharing**

2.  Adjust external sharing slider for SharePoint to **Existing Guests** or **Only people in your organization**

3. Select **Save**

#### MS.SHAREPOINT-ONEDRIVE.1.2v1 instructions:

1.  Follow the same instructions as MS.SHAREPOINT-ONEDRIVE.1.1v1 but set the slider value for OneDrive.

#### MS.SHAREPOINT-ONEDRIVE.1.3v1 instructions:

1.  Select **Policies** \> **Sharing**

2.  Expand **More external sharing settings**

3.  Select **Limit external sharing by domain**

4.  Select **Add domains**

5.  Add each approved external domain that users allowed to share files with

6.  Select **Save**

#### MS.SHAREPOINT-ONEDRIVE.1.4v1 instructions:

1.  Select **Policies** \> **Sharing**

2.  Expand **More external sharing settings**

3.  Select **Allow only users in specific security groups to share
    externally**

4.  Select **Manage security groups**

5. Add each approved security group - members of these groups will be allowed to share files externally

6. Select **Save**

#### MS.SHAREPOINT-ONEDRIVE.1.4v1 instructions:

1.  Select **Policies** \> **Sharing**

2.  Expand **More external sharing settings**

3. Select **Guests must sign in using the same account to which sharing invitations are sent**

4. Select **Save**

## 2. File and Folder Default Sharing Settings

This section provides policies to set the scope and permissions for sharing links to secure default values.

### Policies

#### MS.SHAREPOINT-ONEDRIVE.2.1v1
File and folder default sharing scope SHALL be set to Specific People (only the people the user specifies).
- _Rationale:_ By making the default sharing the most restrictive, administrators prevent accidentally sharing information too broadly.
- _Last modified:_ June 2023

#### MS.SHAREPOINT-ONEDRIVE.2.2v1
File and folder default sharing permissions SHALL be set to View only.
- _Rationale:_ Edit access to files and folders could allow a user to make unauthorized changes.  By restricting default permissions to View only, administrators prevent unintended or malicious modification.
- _Last modified:_ June 2023

### Resources

- [File and folder links \| Microsoft
  Documents](https://docs.microsoft.com/en-us/sharepoint/turn-external-sharing-on-or-off#file-and-folder-links)

### License Requirements

- N/A

### Implementation

All of the settings in this section are configured in the **SharePoint admin center**.

#### MS.SHAREPOINT-ONEDRIVE.2.1v1 instructions:

1.  Select **Policies** \> **Sharing**

2.  Under **File and folder links**, set the default link type to **Specific people (only the people the user specifies)**

3.  Select **Save**

#### MS.SHAREPOINT-ONEDRIVE.2.2v1 instructions:

1.  Navigate to the same location in the portal as MS.SHAREPOINT-ONEDRIVE.2.1v1, but set the permission that's selected by default for sharing links to **View**

## 3. Securing Anyone Links and Verification Code Users

Sharing of files with external users via the usage of Anyone links or Verification codes is strongly discouraged because it provides access to data within a tenant with weak or no authentication. In the event that these features are being used, this section provides some access restrictions that could provide limited security risk mitigations. 

**Note**: The settings in this section are only applicable if an agency is using anyone links or verification code sharing. See each policy below for details.

### Policies
#### MS.SHAREPOINT-ONEDRIVE.3.1v1
Expiration days for anyone links SHALL be set to 30 days or less.
- _Rationale:_ Anyone links may be used to provide access to information for a short period of time. Without expiration, however, access is indefinite. By setting expiration timers for anyone links, administrators prevent unintended sustained access to information.
- _Last modified:_ June 2023
- _Note:_ This policy is only applicable if the external sharing slider on the admin center sharing page is set to Anyone.

#### MS.SHAREPOINT-ONEDRIVE.3.2v1
The allowable file and folder permissions for anyone links SHALL be set to View only.
- _Rationale:_ Unauthorized changes to files can be made if permissions allow editing by anyone.  By restricting permissions on anyone links to View only, administrators prevent anonymous file changes.
- _Last modified:_ June 2023
- _Note:_ This policy is only applicable if the external sharing slider on the admin center sharing page is set to Anyone.

#### MS.SHAREPOINT-ONEDRIVE.3.3v1
Reauthentication days for people who use a verification code SHALL be set to 30 days or less.
- _Rationale:_ A verification code may be given out to provide access to information for a short period of time. Without expiration, however, access is indefinite. By setting expiration timers for verification code access, administrators prevent  unintended sustained access to information.
- _Last modified:_ June 2023
- _Note:_ This policy is only applicable if the external sharing slider on the admin center sharing page is set to Anyone or New and Existing Guests.

### License Requirements

- N/A

### Resources

- [Secure external sharing recipient experience \| Microsoft
  Documents](https://learn.microsoft.com/en-us/sharepoint/what-s-new-in-sharing-in-targeted-release)

### Implementation

All of the settings in this section are configured in the **SharePoint admin center**.

#### MS.SHAREPOINT-ONEDRIVE.3.1v1 instructions:

1.  Select **Policies** \> **Sharing**

2.  Scroll to the section **Choose expiration and permissions options for Anyone links**

3.  Select the checkbox **These links must expire within this many days**

4.  Enter “30” days or less

5.  Select **Save**

#### MS.SHAREPOINT-ONEDRIVE.3.2v1 instructions:

1.  Select **Policies** \> **Sharing**

2.  Scroll to the section **Choose expiration and permissions options for Anyone links**

3.  Set the configuration items in the section **These links can give these permissions**

4.  Set the **Files** option to **View**

5.  Set the **Folders** option to **View**

6.  Select **Save**

#### MS.SHAREPOINT-ONEDRIVE.3.3v1 instructions:

1.  Select **Policies** \> **Sharing**

2.  Expand **More external sharing settings**

3. Select **People who use a verification code must reauthenticate after this many days**

4.  Enter “30” days or less

5. Select **Save**

## 4. Custom Scripts

This section provides policies for restricting the execution of custom scripts.
å
#### MS.SHAREPOINT-ONEDRIVE.4.1v1
Users SHALL be prevented from running custom scripts on personal sites (aka OneDrive).
- _Rationale:_ Scripts on SharePoint sites run in the context of the user visiting the site and have access to everything that user can access. By preventing custom scripts on personal sites, administrators block a path for potentially malicious code execution.
- _Last modified:_ June 2023

#### MS.SHAREPOINT-ONEDRIVE.4.2v1
Users SHALL be prevented from running custom scripts on self-service created sites.
- _Rationale:_ Scripts on SharePoint sites run in the context of the user visiting the site and have access to everything that user can access. By preventing custom scripts on self-service created sites, administrators block a path for potentially malicious code execution.
- _Last modified:_ June 2023

### Resources

- [Allow or prevent custom script \| Microsoft
  Documents](https://docs.microsoft.com/en-us/sharepoint/allow-or-prevent-custom-script)

### License Requirements

- N/A

### Implementation

All of the settings in this section are configured in the **SharePoint admin center**.

#### MS.SHAREPOINT-ONEDRIVE.4.1v1 instructions:

1.  Select **Settings**

2.  Scroll down and select **classic settings page**

3.  Scroll to the **Custom Script** section

4.  Select **Prevent users from running custom script on personal sites**

5.  Select **Ok**

#### MS.SHAREPOINT-ONEDRIVE.4.2v1 instructions:

1.  Navigate to the same location in the portal as MS.SHAREPOINT-ONEDRIVE.4.1v1, but select the option **Prevent users from running custom script on self-service created sites**

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