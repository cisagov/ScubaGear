**`TLP:CLEAR`**
# Removed CISA M365 Secure Configuration Baseline Policies

This document tracks policies that have been removed from the Secure Configuration Baselines. The removal of a policy from the baselines does not necessarily imply that whatever configuration recommended by the removed policy should not be used. In each case, review the "Removal rationale" section of the removed policy in this document for more details.

The Secure Cloud Business Applications (SCuBA) project, run by the Cybersecurity and Infrastructure Security Agency (CISA), provides guidance and capabilities to secure federal civilian executive branch (FCEB) agencies’ cloud business application environments and protect federal information that is created, accessed, shared, and stored in those environments.

The CISA SCuBA SCBs for M365 help secure federal information assets stored within M365 cloud business application environments through consistent, effective, and manageable security configurations. CISA created baselines tailored to the federal government’s threats and risk tolerance with the knowledge that every organization has different threat models and risk tolerance. While use of these baselines will be mandatory for civilian Federal Government agencies, organizations outside of the Federal Government may also find these baselines to be useful references to help reduce risks.

For non-federal users, the information in this document is being provided “as is” for INFORMATIONAL PURPOSES ONLY. CISA does not endorse any commercial product or service, including any subjects of analysis. Any reference to specific commercial entities or commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply endorsement, recommendation, or favoritism by CISA. Without limiting the generality of the foregoing, some controls and settings are not available in all products; CISA has no control over vendor changes to products offerings or features.  Accordingly, these SCuBA SCBs for M365 may not be applicable to the products available to you. This document does not address, ensure compliance with, or supersede any law, regulation, or other authority. Entities are responsible for complying with any recordkeeping, privacy, and other laws that may apply to the use of technology. This document is not intended to, and does not, create any right or benefit for anyone against the United States, its departments, agencies, or entities, its officers, employees, or agents, or any other person.

> This document is marked TLP:CLEAR. Recipients may share this information without restriction. Information is subject to standard copyright rules. For more information on the Traffic Light Protocol, see https://www.cisa.gov/tlp.

## Key Terminology
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

Additional terminology in this document specific to their respective SCBs are to be interpreted as described in the following:

