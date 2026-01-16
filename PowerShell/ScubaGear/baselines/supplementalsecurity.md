**`TLP:CLEAR`**

# CISA M365 Secure Configuration Baseline Supplemental Security

Several essential security functions for M365 services require a dedicated security
tool, e.g., for spam and phishing protections. M365 provides these security functions
natively via Defender for Office 365. Notably, Defender for Office 365 capabilities
require Defender for Office 365 Plan 1 or 2. These are included with E5 and G5
and are available as add-ons for E3 and G3. However, third-party solutions that
offer comparable security functions can be used in lieu of Defender.

The Supplemental Security baseline enumerates a set of required security
functions agencies should configure, be it through Defender or a third-party tool
of their choice. Should an agency elect to use Defender as their tool of choice,
agencies should follow the implementation guidance included with this baseline.
However, regardless of whether or not Defender is used, the policies in this baseline
are applicable to all M365 users.

The Secure Cloud Business Applications (SCuBA) project, run by the Cybersecurity and Infrastructure Security Agency (CISA), provides guidance and capabilities to secure federal civilian executive branch (FCEB) agencies’ cloud business application environments and protect federal information that is created, accessed, shared, and stored in those environments.

The CISA SCuBA SCBs for M365 help secure federal information assets stored within M365 cloud business application environments through consistent, effective, and manageable security configurations. CISA created baselines tailored to the federal government’s threats and risk tolerance with the knowledge that every organization has different threat models and risk tolerance. While use of these baselines will be mandatory for civilian Federal Government agencies, organizations outside of the Federal Government may also find these baselines to be useful references to help reduce risks.

For non-Federal users, the information in this document is being provided "as is" for INFORMATIONAL PURPOSES ONLY. CISA does not endorse any commercial product or service, including any subjects of analysis. Any reference to specific commercial entities or commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply endorsement, recommendation, or favoritism by CISA. Without limiting the generality of the foregoing, some controls and settings are not available in all products; CISA has no control over vendor changes to products offerings or features.  Accordingly, these SCuBA SCBs for M365 may not be applicable to the products available to you. This document does not address, ensure compliance with, or supersede any law, regulation, or other authority. Entities are responsible for complying with any recordkeeping, privacy, and other laws that may apply to the use of technology. This document is not intended to, and does not, create any right or benefit for anyone against the United States, its departments, agencies, or entities, its officers, employees, or agents, or any other person.



> This document is marked TLP:CLEAR. Recipients may share this information without restriction. Information is subject to standard copyright rules. For more information on the Traffic Light Protocol, see https://www.cisa.gov/tlp.

## License Compliance and Copyright
Portions of this document are adapted from documents in Microsoft's [M365](https://github.com/MicrosoftDocs/microsoft-365-docs/blob/public/LICENSE) and [Azure](https://github.com/MicrosoftDocs/azure-docs/blob/main/LICENSE) GitHub repositories. The respective documents are subject to copyright and are adapted under the terms of the Creative Commons Attribution 4.0 International license. Sources are linked throughout this document. The United States government has adapted selections of these documents to develop innovative and scalable configuration standards to strengthen the security of widely used cloud-based software services.

