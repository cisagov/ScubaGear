**`TLP:CLEAR`**

# CISA M365 Secure Configuration Baseline for Exchange Online

Microsoft 365 (M365) Exchange Online is a cloud-based messaging platform that gives users easy access to their email and supports organizational meetings, contacts, and calendars. This Secure Configuration Baseline (SCB) provides specific policies to strengthen Exchange Online security.

Many admin controls for Exchange Online are found in the **Exchange admin center**.
However, several essential security functions for Exchange Online require a dedicated security
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

Portions of this document are adapted from documents in Microsoft's
[M365](https://github.com/MicrosoftDocs/microsoft-365-docs/blob/public/LICENSE)
and
[Azure](https://github.com/MicrosoftDocs/azure-docs/blob/main/LICENSE)
GitHub repositories. The respective documents are subject to copyright
and are adapted under the terms of the Creative Commons Attribution 4.0
International license. Sources are linked throughout this
document. The United States government has adapted selections of these
documents to develop innovative and scalable configuration standards to
strengthen the security of widely used cloud-based software services.

## Assumptions

The **License Requirements** sections of this document assume the
organization is using an [M365
E3](https://www.microsoft.com/en-us/microsoft-365/compare-microsoft-365-enterprise-plans)
or [G3](https://www.microsoft.com/en-us/microsoft-365/government)
license level at a minimum. Therefore, only licenses not included in E3/G3 are
listed.

## Key Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in
[RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

**BOD 25-01 Requirement**: This indicator means that the policy is required under CISA BOD 25-01.

**Automated Check**: This indicator means that the policy can be automatically checked via ScubaGear. See the [Quick Start Guide](../../../README.md#quick-start-guide) for help getting started.

**Configurable**: This indicator means that the policy can be customized via config file.

**Manual**: This indicator means that the policy requires manual verification of configuration settings.

# Baseline Policies

## 1. Automatic Forwarding to External Domains

This control is intended to prevent bad actors from using client-side
forwarding rules to exfiltrate data to external recipients.

### Policies

#### MS.EXO.1.1v2
Automatic forwarding to external domains SHALL be disabled.

[![BOD 25-01 Requirement](https://img.shields.io/badge/BOD_25--01_Requirement-C41230)](https://www.cisa.gov/news-events/directives/bod-25-01-implementation-guidance-implementing-secure-practices-cloud-services)
[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)
[![Configurable](https://img.shields.io/badge/Configurable-005288)](../../../docs/configuration/configuration.md#automatic-forwarding-to-remote-domains)

<!--Policy: MS.EXO.1.1v2; Criticality: SHALL -->
<!--ExclusionType: AllowedForwardingDomains-->
- _Rationale:_ Adversaries can use automatic forwarding to gain
persistent access to a victim's email. Disabling forwarding to
external domains prevents this technique when the adversary is
external to the organization but does not impede legitimate
internal forwarding.
- _Last modified:_ March 2025
- _Note:_ Automatic forwarding MAY be enabled with specific, agency-approved domains.
There may be cases where an external domain is operationally needed and has an acceptable
degree of risk, e.g., a domain controlled by the same agency that hasn't been added
as an accepted domain in M365.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-4
- _MITRE ATT&CK TTP Mapping:_
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
  - [T1048: Exfiltration Over Alternative Protocol](https://attack.mitre.org/techniques/T1048/)
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)
    - [T1566.001: Spearphishing Attachment](https://attack.mitre.org/techniques/T1566/001/)

### Resources

- [Reducing or increasing information flow to another company \|
  Microsoft
  Learn](https://learn.microsoft.com/en-us/exchange/mail-flow-best-practices/remote-domains/remote-domains#reducing-or-increasing-information-flow-to-another-company)

### License Requirements

- N/A

### Implementation

#### MS.EXO.1.1v2 Instructions
To disallow automatic forwarding to external domains:

1.  Sign in to the **Exchange admin center**.

2.  Select **Mail flow**, then **Remote domains**.

3.  Select **Default**.

4.  Under **Email reply types**, select **Edit reply types**.

5.  Clear the checkbox next to **Allow automatic forwarding**, then
    click **Save**.

6.  Return to **Remote domains** and review each
    additional remote domain in the list, ensuring that automatic forwarding
    is only allowed for approved domains.

## 2. Sender Policy Framework

The Sender Policy Framework (SPF) is a mechanism allowing domain
administrators to specify which IP addresses are explicitly approved to
send email on behalf of the domain, facilitating detection of spoofed
emails. SPF is not configured through the Exchange admin center, but
rather via Domain Name System (DNS) records hosted by the agency's
domain. Thus, the exact steps needed to set up SPF vary from agency to
agency, but Microsoft's documentation provides some helpful starting
points.

### Policies

#### MS.EXO.2.2v3
An SPF policy SHALL be published for each domain that fails all non-approved senders.

[![BOD 25-01 Requirement](https://img.shields.io/badge/BOD_25--01_Requirement-C41230)](https://www.cisa.gov/news-events/directives/bod-25-01-implementation-guidance-implementing-secure-practices-cloud-services)
[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)
[![Configurable](https://img.shields.io/badge/Configurable-005288)](../../../docs/configuration/parameters.md#preferreddnsresolvers)

<!--Policy: MS.EXO.2.2v3; Criticality: SHALL -->
- _Rationale:_ An adversary may modify the `FROM` field
of an email such that it appears to be a legitimate email sent by an
agency, facilitating phishing attacks. Publishing an SPF policy for each agency domain mitigates forged `FROM` fields by providing a means for recipients to detect emails spoofed in this way.  SPF is required for FCEB departments and agencies by Binding Operational Directive (BOD) 18-01, "Enhance Email and Web Security".
- _Last modified:_ October 2025
- _Note:_ SPF defines two different "fail" mechanisms: fail (indicated by `-`, sometimes referred to as hardfail) and softfail (indicated by `~`). Either hard or soft fail may be used to comply with this baseline policy.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-2d
- _MITRE ATT&CK TTP Mapping:_
  - [T1656: Impersonation](https://attack.mitre.org/techniques/T1656/)
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)


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

#### MS.EXO.2.2v3 Instructions
First, identify any approved senders specific to your agency, e.g., any on-premises mail servers. SPF allows you to indicate approved senders by IP address or CIDR range. However, note that SPF allows you to [include](https://www.rfc-editor.org/rfc/rfc7208#section-5.2) the IP addresses indicated by a separate SPF policy, referred to by domain name. See [External DNS records required for SPF](https://learn.microsoft.com/en-us/microsoft-365/enterprise/external-domain-name-system-records?view=o365-worldwide#external-dns-records-required-for-spf) for inclusions required for M365 to send email on behalf of your domain.

SPF is not configured through the Exchange admin center, but rather via
DNS records hosted by the agency's domain. Thus, the exact steps needed
to set up SPF varies from agency to agency. See [Add or edit an SPF TXT record to help prevent email spam (Outlook, Exchange Online) \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-365/admin/get-help-with-domains/create-dns-records-at-any-dns-hosting-provider?view=o365-worldwide#add-or-edit-an-spf-txt-record-to-help-prevent-email-spam-outlook-exchange-online) for more details.

To test your SPF configuration, consider using a web-based tool, such as
those listed under [How can I validate SPF records for my domain? \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-365/admin/setup/domains-faq?view=o365-worldwide#how-can-i-validate-spf-records-for-my-domain).
Additionally, SPF records can be requested using the
PowerShell tool `Resolve-DnsName`. For example:

```
Resolve-DnsName example.onmicrosoft.com txt
```

If SPF is configured, you will see a response resembling `v=spf1 include:spf.protection.outlook.com -all`
returned; though by necessity, the contents of the SPF
policy may vary by agency. In this example, the SPF policy indicates
the IP addresses listed by the policy for "spf.protection.outlook.com" are
the only approved senders for "example.onmicrosoft.com." These IPs can be determined
via an additional SPF lookup, this time for "spf.protection.outlook.com." Ensure the IP addresses listed as approved senders for your domains are correct. Additionally, ensure that each policy either ends in `-all` or `~all` or [redirects](https://www.rfc-editor.org/rfc/rfc7208#section-6.1) to one that does; these directives indicates that all IPs that don't match the policy should fail. See [SPF TXT record syntax for Microsoft 365 \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/email-authentication-anti-spoofing?view=o365-worldwide#spf-txt-record-syntax-for-microsoft-365) for a more in-depth discussion
of SPF record syntax.

## 3. DomainKeys Identified Mail

DomainKeys Identified Mail (DKIM) allows digital signatures to be added
to email messages in the message header, providing a layer of both
authenticity and integrity to emails. As with SPF, DKIM relies on DNS
records; thus, its deployment depends on how an agency manages its DNS.
Exchange Online Protection (EOP) features include DKIM signing capabilities.

### Policies

#### MS.EXO.3.1v1
DKIM SHOULD be enabled for all domains.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)
[![Configurable](https://img.shields.io/badge/Configurable-005288)](../../../docs/configuration/parameters.md#preferreddnsresolvers)

<!--Policy: MS.EXO.3.1v1; Criticality: SHOULD -->
- _Rationale:_ An adversary may modify the `FROM` field
of an email such that it appears to be a legitimate email sent by an
agency, facilitating phishing attacks. Enabling DKIM is another means for
recipients to detect spoofed emails and verify the integrity of email content.
- _Last modified:_ June 2023
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SC-8
- _MITRE ATT&CK TTP Mapping:_
  - [T1598: Phishing for Information](https://attack.mitre.org/techniques/T1598/)
  - [T1656: Impersonation](https://attack.mitre.org/techniques/T1656/)
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)

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

- N/A

### Implementation

#### MS.EXO.3.1v1 Instructions
1. To enable DKIM, follow the instructions listed on [Steps to Create,
enable and disable DKIM from Microsoft 365 Defender portal \| Microsoft
Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/email-authentication-dkim-configure?view=o365-worldwide#steps-to-create-enable-and-disable-dkim-from-microsoft-365-defender-portal).

## 4. Domain-Based Message Authentication, Reporting, and Conformance (DMARC)
Domain-based Message Authentication, Reporting, and Conformance (DMARC)
works with SPF and DKIM to authenticate mail senders and helps ensure
destination email systems can validate messages sent from your domain.
DMARC helps receiving mail systems determine what to do with messages
sent from your domain that fail SPF and DKIM checks.

### Policies

#### MS.EXO.4.1v1
A DMARC policy SHALL be published for every second-level domain.

[![BOD 25-01 Requirement](https://img.shields.io/badge/BOD_25--01_Requirement-C41230)](https://www.cisa.gov/news-events/directives/bod-25-01-implementation-guidance-implementing-secure-practices-cloud-services)
[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)
[![Configurable](https://img.shields.io/badge/Configurable-005288)](../../../docs/configuration/parameters.md#preferreddnsresolvers)

<!--Policy: MS.EXO.4.1v1; Criticality: SHALL -->
- _Rationale:_ Without a DMARC policy available for each domain, recipients
may improperly handle SPF and DKIM failures, possibly enabling spoofed
emails to reach end users' mailboxes. Publishing DMARC records at the
second-level domain protects the second-level domains and all subdomains.
- _Last modified:_ June 2023
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-8
- _MITRE ATT&CK TTP Mapping:_
  - [T1598: Phishing for Information](https://attack.mitre.org/techniques/T1598/)
  - [T1656: Impersonation](https://attack.mitre.org/techniques/T1656/)
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)

#### MS.EXO.4.2v1
The DMARC message rejection option SHALL be p=reject.

[![BOD 25-01 Requirement](https://img.shields.io/badge/BOD_25--01_Requirement-C41230)](https://www.cisa.gov/news-events/directives/bod-25-01-implementation-guidance-implementing-secure-practices-cloud-services)
[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)
[![Configurable](https://img.shields.io/badge/Configurable-005288)](../../../docs/configuration/parameters.md#preferreddnsresolvers)

<!--Policy: MS.EXO.4.2v1; Criticality: SHALL -->
- _Rationale:_ Of the three policy options (i.e., none, quarantine, and reject),
reject provides the strongest protection. Reject is the level of protection
required by BOD 18-01 for FCEB departments and agencies.
- _Last modified:_ June 2023
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-8
- _MITRE ATT&CK TTP Mapping:_
  - [T1598: Phishing for Information](https://attack.mitre.org/techniques/T1598/)
  - [T1656: Impersonation](https://attack.mitre.org/techniques/T1656/)
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)

#### MS.EXO.4.3v1
The DMARC point of contact for aggregate reports SHALL include `reports@dmarc.cyber.dhs.gov`.

[![BOD 25-01 Requirement](https://img.shields.io/badge/BOD_25--01_Requirement-C41230)](https://www.cisa.gov/news-events/directives/bod-25-01-implementation-guidance-implementing-secure-practices-cloud-services)
[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)
[![Configurable](https://img.shields.io/badge/Configurable-005288)](../../../docs/configuration/parameters.md#preferreddnsresolvers)

<!--Policy: MS.EXO.4.3v1; Criticality: SHALL -->
- _Rationale:_ Email spoofing attempts are not inherently visible to domain
owners. DMARC provides a mechanism to receive reports of spoofing attempts.
Including <reports@dmarc.cyber.dhs.gov> as a point of contact for these reports gives CISA insight into spoofing attempts and is required by BOD 18-01 for FCEB departments and agencies.
- _Last modified:_ June 2023
- _Note:_ Only federal, executive branch, departments and agencies should
          include this email address in their DMARC record.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-4(5)
- _MITRE ATT&CK TTP Mapping:_
  - [T1562: Impair Defenses](https://attack.mitre.org/techniques/T1562/)

#### MS.EXO.4.4v1
An agency point of contact SHOULD be included for aggregate and failure reports.

[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)
[![Configurable](https://img.shields.io/badge/Configurable-005288)](../../../docs/configuration/parameters.md#preferreddnsresolvers)

<!--Policy: MS.EXO.4.4v1; Criticality: SHOULD -->
- _Rationale:_ Email spoofing attempts are not inherently visible to domain
owners. DMARC provides a mechanism to receive reports of spoofing attempts.
Including an agency point of contact gives the agency insight into attempts
to spoof their domains.
- _Last modified:_ June 2023
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-4(5)
- _MITRE ATT&CK TTP Mapping:_
  - [T1562: Impair Defenses](https://attack.mitre.org/techniques/T1562/)

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

#### MS.EXO.4.1v1 Instructions
DMARC is not configured through the Exchange admin center, but rather via
DNS records hosted by the agency's domain. As such, implementation varies
depending on how an agency manages its DNS records. See [Form the DMARC TXT record for your domain \| Microsoft
Learn](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/email-authentication-dmarc-configure?view=o365-worldwide#step-4-form-the-dmarc-txt-record-for-your-domain)
for Microsoft guidance.

A DMARC record published at the second-level domain will protect all subdomains.
In other words, a DMARC record published for `example.com` will protect both
`a.example.com` and `b.example.com`, but a separate record would need to be
published for `c.example.gov`.

To test your DMARC configuration, consider using one of many publicly available
web-based tools. Additionally, DMARC records can be requested using the
PowerShell tool `Resolve-DnsName`. For example:

```
Resolve-DnsName _dmarc.example.com txt
```

If DMARC is configured, a response resembling `v=DMARC1; p=reject; pct=100; rua=mailto:reports@dmarc.cyber.dhs.gov, mailto:reports@example.com; ruf=mailto:reports@example.com`
will be returned, though by necessity, the contents of the record will vary
by agency. In this example, the policy indicates all emails failing the
SPF/DKIM checks are to be rejected and aggregate reports sent to
reports@dmarc.cyber.dhs.gov and reports@example.com. Failure reports will be
sent to reports@example.com.

#### MS.EXO.4.2v1 Instructions
See [MS.EXO.4.1v1 Instructions](#msexo41v1-instructions) for an overview of how to publish and check a DMARC record. Ensure the record published includes `p=reject`.

#### MS.EXO.4.3v1 Instructions
See [MS.EXO.4.1v1 Instructions](#msexo41v1-instructions) for an overview of how to publish and check a DMARC record. Ensure the record published includes <reports@dmarc.cyber.dhs.gov>
as one of the emails for the RUA field.

#### MS.EXO.4.4v1 Instructions
See [MS.EXO.4.1v1 Instructions](#msexo41v1-instructions) for an overview of how to publish and check a DMARC record. Ensure the record published includes:
- A point of contact specific to your agency in the RUA field.
- <reports@dmarc.cyber.dhs.gov> as one of the emails in the RUA field.
- One or more agency-defined points of contact in the RUF field.

## 5. Simple Mail Transfer Protocol Authentication

Modern email clients that connect to Exchange Online mailboxes—including
Outlook, Outlook on the web, iOS Mail, and Outlook for iOS and
Android—do not use Simple Mail Transfer Protocol Authentication (SMTP
AUTH) to send email messages. SMTP AUTH is only needed for applications
outside of Outlook that send email messages. Multi-factor authentication
(MFA) cannot be enforced while using SMTP Auth. Proceed with caution if
SMTP Auth needs to be enabled for any use case.

### Policies

#### MS.EXO.5.1v1
SMTP AUTH SHALL be disabled.

[![BOD 25-01 Requirement](https://img.shields.io/badge/BOD_25--01_Requirement-C41230)](https://www.cisa.gov/news-events/directives/bod-25-01-implementation-guidance-implementing-secure-practices-cloud-services)
[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.EXO.5.1v1; Criticality: SHALL -->
- _Rationale:_ SMTP AUTH is not used or needed by modern email clients.
Therefore, disabling it as the global default conforms to the principle of
least functionality.
- _Last modified:_ June 2023
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ CM-7
- _MITRE ATT&CK TTP Mapping:_
  - None

### Resources

- [Enable or disable authenticated client SMTP submission (SMTP AUTH) in
  Exchange Online \| Microsoft
  Learn](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/authenticated-client-smtp-submission)

### License Requirements

- N/A

### Implementation

#### MS.EXO.5.1v1 Instructions

To disable SMTP AUTH for the organization:

1. Sign in to the **Exchange admin center**.

2. On the left hand pane, select **Settings**; then from the settings list, select **Mail Flow**.

3. Make sure the setting **Turn off SMTP AUTH protocol for your organization** is checked.

## 6. Calendar and Contact Sharing

Exchange Online allows creation of sharing polices that soften default restrictions on contact and calendar details sharing. These policies should be enabled with caution and only after considering the following policies.

### Policies

#### MS.EXO.6.1v1
Contact folders SHALL NOT be shared with all domains.

[![BOD 25-01 Requirement](https://img.shields.io/badge/BOD_25--01_Requirement-C41230)](https://www.cisa.gov/news-events/directives/bod-25-01-implementation-guidance-implementing-secure-practices-cloud-services)
[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.EXO.6.1v1; Criticality: SHALL -->
- _Rationale:_ Contact folders may contain information that should not be shared by default with all domains. Disabling sharing with all domains closes an avenue for data exfiltration while still allowing
for specific legitimate use as needed.
- _Last modified:_ June 2023
- _Note:_ Contact folders MAY be shared with specific domains.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-3, SC-7(10)(a)
- _MITRE ATT&CK TTP Mapping:_
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
  - [T1048: Exfiltration Over Alternative Protocol](https://attack.mitre.org/techniques/T1048/)


#### MS.EXO.6.2v1
Calendar details SHALL NOT be shared with all domains.

[![BOD 25-01 Requirement](https://img.shields.io/badge/BOD_25--01_Requirement-C41230)](https://www.cisa.gov/news-events/directives/bod-25-01-implementation-guidance-implementing-secure-practices-cloud-services)
[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.EXO.6.2v1; Criticality: SHALL -->
- _Rationale:_ Calendar details may contain information that should not be shared by default with all domains. Disabling sharing with all domains closes an avenue for data exfiltration while still allowing
for legitimate use as needed.
- _Last modified:_ June 2023
- _Note:_ Calendar details MAY be shared with specific domains.
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-3, SC-7(10)(a)
- _MITRE ATT&CK TTP Mapping:_
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
  - [T1048: Exfiltration Over Alternative Protocol](https://attack.mitre.org/techniques/T1048/)

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

#### MS.EXO.6.1v1 Instructions
To restrict sharing with all domains:

1. Sign in to the **Exchange admin center**.

2. On the left-hand pane under **Organization**, select **Sharing**.

3. Select **Individual Sharing**.

4. For all existing policies, select the policy, then select **Manage domains**.

5. For all sharing rules under all existing policies, ensure **Sharing with all domains** is not selected.

#### MS.EXO.6.2v1 Instructions

To restrict sharing calendar details with all domains:

1. Refer to step 5 in [MS.EXO.6.1v1 Instructions](#msexo61v1-instructions) to implement
this policy.

## 7. External Sender Warnings

Mail flow rules allow incoming email modification, such that email from external users can be easily identified (e.g., by prepending the subject line with "\[External\]").

### Policies

#### MS.EXO.7.1v1
External sender warnings SHALL be implemented.

[![BOD 25-01 Requirement](https://img.shields.io/badge/BOD_25--01_Requirement-C41230)](https://www.cisa.gov/news-events/directives/bod-25-01-implementation-guidance-implementing-secure-practices-cloud-services)
[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)


<!--Policy: MS.EXO.7.1v1; Criticality: SHALL -->
- _Rationale:_ Phishing is an ever-present threat. Alerting users when email originates from outside their organization can encourage them to exercise increased caution, especially if an email is one they expected from an internal sender.
- _Last modified:_ June 2023
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-8
- _MITRE ATT&CK TTP Mapping:_
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)

### Resources

- [Mail flow rules (transport rules) in Exchange Online \| Microsoft
  Learn](https://learn.microsoft.com/en-us/exchange/security-and-compliance/mail-flow-rules/mail-flow-rules)

- [Capacity Enhancement Guide: Counter-Phishing Recommendations for
  Federal Agencies \|
  CISA](https://www.cisa.gov/sites/default/files/publications/Capacity_Enhancement_Guide-Counter-Phishing_Recommendations_for_Federal_Agencies.pdf)

- [Actions To Counter Email-Based Attacks On Election-Related Entities
  \|
  CISA](https://www.cisa.gov/sites/default/files/publications/CISA_Insights_Actions_to_Counter_Email-Based_Attacks_on_Election-Related_S508C.pdf)

### License Requirements

- N/A

### Implementation

#### MS.EXO.7.1v1 Instructions
To create a mail flow rule to produce external sender warnings:

1.  Sign in to the **Exchange admin center**.

2.  Under **Mail flow**, select **Rules**.

3.  Click the plus (**+**) button to create a new rule.

4.  Select **Modify messages…**.

5.  Give the rule an appropriate name.

6.  Under **Apply this rule if…,** select **The sender is external/internal**.

7.  Under **select sender location**, select **Outside the organization**, then click **OK**.

8.  Under **Do the following…,** select **Prepend the subject of the message with…**.

9.  Under **specify subject prefix**, enter a message such as
    "\[External\]" (without the quotation marks), then click **OK**.

10. Click **Next**.

11. Under **Choose a mode for this rule**, select **Enforce**.

12. Leave the **Severity** as **Not Specified**.

13. Leave the **Match sender address in message** as **Header** and click **Next**.

14. Click **Finish** and then **Done**.

15. The new rule will be disabled.  Re-select the new rule to show its
    settings and slide the **Enable or disable rule** slider to the right
    until it shows as **Enabled**.

## 13. Mailbox Auditing

Mailbox auditing helps users investigate compromised accounts or
discover illicit access to Exchange Online. As a feature of Exchange
Online, mailbox auditing is enabled by default for all organizations.
Microsoft defines a default audit policy that logs certain actions
performed by administrators, delegates, and owners. While mailbox auditing is enabled by default,
this policy helps avoid inadvertent disabling.
### Policies

#### MS.EXO.13.1v1
Mailbox auditing SHALL be enabled.

[![BOD 25-01 Requirement](https://img.shields.io/badge/BOD_25--01_Requirement-C41230)](https://www.cisa.gov/news-events/directives/bod-25-01-implementation-guidance-implementing-secure-practices-cloud-services)
[![Automated Check](https://img.shields.io/badge/Automated_Check-5E9732)](#key-terminology)

<!--Policy: MS.EXO.13.1v1; Criticality: SHALL -->
- _Rationale:_ Exchange Online user accounts can be compromised or misused. Enabling mailbox auditing provides a valuable source of information to detect and respond to mailbox misuse.
- _Last modified:_ June 2023
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AU-12c
- _MITRE ATT&CK TTP Mapping:_
  - [T1070: Indicator Removal](https://attack.mitre.org/techniques/T1070/)
    - [T1070.008: Clear Mailbox Data](https://attack.mitre.org/techniques/T1070/008/)
  - [T1098: Account Manipulation](https://attack.mitre.org/techniques/T1098/)
    - [T1098.002: Additional Email Delegate Permissions](https://attack.mitre.org/techniques/T1098/002/)
  - [T1562: Impair Defenses](https://attack.mitre.org/techniques/T1562/)
    - [T1562.008: Disable or Modify Cloud Logs](https://attack.mitre.org/techniques/T1562/008/)
  - [T1586: Compromise Accounts](https://attack.mitre.org/techniques/T1586/)
    - [T1586.002: Email Accounts](https://attack.mitre.org/techniques/T1586/002/)
  - [T1564: Hide Artifacts](https://attack.mitre.org/techniques/T1564/)
  - [T1564.008: Email Hiding Rules](https://attack.mitre.org/techniques/T1564/008/)

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

#### MS.EXO.13.1v1 Instructions

Mailbox auditing can be managed from the Exchange Online PowerShell.
Follow the instructions listed on [Manage mailbox auditing in Office
365](https://learn.microsoft.com/en-us/microsoft-365/compliance/audit-mailboxes?view=o365-worldwide).

To check the current mailbox auditing status for your organization via PowerShell:

1.  Connect to the Exchange Online PowerShell.

2.  Run the following command:

    `Get-OrganizationConfig | Format-List AuditDisabled`

3.  An `AuditDisabled : False` result indicates mailbox auditing is enabled.

To enable mailbox auditing by default for your organization via PowerShell:

1.  Connect to the Exchange Online PowerShell.

2.  Run the following command:

    `Set-OrganizationConfig –AuditDisabled $false`


**`TLP:CLEAR`**