1. [Microsoft Entra ID](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/aad.md#key-terminology)
2. [Defender](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/defender.md#key-terminology)
3. [Exchange Online](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/exo.md#key-terminology)
4. [Power BI](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/powerbi.md#key-terminology)
5. [Power Platform](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/powerplatform.md#key-terminology)
6. [Security Suite](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/securitysuite.md#key-terminology)
7. [SharePoint & OneDrive](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/sharepoint.md#key-terminology)
8. [Teams](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/teams.md#key-terminology)

## Removed Policies
<details>
<summary> Microsoft Entra ID </summary> 

#### MS.AAD.5.4v1
Group owners SHALL NOT be allowed to consent to applications.
- _Removal date:_ March 2025
- _Removal rationale:_ Microsoft announced via MC712143 that it will no longer be possible for group owners to consent to applications. All references including the policy, implementation steps, and section have been removed as the setting is no longer present.
</details>

<details>
<summary> Defender </summary> 

#### MS.DEFENDER.1.1v1
The standard and strict preset security policies SHALL be enabled.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy group 1 (MS.SECURITYSUITE.1.1v1 - MS.SECURITYSUITE.1.4v1).

#### MS.DEFENDER.1.2v1
All users SHALL be added to Exchange Online Protection (EOP) in either the standard or strict preset security policy.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy group 1 (MS.SECURITYSUITE.1.1v1 - MS.SECURITYSUITE.1.4v1).

#### MS.DEFENDER.1.3v1
All users SHALL be added to Defender for Office 365 protection in either the standard or strict preset security policy.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy group 1 (MS.SECURITYSUITE.1.1v1 - MS.SECURITYSUITE.1.4v1).

#### MS.DEFENDER.1.4v1
Sensitive accounts SHALL be added to Exchange Online Protection in the strict preset security policy.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy group 1 (MS.SECURITYSUITE.1.1v1 - MS.SECURITYSUITE.1.4v1).

#### MS.DEFENDER.1.5v1
Sensitive accounts SHALL be added to Defender for Office 365 protection in the strict preset security policy.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy group 1 (MS.SECURITYSUITE.1.1v1 - MS.SECURITYSUITE.1.4v1).

#### MS.DEFENDER.2.1v1
User impersonation protection SHOULD be enabled for sensitive accounts in both the standard and strict preset policies.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.2.1v1.

#### MS.DEFENDER.2.2v1
Domain impersonation protection SHOULD be enabled for domains owned by the agency in both the standard and strict preset policies.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.2.2v1.

#### MS.DEFENDER.2.3v1
Domain impersonation protection SHOULD be added for important partners in both the standard and strict preset policies.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.2.3v1.

#### MS.DEFENDER.3.1v1
Safe attachments SHOULD be enabled for SharePoint, OneDrive, and Microsoft Teams.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.1.4v1.

#### MS.DEFENDER.4.1v2
A custom policy SHALL be configured to protect PII and sensitive information, as defined by the agency, blocking at a minimum: credit card numbers, U.S. Individual Taxpayer Identification Numbers (ITIN), and U.S. Social Security numbers (SSN).
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.3.1v1.

#### MS.DEFENDER.4.2v1
The custom policy SHOULD be applied to Exchange, OneDrive, SharePoint, Teams chat, and Devices.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.3.2v1.

#### MS.DEFENDER.4.3v1
The action for the custom policy SHOULD be set to block sharing sensitive information with everyone.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.3.3v1.

#### MS.DEFENDER.4.4v1
Notifications to inform users and help educate them on the proper use of sensitive information SHOULD be enabled in the custom policy.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.3.4v1.

#### MS.DEFENDER.4.5v1
A list of apps that are restricted from accessing files protected by DLP policy SHOULD be defined.
- _Removal date:_ April 2026
- _Removal rationale:_ Removed the policy because it could not be automatically evaluated by the ScubaGear tool. It defined a best practice requiring agencies to create a list of applications restricted from accessing files protected by the DLP policy, but this is open to interpretation and varies by agency, making it difficult for the SCuBA team to enforce.

#### MS.DEFENDER.4.6v1
The custom policy SHOULD include an action to block access to sensitive information by restricted apps and unwanted Bluetooth applications.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.3.5v1.

#### MS.DEFENDER.5.1v1
At a minimum, the alerts required by the CISA M365 Secure Configuration Baseline for Exchange Online SHALL be enabled.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.4.1v1.

#### MS.DEFENDER.5.2v1
The alerts SHOULD be sent to a monitored address or incorporated into a Security Information and Event Management (SIEM).
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.4.2v1.

#### MS.DEFENDER.6.1v1
Unified Audit logging SHALL be enabled.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.5.1v1.

#### MS.DEFENDER.6.2v1
Microsoft Purview Audit (Premium) logging SHALL be enabled for ALL users.
- _Removal date:_ March 2025
- _Removal rationale:_ MS.DEFENDER.6.2v1 was originally included in order to enable auditing of additional user actions not captured under Purview Audit (Standard). In October 2023, Microsoft announced changes to its Purview Audit service that included making audit events in Purview Audit (Premium) available to Purview Audit (Standard) subscribers. Now that the rollout of changes is completed, Purview (Standard) includes the necessary auditing that is addressed by MS.DEFENDER.6.1v1.

#### MS.DEFENDER.6.3v1
Audit logs SHALL be maintained for at least the minimum duration dictated by OMB M-21-31.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.5.2v1.

</details>

<details>
<summary> Exchange Online </summary> 

#### MS.EXO.2.1v1
A list of approved IP addresses for sending mail SHALL be maintained.
- _Removal date:_ May 2024
- _Removal rationale:_ MS.EXO.2.1v1 is not a security configuration that can be audited and acts as a step in implementation of policy MS.EXO.2.2. Having the list of approved IPs will be added as a part of implementation of policy MS.EXO.2.2 and removed as a policy in the baseline.

#### MS.EXO.8.1v2
A DLP solution SHALL be used.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.3.1v1.

#### MS.EXO.8.2v2
The DLP solution SHALL protect personally identifiable information (PII) and sensitive information, as defined by the agency.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.3.1v1.

#### MS.EXO.8.3v1
The selected DLP solution SHOULD offer services comparable to the native DLP solution offered by Microsoft.
- _Removal date:_ April 2026
- _Removal rationale:_ Removed "offer services comparable solution offered by Microsoft" policies in Security Suite Baseline consolidation efforts. 

#### MS.EXO.8.4v1
At a minimum, the DLP solution SHALL restrict sharing credit card numbers, U.S. Individual Taxpayer Identification Numbers (ITIN), and U.S. Social Security numbers (SSN) via email.- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.3.1v1.

#### MS.EXO.9.1v1
Emails SHALL be filtered by attachment file types.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.1.1v1.

#### MS.EXO.9.2v1
The attachment filter SHOULD attempt to determine the true file type and assess the file extension.
- _Removal date:_ April 2026
- _Removal rationale:_ Removed the policy because it could not be configured via Microsoft Defender and assessed by ScubaGear.

#### MS.EXO.9.3v1
Disallowed file types SHALL be determined and enforced.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.1.1v1.

#### MS.EXO.9.4v1
If a third-party filtering solution is used, it SHOULD offer services comparable to Microsoft Defender's Common Attachment Filter.
- _Removal date:_ April 2026
- _Removal rationale:_ Removed "offer services comparable solution offered by Microsoft" policies in Secuirty Suite Baseline consolidation efforts. 

#### MS.EXO.9.5v1
At a minimum, click-to-run files SHOULD be blocked (e.g., .exe, .cmd, and .vbe).
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.1.1v1.

#### MS.EXO.10.1v1
Emails SHALL be scanned for malware.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.1.3v1.

#### MS.EXO.10.2v1
Emails identified as containing malware SHALL be quarantined or dropped.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.1.3v1.

#### MS.EXO.10.3v1
Email scanning SHALL be capable of reviewing emails after delivery.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.1.2v1.

#### MS.EXO.11.1v1
Impersonation protection checks SHOULD be used.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.2.1v1.

#### MS.EXO.11.2v1
User warnings, comparable to the user safety tips included with EOP, SHOULD be displayed.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.2.4v1.

#### MS.EXO.11.3v1
The phishing protection solution SHOULD include an AI-based phishing detection tool comparable to EOP Mailbox Intelligence.
- _Removal date:_ April 2026
- _Removal rationale:_ Removed "offer services comparable solution offered by Microsoft" policies in Secuirty Suite Baseline consolidation efforts.

#### MS.EXO.12.1v1
IP allow lists SHOULD NOT be created.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.8.1v1

#### MS.EXO.12.2v1
Safe lists SHOULD NOT be enabled.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.8.2v1

#### MS.EXO.14.1v2
A spam filter SHALL be enabled.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.6.1v1.

#### MS.EXO.14.2v1
Spam and high confidence spam SHALL be moved to either the junk email folder or the quarantine folder.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.6.1v1.

#### MS.EXO.14.3v2
Allowed domains SHALL NOT be added to inbound anti-spam protection policies.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.6.2v1.

#### MS.EXO.15.1v1
URL comparison with a block-list SHOULD be enabled.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.7.1v1.

#### MS.EXO.15.2v1
Direct download links SHOULD be scanned for malware.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.7.1v1.

#### MS.EXO.15.3v1
User click tracking SHOULD be enabled.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.7.3v1.

#### MS.EXO.16.1v1
At a minimum, the following alerts SHALL be enabled:

  a. **Suspicious email sending patterns detected.**

  b. **Suspicious Connector Activity.**

  c. **Suspicious Email Forwarding Activity.**

  d. **Messages have been delayed.**

  e. **Tenant restricted from sending unprovisioned email.**

  f. **Tenant restricted from sending email.**

  g. **A potentially malicious URL click was detected.**
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.4.1v1.

#### MS.EXO.16.2v1
Unified Audit logging SHALL be enabled.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.4.2v1.

#### MS.EXO.17.1v1
URL comparison with a block-list SHOULD be enabled.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.5.1v1.

#### MS.EXO.17.2v1
Microsoft Purview Audit (Premium) logging SHALL be enabled for ALL users.
- _Removal date:_ March 2025
- _Removal rationale:_ MS.EXO.17.2v1 was originally included in order to enable auditing of additional user actions not captured under Purview Audit (Standard). In October 2023, Microsoft announced changes to its Purview Audit service that included making audit events in Purview Audit (Premium) available to Purview Audit (Standard) subscribers. Now that the rollout of changes has been completed, Purview (Standard) includes the necessary auditing which is addressed by MS.EXO.17.2v1

#### MS.EXO.17.3v1
Audit logs SHALL be maintained for at least the minimum duration dictated by OMB M-21-31 (Appendix C).
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.5.2v1.

</details>

<details>
<summary> Power BI </summary> 

N/A

</details>


<details>
<summary> Power Platform </summary> 

N/A

</details>

<details>
<summary> Security Suite </summary> 

N/A

</details>

<details>
<summary> SharePoint Online & OneDrive </summary> 

#### MS.SHAREPOINT.1.4v1
Guest access SHALL be limited to the email the invitation was sent to.
- _Removal date:_ February 2025
- _Removal rationale:_ The option to limit guest access to the email the invitation was sent to found in policy MS.SHAREPOINT.1.4v1 has been deprecated by Microsoft. All references, including the policy and its implementation steps, have been removed since the setting is no longer present.

#### MS.SHAREPOINT.4.1v1
Users SHALL be prevented from running custom scripts on personal sites (aka OneDrive).
- _Removal date:_ July 2024
- _Removal rationale:_ The option to enable and disable custom scripting on personal sites (aka OneDrive) found in policy MS.SHAREPOINT.4.1v1 has been deprecated by Microsoft. All references including the policy and its implementation steps have been removed as the setting is no longer present.  Furthermore, it is no longer possible to allow custom scripts on personal sites.

#### MS.SHAREPOINT.4.2v1
Users SHALL be prevented from running custom scripts on self-service created sites.
- _Removal date:_ November 2024
- _Removal rationale:_ Microsoft has noted that after November 2024 it will no longer be possible to prevent SharePoint in resetting custom script settings to its original value (disabled) for all sites. All references including the policy, implementation steps, and section, by direction of CISA and Microsoft, have been removed as the setting will be automatically reverted back to **Blocked** within 24 hours.

</details>


<details>
<summary> Teams </summary> 

#### MS.TEAMS.3.1v1

Contact with Skype users SHALL be blocked.
- _Removal date:_ August 2025
- _Removal rationale:_ The option to restrict contact with Skype users found in policy MS.TEAMS.3.1v1 has been deprecated by Microsoft. All references, including the policy and its implementation steps, have been removed since the setting is no longer present.

#### MS.EXO.6.1v1
A DLP solution SHALL be enabled and SHOULD offer services comparable to the native DLP solution offered by Microsoft.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.3.2v1.

#### MS.EXO.6.2v1
The DLP solution SHALL protect personally identifiable information (PII) and sensitive information, as defined by the agency. At a minimum, sharing credit card numbers, taxpayer identification numbers (TINs), and Social Security numbers (SSNs) via email SHALL be restricted.- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.3.1v1.

#### MS.EXO.7.1v1
Attachments included with Teams messages SHOULD be scanned for malware.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.1.4v1.

#### MS.EXO.7.2v1
Users SHOULD be prevented from opening or downloading files detected as malware.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.1.4v1.

#### MS.EXO.8.1v1
Attachments included with Teams messages SHOULD be scanned for malware.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.7.1v1.

#### MS.EXO.8.2v1
Users SHOULD be prevented from opening or downloading files detected as malware.
- _Removal date:_ April 2026
- _Removal rationale:_ Reworked into the new security suite baseline policy MS.SECURITYSUITE.7.3v1.

</details>

**`TLP:CLEAR`**
