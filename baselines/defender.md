# Introduction

Microsoft 365 Defender is a cloud-based enterprise defense suite that
coordinates prevention, detection, investigation, and response. This set
of tools and features are used to detect many types of attacks.

This baseline focuses on the features of Defender for Office 365 and
some settings are in fact configured in the [Microsoft 365
compliance](https://compliance.microsoft.com) admin center. However, for
simplicity, both the Microsoft 365 Defender and Microsoft 365 compliance
admin center items are contained in this baseline.

Generally, use of Microsoft Defender is not required by the baselines of
the core M365 products (Exchange Online, Teams, etc.). However, some of
the controls in the core baselines require the use of a dedicated
security tool, such as Defender. This baseline should not be a
requirement to use Defender, but instead, as guidance for how these
requirements could be met using Defender, should an agency elect to use
Defender as their tool of choice.

In addition to these controls, agencies should consider using a Cloud
Access Security Broker to secure their environments as they adopt zero
trust principles.

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

## 1. Preset Security Profiles

Microsoft Defender defines two [preset security
profiles](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/preset-security-policies?view=o365-worldwide):
standard and strict. While most of the settings in this baseline mirror
the settings of the standard profile, this baseline recommends against
the use of the preset profiles. Instead, it enumerates all relevant
settings, as the preset security profiles are inflexible and take
precedence over all other present policies.

### Policy
#### MS.DEFENDER.1.1v1
Preset security profiles SHOULD NOT be used.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Recommended settings for EOP and Microsoft Defender for Office 365
  security \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365?view=o365-worldwide#eop-anti-spam-policy-settings)

### License Requirements

- N/A

## 2. Data Loss Prevention

There are multiple, different ways to secure sensitive information, such
as warning users, encryption, or blocking attempts to share. The
agency’s data loss prevention (DLP) policy will dictate what agency
information is sensitive and how that information is handled.

### Policies
#### MS.DEFENDER.2.1v1
A custom policy SHALL be configured to protect PII and sensitive information, as defined by the agency. At a minimum, credit card numbers, Taxpayer Identification Numbers (TIN), and Social Security Numbers (SSN) SHALL be blocked.
 - _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.2.2v1
The custom policy SHOULD be applied in Exchange, OneDrive, Teams Chat, and Microsoft Defender.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.2.3v1
The action for the DLP policy SHOULD be set to block sharing sensitive information with everyone when DLP conditions are met.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.2.4v1
Notifications to inform users and help educate them on the proper use of sensitive information SHOULD be enabled.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.2.5v1
A list of apps that are not allowed to access files protected by DLP policy SHOULD be defined.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.2.6v1
A list of browsers that are not allowed to access files protected by DLP policy SHOULD be defined.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Plan for data loss prevention (DLP) \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/compliance/dlp-overview-plan-for-dlp?view=o365-worldwide)

