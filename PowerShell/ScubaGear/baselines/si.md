**`TLP:CLEAR`**

# CISA M365 Secure Configuration Baseline for Super Intelligence (SI) / SI Agents capabilities

TBD - Description of Super Intelligence (SI) and SI Agents capabilities in Microsoft 365 (M365). This Secure Configuration Baseline (SCB) provides specific policies to help secure SI and SI Agents capabilities, including related settings that are configured in other M365 admin centers (for example, Microsoft Entra Conditional Access policies and Microsoft Purview data loss prevention policies).

The Cybersecurity and Infrastructure Security Agency's (CISA) Secure Cloud Business Applications (SCuBA) project provides guidance and capabilities to secure federal civilian executive branch (FCEB) agencies' cloud business application environments and protect federal information that is created, accessed, shared, and stored in those environments.

The CISA SCuBA SCBs for M365 help secure federal information assets stored within M365 cloud business application environments through consistent, effective, and manageable security configurations. CISA created baselines tailored to the federal government’s threats and risk tolerance with the knowledge that every organization has different threat models and risk tolerance. While use of these baselines will be mandatory for civilian federal government agencies, organizations outside of the federal government may also find these baselines to be useful references to help reduce risks.

For non-federal users, the information in this document is being provided "as is" for INFORMATIONAL PURPOSES ONLY. CISA does not endorse any commercial product or service, including any subjects of analysis. Any reference to specific commercial entities or commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply endorsement, recommendation, or favoritism by CISA. Without limiting the generality of the foregoing, some controls and settings are not available in all products. CISA has no control over vendor changes to products offerings or features. Accordingly, these SCuBA SCBs for M365 may not be applicable to the products available to you. This document does not address, ensure compliance with, or supersede any law, regulation, or other authority. Entities are responsible for complying with any recordkeeping, privacy, and other laws that may apply to the use of technology. This document is not intended to, and does not, create any right or benefit for anyone against the United States, its departments, agencies, or entities, its officers, employees, or agents, or any other person.

> This document is marked TLP:CLEAR. Recipients may share this information without restriction. Information is subject to standard copyright rules. For more information on the Traffic Light Protocol, see https://www.cisa.gov/tlp.

