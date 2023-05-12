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

## 1. Anyone Links

Unauthenticated sharing (Anyone links) is used to share data without
authentication and users are free to pass it on to others outside the
agency. To prevent users from unauthenticated sharing of content, turn
off Anyone sharing for users outside the tenant when accessing content
in SharePoint, Groups, or Teams.

### Policies

#### MS.ONEDRIVE.1.1v1
Anyone links SHOULD be disabled.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Limit accidental exposure \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/solutions/share-limit-accidental-exposure?view=o365-worldwide)

###  License Requirements

- N/A

###  Implementation

**Note**: OneDrive settings can be more restrictive than the SharePoint
setting, but not more permissive.

To turn off Anyone links for the agency:

1.  Open the **SharePoint admin center**.

2.  In the left-hand navigation pane, expand **Policies,** then select
    [**Sharing**](https://go.microsoft.com/fwlink/?linkid=2185222).

3.  Set the SharePoint external sharing settings to **New and existing
    guests**, then set OneDrive to **New and existing guests**.

4.  Click **Save**.

To turn off Anyone links for a site:

1.  In the **SharePoint admin center** left navigation pane, expand
    **Sites,** and select [**Active
    sites**](https://go.microsoft.com/fwlink/?linkid=2185220).

2.  Select the site to configure.

3.  In the ribbon, select **Sharing**.

4.  Ensure that **Sharing** is set to **New and existing guests**.

5.  Click **Save**.

## 2. Expiration Date for Anyone Links

Files that are stored in SharePoint sites, Groups, and Teams for months
and years could lead to unexpected modifications to files if shared with
unauthenticated people. Configuring expiration times for Anyone links
can help avoid unwanted changes. If Anyone links are enabled, the
expiration date SHOULD be set to thirty days or as determined by mission
needs or agency policy.

### Policies

#### MS.ONEDRIVE.2.1v1
Expiration Date SHOULD Be Set for Anyone Links.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.ONEDRIVE.2.2v1
Expiration date SHOULD be set to thirty days.
- _Rationale:_ TODO
- _Last modified:_ June 2023

###  Resources

- [Best practices for unauthenticated sharing \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/solutions/best-practices-anonymous-sharing?view=o365-worldwide)

###  License Requirements

- N/A

###  Implementation

To set an expiration date for Anyone links across the agency (**Note**:
Anyone links must be enabled).

1.  Open the **SharePoint admin center.**

2.  In the left-hand navigation pane, expand **Policies**, and then
    select
    [**Sharing**](https://go.microsoft.com/fwlink/?linkid=2185222).

3.  Under **Choose expiration and permissions options for Anyone
    links**, select the **These links must expire within this many
    days** check box.

4.  Enter the number of days in the box, and then click **Save**.

To set an expiration date for Anyone links on a specific site:

1.  Open the **SharePoint admin center**, expand **Sites**, and then
    select [**Active
    sites**](https://go.microsoft.com/fwlink/?linkid=2185220).

2.  Select the site to change, and then select **Sharing**.

3.  Under **Advanced settings for Anyone links**, under **Expiration of
    Anyone links**, clear the **Same as organization-level setting**
    check box.

4.  Select the **These links must expire within this many days** option
    and enter a number of days in the box.

5.  Click **Save**.

## 3. Link Permissions

The Anyone links default to allow people to edit files, as well as edit
and view files and upload new files to folders. To allow unauthenticated
sharing but keep unauthenticated people from modifying the agency's
content, consider setting the file and folder permissions to **View**.

### Policies

#### MS.ONEDRIVE.3.1v1
Link Permissions SHOULD Be Set to Enabled Anyone Links to View.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Set link permissions \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/solutions/best-practices-anonymous-sharing?view=o365-worldwide#set-link-permissions)

### 2.3.3 License Requirements

- N/A

### Implementation

1.  Open the **SharePoint admin center**.

2.  In the left-hand navigation pane, expand **Policies**, then select
    **Sharing**.

3.  Under **Advanced settings for Anyone links**, set the file and
    folder permissions to **View**.

## 4. OneDrive Client

Configuring OneDrive to sync only to agency-deined domains ensures that
users can only sync to agency-managed computers.

### Policies

#### MS.ONEDRIVE.4.1v1
OneDrive Client SHALL Be Restricted to Windows for Agency-Defined Domain(s).
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Allow syncing only on computers joined to specific domains – OneDrive
  \| Microsoft
  Docs](https://docs.microsoft.com/en-us/onedrive/allow-syncing-only-on-specific-domains)

### License Requirements

- N/A

### Implementation

1.  Open the **SharePoint admin center.**

2.  In the left-hand navigation pane, select **Settings** and sign in
    with an account that has [admin
    permissions](https://docs.microsoft.com/en-us/sharepoint/sharepoint-admin-role)
    for the agency.

3.  Select **Sync**.

4.  Select the **Allow syncing only on computers joined to specific
    domains** check box.

5.  Add the [Globally Unique Identifier (GUID) of each
    domain](https://docs.microsoft.com/en-us/powershell/module/activedirectory/get-addomain?view=windowsserver2022-ps) for
    the member computers that the agency wants to be able to sync.

**Note:** Add the domain GUID of the computer domain membership. If
users are in a separate domain, only the domain GUID that the computer
account is joined to is required.

**Important:** This setting is only applicable to Active Directory
domains. It does not apply to Azure Active Directory (AAD) domains. If
agency devices are only Azure AD joined, consider using a [Conditional
Access Policy](https://docs.microsoft.com/en-us/azure/active-directory/conditional-access/overview)
instead.

6.  Click **Save**.

## 5. Sync with Mac for Agency-Defined Devices

Set restrictions on whether users can sync items to non-domain joined
machines, control the list of allowed domains, and manage whether Mac
clients (which do not support domain join) can sync.

### Policies

#### MS.ONEDRIVE.5.1v1
OneDrive Client SHALL Be Restricted to Sync with Mac for Agency-Defined Devices.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Set-SPOTenantSyncClientRestriction (SharePointOnlinePowerShell) \|
  Microsoft
  Docs](https://docs.microsoft.com/en-us/powershell/module/sharepoint-online/set-spotenantsyncclientrestriction?view=sharepoint-ps#:~:text=In%20order%20to%20explicitly%20block%20Microsoft%20OneDrive%20client,cmdlet%20with%20the%20BlockMacSync%20parameter%20set%20to%20true.?msclkid=f80f95c5c4c611ecac7de0980370f33c)

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

## 6. Local Domain Sync

Configuring OneDrive to sync only to agency-defined domains ensures that
users can only sync to agency-managed computers.

### Policies

#### MS.ONEDRIVE.6.1v1
OneDrive Client Sync SHALL Only Be Allowed Within the Local Domain.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Allow syncing only on computers joined to specific domains \|
  Microsoft
  Documents](https://docs.microsoft.com/en-us/onedrive/allow-syncing-only-on-specific-domains)

### License Requirements

- N/A

### Implementation

1.  Open the **SharePoint admin center**.

2.  In the left-hand navigation pane, select **Settings**.

3.  Next to **OneDrive**, click **Sync** to display synchronization
    settings.

4.  On the **Sync settings** page, confirm that **Allow syncing only on
    computers joined to specific domains** is checked, and that a domain
    GUID displays in the box below it.

## 7. Legacy Authentication

Modern authentication, based on Active Directory Authentication Library
(ADAL) and Open Authorization 2 (OAuth2), is a critical component of
security in Office 365. It provides the device authentication and
authorization capability of Office 365, which is a foundational security
component. If modern authentication is not required, this creates a
loophole that could allow unauthorized devices to connect to OneDrive
and download/exfiltrate enterprise data. For this reason, it is
important to make sure that only apps that support modern authentication
are allowed to connect, assuring that only authorized devices are
allowed to access enterprise data.

### Policies

#### MS.ONEDRIVE.7.1v1
Legacy Authentication SHALL Be Blocked.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Control access from unmanaged devices \| Microsoft
  Documents](https://docs.microsoft.com/en-us/sharepoint/control-access-from-unmanaged-devices)

### License Requirements

- N/A

### Implementation

1.  Open the **SharePoint admin center**.

2. In the left-hand navigation pane, click **Policies** \> **Access
    Control** \> **Device access**.

3. Click **Apps that don’t use modern authentication** to display the
    device access settings.

4. On the **Apps that don’t use modern authentication** page, select
    the **Block access** option.

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

# Configuring On-Premises Devices

##### Limit Syncing to Agency-defined Equipment within the Agency (Tenants)

OneDrive includes a sync client that allows users to synchronize their
files from the OneDrive cloud service to their desktop/laptop computer.
This allows them to interact with a local copy of the files in a way
that is very similar to working with regular local files on their
computer.

**Resources**

[Use OneDrive policies to control sync settings - OneDrive \| Microsoft
Docs](https://docs.microsoft.com/en-us/onedrive/use-group-policy#allow-syncing-onedrive-accounts-for-only-specific-organizations)
