**`TLP:CLEAR`**
# CISA M365 Secure Configuration Baseline for Teams

Microsoft 365 (M365) Teams is a cloud-based text and live chat workspace that supports video calls, chat messaging, screen sharing, and file sharing. This secure configuration baseline (SCB) provides specific policies to strengthen Microsoft Teams' security.

The Secure Cloud Business Applications (SCuBA) project, run by the Cybersecurity and Infrastructure Security Agency (CISA), provides guidance and capabilities to secure federal civilian executive branch (FCEB) agencies’ cloud business application environments and protect federal information that is created, accessed, shared, and stored in those environments.

The CISA SCuBA SCBs for M365 help secure federal information assets stored within M365 cloud business application environments through consistent, effective, and manageable security configurations. CISA created baselines tailored to the federal government’s threats and risk tolerance with the knowledge that every organization has different threat models and risk tolerance. While use of these baselines will be mandatory for civilian Federal Government agencies, organizations outside of the Federal Government may also find these baselines to be useful references to help reduce risks.

For non-Federal users, the information in this document is being provided “as is” for INFORMATIONAL PURPOSES ONLY. CISA does not endorse any commercial product or service, including any subjects of analysis. Any reference to specific commercial entities or commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply endorsement, recommendation, or favoritism by CISA. Without limiting the generality of the foregoing, some controls and settings are not available in all products; CISA has no control over vendor changes to products offerings or features.  Accordingly, these SCuBA SCBs for M365 may not be applicable to the products available to you. This document does not address, ensure compliance with, or supersede any law, regulation, or other authority. Entities are responsible for complying with any recordkeeping, privacy, and other laws that may apply to the use of technology. This document is not intended to, and does not, create any right or benefit for anyone against the United States, its departments, agencies, or entities, its officers, employees, or agents, or any other person.

> This document is marked TLP:CLEAR. Recipients may share this information without restriction. Information is subject to standard copyright rules. For more information on the Traffic Light Protocol, see https://www.cisa.gov/tlp.

## License Compliance and Copyright 
Portions of this document are adapted from documents in Microsoft's [M365](https://github.com/MicrosoftDocs/microsoft-365-docs/blob/public/LICENSE) and [Azure](https://github.com/MicrosoftDocs/azure-docs/blob/main/LICENSE) GitHub repositories. The respective documents are subject to copyright and are adapted under the terms of the Creative Commons Attribution 4.0 International license. Source documents are linked throughout this document. The United States government has adapted selections of these documents to develop innovative and scalable configuration standards to strengthen the security of widely used cloud-based software services.