## License Compliance and Copyright
Portions of this document are adapted from documents in Microsoft’s [M365](https://github.com/MicrosoftDocs/microsoft-365-docs/blob/public/LICENSE) and [Azure](https://github.com/MicrosoftDocs/azure-docs/blob/main/LICENSE) GitHub repositories. The respective documents are subject to copyright and are adapted under the terms of the Creative Commons Attribution 4.0 International license. Sources are linked throughout this document. The United States government has adapted selections of these documents to develop innovative and scalable configuration standards to strengthen the security of widely used cloud-based software services.

## Assumptions
The **License Requirements** sections of this document assume the organization is using an [M365 E3](https://www.microsoft.com/en-us/microsoft-365/compare-microsoft-365-enterprise-plans) or [G3](https://www.microsoft.com/en-us/microsoft-365/government) license level at a minimum. Therefore, only licenses not included in E3/G3 are listed.

TBD - Additional SI and SI Agents assumptions.

## Key Terminology
The key words "MUST," "MUST NOT," "REQUIRED," "SHALL," "SHALL NOT," "SHOULD," "SHOULD NOT," "RECOMMENDED," "MAY," and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

The following are key terms and descriptions used in this document.

**Super Intelligence (SI)**: As defined in Section 3(a) of [Executive Order 14434, Inaugurating the Era of Super Intelligence](https://www.whitehouse.gov/presidential-actions/2026/09/inaugurating-the-era-of-super-intelligence/), except where otherwise provided by law, the terms "Super Intelligence" and "SI" mean the technologies and systems encompassed by the term "artificial intelligence" as defined in [section 9401(3) of title 15, United States Code](https://uscode.house.gov/view.xhtml?req=granuleid:USC-prelim-title15-section9401&num=0&edition=prelim). This definition governs unless and until superseded by subsequent Presidential action consistent with applicable law or by an Act of Congress.

**SI Agents**: Agents as defined by Microsoft in [What are agent identities? \| Microsoft Learn](https://learn.microsoft.com/en-us/entra/agent-id/what-are-agent-identities#what-is-an-agent): "In its most fundamental form, an agent is an application that attempts to achieve a goal by understanding its environment / context, making decisions and acting on them autonomously using available tools. Agents can act with or without human intervention when provided with proper goals or objectives."

**BOD 25-01 Requirement**: This indicator means that the policy is required under [CISA BOD 25-01](https://www.cisa.gov/news-events/directives/bod-25-01-implementing-secure-practices-cloud-services).

**Automated Check**: This indicator means that the policy can be automatically checked via ScubaGear. See the [Quick Start Guide](../../../README.md#quick-start-guide) for help getting started.

**Configurable**: This indicator means that the policy can be customized via a configuration file.

**Requires Configuration**: This indicator means that ScubaGear requires configuration via configuration file in order to check the policy.

**Manual**: This indicator means that the policy requires manual verification of configuration settings.

## Conditional Access Policies

TBD - Guidance for SI and SI Agents policies that rely on Microsoft Entra ID Conditional Access. See the [Conditional Access Policies](aad.md#conditional-access-policies) section of the Microsoft Entra ID baseline for general guidance.

# Baseline Policies

## 1. Agentic Identity Governance

TBD - Section description.

### Policies
#### MS.SI.1.1v1
No Agent Service Principal SHALL hold the Global Administrator role.

<!--Policy: MS.SI.1.1v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.1.2v1
No Agent Service Principal SHALL hold the Privileged Role Administrator role.

<!--Policy: MS.SI.1.2v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.1.3v1
Conditional Access policies SHOULD be applied at the agent identity blueprint level.

<!--Policy: MS.SI.1.3v1; Criticality: SHOULD -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

### Resources

- TBD

### License Requirements

- TBD

### Implementation

#### MS.SI.1.1v1 Instructions

1. TBD

#### MS.SI.1.2v1 Instructions

1. TBD

#### MS.SI.1.3v1 Instructions

1. TBD

## 2. Agent Authentication Strength

TBD - Section description.

### Policies
#### MS.SI.2.1v1
Agent service principals SHALL authenticate via Managed Identity or certificate credentials, not client secrets.

<!--Policy: MS.SI.2.1v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.2.2v1
Workload Identity Conditional Access SHOULD be enabled for agent service principals.

<!--Policy: MS.SI.2.2v1; Criticality: SHOULD -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.2.3v1
Copilot Studio agents SHALL NOT be configured to run on the maker's stored connections (delegated maker credentials).

<!--Policy: MS.SI.2.3v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

### Resources

- TBD

### License Requirements

- TBD

### Implementation

#### MS.SI.2.1v1 Instructions

1. TBD

#### MS.SI.2.2v1 Instructions

1. TBD

#### MS.SI.2.3v1 Instructions

1. TBD

## 3. Agent Inventory & Discovery

TBD - Section description.

### Policies
#### MS.SI.3.1v1
Every agent SHALL be registered with a business owner and technical owner before deployment.

<!--Policy: MS.SI.3.1v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.3.2v1
Every agent SHALL be registered with purpose statement before deployment.

<!--Policy: MS.SI.3.2v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.3.3v1
Unused agents SHOULD be disabled after X days of inactivity.

<!--Policy: MS.SI.3.3v1; Criticality: SHOULD -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ The inactivity threshold (X days) is TBD. This policy may require an additional license.

#### MS.SI.3.4v1
Orphaned agents SHOULD be disabled after X days of inactivity.

<!--Policy: MS.SI.3.4v1; Criticality: SHOULD -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ The inactivity threshold (X days) is TBD. This policy may require an additional license.

### Resources

- TBD

### License Requirements

- TBD

### Implementation

#### MS.SI.3.1v1 Instructions

1. TBD

#### MS.SI.3.2v1 Instructions

1. TBD

#### MS.SI.3.3v1 Instructions

1. TBD

#### MS.SI.3.4v1 Instructions

1. TBD

## 4. Agent Sharing

TBD - Section description.

### Policies
#### MS.SI.4.1v1
Anonymous access to published agents SHALL be disabled.

<!--Policy: MS.SI.4.1v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.4.2v1
Public publishing of agents SHALL be disabled.

<!--Policy: MS.SI.4.2v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.4.3v1
External user access SHALL be restricted to approved domains.

<!--Policy: MS.SI.4.3v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

### Resources

- TBD

### License Requirements

- TBD

### Implementation

#### MS.SI.4.1v1 Instructions

1. TBD

#### MS.SI.4.2v1 Instructions

1. TBD

#### MS.SI.4.3v1 Instructions

1. TBD

## 5. Agent Monitoring & Auditability

TBD - Section description.

### Policies
#### MS.SI.5.1v1
Agent conversations and actions SHALL be logged and retained according to M-26-14.

<!--Policy: MS.SI.5.1v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

### Resources

- TBD

### License Requirements

- TBD

### Implementation

#### MS.SI.5.1v1 Instructions

1. TBD

## 6. SI Governance Prerequisites

TBD - Section description.

### Policies
#### MS.SI.6.1v1
Sensitivity label policy scope SHALL include Groups and sites.

<!--Policy: MS.SI.6.1v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.6.2v1
Unified audit log ingestion SHALL be enabled.

<!--Policy: MS.SI.6.2v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.6.3v1
Sensitivity label display names SHALL be unique within the tenant.

<!--Policy: MS.SI.6.3v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.6.4v1
AI data-security admin roles SHALL be assigned by least privilege.

<!--Policy: MS.SI.6.4v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

### Resources

- TBD

### License Requirements

- TBD

### Implementation

#### MS.SI.6.1v1 Instructions

1. TBD

#### MS.SI.6.2v1 Instructions

1. TBD

#### MS.SI.6.3v1 Instructions

1. TBD

#### MS.SI.6.4v1 Instructions

1. TBD

## 7. Sensitivity Label Taxonomy

TBD - Section description.

### Policies
#### MS.SI.7.1v1
A sensitivity label taxonomy SHALL be published to all users.

<!--Policy: MS.SI.7.1v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.7.2v1
A default label SHALL be configured for new content.

<!--Policy: MS.SI.7.2v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.7.3v1
Justification SHALL be required to lower or remove a label.

<!--Policy: MS.SI.7.3v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.7.4v1
Container labeling SHALL be applied to sites and Teams in AI scope.

<!--Policy: MS.SI.7.4v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

### Resources

- TBD

### License Requirements

- TBD

### Implementation

#### MS.SI.7.1v1 Instructions

1. TBD

#### MS.SI.7.2v1 Instructions

1. TBD

#### MS.SI.7.3v1 Instructions

1. TBD

#### MS.SI.7.4v1 Instructions

1. TBD

## 8. SI Content Detection & Labeling

TBD - Section description.

### Policies
#### MS.SI.8.1v1
Service-side auto-labeling SHALL be configured for SharePoint, OneDrive, and Exchange.

<!--Policy: MS.SI.8.1v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.8.2v1
Auto-labeling policies SHALL be validated in simulation before enforcement.

<!--Policy: MS.SI.8.2v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.8.3v1
Disposition toward existing labels SHALL be explicitly configured for auto-labeling policies.

<!--Policy: MS.SI.8.3v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.8.4v1
Custom sensitive information types SHALL be defined for organization-specific identifiers.

<!--Policy: MS.SI.8.4v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.8.5v1
Classifiers SHOULD be validated before use in enforcing policies.

<!--Policy: MS.SI.8.5v1; Criticality: SHOULD -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

### Resources

- TBD

### License Requirements

- TBD

### Implementation

#### MS.SI.8.1v1 Instructions

1. TBD

#### MS.SI.8.2v1 Instructions

1. TBD

#### MS.SI.8.3v1 Instructions

1. TBD

#### MS.SI.8.4v1 Instructions

1. TBD

#### MS.SI.8.5v1 Instructions

1. TBD

## 9. SI Oversharing Containment

TBD - Section description.

### Policies
#### MS.SI.9.1v1
Sites not approved for AI grounding SHALL be excluded from AI discovery.

<!--Policy: MS.SI.9.1v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.9.2v1
An oversharing assessment SHALL be completed before AI enablement.

<!--Policy: MS.SI.9.2v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.9.3v1
A defined process SHALL evaluate newly created sites for AI-discovery exclusion.

<!--Policy: MS.SI.9.3v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

### Resources

- TBD

### License Requirements

- TBD

### Implementation

#### MS.SI.9.1v1 Instructions

1. TBD

#### MS.SI.9.2v1 Instructions

1. TBD

#### MS.SI.9.3v1 Instructions

1. TBD

## 10. DLP for SI Surfaces

TBD - Section description.

### Policies
#### MS.SI.10.1v1
A DLP policy SHALL be scoped to the Copilot and Copilot Chat location.

<!--Policy: MS.SI.10.1v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.10.2v1
That DLP policy SHALL be in enforcement mode, not simulation.

<!--Policy: MS.SI.10.2v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.10.3v1
A defined AI disposition SHALL exist for every label applying encryption.

<!--Policy: MS.SI.10.3v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.10.4v1
Prompts containing sensitive information types SHOULD be restricted from AI processing.

<!--Policy: MS.SI.10.4v1; Criticality: SHOULD -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.10.5v1
External web grounding SHOULD be restricted for sensitive prompts.

<!--Policy: MS.SI.10.5v1; Criticality: SHOULD -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.10.6v1
Endpoint DLP SHOULD monitor third-party generative AI sites.

<!--Policy: MS.SI.10.6v1; Criticality: SHOULD -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

### Resources

- TBD

### License Requirements

- TBD

### Implementation

#### MS.SI.10.1v1 Instructions

1. TBD

#### MS.SI.10.2v1 Instructions

1. TBD

#### MS.SI.10.3v1 Instructions

1. TBD

#### MS.SI.10.4v1 Instructions

1. TBD

#### MS.SI.10.5v1 Instructions

1. TBD

#### MS.SI.10.6v1 Instructions

1. TBD

## 11. DSPM, Audit & Records for AI

TBD - Section description.

### Policies
#### MS.SI.11.1v1
Data Security Posture Management for AI SHALL be activated.

<!--Policy: MS.SI.11.1v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.11.2v1
Recommended AI protection policies SHOULD be evaluated, applied, or declined on record.

<!--Policy: MS.SI.11.2v1; Criticality: SHOULD -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.11.3v1
DSPM findings SHOULD be reviewed on a defined recurring cadence.

<!--Policy: MS.SI.11.3v1; Criticality: SHOULD -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.11.4v1
Audit retention for AI interactions SHALL meet records requirements.

<!--Policy: MS.SI.11.4v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.11.5v1
Retention policies SHALL cover AI interactions.

<!--Policy: MS.SI.11.5v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.11.6v1
AI interactions SHALL be discoverable through eDiscovery.

<!--Policy: MS.SI.11.6v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

### Resources

- TBD

### License Requirements

- TBD

### Implementation

#### MS.SI.11.1v1 Instructions

1. TBD

#### MS.SI.11.2v1 Instructions

1. TBD

#### MS.SI.11.3v1 Instructions

1. TBD

#### MS.SI.11.4v1 Instructions

1. TBD

#### MS.SI.11.5v1 Instructions

1. TBD

#### MS.SI.11.6v1 Instructions

1. TBD

## 12. SI Communications Compliance & Insider Risk

TBD - Section description.

### Policies
#### MS.SI.12.1v1
A Communication Compliance policy SHOULD be scoped to AI interactions.

<!--Policy: MS.SI.12.1v1; Criticality: SHOULD -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.12.2v1
Reviewers SHALL be assigned and triage SHALL occur on a defined cadence.

<!--Policy: MS.SI.12.2v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.12.3v1
Insider Risk Management policies SHOULD include AI usage indicators.

<!--Policy: MS.SI.12.3v1; Criticality: SHOULD -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.12.4v1
Compensating detective controls SHALL exist where preventive AI controls are unavailable.

<!--Policy: MS.SI.12.4v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

### Resources

- TBD

### License Requirements

- TBD

### Implementation

#### MS.SI.12.1v1 Instructions

1. TBD

#### MS.SI.12.2v1 Instructions

1. TBD

#### MS.SI.12.3v1 Instructions

1. TBD

#### MS.SI.12.4v1 Instructions

1. TBD

## 13. Copilot Studio Agent Governance

TBD - Section description.

### Policies
#### MS.SI.13.1v1
Pay-as-you-go metering for agents SHALL NOT be enabled.

<!--Policy: MS.SI.13.1v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.13.2v1
Agent knowledge sources SHALL be limited to those carrying required protection.

<!--Policy: MS.SI.13.2v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.13.3v1
Agents published on non-Microsoft channels SHALL be inventoried and approved.

<!--Policy: MS.SI.13.3v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.13.4v1
DLP SHALL be scoped to cover agents where the knowledge source supports it.

<!--Policy: MS.SI.13.4v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.13.5v1
Power Platform data loss prevention policies SHALL restrict connector combinations available to agent environments.

<!--Policy: MS.SI.13.5v1; Criticality: SHALL -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

#### MS.SI.13.6v1
External threat detection for Copilot Studio agents SHOULD be configured to block on error rather than allow.

<!--Policy: MS.SI.13.6v1; Criticality: SHOULD -->
- _Rationale:_ TBD
- _Last modified:_ TBD
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ TBD
- _MITRE ATT&CK TTP Mapping:_
  - TBD
- _Note:_ TBD

### Resources

- TBD

### License Requirements

- TBD

### Implementation

#### MS.SI.13.1v1 Instructions

1. TBD

#### MS.SI.13.2v1 Instructions

1. TBD

#### MS.SI.13.3v1 Instructions

1. TBD

#### MS.SI.13.4v1 Instructions

1. TBD

#### MS.SI.13.5v1 Instructions

1. TBD

#### MS.SI.13.6v1 Instructions

1. TBD
