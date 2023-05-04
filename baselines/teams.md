# Introduction

Microsoft Teams is a text and live chat workspace in Microsoft 365 that
supports video calls, chat messaging, screen-sharing, and file sharing.
It has a permission-based team structure for managing calls and files.
Microsoft teams also enables teams to manage their own user access
rights, security policies, and record video calls.

Access to Teams can be controlled by the user type. In this baseline,
the types of users are defined as follows (Note: these terms vary in use
across Microsoft documentation):

1.  **Internal users**: members of the agency’s M365 tenant.

2.  **External users**: members of a different M365 tenant.

3.  **Business to Business** (B2B) guest users: external users that are
    formally invited to collaborate with the team and added to the
    agency’s Azure Active Directory (AAD) as guest users. These users
    authenticate with their home organization/tenant and are granted
    access to the team by virtue of being listed as guest users on the
    tenant’s AAD.

4.  **Unmanaged users**: users who are not members of any M365 tenant or
    organization (e.g., personal Microsoft accounts).

5.  **Anonymous users**: Teams users joining calls that are not
    authenticated through the agency’s tenant, including unmanaged
    users, external users (except for B2B guests), and true anonymous
    users, meaning users that are not logged in to any Microsoft or
    organization account, such as dial-in users.[^1]

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

## 1. Requesting Control of Shared Desktops or Windows

This setting controls whether external meeting participants can request
control of the shared desktop or window during the meeting. In this
instance, the term “external participants” includes external users, B2B
guest users, unmanaged users and anonymous users.

### Policy

#### MS.TEAMS.1.1v1
External participants SHOULD NOT be enabled to request control of shared desktops or windows in the Global (Org-wide default) meeting policy or in custom meeting policies if any exist

- _Rationale:_ While there is some inherent risk in granting an external participant
control of a shared screen, legitimate use cases for this exist.
Furthermore, the risk is minimal as users cannot gain control of another
user’s screen unless the user giving control explicitly accepts a
control request. As such, while enabling external participants to
request control is discouraged, it may be done, depending on agency
need.
- _Last modified:_ July 2023

### Resources

- [Configure desktop sharing in Microsoft Teams \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoftteams/configure-desktop-sharing)

### License Requirements

- N/A

### Implementation

To ensure external participants do not have the ability to request
control of the shared desktop or window in the meeting:

