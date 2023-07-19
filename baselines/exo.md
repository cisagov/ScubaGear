# CISA M365 Security Configuration Baseline for Exchange Online

Microsoft Exchange Online provides users easy access to their email and
supports organizational meetings, contacts, and calendars.

Many admin controls for Exchange Online are found in the **Exchange admin center**.
However, several of the
security features for Exchange Online are shared between Microsoft
products and are configured in either the **Microsoft 365 Defender portal**
or **Microsoft 365 Purview compliance portal** admin centers. Generally
speaking, the use of Microsoft Defender is not strictly required for
this baseline. When noted, alternative products may be used in lieu of
Defender, on the condition that they fulfill these required baseline
settings.

## License Compliance and Copyright

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

## Assumptions

The **License Requirements** sections of this document assume the
organization is using an [M365
E3](https://www.microsoft.com/en-us/microsoft-365/compare-microsoft-365-enterprise-plans)
or [G3](https://www.microsoft.com/en-us/microsoft-365/government)
license level. Therefore, only licenses not included in E3/G3 are
listed.

# Baseline Policies

## 1. Automatic Forwarding to External Domains

This control is intended to prevent bad actors from using client-side
forwarding rules to exfiltrate data to external recipients.

### Policies

#### MS.EXO.1.1v1
Automatic forwarding to external domains SHALL be disabled.
- _Rationale:_ Adversaries can use automatic forwarding to gain
persistent access to a victim's email. Disabling forwarding to
external domains prevents this technique when the adversary is
external to the organization but does not impede legitimate
internal forwarding.
- _Last modified:_ June 2023

### Resources

- [Reducing or increasing information flow to another company \|
  Microsoft
  Learn](https://learn.microsoft.com/en-us/exchange/mail-flow-best-practices/remote-domains/remote-domains#reducing-or-increasing-information-flow-to-another-company)

### License Requirements

- N/A

### Implementation

#### MS.EXO.1.1v1 instructions:
To disallow automatic forwarding to external domains:

1.  Sign in to the **Exchange admin center**.

2.  Select **Mail flow,** then **Remote domains**.

3.  Select **Default**.

4.  Under **Email reply types**, select **Edit reply types**.

5.  Clear the checkbox next to **Allow automatic forwarding**, then
    click **Save**.

## 2. Sender Policy Framework

The Sender Policy Framework (SPF) is a mechanism that allows domain
administrators to specify which IP addresses are explicitly approved to
send email on behalf of the domain, facilitating detection of spoofed
emails. SPF isn’t configured through the Exchange admin center, but
rather via DNS records hosted by the agency’s domain. Thus, the exact
steps needed to set up SPF varies from agency to agency, but Microsoft’s
documentation provides some helpful starting points.

### Policies

#### MS.EXO.2.1v1
A list of approved IP addresses for sending mail SHALL be maintained.
- _Rationale:_ Failing to maintain an accurate list of authorized IP addresses may result in spoofed email messages or failure to deliver legitimate messages when SPF is enabled.  Maintaining such a list ensures that unauthorized servers sending spoofed messages can be detected and permit messages from legitimate senders to be delivered.
- _Last modified:_ June 2023

#### MS.EXO.2.2v1
An SPF policy(s) that designates only these addresses as approved senders SHALL be published.

- _Rationale:_ An adversary may modify the `FROM` field
of an email such that it appears to be a legitimate email sent by an
agency, facilitating phishing attacks. Publishing an SPF policy for each agency domain mitigates forged `FROM` fields by providing a means for recipients to detect emails spoofed in this way.  SPF is required for federal, executive branch, departments and agencies by Binding Operational Directive 18-01, “Enhance Email and Web Security”.
- _Last modified:_ June 2023

### Resources

- [Binding Operational Directive 18-01 - Enhance Email and Web Security
  \| DHS](https://cyber.dhs.gov/bod/18-01/)

- [Trustworthy Email \| NIST 800-177 Rev.
  1](https://csrc.nist.gov/publications/detail/sp/800-177/rev-1/final)

- [Set up SPF to help prevent spoofing \| Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/email-authentication-spf-configure?view=o365-worldwide)

- [How Microsoft 365 uses Sender Policy Framework (SPF) to prevent
  spoofing \| Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/email-authentication-anti-spoofing?view=o365-worldwide)

### License Requirements

- N/A

### Implementation

#### MS.EXO.2.1v1 instructions:
Identify any approved senders specific to your agency.
Additionally, see [External DNS records required for SPF](https://learn.microsoft.com/en-us/microsoft-365/enterprise/external-domain-name-system-records?view=o365-worldwide#external-dns-records-required-for-spf) for
inclusions required for Microsoft to be able to send email on behalf of your domain.

#### MS.EXO.2.2v1 instructions:
SPF is not configured through the Exchange admin center, but rather via
DNS records hosted by the agency’s domain. Thus, the exact steps needed
to set up SPF varies from agency to agency. See [Add or edit an SPF TXT record to help prevent email spam (Outlook, Exchange Online) \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-365/admin/get-help-with-domains/create-dns-records-at-any-dns-hosting-provider?view=o365-worldwide#add-or-edit-an-spf-txt-record-to-help-prevent-email-spam-outlook-exchange-online) for more details.

To test your SPF configuration, consider using a web-based tool, such as
those listed under [How can I validate SPF records for my domain? \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-365/admin/setup/domains-faq?view=o365-worldwide#how-can-i-validate-spf-records-for-my-domain).
Additionally, SPF records can be requested using the
PowerShell tool `Resolve-DnsName`. For example:

```
Resolve-DnsName example.onmicrosoft.com txt
```

If SPF is configured, a response resembling `v=spf1 include:spf.protection.outlook.com -all`
will be returned, though by necessity, the contents of the SPF
policy may vary by agency. In this example, the SPF policy indicates
that the IP addresses listed by the policy for "spf.protection.outlook.com" are
the only approved senders for "example.onmicrosoft.com." These IPs can be determined
via an additional SPF lookup, this time for "spf.protection.outlook.com." Ensure that
the IP addresses listed as approved senders for your domain are those identified for
MS.EXO.2.1v1. See [SPF TXT record syntax for Microsoft 365 \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/email-authentication-anti-spoofing?view=o365-worldwide#spf-txt-record-syntax-for-microsoft-365) for a more in-depth discussion
SPF record syntax.

## 3. DomainKeys Identified Mail

DomainKeys Identified Mail (DKIM) allows digital signatures to be added
to email messages in the message header, providing a layer of both
authenticity and integrity to emails. As with SPF, DKIM relies on Domain
Name System (DNS) records, thus, its deployment depends on how an
agency manages its DNS. DKIM is enabled for your tenant's default domain
(e.g., onmicrosoft.com domains), but it must be manually enabled for
custom domains.

### Policies

#### MS.EXO.3.1v1
DKIM SHOULD be enabled for any custom domain.

- _Rationale:_ An adversary may modify the `FROM` field
of an email such that it appears to be a legitimate email sent by an
agency, facilitating phishing attacks. Enabling DKIM is another means to allow
recipients to detect spoofed emails and verify the integrity of email content.
- _Last modified:_ June 2023

### Resources

- [Binding Operational Directive 18-01 - Enhance Email and Web Security
  \| DHS](https://cyber.dhs.gov/bod/18-01/)

- [Trustworthy Email \| NIST 800-177 Rev.
  1](https://csrc.nist.gov/publications/detail/sp/800-177/rev-1/final)

- [Use DKIM to validate outbound email sent from your custom domain \|
  Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/email-authentication-dkim-configure?view=o365-worldwide)

- [Support for validation of DKIM signed messages \| Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/email-authentication-dkim-support-about?view=o365-worldwide)

- [What is EOP? \| Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/eop-faq?view=o365-worldwide#what-is-eop-)

### License Requirements

- DKIM signing is included with Exchange Online Protection (EOP), which
  in turn is included in all Microsoft 365 subscriptions that contain
  Exchange Online mailboxes.

### Implementation

#### MS.EXO.3.1v1 instructions:
To enable DKIM, follow the instructions listed on [Steps to Create,
enable and disable DKIM from Microsoft 365 Defender portal \| Microsoft
Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/email-authentication-dkim-configure?view=o365-worldwide#steps-to-create-enable-and-disable-dkim-from-microsoft-365-defender-portal).

1.  Navigate to the [Microsoft 365 Defender portal](https://learn.microsoft.com/en-us/microsoft-365/security/defender/usgov?view=o365-worldwide#portal-urls).

2.  On the left hand side go to **Email & collaboration** > **Policies & Rules**.

3. From the list of policies, select *Threat Policies**.

4. Under **Rules**, select **Email Authentication Settings**.

5. Select **DKIM**.

6.  Select your domain.

7.  Switch **Sign messages for this domain with DKIM signatures** to
    **Enabled**.

8.  If you are enabling DKIM for the first time, a pop-up window listing
    Canonical Name (CNAME) records displays. Publish these records to
    your DNS service provider.

9.  Return to the DKIM page on the Defender admin center to finish
    enabling DKIM.


## 4. Domain-Based Message Authentication, Reporting, and Conformance (DMARC)
Domain-based Message Authentication, Reporting, and Conformance (DMARC)
works with SPF and DKIM to authenticate mail senders and ensure that
destination email systems can validate messages sent from your domain.
DMARC helps receiving mail systems determine what to do with messages
sent from your domain that fail SPF and DKIM checks.

### Policies

#### MS.EXO.4.1v1
A DMARC policy SHALL be published for every second-level domain.

- _Rationale:_ Without a DMARC policy available for each domain, recipients
may improperly handle SPF and DKIM failures, possibly enabling spoofed
emails to reach end users' mailboxes. By publishing DMARC records at the
second-level domain, the second-level domains and all subdomains will be
protected.
- _Last modified:_ June 2023

#### MS.EXO.4.2v1
The DMARC message rejection option SHALL be p=reject.

- _Rationale:_ Of the three policy options (none, quarantine, and reject),
reject provides the strongest protection. This is the level of protection
required by BOD 18-01 for federal, executive branch, departments and agencies.
- _Last modified:_ June 2023

#### MS.EXO.4.3v1
The DMARC point of contact for aggregate reports SHALL include <reports@dmarc.cyber.dhs.gov>.

- _Rationale:_ Email spoofing attempts are not inherently visible to domain
owners. DMARC provides a mechanism to receive reports of spoofing attempts.
Including <reports@dmarc.cyber.dhs.gov> as a point of contact for these reports
gives CISA insight into spoofing attempts and is required by Binding Operational Directive 18-01, "Enhance Email and Web Security” for
federal, executive branch, departments and agencies.
- _Last modified:_ June 2023

#### MS.EXO.4.4v1
An agency point of contact SHOULD be included for aggregate and/or failure reports.

- _Rationale:_ Email spoofing attempts are not inherently visible to domain
owners. DMARC provides a mechanism to receive reports of spoofing attempts.
Including an agency point of contact gives the agency insight into attempts
to spoof their domains.
- _Last modified:_ June 2023

### Resources

- [Binding Operational Directive 18-01 - Enhance Email and Web Security
  \| DHS](https://cyber.dhs.gov/bod/18-01/)

- [Trustworthy Email \| NIST 800-177 Rev.
  1](https://csrc.nist.gov/publications/detail/sp/800-177/rev-1/final)

- [Domain-based Message Authentication, Reporting, and Conformance
  (DMARC) \| RFC 7489](https://datatracker.ietf.org/doc/html/rfc7489)

- [Best practices for implementing DMARC in Office 365 \| Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/email-authentication-dmarc-configure?view=o365-worldwide#best-practices-for-implementing-dmarc-in-microsoft-365)

- [How Office 365 handles outbound email that fails DMARC \| Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/email-authentication-dmarc-configure?view=o365-worldwide#how-microsoft-365-handles-inbound-email-that-fails-dmarc)

### License Requirements

- N/A

### Implementation

#### MS.EXO.4.1v1 instructions:
DMARC is not configured through the Exchange admin center, but rather via
DNS records hosted by the agency’s domain. As such, implementation varies
depending on how an agency manages its DNS records. See [Form the DMARC TXT record for your domain \| Microsoft
Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/email-authentication-dmarc-configure?view=o365-worldwide#step-4-form-the-dmarc-txt-record-for-your-domain)
for Microsoft guidance.

Note that a DMARC record published at the second-level domain will protect all subdomains.
In other words, a DMARC record published for `example.com` will protect both
`a.example.com` and `b.example.com`, but a separate record would need to be
published for `c.example.gov`.

To test your DMARC configuration, consider using one of many publicly available
web-based tools. Additionally, DMARC records can be requested using the
PowerShell tool `Resolve-DnsName`. For example:

```
Resolve-DnsName _dmarc.example.com txt
```

If DMARC is configured, a response resembling `v=DMARC1; p=reject; pct=100; rua=mailto:reports@dmarc.cyber.dhs.gov, mailto:reports@example.com`
will be returned, though by necessity, the contents of the record will vary by agency.
In this example, the policy indicates that all emails that fail the SPF/DKIM checks are to
be rejected and reported to reports@dmarc.cyber.dhs.gov and reports@example.com.

#### MS.EXO.4.2v1 instructions:
See [MS.EXO.4.1v1 instructions](#msexo41v1-instructions) for an overview of how to publish and check a DMARC record. Ensure that the record published includes `p=reject`.

#### MS.EXO.4.3v1 instructions:
See [MS.EXO.4.1v1 instructions](#msexo41v1-instructions) for an overview of how to publish and check a DMARC record. Ensure that the record published includes <reports@dmarc.cyber.dhs.gov>
as one of the emails for the `rua` field.

#### MS.EXO.4.4v1 instructions:
See [MS.EXO.4.1v1 instructions](#msexo41v1-instructions) for an overview of how to publish and check a DMARC record. Ensure that the record published includes a point of contact
specific to your agency in addition to <reports@dmarc.cyber.dhs.gov>
as one of the emails for the `rua` field.

## 5. Simple Mail Transfer Protocol Authentication (SMTP AUTH)

Modern email clients that connect to Exchange Online mailboxes—including
Outlook, Outlook on the web, iOS Mail, and Outlook for iOS and
Android—do not use Simple Mail Transfer Protocol Authentication (SMTP
AUTH) to send email messages. SMTP AUTH is only needed for applications
outside of Outlook that send email messages. MFA cannot be enforced while using
SMTP Auth. Proceed with caution if SMTP Auth needs to be enabled for any use case.

### Policies

#### MS.EXO.5.1v1
SMTP AUTH SHALL be disabled in Exchange Online.

- _Rationale:_ SMTP AUTH is not used or needed by modern email clients.
Therefore, disabling it as the global default conforms to the principle of least
functionality.
- _Last modified:_ June 2023

#### MS.EXO.5.2v1
SMTP AUTH MAY be enabled on a per-mailbox basis as needed.

- _Rationale:_ SMTP AUTH is required for POP3 and IMAP4 clients.
As there are still legitimate uses for such clients, SMTP
AUTH can be enabled on a per-mailbox basis as necessary.
- _Last modified:_ June 2023

### Resources

- [Enable or disable authenticated client SMTP submission (SMTP AUTH) in
  Exchange Online \| Microsoft
  Learn](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/authenticated-client-smtp-submission)

- [Use the Microsoft 365 admin center to enable or disable SMTP AUTH on
  specific mailboxes \| Microsoft
  Learn](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/authenticated-client-smtp-submission#use-the-microsoft-365-admin-center-to-enable-or-disable-smtp-auth-on-specific-mailboxes)

### License Requirements

- N/A

### Implementation

#### MS.EXO.5.1v1 instructions:
SMTP AUTH can be disabled tenant-wide using the Exchange admin center
or Exchange Online PowerShell. Follow the instructions listed at [Disable
SMTP AUTH in your organization \| Microsoft
Learn](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/authenticated-client-smtp-submission#disable-smtp-auth-in-your-organization).

#### MS.EXO.5.2v1 instructions:
To enable SMTP AUTH on a per-mailbox basis, follow the instructions
listed at [Use the Microsoft 365 admin center to enable or disable SMTP
AUTH on specific mailboxes \| Microsoft
Learn](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/authenticated-client-smtp-submission#use-the-microsoft-365-admin-center-to-enable-or-disable-smtp-auth-on-specific-mailboxes).

## 6. Calendar and Contact Sharing

Exchange Online allows the creation of sharing polices that soften
default restrictions on contact and calendar details sharing. These
policies should only be enabled with caution and after considering
the following policies.

### Policies

#### MS.EXO.6.1v1
Contact folders SHALL NOT be shared with all domains.

- _Rationale:_ Contact folders may contain information that should not be shared by default with all domains. Disabling sharing with all domains closes an avenue for data exfiltration while still allowing
for specific legitimate uses as needed.
- _Last modified:_ June 2023
- _Note:_ Contact folders MAY be shared with specific domains.

#### MS.EXO.6.2v1
Calendar details SHALL NOT be shared with all domains.

- _Rationale:_ Calendar details may contain information that should not be shared by default with all domains. Disabling sharing with all domains closes an avenue for data exfiltration while still allowing
for legitimate uses as needed.
- _Last modified:_ June 2023
- _Note:_ Calendar details MAY be shared with specific domains.

### Resources

- [Sharing in Exchange Online \| Microsoft
  Learn](https://learn.microsoft.com/en-us/exchange/sharing/sharing)

- [Organization relationships in Exchange Online \| Microsoft
  Learn](https://learn.microsoft.com/en-us/exchange/sharing/organization-relationships/organization-relationships)

- [Sharing policies in Exchange Online \| Microsoft
  Learn](https://learn.microsoft.com/en-us/exchange/sharing/sharing-policies/sharing-policies)

### License Requirements

- N/A

### Implementation

#### MS.EXO.6.1v1 instructions:
To restrict sharing with all domains:

1.  Sign in to the **Exchange admin center**.

2.  On the left hand pane under **Organization**, select **Sharing** .

3.  Select **Individual Sharing**.

4. For all existing policies, Select the policy, then select **Manage domains**

5. For all sharing rules under all existing policies, ensure **Sharing with all domains** is not selected.

#### MS.EXO.6.2v1 instructions:

1. Refer to step 5 in [MS.EXO.6.1v1 instructions](#msexo61v1-instructions) to implement
this policy.

## 7. External Sender Warnings

Mail flow rules allow the modification of incoming mail, such that mail
from external users can be easily identified, for example by prepending
the subject line with “\[External\].”

### Policies

#### MS.EXO.7.1v1
External sender warnings SHALL be implemented.

- _Rationale:_ Phishing is an ever-present threat. Alerting the user when
an email originates from outside their organization can encourage them
to exercise increased caution, especially if it is an email they would
have expected to be sent from an internal sender.
- _Last modified:_ June 2023

### Resources

- [Mail flow rules (transport rules) in Exchange Online \| Microsoft
  Learn](https://learn.microsoft.com/en-us/exchange/security-and-compliance/mail-flow-rules/mail-flow-rules)

- [Capacity Enhancement Guide: Counter-Phishing Recommendations for
  Federal Agencies \|
  CISA](https://www.cisa.gov/sites/default/files/publications/Capacity_Enhancement_Guide-Counter-Phishing_Recommendations_for_Federal_Agencies.pdf)

- [Actions To Counter Email-Based Attacks On Election-Related Entities
  \|
  Cisa](https://www.cisa.gov/sites/default/files/publications/CISA_Insights_Actions_to_Counter_Email-Based_Attacks_on_Election-Related_S508C.pdf)

### License Requirements

- N/A

### Implementation

#### MS.EXO.7.1v1 instructions:
To enable external sender warnings:

1.  Sign in to the **Exchange admin center**

2.  Under **Mail flow**, select **Rules**.

3.  Click the plus (**+**) button to create a new rule.

4.  Select **Modify messages…**.

5.  Give the rule an appropriate name.

6.  Under **Apply this rule if…,** select **The sender is external/internal**

7.  Under **select sender location**, select **Outside the organization**, then click **OK.**

8.  Under **Do the following…,** select **Prepend the subject of the message with…**.

9.  Under **specify subject prefix**, enter a message such as
    “\[External\]” (without the quotation marks), then click **OK**.

10. Click **Next**.

11. Under **Choose a mode for this rule**, select **Enforce**.

12. Leave the **Severity** as **Not Specified** and click **Next**

13. Click **Finish**.

## 8. Data Loss Prevention Solutions

Data loss prevention (DLP) helps prevent both accidental leakage of
sensitive information as well as intentional exfiltration of data. DLP
forms an integral part of securing Microsoft Exchange Online. There are
several commercial DLP solutions available that document support for
M365. Agencies may select any service that fits their needs and meets
the requirements outlined in this baseline setting.

Microsoft offers DLP services, controlled within the Microsoft Purview
compliance portal. Though use of Microsoft’s DLP solution is not strictly
required, guidance for configuring Microsoft’s DLP solution can be found in the
[Data Loss Prevention](https://github.com/cisagov/ScubaGear/blob/main/baselines/defender.md#4-data-loss-prevention) section of the [Defender for Office 365 Minimum Viable Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/baselines/defender.md). The DLP solution selected by an agency should offer services comparable
to those offered by Microsoft.

### Policies

#### MS.EXO.8.1v1
A DLP solution SHALL be used. The selected DLP solution SHOULD offer services comparable to the native DLP solution offered by Microsoft.

- _Rationale:_ Users may inadvertently disclose sensitive information to unauthorized individuals. A capable DLP solution should detect the presence of sensitive information in Exchange Online and block access to authorized entities.
- _Last modified:_ June 2023

#### MS.EXO.8.2v1
The DLP solution SHALL protect PII and sensitive information, as defined by the agency. At a minimum, the sharing of credit card numbers, Taxpayer Identification Numbers (TIN), and Social Security Numbers (SSN) via email SHALL be restricted.

- _Rationale:_ Users may inadvertently share sensitive information with others who should not have access to it. Data loss prevention policies provide a way for agencies to detect and prevent unauthorized disclosures.
- _Last modified:_ June 2023

### Resources

- The [Data Loss Prevention](https://github.com/cisagov/ScubaGear/blob/main/baselines/defender.md#4-data-loss-prevention) section of the [Defender for Office 365 Minimum Viable Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/baselines/defender.md).

## 9. Attachment File Type

For some types of files (e.g., executable files), the dangers of
allowing them to be sent over email outweigh any potential benefits.
Some services, such as the Common Attachment Filter of Microsoft
Defender, filter emails based on the attachment file types. Use of
Microsoft Defender for this purpose is not strictly required; instead,
equivalent products that fulfill the requirements outlined in this
baseline setting may be used.

Though use of Microsoft Defender’s solution is not strictly required for
this purpose, guidance for configuring the Common Attachment Filter in
Microsoft Defender can be found in the [Preset Security Policies](https://github.com/cisagov/ScubaGear/blob/emerald/baselines/defender.md#baseline) section of the [Defender for Office 365 Minimum Viable Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/baselines/defender.md). The solution selected by an agency should offer services comparable to those offered by Microsoft.

### Policies

#### MS.EXO.9.1v1
Emails SHALL be filtered by the file types of included attachments. The selected filtering solution SHOULD offer services comparable to Microsoft Defender's Common Attachment Filter.

- _Rationale:_ Malicious attachments often take the form of click-to-run files.
Sharing of high risk file types, when necessary, is better left to a means other
than email; the dangers of allowing them to be sent over email outweigh
any potential benefits. Filtering email attachment based on file types can
prevent the spread of malware distributed via click-to-run email attachments.
- _Last modified:_ June 2023

#### MS.EXO.9.2v1
The attachment filter SHOULD attempt to determine the true file type and assess the file extension.

- _Rationale:_ Users have the ability to change a file extension at the end of a
file name (e.g., notepad.exe to notepad.txt) to obscure the actual file type.
Performing checks to verify the file type and whether it matches the designated
file extension can help detect instances where the file extension has been changed.
- _Last modified:_ June 2023

#### MS.EXO.9.3v1
Disallowed file types SHALL be determined and set. At a minimum, click-to-run files SHOULD be blocked (e.g., .exe, .cmd, and .vbe).
- _Rationale:_ Malicious attachments often take the form of click-to-run files,
though other file types can contain malicious content as well. As such, the
determination of the full list of file types to block is left to each
organization, to be made in accordance with their risk tolerance.
- _Last modified:_ June 2023

### Resources

- The [Preset Security Policies](https://github.com/cisagov/ScubaGear/blob/emerald/baselines/defender.md#baseline) section of the [Defender for Office 365 Minimum Viable Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/baselines/defender.md).

## 10. Malware

Though any product that fills the requirements outlined in this baseline
setting may be used, for guidance on implementing malware scanning using
Microsoft Defender, see the following policies of the [Defender for Office 365 Minimum Viable Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/baselines/defender.md)

- [MS.DEFENDER.1.2v1](https://github.com/cisagov/ScubaGear/blob/emerald/baselines/defender.md#msdefender12v1)
  - All users SHALL be added to Exchange Online Protection in either the standard or strict preset security policy.

- [MS.DEFENDER.1.3v1](https://github.com/cisagov/ScubaGear/blob/emerald/baselines/defender.md#msdefender13v1)
  - All users SHALL be added to Defender for Office 365 Protection in either the standard or strict preset security policy.

### Policies

#### MS.EXO.10.1v1
Emails SHALL be scanned for malware.

- _Rationale:_ Email can be used as a mechanism for delivering malware.
In many cases, malware can be detected through scanning, reducing
the risk for end users.
- _Last modified:_ June 2023

#### MS.EXO.10.2v1
Emails identified as containing malware SHALL be quarantined or dropped.

- _Rationale:_ Email can be used as a mechanism for delivering malware.
Preventing emails with known malware from reaching user mailboxes ensures
users cannot interact with those emails.
- _Last modified:_ June 2023

#### MS.EXO.10.3v1
Email scanning SHOULD be capable of reviewing emails after delivery.

- _Rationale:_ As known malware signatures are updated, it is possible
for an email to be retroactively identified as containing malware after
delivery. By scanning emails in cases like this, the number of emails
containing malware in any given user's mailbox can be reduced.
- _Last modified:_ June 2023

### Resources

- [MS.DEFENDER.1.2v1](https://github.com/cisagov/ScubaGear/blob/emerald/baselines/defender.md#msdefender12v1) `All users SHALL be added to Exchange Online Protection in either the standard or strict preset security policy` policy of the [Defender for Office 365 Minimum Viable Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/baselines/defender.md).

- [MS.DEFENDER.1.3v1](https://github.com/cisagov/ScubaGear/blob/emerald/baselines/defender.md#msdefender13v1) `All users SHALL be added to Defender for Office 365 Protection in either the standard or strict preset security policy` policy of the [Defender for Office 365 Minimum Viable Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/baselines/defender.md)

## 11. Phishing Protections

Several techniques exist for protecting against phishing attacks,
including the following techniques:

- Impersonation protection checks, wherein a tool compares the sender’s
  address to the addresses of known senders to flag look-alike
  addresses, like <user@exmple.com> and <user@example.com>

- User warnings, such as displaying a notice the first time a user
  receives an email from a new sender

- AI-based tools

Microsoft Defender has capabilities for all of these phishing
protections. And except for impersonation protection, these features are
available with Exchange Online Protection (EOP), which is included in all
Microsoft 365 subscriptions that contain Exchange Online mailboxes.
For more guidance on configuring phishing protections with Microsoft’s native solutions,
see the [Preset Security Policies](https://github.com/cisagov/ScubaGear/blob/emerald/baselines/defender.md#baseline) and [Impersonation Protection](https://github.com/cisagov/ScubaGear/blob/emerald/baselines/defender.md#2-impersonation-protection) sections of the [Defender for Office 365 Minimum Viable Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/baselines/defender.md).

### Policies

#### MS.EXO.11.1v1
Impersonation protection checks SHOULD be used.

- _Rationale:_ Users might not be able to reliably identify phishing emails, especially
if the `FROM` address is nearly indistinguishable from that of a known entity.
By automatically identifying senders that appear to be impersonating known
senders, the risk of a successful phishing attempt can be reduced.
- _Last modified:_ June 2023

#### MS.EXO.11.2v1
User warnings, comparable to the user safety tips included with EOP, SHOULD be displayed.

- _Rationale:_ Many tasks are better suited for automated processes, such as identifying
unusual characters in the `FROM` address or identifying a first-time sender.
User warnings can handle these tasks, reducing the burden on end users and the risk of
successful phishing attempts.
- _Last modified:_ June 2023

#### MS.EXO.11.3v1
The phishing protection solution SHOULD include an AI-based phishing detection tool comparable to EOP Mailbox Intelligence.

- _Rationale:_ Phishing attacks can result in a unauthorized data disclosure and unauthorized access. Using AI-based phishing detection tools to improve the detection rate of phishing attempts helps reduce the risk of successful phishing attacks.
- _Last modified:_ June 2023

### Resources

- [MS.DEFENDER.1.2v1](https://github.com/cisagov/ScubaGear/blob/emerald/baselines/defender.md#msdefender12v1) `All users SHALL be added to Exchange Online Protection in either the standard or strict preset security policy` policy of the [Defender for Office 365 Minimum Viable Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/baselines/defender.md).

- [Impersonation Protection](https://github.com/cisagov/ScubaGear/blob/emerald/baselines/defender.md#2-impersonation-protection) section of the [Defender for Office 365 Minimum Viable Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/baselines/defender.md).

## 12. IP Allow Lists

Microsoft Defender supports the creations of IP “allow lists,” intended
to ensure that emails from *specific* senders are not blocked. However,
as a result, emails from these senders bypass important security
mechanisms, such as spam filtering, SPF, DKIM, DMARC, and [FROM address
enforcement](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/anti-phishing-from-email-address-validation?view=o365-worldwide#override-from-address-enforcement).

IP “block lists” ensure that mail from these IP addresses is always
blocked. Although we have no specific guidance on which IP addresses to
add, block lists can be used to block mail from known spammers.

IP “safe lists” is a dynamic list of “known, good senders,” which
Microsoft sources from various third-party subscriptions. As with
senders in the allow list, emails from these senders bypass important
security mechanisms.

### Policies

#### MS.EXO.12.1v1
IP allow lists SHOULD NOT be created.

- _Rationale:_ Messages sent from IP addresses on an allow list bypass important
security mechanisms, including spam filtering and sender authentication checks.  Avoiding use of IP allow lists prevents potential threats from circumventing security mechanisms.
- _Last modified:_ June 2023

#### MS.EXO.12.2v1
Safe lists SHOULD NOT be enabled.

- _Rationale:_ Messages sent from allowed safe list addresses bypass important
security mechanisms, including spam filtering and sender authentication checks.  Avoiding use of safe lists prevents potential threats from circumventing security mechanisms.
- _Last modified:_ June 2023

#### MS.EXO.12.3v1
A connection filter MAY be implemented to create an IP Block list.

- _Rationale:_ While blocking all malicious senders is not feasible,
blocking specific known, malicious IP addresses may reduce the threat from
specific senders.
- _Last modified:_ June 2023

### Resources

- [Use the IP Allow List \| Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/create-safe-sender-lists-in-office-365?view=o365-worldwide#use-the-ip-allow-list)

- [Configure connection filtering \| Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/connection-filter-policies-configure?view=o365-worldwide)

- [Use the Microsoft 365 Defender portal to modify the default
  connection filter policy \| Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/connection-filter-policies-configure?view=o365-worldwide#use-the-microsoft-365-defender-portal-to-modify-the-default-connection-filter-policy)

### License Requirements

- Exchange Online Protection

### Implementation

#### MS.EXO.12.1v1 instructions:
To modify the connection filters, follow the instructions found on [Use
the Microsoft 365 Defender portal to modify the default connection
filter
policy](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/connection-filter-policies-configure?view=o365-worldwide#use-the-microsoft-365-defender-portal-to-modify-the-default-connection-filter-policy).

1.  Sign in to [Microsoft 365 Defender portal](https://learn.microsoft.com/en-us/microsoft-365/security/defender/usgov?view=o365-worldwide#portal-urls).

2.  From the left-hand menu, find **Email & collaboration** and select **Policies and Rules**

3.  Select **Threat Policies** from the list of policy names.

4.  Under **Policies**, select **Anti-spam.**

5.  Select **Connection filter policy (Default).**

6.  Click **Edit connection filter policy.**

7.  Ensure no addresses are specified under **Always allow messages from
    the following IP addresses or address range**.

8.  Enter addresses under **Always block messages from the following IP
    addresses or address range** as needed.

9.  Ensure **Turn on safe list** is not selected.

#### MS.EXO.12.2v1 instructions:

1. Refer to step 7 in [MS.EXO.12.1v1 instructions](#msexo121v1-instructions) to implement
this policy.

#### MS.EXO.12.3v1 instructions:
1. Divert from step 4 in [MS.EXO.12.1v1 instructions](#msexo121v1-instructions) to implement
this policy.


## 13. Mailbox Auditing

Mailbox auditing helps users investigate compromised accounts or
discover illicit access to Exchange Online. Some actions performed by
administrators, delegates, and owners are logged automatically. While
mailbox auditing is enabled by default, agencies should ensure that it
has not been inadvertently disabled.

### Policies

#### MS.EXO.13.1v1
Mailbox auditing SHALL be enabled.

- _Rationale:_ Exchange online user accounts may be compromised or misused in some cases. Enabling mailbox auditing provides a valuable source of information to detect and respond to mailbox misuse.
- _Last modified:_ June 2023

### Resources

- [Manage mailbox auditing in Office 365 \| Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoft-365/compliance/audit-mailboxes?view=o365-worldwide)

- [Supported mailbox types \| Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoft-365/compliance/audit-mailboxes?view=o365-worldwide&viewFallbackFrom=o365-worldwide%22%20%5Cl%20%22supported-mailbox-types)

- [Microsoft Purview Compliance Manager - Microsoft 365 Compliance \|Microsoft
  Learn](https://learn.microsoft.com/en-us/microsoft-365/compliance/compliance-manager?view=o365-worldwide)

### License Requirements

- N/A

### Implementation

#### MS.EXO.13.1v1 instructions:

Mailbox auditing can be managed from the Exchange Online PowerShell.
Follow the instructions listed on [Manage mailbox auditing in Office
365](https://learn.microsoft.com/en-us/microsoft-365/compliance/audit-mailboxes?view=o365-worldwide).

To check the current mailbox auditing status for your organization via PowerShell:

1.  Connect to the Exchange Online PowerShell.

2.  Run the following command:

    `Get-OrganizationConfig | Format-List AuditDisabled`

3.  An `AuditDisabled : False` result indicates that mailbox auditing is enabled.

To enable mailbox auditing by default for your organization via PowerShell:

1.  Connect to the Exchange Online PowerShell

2.  Run the following command:

    `Set-OrganizationConfig –AuditDisabled $false`

## 14. Inbound Anti-Spam Protections

Microsoft Defender includes several capabilities for protecting against
inbound spam emails. Use of Microsoft Defender is not strictly required
for this purpose; any product that fulfills the requirements outlined in
this baseline setting may be used. See the - [MS.DEFENDER.1.2v1](https://github.com/cisagov/ScubaGear/blob/emerald/baselines/defender.md#msdefender12v1) `All users SHALL be added to Exchange Online Protection in either the standard or strict preset security policy` policy of the [Defender for Office 365 Minimum Viable Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/baselines/defender.md) for additional guidance.

### Policies

#### MS.EXO.14.1v1
A spam filter SHALL be enabled. The filtering solution selected SHOULD offer services comparable to the native spam filtering offered by Microsoft.

- _Rationale:_ Spam is a constant threat as junk mail can reduce user productivity, fill up mailboxes unnecessarily, and in some cases include malicious links or attachments.
Filtering out spam reduces the workload burden on users, prevents filling up user mailboxes with junk mail, and reduces exposure to potentially malicious content.
- _Last modified:_ June 2023

#### MS.EXO.14.2v1
Spam and high confidence spam SHALL be moved to either the junk email folder or the quarantine folder.

- _Rationale:_ Spam is a constant threat as junk mail can reduce user productivity, fill up mailboxes unnecessarily, and in some cases include malicious links or attachments.
Moving spam messages to a separate junk or quarantine folder helps users filter out spam while still giving them the ability to review messages, as needed, in case a message is filtered incorrectly.
- _Last modified:_ June 2023

#### MS.EXO.14.3v1
Allowed senders MAY be added, but allowed domains SHALL NOT be added.

- _Rationale:_ Legitimate emails may be incorrectly filtered
by spam protections. Adding allowed senders is an acceptable method of combating
these false positives. Allowing an entire domain, especially
a common domain like office.com, however, provides for a large number of
potentially unknown users to bypass spam protections.
- _Last modified:_ June 2023

### Resources

- [MS.DEFENDER.1.2v1](https://github.com/cisagov/ScubaGear/blob/emerald/baselines/defender.md#msdefender12v1) `All users SHALL be added to Exchange Online Protection in either the standard or strict preset security policy` policy of the [Defender for Office 365 Minimum Viable Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/baselines/defender.md).

## 15. Link Protection

Several technologies exist for protecting users from malicious links
included in emails. For example, Microsoft Defender accomplishes this by
prepending

`https://*.safelinks.protection.outlook.com/?url=`

to any URLs included in emails. By prepending the safe links URL,
Microsoft can proxy the initial URL through their scanning service.
Their proxy can perform the following actions:

- Compare the URL with a block list,

- Compare the URL with a list of know malicious sites, and

- If the URL points to a downloadable file, apply real-time file
  scanning.

If all checks pass, the user is redirected to the original URL.

Though Defender’s use is not strictly required for this purpose,
guidance for enabling link scanning using Microsoft Defender is included
in the [MS.DEFENDER.1.3v1](https://github.com/cisagov/ScubaGear/blob/emerald/baselines/defender.md#msdefender13v1) `All users SHALL be added to Defender for Office 365 Protection in either the standard or strict preset security policy` policy of the [Defender for Office 365 Minimum Viable Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/baselines/defender.md)

### Policies

#### MS.EXO.15.1v1
URL comparison with a block-list SHOULD be enabled.

- _Rationale:_ Users may be directed to malicious websites via links in email. Blocking access to known, malicious URLs can prevent users from accessing known malicious websites.
- _Last modified:_ June 2023

#### MS.EXO.15.2v1
Direct download links SHOULD be scanned for malware.

- _Rationale:_ URLs in emails may direct users to download and run malware.
Scanning direct download links in real-time for known malware and blocking access can prevent
users from infecting their devices.
- _Last modified:_ June 2023

#### MS.EXO.15.3v1
User click tracking SHOULD be enabled.

- _Rationale:_ Users may click on malicious links in emails, leading to compromise or authorized data disclosure.  Enabling user click tracking lets agencies know if a malicious link may have been visited after the fact to help tailor a response to a potential incident.
- _Last modified:_ June 2023

### Resources

- [MS.DEFENDER.1.3v1](https://github.com/cisagov/ScubaGear/blob/emerald/baselines/defender.md#msdefender13v1) `All users SHALL be added to Defender for Office 365 Protection in either the standard or strict preset security policy` policy of the [Defender for Office 365 Minimum Viable Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/baselines/defender.md)

## 16. Alerts

Microsoft Defender includes several prebuilt alert policies, many of
which pertain to Exchange Online. These alerts give admins better
real-time insight into possible security incidents. Guidance for
configuring alerts in Microsoft Defender is given in the [Alerts](https://github.com/cisagov/ScubaGear/blob/emerald/baselines/defender.md#5-alerts) section of the [Defender for Office 365 Minimum Viable Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/baselines/defender.md)

### Policies

#### MS.EXO.16.1v1
At a minimum, the following alerts SHALL be enabled:

  - Suspicious email sending patterns detected.

  - Suspicious Connector Activity.

  - Suspicious Email Forwarding Activity.

  - Messages have been delayed.

  - Tenant restricted from sending unprovisioned email.

  - Tenant restricted from sending email.

  - A potentially malicious URL click was detected.

- _Rationale:_ Potentially malicious or service impacting events may go undetected
without a means of detecting these events.  Setting up a mechanism to alert
administrators to the list of events above draws attention to them to ensure that any
impact to users and the agency are minimized.
- _Last modified:_ June 2023

#### MS.EXO.16.2v1
The alerts SHOULD be sent to a monitored address or incorporated into a SIEM.

- _Rationale:_ Suspicious or malicious events, if not resolved promptly, may have a greater impact to users and the agency.  Sending alerts to a monitored email address or SIEM helps ensure it is acted upon in a timely manner to limit overall impact.
- _Last modified:_ June 2023

### Resources

- The [Alerts](https://github.com/cisagov/ScubaGear/blob/emerald/baselines/defender.md#5-alerts) section of the [Defender for Office 365 Minimum Viable Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/baselines/defender.md).

## 17. Microsoft Purview Audit

Unified audit logging generates logs of user activity in M365 services.
These logs are essential for conducting incident response and threat detection activity.

By default, Microsoft retains the audit logs for only 90 days. Activity by users with E5 licenses is logged for one year.

However, per OMB M-21-31, Microsoft 365 audit logs are to be retained at least 12 months in active storage and an additional 18 months in cold storage.
This can be accomplished either by offloading the logs out of the cloud environment or natively through Microsoft by creating an audit log retention policy.

OMB M-21-13 also requires Advanced Audit be configured in M365. Advanced Audit adds additional event types to the Unified Audit Log.

Audit logging is managed from the Microsoft Purview compliance center. For
guidance configuring audit logging, see the [Microsoft Purview Audit](https://github.com/cisagov/ScubaGear/blob/emerald/baselines/defender.md#6-microsoft-purview-audit) section of the [Defender for Office 365 Minimum Viable Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/baselines/defender.md).

### Policies

#### MS.EXO.17.1v1
Microsoft Purview Audit (Standard) logging SHALL be enabled.

- _Rationale:_ Responding to incidents without detailed information about
activities that took place slows response actions.  Enabling Microsoft
Purview Audit (Standard) helps ensure agencies have visibility into user
actions. Furthermore, Microsoft Purview Audit (Standard) is required for
government agencies by OMB M-21-31 (referred to therein by its former
name, Unified Audit Logs).
- _Last modified:_ June 2023

#### MS.EXO.17.2v1
Microsoft Purview Audit (Premium) logging SHALL be enabled.

- _Rationale:_ Standard logging may not include relevant details necessary for
visibility into user actions during an incident.  Enabling Microsoft Purview Audit
(Premium) captures additional event types that are not included with Standard.
Furthermore, it is required for government agencies by OMB M-21-13 (referred to therein as by its former name, Unified Audit Logs w/ Advanced Features).
- _Last modified:_ June 2023

#### MS.EXO.17.3v1
Audit logs SHALL be maintained for at least the minimum duration dictated by [OMB M-21-31 (Appendix C)](https://www.whitehouse.gov/wp-content/uploads/2021/08/M-21-31-Improving-the-Federal-Governments-Investigative-and-Remediation-Capabilities-Related-to-Cybersecurity-Incidents.pdf).
- _Rationale:_ Audit logs may no longer be available at the time of need if they are not retained for a sufficient period of time.  Increased log retention time gives an agency the necessary visibility
to investigate incidents that occurred some time ago.
- _Last modified:_ June 2023

### Resources

- [Microsoft Purview Audit](https://github.com/cisagov/ScubaGear/blob/emerald/baselines/defender.md#6-microsoft-purview-audit) section of the [Defender for Office 365 Minimum Viable Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/baselines/defender.md).


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
