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

#### MS.ONEDRIVE.1.2v1
Expiration Date SHOULD Be Set for Anyone Links.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.ONEDRIVE.1.2v1
Expiration date SHOULD be set to thirty days.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.ONEDRIVE.1.3v1
Link Permissions SHOULD Be Set to Enabled Anyone Links to View.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Limit accidental exposure \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/solutions/share-limit-accidental-exposure?view=o365-worldwide)
- [Best practices for unauthenticated sharing \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/solutions/best-practices-anonymous-sharing?view=o365-worldwide)
- [Set link permissions \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/solutions/best-practices-anonymous-sharing?view=o365-worldwide#set-link-permissions)

### License Requirements

- N/A


## 2. OneDrive Client Sync 
Configuring OneDrive to sync only to agency-defined domains ensures that
users can only sync to agency-managed computers.

### Policies
#### MS.ONEDRIVE.2.1v1
OneDrive Client SHALL Be Restricted to Windows for Agency-Defined Domain(s).
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.ONEDRIVE.2.2v1
OneDrive Client SHALL Be Restricted to Sync with Mac for Agency-Defined Devices.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.ONEDRIVE.2.3v1
OneDrive Client Sync SHALL Only Be Allowed Within the Local Domain.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Allow syncing only on computers joined to specific domains – OneDrive
  \| Microsoft
  Docs](https://docs.microsoft.com/en-us/onedrive/allow-syncing-only-on-specific-domains)

- [Set-SPOTenantSyncClientRestriction (SharePointOnlinePowerShell) \|
  Microsoft
  Docs](https://docs.microsoft.com/en-us/powershell/module/sharepoint-online/set-spotenantsyncclientrestriction?view=sharepoint-ps#:~:text=In%20order%20to%20explicitly%20block%20Microsoft%20OneDrive%20client,cmdlet%20with%20the%20BlockMacSync%20parameter%20set%20to%20true.?msclkid=f80f95c5c4c611ecac7de0980370f33c)
  
  
### License Requirements

- N/A

## 3. Legacy Authentication
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
#### MS.ONEDRIVE.3.1v1
Legacy Authentication SHALL Be Blocked.


### Resources

- [Control access from unmanaged devices \| Microsoft
  Documents](https://docs.microsoft.com/en-us/sharepoint/control-access-from-unmanaged-devices)

### License Requirements

- N/A


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