1.  Sign in to the [**Microsoft Teams admin
    center**](https://admin.teams.microsoft.com).

2.  Select **Meetings** -\> **Meeting policie**s.

3.  Select the **Global (Org-wide default)** policy.

4.  Under the **Content sharing** section, set **Allow an external
    participant to give or request control** to **Off**.

5.  If custom policies have been created, repeat these steps for each
    policy, selecting the appropriate policy in step 3.

## 2. Starting Teams Meetings

This setting controls which meeting participants can start a meeting. In
this instance, the term “anonymous users” refers to any Teams users
joining calls that are not authenticated through the agency’s tenant.

### Policy

#### MS.TEAMS.2.1v1
Anonymous users SHALL NOT be enabled to start meetings in the Global (Org-wide default) meeting policy or in custom meeting policies if any exist
- _Rationale:_ TODO add rationale.
- _Last modified:_ July 2023

### Resources
- [Meeting policy settings - Participants & guests \| Microsoft
Docs](https://docs.microsoft.com/en-us/microsoftteams/meeting-policies-participants-and-guests)

### License Requirements
- N/A

### Implementation
To configure settings for anonymous users:

1.  Sign in to the [**Microsoft Teams admin
    center**](https://admin.teams.microsoft.com).

2.  Select **Meetings -\>** **Meeting policies**.

3.  Select the **Global (Org-wide default)** policy.

4.  Under the **Participants & guests** section**,** set **Let anonymous
    people start a meeting** to **Off.**

5.  If custom policies have been created, repeat these steps for each
    policy, selecting the appropriate policy in step 3.

## 3. Automatic Admittance into meetings
This setting controls which meeting participants wait in the lobby
before they are admitted to the meeting.

### Policy

#### MS.TEAMS.3.1v1
Anonymous users, including dial-in users, SHOULD NOT be admitted automatically.
- _Rationale:_ TODO add rationale.
- _Last modified:_ July 2023

#### MS.TEAMS.3.2v1
Internal users SHOULD be admitted automatically.
- _Rationale:_ TODO add rationale.
- _Last modified:_ July 2023

#### MS.TEAMS.3.3v1
B2B guest users MAY be admitted automatically.
- _Rationale:_ TODO add rationale.
- _Last modified:_ July 2023

#### MS.TEAMS.3.4v1
MS.TEAMS.3.1.1, MS.TEAMS.3.2.1, and MS.TEAMS.3.3.1 SHOULD be applied in the Global (Org-wide default) meeting policy.
- _Rationale:_ TODO add rationale.
- _Last modified:_ July 2023

#### MS.TEAMS.3.5v1
Custom meeting policies MAY be created that allow more flexibility for specific users.
- _Rationale:_ TODO add rationale.
- _Last modified:_ July 2023

### Resources
- [Meeting policy settings - Participants & guests \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoftteams/meeting-policies-participants-and-guests)

### License Requirements
- N/A

### Implementation
To configure settings for automatic meeting admittance:

1.  Sign in to the [**Microsoft Teams admin
    center**](https://admin.teams.microsoft.com).

2.  Select **Meetings -\>** **Meeting** **policies**.

3.  Select the **Global (Org-wide default)** policy.

4.  Under the **Participants & guests** section**,** ensure
    **Automatically admit people** is *not* set to **Everyone**.

5.  In the same section, set **Dial-in users can bypass the lobby** to
    **Off**.

6.  If custom policies have been created, repeat these steps for each
    policy, selecting the appropriate policy in step 3.

## 4. External User Access

External access allows external users to look up internal users by their
email address to initiate chats and calls entirely within Teams.
Blocking external access prevents external users from using Teams as an
avenue for reconnaissance or phishing. Even with external access
disabled, external users will still be able to join Teams calls,
assuming anonymous join is enabled. Depending on agency need, if both
external access and anonymous join need to be blocked—neither required
nor recommended by this baseline—external collaborators would only be
able to attend meetings if added as a B2B guest user.

External access may be granted on a per-domain basis. This may be
desirable in some cases, e.g., for agency-to-agency collaboration (see
the CIO Council's [Interagency Collaboration
Program](https://community.max.gov/display/Egov/Interagency+Collaboration+Program)’s
OMB Max Site for a list of .gov domains for sharing).

Importantly, this setting only pertains to external users (i.e., members
of a different M365 tenant). Access for unmanaged users is controlled
separately.

### Policy

#### MS.TEAMS.4.1v1
External access SHALL only be enabled on a per-domain basis.
- _Rationale:_ TODO add rationale.
- _Last modified:_ July 2023

### Resources

- [Manage external access in Microsoft Teams \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoftteams/manage-external-access)

- [Allow anonymous users to join meetings \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoftteams/meeting-settings-in-teams#allow-anonymous-users-to-join-meetings)

- [Use guest access and external access to collaborate with people
  outside your organization \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoftteams/communicate-with-users-from-other-organizations)

### License Requirements

- N/A

### Implementation

To enable external access for only specific domains:

1.  Sign in to the [**Microsoft Teams admin
    center**](https://admin.teams.microsoft.com).

2.  Select **Users** -\> **External access**.

3.  Under **Choose which external domains your users have access to**,
    select **Allow only specific external domains**.

4.  Click **Allow domains** to add allowed external domains. All domains
    not added in this step will be blocked.

5.  Click **Save.**

## 5. Unmanaged User Access

Blocking contact with unmanaged Teams users prevents these users from
looking up internal users by their email address and initiating chats
and calls within Teams. These users would still be able to join calls,
assuming anonymous join is enabled. Additionally, unmanaged users may be
added to Teams chats if the internal user initiates the contact.

### Policy
#### MS.TEAMS.5.1v1
Unmanaged users SHALL NOT be enabled to initiate contact with internal
users.
- _Rationale:_ TODO add rationale.
- _Last modified:_ July 2023

#### MS.TEAMS.5.2v1
Internal users SHOULD NOT be enabled to initiate contact with unmanaged
users.
- _Rationale:_ TODO add rationale.
- _Last modified:_ July 2023

### Resources

- [Manage contact with external Teams users not managed by an organization
\| Microsoft
Docs](https://docs.microsoft.com/en-us/microsoftteams/manage-external-access#manage-contact-with-external-teams-users-not-managed-by-an-organization)

### License Requirements

- N/A

### Implementation

Steps are outlined in [Manage contact with external Teams users not
managed by an
organization](https://docs.microsoft.com/en-us/microsoftteams/manage-external-access#manage-contact-with-external-teams-users-not-managed-by-an-organization).

1.  Sign in to the **[Microsoft Teams admin
    center](https://admin.teams.microsoft.com).**

2.  Select **Users -\> External access.**

3.  To completely block contact with unmanaged users, under **Teams
    accounts not managed by an organization**, set **People in my
    organization can communicate with Teams users whose accounts aren't
    managed by an organization** to **Off**.

4.  To allow contact with unmanaged users only if the internal user
    initiates the contact:

    1.  Under **Teams accounts not managed by an organization**, set **People in my organization can communicate with Teams users whose accounts aren't managed by an organization** to **On**.

    2.  Clear the check next to **External users with Teams accounts not managed by an organization can contact users in my organization**.

## 6. Skype Users
Microsoft officially retired Skype for Business Online on July 31, 2021, and it is no longer supported. Skype for Business 2015 is slated for Apr 11, 2023 and Skype for Business Server 2015, 2016, 2019 LTSC and Server 2019 is slated for Oct 14, 2025.

### Policy

#### MS.TEAMS.6.1v1
Contact with Skype users SHALL be blocked.
- _Rationale:_ Microsoft officially retired Skype for Business Online on July 31, 2021,
and it is no longer supported.
- _Last modified:_ July 2023

### Resources

- [Communicate with Skype users \| Microsoft
Docs](https://docs.microsoft.com/en-us/microsoftteams/manage-external-access#communicate-with-skype-users)

- [Skype for Business Online to Be Retired in 2021 \| Microsoft Teams
Blog](https://techcommunity.microsoft.com/t5/microsoft-teams-blog/skype-for-business-online-to-be-retired-in-2021/ba-p/777833)

### License Requirements

- N/A

### Implementation

Instructions for *enabling* communications with Skype users are outlined
in [Communicate with Skype
users](https://docs.microsoft.com/en-us/microsoftteams/manage-external-access#communicate-with-skype-users).

1.  Sign in to the **[Microsoft Teams admin
    center](https://admin.teams.microsoft.com).**

2.  Select **Users -\> External access.**

3.  Under **Skype** users, set **Allow users in my organization to
    communicate with Skype users** to **Off**.

4.  Click **Save**.

## 7. Teams Email Integration

Teams provides an optional feature that allows channels to have an email
address and receive email. These channel email addresses are not under
the tenant’s domain; rather, they are associated with a Microsoft-owned
domain, teams.ms. As such, although some basic checks are performed,
agencies do not have control over the security settings associated with
this email. For this reason, email channel integration should be
disabled.

### Policy
#### MS.TEAMS.7.1v1
Teams email integration SHALL be disabled.
- _Rationale:_ TODO
- _Last modified:_ July 2023

### Resources

- [Email Integration \| Microsoft
Docs](https://docs.microsoft.com/en-us/microsoftteams/enable-features-office-365#email-integration)

### License Requirements

- Teams email integration is only available with E3/E5 licenses. It is not
available in GCC or DoD tenants.

### Implementation

To ensure that teams email integration is disabled:

1.  Sign in to the **[Microsoft Teams admin
    center](https://admin.teams.microsoft.com).**

2.  Select **Teams** -\> **Teams Settings**.

3.  Under the **Email integration** section, set **Allow users to send
    emails to a channel email address** to **Off**.

## 8. App Management

Teams is capable of integrating with the following classes of apps:

*Microsoft apps*: apps published by Microsoft.

*Third-party apps*: apps not authored by Microsoft, published to the
Teams store.

*Custom apps*: apps not published to the Teams store, such as apps under
development, that users “sideload” into Teams.

### Policy

#### MS.TEAMS.8.1v1
Agencies SHOULD allow all apps published by Microsoft, but MAY block specific Microsoft apps as needed.
- _Rationale:_ TODO
- _Last modified:_ July 2023

#### MS.TEAMS.8.2v1
Agencies SHOULD NOT allow installation of all third-party apps or custom apps, but MAY allow specific apps as needed.
- _Rationale:_ TODO
- _Last modified:_ July 2023

#### MS.TEAMS.8.3v1
Agencies SHALL establish policy dictating the app review and approval process to be used by the agency.
- _Rationale:_ TODO
- _Last modified:_ July 2023

### Resources

- [Manage app permission policies in Microsoft Teams \| Microsoft
Docs](https://docs.microsoft.com/en-us/microsoftteams/teams-app-permission-policies)

- [Upload your app in Microsoft Teams \| Microsoft
Docs](https://docs.microsoft.com/en-us/microsoftteams/platform/concepts/deploy-and-publish/apps-upload)

### License Requirements

- N/A

### Implementation

To restrict which Team apps can be installed:

1.  Sign in to the **[Microsoft Teams admin
    center](https://admin.teams.microsoft.com).**

2.  Select **Teams apps -**\> **Permission policies.**

3.  Select **Global (Org-wide default)**.

4.  Under **Microsoft apps**, select **Allow all apps**, unless specific
    apps need to be disallowed, in which case select **Block specific
    apps and allow all others**.

5.  Set **Third-party apps** to **Block all apps**, unless specific apps
    have been approved by the agency, in which case select **Allow
    specific apps and block all others**.

6.  Set **Custom apps** to **Block all apps**, unless specific apps have
    been approved by the agency, in which case select **Allow specific
    apps and block all others**.

7.  Click **Save**.

8.  If custom policies have been created, repeat these steps for each
    policy, selecting the appropriate policy in step 3.

## 9. Cloud Recording of Teams Meetings

This setting determines whether video can be recorded in meetings hosted
by a user, during one-on-one calls, and on group calls started by a
user. Agencies should comply with any other applicable policies or
legislation in addition to this guidance.

### Policy

#### MS.TEAMS.9.1v1
Cloud video recording SHOULD be disabled in the global (org-wide default) meeting policy.
- _Rationale:_ TODO
- _Last modified:_ July 2023

#### MS.TEAMS.9.2v1
 Alternate meeting policies MAY be created that allow agency-approved users the ability to record.
- _Rationale:_ TODO
- _Last modified:_ July 2023

#### MS.TEAMS.9.3v1
For all meeting polices that allow cloud recording, recordings SHOULD be stored inside the country of that agency’s tenant.
- _Rationale:_ TODO
- _Last modified:_ July 2023

### Resources

- [Teams cloud meeting recording \| Microsoft
Docs](https://docs.microsoft.com/en-us/microsoftteams/cloud-recording)

- [Assign policies in Teams – getting started \| Microsoft
Docs](https://docs.microsoft.com/en-us/microsoftteams/policy-assignment-overview)

### License Requirements

- N/A

### Implementation

To configure the Meeting policies for cloud video recording:

1.  Sign in to the **[Microsoft Teams admin
    center](https://admin.teams.microsoft.com).**

2.  Select **Meetings** -\> **Meeting policies**.

3.  Select the **Global (Org-wide default)** policy.

4.  Under the **Recording & transcription** section, set **Cloud
    recording** to **Off**.

5.  Select **Save**.

If there is a legitimate business need, *specific* users can be given
permission to record meetings. To allow specific users the ability to
record meetings:

1.  Sign in to the **[Microsoft Teams admin
    center](https://admin.teams.microsoft.com).**

2.  Select **Meetings** -\> **Meeting policies**.

3.  Create a new policy by selecting **Add**. Give this new policy a
    name and appropriate description.

4.  Under the **Recording & transcription** section, set **Cloud
    recording** to **On**.

5.  Under the **Recording & transcription** section, set **Store
    recordings outside of your country or region** to **Off**.

6.  Select **Save**.

7.  After selecting **Save**, a table displays the set of policies.
    Select the row containing the new policy, then select **Manage
    users**.

8.  Assign the users that need the ability to record to this policy.

9.  Select **Apply**.

## 10. Recording of Live Events

Live events are recorded by default. Agencies should increase their
privacy by changing the policy so that events are only recorded at the
organizer’s discretion.

### Policy
#### MS.TEAMS.10.1v1
Record an event SHOULD be set to Organizer can record.
- _Rationale:_ TODO
- _Last modified:_ July 2023

### Resources

- [Live Event Recording Policies \| Microsoft
Docs](https://docs.microsoft.com/en-us/microsoftteams/teams-live-events/live-events-recording-policies)

### License Requirements

- N/A

### Implementation

1.  Sign in to the **[Microsoft Teams admin
    center](https://admin.teams.microsoft.com).**

2.  Select **Meetings** -\> **Live events policies**.

3.  Select **Global (Org-wide default)**.

4.  Set **Record an event** to **Organizer can record**.

5.  Click **Save**.

## 11. Data Loss Prevention

Data loss prevention (DLP) helps prevent both accidental leakage of
sensitive information as well as intentional exfiltration of data. DLP
forms an integral part of securing Microsoft Teams. There a several
commercial DLP solutions available that document support for Microsoft
Teams. Agencies may select any service that fits their needs and meets
the requirements outlined in this baseline control.

Microsoft offers DLP services, controlled within the [Microsoft 365
compliance](https://compliance.microsoft.com) admin center. Though use
of Microsoft’s DLP solution is not strictly required, guidance for
configuring Microsoft’s DLP solution can be found in the “Data Loss
Prevention SHALL Be Enabled” section of the *Defender for Office 365
Minimum Viable Secure Configuration Baseline*. The DLP solution selected
by an agency should offer services comparable to those offered by
Microsoft.

### Policy

#### MS.TEAMS.11.1v1
A DLP solution SHALL be enabled.
- _Rationale:_ TODO
- _Last modified:_ July 2023

#### MS.TEAMS.11.2v1
Agencies SHOULD use either the native DLP solution offered by Microsoft or a DLP solution that offers comparable services.
- _Rationale:_ TODO
- _Last modified:_ July 2023

#### MS.TEAMS.11.3v1
Agencies SHOULD use either the native DLP solution offered by Microsoft or a DLP solution that offers comparable services.
- _Rationale:_ TODO
- _Last modified:_ July 2023

#### MS.TEAMS.11.4v1
The DLP solution SHALL protect Personally Identifiable Information (PII)
and sensitive information, as defined by the agency. At a minimum, the
sharing of credit card numbers, taxpayer Identification Numbers (TIN),
and Social Security Numbers (SSN) via email SHALL be restricted.
- _Rationale:_ TODO
- _Last modified:_ July 2023

### Resources

- The “Data Loss Prevention SHALL Be Enabled” section of the *Defender for
Office 365 Minimum Viable Secure Configuration Baseline*.

## 12. Attachment Scanning

Though any product that fills the requirements outlined in this baseline
control may be used, for guidance on implementing malware scanning using
Microsoft Defender, see the “Data Loss Prevention SHALL Be Enabled”
section of the *Defender for Office 365 Minimum Viable Secure
Configuration Baseline*.

### Policy

#### MS.TEAMS.12.1v1
Attachments included with Teams messages SHOULD be scanned for malware.
- _Rationale:_ TODO
- _Last modified:_ July 2023

#### MS.TEAMS.12.2v1
Users SHOULD be prevented from opening or downloading files detected as malware.
- _Rationale:_ TODO
- _Last modified:_ July 2023

### Resources

- The “Data Loss Prevention SHALL Be Enabled” section of the *Defender for
Office 365 Minimum Viable Secure Configuration Baseline.*

## 13. Link Protection

Microsoft Defender protects users from malicious links included in Teams
messages by prepending

`https://\*.safelinks.protection.outlook.com/?url=`

to URLs included in the messages. By prepending the safe links URL,
Microsoft can proxy the initial URL through their scanning service.
Their proxy performs the following checks:

- Compares the URL with a block list

- Compares the URL with a list of know malicious sites

- If the URL points to a downloadable file, applies real-time file
scanning

- If all checks pass, the user is redirected to the original URL.

Though Defender’s use is not strictly required for this purpose,
guidance for enabling link scanning using Microsoft Defender is included
in the “Safe Links Policies SHALL Be Enabled” and “Safe Links in Global
Settings SHALL be Configured” sections of the *Defender for Office 365
Minimum Viable Secure Configuration Baseline.*

### Policy

#### MS.TEAMS.13.1v1
URL comparison with a block-list SHOULD be enabled.
- _Rationale:_ TODO
- _Last modified:_ July 2023

#### MS.TEAMS.13.2v1
Direct download links SHOULD be scanned for malware.
- _Rationale:_ TODO
- _Last modified:_ July 2023

#### MS.TEAMS.13.3v1
User click tracking SHOULD be enabled.
- _Rationale:_ TODO
- _Last modified:_ July 2023

### Resources

- The “Safe Links Policies SHALL Be Enabled” section of the *Defender for
Office 365 Minimum Viable Secure Configuration Baseline.*


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

[^1]: Note that B2B guest users and all anonymous users except for
    external users appear in Teams calls as *John Doe (Guest)*. To avoid
    any potential confusion this may cause, true guest users are always
    referred to as B2B guest users in this document.