- [Data loss prevention in Exchange Online \| Microsoft
  Docs](https://docs.microsoft.com/en-us/exchange/security-and-compliance/data-loss-prevention/data-loss-prevention)

- [Personally identifiable information (PII) \|
  NIST](https://csrc.nist.gov/glossary/term/personally_identifiable_information#:~:text=NISTIR%208259,2%20under%20PII%20from%20EGovAct)

- [Sensitive information \|
  NIST](https://csrc.nist.gov/glossary/term/sensitive_information)

### License Requirements

- DLP for Teams requires an E5 or G5 license. See [Information
  Protection: Data Loss Prevention for Teams \| Microsoft
  Docs](https://docs.microsoft.com/en-us/office365/servicedescriptions/microsoft-365-service-descriptions/microsoft-365-tenantlevel-services-licensing-guidance/microsoft-365-security-compliance-licensing-guidance#information-protection-data-loss-prevention-for-teams)
  for more information.

- DLP for Endpoint requires an E5 or G5 license. See [Get started with
  Endpoint data loss prevention - Microsoft Purview (compliance) \|
  Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/compliance/endpoint-dlp-getting-started?view=o365-worldwide)
  for more information.

### Implementation

1.  Sign in to the [Microsoft 365
    compliance](https://compliance.microsoft.com) admin center.

2.  Under **Solutions**, select **Data loss prevention**.

3.  Select **Policies** from the top of the page.

4.  Select **Default Office 365 DLP policy**.

5.  Select **Edit policy**.

6.  Edit the name and description of the policy if desired, then click
    **Next**. 

7.  Under **Locations to apply the policy**, set **Status** to **On**
    for all products except Power BI (preview).

8.  Click **Create rule**. Assign the rule an appropriate name and
    description.

9.  Click **Add condition**, then **Content contains**.

10. Click **Add**, then **Sensitive info types**.

11. Create policies that protect information that is sensitive to the
    agency. At a minimum, the agency should protect:

  - Credit card numbers

  - U.S. Individual Taxpayer Identification Numbers (TIN)

  - U.S. Social Security Numbers (SSN)

  - All agency defined PII and sensitive information

12. Click **Add**.

13. Under **Actions**, click **Add an action**.

14. Click **Restrict access of encrypt the content in Microsoft 365
    locations**.

15. Check **Restrict Access or encrypt the content in Microsoft 365
    locations**.

16. Select **Block Everyone**.

17. Turn on **Use notifications to inform your users and help educate
    them on the proper use of sensitive info**.

18. Click **Save**, then **Next**.

19. Select **Turn it on right away**, then click **Next**.

20. Click **Submit**.

21. Go to **Endpoint DLP Settings.**

  1.  Go to **Unallowed Apps.**

  2.  Click **Add** or **Edit Unallowed Apps.**

  3.  Enter an app and executable name to disallow said app from accessing
    protected files and to log the incident.

  4.  Return and click **Unallowed Bluetooth Apps**.

  5.  Enter an app and executable name to disallow said app from accessing
    protected files and to log the incident.

  6.  Return and click **Browser and domain restrictions to sensitive
    data**.

  7.  Under **Unallowed Browsers**, enter and select needed browsers to
    prevent that browser from accessing protected files.

  8.  Switch **Always audit file activity for devices** to **ON**.

## 3. Common Attachments Filter

Filtering emails by attachment file types will flag emails as malware if
the file type has been put in a predefined list of disallowed file
types. The Common Attachments Filter also attempts to look beyond just
the file extension and automatically detect the file type using true
typing.

### Policies
#### MS.DEFENDER.3.1v1
The common attachments filter SHALL be enabled in the default anti-malware policy and in all existing policies.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.3.2v1
Disallowed file types SHALL be determined and set. At a minimum, click-to-run files SHOULD be blocked (e.g., .exe, .cmd, and .vbe).
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Configure anti-malware policies in EOP \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/configure-anti-malware-policies?view=o365-worldwide)

- [Anti-malware policies \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/anti-malware-protection?view=o365-worldwide#anti-malware-policies)

### License Requirements

- Requires Defender for Office 365 Plan 1 or 2. These are included with
  E5 and G5 and are available as add-ons for E3 and G3.

### Implementation

To enable common attachments filter in the default policy:

1.  Sign in to [Microsoft 365
    Defender](https://security.microsoft.com/).

2.  Under **Email & collaboration**, select **Policies & rules**.

3.  Select **Threat policies**.

4.  Under **Policies**, select **Anti-malware**.

5.  Select the **Default (Default)** policy.

6.  Click **Edit protection settings**.

7.  Check **Enable the common attachments filter**.

8.  Click **Customize file types** as needed.

9.  Click **Save**.

To create a new, custom policy, follow the instructions on [Use the
Microsoft 365 Defender portal to create anti-malware
policies](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/configure-anti-malware-policies?view=o365-worldwide#use-the-microsoft-365-defender-portal-to-create-anti-malware-policies).

## 4. Zero-Hour Auto Purge

This setting determines whether emails can be quarantined automatically
after delivery to a user’s mailbox (e.g., in the case of a match with an
updated malware classification rule).

### Policy

#### MS.DEFENDER.4.1v1
Zero-hour Auto Purge (ZAP) for malware SHOULD be enabled in the default anti-malware policy and in all existing custom policies.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Configure anti-malware policies in EOP \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/configure-anti-malware-policies?view=o365-worldwide)

- [Anti-malware policies \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/anti-malware-protection?view=o365-worldwide#anti-malware-policies)

### 2.4.3 License Requirements

- Requires Defender for Office 365 Plan 1 or 2. These are included with
  E5 and G5 and are available as add-ons for E3 and G3.

### Implementation

To enable ZAP:

1.  Sign in to [Microsoft 365
    Defender](https://security.microsoft.com/).

2.  Under **Email & collaboration**, select **Policies & rules**.

3.  Select **Threat policies**.

4.  Under **Policies**, select **Anti-malware**.

5.  Select the **Default (Default)** policy.

6.  Click **Edit protection settings**.

7.  Check **Enable zero-hour auto purge for malware (Recommended)**.

8.  Click **Save**.

## 5. Phishing Protections

There are multiple ways to protect against phishing, including
impersonation protection, mailbox intelligence and safety tips.
Impersonation protection checks incoming emails to see if the sender
address is similar to the users or domains on an agency-defined list. If
the sender address is significantly similar, as to indicate an
impersonation attempt, the email is quarantined. Mailbox intelligence is
an AI-based tool for identifying potential impersonation attempts.

### Policies
#### MS.DEFENDER.5.1v1
User impersonation protection SHOULD be enabled for key agency
  leaders.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.5.2v1
Domain impersonation protection SHOULD be enabled for domains owned by
  the agency.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.5.3v1
Domain impersonation protection SHOULD be added for frequent partners.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.5.4v1
Trusted senders and domains MAY be added in the event of false
  positives.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.5.5v1
Intelligence for impersonation protection SHALL be enabled.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.5.6v1
Message action SHALL be set to quarantine if the message is detected
  as impersonated.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.5.7v1
Mail classified as spoofed SHALL be quarantined.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.5.8v1
All safety tips SHALL be enabled, including:

  - first contact,

  - user impersonation,
  
  - domain impersonation,
  
  - user impersonation unusual characters,

  - ? for unauthenticated senders for spoof, and

  - via tag.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.5.9v1
The above configurations SHALL be set in the default policy and SHOULD
  be set in all existing custom policies.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Configure anti-phishing policies in EOP \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/configure-anti-phishing-policies-eop?view=o365-worldwide)

- [EOP anti-phishing policy settings \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365?view=o365-worldwide#eop-anti-phishing-policy-settings)

### License Requirements

- Impersonation protection and advanced phishing thresholds require
  Defender for Office 365 Plan 1 or 2. These are included with E5 and G5
  and are available as add-ons for E3 and G3. As of September 1, 2022
  anti-phishing for user and domain impersonation and spoof intelligence
  are not yet available in GCC High and DoD (see [Platform features \|
  Microsoft
  Docs](https://docs.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/office-365-us-government#platform-features)
  for current offerings).

### Implementation

1.  Sign in to [Microsoft 365
    Defender](https://security.microsoft.com/).

2.  Under **Email & collaboration**, select **Policies & rules**.

3.  Select **Threat policies**.

4.  Under **Policies**, select **Anti-phishing**.

5.  Select the **Office365 AntiPhish Default (Default)** policy.

6.  Click **Edit protection settings**.

7.  Check **Enable users to protect**.

8.  Click **Manage sender(s)**, then add users that merit impersonation
    protection.

9.  Check **Enable domains to protect**.

10. Check **Include domains I own**.

11. Check **Include custom domains**.

12. Click **Manage custom domains(s)** to add the domains of frequent
    partners.

13. Check **Enable mailbox intelligence (Recommended)**.

14. Check **Enable Intelligence for impersonation protection
    (Recommended)**.

15. Click **Save**.

16. Click **Edit actions**.

17. Set **If message is detected as an impersonated user** to
    **Quarantine the message**.

18. Set **If message is detected as an impersonated domain** to
    **Quarantine the message**.

19. Set **If Mailbox Intelligence detects an impersonated user** to
    **Quarantine the message**.

20. Set **If message is detected as spoof** to **Quarantine the
    message**.

21. Under **Safety tips & indicators**, check:

1.  **Show first contact safety tip (Recommended)**

2.  **Show user impersonation safety tip**

3.  **Show domain impersonation safety tip**

4.  **Show user impersonation unusual characters safety tip**

5.  **Show (?) for unauthenticated senders for spoof**

6.  **Show “via” tag**

22. Click **Save**.

## 6. Inbound Anti-Spam Protections

There are several features that protect against inbound spam. Bulk
compliant level, quarantines, safety tips, and zero-hour auto purge.

### Policies

#### MS.DEFENDER.6.1v1
The bulk complaint level (BCL) threshold SHOULD be set to six or lower.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.6.2v1
Spam and high confidence spam SHALL be moved to either the junk email folder or the quarantine folder.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.6.3v1
Phishing and high confidence phishing SHALL be quarantined.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.6.4v1
Bulk email SHOULD be moved to either the junk email folder or the quarantine folder.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.6.5v1
Spam in quarantine SHOULD be retained for at least 30 days.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.6.6v1
Spam safety tips SHOULD be turned on.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.6.7v1
Zero-hour auto purge (ZAP) SHALL be enabled for both phishing and spam messages.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.6.8v1
Allowed senders MAY be added but allowed domains SHALL NOT be added.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.6.9v1
The previously listed configurations SHALL be set in the default policy and SHOULD be set in all existing custom policies.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Bulk complaint level (BCL) in EOP \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/bulk-complaint-level-values?view=o365-worldwide)

- [EOP anti-spam policy settings \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365?view=o365-worldwide#eop-anti-spam-policy-settings)

- [Configure anti-spam policies in EOP \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/configure-your-spam-filter-policies?view=o365-worldwide)

### License Requirements

- N/A

### Implementation

1.  Sign in to [Microsoft 365
    Defender](https://security.microsoft.com/).

2.  Under **Email & collaboration**, select **Policies & rules**.

3.  Select **Threat policies**.

4.  Under Policies, select **Anti-spam**.

5.  Select **Anti-spam inbound policy (Default)**.

6.  Under **Bulk email threshold & spam properties**, click **Edit spam
    threshold and properties**.

7.  Set **Bulk email threshold** to six or lower.

8.  Click **Save**.

9.  Under **Actions**, click **Edit actions**.

10. In the **Message actions** section:

1.  For **Spam, High confidence spam**, and **Bulk**, set the action to
    either **Move message to Junk Email folder** or **Quarantine
    message**.

2.  Set the action for both **Phishin**g and **High confidence
    phishing** to **Quarantine message**.

3.  Set **Retain spam in quarantine for this many days** to “30.”

4.  Check **Enable spam safety tips**.

5.  Check **Enable zero-hour auto purge (ZAP)**, **Enable for phishing
    messages,** and **Enable for spam messages**.

11. Click **Save.**

## 7. Safe Links

When enabled, URLs in emails are rewritten by prepending

`https://*.safelinks.protection.outlook.com/?url=`

to the original URL. This change can only be seen by either clicking the
URL or copying and pasting it; the end-user, even when hovering over the
URL in their email, will still only see the original URL. By prepending
the safe links URL, Microsoft can proxy the initial URL through their
scanning service. Their proxy can perform the following:

- Compare the URL will a block list.

- Compare the URL with a list of know malicious sites.

- If the URL points to a downloadable file, apply real-time file
  scanning.

If all checks pass, the user is redirected to the original URL.

### Policies
#### MS.DEFENDER.7.1v1
The Safe Links Policy SHALL include all agency domains and by extension all users.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.7.2v1
URL rewriting and malicious link click checking SHALL be enabled.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.7.3v1
Malicious link click checking SHALL be enabled with Microsoft Teams.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.7.4v1
Real-time suspicious URL and file-link scanning SHALL be enabled.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.7.5v1
URLs SHALL be scanned completely before message delivery.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.7.6v1
Internal agency email messages SHALL have safe links enabled.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.7.7v1
User click tracking SHALL be enabled.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.7.8v1
Safe Links in Office 365 apps SHALL be turned on.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.7.9v1
- Users SHALL NOT be enabled to click through to the original URL.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Safe Links in Microsoft Defender for Office 365 \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/safe-links?view=o365-worldwide)

- [Set up Safe Links policies in Microsoft Defender for Office 365 \|
  Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/set-up-safe-links-policies?view=o365-worldwide)

### License Requirements

- Requires Defender for Office 365 Plan 1 or 2. These are included with
  E5 and G5 and are available as add-ons for E3 and G3.

### Implementation

For more information about recommended Safe Links settings, see
[Safe](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365?view=o365-worldwide#safe-links-settings)
<u>Links settings</u>.

1.  Sign in to [Microsoft 365
    Defender](https://security.microsoft.com/).

2.  Under **Email & collaboration**, select **Policies & rules**.

3.  Select **Threat policies**.

4.  Under **Policies**, select **Safe Links**.

5.  Create a Safe Links Policy.

1.  Assign the new policy an appropriate name and description.

2.  Include all tenant domains. All users under those domains will be
    added.

3.  On the **URL & click protection settings** page:


1.  Select **On: Safe Links cehcks a list of known, malicious links when
users click links in email. URLs are rewritten by default.**

2.  Select **Apply Safe Links to email messages sent within the
organization**

3.  Select **Apply real-time URL scanning for suspicious links and links
that point to files.**

4.  Select **Wait for URL scanning to complete before delivering the
message.**


1.  On the **URL & click protection settings** page, under **Teams**,
    select **On: Safe Links checks a list of known, malicious links when
    users click links in Microsoft Teams. URLs are not rewritten**.

2.  On the **URL & click protection settings** page, under **Office 365
    Apps**, select **On: Safe Links checks a list of known, malicious
    links when users click links in Microsoft Office Apps. URLs are not
    rewritten**.

3.  On the **URL & click protestion settings** page, under **Click
    protestion settings**:

    1.  Select **Track User Clicks**

    2.  Do not select **Let users click through to the original URL**.


5.  Review the new policy, then click **Submit**.

## 8. Safe-Attachments

The Safe Attachments will scan messages for attachments with malicious
content. It routes all messages and attachments that do not have a
virus/malware signature to a special environment. It then uses machine
learning and analysis techniques to detect malicious intent. Enabling
this feature may slow down message delivery to the user due to the
scanning.

### Policies
#### MS.DEFENDER.8.1v1
At least one Safe Attachments Policy SHALL include all agency domains and by extension all users.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.8.2v1
The action for malware in email attachments SHALL be set to block.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.8.3v1
Redirect emails with detected attachments to an agency-specified email SHOULD be enabled.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.8.4v1
Safe attachments SHOULD be enabled for SharePoint, OneDrive, and Microsoft Teams.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Safe Attachments in Microsoft Defender for Office 365 \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/safe-attachments?view=o365-worldwide#safe-attachments-policy-settings)

- [Safe Attachments Policy Settings \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/safe-attachments?view=o365-worldwide#safe-attachments-policy-settings)

- [Use the Microsoft 365 Defender portal to create Safe Attachments
  policies \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/set-up-safe-attachments-policies?view=o365-worldwide#use-the-microsoft-365-defender-portal-to-create-safe-attachments-policies)

- [Turn on Safe Attachments for SharePoint, OneDrive, and Microsoft
  Teams \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/turn-on-mdo-for-spo-odb-and-teams?view=o365-worldwide)

### License Requirements

- Requires Defender for Office 365 Plan 1 or 2. These are included with
  E5 and G5 and are available as add-ons for E3 and G3.

### Implementation

To configure safe attachments for Exchange Online, follow the
instructions listed on [Use the Microsoft 365 Defender portal to create
Safe Attachments
policies](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/set-up-safe-attachments-policies?view=o365-worldwide#use-the-microsoft-365-defender-portal-to-create-safe-attachments-policies).

1.  Sign in to [Microsoft 365
    Defender](https://security.microsoft.com/).

2.  Under **Email & collaboration**, select **Policies & rules**.

3.  Select **Threat policies**.

4.  Under **Policies**, select **Safe Attachments**.

5.  Click **Create** to start a new policy.

6.  Give the new policy an appropriate name and description.

7.  Under domains, enter all agency tenant domains. All users under
    these domains will be added to the policy.

8.  Under **Safe Attachments unknown malware response**, select
    **Block**.

9.  Set the **Quarantine policy** to **AdminOnlyAccessPolicy**.

10. Click **Next**, then **Submit**.

To enable Safe Attachments for SharePoint, OneDrive, and Microsoft
Teams, follow the instructions listed at [Turn on Safe Attachments for
SharePoint, OneDrive, and Microsoft Teams \| Microsoft
Docs](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/turn-on-mdo-for-spo-odb-and-teams?view=o365-worldwide).

1.  Sign in to [Microsoft 365
    Defender](https://security.microsoft.com/).

2.  Under **Email & collaboration**, select **Policies & rules**.

3.  Select **Threat policies**.

4.  Under **Policies**, select **Safe Attachments**.

5.  Select **Global settings**.

6.  Set **Turn on Defender for Office 365 for SharePoint, OneDrive, and
    Microsoft Teams** to on.

## 9. Alerts

There are several pre-built alert policies available pertaining to
various apps in the M365 suite. These alerts give admins better
real-time insight into possible security incidents.

### Policy
#### MS.DEFENDER.9.1v1
At a minimum, the alerts required by the *Exchange Online Minimum Viable Secure Configuration Baseline* SHALL be enabled.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.9.2v1
The alerts SHOULD be sent to a monitored address or incorporated into a SIEM.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Alert policies in Microsoft 365 \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/compliance/alert-policies?view=o365-worldwide)

### License Requirements

- N/A

### Implementation

1.  Sign in to [Microsoft 365
    Defender](https://security.microsoft.com/).

2.  Under **Email & collaboration**, select **Policies & rules**.

3.  Select **Alert Policy**.

4. Click the policy name.

5.  Ensure **Status** is set to **On**.

6.  Ensure **Email recipients** includes at least one monitored address.

## 10. Microsoft Purview Audit

Unified audit logging generates logs of user activity in M365 services. 
These logs are essential for conducting incident response and threat detection activity.

By default, Microsoft retains the audit logs for only 90 days. Activity
by users with E5 licenses is logged for one year. 

However, per OMB M-21-31, Microsoft 365 audit logs are to be retained at least 12 months in
active storage and an additional 18 months in cold storage. This can be
accomplished either by offloading the logs out of the cloud environment
or natively through Microsoft by creating an [audit log retention
policy](https://docs.microsoft.com/en-us/microsoft-365/compliance/audit-log-retention-policies?view=o365-worldwide#create-an-audit-log-retention-policy).

OMB M-21-13 also requires Advanced Audit be configured in M365. Advanced Audit adds additional event types to the Unified Audit Log.

### Policy
#### MS.DEFENDER.10.1v1
Microsoft Purview Audit (Standard) logging SHALL be enabled.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.10.2v1
Microsoft Purview Audit (Premium) logging SHALL be enabled.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.10.3v1
Audit logs SHALL be maintained for at least the minimum duration dictated by OMB M-21-31.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### 2.10.2 Resources

- [OMB M-21-31 \| Office of Management and
  Budget](https://www.whitehouse.gov/wp-content/uploads/2021/08/M-21-31-Improving-the-Federal-Governments-Investigative-and-Remediation-Capabilities-Related-to-Cybersecurity-Incidents.pdf)

- [<u>Turn auditing on or off \| Microsoft
  Docs</u>](https://docs.microsoft.com/en-us/microsoft-365/compliance/turn-audit-log-search-on-or-off?view=o365-worldwide) 

- [Create an audit log retention policy \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/compliance/audit-log-retention-policies?view=o365-worldwide#create-an-audit-log-retention-policy)

- [<u>Search the audit log in the compliance center \| Microsoft
  Docs </u>](https://docs.microsoft.com/en-us/microsoft-365/compliance/search-the-audit-log-in-security-and-compliance?view=o365-worldwide) 

- [Audited Activities \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/compliance/search-the-audit-log-in-security-and-compliance?view=o365-worldwide#audited-activities)

### License Requirements

- Microsoft Purview Audit (Premium) logging capabilities, including the creation of a custom audit
  log retention policy, requires E5/G5 licenses or E3/G3 licenses with
  add-on compliance licenses.

- Additionally, maintaining logs in the M365 environment for longer than
  one year requires an add-on license. For more information, see
  [Licensing requirements \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/compliance/auditing-solutions-overview?view=o365-worldwide#licensing-requirements).

### Implementation

Auditing can be enabled from the Microsoft 365 compliance admin center
and the Exchange Online PowerShell. Follow the instructions listed on
[Turn on
auditing](https://docs.microsoft.com/en-us/microsoft-365/compliance/turn-audit-log-search-on-or-off?view=o365-worldwide#turn-on-auditing).

1.  Sign in to the [Microsoft 365
    compliance](https://compliance.microsoft.com) admin center.

2. Under **Solutions**, select **Audit**.

3. If auditing is not enabled, a banner displays and prompts that the
    user and admin activity start being recorded.

4. Click the **Start recording user and admin activity banner**.

To set up advanced audit, see [Set up Advanced Audit in Microsoft 365 \|
Microsoft
Docs.](https://docs.microsoft.com/en-us/microsoft-365/compliance/set-up-advanced-audit?view=o365-worldwide)

To create an audit retention policy, follow the instructions listed on
[Create an audit log retention policy](https://docs.microsoft.com/en-us/microsoft-365/compliance/audit-log-retention-policies?view=o365-worldwide#create-an-audit-log-retention-policy).

To check the current logging status via PowerShell

1. Connect to the Exchange Online PowerShell.

2. Run the following command: `Get-AdminAuditLogConfig | FL UnifiedAuditLogIngestionEnabled`

To enable logging via PowerShell:

1. Connect to the Exchange Online PowerShell.

2. Run the following command: `Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true`


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