## Assumptions
The **License Requirements** sections of this document assume the organization is using an [M365 E3](https://www.microsoft.com/en-us/microsoft-365/compare-microsoft-365-enterprise-plans) or [G3](https://www.microsoft.com/en-us/microsoft-365/government) license level at a minimum. Therefore, only licenses not included in E3/G3 are listed.

## Key Terminology
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

Access to Teams can be controlled by the user type. In this baseline,
the types of users are defined as follows:

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

# Baseline Policies

## 1. Meeting Policies

This section helps reduce security risks posed by the external participants during meetings. In this instance, the term "external participants" includes external users, B2B guest users, unmanaged users, and anonymous users.

This section helps reduce security risks related to the user permissions for recording Teams meetings and events. These policies and user permissions apply to meetings hosted by a user, as well as during one-on-one calls and group calls started by a user. Agencies should comply with any other applicable policies or legislation in addition to this guidance.

### Policies

#### MS.TEAMS.1.1v1
External meeting participants SHOULD NOT be enabled to request control of shared desktops or windows.

<!--Policy: MS.TEAMS.1.1v1; Criticality: SHOULD -->
- _Rationale:_ An external participant with control of a shared screen could potentially perform unauthorized actions on the shared screen. This policy reduces that risk by removing an external participant's ability to request control. However, if an agency has a legitimate use case to grant this control, it may be done on a case-by-case basis.
- _Last modified:_ July 2023
- _Note:_ This policy applies to the Global (Org-wide default) meeting policy, as well as custom meeting policies.
- _MITRE ATT&CK TTP Mapping:_
  - None

#### MS.TEAMS.1.2v1
Anonymous users SHALL NOT be enabled to start meetings.

<!--Policy: MS.TEAMS.1.2v1; Criticality: SHALL -->
- _Rationale:_ For agencies that implemented custom policies providing more flexibility to some users to automatically admit "everyone" to a meeting - this policy provides protection from anonymous users starting meeting to scrape internal contacts.
- _Last modified:_ July 2023
- _Note:_ This policy applies to the Global (Org-wide default) meeting policy, and custom meeting policies if they exist.
- _MITRE ATT&CK TTP Mapping:_
  - [T1078: Valid Accounts](https://attack.mitre.org/techniques/T1078/)
    - [T1078.001: Default Accounts](https://attack.mitre.org/techniques/T1078/001/)

#### MS.TEAMS.1.3v1
Anonymous users and dial-in callers SHOULD NOT be admitted automatically.

<!--Policy: MS.TEAMS.1.3v1; Criticality: SHOULD -->
- _Rationale:_ Automatically allowing admittance to anonymous and dial-in users diminishes control of meeting participation and invites potential data breach. This policy reduces that risk by requiring all anonymous and dial-in users to wait in a lobby until admitted by an authorized meeting participant. If the agency has a use case to admit members of specific trusted organizations and/or B2B guests automatically, custom policies may be created and assigned to authorized meeting organizers.  
- _Last modified:_ July 2023
- _Note:_ This policy applies to the Global (Org-wide default) meeting policy. Custom meeting policies MAY be created to allow specific users more flexibility. For example, B2B guest users and trusted partner members may be admitted automatically into meetings organized by authorized users.
- _MITRE ATT&CK TTP Mapping:_
  - None

#### MS.TEAMS.1.4v1
Internal users SHOULD be admitted automatically.

<!--Policy: MS.TEAMS.1.4v1; Criticality: SHOULD -->
- _Rationale:_ Requiring internal users to wait in the lobby for explicit admission can lead to admission fatigue. This policy enables internal users to be automatically admitted to the meeting through global policy.  
- _Last modified:_ July 2023
- _Note:_ This policy applies to the Global (Org-wide default) meeting policy. Custom meeting policies MAY be created to allow specific users more flexibility.
- _MITRE ATT&CK TTP Mapping:_
  - None

#### MS.TEAMS.1.5v1
Dial-in users SHOULD NOT be enabled to bypass the lobby.

<!--Policy: MS.TEAMS.1.5v1; Criticality: SHOULD -->
- _Rationale:_ Automatically admitting dial-in users reduces control over who can participate in a meeting and increases potential for data breaches. This policy reduces the risk by requiring all dial-in users to wait in a lobby until they are admitted by an authorized meeting participant.
- _Last modified:_ July 2023
- _Note:_ This policy applies to the Global (Org-wide default) meeting policy, as well as custom meeting policies.  
- _MITRE ATT&CK TTP Mapping:_
  - None

#### MS.TEAMS.1.6v1
Meeting recording SHOULD be disabled.

<!--Policy: MS.TEAMS.1.6v1; Criticality: SHOULD -->
- _Rationale:_ Allowing any user to record a Teams meeting or group call may lead to unauthorized disclosure of shared information, including audio, video, and shared screens. By disabling the meeting recording setting in the Global (Org-wide default) meeting policy, an agency limits information exposure.
- _Last modified:_ July 2023
- _Note:_ This policy applies to the Global (Org-wide default) meeting policy, as well as custom meeting policies. Custom policies MAY be created to allow more flexibility for specific users.
- _MITRE ATT&CK TTP Mapping:_
  - None

#### MS.TEAMS.1.7v1
Record an event SHOULD be set to Organizer can record.

<!--Policy: MS.TEAMS.1.7v1; Criticality: SHOULD -->
- _Rationale:_ The security risk of the default settings for Live Events is Live Events can be recorded by all participants by default. Limiting recording permissions to only the organizer minimizes the security risk to the organizer's discretion for these Live Events.
- _Last modified:_ July 2023
- _Note:_ This policy applies to the Global (Org-wide default) meeting policy, as well as custom meeting policies. Custom policies MAY be created to allow more flexibility for specific users.
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

4.  Under the **Content sharing** section, set **External
    participants can give or request control** to **Off**.

5.  If custom policies were created, repeat these steps for each
    policy, selecting the appropriate policy in step 3.

#### MS.TEAMS.1.2v1 Instructions

To configure settings for anonymous users:

1.	Sign in to the **Microsoft Teams admin center**.

2.	Select **Meetings** > **Meeting policies**.

3.	Select the **Global (Org-wide default)** policy.

4.	Under the **Meeting join & lobby** section, set **Anonymous users and dial-in callers can start a meeting** to **Off**.

5.	If custom policies were created, repeat these steps for each policy, selecting the appropriate policy in step 3.

#### MS.TEAMS.1.3v1 Instructions

1.	Sign in to the **Microsoft Teams admin center**.

2.	Select **Meetings** > **Meeting policies**.

3.	Select the **Global (Org-wide default)** policy.

4.	Under the **Meeting join & lobby** section, ensure **Who can bypass the lobby** is **not** set to **Everyone**. Bypassing the lobby should be set to **People in my org**, though other options may be used if needed.

5.	In the same section, set **People dialing in can bypass the lobby** to **Off**.

#### MS.TEAMS.1.4v1 Instructions

1.	Sign in to the **Microsoft Teams admin center**.

2.	Select **Meetings** > **Meeting policies**.

3.	Select the **Global (Org-wide default)** policy.

4.	Under the **Meeting join & lobby** section, ensure **Who can bypass the lobby** is set to **People in my org**.

5.	In the same section, set **People dialing in can bypass the lobby** to **Off**.

#### MS.TEAMS.1.5v1 Instructions

1.	Sign in to the **Microsoft Teams admin center**.

2.	Select **Meetings** > **Meeting policies**.

3.	Select the **Global (Org-wide default)** policy.

4.	Under the **Meeting join & lobby** section, set **People dialing in can bypass the lobby** to **Off**.

#### MS.TEAMS.1.6v1 Instructions

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **Meetings** > **Meeting policies**.

3.  Select the **Global (Org-wide default)** policy.

4.  Under the **Recording & transcription** section, set **Meeting
    recording** to **Off**.

5.  Select **Save**.


#### MS.TEAMS.1.7v1 Instructions

1.  Sign in to the **Microsoft Teams admin
    center**.

2.  Select **Meetings** > **Live events policies**.

3.  Select **Global (Org-wide default)** policy.

4.  Set **Record an event** to **Organizer can record**.

5.  Click **Save**.

6.  If custom policies were created, repeat these steps for each
    policy, selecting the appropriate policy in step 3.

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

#### MS.TEAMS.2.1v1
External access for users SHALL only be enabled on a per-domain basis.

<!--Policy: MS.TEAMS.2.1v1; Criticality: SHALL -->
- _Rationale:_ The default configuration allows members to communicate with all external users with similar access permissions. This unrestricted access can lead to data breaches and other security threats. This policy provides protection against threats posed by unrestricted access by allowing communication with only trusted domains.  
- _Last modified:_ July 2023
- _MITRE ATT&CK TTP Mapping:_
  - [T1199: Trusted Relationship](https://attack.mitre.org/techniques/T1199/)
  - [T1204: User Execution](https://attack.mitre.org/techniques/T1204/)
    - [T1204.001: Malicious Link](https://attack.mitre.org/techniques/T1204/001/)

#### MS.TEAMS.2.2v1
Unmanaged users SHALL NOT be enabled to initiate contact with internal users.

<!--Policy: MS.TEAMS.2.2v1; Criticality: SHALL -->
- _Rationale:_ Allowing contact from unmanaged users can expose users to email and contact address harvesting. This policy provides protection against this type of harvesting. 
- _Last modified:_ July 2023
- _Note:_ This policy is not applicable to Government Community Cloud (GCC), GCC High, and Department of Defense (DoD) tenants. 
- _MITRE ATT&CK TTP Mapping:_
  - [T1204: User Execution](https://attack.mitre.org/techniques/T1204/)
    - [T1204.001: Malicious Link](https://attack.mitre.org/techniques/T1204/001/)

#### MS.TEAMS.2.3v1
Internal users SHOULD NOT be enabled to initiate contact with unmanaged users.

<!--Policy: MS.TEAMS.2.3v1; Criticality: SHOULD -->
- _Rationale:_ Contact with unmanaged users can pose the risk of data leakage and other security threats. This policy provides protection by disabling internal user access to unmanaged users.
- _Last modified:_ July 2023
- _Note:_ This policy is not applicable to Government Community Cloud (GCC), GCC High, and Department of Defense (DoD) tenants.  
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

#### MS.TEAMS.2.1v1 Instructions

To enable external access for only specific domains:

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **Users** > **External access**.

3.  Under **Choose which external domains your users have access to**,
    select **Allow only specific external domains**.

4.  Click **Allow domains** to add allowed external domains. All domains
    not added in this step will be blocked.

5.  Click **Save**.


#### MS.TEAMS.2.2v1 Instructions

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **Users > External access**.

3. Under **Teams accounts not managed by an organization**, toggle **People in my organization can communicate with Teams users whose accounts aren't managed by an organization** to one of the following:
    1. To completely block contact with unmanaged users, toggle the setting to **Off**.
    2. To allow contact with unmanaged users only if the internal user initiates the contact:
        - Toggle the setting to **On**.
        - Clear the check next to **External users with Teams accounts not managed by an organization can contact users in my organization**.

#### MS.TEAMS.2.3v1 Instructions

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **Users > External access**.

3.  To completely block contact with unmanaged users, under **Teams
    accounts not managed by an organization**, set **People in my
    organization can communicate with Teams users whose accounts aren't
    managed by an organization** to **Off**.

## 3. Skype Users

This section helps reduce security risks related to contact with Skype users. Microsoft is officially retiring Skype for Business Online and wants to give customers information and resources to plan and execute a successful upgrade to Teams. Below are the decommissioning dates by product:

- Skype for Business Online: July 31, 2021
- Skype for Business 2015: April 11, 2023
- Skype for Business 2016: Oct. 14, 2025
- Skype for Business 2019: Oct. 14, 2025
- Skype for Business Server 2015: Oct. 14, 2025
- Skype for Business Server 2019: Oct. 14, 2025
- Skype for Business LTSC 2021: Oct. 13, 2026

### Policies

#### MS.TEAMS.3.1v1
Contact with Skype users SHALL be blocked.

<!--Policy: MS.TEAMS.3.1v1; Criticality: SHALL -->
- _Rationale:_ Microsoft is officially retiring all forms of Skype as listed above. Allowing contact with Skype users puts agency users at additional security risk.  By blocking contact with Skype users an agency limits access to security threats utilizing the vulnerabilities of the Skype product.
- _Last modified:_ July 2023
- _Note:_ This policy is not applicable to Government Community Cloud (GCC), GCC High, and Department of Defense (DoD) tenants. 
- _MITRE ATT&CK TTP Mapping:_
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)

### Resources

- [Configure external meetings and chat with Skype for Business Server \| Microsoft
Learn](https://learn.microsoft.com/en-us/microsoftteams/external-meetings-skype-for-business-server-hybrid)

- [Skype for Business Online to Be Retired in 2021 \| Microsoft Teams
Blog](https://techcommunity.microsoft.com/t5/microsoft-teams-blog/skype-for-business-online-to-be-retired-in-2021/ba-p/777833)

### License Requirements

- N/A

### Implementation

#### MS.TEAMS.3.1v1 Instructions

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **Users > External access**.

3.  Under **Skype** users, set **Allow users in my organization to
    communicate with Skype users** to **Off**.

4.  Click **Save**.

## 4. Teams Email Integration
This section helps reduce security risks related to Teams email integration. Teams provides an optional feature allowing channels to have an email address and receive email.

### Policies
#### MS.TEAMS.4.1v1
Teams email integration SHALL be disabled.

<!--Policy: MS.TEAMS.4.1v1; Criticality: SHALL -->
- _Rationale:_ Microsoft Teams email integration associates a Microsoft, not tenant domain, email address with a Teams channel. Channel emails are addressed using the Microsoft-owned domain <code>&lt;teams.ms&gt;</code>. By disabling Teams email integration, an agency prevents potentially sensitive Teams messages from being sent through external email gateways.  
- _Last modified:_ July 2023
- _Note:_ Teams email integration is not available in GCC, GCC High, or DoD regions.
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

1.  Sign in to the **Microsoft Teams admin
    center**.

2.  Select **Teams** > **Teams Settings**.

3.  Under the **Email integration** section, set **Users can send
    emails to a channel email address** to **Off**.

## 5. App Management
This section helps reduce security risks related to app integration with Microsoft Teams. Teams can integrate with the following classes of apps:

- *Microsoft apps*: apps published by Microsoft.

- *Third-party apps*: apps not authored by Microsoft, published to the
Teams store.

- *Custom apps*: apps not published to the Teams store, such as apps under
development, that users sideload into Teams.

### Policies

#### MS.TEAMS.5.1v1
Agencies SHOULD only allow installation of Microsoft apps approved by the agency.

<!--Policy: MS.TEAMS.5.1v1; Criticality: SHOULD -->
- _Rationale:_ Allowing Teams integration with all Microsoft apps can expose the agency to potential vulnerabilities present in those apps. By only allowing specific apps and blocking all others, the agency will better manage its app integration and potential exposure points.
- _Last modified:_ July 2023
- _Note:_ This policy applies to the Global (Org-wide default) policy, all custom policies, and the org-wide app settings. Custom policies MAY be created to allow more flexibility for specific users.
- _MITRE ATT&CK TTP Mapping:_
  - [T1195: Supply Chain Compromise](https://attack.mitre.org/techniques/T1195/)

#### MS.TEAMS.5.2v1
Agencies SHOULD only allow installation of third-party apps approved by the agency.

<!--Policy: MS.TEAMS.5.2v1; Criticality: SHOULD -->
- _Rationale:_ Allowing Teams integration with third-party apps can expose the agency to potential vulnerabilities present in an app not managed by the agency. By allowing only specific apps approved by the agency and blocking all others, the agency can limit its exposure to third-party app vulnerabilities.
- _Last modified:_ July 2023
- _Note:_ This policy applies to the Global (Org-wide default) policy, all custom policies if they exist, and the org-wide settings. Custom policies MAY be created to allow more flexibility for specific users. Third-party apps are not available in GCC, GCC High, or DoD regions.
- _MITRE ATT&CK TTP Mapping:_
  - [T1195: Supply Chain Compromise](https://attack.mitre.org/techniques/T1195/)
  - [T1528: Steal Application Access Token](https://attack.mitre.org/techniques/T1528/)

#### MS.TEAMS.5.3v1
Agencies SHOULD only allow installation of custom apps approved by the agency.

<!--Policy: MS.TEAMS.5.3v1; Criticality: SHOULD -->
- _Rationale:_ Allowing custom apps integration can expose the agency to potential vulnerabilities present in an app not managed by the agency. By allowing only specific apps approved by the agency and blocking all others, the agency can limit its exposure to custom app vulnerabilities.
- _Last modified:_ July 2023
- _Note:_ This policy applies to the Global (Org-wide default) policy, all custom policies if they exist, and the org-wide settings. Custom policies MAY be created to allow more flexibility for specific users. Custom apps are not available in GCC, GCC High, or DoD regions.
- _MITRE ATT&CK TTP Mapping:_
  - [T1195: Supply Chain Compromise](https://attack.mitre.org/techniques/T1195/)
  - [T1528: Steal Application Access Token](https://attack.mitre.org/techniques/T1528/)

### Resources

- [Use app permission policies to control user access to apps \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoftteams/teams-app-permission-policies)

- [Upload your app in Microsoft Teams \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoftteams/platform/concepts/deploy-and-publish/apps-upload)

### License Requirements

- N/A

### Implementation

#### MS.TEAMS.5.1v1 Instructions

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **Teams apps** > **Permission policies**.

3.  Select **Global (Org-wide default)**.

4.  Under **Microsoft apps**, select **Allow specific apps and block all others** or **Block all apps**.

5.  Click **Allow apps**.

6.  Search and Click **Add** to all appropriate Microsoft Apps.

7.  Click **Allow**.

8.  Click **Save**.

9.  If custom policies have been created, repeat these steps for each
    policy, selecting the appropriate policy in step 3.

#### MS.TEAMS.5.2v1 Instructions

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **Teams apps** > **Manage apps**.

3.  Select **Org-wide app settings** button to access pop-up options.
    - Under **Third-party apps** turn off **Third-party apps**.
    - Click **Save**.

4.  Select **Teams apps** > **Permission policies**.

5.  Select **Global (Org-wide default)**.

6.  Set **Third-party apps** to **Block all apps**, unless specific apps
    have been approved by the agency, in which case select **Allow
    specific apps and block all others**.

7.  Click **Save**.

8.   If custom policies have been created, repeat steps 4 to 7 for each
    policy, selecting the appropriate policy in step 5.

#### MS.TEAMS.5.3v1 Instructions

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **Teams apps** > **Manage apps**.

3.  Select **Org-wide app settings** button to access pop-up options.
    - Under **Custom apps** turn off **Interaction with custom apps**.
    - Click **Save**.

4.  Select **Teams apps** > **Permission policies**.

5.  Select **Global (Org-wide default)**.

6.  Set **Custom apps** to **Block all apps**, unless specific apps have
    been approved by the agency, in which case select **Allow specific apps and block all others**.

7.  Click **Save**.

8.  If custom policies have been created, repeat steps 4 to 7 for each
    policy, selecting the appropriate policy in step 5.

## 6. Data Loss Prevention

Data loss prevention (DLP) helps prevent both accidental leakage of
sensitive information as well as intentional exfiltration of data. DLP
forms an integral part of securing Microsoft Teams. There are
several commercial DLP solutions available documenting support for
M365. Microsoft itself offers DLP services, controlled within the Microsoft Purview
compliance portal. Agencies may select any service that fits their needs and meets
the requirements outlined in this baseline setting. The DLP solution selected by an agency
should offer services comparable to those offered by Microsoft.

Though using Microsoft's DLP solution is not strictly
required, guidance for configuring Microsoft's DLP solution can be found in following section of the CISA M365 Secure Configuration Baseline for Defender for Office 365.

- [Data Loss Prevention \| CISA M365 Secure Configuration Baseline for Defender for Office 365](./defender.md#4-data-loss-prevention)

### Policies

#### MS.TEAMS.6.1v1
A DLP solution SHALL be enabled. The selected DLP solution SHOULD offer services comparable to the native DLP solution offered by Microsoft.

<!--Policy: MS.TEAMS.6.1v1; Criticality: SHALL -->
- _Rationale:_ Teams users may inadvertently disclose sensitive information to unauthorized individuals. Data loss prevention policies provide a way for agencies to detect and prevent unauthorized disclosures.
- _Last modified:_ July 2023
- _MITRE ATT&CK TTP Mapping:_
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)

#### MS.TEAMS.6.2v1
The DLP solution SHALL protect personally identifiable information (PII)
and sensitive information, as defined by the agency. At a minimum, sharing of credit card numbers, taxpayer identification numbers (TINs),
and Social Security numbers (SSNs) via email SHALL be restricted.

<!--Policy: MS.TEAMS.6.2v1; Criticality: SHALL -->
- _Rationale:_ Teams users may inadvertently share sensitive information with others who should not have access to it. Data loss prevention policies provide a way for agencies to detect and prevent unauthorized sharing of sensitive information. 
- _Last modified:_ July 2023
- _MITRE ATT&CK TTP Mapping:_
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)

### Resources

- [Plan for data loss prevention (DLP) \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-365/compliance/dlp-overview-plan-for-dlp?view=o365-worldwide)

- [Personally identifiable information (PII) \|
  NIST](https://csrc.nist.gov/glossary/term/personally_identifiable_information#:~:text=NISTIR%208259,2%20under%20PII%20from%20EGovAct)

- [Sensitive information \|
  NIST](https://csrc.nist.gov/glossary/term/sensitive_information)

### License Requirements

- DLP for Teams within Microsoft Purview requires an E5 or G5 license. See [Microsoft Purview Data Loss Prevention: Data Loss Prevention for Teams \| Microsoft Learn](https://learn.microsoft.com/en-us/office365/servicedescriptions/microsoft-365-service-descriptions/microsoft-365-tenantlevel-services-licensing-guidance/microsoft-365-security-compliance-licensing-guidance#microsoft-purview-data-loss-prevention-data-loss-prevention-dlp-for-teams)
  for more information. However, this requirement can also be met through a third-party solution. If a third-party solution is used, then a E5 or G5 license is not required for the respective policies.

### Implementation

#### MS.TEAMS.6.1v1 Instructions

Any product meeting the requirements outlined in this baseline policy may be used. If the agency uses Microsoft Defender, see the following implementation steps for [DLP](./defender.md#implementation-3) for additional guidance.

#### MS.TEAMS.6.2v1 Instructions

Any product meeting the requirements outlined in this baseline policy may be used. If the agency uses Microsoft Defender, see the following implementation steps for [DLP](./defender.md#implementation-3) for additional guidance.

## 7. Malware Scanning

Malware scanning protects M365 Teams assets from malicious software. Several commercial anti-malware solutions detect and prevent computer viruses, malware, and other malicious software from being introduced into M365 Teams. Agencies may select any product that meets the requirements outlined in this baseline policy group. If the agency is using Microsoft Defender to implement malware scanning, see the following policies of the CISA M365 Secure Configuration Baseline for Defender for Office 365 for additional guidance.

- [MS.DEFENDER.3.1v1 \| CISA M365 Secure Configuration Baseline for Defender for Office 365](./defender.md#msdefender31v1)
  - Safe attachments SHOULD be enabled for SharePoint, OneDrive, and Microsoft Teams.

### Policies

#### MS.TEAMS.7.1v1
Attachments included with Teams messages SHOULD be scanned for malware.

<!--Policy: MS.TEAMS.7.1v1; Criticality: SHOULD -->
- _Rationale:_ Teams can be used as a mechanism for delivering malware. In many cases, malware can be detected through scanning, reducing the risk for end users.
- _Last modified:_ July 2023
- _MITRE ATT&CK TTP Mapping:_
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)
    - [T1566.001: Spearphishing Attachment](https://attack.mitre.org/techniques/T1566/001/)

#### MS.TEAMS.7.2v1
Users SHOULD be prevented from opening or downloading files detected as malware.

<!--Policy: MS.TEAMS.7.2v1; Criticality: SHOULD -->
- _Rationale:_ Teams can be used as a mechanism for delivering malware. In many cases, malware can be detected through scanning, reducing the risk for end users.
- _Last modified:_ July 2023
- _MITRE ATT&CK TTP Mapping:_
  - [T1204: User Execution](https://attack.mitre.org/techniques/T1204/)
    - [T1204.002: Malicious File](https://attack.mitre.org/techniques/T1204/002/)


### Resources

- [Safe Attachments in Microsoft Defender for Office 365 \| Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/safe-attachments-about?view=o365-worldwide#safe-attachments-policy-settings)

- [Turn on Safe Attachments for SharePoint, OneDrive, and Microsoft
  Teams \| Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/safe-attachments-for-spo-odfb-teams-configure?view=o365-worldwide)

### License Requirements

- If using Microsoft Defender, require Defender for Office 365 Plan 1 or 2. These are included with
  E5 and G5 and are available as add-ons for E3 and G3.

### Implementation

#### MS.TEAMS.7.1v1 Instructions

Any product meeting the requirements outlined in this baseline policy may be used. If the agency uses Microsoft Defender, see the following implementation steps for [Safe Attachments](./defender.md#implementation-2) for additional guidance.

#### MS.TEAMS.7.2v1 Instructions

Any product meeting the requirements outlined in this baseline policy may be used. If the agency uses Microsoft Defender, see the following implementation steps for [Safe Attachments](./defender.md#implementation-2) for additional guidance.

## 8. Link Protection

Several technologies exist for protecting users from malicious links
included in emails. For example, Microsoft Defender accomplishes this by
prepending

`https://*.safelinks.protection.outlook.com/?url=`

to any URLs included in emails. By prepending the safe links URL,
Microsoft can proxy the initial URL through their scanning service.
Their proxy can perform the following actions:

- Compare the URL with a block list.

- Compare the URL with a list of know malicious sites.

- If the URL points to a downloadable file, apply real-time file
  scanning.

If all checks pass, the user is redirected to the original URL.

Microsoft Defender includes link-scanning capabilities. Using Microsoft Defender is not strictly required for this purpose; any product fulfilling the requirements outlined in this baseline policy group may be used.
If the agency uses Microsoft Defender to meet this baseline policy group, see the following policy of the CISA M365 Secure Configuration Baseline for Defender for Office 365 for additional guidance.

- [MS.DEFENDER.1.3v1 \| CISA M365 Secure Configuration Baseline for Defender for Office 365](./defender.md#msdefender13v1).
  - All users SHALL be added to Defender for Office 365 Protection in either the standard or strict preset security policy.

### Policies

#### MS.TEAMS.8.1v1
URL comparison with a blocklist SHOULD be enabled.

<!--Policy: MS.TEAMS.8.1v1; Criticality: SHOULD -->
- _Rationale:_ Users may be directed to malicious websites via links in Teams. Blocking access to known malicious URLs can help prevent users from accessing known malicious websites.
- _Last modified:_ July 2023
- _MITRE ATT&CK TTP Mapping:_
  - [T1204: User Execution](https://attack.mitre.org/techniques/T1204/)
    - [T1204.001: Malicious Link](https://attack.mitre.org/techniques/T1204/001/)
    - [T1204.002: Malicious File](https://attack.mitre.org/techniques/T1204/002/)
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)
    - [T1566.001: Spearphishing Attachment](https://attack.mitre.org/techniques/T1566/001/)
  - [T1189: Drive-by Compromise](https://attack.mitre.org/techniques/T1189/)

#### MS.TEAMS.8.2v1
User click tracking SHOULD be enabled.

<!--Policy: MS.TEAMS.8.2v1; Criticality: SHOULD -->
- _Rationale:_ Users may click on malicious links in Teams, leading to compromise or authorized data disclosure. Enabling user click tracking lets agencies know if a malicious link may have been visited after the fact to help tailor a response to a potential incident.
- _Last modified:_ July 2023
- _MITRE ATT&CK TTP Mapping:_
  - [T1204: User Execution](https://attack.mitre.org/techniques/T1204/)
    - [T1204.001: Malicious Link](https://attack.mitre.org/techniques/T1204/001/)
    - [T1204.002: Malicious File](https://attack.mitre.org/techniques/T1204/002/)
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)
    - [T1566.001: Spearphishing Attachment](https://attack.mitre.org/techniques/T1566/001/)
  - [T1189: Drive-by Compromise](https://attack.mitre.org/techniques/T1189/)

### Resources

- [Recommended settings for EOP and Microsoft Defender for Office 365
  security \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365)

- [Set up Safe Links policies in Microsoft Defender for Office 365 \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/safe-links-policies-configure?view=o365-worldwide)
  
### License Requirements

- N/A

### Implementation

#### MS.TEAMS.8.1v1 Instructions

Any product meeting the requirements outlined in this baseline policy may be used. If the agency uses Microsoft Defender, see the following implementation steps for [standard or strict preset security policy](defender.md#msdefender13v1-instructions) for additional guidance.

#### MS.TEAMS.8.2v1 Instructions

Any product meeting the requirements outlined in this baseline policy may be used. If the agency uses Microsoft Defender, see the following implementation steps for [standard or strict preset security policy](defender.md#msdefender13v1-instructions) for additional guidance.


[^1]: Note that B2B guest users and all anonymous users except for
    external users appear in Teams calls as _John Doe (Guest)_. To avoid
    potential confusion, true guest users are always referred to as B2B guest users in this document.

# Appendix A - Custom Meeting Policies

If there is a legitimate business need, custom meeting policies can be defined with _specific_ users assigned to them. For example, custom meeting policies can be configured with _specific_ users having
permission to record meetings. To allow specific users the ability to
record meetings:

1.  Sign in to the **Microsoft Teams admin center**.

2.  Select **Meetings** > **Meeting policies**.

3.  Create a new policy by selecting **Add**. Give this new policy a
    name and appropriate description.

4.  Under the **Recording & transcription** section, set **Cloud
    recording** to **On**.

5.  Select **Save**.

6.  After selecting **Save**, a table displays the set of policies.
    Select the row containing the new policy, then select **Manage
    users**.

7.  Assign the users who need the ability to record to this policy.

8.  Select **Apply**.

**`TLP:CLEAR`**