## Assumptions
The agency has identified a set of user accounts that are considered sensitive accounts. See [Key Terminology](#key-terminology) for a detailed description of sensitive accounts.

The **License Requirements** sections of this document assume the organization is using an [M365 E3](https://www.microsoft.com/en-us/microsoft-365/compare-microsoft-365-enterprise-plans) or [G3](https://www.microsoft.com/en-us/microsoft-365/government) license level at a minimum. Therefore, only licenses not included in E3/G3 are listed.

## Key Terminology
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

The following are key terms and descriptions used in this document.

**Sensitive Accounts**: This term denotes a set of user accounts that have either
access to sensitive and high-value information or are likely to be seen as trusted
authority figures by other users. Certain accounts—like those belonging to CEOs,
CFOs, CISOs, and IT administrators—have access to highly sensitive data and critical
systems, making them prime targets for cyberattacks. These accounts, referred to
as priority accounts, require enhanced security measures to minimize the risk of
compromise.

**Threat Policies**: Much of Microsoft Defender for Office 365's configuration
is managed through threat policies. Users, groups, and domains can be added to
or excluded from threat security polices. Users added to a policy receive the
protections configured for that policy.

While users can create custom threat polices, Microsoft Defender defines three
[preset security policies](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/preset-security-policies?view=o365-worldwide):
built-in protection, standard, and strict. These preset policies are informed by
Microsoft's observations, and are designed to strike the balance between usability
and security. They allow administrators to enable the full feature set of Defender
by adding users to the policies rather than manually configuring each setting.
One simple method of meeting most requirements of this baseline is to add users
to the standard or strict preset policies, though some organizations may require
the flexibility afforded by custom policies.

Note that a user can be added to multiple policies. In that case, the policies
are applied in order of precedence, as desribed by
[Order of precedence for preset security policies and other threat policies](https://learn.microsoft.com/en-us/defender-office-365/preset-security-policies#order-of-precedence-for-preset-security-policies-and-other-threat-policies).


**BOD 25-01 Requirement**: This indicator means that the policy is required under CISA BOD 25-01.

**Automated Check**: This indicator means that the policy can be automatically checked via ScubaGear. See the [Quick Start Guide](../../../README.md#quick-start-guide) for help getting started.

**Requires Configuration**: This indicator means that ScubaGear requires configuration via config file in order to check the policy.

**Manual**: This indicator means that the policy requires manual verification of configuration settings.

## Adding Users to the Preset Security Policies
As many controls in this baseline can be satisfied by adding users to the standard
or strict security policies, we describe this process once here, rather than
duplicating it in each applicable control.

To add users to the standard policy:
1. Sign in to **Microsoft 365 Defender**.
2. In the left-hand menu, go to **Email & Collaboration** > **Policies & Rules**.
3. Select **Threat Policies**.
4. From the **Templated policies** section, select **Preset Security Policies**.
5. Under **Standard protection**, ensure the toggle is enabled such that it reads "Standard protection is on."
6. Under **Standard protection is on**, select **Manage protection settings**.
7. On the **Apply Exchange Online Protection** page, select **All recipients**.
8. (Optional) Under **Exclude these recipients**, add **Users** and **Groups**
   to be exempted from the preset policies.
9. Select **Next**, then on the **Apply Defender for Office 365 protection** page, select **All recipients**.
10. (Optional) Under **Exclude these recipients**, add **Users** and **Groups**
   to be exempted from the preset policies.
11. Select **Next** on each page until the **Review and confirm your changes** page.
12. On the **Review and confirm your changes** page, select **Confirm**.

To add users to the strict policy:
1. Sign in to **Microsoft 365 Defender**.
2. In the left-hand menu, go to **Email & Collaboration** > **Policies & Rules**.
3. Select **Threat Policies**.
4. From the **Templated policies** section, select **Preset Security Policies**.
5. Under **Strict protection**, ensure the toggle is enabled such that it reads "Strict protection is on."
6. Under **Strict protection is on**, select **Manage protection settings**.
7. On the **Apply Exchange Online Protection** page, select **All recipients**.
8. (Optional) Under **Exclude these recipients**, add **Users** and **Groups**
   to be exempted from the preset policies.
9. Select **Next**, then on the **Apply Defender for Office 365 protection** page, select **All recipients**.
10. (Optional) Under **Exclude these recipients**, add **Users** and **Groups**
   to be exempted from the preset policies.
11. Select **Next** on each page until the **Review and confirm your changes** page.
12. On the **Review and confirm your changes** page, select **Confirm**.

See [Recommended email and collaboration threat policy settings for cloud organizations](https://learn.microsoft.com/en-us/defender-office-365/recommended-settings-for-eop-and-office365) to understand the
differences between the two preset policies.

# Baseline Policies

## 1. Malware Protection

Emails and Teams messages may include attachments that contain malware. Therefore,
messages should be scanned for malware to prevent infections. Once malware has
been identified, the scanner should drop or quarantine the associated messages.
Because malware detections may be updated, it is also important that messages
that were already delivered to users are also scanned and removed.

The Safe Attachments feature included with Defender will scan messages for
attachments with malicious content. All messages with attachments not already
flagged by anti-malware protections in EOP are downloaded to a Microsoft virtual
environment for further analysis. Safe Attachments then uses machine learning and
other analysis techniques to detect malicious intent. While Safe Attachments for
Exchange Online is automatically configured in the preset policies, separate
action is needed to enable it for other products.

### Policies

#### MS.SECURITY.1.1v1
Emails with click-to-run file attachments SHALL be blocked, including at a minimum .exe, .cmd, and .vbe files.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)
[![Configurable](https://img.shields.io/badge/Configurable-005288)](#)
<!-- todo link to proper config doc -->

<!--Policy: MS.SECURITY.1.1v2; Criticality: SHALL -->
- _Rationale:_ Malicious attachments often take the form of click-to-run files.
Sharing high risk file types, when necessary, is better left to a means other
than email; the dangers of allowing them to be sent over email outweigh
any potential benefits. Filtering email attachments based on file types can
prevent spread of malware distributed via click-to-run email attachments.
- _Last modified:_ February 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-3
- _MITRE ATT&CK TTP Mapping:_
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)
    - [T1566.001: Spearphishing Attachment](https://attack.mitre.org/techniques/T1566/001/)

#### MS.SECURITY.1.2v1
Email scanning SHALL be capable of reviewing emails after delivery.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)
[![Configurable](https://img.shields.io/badge/Configurable-005288)](#)
<!-- todo link to proper config doc -->

<!--Policy: MS.SECURITY.1.2v1; Criticality: SHALL -->
- _Rationale:_ As known malware signatures are updated, it is possible for an email to be retroactively identified as containing malware after delivery. By scanning emails, the number of malware-infected in users' mailboxes can be reduced.
- _Last modified:_ February 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-3
- _MITRE ATT&CK TTP Mapping:_
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)
    - [T1566.001: Spearphishing Attachment](https://attack.mitre.org/techniques/T1566/001/)

#### MS.SECURITY.1.3v1
Emails identified as containing malware SHALL be quarantined or dropped.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)
[![Configurable](https://img.shields.io/badge/Configurable-005288)](#)
<!-- todo link to proper config doc -->

<!--Policy: MS.SECURITY.1.3v1; Criticality: SHALL -->
- _Rationale:_ Email can be used as a mechanism for delivering malware.
Preventing emails with known malware from reaching user mailboxes helps ensure
users cannot interact with those emails.
- _Last modified:_ February 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-3
- _MITRE ATT&CK TTP Mapping:_
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)
    - [T1566.001: Spearphishing Attachment](https://attack.mitre.org/techniques/T1566/001/)
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)
    - [T1566.001: Spearphishing Attachment](https://attack.mitre.org/techniques/T1566/001/)

#### MS.SECURITY.1.4v1
SharePoint, OneDrive, and Teams message attachments SHOULD be scanned for malware.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.SECURITY.1.4v1; Criticality: SHOULD -->
- _Rationale:_ Files shared through Teams or hosted on SharePoint/OneDrive can be used as a mechanism for delivering malware. In many cases, malware can be detected through scanning, reducing the risk for end users.
- _Last modified:_ February 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-3a
- _MITRE ATT&CK TTP Mapping:_
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)
    - [T1566.001: Spearphishing Attachment](https://attack.mitre.org/techniques/T1566/001/)

### Resources

- [Anti-malware protection for cloud mailboxes \| Microsoft Learn](https://learn.microsoft.com/en-us/defender-office-365/anti-malware-protection-about)
- [Set up Safe Attachments policies in Microsoft Defender for Office 365 \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/safe-attachments-policies-configure?view=o365-worldwide)

### License Requirements

Safe attachments require Defender for Office 365 Plan 1 or 2. These are included with
  E5 and G5 and are available as add-ons for E3 and G3.

### Implementation

#### MS.SECURITY.1.1v1 Instructions

Both the standard and strict preset policies meet this baseline policy requirement,
so no further actions are needed for users added to those policies. See
[Adding Users to the Preset Security Policies](#adding-users-to-the-preset-security-policies)
for instructions on adding users to these policies.

For users not added to the standard or strict preset policies:
1.  Sign in to **Microsoft 365 Defender**.
2.  Under **Email & collaboration**, select **Policies & rules**.
3.  Select **Threat policies**.
4.  Under **Policies**, select **Anti-malware**.
5.  If modifying an existing policy:
    1. Click the name of the policy from the policy list to open the policy summary.
    2. Click **Edit user and domains**. _Note:_ the **Default (default)** policy applies to all users, so skip this step if modifying the default policy.
        - Under **Domains**, enter all the tenant domains. All users under these domains will be added to the policy.
        - (Optional) Under **Exclude these users, groups, and domains**, add **Users** and **Groups**
          to be exempted from this policy.
        - Click **Save**.
    3. Click **Edit protection settings**
    4. Check **Enable the common attachments filter**.
    5. Click **Customize file types** and ensure that at a minimum .exe, .cmd, and .vba are selected.
    5. Click **Save**.
6.  If creating a new policy:
    1. Click **Create**.
    2. After naming the policy, click **Next**.
    3. Under **Domains**, enter all the tenant domains. All users under these domains will be added to the policy.
    4. (Optional) Under **Exclude these users, groups, and domains**, add **Users** and **Groups**
       to be exempted from this policy.
    5. Click **Next**.
    4. Check **Enable the common attachments filter**.
    5. Click **Select file types** and ensure that at a minimum .exe, .cmd, and .vba are selected, then click **Done**.
    6. Click **Next** then **Submit**.

#### MS.SECURITY.1.2v1 Instructions
Both the standard and strict preset policies meet this baseline policy requirement,
so no further actions are needed for users added to those policies. See
[Adding Users to the Preset Security Policies](#adding-users-to-the-preset-security-policies)
for instructions on adding users to these policies.

For users not added to the standard or strict preset policies:
1.  Sign in to **Microsoft 365 Defender**.
2.  Under **Email & collaboration**, select **Policies & rules**.
3.  Select **Threat policies**.
4.  Under **Policies**, select **Anti-malware**.
5.  If modifying an existing policy:
    1. Click the name of the policy from the policy list to open the policy summary.
    2. Click **Edit user and domains**. _Note:_ the **Default (default)** policy applies to all users, so skip this step if modifying the default policy.
        - Under **Domains**, enter all the tenant domains. All users under these domains will be added to the policy.
        - (Optional) Under **Exclude these users, groups, and domains**, add **Users** and **Groups**
          to be exempted from this policy.
        - Click **Save**.
    3. Click **Edit protection settings**
    4. Check **Enable zero-hour auto purge for malware (Recommended)**.
    5. Click **Save**.
6.  If creating a new policy:
    1. Click **Create**.
    2. After naming the policy, click **Next**.
    3. Under **Domains**, enter all the tenant domains. All users under these domains will be added to the policy.
    4. (Optional) Under **Exclude these users, groups, and domains**, add **Users** and **Groups**
       to be exempted from this policy.
    5. Click **Next**.
    4. Check **Enable zero-hour auto purge for malware (Recommended)**.
    5. Click **Next** then **Submit**.


#### MS.SECURITY.1.3v1 Instructions

Both the standard and strict preset policies meet this baseline policy requirement,
so no further actions are needed for users added to those policies. See
[Adding Users to the Preset Security Policies](#adding-users-to-the-preset-security-policies)
for instructions on adding users to these policies.

For users not added to the standard or strict preset policies:
1.  Sign in to **Microsoft 365 Defender**.
2.  Under **Email & collaboration**, select **Policies & rules**.
3.  Select **Threat policies**.
4.  Under **Policies**, select **Safe Attachments**.
5.  If modifying an existing policy:
    1. Click the name of the policy from the policy list to open the policy summary.
    2. Click **Edit user and domains**. _Note:_ the **Default (default)** policy applies to all users, so skip this step if modifying the default policy.
        - Under **Domains**, enter all the tenant domains. All users under these domains will be added to the policy.
        - (Optional) Under **Exclude these users, groups, and domains**, add **Users** and **Groups**
          to be exempted from this policy.
        - Click **Save**.
    3. Click **Edit settings**
    4. Under **Safe Attachments unknown malware response**, select **Block** or **Dynamic Delivery**.
    5. Click **Save**.
6.  If creating a new policy:
    1. Click **Create**.
    2. After naming the policy, click **Next**.
    3. Under **Domains**, enter all the tenant domains. All users under these domains will be added to the policy.
    4. (Optional) Under **Exclude these users, groups, and domains**, add **Users** and **Groups**
       to be exempted from this policy.
    5. Click **Next**.
    4. Under **Safe Attachments unknown malware response**, select **Block** or **Dynamic Delivery**.
    5. Click **Next** then **Submit**.

#### MS.SECURITY.1.4v1 Instructions

This baseline policy is _not_ covered by the preset policies, so these steps
need to be taken even if the standard or strict policies are used.

1.  Sign in to **Microsoft 365 Defender**.

2.  Under **Email & collaboration**, select **Policies & rules**.

3.  Select **Threat policies**.

4.  Under **Policies**, select **Safe Attachments**.

5.  Select **Global settings**.

6.  Toggle the **Turn on Defender for Office 365 for SharePoint, OneDrive, and Microsoft Teams**
    slider to **On**.

7. Click **Save**.

## 2. Impersonation Protection
Impersonation protection checks incoming emails to see if the sender
address is similar to the users or domains on an agency-defined list. If
the sender address is significantly similar, as to indicate an
impersonation attempt, the email is quarantined.

### Policies
#### MS.SECURITY.2.1v1
User impersonation protection SHOULD be enabled for sensitive accounts.
[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)
[![Requires Configuration](https://img.shields.io/badge/Requires_Configuration-981D20)](../../../docs/configuration/configuration.md#defender-configuration)

<!--Policy: MS.SECURITY.2.1v1; Criticality: SHOULD -->
<!--ExclusionType: SensitiveUsers-->
- _Rationale:_ User impersonation, especially of users with access to sensitive or high-value information and resources, has the potential to result in serious harm. Impersonation protection mitigates this risk. By configuring impersonation protection in both preset policies, administrators can help protect email recipients from impersonated emails, regardless of whether they are added to the standard or strict policy.
- _Last modified:_ February 2026
- _Note:_ The standard and strict preset security policies must be enabled to
          protect accounts.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-8
- _MITRE ATT&CK TTP Mapping:_
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)
    - [T1566.001: Spearphishing Attachment](https://attack.mitre.org/techniques/T1566/001/)
    - [T1566.002: Spearphishing Link](https://attack.mitre.org/techniques/T1566/002/)
  - [T1656: Impersonation](https://attack.mitre.org/techniques/T1656/)

#### MS.SECURITY.2.2v1
Domain impersonation protection SHOULD be enabled for domains owned by the agency.
[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)
[![Requires Configuration](https://img.shields.io/badge/Requires_Configuration-981D20)](../../../docs/configuration/configuration.md#defender-configuration)

<!--Policy: MS.SECURITY.2.2v1; Criticality: SHOULD -->
<!--ExclusionType: AgencyDomains-->
- _Rationale:_ Configuring domain impersonation protection for all agency domains reduces the risk of a user being deceived by a look-alike domain. By configuring impersonation protection in both preset policies, administrators can help protect email recipients from impersonated emails, regardless of whether they are added to the standard or strict policy.
- _Last modified:_ February 2026
- _Note:_ The standard and strict preset security policies must be enabled to
          protect agency domains.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-8
- _MITRE ATT&CK TTP Mapping:_
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)
    - [T1566.001: Spearphishing Attachment](https://attack.mitre.org/techniques/T1566/001/)
    - [T1566.002: Spearphishing Link](https://attack.mitre.org/techniques/T1566/002/)
  - [T1656: Impersonation](https://attack.mitre.org/techniques/T1656/)

#### MS.SECURITY.2.3v1
Domain impersonation protection SHOULD be added for key suppliers and partners.
[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)
[![Requires Configuration](https://img.shields.io/badge/Requires_Configuration-981D20)](../../../docs/configuration/configuration.md#defender-configuration)

<!--Policy: MS.SECURITY.2.3v1; Criticality: SHOULD -->
<!--ExclusionType: PartnerDomains-->
- _Rationale:_ Configuring domain impersonation protection for domains owned by important partners reduces the risk of a user being deceived by a look-alike domain. By configuring impersonation protection in both preset policies, administrators can help protect email recipients from impersonated emails, regardless of whether they are added to the standard or strict policy.
- _Last modified:_ February 2026
- _Note:_ The standard and strict preset security policies must be enabled to
          protect partner domains.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-8
- _MITRE ATT&CK TTP Mapping:_
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)
    - [T1566.001: Spearphishing Attachment](https://attack.mitre.org/techniques/T1566/001/)
    - [T1566.002: Spearphishing Link](https://attack.mitre.org/techniques/T1566/002/)
  - [T1656: Impersonation](https://attack.mitre.org/techniques/T1656/)

### Resources

- [Impersonation settings in anti-phishing policies in Microsoft Defender for Office 365 \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/anti-phishing-policies-about?view=o365-worldwide#impersonation-settings-in-anti-phishing-policies-in-microsoft-defender-for-office-365)
- [Use the Microsoft 365 Defender portal to assign Standard and Strict preset security policies to users \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/preset-security-policies?view=o365-worldwide#use-the-microsoft-365-defender-portal-to-assign-standard-and-strict-preset-security-policies-to-users)

### License Requirements

- Impersonation protection and advanced phishing thresholds require
  Defender for Office 365 Plan 1 or 2. These are included with E5 and G5
  and are available as add-ons for E3 and G3. As of April 25, 2023,
  anti-phishing for user and domain impersonation and spoof intelligence
  are not yet available in M365 Government Community Cloud (GCC High) and Department of Defense (DoD) environments. See [Platform features \|
  Microsoft
  Learn](https://learn.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/office-365-us-government#platform-features)
  for current offerings.

### Implementation

#### MS.SECURITY.2.1v1 Instructions
<!-- todo update steps
this is no longer about just the standard and strict policies
basically all policies that have users need this

maybe just adding to the default policy will work? That applies to all users -->
1. Sign in to **Microsoft 365 Defender**.
2. In the left-hand menu, go to **Email & Collaboration** > **Policies & Rules**.
3. Select **Threat Policies**.
4. From the **Templated policies** section, select **Preset Security Policies**.
5. Under either **Standard protection** or **Strict protection**, select **Manage
   protection settings**.
6. Select **Next** until you reach the **Impersonation Protection** page, then
   select **Next** once more.
7. On the **Protected custom users** page, add a name and valid email address for each
   sensitive account and click **Add** after each.
8. Select **Next** until you reach the **Trusted senders and domains** page.
9. (Optional) Add specific email addresses here to not flag as impersonation
   when sending messages and prevent false positives. Click **Add** after each.
10. Select **Next** on each page until the **Review and confirm your changes** page.
11. On the **Review and confirm your changes** page, select **Confirm**.

#### MS.SECURITY.2.2v1 Instructions

1. Sign in to **Microsoft 365 Defender**.
2. In the left-hand menu, go to **Email & Collaboration** > **Policies & Rules**.
3. Select **Threat Policies**.
4. From the **Templated policies** section, select **Preset Security Policies**.
5. Under either **Standard protection** or **Strict protection**, select **Manage
   protection settings**.
6. Select **Next** until you reach the **Impersonation Protection** page, then
   select **Next** once more.
7. On the **Protected custom domains** page, add each agency domain
   and click **Add** after each.
8. Select **Next** until you reach the **Trusted senders and domains** page.
9. (Optional) Add specific domains here to not flag as impersonation when
   sending messages and prevent false positives. Click **Add** after each.
10. Select **Next** on each page until the **Review and confirm your changes** page.
11. On the **Review and confirm your changes** page, select **Confirm**.

#### MS.SECURITY.2.3v1 Instructions

1. Sign in to **Microsoft 365 Defender**.
2. In the left-hand menu, go to **Email & Collaboration** > **Policies & Rules**.
3. Select **Threat Policies**.
4. From the **Templated policies** section, select **Preset Security Policies**.
5. Under either **Standard protection** or **Strict protection**, select **Manage
   protection settings**.
6. Select **Next** until you reach the **Impersonation Protection** page, then
   select **Next** once more.
7. On the **Protected custom domains** page, add each partner domain
   and click **Add** after each.
8. Select **Next** on each page until the **Review and confirm your changes** page.
9. On the **Review and confirm your changes** page, select **Confirm**.

## 3. Data Loss Prevention

There are several approaches to securing sensitive information, such
as warning users, encryption, or blocking attempts to share. Agency
policies for sensitive information, such as personally identifiable
information (PII), should dictate how that information is handled and
inform associated data loss prevention (DLP) policies. Defender can detect
sensitive information and associates a default confidence level with
this detection based on the sensitive information type matched.
Confidence levels are used to reduce false positives in detecting access
to sensitive information. Agencies may choose to use the default
confidence levels or adjust the levels in custom DLP policies to fit
their environment and needs.

### Policies
#### MS.SECURITY.3.1v1
A DLP policy SHALL be configured to protect PII and sensitive information, as defined by the agency, blocking at a minimum: credit card numbers, U.S. Individual Taxpayer Identification Numbers (ITIN), and U.S. Social Security numbers (SSN).

[![BOD 25-01 Requirement](https://img.shields.io/badge/BOD_25--01_Requirement-C41230)](https://www.cisa.gov/news-events/directives/bod-25-01-implementation-guidance-implementing-secure-practices-cloud-services)
[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.SECURITY.3.1v2; Criticality: SHALL -->
- _Rationale:_ Users may inadvertently share sensitive information with
               others who should not have access to it. DLP policies
               provide a way for agencies to detect and prevent
               unauthorized disclosures.
- _Last modified:_ February 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SC-7(10)
- _MITRE ATT&CK TTP Mapping:_
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)

#### MS.SECURITY.3.2v1
The DLP policy SHOULD be applied to Exchange, OneDrive, SharePoint, Teams chat, and Devices.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.SECURITY.3.2v1; Criticality: SHOULD -->
- _Rationale:_ Unauthorized disclosures may happen through M365 services
               or endpoint devices. DLP policies should cover all
               affected locations to be effective.
- _Last modified:_ February 2026
- _Note:_ The DLP policy referenced here is the same policy
          configured in [MS.SECURITY.4.1v2](#msdefender41v2).
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SC-7(10)
- _MITRE ATT&CK TTP Mapping:_
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
    - [T1213.002: Sharepoint](https://attack.mitre.org/techniques/T1213/002/)

#### MS.SECURITY.3.3v1
The action for the DLP policy SHOULD be set to block sharing sensitive information with everyone.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.SECURITY.3.3v1; Criticality: SHOULD -->
- _Rationale:_ Access to sensitive information should be prohibited unless
               explicitly allowed. Specific exemptions can be made based
               on agency policies and valid business justifications.
- _Last modified:_ February 2026
- _Note:_ The custom policy referenced here is the same policy
          configured in [MS.SECURITY.4.1v2](#msdefender41v2).
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-3, SC-7(10)
- _MITRE ATT&CK TTP Mapping:_
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)

#### MS.SECURITY.3.4v1
Notifications to inform users and help educate them on the proper use of sensitive information SHOULD be enabled in the DLP policy.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.SECURITY.3.4v1; Criticality: SHOULD -->
- _Rationale:_ Some users may not be aware of agency policies on
               proper use of sensitive information. Enabling
               notifications provides positive feedback to users when
               accessing sensitive information.
- _Last modified:_ February 2026
- _Note:_ The custom policy referenced here is the same policy
          configured in [MS.SECURITY.4.1v2](#msdefender41v2).
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AT-2b
- _MITRE ATT&CK TTP Mapping:_
  - None

#### MS.SECURITY.3.5v1
A list of apps that are restricted from accessing files protected by DLP policy SHOULD be defined.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#msdefender45v1-instructions)

<!--Policy: MS.SECURITY.3.5v1; Criticality: SHOULD -->
- _Rationale:_ Some apps may inappropriately share accessed files or not
               conform to agency policies for access to sensitive
               information. Defining a list of those apps makes it
               possible to use DLP policies to restrict those apps' access
               to sensitive information on endpoints using Defender.
- _Last modified:_ February 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SC-7(10)
- _MITRE ATT&CK TTP Mapping:_
  - [T1565: Data Manipulation](https://attack.mitre.org/techniques/T1565/)
  - [T1485: Data Destruction](https://attack.mitre.org/techniques/T1485/)
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)

#### MS.SECURITY.3.6v1
The custom policy SHOULD include an action to block access to sensitive
information by restricted apps and unwanted Bluetooth applications.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#msdefender46v1-instructions)

<!--Policy: MS.SECURITY.3.6v1; Criticality: SHOULD -->
- _Rationale:_ Some apps may inappropriately share accessed files
               or not conform to agency policies for access to sensitive
               information. Defining a DLP policy with an action to block
               access from restricted apps and unwanted Bluetooth
               applications prevents unauthorized disclosure by those
               programs.
- _Last modified:_ February 2026
- _Note:_
  - The custom policy referenced here is the same policy
    configured in [MS.SECURITY.4.1v2](#msdefender41v2).
  - This action can only be included if at least one device is onboarded
    to the agency tenant. Otherwise, the option to block restricted apps will
    not be available.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-19a
- _MITRE ATT&CK TTP Mapping:_
  - [T1565: Data Manipulation](https://attack.mitre.org/techniques/T1565/)
  - [T1485: Data Destruction](https://attack.mitre.org/techniques/T1485/)
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)
  - [T1486: Data Encrypted for Impact](https://attack.mitre.org/techniques/T1486/)

### Resources

- [Plan for data loss prevention (DLP) \| Microsoft
  Learn](https://learn.microsoft.com/en-us/purview/dlp-overview-plan-for-dlp?view=o365-worldwide)

- [Data loss prevention in Exchange Online \| Microsoft
  Learn](https://learn.microsoft.com/en-us/exchange/security-and-compliance/data-loss-prevention/data-loss-prevention)

- [Personally identifiable information (PII) \|
  NIST](https://csrc.nist.gov/glossary/term/personally_identifiable_information#:~:text=NISTIR%208259,2%20under%20PII%20from%20EGovAct)

- [Sensitive information \|
  NIST](https://csrc.nist.gov/glossary/term/sensitive_information)

- [Get started with Endpoint data loss prevention - Microsoft Purview
  (compliance) \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/endpoint-dlp-getting-started?view=o365-worldwide)

### License Requirements

- DLP for Teams requires an E5 or G5 license. See [Microsoft Purview Data Loss Prevention: Data Loss Prevention for Teams \| Microsoft
  Learn](https://learn.microsoft.com/en-us/office365/servicedescriptions/microsoft-365-service-descriptions/microsoft-365-tenantlevel-services-licensing-guidance/microsoft-365-security-compliance-licensing-guidance#microsoft-purview-data-loss-prevention-data-loss-prevention-dlp-for-teams)
  for more information. However, this requirement can also be met through a third-party solution. If a third-party solution is used, then a E5 or G5 license is not required for the respective policies.


- DLP for Endpoint requires an E5 or G5 license. See [Get started with
  Endpoint data loss prevention - Microsoft Purview (compliance) \|
  Microsoft
  Learn](https://learn.microsoft.com/en-us/purview/endpoint-dlp-getting-started?view=o365-worldwide)
  for more information. However, this requirement can also be met through a third-party solution. If a third-party solution is used, then a E5 or G5 license is not required for the respective policies.


### Implementation

#### MS.SECURITY.3.1v2 Instructions

1. Sign in to the **Microsoft Purview portal**.

2. Under the **Solutions** section on the left-hand menu, select **Data loss
   prevention**.

3. Select **Policies** from the top of the page.

4. Select **Create policy**.

5. From the **Categories** list, select **Custom**.

6. From the **Regulations** list, select **Custom policy** and then click
   **Next**.

7. Edit the name and description of the policy if desired, then click
   **Next**.

8. Under **Assign admin units**,  ensure **Admin units** is set to **Full directory** by default, then click **Next**.

9. Under **Choose where to apply the policy**, set **Status** to **On**
   for at least the Exchange email, OneDrive accounts, SharePoint
   sites, Teams chat and channel messages, and Devices locations, then
   click **Next**.

10. Under **Define policy settings**, select **Create or customize advanced
   DLP rules**, and then click **Next**.

11. Click **Create rule**. Assign the rule an appropriate name and
   description.

12. Click **Add condition**, then **Content contains**.

13. Click **Add**, then **Sensitive info types**.

14. Add information types that protect information sensitive to the agency.
    At a minimum, the agency should protect:

    - Credit card numbers
    - U.S. Individual Taxpayer Identification Numbers (ITIN)
    - U.S. Social Security Numbers (SSN)
    - All agency-defined PII and sensitive information

15. Click **Add**.

16. Under **Actions**, click **Add an action**.

17. Check **Restrict Access or encrypt the content in Microsoft 365
    locations**.

18. Under this action, select **Block Everyone**.

19. Under **User notifications**, turn on **Use notifications to inform your users and help educate them on the proper use of sensitive info**.

20. Under **Microsoft 365 services** if using a GCC environment or under **Microsoft 365 files and Microsoft Fabric items** if using a Commercial environment, a section that appears after user notifications are turned on, check the box next to **Notify users in Office 365 service with a policy tip or email notifications**.

21. Click **Save**, then **Next**.

22. Select **Turn the policy on immediately**, then click **Next**.

23. Click **Submit**.

#### MS.SECURITY.3.2v1 Instructions

See [MS.SECURITY.3.1v2 Instructions](#msdefender31v2-instructions) step 8
   for details on enforcing DLP policy in specific M365 service locations.

#### MS.SECURITY.3.3v1 Instructions

See [MS.SECURITY.3.1v2 Instructions](#msdefender31v2-instructions) steps
   15-17 for details on configuring DLP policy to block sharing sensitive
   information with everyone.

#### MS.SECURITY.3.4v1 Instructions

See [MS.SECURITY.3.1v2 Instructions](#msdefender31v2-instructions) steps
   18-19 for details on configuring DLP policy to notify users when accessing
   sensitive information.

#### MS.SECURITY.3.5v1 Instructions

1. Sign in to the **Microsoft Purview portal**.

2. Go to **Settings**, under **Solution Settings** select **Data loss prevention**.

3. Go to **Endpoint DLP Settings**.

4. Go to **Restricted apps and app groups**.

5. Click **Add or edit Restricted Apps**.

6. Enter an app and executable name to disallow said app from
   accessing protected files, and log the incident.

7. Return and click **Unallowed Bluetooth apps**.

8. Click **Add or edit unallowed Bluetooth apps**.

9. Enter an app and executable name to disallow said app from
   accessing protected files, and log the incident.

#### MS.SECURITY.3.6v1 Instructions

If restricted app and unwanted Bluetooth app restrictions are desired,
associated devices must be onboarded with Defender for Endpoint
before the instructions below can be completed.

1. Sign in to the **Microsoft Purview portal**.

2. Under **Solutions**, select **Data loss prevention**.

3. Select **Policies** from the top of the page.

4. Find the custom DLP policy configured under
   [MS.SECURITY.3.1v2 Instructions](#msdefender41v2-instructions) in the list
   and click the Policy name to select.

5. Select **Edit Policy**.

6. Click **Next** on each page in the policy wizard until you reach the
   Advanced DLP rules page.

7. Select the relevant rule and click the pencil icon to edit it.

8. Under **Actions**, click **Add an action**.

9. Choose **Audit or restrict activities on device**

10. Under **File activities for all apps**, select
    **Apply restrictions to specific activity**.

11. Check the box next to **Copy or move using unallowed Bluetooth app**
    and set its action to **Block**.

12. Under **Restricted app activities**, check the **Access by restricted apps** box
   and set the action drop-down to **Block**.

13. Click **Save** to save the changes.

14. Click **Next** on each page until reaching the
    **Review your policy and create it** page.

15. Review the policy and click **Submit** to complete the policy changes.

## 4. Alerts

Managing and monitoring Exchange mailboxes and user activity requires a means
to define activity of concern and notify administrators.  Alerts can be
generated to help identify suspicious or malicious activity in Exchange Online.
These alerts give administrators better real-time insight into possible
security incidents.

There are several pre-built alert policies available pertaining to
various apps in the M365 suite. These alerts give administrators better
real-time insight into possible security incidents.

### Policies
#### MS.SECURITY.4.1v1
At a minimum, the following alerts SHALL be enabled:

  a. **Suspicious email sending patterns detected.**

  b. **Suspicious Connector Activity.**

  c. **Suspicious Email Forwarding Activity.**

  d. **Messages have been delayed.**

  e. **Tenant restricted from sending unprovisioned email.**

  f. **Tenant restricted from sending email.**

  g. **A potentially malicious URL click was detected.**

[![BOD 25-01 Requirement](https://img.shields.io/badge/BOD_25--01_Requirement-C41230)](https://www.cisa.gov/news-events/directives/bod-25-01-implementation-guidance-implementing-secure-practices-cloud-services)
[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.SECURITY.4.1v1; Criticality: SHALL -->
- _Rationale:_ Potentially malicious or service-impacting events may go undetected without a means of detecting these events. Setting up a mechanism to alert administrators to the list of events linked above draws attention to them to minimize any impact to users and the agency.
- _Last modified:_ February 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-4(5)
- _MITRE ATT&CK TTP Mapping:_
  - [T1562: Impair Defenses](https://attack.mitre.org/techniques/T1562/)
    - [T1562.006: Indicator Blocking](https://attack.mitre.org/techniques/T1562/006/)

#### MS.SECURITY.4.2v1
The alerts SHOULD be sent to a monitored address or incorporated into a Security Information and Event Management (SIEM).

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#msdefender52v1-instructions)

<!--Policy: MS.SECURITY.4.2v1; Criticality: SHOULD -->
- _Rationale:_ Suspicious or malicious events, if not resolved promptly, may have a greater impact to users and the agency. Sending alerts to a monitored email address or SIEM system helps ensure events are acted upon in a timely manner to limit overall impact.
- _Last modified:_ February 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-4(5)
- _MITRE ATT&CK TTP Mapping:_
  - [T1562: Impair Defenses](https://attack.mitre.org/techniques/T1562/)
    - [T1562.006: Indicator Blocking](https://attack.mitre.org/techniques/T1562/006/)

### Resources

- [Alert policies in Microsoft 365 \| Microsoft
  Learn](https://learn.microsoft.com/en-us/purview/alert-policies?view=o365-worldwide)

### License Requirements

- N/A

### Implementation

#### MS.SECURITY.4.1v1 Instructions

1. Sign in to **Microsoft 365 Defender**.

2. Under **Email & collaboration**, select **Policies & rules**.

3. Select **Alert Policy**.

4. Select the checkbox next to each alert to enable as determined by the
   agency and at a minimum the following:

   a. **Suspicious email sending patterns detected.**

   b. **Suspicious connector activity.**

   c. **Suspicious Email Forwarding Activity.**

   d. **Messages have been delayed.**

   e. **Tenant restricted from sending unprovisioned email.**

   f. **Tenant restricted from sending email.**

   g. **A potentially malicious URL click was detected.**

5. Click the pencil icon from the top menu.

6. Select the **Enable selected policies** action from the **Bulk actions**
   menu.

#### MS.SECURITY.4.2v1 Instructions

For each enabled alert, to add one or more email recipients:

1. Sign in to **Microsoft 365 Defender**.

2. Under **Email & collaboration**, select **Policies & rules**.

3. Select **Alert Policy**.

4. Click the alert policy to modify.

5. Click the pencil icon next to **Set your recipients**.

6. Check the **Opt-In for email notifications** box.

7. Add one or more email addresses to the **Email recipients** text box.

8. Click **Next**.

9. On the **Review** page, click **Submit** to save the notification settings.

## 5. Audit Logging

User activity from M365 services is captured in the organization's unified
audit log. These logs are essential for conducting incident response and
threat detection activity.

By default, Microsoft retains the audit logs for 180 days. Activity
by users with E5 licenses is logged for one year.

However, in accordance with Office of Management and Budget (OMB) Memorandum
21-31, _Improving the Federal Government's Investigative and Remediation
Capabilities Related to Cybersecurity Incidents_, M365 audit logs are to be
retained for at least 12 months in active storage and an additional 18 months
in cold storage. This can be accomplished either by offloading the logs out of
the cloud environment or natively through Microsoft by creating an [audit log
retention policy](https://learn.microsoft.com/en-us/purview/audit-log-retention-policies?view=o365-worldwide#create-an-audit-log-retention-policy).

OMB M-21-13 requires Advanced Audit Features be configured in M365.
Advanced Audit, now Microsoft Purview Audit (Premium), adds additional event
types to the Unified Audit Log.

### Policies
#### MS.SECURITY.5.1v1
Unified Audit logging SHALL be enabled.

[![BOD 25-01 Requirement](https://img.shields.io/badge/BOD_25--01_Requirement-C41230)](https://www.cisa.gov/news-events/directives/bod-25-01-implementation-guidance-implementing-secure-practices-cloud-services)
[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.SECURITY.5.1v1; Criticality: SHALL -->
- _Rationale:_ Responding to incidents without detailed information about activities that took place slows response actions. Enabling Unified Audit logging helps ensure agencies have visibility into user actions. Furthermore, enabling the Unified Audit log is required for government agencies by OMB M-21-31.
- _Last modified:_ February 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AU-12
- _MITRE ATT&CK TTP Mapping:_
  - [T1562: Impair Defenses](https://attack.mitre.org/techniques/T1562/)
    - [T1562.008: Disable or Modify Cloud Logs](https://attack.mitre.org/techniques/T1562/008/)

#### MS.SECURITY.5.2v1
Audit logs SHALL be maintained for at least the minimum duration dictated by OMB M-21-31.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#msdefender63v1-instructions)

<!--Policy: MS.SECURITY.5.3v1; Criticality: SHALL -->
- _Rationale:_ Audit logs may no longer be available when needed if they are not retained for a sufficient time. Increased log retention time gives an agency the necessary visibility to investigate incidents that occurred some time ago.
- _Last modified:_ February 2026
- _Note_: Purview Audit (Premium) provides a default audit log retention policy,
          retaining Exchange Online, SharePoint Online, OneDrive for
          Business, and Microsoft Entra ID audit records for one year.
          Additional record types require custom audit retention policies.
          Agencies may also consider alternate storage locations and services
          to meet audit log retention needs.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AU-11
- _MITRE ATT&CK TTP Mapping:_
  - [T1070: Indicator Removal](https://attack.mitre.org/techniques/T1070/)

### Resources

- [OMB M-21-31, Improving the Federal Government's Investigative and Remediation Capabilities
Related to Cybersecurity Incidents \| Office of Management and
  Budget](https://www.whitehouse.gov/wp-content/uploads/2021/08/M-21-31-Improving-the-Federal-Governments-Investigative-and-Remediation-Capabilities-Related-to-Cybersecurity-Incidents.pdf)

- [Turn auditing on or off \| Microsoft
  Learn](https://learn.microsoft.com/en-us/purview/audit-log-enable-disable?view=o365-worldwide)

- [Create an audit log retention policy \| Microsoft
  Learn](https://learn.microsoft.com/en-us/purview/audit-log-retention-policies?view=o365-worldwide#create-an-audit-log-retention-policy)

- [Search the audit log in the compliance center \| Microsoft
  Learn](https://learn.microsoft.com/en-us/purview/audit-log-search?view=o365-worldwide)

- [Audit log activities \| Microsoft
  Learn](https://learn.microsoft.com/en-us/purview/audit-log-activities)

- [Expanding cloud logging to give customers deeper security visibility \|
  Microsoft Security Blog](https://www.microsoft.com/en-us/security/blog/2023/07/19/expanding-cloud-logging-to-give-customers-deeper-security-visibility/)

- [Export, configure, and view audit log records | Microsoft Learn](https://learn.microsoft.com/en-us/purview/audit-log-export-records)

- [Untitled Goose Tool Fact Sheet | CISA.](https://www.cisa.gov/resources-tools/resources/untitled-goose-tool-fact-sheet)

- [Manage audit log retention policies | Microsoft Learn](https://learn.microsoft.com/en-us/purview/audit-log-retention-policies?tabs=microsoft-purview-portal#before-you-create-an-audit-log-retention-policy)

### License Requirements

- Microsoft Purview Audit (Premium) logging capabilities, including the creation of a custom audit
  log retention policy, requires E5/G5 licenses or E3/G3 licenses with
  add-on compliance licenses.

- Additionally, maintaining logs in the M365 environment for longer than
  one year requires an add-on license. For more information, see
  [Manage audit log retention policies | Microsoft Learn](https://learn.microsoft.com/en-us/purview/audit-log-retention-policies?tabs=microsoft-purview-portal#before-you-create-an-audit-log-retention-policy). However, this requirement can also be met by exporting the logs from M365 and storing them with your solution of choice, in which case audit log retention policies are not necessary.

### Implementation

#### MS.SECURITY.5.1v1 Instructions

To enable auditing via the **Microsoft Purview portal**:

1. Sign in to the **Microsoft Purview portal**.

2. Under **Solutions**, select **Audit**.

3. If auditing is not enabled, a banner is displayed to notify the
administrator to start recording user and admin activity.

4. Click the **Start recording user and admin activity**.

#### MS.SECURITY.5.2v1 Instructions
To create one or more custom audit retention policies, if the default retention policy is not sufficient for agency needs, follow [Create an audit log retention policy](https://learn.microsoft.com/en-us/purview/audit-log-retention-policies?view=o365-worldwide#create-an-audit-log-retention-policy) instructions.
Ensure the duration selected in the retention policies is at least one year, in accordance with OMB M-21-31.

As noted in the [License Requirements](https://github.com/cisagov/ScubaGear/baselines/defender.md#license-requirements-1) section above, the creation of a custom audit log retention policy and its retention in the M365 environment requires E5/G5 licenses or E3/G3 licenses with add-on compliance licenses. No additional license is required to view and export logs. To view and export audit logs follow [Export, configure, and view audit log records | Microsoft Learn](https://learn.microsoft.com/en-us/purview/audit-log-export-records) and/or [Untitled Goose Tool Fact Sheet | CISA.](https://www.cisa.gov/resources-tools/resources/untitled-goose-tool-fact-sheet)


## 6. Inbound Anti-Spam Protections

Junk email, or spam, can clutter user mailboxes and hamper communications
across an agency. Implementing a spam filter helps to identify inbound spam and
quarantine or move those messages. Microsoft Defender includes several
capabilities for protecting against inbound spam emails. Using Microsoft
Defender is not strictly required for this purpose; any product that
fulfills the requirements outlined in this baseline policy group may be
used.

### Policies

#### MS.SECURITY.6.1v1
Spam and high confidence spam SHALL be moved to either the junk email folder or the quarantine folder.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#msexo142v1-instructions)

<!--Policy: MS.SECURITY.6.1v1; Criticality: SHALL -->
- _Rationale:_ Spam is a constant threat as junk mail can reduce user productivity, fill up mailboxes unnecessarily, and in some cases include malicious links or attachments.
Moving spam messages to a separate junk or quarantine folder helps users filter out spam while still giving them the ability to review messages, as needed, in case a message is filtered incorrectly.
- _Last modified:_ February 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-8
- _MITRE ATT&CK TTP Mapping:_
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)

#### MS.SECURITY.6.2v1
Allowed domains SHALL NOT be added to inbound anti-spam protection policies.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#msexo143v1-instructions)

<!--Policy: MS.SECURITY.6.2v1; Criticality: SHALL -->
- _Rationale:_ Legitimate emails may be incorrectly filtered
by spam protections. Adding allowed senders is an acceptable method of
combating these false positives. Allowing an entire domain, especially
a common domain like office.com, however, provides for a large number of
potentially unknown users to bypass spam protections.
- _Last modified:_ February 2026
- _Note:_ Allowed senders MAY be added.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-8
- _MITRE ATT&CK TTP Mapping:_
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)

### Resources

- [Configure anti-spam policies in EOP \| Microsoft Learn](https://learn.microsoft.com/en-us/defender-office-365/anti-spam-policies-configure?view=o365-worldwide)

### License Requirements

- N/A

### Implementation

#### MS.SECURITY.6.1v2 Instructions

Any product meeting the requirements outlined in this baseline policy may be
used. If the agency uses Microsoft Defender, see the following
implementation steps for
[enabling preset security policies](./defender.md#msdefender12v1), which
include spam filtering.

#### MS.SECURITY.6.2v1 Instructions

Any product meeting the requirements outlined in this baseline policy may be
used. If the agency uses Microsoft Defender, see the following
implementation steps for
[enabling preset security policies](./defender.md#msdefender12v1), which
include spam filtering that moves high confidence spam to either the junk
 or quarantine folder.

## 7. Link Protection

Several technologies exist for protecting users from malicious links. For example,
Microsoft Defender accomplishes this by
prepending:

`https://*.safelinks.protection.outlook.com/?url=`

to any URLs included in emails. By prepending the safe links URL,
Microsoft can proxy the initial URL through their scanning service.
Their proxy can perform the following actions:

- Compare the URL with a block list.

- Compare the URL with a list of known malicious sites.

- If the URL points to a downloadable file, apply real-time file
  scanning.

If all checks pass, the user is redirected to the original URL.

Microsoft Defender for Office 365 includes link scanning capabilities.
Using Microsoft Defender is not strictly required for this purpose;
any product fulfilling the requirements outlined in this baseline policy group may be used.
If the agency uses Microsoft Defender for Office 365 to meet this baseline policy group,
implementations steps are provided below.

### Policies

#### MS.SECURITY.7.1v1
URL comparison with a block-list SHOULD be enabled for URLs in emails, Teams messages, and Office documents.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#msexo151v1-instructions)

<!--Policy: MS.SECURITY.7.1v1; Criticality: SHOULD -->
- _Rationale:_ Users may be directed to malicious websites via links in email. Blocking access to known, malicious URLs can prevent users from accessing known malicious websites.
- _Last modified:_ February 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-3
- _MITRE ATT&CK TTP Mapping:_
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)
    - [T1566.002: Spearphishing Link](https://attack.mitre.org/techniques/T1566/002/)

#### MS.SECURITY.7.2v1
Direct download links SHOULD be scanned for malware.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#msexo152v1-instructions)

<!--Policy: MS.SECURITY.15.2v1; Criticality: SHOULD -->
- _Rationale:_ URLs in emails may direct users to download and run malware.
Scanning direct download links in real-time for known malware and blocking access can prevent
users from infecting their devices.
- _Last modified:_ February 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-3
- _MITRE ATT&CK TTP Mapping:_
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)
    - [T1566.002: Spearphishing Link](https://attack.mitre.org/techniques/T1566/002/)

#### MS.SECURITY.7.3v1
User click tracking SHOULD be enabled.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#msexo153v1-instructions)

<!--Policy: MS.SECURITY.7.3v1; Criticality: SHOULD -->
- _Rationale:_ Users may click on malicious links in emails, leading to compromise or unauthorized data disclosure. Enabling user click tracking lets agencies know if a malicious link may have been visited after the fact to help tailor a response to a potential incident.
- _Last modified:_ February 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-3, AU-12c
- _MITRE ATT&CK TTP Mapping:_
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)
    - [T1566.002: Spearphishing Link](https://attack.mitre.org/techniques/T1566/002/)

### Resources

- None

### License Requirements

- N/A

### Implementation

#### MS.SECURITY.7.1v1 Instructions

<!-- TODO update these steps -->
Any product meeting the requirements outlined in this baseline policy may be
used. If the agency uses Microsoft Defender for Office 365, see the following
implementation steps for
[enabling preset security policies](./defender.md#msdefender13v1), which
include Safe Links protections to scan URLs in email messages against a list
of known, malicious links.

#### MS.SECURITY.7.2v1 Instructions

Any product meeting the requirements outlined in this baseline policy may be
used. If the agency uses Microsoft Defender for Office 365, see the following
implementation steps for
[enabling preset security policies](./defender.md#msdefender13v1), which
include Safe Links protections to scan links to files for malware.

#### MS.SECURITY.7.3v1 Instructions

Any product meeting the requirements outlined in this baseline policy may be
used. If the agency uses Microsoft Defender for Office 365, see the following
implementation steps for
[enabling preset security policies](./defender.md#msdefender13v1), which
include Safe Links click protections to track user clicks on links in email.

## 8. IP Allow Lists

Microsoft Defender supports creating IP allow lists intended
to prevent blocking emails from *specific* senders. However,
as a result, emails from these senders bypass important security
mechanisms, such as spam filtering, SPF, DKIM, DMARC, and [FROM address
enforcement](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/anti-phishing-from-email-address-validation?view=o365-worldwide#override-from-address-enforcement).

IP block lists block email from listed IP addresses. Although we have no specific guidance on which IP addresses to add, block lists can be used to block mail from known spammers.

IP safe lists are dynamic lists of "known, good senders," which Microsoft sources from various third-party subscriptions. As with senders in the allow list, emails from these senders bypass important security mechanisms.

### Policies

#### MS.SECURITY.8.1v1
IP allow lists SHOULD NOT be created.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.SECURITY.8.1v1; Criticality: SHOULD -->
- _Rationale:_ Messages sent from IP addresses on an allow list bypass important
security mechanisms, including spam filtering and sender authentication checks.  Avoiding use of IP allow lists prevents potential threats from circumventing security mechanisms.
- _Last modified:_ February 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-4
- _MITRE ATT&CK TTP Mapping:_
  - None

#### MS.SECURITY.8.2v1
Safe lists SHOULD NOT be enabled.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.SECURITY.8.2v1; Criticality: SHOULD -->
- _Rationale:_ Messages sent from allowed safe list addresses bypass important
security mechanisms, including spam filtering and sender authentication checks.
Avoiding use of safe lists prevents potential threats from circumventing
security mechanisms. While blocking all malicious senders is not feasible,
blocking specific known, malicious IP addresses may reduce the threat from
specific senders.
- _Last modified:_ February 2026
- _Note:_ A connection filter MAY be implemented to create an IP block list.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-4
- _MITRE ATT&CK TTP Mapping:_
  - None

### Resources

- [Use the IP Allow List \| Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/create-safe-sender-lists-in-office-365?view=o365-worldwide#use-the-ip-allow-list)

- [Configure connection filtering \| Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/connection-filter-policies-configure?view=o365-worldwide)

- [Use the Microsoft 365 Defender portal to modify the default
  connection filter policy \| Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/connection-filter-policies-configure?view=o365-worldwide#use-the-microsoft-365-defender-portal-to-modify-the-default-connection-filter-policy)

### License Requirements

- N/A

### Implementation

#### MS.SECURITY.8.1v1 Instructions
To modify the connection filters, follow the instructions found in [Use
the Microsoft 365 Defender portal to modify the default connection
filter
policy](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/connection-filter-policies-configure?view=o365-worldwide#use-the-microsoft-365-defender-portal-to-modify-the-default-connection-filter-policy).

1. Sign in to **Microsoft 365 Defender portal**.

2. From the left-hand menu, find **Email & collaboration** and select **Policies and Rules**.

3. Select **Threat Policies** from the list of policy names.

4. Under **Policies**, select **Anti-spam**.

5. Select **Connection filter policy (Default)**.

6. Click **Edit connection filter policy**.

7. Ensure no addresses are specified under **Always allow messages from
   the following IP addresses or address range**.

8. Ensure **Turn on safe list** is not selected.

#### MS.SECURITY.8.2v1 Instructions

1. Sign in to **Microsoft 365 Defender portal**.

2. From the left-hand menu, find **Email & collaboration** and select **Policies and Rules**.

3. Select **Threat Policies** from the list of policy names.

4. Under **Policies**, select **Anti-spam**.

5. Select **Connection filter policy (Default)**.

6. Click **Edit connection filter policy**.

7. (Optional) Enter addresses under **Always block messages from the following
   IP addresses or address range** as needed.

8. Ensure **Turn on safe list** is not selected.

**`TLP:CLEAR`**
