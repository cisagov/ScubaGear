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

The agency has identified a set of user accounts that have access to sensitive and high value information.  As a result, these accounts may be at a higher risk of being targeted.  These accounts are referred to as sensitive accounts for the purposes of the Defender policies in this baseline.

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
profiles](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/preset-security-policies):
standard and strict. These preset policies are informed by observations made by Microsoft and are designed to strike the balance between usability and security. They allow administrators to enable the full feature set of Defender by simply adding users to the policies rather than manually configuring each setting.

Within the preset policies, users can be enrolled in [Exchange Online Protection](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/eop-about?view=o365-worldwide) and [Defender for Office 365 protection](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/microsoft-defender-for-office-365-product-overview?view=o365-worldwide), and [Impersonation Protection](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/anti-phishing-policies-about?view=o365-worldwide#impersonation-settings-in-anti-phishing-policies-in-microsoft-defender-for-office-365) can be configured.

### Policies
#### MS.DEFENDER.1.1v1
The standard and strict preset security policies SHALL be enabled.
- _Rationale:_  Defender includes a large number of features and settings to protect users against threats. Using the preset security policies, administrators can easily ensure that all new and existing users automatically have secure defaults applied.

- _Last modified:_ June 2023
#### MS.DEFENDER.1.2v1
All users SHALL be added to Exchange Online Protection in either the standard or strict preset security policy.
- _Rationale:_ Important user protections are provided by Exchange Online Protection, including anti-spam, anti-malware, and anti-phishing protections. By using the preset policies, administrators can easily ensure that all new and existing users automatically have secure defaults applied.

- _Last modified:_ June 2023

#### MS.DEFENDER.1.3v1
All users SHALL be added to Defender for Office 365 Protection in either the standard or strict preset security policy.
- _Rationale:_ Important user protections are provided by Defender for Office 365 Protection, including safe attachments and safe links. By using the preset policies, administrators can easily ensure that all new and existing users automatically have secure defaults applied.
- _Last modified:_ June 2023

#### MS.DEFENDER.1.4v1
Sensitive accounts SHALL be added to Exchange Online Protection in the strict preset security policy.
- _Rationale:_ The increased protection offered by the strict preset policy helps mitigate the greater harm that could result from the compromise of a sensitive account.
- _Last modified:_ June 2023

#### MS.DEFENDER.1.5v1
Sensitive accounts SHALL be added to Defender for Office 365 Protection in the strict preset security policy.
- _Rationale:_ The increased protection offered by the strict preset policy helps mitigate the greater harm that could result from the compromise of a sensitive account.
- _Last modified:_ June 2023

#### MS.DEFENDER.1.6v1
Specific user accounts, except for sensitive accounts, MAY be exempt from the preset policies, provided that they are added to a custom policy that offers comparable protection.
- _Rationale:_ In some cases, specific users might need flexibility that is not offered by the preset policies. In these cases, these users' accounts should be added to a custom policy that conforms as closely as possible to the settings used by the preset policies (see the **Resources** section for more details).
- _Last modified:_ June 2023

### Resources

- [Recommended settings for EOP and Microsoft Defender for Office 365
  security \| Microsoft
  Docs](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365)

### License Requirements

- N/A

### Implementation
To add users to the preset policies, follow the instructions listed under [Use the Microsoft 365 Defender portal to assign Standard and Strict preset security policies to users \| Microsoft Docs](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/preset-security-policies?view=o365-worldwide#use-the-microsoft-365-defender-portal-to-assign-standard-and-strict-preset-security-policies-to-users).

To apply a preset policy to all users, under "Apply protection to," select "All recipients."

## 2. Impersonation Protection
Impersonation protection checks incoming emails to see if the sender
address is similar to the users or domains on an agency-defined list. If
the sender address is significantly similar, as to indicate an
impersonation attempt, the email is quarantined.

### Policies
#### MS.DEFENDER.2.1v1
User impersonation protection SHOULD be enabled for sensitive accounts in both the standard and strict preset policies.
- _Rationale:_ User impersonation, especially the impersonation of users with access to sensitive or high value information and resources, has the potential to result in serious harm. Impersonation protection mitigates this risk. By configuring impersonation protection in both preset policies, administrators ensure that all email recipients are protected from impersonated emails, regardless of whether they are added to the standard or strict policy.
- _Last modified:_ June 2023

#### MS.DEFENDER.2.2v1
Domain impersonation protection SHOULD be enabled for domains owned by the agency in both the standard and strict preset policies.
- _Rationale:_ By configuring domain impersonation protection for all agency domains, the risk of a user being deceived by a look-alike domain may be reduced. By configuring impersonation protection in both preset policies, administrators ensure that all email recipients are protected from impersonated emails, regardless of whether they are added to the standard or strict policy.
- _Last modified:_ June 2023

#### MS.DEFENDER.2.3v1
Domain impersonation protection SHOULD be added for important partners in both the standard and strict preset policies.
- _Rationale:_ By configuring domain impersonation protection for domains owned by important partners, the risk of a user being deceived by a look-alike domain may be reduced. By configuring impersonation protection in both preset policies, administrators ensure that all email recipients are protected from impersonated emails, regardless of whether they are added to the standard or strict policy.
- _Last modified:_ June 2023

#### MS.DEFENDER.2.4v1
Trusted senders and domains MAY be added in the event of false positives.
- _Rationale:_ It is possible that false positives may be raised by the impersonation protection system. In these cases, consider marking legitimate senders as trusted to prevent protection from flagging them in the future.
- _Last modified:_ June 2023

### Resources

- [Impersonation settings in anti-phishing policies in Microsoft Defender for Office 365 \| Microsoft Docs](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/anti-phishing-policies-about?view=o365-worldwide#impersonation-settings-in-anti-phishing-policies-in-microsoft-defender-for-office-365).

### License Requirements

- Impersonation protection and advanced phishing thresholds require
  Defender for Office 365 Plan 1 or 2. These are included with E5 and G5
  and are available as add-ons for E3 and G3. As of April 25, 2023
  anti-phishing for user and domain impersonation and spoof intelligence
  are not yet available in GCC High and DoD (see [Platform features \|
  Microsoft
  Docs](https://docs.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/office-365-us-government#platform-features)
  for current offerings).

### Implementation
To add email addresses and domains to flag when impersonated by attackers, follow the instructions listed under [Use the Microsoft 365 Defender portal to assign Standard and Strict preset security policies to users \| Microsoft Docs](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/preset-security-policies?view=o365-worldwide#use-the-microsoft-365-defender-portal-to-assign-standard-and-strict-preset-security-policies-to-users).

## 3. Safe Attachments

The Safe Attachments feature will scan messages for attachments with malicious
content. It routes all messages and attachments that do not have a
virus or malware signature to a special environment. It then uses machine
learning and analysis techniques to detect malicious intent.
While safe attachments for Exchange Online is automatically
configured in the preset policies, separate action needs to be taken to
enable it for other products.

### Policies
#### MS.DEFENDER.3.1v1
Safe attachments SHOULD be enabled for SharePoint, OneDrive, and Microsoft Teams.
- _Rationale:_ Users clicking malicious links makes them vulnerable to attacks. However, this danger is not limited to links included in emails. Other Microsoft products, such as Microsoft Teams, can be used to present users with malicious links. As such, it is important to protect users on these other Microsoft products as well.
- _Last modified:_ June 2023

### Resources

- [Safe Attachments in Microsoft Defender for Office 365 \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/safe-attachments?view=o365-worldwide#safe-attachments-policy-settings)

- [Turn on Safe Attachments for SharePoint, OneDrive, and Microsoft
  Teams \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/turn-on-mdo-for-spo-odb-and-teams?view=o365-worldwide)

### License Requirements

- Requires Defender for Office 365 Plan 1 or 2. These are included with
  E5 and G5 and are available as add-ons for E3 and G3.

### Implementation

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

## 4. Data Loss Prevention

There are several approaches to secure sensitive information, such
as warning users, encryption, or blocking attempts to share. The
agency’s data loss prevention (DLP) policy will dictate what agency
information is sensitive and how that information is handled.  Defender
can detect sensitive information and associates a default confidence
level with this detection based on the sensitive information type
matched.  Confidence levels are used to reduce false positives in
detecting access to sensitive information.  Agencies may choose to use
the default confidence levels or adjust the levels in custom DLP policies
to fit their environment and needs.

### Policies
#### MS.DEFENDER.4.1v1
A custom policy SHALL be configured to protect PII and sensitive information,
as defined by the agency. At a minimum, credit card numbers, Taxpayer
Identification Numbers (TIN), and Social Security Numbers (SSN) SHALL be
blocked.
 - _Rationale:_ Users may inadvertently share sensitive information with
                others who should not have access to it.  Data loss prevention policies provide a way for agencies to detect
                and prevent unauthorized disclosures.
- _Last modified:_ June 2023

#### MS.DEFENDER.4.2v1
The custom policy SHOULD be applied in Exchange, OneDrive, Teams Chat,
and Devices.
- _Rationale:_ Unauthorized disclosures may happen through Microsoft 365
               services or endpoint devices.  Data loss prevention
               policies should cover all affected locations to be
               effective.
- _Last modified:_ June 2023

#### MS.DEFENDER.4.3v1
The action for the DLP policy SHOULD be set to block sharing sensitive information with everyone when DLP conditions are met.
- _Rationale:_ Access to sensitive information should be prohibited unless
               explicitly allowed.  Specific exemptions can be made based
               on agency policies and valid business justifications.
- _Last modified:_ June 2023

#### MS.DEFENDER.4.4v1
Notifications to inform users and help educate them on the proper use of sensitive information SHOULD be enabled.
- _Rationale:_ Some users may not be aware of agency policies on the
               proper use of sensitive information.  Enabling
               notifications provides positive feedback to users when
               accessing sensitive information.
- _Last modified:_ June 2023

#### MS.DEFENDER.4.5v1
A list of apps that are restricted when accessing files protected by DLP policy SHOULD be defined.
- _Rationale:_ Some applications may inappropriately share accessed files
               or not conform to agency policies for access to sensitive
               information.  Defining a list of those apps makes it
               possible to use DLP policies to restrict those apps access
               to sensitive information on endpoints using Defender.
- _Last modified:_ June 2023

#### MS.DEFENDER.4.6v1
The custom policy SHOULD include an action to block access to sensitive
information by restricted apps and unwanted bluetooth applications.
- _Rationale:_ Some applications may inappropriately share accessed files
               or not conform to agency policies for access to sensitive
               information.  Defining a DLP policy with an action to block
               access from restricted apps and unwanted bluetooth applications prevents unauthorized disclosure by those
               programs.
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

MS.DEFENDER.4.1v1 implementation:

1. Sign in to the [Microsoft 365
   compliance](https://compliance.microsoft.com) admin center.

2. Under **Solutions**, select **Data loss prevention**.

3. Select **Policies** from the top of the page.

4. Select **Default Office 365 DLP policy**.

5. Select **Copy policy**.

6. Edit the name and description of the policy if desired, then click
   **Next**.

7. Under **Assign admin units**, select **Full directory**, then click
   **Next**.

8. Under **Choose Locations to apply the policy**, set **Status** to **On**
   for all products except Power BI and Microsoft Defender for Cloud
   Apps.

9. Click **Create rule**. Assign the rule an appropriate name and
   description.

10. Click **Add condition**, then **Content contains**.

11. Click **Add**, then **Sensitive info types**.

12. Add info types that protect information that is sensitive to the
    agency. At a minimum, the agency should protect:

    - Credit card numbers
    - U.S. Individual Taxpayer Identification Numbers (TIN)
    - U.S. Social Security Numbers (SSN)
    - All agency defined PII and sensitive information

13. Click **Add**.

14. Under **Actions**, click **Add an action**.

15. Check **Restrict Access or encrypt the content in Microsoft 365
    locations**.

16. Select **Block Everyone**.

17. Turn on **Use notifications to inform your users and help educate them on the proper use of sensitive info**.

18. Click **Save**, then **Next**.

19. Select **Turn it on right away**, then click **Next**.

20. Click **Submit**.

MS.DEFENDER.4.2v1 implementation:

1. Sign in to the [Microsoft 365
   compliance](https://compliance.microsoft.com) admin center.

2. Under **Solutions**, select **Data loss prevention**.

3. Select **Policies** from the top of the page.

4. Find the relevant DLP policy in the list and click the Policy name to select.
   Select **Edit Policy**.

5. Click **Next** on each page in the policy wizard until you reach the
   Locations page.

6. Under **Choose locations to apply the policy**, ensure **Status** is set
   to **On** for at least the Exchange email, OneDrive accounts, Teams chat
   and channel messages, and Devices.

7. Click **Next** on each page until reaching the
   **Review your policy and create it** page.

8. Review the policy locations listed and click **Submit**.

MS.DEFENDER.4.3v1 implementation:

1. Sign in to the [Microsoft 365
   compliance](https://compliance.microsoft.com) admin center.

2. Under **Solutions**, select **Data loss prevention**.

3. Select **Policies** from the top of the page.

4. Select the relevant custom policy and select **Edit policy**.

5. Click **Next** on each page in the policy wizard until you reach the
   Advanced DLP rules page.

6. Select the relevant rule and click the pencil icon to edit it.

7. Under **Actions**, click **Add an action**.

8. Select **Restrict Access or encrypt the content in Microsoft 365
   locations**.

9. Select **Block Everyone**.

10. Click **Save** to save the changes.

11. Click **Next** on each page until reaching the
    **Review your policy and create it** page.

12. Review the policy and click **Submit** to complete the policy changes.

MS.DEFENDER.4.4v1 implementation:

1. Sign in to the [Microsoft 365
   compliance](https://compliance.microsoft.com) admin center.

2. Under **Solutions**, select **Data loss prevention**.

3. Select **Policies** from the top of the page.

4. Select the relevant custom policy and select **Edit policy**.

5. Click **Next** on each page in the policy wizard until you reach the
   Advanced DLP rules page.

6. Select the relevant rule and click the pencil icon to edit it.

7. Under **User notifications**, toggle **Turn on Use notifications to inform
   your users and help educate them on the proper use of sensitive info.**
   to **On**.

8. Click **Save** to save the changes.

9. Click **Next** on each page until reaching the
  **Review your policy and create it** page.

10. Review the policy and click **Submit** to complete the policy changes.

MS.DEFENDER.4.5v1 implementation:

1. Sign in to the [Microsoft 365
   compliance](https://compliance.microsoft.com) admin center.

2. Under **Solutions**, select **Data loss prevention**.
  
3. Go to **Endpoint DLP Settings**.

4. Go to **Restricted apps and app groups**.

5. Click **Add or edit Restricted Apps**.

6. Enter an app and executable name to disallow said app from
   accessing protected files and to log the incident.

7. Return and click **Unallowed Bluetooth apps**.

8. Click **Add or edit unallowed Bluetooth apps**.

9. Enter an app and executable name to disallow said app from
   accessing protected files and to log the incident.

MS.DEFENDER.4.6v1 implementation:

1. Sign in to the [Microsoft 365
   compliance](https://compliance.microsoft.com) admin center.

2. Under **Solutions**, select **Data loss prevention**.

3. Select **Policies** from the top of the page.

4. Find the relevant DLP policy in the list and click the Policy name to select.
   Select **Edit Policy**.

5. Click **Next** on each page in the policy wizard until you reach the
   Advanced DLP rules page.

6. Select the relevant rule and click the pencil icon to edit it.

7. Under **Actions**, click **Add an action**.

8. Choose **Audit or restrict activities on device**

9. Under **File activities for all apps**, select
   **Apply restrictions to specific activity**.

10. Check the box next to **Copy or move using unallowed Bluetooth app**
    and set its action to **Block**.

11. Under **Restricted app activities** , check the **Access by restricted apps** box
   and set the action drop-down to **Block**.

12. Click **Save** to save the changes.

13. Click **Next** on each page until reaching the
    **Review your policy and create it** page.

14. Review the policy and click **Submit** to complete the policy changes.

## 5. Alerts

There are several pre-built alert policies available pertaining to
various apps in the M365 suite. These alerts give administrators better
real-time insight into possible security incidents.

### Policies
#### MS.DEFENDER.5.1v1
At a minimum, the alerts required by the *Exchange Online Minimum Viable Secure Configuration Baseline* SHALL be enabled.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.5.2v1
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

## 6. Microsoft Purview Audit

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

### Policies
#### MS.DEFENDER.6.1v1
Microsoft Purview Audit (Standard) logging SHALL be enabled.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.6.2v1
Microsoft Purview Audit (Premium) logging SHALL be enabled.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.DEFENDER.6.3v1
Audit logs SHALL be maintained for at least the minimum duration dictated by OMB M-21-31.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [OMB M-21-31 \| Office of Management and
  Budget](https://www.whitehouse.gov/wp-content/uploads/2021/08/M-21-31-Improving-the-Federal-Governments-Investigative-and-Remediation-Capabilities-Related-to-Cybersecurity-Incidents.pdf)

- [<u>Turn auditing on or off \| Microsoft
  Docs</u>](https://docs.microsoft.com/en-us/microsoft-365/compliance/turn-audit-log-search-on-or-off?view=o365-worldwide) 

- [Create an audit log retention policy \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/compliance/audit-log-retention-policies?view=o365-worldwide#create-an-audit-log-retention-policy)

- [<u>Search the audit log in the compliance center \| Microsoft
  Docs </u>](https://docs.microsoft.com/en-us/microsoft-365/compliance/search-the-audit-log-in-security-and-compliance?view=o365-worldwide) 

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
