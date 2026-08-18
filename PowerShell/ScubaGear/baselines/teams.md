**`TLP:CLEAR`**
# CISA M365 Secure Configuration Baseline for Teams

Microsoft 365 (M365) Teams is a cloud-based text and live chat workspace that supports video calls, chat messaging, screen sharing, and file sharing. This secure configuration baseline (SCB) provides specific policies to strengthen Microsoft Teams' security.

Many admin controls for Teams are found in the **Teams admin center**.
However, several essential security functions for Teams require a dedicated security
tool, e.g., for data loss prevention. M365 provides these security functions
natively via Defender for Office 365. Notably, Defender for Office 365 capabilities
require Defender for Office 365 Plan 1 or 2. These are included with E5 and G5
and are available as add-ons for E3 and G3. However, third-party solutions that
offer comparable security functions can be used in lieu of Defender.
Refer to the [CISA M365 Secure Configuration Security Suite Baseline](securitysuite.md)
for additional guidance.

The Secure Cloud Business Applications (SCuBA) project, run by the Cybersecurity and Infrastructure Security Agency (CISA), provides guidance and capabilities to secure federal civilian executive branch (FCEB) agencies’ cloud business application environments and protect federal information that is created, accessed, shared, and stored in those environments.

The CISA SCuBA SCBs for M365 help secure federal information assets stored within M365 cloud business application environments through consistent, effective, and manageable security configurations. CISA created baselines tailored to the federal government’s threats and risk tolerance with the knowledge that every organization has different threat models and risk tolerance. While use of these baselines will be mandatory for civilian Federal Government agencies, organizations outside of the Federal Government may also find these baselines to be useful references to help reduce risks.

For non-Federal users, the information in this document is being provided "as is" for INFORMATIONAL PURPOSES ONLY. CISA does not endorse any commercial product or service, including any subjects of analysis. Any reference to specific commercial entities or commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply endorsement, recommendation, or favoritism by CISA. Without limiting the generality of the foregoing, some controls and settings are not available in all products; CISA has no control over vendor changes to products offerings or features.  Accordingly, these SCuBA SCBs for M365 may not be applicable to the products available to you. This document does not address, ensure compliance with, or supersede any law, regulation, or other authority. Entities are responsible for complying with any recordkeeping, privacy, and other laws that may apply to the use of technology. This document is not intended to, and does not, create any right or benefit for anyone against the United States, its departments, agencies, or entities, its officers, employees, or agents, or any other person.

> This document is marked TLP:CLEAR. Recipients may share this information without restriction. Information is subject to standard copyright rules. For more information on the Traffic Light Protocol, see https://www.cisa.gov/tlp.

## License Compliance and Copyright
Portions of this document are adapted from documents in Microsoft's [M365](https://github.com/MicrosoftDocs/microsoft-365-docs/blob/public/LICENSE) and [Azure](https://github.com/MicrosoftDocs/azure-docs/blob/main/LICENSE) GitHub repositories. The respective documents are subject to copyright and are adapted under the terms of the Creative Commons Attribution 4.0 International license. Source documents are linked throughout this document. The United States government has adapted selections of these documents to develop innovative and scalable configuration standards to strengthen the security of widely used cloud-based software services.

