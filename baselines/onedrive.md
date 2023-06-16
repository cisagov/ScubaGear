# Introduction

OneDrive for Business is a cloud-based file storage system with online
editing and collaboration tools for Microsoft Office documents and is
part of Office 365. OneDrive for Business facilitates synchronization
across multiple devices and enables secure, compliant, and intelligent
collaboration with multiple people.

This security baseline applies guidance from industry benchmarks on how
to secure cloud solutions on Azure.

## Assumptions

These baseline specifications assume that the agency is using OneDrive
for Business, not personal or school versions, and allowing access using
both OneDrive application sync and the browser-based client.

It is also assumed that the agency will use Azure Active Directory to
authenticate accounts and authorize applications.

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

## 1. External Sharing

Unauthenticated sharing (Anyone links) is used to share data without
authentication and users are free to pass it on to others outside the
agency. To prevent users from unauthenticated sharing of content, turn
off Anyone sharing for users outside the tenant when accessing content
in SharePoint, Groups, or Teams.

### Policies

#### MS.ONEDRIVE.1.1v1
External sharing SHOULD be limited to Existing Guests or the more restrictive setting, Only People in your Organization.
- _Rationale:_ TODO
- _Last Modified:_ June 2023
- _Note:_ Same Implementation in MS.SHAREPOINT.1.1V1

### Resources

- [Limit accidental exposure \| Microsoft
  Docs](https://learn.microsoft.com/en-us/microsoft-365/solutions/share-limit-accidental-exposure?view=o365-worldwide)

### License Requirements

- N/A

### Implementation

**Note**: OneDrive settings can be more restrictive than the SharePoint
setting, but not more permissive.

To turn off Anyone links for the agency:

1.  Open the **SharePoint admin center**.

2.  In the left-hand navigation pane, expand **Policies,** then select
    [**Sharing**](https://go.microsoft.com/fwlink/?linkid=2185222).

3.  Set the SharePoint external sharing settings to either **Existing guests** or **Only people in your organization**, then set OneDrive to either **Existing guests** or **Only people in your organization**.

4.  Click **Save**.

To turn off Anyone links for a site: (**Default is set to organization-level settings**)
 
1.  In the **SharePoint admin center** left navigation pane, expand
    **Sites,** and select [**Active
    sites**](https://go.microsoft.com/fwlink/?linkid=2185220).

2.  Select the site to configure.

3.  In the ribbon, under **Settings**, select **More sharing settings**.

4.  Ensure that **External Sharing** is set to either **Existing guests** or **Only people in your organization**.

5.  Click **Save**.

## 2. Expiration Date for Anyone Links

Files that are stored in SharePoint sites, Groups, and Teams for months
and years could lead to unexpected modifications to files if shared with
unauthenticated people. Configuring expiration times for Anyone links
can help avoid unwanted changes. If Anyone links are enabled, the
expiration date of thirty days or less is necessary.

### Policies

#### MS.ONEDRIVE.2.1v1
Expiration Date SHOULD Be Set for Anyone Links for 30 days or less.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Best practices for unauthenticated sharing \| Microsoft
  Docs](https://learn.microsoft.com/en-us/microsoft-365/solutions/best-practices-anonymous-sharing?view=o365-worldwide)

### License Requirements

- N/A

### Implementation

To set an expiration date for Anyone links across the agency (**Note**:
Only necessary when MS.ONEDRIVE.1.1v1 is not being implemented and OneDrive external sharing is set to Anyone).

1.  Open the **SharePoint admin center.**

2.  In the left-hand navigation pane, expand **Policies**, and then
    select
    [**Sharing**](https://go.microsoft.com/fwlink/?linkid=2185222).

3.  Under **Choose expiration and permissions options for Anyone links**, 
    select the **These links must expire within this many days** 
    check box.

4.  Enter the number of days in the box, and then click **Save**.

## 3. File and Folder Links Default Sharing Settings

The Anyone links default to allow people to edit files, as well as edit
and view files and upload new files to folders. To allow unauthenticated
sharing but keep unauthenticated people from modifying the agency's
content, consider setting the file and folder permissions to **View**.

### Policies

#### MS.ONEDRIVE.3.1v1
Default Link Sharing Type SHOULD NOT Be Set to Anyone
- _Rationale:_ TODO
- _Last modified:_ June 2023
_Note:_ Similar Implementation in MS.SHAREPOINT.2.1V1

#### MS.ONEDRIVE.3.2v1
Anyone Link Permissions SHOULD Be Set to View Only
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Set link permissions \| Microsoft
  Docs](https://learn.microsoft.com/en-us/microsoft-365/solutions/best-practices-anonymous-sharing?view=o365-worldwide#set-link-permissions)

### License Requirements

- N/A

### Implementation

To set the default file and folder sharing link for the organization:

1.  Open the **SharePoint admin center**.

2.  In the left-hand navigation pane, expand **Policies**, then select
    **Sharing**.

3.  Under **File and folder links**, for **Choose the type of link that's selected by default when users share files and folders in SharePoint and OneDrive**
    select **Only people in your organization** or **Specific people (only the people the user specifies)**.

The set Link permission to View Only

1.  Open the **SharePoint admin center**.

2.  In the left-hand navigation pane, expand **Policies**, then select
    **Sharing**.

3.  Under **File and folder links**, for **Choose the permission that's selected by default for sharing links**
    select **View**.

### Resources

- [Set-SPOTenantSyncClientRestriction (SharePointOnlinePowerShell) \|
  Microsoft
  Docs](https://learn.microsoft.com/en-us/powershell/module/sharepoint-online/set-spotenantsyncclientrestriction?view=sharepoint-ps)

### License Requirements

- N/A

### Implementation

The `Set-SPOTenantSyncClientRestriction` cmdlet can be used to enable
the feature for tenancy and set the domain GUIDs in the safe recipients
list. When this feature is enabled, it can take up to 24 hours for the
change to take effect. However, any changes to the safe domains list are
reflected within five minutes.

`Set-SPOTenantSyncClientRestriction -Enable -DomainGuids
"786548DD-877B-4760-A749-6B1EFBC1190A;
877564FF-877B-4760-A749-6B1EFBC1190A" -BlockMacSync:$false`

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