## Assumptions
The **License Requirements** sections of this document assume the organization is using an [M365 E3](https://www.microsoft.com/en-us/microsoft-365/compare-microsoft-365-enterprise-plans) or [G3](https://www.microsoft.com/en-us/microsoft-365/government) license level at a minimum. Therefore, only licenses not included in E3/G3 are listed.

## Key Terminology
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

**User Types**: Access to Teams can be controlled by the user type. In this baseline, the types of users are defined as follows:

1.  **Internal users**: Members of the agency's M365 tenant.

2.  **External users**: Members of a different M365 tenant.

3.  **Business to Business (B2B) guest users**: External users who are
    formally invited to collaborate with the team and added to the
    agency's Microsoft Entra as guest users. These users
    authenticate with their home organization/tenant and are granted
    access to the team by virtue of being listed as guest users on the
    tenant's Microsoft Entra.

4.  **Unmanaged users**: Users who are not members of any M365 tenant or
    organization (e.g., personal Microsoft accounts).

5.  **Anonymous users**: Teams users joining calls who are not
    authenticated through the agency's tenant; these users include unmanaged
    users, external users (except for B2B guests), and true anonymous
    users (i.e., users who are not logged in to any Microsoft or
    organization account, such as dial-in users[^1]).

[^1]: Note that B2B guest users and all anonymous users except for external users appear in Teams calls as _John Doe (Guest)_. To avoid potential confusion, true guest users are always referred to as B2B guest users in this document.

**BOD 25-01 Requirement**: This indicator means that the policy is required under CISA BOD 25-01.

**Automated Check**: This indicator means that the policy can be automatically checked via ScubaGear. See the [Quick Start Guide](../../../README.md#quick-start-guide) for help getting started.

**Manual**: This indicator means that the policy requires manual verification of configuration settings.

# Baseline Policies

## 1. Meeting Policies

This section helps reduce security risks posed by the external participants during meetings. In this instance, the term "external participants" includes external users, B2B guest users, unmanaged users, and anonymous users.

This section helps reduce security risks related to the user permissions for recording Teams meetings and events. These policies and user permissions apply to meetings hosted by a user, as well as during one-on-one calls and group calls started by a user. Agencies should comply with any other applicable policies or legislation in addition to this guidance.

### Policies

#### MS.TEAMS.1.1v1
External meeting participants SHOULD NOT be enabled to request control of shared desktops or windows.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.TEAMS.1.1v1; Criticality: SHOULD -->
- _Rationale:_ An external participant with control of a shared screen could potentially perform unauthorized actions on the shared screen. This policy reduces that risk by removing an external participant's ability to request control. However, if an agency has a legitimate use case to grant this control, it may be done on a case-by-case basis.
- _Last modified:_ July 2023
- _Note:_ This policy applies to the Global (Org-wide default) meeting policy, as well as custom meeting policies.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-17a
- _MITRE ATT&CK TTP Mapping:_
  - None

#### MS.TEAMS.1.2v2
Anonymous users SHALL NOT be enabled to start meetings.

[![BOD 25-01 Requirement](https://img.shields.io/badge/BOD_25--01_Requirement-C41230)](https://www.cisa.gov/news-events/directives/bod-25-01-implementation-guidance-implementing-secure-practices-cloud-services)
[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.TEAMS.1.2v2; Criticality: SHALL -->
- _Rationale:_ This policy protects against anonymous users starting Microsoft Teams meetings to scrape internal contacts. The policy is beneficial for agencies that have implemented custom policies, providing flexibility for some users to automatically admit "everyone" to a Microsoft Teams meeting.
- _Last modified:_ August 2025
- _Note:_ This policy applies to the Global (Org-wide default) meeting policy, and custom meeting policies if they exist.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SC-15a
- _MITRE ATT&CK TTP Mapping:_
  - [T1078: Valid Accounts](https://attack.mitre.org/techniques/T1078/)
    - [T1078.001: Default Accounts](https://attack.mitre.org/techniques/T1078/001/)

#### MS.TEAMS.1.3v1
Anonymous users and dial-in callers SHOULD NOT be admitted automatically.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.TEAMS.1.3v1; Criticality: SHOULD -->
- _Rationale:_ Automatically allowing admittance to anonymous and dial-in users diminishes control of meeting participation and invites potential data breach. This policy reduces that risk by requiring all anonymous and dial-in users to wait in a lobby until admitted by an authorized meeting participant. If the agency has a use case to admit members of specific trusted organizations and/or B2B guests automatically, custom policies may be created and assigned to authorized meeting organizers.
- _Last modified:_ July 2023
- _Note:_ This policy applies to the Global (Org-wide default) meeting policy. Custom meeting policies MAY be created to allow specific users more flexibility. For example, B2B guest users and trusted partner members may be admitted automatically into meetings organized by authorized users.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SC-15a
- _MITRE ATT&CK TTP Mapping:_
  - None

#### MS.TEAMS.1.4v1
Internal users SHOULD be admitted automatically.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.TEAMS.1.4v1; Criticality: SHOULD -->
- _Rationale:_ Requiring internal users to wait in the lobby for explicit admission can lead to admission fatigue. This policy enables internal users to be automatically admitted to the meeting through global policy.
- _Last modified:_ July 2023
- _Note:_ This policy applies to the Global (Org-wide default) meeting policy. Custom meeting policies MAY be created to allow specific users more flexibility.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-3
- _MITRE ATT&CK TTP Mapping:_
  - None

#### MS.TEAMS.1.5v1
Dial-in users SHOULD NOT be enabled to bypass the lobby.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.TEAMS.1.5v1; Criticality: SHOULD -->
- _Rationale:_ Automatically admitting dial-in users reduces control over who can participate in a meeting and increases potential for data breaches. This policy reduces the risk by requiring all dial-in users to wait in a lobby until they are admitted by an authorized meeting participant.
- _Last modified:_ July 2023
- _Note:_ This policy applies to the Global (Org-wide default) meeting policy, as well as custom meeting policies.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SC-15a
- _MITRE ATT&CK TTP Mapping:_
  - None

#### MS.TEAMS.1.6v1
Meeting recording SHOULD be disabled.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.TEAMS.1.6v1; Criticality: SHOULD -->
- _Rationale:_ Allowing any user to record a Teams meeting or group call may lead to unauthorized disclosure of shared information, including audio, video, and shared screens. By disabling the meeting recording setting in the Global (Org-wide default) meeting policy, an agency limits information exposure.
- _Last modified:_ March 2025
- _Note:_ This policy applies to the Global (Org-wide default) meeting policy. Custom policies MAY be created to allow more flexibility for specific users.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ CM-7
- _MITRE ATT&CK TTP Mapping:_
  - None

#### MS.TEAMS.1.7v2
Record an event SHOULD NOT be set to Always record.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.TEAMS.1.7v2; Criticality: SHOULD -->
- _Rationale:_ Limiting recording permissions to only the organizer minimizes the security risk to the organizer's discretion for these Live Events, reducing data leakage and other security risks. Administrators can also disable recording for all live events.
- _Last modified:_ March 2025
- _Note:_ This policy applies to the Global (Org-wide default) meeting policy. Custom policies MAY be created to allow more flexibility for specific users.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-21a
- _MITRE ATT&CK TTP Mapping:_
  - None



### Resources

- [Manage who can present and request control in Microsoft Teams \| Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoftteams/meeting-who-present-request-control)
- [Meeting policy settings \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoftteams/settings-policies-reference#meetings)

- [Teams cloud meeting recording \| Microsoft
Learn ](https://learn.microsoft.com/en-us/microsoftteams/cloud-recording)

- [Assign policies in Teams – getting started \| Microsoft
Learn](https://learn.microsoft.com/en-us/microsoftteams/policy-assignment-overview)
- [Live Event Recording Policies \| Microsoft
Learn](https://learn.microsoft.com/en-us/microsoftteams/teams-live-events/live-events-recording-policies)

### License Requirements

- N/A

### Implementation

#### MS.TEAMS.1.1v1 Instructions

To help ensure external participants do not have the ability to request
control of the shared desktop or window in the meeting:

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **Meetings** > **Meeting policies**.

3.  Select the **Global (Org-wide default)** policy.

4.  Under the **Content sharing** section, ensure **External participants can give or request control** is set to the **Off** position.

5.  Select **Save** (if applicable).

6.  If custom policies exist on the tenant, repeat these steps for each policy, selecting the appropriate policy in step 3.

#### MS.TEAMS.1.2v2 Instructions

To configure settings for anonymous users so that they cannot start meetings:

1.	Sign in to the **Microsoft Teams admin center**.

2.	Select **Meetings** > **Meeting policies**.

3.	Select the **Global (Org-wide default)** policy.

4.	Under the **Meeting join & lobby** section, ensure the **Anonymous users and dial-in callers can start a meeting** setting remains in the default **Off** position.

5.  Select **Save** (if applicable).

6.	If custom policies exist on the tenant, repeat these steps for each policy, selecting the appropriate policy in step 3.

#### MS.TEAMS.1.3v1 Instructions

To configure settings for anonymous users so that they are not admitted automatically:

1.	Sign in to the **Microsoft Teams admin center**.

2.	Select **Meetings** > **Meeting policies**.

3.	Select the **Global (Org-wide default)** policy.

4.	Under the **Meeting join & lobby** section, ensure **Who can bypass the lobby** is **not** set to **Everyone**. Bypassing the lobby should be set to **People in my org**, though other options may be used if needed or approved.

5.	In the same section, ensure **People dialing in can bypass the lobby** is set to the **Off** position.

6.  Select **Save** (if applicable).

7.	If custom policies exist on the tenant, repeat these steps for each policy, selecting the appropriate policy in step 3.

#### MS.TEAMS.1.4v1 Instructions

To configure settings so that internal users are admitted automatically:

1.	Sign in to the **Microsoft Teams admin center**.

2.	Select **Meetings** > **Meeting policies**.

3.	Select the **Global (Org-wide default)** policy.

4.	Under the **Meeting join & lobby** section, ensure **Who can bypass the lobby** is set to **People in my org**.

5.	In the same section, ensure **People dialing in can bypass the lobby** is set to the **Off** position.

6.  Select **Save** (if applicable).

7.	If custom policies exist on the tenant, repeat these steps for each policy, selecting the appropriate policy in step 3.

#### MS.TEAMS.1.5v1 Instructions

To configure settings for anonymous users so that they are not able to bypass the lobby:

1.	Sign in to the **Microsoft Teams admin center**.

2.	Select **Meetings** > **Meeting policies**.

3.	Select the **Global (Org-wide default)** policy.

4.	Under the **Meeting join & lobby** section, ensure **People dialing in can bypass the lobby** is set to the **Off** position.

5.  Select **Save** (if applicable).

6.	If custom policies exist on the tenant, repeat these steps for each policy, selecting the appropriate policy in step 3.

#### MS.TEAMS.1.6v1 Instructions

To configure the settings that control meeting recordings:

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **Meetings** > **Meeting policies**.

3.  Select the **Global (Org-wide default)** policy.

4.  Under the **Recording & transcription** section, ensure **Meeting recording** is set to the **Off** position.

5.  Select **Save** (if applicable).

6.	If custom policies exist on the tenant, repeat these steps for each policy, selecting the appropriate policy in step 3.

#### MS.TEAMS.1.7v2 Instructions

To configure the settings that control "live events" meeting recordings:

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **Meetings** > **Live events policies**.

3.  Select **Global (Org-wide default)** policy.

4.  Set **Record an event** to either  **Organizer can record** or **Never record**.

5.  Select **Save** (if applicable).

6.	If custom policies exist on the tenant, repeat these steps for each policy, selecting the appropriate policy in step 3.



## 2. External User Access
This section helps reduce security risks related to external and unmanaged user access. In this instance, external users refer to members of a different M365 tenant, and unmanaged users refer to users who are not members of any M365 tenant or organization.

External access allows external users to look up internal users by their
email address to initiate chats and calls entirely within Teams.
Blocking external access prevents external users from using Teams as an
avenue for reconnaissance or phishing. Even with external access
disabled, external users will still be able to join Teams calls,
assuming anonymous join is enabled. Depending on agency need, if both
external access and anonymous join are blocked—neither required
nor recommended by this baseline—external collaborators would only be
able to attend meetings if added as B2B guest users.

External access may be granted on a per-domain basis. This may be
desirable in some cases (e.g., for agency-to-agency collaboration). See
the Chief Information Officer Council's [Interagency Collaboration
Program](https://community.max.gov/display/Egov/Interagency+Collaboration+Program) Office of Management and Budget MA site for a list of .gov domains for sharing.

Similar to external users, blocking contact with unmanaged Teams users prevents these users from looking up internal users by their email address and initiating chats and calls within Teams. These users would still be able to join calls, assuming anonymous join is enabled. Additionally, unmanaged users may be added to Teams chats if the internal user initiates the contact.

### Policies

#### MS.TEAMS.2.1v2
External access for users SHALL only be enabled on a per-domain basis.

[![BOD 25-01 Requirement](https://img.shields.io/badge/BOD_25--01_Requirement-C41230)](https://www.cisa.gov/news-events/directives/bod-25-01-implementation-guidance-implementing-secure-practices-cloud-services)
[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.TEAMS.2.1v2; Criticality: SHALL -->
- _Rationale:_ The default configuration allows members to communicate with all external users with similar access permissions. Unrestricted access can lead to data breaches and other security threats. This policy provides protection against threats posed by unrestricted access by allowing communication with only trusted domains.
- _Last modified:_ August 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-3
- _MITRE ATT&CK TTP Mapping:_
  - [T1199: Trusted Relationship](https://attack.mitre.org/techniques/T1199/)
  - [T1204: User Execution](https://attack.mitre.org/techniques/T1204/)
    - [T1204.001: Malicious Link](https://attack.mitre.org/techniques/T1204/001/)

#### MS.TEAMS.2.2v2
Unmanaged users SHALL NOT be enabled to initiate contact with internal users.

[![BOD 25-01 Requirement](https://img.shields.io/badge/BOD_25--01_Requirement-C41230)](https://www.cisa.gov/news-events/directives/bod-25-01-implementation-guidance-implementing-secure-practices-cloud-services)
[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.TEAMS.2.2v2; Criticality: SHALL -->
- _Rationale:_ Allowing contact from unmanaged users can expose users to email and contact address harvesting. This policy provides protection against this type of harvesting.
- _Last modified:_ August 2026
- _Note:_ This policy's availability may vary by Microsoft 365 environment and tenant, particularly within Government Community Cloud (GCC), GCC High, and Department of Defense (DoD) tenants.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ CM-7, SI-8
- _MITRE ATT&CK TTP Mapping:_
  - [T1204: User Execution](https://attack.mitre.org/techniques/T1204/)
    - [T1204.001: Malicious Link](https://attack.mitre.org/techniques/T1204/001/)

#### MS.TEAMS.2.3v2
Internal users SHOULD NOT be enabled to initiate contact with unmanaged users.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.TEAMS.2.3v2; Criticality: SHOULD -->
- _Rationale:_ Contact with unmanaged users can pose the risk of data leakage and other security threats. This policy provides protection by disabling internal user access to unmanaged users.
- _Last modified:_ August 2026
- _Note:_ This policy's availability may vary by Microsoft 365 environment and tenant, particularly within Government Community Cloud (GCC), GCC High, and Department of Defense (DoD) tenants.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ CM-7, SC-7(10)(a)
- _MITRE ATT&CK TTP Mapping:_
  - [T1204: User Execution](https://attack.mitre.org/techniques/T1204/)
    - [T1204.001: Malicious Link](https://attack.mitre.org/techniques/T1204/001/)

### Resources

- [IT Admins - Manage external meetings and chat with people and organizations using Microsoft identities \| Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoftteams/manage-external-access)

- [Teams settings and policies reference \| Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoftteams/meeting-settings-in-teams#allow-anonymous-users-to-join-meetings)

- [Use guest access and external access to collaborate with people
  outside your organization \| Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoftteams/communicate-with-users-from-other-organizations)

- [Manage chat with external Teams users not managed by an organization
\| Microsoft
Learn](https://learn.microsoft.com/en-us/microsoftteams/manage-external-access#manage-chat-with-external-teams-users-not-managed-by-an-organization)

### License Requirements

- N/A

### Implementation

Steps for the unmanaged users are outlined in [Manage chat with external Teams users not
managed by an
organization](https://learn.microsoft.com/en-us/microsoftteams/manage-external-access#manage-chat-with-external-teams-users-not-managed-by-an-organization).

#### MS.TEAMS.2.1v2 Instructions

To enable external access for only specific domains:

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **External collaboration** > **External access** > **Organization settings** (Tab).

3.  Next to **Teams and Skype for Business users in external organizations**, select **Allow only specific external domains**

4.  Select **Add a domain**. Enter the allowed domain in the text box, press **Add**, and then select **Done** to save your changes.

    **NOTE:** Domains will need to be added in this step in order for users to communicate with them. Ensure only currently allowed domains remain present in the list.

5.  Click **Save** and then **Confirm**.

    **NOTE:** You'll receive a pop-up at this stage stating **Changes will take time to take effect - Changes to External access will have an impact across the organization and can't be rolled back immediately.** This is an expected message.

#### MS.TEAMS.2.2v2 Instructions

To ensure unmanaged users cannot initiate contact with internal users:

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **External collaboration** > **External access** > **Policies** (Tab).

3.  Select **Global (Org-wide Default)**.

4.  On the **Edit policy details** screen, set **People in my org can chat and have meetings with external users who have unmanaged Microsoft accounts** to one of the following:
    1. To completely block contact with unmanaged users, toggle the setting to the **Off** position.
    2. To allow contact with unmanaged users only if the internal user initiates the contact:
        - Toggle the setting to the **On** position.
        - Clear the check next to **People in my org can join external meetings and receive new chats from users who have unmanaged Microsoft accounts.**.

5.  Click **Save** and then **Confirm**.

    **NOTE:** You'll receive a pop-up at this stage stating **Changes will take time to take effect - Changes to Global (Org-wide default) will have an impact across the organization and can't be rolled back immediately.** This is an expected message.

6.	If custom policies exist on the tenant, repeat these steps for each policy, selecting the appropriate policy in step 3.

#### MS.TEAMS.2.3v2 Instructions

To ensure internal users cannot initiate contact with unmanaged users:

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **External collaboration** > **External access** > **Policies** (Tab).

3.  Select **Global (Org-wide Default)**.

4.  To completely block contact with unmanaged users, under **Edit policy details**, set **People in my org can chat and have meetings with external users who have unmanaged Microsoft accounts** to the **Off** position.

5.  Click **Save** and then **Confirm**.

    **NOTE:** You'll receive a pop-up at this stage stating **Changes will take time to take effect - Changes to Global (Org-wide default) will have an impact across the organization and can't be rolled back immediately.** This is an expected message.

6.	If custom policies exist on the tenant, repeat these steps for each policy, selecting the appropriate policy in step 3.



## 4. Teams Email Integration
This section helps reduce potential security risks related to Teams' email integration functionality. Teams provides an optional email integration feature that allows senders to send email to a channel-specific email address, causing the email and its contents to appear in the channel. If this is not appropriately restricted, this functionality can provide a pathway for external or untrusted content to enter Teams channels.

### Policies
#### MS.TEAMS.4.1v1
Teams email integration SHALL be disabled.

[![BOD 25-01 Requirement](https://img.shields.io/badge/BOD_25--01_Requirement-C41230)](https://www.cisa.gov/news-events/directives/bod-25-01-implementation-guidance-implementing-secure-practices-cloud-services)
[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.TEAMS.4.1v1; Criticality: SHALL -->
- _Rationale:_ Microsoft Teams email integration associates a Microsoft, not tenant domain, email address with a Teams channel. Channel emails are addressed using the Microsoft-owned domain <code>&lt;teams.ms&gt;</code>. By disabling Teams email integration, an agency prevents potentially sensitive Teams messages from being sent through external email gateways.
- _Last modified:_ July 2023
- _Note:_ Teams email integration availability may vary by Microsoft 365 environment and tenant, particularly within Government Community Cloud (GCC), GCC High, and Department of Defense (DoD) tenants.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-8, SC-7(10)(a), AC-4
- _MITRE ATT&CK TTP Mapping:_
  - [T1204: User Execution](https://attack.mitre.org/techniques/T1204/)
    - [T1204.001: Malicious Link](https://attack.mitre.org/techniques/T1204/001/)
    - [T1204.002: Malicious File](https://attack.mitre.org/techniques/T1204/002/)

### Resources

- [Email Integration \| Microsoft
Learn](https://learn.microsoft.com/en-us/microsoftteams/settings-policies-reference#email-integration)

### License Requirements

- N/A

### Implementation

#### MS.TEAMS.4.1v1 Instructions

To ensure users cannot send emails and their contents to a channel email address:

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **Teams** > **Teams Settings**.

3.  Under the **Email integration** section, ensure **Users can send emails to a channel email address** is set to the **Off** position.

4. Under the same section, ensure the **Accept channel email from these SMTP domains** field has no domains entered and that it remains empty.

5.  Select **Save** (if applicable).



## 5. App Management

This section helps reduce security risks associated with applications integrated with Microsoft Teams. Apps can introduce additional access to organizational data and resources, increasing risk if they are not appropriately restricted. Teams can integrate with the following classes of apps:

- *Microsoft apps*: Apps authored and published by Microsoft (First party, Official).

- *Third-party apps*: Apps not authored by Microsoft, published to the Teams store (External).

- *Custom apps*: Apps not published to the Teams store, such as internal apps under development, that users sideload into Teams.

### Policies

#### MS.TEAMS.5.1v2
Agencies SHOULD only allow installation of Microsoft apps approved by the agency.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.TEAMS.5.1v2; Criticality: SHOULD -->
- _Rationale:_ Allowing Teams integration with all Microsoft apps can expose the agency to potential vulnerabilities present in those apps. By only allowing specific apps and blocking all others, the agency can better manage app integration and potential exposure points.
- _Last modified:_ August 2026
- _Note:_ This policy applies to the Global (Org-wide default) policy, all custom policies, and the org-wide app settings. Custom policies MAY be created to allow more flexibility for specific users.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ CM-11
- _MITRE ATT&CK TTP Mapping:_
  - [T1195: Supply Chain Compromise](https://attack.mitre.org/techniques/T1195/)

#### MS.TEAMS.5.2v2
Agencies SHOULD only allow installation of third-party apps approved by the agency.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.TEAMS.5.2v2; Criticality: SHOULD -->
- _Rationale:_ Allowing Teams integration with third-party apps can expose the agency to potential vulnerabilities present in an app not managed by the agency. By allowing only specific apps approved by the agency and blocking all others, the agency can limit its exposure to third-party app vulnerabilities.
- _Last modified:_ August 2026
- _Note:_ This policy applies to the Global (Org-wide default) policy, all custom policies if they exist, and the org-wide settings. Custom policies MAY be created to allow more flexibility for specific users. Third-party apps may not be available in the Government Community Cloud (GCC), GCC High, and Department of Defense (DoD) regions.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ CM-11
- _MITRE ATT&CK TTP Mapping:_
  - [T1195: Supply Chain Compromise](https://attack.mitre.org/techniques/T1195/)
  - [T1528: Steal Application Access Token](https://attack.mitre.org/techniques/T1528/)

#### MS.TEAMS.5.3v2
Agencies SHOULD only allow installation of custom apps approved by the agency.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.TEAMS.5.3v2; Criticality: SHOULD -->
- _Rationale:_ Allowing Teams integration with custom apps can expose the agency to potential vulnerabilities present in an app not managed by the agency. By allowing only specific apps approved by the agency and blocking all others, the agency can limit its exposure to custom app vulnerabilities.
- _Last modified:_ August 2026
- _Note:_ This policy applies to the Global (Org-wide default) policy, all custom policies if they exist, and the org-wide settings. Custom policies MAY be created to allow more flexibility for specific users. Custom apps may not be available in the Government Community Cloud (GCC), GCC High, and Department of Defense (DoD) regions.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ CM-11
- _MITRE ATT&CK TTP Mapping:_
  - [T1195: Supply Chain Compromise](https://attack.mitre.org/techniques/T1195/)
  - [T1528: Steal Application Access Token](https://attack.mitre.org/techniques/T1528/)

### Resources

- [Use app permission policies to control user access to apps \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoftteams/teams-app-permission-policies)

- [Upload your app in Microsoft Teams \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoftteams/platform/concepts/deploy-and-publish/apps-upload)

### License Requirements

- N/A

### Implementation

**INTERFACE NOTE:** The Teams admin portal interface has been updated, and the manner in which applications are controlled has changed. The MS.TEAMS.5.x v2 policies now follow the new manner of implementing the policies. Newer Tenants created after 2024 should follow the v2 policy implementation steps, while older tenants should follow the legacy implementation steps, only if the newer settings are not available.

Legacy implementation instructions for this section are now located in Appendix B at the end of this document. If your tenant has the Version 2 settings available, there is no need to perform the legacy implementation instructions. These instructions will remain only until they are fully depreciated.

**ScubaGear will continue to look for and gather the legacy policies when running in any mode.  However, there a limitation in the API when gathering the data for the report. Users must utilize "interactive mode" to allow ScubaGear to gather the data for the newer portal based settings.**

#### MS.TEAMS.5.1v2 Instructions

To ensure users can only install Microsoft apps approved by the agency:

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **Teams apps** > **Manage apps**.

3.  In the upper right-hand corner select **Actions**.

4.  Select **Org-wide app settings**.

5.  Under the **Microsoft apps** section, ensure it is set to the **On** position.

6.  Click **Save** (if applicable).

    **NOTE:** This will make all "Microsoft apps" in the application list available to "Everyone." If custom adjustments are needed, on an app by app basis, follow the remaining instructions below. Additionally, previously configured availability settings for individual apps may persist after changing the global toggle and should be reviewed to ensure they remain appropriate.

##### Optional:

7. Close the **Org-wide app settings** settings screen.

8. Select the individual app.

    **NOTE:** To filter out the application list so it is easier to see the relevant apps, click on the **Filter** icon to the left of the search bar. In this screen set **App type** to the **Microsoft apps**, then click **Apply** to save your choices. You can press **Add more** to consider other criteria, such as **App status** (Blocked, Unblocked). 

9. Press the **Edit availability** button at the top of the app list, while the app is selected.

10. Ensure the correct app is reflecting on the edit screen and then change the value in the **Available to** dropdown box to the appropriate setting for your organization (**Everyone, Specific users or groups, or No one**).

11. Click **Apply** (if applicable).

12. Repeat steps 8 to 11 for each application.

#### MS.TEAMS.5.2v2 Instructions

To ensure users can only install third-party apps approved by the agency:

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **Teams apps** > **Manage apps**.

3.  In the upper right-hand corner select **Actions**.

4.  Select **Org-wide app settings**.

5.  Under the **Third-party apps** section, ensure it is set to the **Off** position.

6.  Click **Save** (if applicable).

    **NOTE:** This will make all "Third-party" apps in the application list available to "No one." If custom adjustments are needed, on an app by app basis, follow the remaining instructions below. Additionally, previously configured availability settings for individual apps may persist after changing the global toggle and should be reviewed to ensure they remain appropriate.

##### Optional:

7. Close the **Org-wide app settings** settings screen.

8. Select the individual app.

    **NOTE:** To filter out the application list so it is easier to see the relevant apps, click on the **Filter** icon to the left of the search bar. In this screen set **App type** to the **Third-party apps**, then click **Apply** to save your choices. You can press **Add more** to consider other criteria, such as **App status** (Blocked, Unblocked).

9. Press the **Edit availability** button at the top of the app list, while the app is selected.

10. Ensure the correct app is reflecting on the edit screen and then change the value in the **Available to** dropdown box to the appropriate setting for your organization (**Everyone, Specific users or groups, or No one**).

11. Click **Apply** (if applicable).

12. Repeat steps 8 to 11 for each application.

#### MS.TEAMS.5.3v2 Instructions

To ensure users can only install custom apps approved by the agency:

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **Teams apps** > **Manage apps**.

3.  In the upper right-hand corner select **Actions**.

4.  Select **Org-wide app settings**.

5.  Under the **Custom apps** section, ensure it is set to the **Off** position.

6.  Click **Save** (if applicable).

    **NOTE:** This will make all "Custom apps" in the application list available to "No one." If custom adjustments are needed, on an app by app basis, follow the remaining instructions below. Additionally, previously configured availability settings for individual apps may persist after changing the global toggle and should be reviewed to ensure they remain appropriate.

##### Optional:

7. Close the **Org-wide app settings** settings screen.

8. Select the individual app.

    **NOTE:** To filter out the application list so it is easier to see the relevant apps, click on the **Filter** icon to the left of the search bar. In this screen set **App type** to the **Custom apps**, then click **Apply** to save your choices. You can press **Add more** to consider other criteria, such as **App status** (Blocked, Unblocked).

9. Press the **Edit availability** button at the top of the app list, while the app is selected.

10. Ensure the correct app is reflecting on the edit screen and then change the value in the **Available to** dropdown box to the appropriate setting for your organization (**Everyone, Specific users or groups, or No one**).

11. Click **Apply** (if applicable).

12. Repeat steps 8 to 11 for each application.



# Appendix A - Custom Meeting Policies (Recordings)

If there is a legitimate business need, custom meeting policies can be defined with _specific_ users assigned to them for narrowly scoped purposes. For example, custom meeting policies can be configured for _specific_ users granting them permission to record meetings. To allow _specific_ users the ability to record meetings:

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **Meetings** > **Meeting policies**.

3.  Create a new policy by selecting the **Add** button. Give this new policy a name and an appropriate description (inclusion of the scoped users is recommended).

4.  Under the **Recording & transcription** section, set **Meeting recording** to the **On** position.

5.  Select **Save** (if applicable).

6.  After selecting **Save**, you're returned to the table displaying all of your tenant's policies. Select the checkbox on the row containing the new policy you just created, then select **Manage users** in the actions area above the table.

7.  On the **Manage users** screen, assign the users to this policy who need the ability to record meetings.

8.  Select **Apply**. Once saved, your custom policy will go into effect following a short delay.


# Appendix B - Legacy Policy Implementation (App Management)

### Legacy Policy Implementation

**NOTE:** Only Implement these settings if the MS.TEAMS.5.x v2 settings in section 5 are not available in your tenant.

#### Legacy MS.TEAMS.5.1v1 Instructions

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **Teams apps** > **Permission policies**.

3.  Select **Global (Org-wide default)**.

4.  Under the **Microsoft apps** section, select **Allow specific apps and block all others** or **Block all apps**.

5.  Click **Allow apps**.

6.  Search and click **Add** to all appropriate Microsoft Apps.

7.  Click **Allow**.

8.  Click **Save**.

9.  If custom policies have been created, repeat these steps for each policy, selecting the appropriate policy in step 3.

#### Legacy MS.TEAMS.5.2v1 Instructions

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **Teams apps** > **Manage apps**.

3.  Select the **Org-wide app settings** button to access pop-up options.
    - Under **Third-party apps**, turn off **Third-party apps**.
    - Click **Save**.

4.  Select **Teams apps** > **Permission policies**.

5.  Select **Global (Org-wide default)**.

6.  Set **Third-party apps** to **Block all apps**, unless specific apps have been approved by the agency, in which case select **Allow specific apps and block all others**.

7.  Click **Save**.

8.  If custom policies have been created, repeat steps 4 to 7 for each policy, selecting the appropriate policy in step 5.

#### Legacy MS.TEAMS.5.3v1 Instructions

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **Teams apps** > **Manage apps**.

3.  Select the **Org-wide app settings** button to access pop-up options.
    - Under **Custom apps**, turn off **Interaction with custom apps**.
    - Click **Save**.

4.  Select **Teams apps** > **Permission policies**.

5.  Select **Global (Org-wide default)**.

6.  Set **Custom apps** to **Block all apps**, unless specific apps have been approved by the agency, in which case select **Allow specific apps and block all others**.

7.  Click **Save**.

8.  If custom policies have been created, repeat steps 4 to 7 for each policy, selecting the appropriate policy in step 5.

**`TLP:CLEAR`**
