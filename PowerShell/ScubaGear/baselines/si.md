**`TLP:CLEAR`**

# CISA M365 Secure Configuration Baseline for Super Intelligence (SI) / SI Agents capabilities

Microsoft 365 (M365) includes a growing set of Super Intelligence (SI) and SI Agents capabilities. These include Microsoft 365 Copilot and Microsoft 365 Copilot Chat, which ground generative responses in organizational data the user can already access (for example, SharePoint, OneDrive, Exchange, and Teams content); agents built with Copilot Studio, Agent Builder, and declarative agent tooling, which can be granted knowledge sources, connectors, and tools that let them act on a user's or their own behalf; and Microsoft Entra Agent ID, which gives agents first-class identities that can be governed, authenticated, and audited like other identities in the tenant. Because SI capabilities inherit and amplify existing data access, their security depends heavily on the data-security controls in Microsoft Purview, including sensitivity labels, data loss prevention (DLP), Data Security Posture Management (DSPM) for AI, audit, retention, eDiscovery, Communication Compliance, and Insider Risk Management. This Secure Configuration Baseline (SCB) provides specific policies to help secure SI and SI Agents capabilities, including related settings that are configured in other M365 admin centers (for example, Microsoft Entra Conditional Access policies and Microsoft Purview data loss prevention policies).

The Cybersecurity and Infrastructure Security Agency's (CISA) Secure Cloud Business Applications (SCuBA) project provides guidance and capabilities to secure federal civilian executive branch (FCEB) agencies' cloud business application environments and protect federal information that is created, accessed, shared, and stored in those environments.

The CISA SCuBA SCBs for M365 help secure federal information assets stored within M365 cloud business application environments through consistent, effective, and manageable security configurations. CISA created baselines tailored to the federal government’s threats and risk tolerance with the knowledge that every organization has different threat models and risk tolerance. While use of these baselines will be mandatory for civilian federal government agencies, organizations outside of the federal government may also find these baselines to be useful references to help reduce risks.

For non-federal users, the information in this document is being provided "as is" for INFORMATIONAL PURPOSES ONLY. CISA does not endorse any commercial product or service, including any subjects of analysis. Any reference to specific commercial entities or commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply endorsement, recommendation, or favoritism by CISA. Without limiting the generality of the foregoing, some controls and settings are not available in all products. CISA has no control over vendor changes to products offerings or features. Accordingly, these SCuBA SCBs for M365 may not be applicable to the products available to you. This document does not address, ensure compliance with, or supersede any law, regulation, or other authority. Entities are responsible for complying with any recordkeeping, privacy, and other laws that may apply to the use of technology. This document is not intended to, and does not, create any right or benefit for anyone against the United States, its departments, agencies, or entities, its officers, employees, or agents, or any other person.

> This document is marked TLP:CLEAR. Recipients may share this information without restriction. Information is subject to standard copyright rules. For more information on the Traffic Light Protocol, see https://www.cisa.gov/tlp.

## License Compliance and Copyright
Portions of this document are adapted from documents in Microsoft’s [M365](https://github.com/MicrosoftDocs/microsoft-365-docs/blob/public/LICENSE) and [Azure](https://github.com/MicrosoftDocs/azure-docs/blob/main/LICENSE) GitHub repositories. The respective documents are subject to copyright and are adapted under the terms of the Creative Commons Attribution 4.0 International license. Sources are linked throughout this document. The United States government has adapted selections of these documents to develop innovative and scalable configuration standards to strengthen the security of widely used cloud-based software services.

## Assumptions
The **License Requirements** sections of this document assume the organization is using an [M365 E3](https://www.microsoft.com/en-us/microsoft-365/compare-microsoft-365-enterprise-plans) or [G3](https://www.microsoft.com/en-us/microsoft-365/government) license level at a minimum. Therefore, only licenses not included in E3/G3 are listed.

This baseline also assumes the following:

- The organization has licensed, or intends to license, Microsoft 365 Copilot and/or Copilot Studio for some or all users. Policies that govern Copilot Chat apply even where users hold no paid Copilot license.
- The other SCuBA baselines remain in effect, in particular the [Microsoft Entra ID](aad.md), [Defender](defender.md), [Exchange Online](exo.md), [SharePoint Online and OneDrive](sharepoint.md), [Teams](teams.md), and [Power Platform](powerplatform.md) baselines. This baseline builds on those controls and does not restate them; for example, unified audit logging is also required by MS.EXO.17.1v1, and Power Platform DLP is also required by MS.POWERPLATFORM.2.
- Several SI and SI Agents capabilities, including Microsoft Entra Agent ID, agent identity blueprints, and some Purview DLP actions for Copilot, may be in preview or may not yet be available in every cloud (Commercial, GCC, GCC High, DoD). Where a capability is unavailable, agencies should apply the compensating detective controls described in MS.SI.12.4v1.
- Some policies are process controls (for example, data risk assessments, review cadences, and approval workflows). Agencies are expected to document these processes and keep evidence of their execution; they cannot be fully verified from tenant configuration alone.

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

Microsoft Entra Conditional Access can target agent identities, as distinct from users and workload identities. Policies MS.SI.1.3v1 and MS.SI.2.2v1 rely on this capability. Agencies should keep agent-targeted Conditional Access policies separate from user-targeted ones so that exclusions for one population do not accidentally weaken controls on the other. As with user policies, agencies should first deploy new agent policies in **Report-only** mode, review their impact in the sign-in logs, and then switch them to **On**. Break-glass user accounts are not relevant to agent policies and should not be added as exclusions. Any agent identity excluded from an agent Conditional Access policy should be documented with a justification and an owner. See the [Conditional Access Policies](aad.md#conditional-access-policies) section of the Microsoft Entra ID baseline for general guidance.
<!-- VERIFY: Conditional Access "Agents (Preview)" assignment option name and whether it is GA in Commercial/GCC/GCC High. -->

# Baseline Policies

## 1. Agentic Identity Governance

Agents registered in Microsoft Entra Agent ID are identities that can be assigned directory roles, granted application permissions, and targeted by Conditional Access. Because agents act autonomously, can be influenced by the content they process (for example, through prompt injection), and often run without a human reviewing each action, granting them highly privileged roles creates an outsized risk of tenant compromise. This section limits the privileges agents can hold and requires that access controls be applied consistently through agent identity blueprints.

### Policies
#### MS.SI.1.1v1
No agent identity SHALL hold the Global Administrator role.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi11v1-instructions)

<!--Policy: MS.SI.1.1v1; Criticality: SHALL -->
- _Rationale:_ The Global Administrator role grants unrestricted control over the tenant. An agent can be manipulated through untrusted input it processes, and its credentials can be stolen. An agent holding this role would therefore give an attacker a direct path to complete tenant compromise without having to compromise a human administrator.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-2(7), AC-6, AC-6(5), AC-6(7)
- _MITRE ATT&CK TTP Mapping:_
  - [T1078: Valid Accounts](https://attack.mitre.org/techniques/T1078/)
    - [T1078.004: Cloud Accounts](https://attack.mitre.org/techniques/T1078/004/)
  - [T1098: Account Manipulation](https://attack.mitre.org/techniques/T1098/)
    - [T1098.003: Additional Cloud Roles](https://attack.mitre.org/techniques/T1098/003/)
  - [T1484: Domain or Tenant Policy Modification](https://attack.mitre.org/techniques/T1484/)
    - [T1484.002: Trust Modification](https://attack.mitre.org/techniques/T1484/002/)
- _Note:_ This policy applies to both active and eligible (Privileged Identity Management) role assignments. See also the privileged role guidance in the [Microsoft Entra ID baseline](aad.md) (MS.AAD.7).

#### MS.SI.1.2v1
No agent identity SHALL hold the Privileged Role Administrator role.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi12v1-instructions)

<!--Policy: MS.SI.1.2v1; Criticality: SHALL -->
- _Rationale:_ The Privileged Role Administrator role can assign any directory role, including Global Administrator, to any identity. An agent holding this role could escalate its own privileges or the privileges of an attacker-controlled identity, which makes it equivalent in risk to Global Administrator.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-2(7), AC-6, AC-6(5), AC-6(7)
- _MITRE ATT&CK TTP Mapping:_
  - [T1078: Valid Accounts](https://attack.mitre.org/techniques/T1078/)
    - [T1078.004: Cloud Accounts](https://attack.mitre.org/techniques/T1078/004/)
  - [T1098: Account Manipulation](https://attack.mitre.org/techniques/T1098/)
    - [T1098.003: Additional Cloud Roles](https://attack.mitre.org/techniques/T1098/003/)
- _Note:_ This policy applies to both active and eligible (Privileged Identity Management) role assignments.

#### MS.SI.1.3v1
Conditional Access policies SHOULD be applied at the agent identity blueprint level.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi13v1-instructions)

<!--Policy: MS.SI.1.3v1; Criticality: SHOULD -->
- _Rationale:_ Agent identities created from a blueprint share its configuration. When a Conditional Access policy targets the blueprint instead of individual agent identities, every new agent created from that blueprint gets the same controls automatically, with no gap between creation and policy assignment. This also reduces the risk of individually managed agents being left out of policy.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-2(11), AC-3, CM-2
- _MITRE ATT&CK TTP Mapping:_
  - [T1078: Valid Accounts](https://attack.mitre.org/techniques/T1078/)
    - [T1078.004: Cloud Accounts](https://attack.mitre.org/techniques/T1078/004/)
  - [T1550: Use Alternate Authentication Material](https://attack.mitre.org/techniques/T1550/)
    - [T1550.001: Application Access Token](https://attack.mitre.org/techniques/T1550/001/)
- _Note:_ Agent-specific policies (MS.SI.2.2v1) may still be needed for agents with unique risk profiles. Blueprint-level policies set the minimum.

### Resources

- [What are agent identities? \| Microsoft Learn](https://learn.microsoft.com/en-us/entra/agent-id/what-are-agent-identities)
- [Microsoft Entra built-in roles \| Microsoft Learn](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference)
- [Conditional Access for Agent ID \| Microsoft Learn](https://learn.microsoft.com/en-us/entra/identity/conditional-access/agent-id)
<!-- VERIFY: exact URL for Conditional Access for Agent ID and agent identity blueprint docs. -->

### License Requirements

- Microsoft Entra Agent ID capabilities may require Microsoft Agent 365 or additional Microsoft Entra licensing. Verify current licensing requirements for agent identities in your cloud environment.
- Privileged Identity Management (to review eligible assignments) requires Microsoft Entra ID P2.
<!-- VERIFY: Agent ID / Agent 365 licensing and whether Conditional Access for agents needs Entra ID P1 only or Workload ID Premium. -->

### Implementation

#### MS.SI.1.1v1 Instructions

1. Sign in to the **Microsoft Entra admin center** as at least a Privileged Role Administrator.
2. Select **Entra ID** > **Roles & admins** > **Global Administrator**.
3. Review **Active assignments** and **Eligible assignments**. Confirm that no assignment belongs to an agent identity (listed with the agent or service principal type). Cross-check against **Entra ID** > **Agent ID** > **All agent identities**.
4. Remove any agent identity found, then grant it a least-privilege role or scoped application permissions instead.

Alternatively, using Microsoft Graph PowerShell:

```powershell
$roleId = "62e90394-69f5-4237-9190-012177145e10" # Global Administrator
Get-MgRoleManagementDirectoryRoleAssignment -Filter "roleDefinitionId eq '$roleId'" -ExpandProperty Principal |
  Where-Object { $_.Principal.AdditionalProperties.'@odata.type' -ne '#microsoft.graph.user' }
Get-MgRoleManagementDirectoryRoleEligibilitySchedule -Filter "roleDefinitionId eq '$roleId'" -ExpandProperty Principal |
  Where-Object { $_.Principal.AdditionalProperties.'@odata.type' -ne '#microsoft.graph.user' }
```

Investigate every non-user principal returned, and confirm that none of them is an agent identity.
<!-- VERIFY: portal path "Entra ID > Agent ID > All agent identities" and the @odata.type / servicePrincipalType value Graph returns for agent identities. -->

#### MS.SI.1.2v1 Instructions

1. Follow the steps in [MS.SI.1.1v1 Instructions](#mssi11v1-instructions), selecting the **Privileged Role Administrator** role instead of Global Administrator.
2. When using PowerShell, set `$roleId = "e8611ab8-c189-46e8-94e1-60213ab1f814"` (Privileged Role Administrator).

#### MS.SI.1.3v1 Instructions

1. Sign in to the **Microsoft Entra admin center** as at least a Conditional Access Administrator.
2. Select **Entra ID** > **Conditional Access** > **Policies** > **New policy**.
3. Under **Assignments** > **Users, agents, or workload identities**, select **Agents**. Then choose **Select agents** and include the agent identity blueprints to govern, so that the policy applies to all agent identities created from them.
4. Configure the conditions and grant or block controls that fit the blueprint's risk profile (see [MS.SI.2.2v1](#mssi22v1-instructions)).
5. Set **Enable policy** to **Report-only**, validate the results in the sign-in logs, and then set it to **On**.
6. Repeat for each blueprint in use. Review the list of blueprints at **Entra ID** > **Agent ID** > **Agent blueprints**, and confirm that each one is covered by at least one policy.
<!-- VERIFY: exact Conditional Access assignment UI labels for targeting agents by blueprint. -->

## 2. Agent Authentication Strength

Agents authenticate to Microsoft Entra ID through credentials configured on their agent identity blueprints, and to downstream services through connectors and tools. Long-lived shared secrets, and connections that reuse an individual maker's credentials, are common causes of credential theft and privilege escalation. This section requires strong, non-secret credential types, Conditional Access for agents, and end-user (not maker) authentication for Copilot Studio agents.

### Policies
#### MS.SI.2.1v1
Agent identity blueprints SHALL use federated identity credentials (such as managed identities) or certificates, not client secrets.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi21v1-instructions)

<!--Policy: MS.SI.2.1v1; Criticality: SHALL -->
- _Rationale:_ Client secrets are static strings. They are easily copied into code, configuration files, and logs, and anyone holding a stolen secret can use it from anywhere. Federated identity credentials and managed identities remove the stored secret altogether. Certificates are much harder to exfiltrate and reuse, especially when stored in a hardware-backed key store.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ IA-5, IA-5(2), IA-5(7), SC-12
- _MITRE ATT&CK TTP Mapping:_
  - [T1552: Unsecured Credentials](https://attack.mitre.org/techniques/T1552/)
    - [T1552.001: Credentials In Files](https://attack.mitre.org/techniques/T1552/001/)
  - [T1098: Account Manipulation](https://attack.mitre.org/techniques/T1098/)
    - [T1098.001: Additional Cloud Credentials](https://attack.mitre.org/techniques/T1098/001/)
  - [T1528: Steal Application Access Token](https://attack.mitre.org/techniques/T1528/)
- _Note:_ Federated identity credentials or managed identities are preferred over certificates where the hosting platform supports them.

#### MS.SI.2.2v1
Conditional Access for Agent ID SHOULD be configured for agent identities.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi22v1-instructions)

<!--Policy: MS.SI.2.2v1; Criticality: SHOULD -->
- _Rationale:_ Without Conditional Access, an agent identity with valid credentials can obtain tokens under any conditions. Conditional Access for agents lets agencies block high-risk agents, block agents that have not been approved, and restrict the resources agents can access. This limits the damage a compromised or misbehaving agent can do.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-2(11), AC-2(12), AC-3
- _MITRE ATT&CK TTP Mapping:_
  - [T1078: Valid Accounts](https://attack.mitre.org/techniques/T1078/)
    - [T1078.004: Cloud Accounts](https://attack.mitre.org/techniques/T1078/004/)
  - [T1550: Use Alternate Authentication Material](https://attack.mitre.org/techniques/T1550/)
    - [T1550.001: Application Access Token](https://attack.mitre.org/techniques/T1550/001/)
- _Note:_ At a minimum, agencies should block agent identities that Microsoft Entra ID Protection flags as high risk. Agencies should also consider restricting agents to approved resources. Where possible, apply these policies at the blueprint level (MS.SI.1.3v1).

#### MS.SI.2.3v1
Copilot Studio agents SHALL NOT use maker-provided credentials.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi23v1-instructions)

<!--Policy: MS.SI.2.3v1; Criticality: SHALL -->
- _Rationale:_ When a Copilot Studio agent's tools, connectors, or actions use the maker's own credentials, every user of the agent operates with the maker's permissions. A low-privileged user can then read or change data that only the maker should reach, and audit records attribute the actions to the maker instead of the user. End-user authentication keeps each action bound to the permissions and identity of the person invoking the agent.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-3, AC-6, AU-10, IA-5(7)
- _MITRE ATT&CK TTP Mapping:_
  - [T1078: Valid Accounts](https://attack.mitre.org/techniques/T1078/)
    - [T1078.004: Cloud Accounts](https://attack.mitre.org/techniques/T1078/004/)
  - [T1528: Steal Application Access Token](https://attack.mitre.org/techniques/T1528/)
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
- _Note:_ Autonomous agents that run without an interactive user should authenticate with their own agent identity under MS.SI.2.1v1, not with a maker's personal credentials.

### Resources

- [Agent identity blueprints \| Microsoft Learn](https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/agent-blueprint)
- [Conditional Access for Agent ID \| Microsoft Learn](https://learn.microsoft.com/en-us/entra/identity/conditional-access/agent-id)
- [Configure user authentication for actions \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-copilot-studio/configure-enduser-authentication)
<!-- VERIFY: blueprint and Copilot Studio tool-authentication doc URLs. -->

### License Requirements

- Copilot Studio requires a Copilot Studio license or Microsoft 365 Copilot license, depending on agent type.
- Conditional Access based on agent or sign-in risk requires Microsoft Entra ID P2 (ID Protection).
<!-- VERIFY: license for Conditional Access targeting agent identities. -->

### Implementation

#### MS.SI.2.1v1 Instructions

1. Sign in to the **Microsoft Entra admin center** as at least an Application Administrator.
2. Select **Entra ID** > **Agent ID** > **Agent blueprints**.
3. For each blueprint, open **Certificates & secrets** (or **Credentials**) and confirm there are no **Client secrets**. Only **Certificates** or **Federated credentials** should be present.
4. For any blueprint that uses a client secret, add a federated identity credential (for example, for a managed identity of the hosting Azure resource) or a certificate, update the agent's hosting service to use it, and then delete the client secret.

Alternatively, using Microsoft Graph, list blueprints with populated `passwordCredentials` and remediate each one.
<!-- VERIFY: blueprint blade names and the Graph resource name (e.g., agentIdentityBlueprint) and its credential properties. -->

#### MS.SI.2.2v1 Instructions

1. Sign in to the **Microsoft Entra admin center** as at least a Conditional Access Administrator.
2. Select **Entra ID** > **Conditional Access** > **Policies** > **New policy**.
3. Under **Assignments** > **Users, agents, or workload identities**, select **Agents** > **All agent identities** (or the blueprints in scope; see MS.SI.1.3v1).
4. Under **Conditions** > **Agent risk**, select **High**.
5. Under **Grant**, select **Block access**.
6. Set **Enable policy** to **Report-only**, validate, and then set it to **On**.
7. Optionally, create additional policies that block agent access to resources the agents are not approved to use.
<!-- VERIFY: "Agent risk" condition name and availability. -->

#### MS.SI.2.3v1 Instructions

1. Sign in to **Copilot Studio** and open each agent in the environment, or ask the agent's owner to do so.
2. For each tool, connector action, or flow used by the agent, open its **Settings** and review the **Credentials to use** (or **Authentication**) option.
3. Confirm that **End user credentials** is selected, not **Maker-provided credentials**.
4. Republish the agent after making any changes.
5. To check across the tenant, use the **Power Platform admin center** > **Manage** > **Inventory** (or Copilot Studio agent inventory) to list agents, and review the connection references on each agent.
<!-- VERIFY: exact label "Maker-provided credentials" vs "Copilot author authentication", and whether a tenant/environment-level admin control exists to block maker credentials. -->

## 3. Agent Inventory & Discovery

An agency cannot secure agents it does not know about. Agents can be created by many users across Copilot Studio, Agent Builder, Azure AI Foundry, and third-party platforms, and many accumulate over time with no clear accountability. This section requires every agent to have a named sponsor and owner and a documented purpose before deployment, and requires inactive or ownerless agents to be disabled.

### Policies
#### MS.SI.3.1v1
Every agent SHALL be assigned a sponsor and an owner before deployment.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi31v1-instructions)

<!--Policy: MS.SI.3.1v1; Criticality: SHALL -->
- _Rationale:_ A named owner is responsible for an agent's technical configuration, and a sponsor is accountable for its business use. Together they make sure someone is answerable for the agent's access, behavior, and lifecycle. Agents with no accountable humans are less likely to be reviewed, patched, or retired, and harder to investigate during an incident.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-2, CM-8, CM-8(4)
- _MITRE ATT&CK TTP Mapping:_
  - [T1136: Create Account](https://attack.mitre.org/techniques/T1136/)
    - [T1136.003: Cloud Account](https://attack.mitre.org/techniques/T1136/003/)
  - [T1078: Valid Accounts](https://attack.mitre.org/techniques/T1078/)
    - [T1078.004: Cloud Accounts](https://attack.mitre.org/techniques/T1078/004/)
- _Note:_ The sponsor and owner may be the same person for low-risk agents, but agencies should name at least two accountable people for agents with access to sensitive data or with write or act capabilities.

#### MS.SI.3.2v1
Every agent SHALL be registered with a description of its purpose before deployment.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi32v1-instructions)

<!--Policy: MS.SI.3.2v1; Criticality: SHALL -->
- _Rationale:_ A documented purpose defines what an agent is supposed to do. Reviewers need that to judge whether its permissions, knowledge sources, and connectors are appropriate, and to spot behavior or access that goes beyond its intended scope.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ CM-8, CM-8(4), PL-2
- _MITRE ATT&CK TTP Mapping:_
  - [T1136: Create Account](https://attack.mitre.org/techniques/T1136/)
    - [T1136.003: Cloud Account](https://attack.mitre.org/techniques/T1136/003/)

#### MS.SI.3.3v1
Unused agents SHOULD be disabled after 90 days of inactivity.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi33v1-instructions)

<!--Policy: MS.SI.3.3v1; Criticality: SHOULD -->
- _Rationale:_ Inactive agents keep their identities, credentials, permissions, and knowledge-source access long after they stop providing value. Disabling them shrinks the attack surface and removes standing access that might otherwise be abused unnoticed.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-2(3), CM-7
- _MITRE ATT&CK TTP Mapping:_
  - [T1078: Valid Accounts](https://attack.mitre.org/techniques/T1078/)
    - [T1078.004: Cloud Accounts](https://attack.mitre.org/techniques/T1078/004/)
- _Note:_ Agents that run on a known schedule longer than 90 days (for example, an annual reporting agent) may be excluded if the exclusion is documented. Automated detection of inactive agents may require an additional license.

#### MS.SI.3.4v1
Ownerless agents SHOULD be disabled after 30 days of inactivity.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi34v1-instructions)

<!--Policy: MS.SI.3.4v1; Criticality: SHOULD -->
- _Rationale:_ An agent loses its owner when the owner leaves the agency or changes roles. After that, no one is accountable for its access or behavior. A shorter inactivity window than MS.SI.3.3v1 reflects this higher risk. Agencies should either reassign ownership or disable the agent.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-2(3), AC-2(4), CM-8(4)
- _MITRE ATT&CK TTP Mapping:_
  - [T1078: Valid Accounts](https://attack.mitre.org/techniques/T1078/)
    - [T1078.004: Cloud Accounts](https://attack.mitre.org/techniques/T1078/004/)
- _Note:_ An ownerless agent that is still active should have a new owner assigned (MS.SI.3.1v1) instead of being left in service unowned. Automated detection of ownerless agents may require an additional license.

### Resources

- [What are agent identities? \| Microsoft Learn](https://learn.microsoft.com/en-us/entra/agent-id/what-are-agent-identities)
- [Manage agents in the Microsoft 365 admin center \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-365/admin/manage/manage-copilot-agents-integrated-apps)
- [View Copilot Studio inventory in the Power Platform admin center \| Microsoft Learn](https://learn.microsoft.com/en-us/power-platform/admin/power-platform-inventory)
<!-- VERIFY: agent registry / Agent 365 documentation URLs and current naming (Agent 365, Agent registry, Agent inventory). -->

### License Requirements

- Centralized agent inventory, ownerless agent detection, and agent lifecycle automation may require Microsoft Agent 365 and/or Microsoft Entra ID Governance.
<!-- VERIFY: which license provides agent registry, ownerless-agent reports, and agent lifecycle/access reviews. -->

### Implementation

#### MS.SI.3.1v1 Instructions

1. Sign in to the **Microsoft Entra admin center**.
2. Select **Entra ID** > **Agent ID** > **All agent identities**.
3. For each agent identity, open **Owners** and **Sponsors** and confirm at least one active user is assigned to each.
4. For Copilot Studio agents, also confirm in the **Power Platform admin center** inventory (or the **Microsoft 365 admin center** > **Agents** > **All agents**) that each agent has an active owner.
5. Update the agency's agent deployment procedure so that no agent is published until a sponsor and owner are recorded.
<!-- VERIFY: "Sponsors" blade name on agent identities and M365 admin center Agents page path. -->

#### MS.SI.3.2v1 Instructions

1. Sign in to the **Microsoft 365 admin center** and select **Agents** > **All agents** (the agent registry).
2. For each agent, confirm that the **Description** field states the agent's business purpose, the data it accesses, and the actions it can take.
3. For agent identities in Microsoft Entra Agent ID, confirm that the **Description** (or **Notes**) field is filled in on the agent identity or its blueprint.
4. Update the agency's agent deployment procedure so that no agent is published without a documented purpose.

#### MS.SI.3.3v1 Instructions

1. Sign in to the **Microsoft Entra admin center** and review the sign-in logs (**Entra ID** > **Monitoring & health** > **Sign-in logs** > **Agent sign-ins**) to find each agent identity's last sign-in.
2. In the **Microsoft 365 admin center** > **Agents** > **All agents**, and in the **Power Platform admin center** inventory, review each agent's last-used or last-activity date.
3. For any agent with no activity in the last 90 days, notify the owner and sponsor. If no documented justification is provided, disable the agent identity (**Disable**) and unpublish or block the agent.
4. Repeat at least monthly, or automate the process with lifecycle workflows where available.
<!-- VERIFY: agent sign-in log filter name and agent "last activity" column location. -->

#### MS.SI.3.4v1 Instructions

1. Sign in to the **Microsoft 365 admin center**, select **Agents** > **All agents**, and filter for agents with no owner (or use the ownerless agents report, where available).
2. In the **Microsoft Entra admin center**, review agent identities whose owners and sponsors are disabled, deleted, or unassigned.
3. For each ownerless agent, assign a new owner and sponsor. If none can be assigned and the agent has been inactive for 30 days, disable the agent identity and unpublish or block the agent.
4. Repeat at least monthly.
<!-- VERIFY: ownerless-agent filter/report availability. -->

## 4. Agent Sharing

Copilot Studio and other agent platforms let makers publish agents to wide audiences, including anonymous users on public websites and users in other organizations. An agent's knowledge sources and tools then become reachable by whoever can talk to it. This section prohibits unauthenticated and public publishing of agents and restricts external access to approved domains.

### Policies
#### MS.SI.4.1v1
Agents SHALL NOT be published with the No authentication option.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi41v1-instructions)

<!--Policy: MS.SI.4.1v1; Criticality: SHALL -->
- _Rationale:_ An agent published with **No authentication** can be used by anyone who can reach its endpoint, with no identity, audit attribution, or access control. Any knowledge source or tool attached to such an agent is effectively public, and the agent can be abused anonymously for data harvesting or prompt injection.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-3, AC-14, IA-2, IA-8
- _MITRE ATT&CK TTP Mapping:_
  - [T1190: Exploit Public-Facing Application](https://attack.mitre.org/techniques/T1190/)
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)

#### MS.SI.4.2v1
Public publishing of agents SHALL be disabled.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi42v1-instructions)

<!--Policy: MS.SI.4.2v1; Criticality: SHALL -->
- _Rationale:_ Publishing agents to public channels, such as the demo website, custom websites, or social media channels, exposes them to the internet. This expands the attack surface for prompt injection, data leakage, and abuse well beyond the agency's managed user population.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-14, AC-22, SC-7
- _MITRE ATT&CK TTP Mapping:_
  - [T1190: Exploit Public-Facing Application](https://attack.mitre.org/techniques/T1190/)
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
- _Note:_ Agencies with a mission need for a public-facing agent should host it in a dedicated, isolated environment with no access to internal knowledge sources, and document an approved exception. See also MS.SI.13.3v1 for non-Microsoft channels.

#### MS.SI.4.3v1
External user access SHALL be restricted to approved domains.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi43v1-instructions)

<!--Policy: MS.SI.4.3v1; Criticality: SHALL -->
- _Rationale:_ Agents shared with guest users, or reachable from other tenants, extend the agency's data to external parties. Restricting external collaboration and cross-tenant connections to an approved list of domains and tenants ensures that only vetted partner organizations can be given access to agents and the data behind them.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-3, AC-20, AC-21, CA-3
- _MITRE ATT&CK TTP Mapping:_
  - [T1199: Trusted Relationship](https://attack.mitre.org/techniques/T1199/)
  - [T1078: Valid Accounts](https://attack.mitre.org/techniques/T1078/)
    - [T1078.004: Cloud Accounts](https://attack.mitre.org/techniques/T1078/004/)
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
- _Note:_ Microsoft Entra external collaboration settings and cross-tenant access settings are the primary control. Power Platform tenant isolation is a secondary control for Copilot Studio agents and connectors. See also the external sharing policies in the [Microsoft Entra ID](aad.md) and [Power Platform](powerplatform.md) baselines.

### Resources

- [Configure user authentication in Copilot Studio \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-copilot-studio/configuration-end-user-authentication)
- [Configure data policies for agents \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-copilot-studio/admin-data-loss-prevention)
- [Configure external collaboration settings \| Microsoft Learn](https://learn.microsoft.com/en-us/entra/external-id/external-collaboration-settings-configure)
- [Cross-tenant inbound and outbound restrictions (tenant isolation) \| Microsoft Learn](https://learn.microsoft.com/en-us/power-platform/admin/cross-tenant-restrictions)

### License Requirements

- N/A

### Implementation

#### MS.SI.4.1v1 Instructions

To block unauthenticated agents tenant-wide:

1. Sign in to the **Power Platform admin center**.
2. Select **Security** > **Data and privacy** > **Data policy** (or **Policies** > **Data policies**).
3. Edit the policy that applies to all environments (or create one scoped to all environments).
4. Find the **Chat without Microsoft Entra ID authentication in Copilot Studio** connector and move it to **Blocked**.
5. Save the policy.

To verify individual agents:

1. In **Copilot Studio**, open each agent and select **Settings** > **Security** > **Authentication**.
2. Confirm that **No authentication** is not selected. Use **Authenticate with Microsoft** wherever possible.

#### MS.SI.4.2v1 Instructions

1. Sign in to the **Power Platform admin center**.
2. Select **Security** > **Data and privacy** > **Data policy**, and edit the policy that applies to all environments.
3. Move the following Copilot Studio channel connectors to **Blocked** unless the agency has approved a specific exception: **Direct Line channels in Copilot Studio** (used by the demo website and custom websites), **Facebook channel in Copilot Studio**, and any other public or social channel connectors.
4. Confirm that **Chat without Microsoft Entra ID authentication in Copilot Studio** is also **Blocked** (MS.SI.4.1v1).
5. Save the policy.
<!-- VERIFY: current list of Copilot Studio channel connectors available for data policies. -->

#### MS.SI.4.3v1 Instructions

Microsoft Entra external collaboration (primary control):

1. Sign in to the **Microsoft Entra admin center** as at least a Global Administrator or External Identity Provider Administrator.
2. Select **Entra ID** > **External Identities** > **External collaboration settings**.
3. Under **Collaboration restrictions**, select **Allow invitations only to the specified domains (most restrictive)** and enter the approved domains.
4. Select **Entra ID** > **External Identities** > **Cross-tenant access settings**. Make the default inbound and outbound settings restrictive, and add organizational settings only for approved partner tenants.

Power Platform tenant isolation (secondary control for Copilot Studio):

1. Sign in to the **Power Platform admin center**.
2. Select **Security** > **Identity and access** > **Tenant isolation**.
3. Turn on tenant isolation, and add allow rules only for approved partner tenants.

## 5. Agent Monitoring & Auditability

Agents take actions, retrieve data, and generate content on behalf of users or on their own. Agencies need a complete, retained record of agent conversations and actions to detect misuse, investigate incidents, and meet federal logging requirements. This section requires agent activity to be logged and retained. Prerequisite and retention-duration controls are covered in MS.SI.6.2v1 and MS.SI.11.4v1.

### Policies
#### MS.SI.5.1v1
Agent conversations and actions SHALL be logged and retained according to M-26-14.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi51v1-instructions)

<!--Policy: MS.SI.5.1v1; Criticality: SHALL -->
- _Rationale:_ Logs of agent prompts, responses, accessed resources, and tool invocations are needed to detect prompt injection, data exfiltration, and misuse, and to reconstruct events during an incident. Without them, agent activity is effectively invisible to security operations.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AU-2, AU-3, AU-11, AU-12
- _MITRE ATT&CK TTP Mapping:_
  - [T1562: Impair Defenses](https://attack.mitre.org/techniques/T1562/)
    - [T1562.008: Disable or Modify Cloud Logs](https://attack.mitre.org/techniques/T1562/008/)
  - [T1070: Indicator Removal](https://attack.mitre.org/techniques/T1070/)
- _Note:_ This policy covers *capturing* agent activity (Purview audit records such as `CopilotInteraction` and Copilot Studio activities, and Copilot Studio conversation transcripts). Unified audit logging must be enabled as a prerequisite (MS.SI.6.2v1; also MS.EXO.17.1v1). MS.SI.11.4v1 sets audit retention duration, and MS.SI.11.5v1 sets retention of interaction content. Agencies should also forward these logs to their SIEM in line with the logging guidance in the SCuBA baselines.

### Resources

- [Audit logs for Copilot and AI applications \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/audit-copilot)
- [View audit logs for Copilot Studio \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-copilot-studio/admin-logging-copilot-studio)
- [Configure conversation transcript retention in Copilot Studio \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-copilot-studio/analytics-transcripts-powerapps)
- OMB Memorandum M-26-14
<!-- VERIFY/TODO: add link to OMB M-26-14. -->

### License Requirements

- Retaining audit records beyond the Audit (Standard) default retention period requires Microsoft Purview Audit (Premium), which is included with M365 E5/G5 or E5/G5 Compliance. See MS.SI.11.4v1.

### Implementation

#### MS.SI.5.1v1 Instructions

1. Confirm that unified audit logging is enabled ([MS.SI.6.2v1](#mssi62v1-instructions)).
2. Sign in to the **Microsoft Purview portal** and select **Solutions** > **Audit** > **Search**. Search for the **Copilot activities** (record type `CopilotInteraction`) and **Copilot Studio** activities, and confirm that recent agent interactions appear.
3. Sign in to the **Power Platform admin center**. For each environment hosting Copilot Studio agents, open **Settings** > **Audit and logs** and confirm that auditing is enabled.
4. In each Copilot Studio environment, confirm that conversation transcripts (Dataverse `ConversationTranscript` table) are kept for at least as long as M-26-14 requires, adjusting the default bulk-deletion job if needed.
5. Configure audit retention policies as described in [MS.SI.11.4v1](#mssi114v1-instructions) so that retention meets M-26-14.
6. Forward the audit records to the agency's SIEM (for example, through the Office 365 Management Activity API or Microsoft Sentinel).
<!-- VERIFY: Copilot Studio transcript default retention (historically 30 days) and how to change it. -->

## 6. SI Governance Prerequisites

Many SI data-security controls depend on foundational tenant settings. Sensitivity labels must be able to apply to containers, audit logging must be on, label names must be clear, and the administrative roles that govern AI data security must themselves be controlled. This section sets those prerequisites, which the later sections of this baseline rely on.

### Policies
#### MS.SI.6.1v1
The sensitivity label scope SHALL include Groups & sites.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi61v1-instructions)

<!--Policy: MS.SI.6.1v1; Criticality: SHALL -->
- _Rationale:_ Labeling SharePoint sites, Microsoft 365 Groups, and Teams lets the agency apply container-level protections (privacy, external sharing, and unmanaged device access) to the places where Copilot and agents find their grounding data. It is also a prerequisite for MS.SI.7.4v1 and for site-level oversharing controls.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-3, AC-4, RA-2
- _MITRE ATT&CK TTP Mapping:_
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
    - [T1213.002: Sharepoint](https://attack.mitre.org/techniques/T1213/002/)
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)
- _Note:_ This policy requires that at least the labels intended for SharePoint sites and Teams be scoped to **Groups & sites**. Not every label in the taxonomy needs this scope.

#### MS.SI.6.2v1
Unified audit logging SHALL be enabled.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi62v1-instructions)

<!--Policy: MS.SI.6.2v1; Criticality: SHALL -->
- _Rationale:_ Copilot interactions, agent activities, DSPM for AI, Communication Compliance, and Insider Risk Management all depend on the unified audit log. If it is disabled, AI activity goes unrecorded and most of the detective controls in this baseline do nothing.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AU-2, AU-12
- _MITRE ATT&CK TTP Mapping:_
  - [T1562: Impair Defenses](https://attack.mitre.org/techniques/T1562/)
    - [T1562.008: Disable or Modify Cloud Logs](https://attack.mitre.org/techniques/T1562/008/)
- _Note:_ This policy duplicates MS.EXO.17.1v1 in the [Exchange Online baseline](exo.md) and is included here because so many SI controls depend on it. See also MS.SI.5.1v1 and MS.SI.11.4v1.

#### MS.SI.6.3v1
Sensitivity label display names SHALL be unique within the tenant.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi63v1-instructions)

<!--Policy: MS.SI.6.3v1; Criticality: SHALL -->
- _Rationale:_ Copilot and agents show sensitivity label display names on responses and referenced content, and users choose labels by display name. Duplicate display names (for example, a parent and a sublabel both named "Sensitive") cause users to misjudge how sensitive content is or to apply the wrong label. That weakens every label-based DLP, encryption, and Copilot control.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-4, RA-2
- _MITRE ATT&CK TTP Mapping:_
  - None
- _Note:_ Label **Name** values are already unique by design. This policy applies to **Display name**, the value users see. Display names for sublabels should be unique across the whole tenant, not only within their parent label.

#### MS.SI.6.4v1
Data Security AI Admin roles SHALL be assigned by least privilege.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi64v1-instructions)

<!--Policy: MS.SI.6.4v1; Criticality: SHALL -->
- _Rationale:_ Administrators of AI data security can change or disable DSPM for AI policies, and some AI viewer roles can see the content of user prompts and responses. Over-assigning these roles lets privileged insiders or compromised accounts weaken AI protections or view sensitive conversation content.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-2(7), AC-5, AC-6, AC-6(5)
- _MITRE ATT&CK TTP Mapping:_
  - [T1098: Account Manipulation](https://attack.mitre.org/techniques/T1098/)
    - [T1098.003: Additional Cloud Roles](https://attack.mitre.org/techniques/T1098/003/)
  - [T1562: Impair Defenses](https://attack.mitre.org/techniques/T1562/)
    - [T1562.001: Disable or Modify Tools](https://attack.mitre.org/techniques/T1562/001/)
- _Note:_ Roles that grant access to prompt and response *content* (for example, Data Security AI Content Viewer) should be limited to personnel with an investigative need and should be governed through Privileged Identity Management where supported. Agencies should keep a documented list of who holds each role and why.
<!-- VERIFY: exact Purview role group names (e.g., "Data Security AI Admin", "Data Security AI Viewer", "Data Security AI Content Viewer") and Entra "AI Administrator" role relationship. -->

### Resources

- [Enable sensitivity labels for Microsoft Teams, Microsoft 365 groups, and SharePoint sites \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/sensitivity-labels-teams-groups-sites)
- [Turn auditing on or off \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/audit-log-enable-disable)
- [Permissions for Data Security Posture Management for AI \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/ai-microsoft-purview-permissions)

### License Requirements

- N/A

### Implementation

#### MS.SI.6.1v1 Instructions

1. Enable sensitivity labels for containers if this has not already been done. Using Microsoft Graph PowerShell, set the `EnableMIPLabels` directory setting to `True`. Then, in Security & Compliance PowerShell, run `Execute-AzureAdLabelSync`.
2. Sign in to the **Microsoft Purview portal** and select **Solutions** > **Information Protection** > **Sensitivity labels**.
3. Edit each label intended for sites and Teams. Under **Define the scope for this label**, select **Groups & sites**, then configure the group and site settings (privacy, external user access, and external sharing).
4. Save the label and confirm that it is published (MS.SI.7.1v1).

To verify using Security & Compliance PowerShell:

```powershell
Get-Label | Select-Object DisplayName, ContentType
```

At least one label's `ContentType` should include `Site` and `UnifiedGroup`.

#### MS.SI.6.2v1 Instructions

1. Using Exchange Online PowerShell, run:

```powershell
Get-AdminAuditLogConfig | Format-List UnifiedAuditLogIngestionEnabled
```

2. If the value is `False`, run:

```powershell
Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
```

3. Alternatively, sign in to the **Microsoft Purview portal**, select **Solutions** > **Audit**, and if prompted, select **Start recording user and admin activity**.

#### MS.SI.6.3v1 Instructions

1. Using Security & Compliance PowerShell, run:

```powershell
Get-Label | Group-Object DisplayName | Where-Object Count -gt 1 | Select-Object Name, Count
```

2. If any results are returned, sign in to the **Microsoft Purview portal**, select **Information Protection** > **Sensitivity labels**, and edit the duplicated labels so that each **Display name** is unique.

#### MS.SI.6.4v1 Instructions

1. Sign in to the **Microsoft Purview portal**.
2. Select **Settings** > **Roles and scopes** > **Role groups**.
3. Review the membership of the Data Security AI role groups (for example, **Data Security AI Admin**, **Data Security AI Viewer**, and **Data Security AI Content Viewer**) and of any custom role group that contains their roles.
4. Remove any member who does not have a documented, current need for the role.
5. In the **Microsoft Entra admin center**, also review assignments of the **AI Administrator** directory role, and use Privileged Identity Management for eligible (just-in-time) assignment where possible.

## 7. Sensitivity Label Taxonomy

Copilot and agents respect and inherit sensitivity labels. A label applied to source content flows to generated content, and labels can restrict what Copilot may process. These protections work only if the agency has a published label taxonomy, labels are applied by default, downgrades are deliberate, and the sites and Teams in Copilot's scope are labeled. This section sets those requirements.

### Policies
#### MS.SI.7.1v1
A sensitivity label taxonomy SHALL be published to all users.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi71v1-instructions)

<!--Policy: MS.SI.7.1v1; Criticality: SHALL -->
- _Rationale:_ Users, Copilot, and agents can only apply and honor labels that have been published to them. A taxonomy available to everyone ensures that all content, including AI-generated content, can be classified and protected consistently.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-4, MP-3, RA-2
- _MITRE ATT&CK TTP Mapping:_
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
- _Note:_ The taxonomy should align with the agency's data categorization (for example, CUI categories) and should be kept small enough for users to apply correctly.

#### MS.SI.7.2v1
A default label SHALL be configured for new content.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi72v1-instructions)

<!--Policy: MS.SI.7.2v1; Criticality: SHALL -->
- _Rationale:_ Unlabeled content gets none of the label-based protections that govern Copilot and agents. A default label makes sure new documents, emails, meetings, and sites start with a baseline classification, which users can raise when needed.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-4, MP-3, RA-2
- _MITRE ATT&CK TTP Mapping:_
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)
  - [T1114: Email Collection](https://attack.mitre.org/techniques/T1114/)
    - [T1114.002: Remote Email Collection](https://attack.mitre.org/techniques/T1114/002/)
- _Note:_ The default label should be configured separately for documents, emails, meetings and calendar events, and groups and sites.

#### MS.SI.7.3v1
Users SHALL be required to provide a justification to remove a label or lower its classification.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi73v1-instructions)

<!--Policy: MS.SI.7.3v1; Criticality: SHALL -->
- _Rationale:_ Removing or lowering a label can strip encryption and remove Copilot and DLP restrictions. Requiring a justification discourages casual downgrades and creates an audit trail that can be reviewed when content is misused or exfiltrated.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-4, AU-2, AU-12
- _MITRE ATT&CK TTP Mapping:_
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
  - [T1562: Impair Defenses](https://attack.mitre.org/techniques/T1562/)

#### MS.SI.7.4v1
Sensitivity labels SHALL be applied to SharePoint sites and Teams in AI scope.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi74v1-instructions)

<!--Policy: MS.SI.7.4v1; Criticality: SHALL -->
- _Rationale:_ Copilot draws heavily on SharePoint sites and Teams. Container labels enforce privacy, external sharing, and access settings on those locations, and they give administrators a reliable signal for scoping Restricted Content Discovery, DLP, and DSPM for AI.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-3, AC-4, RA-2
- _MITRE ATT&CK TTP Mapping:_
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
    - [T1213.002: Sharepoint](https://attack.mitre.org/techniques/T1213/002/)
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)
- _Note:_ "In AI scope" means any site or Team not excluded from Copilot by Restricted Content Discovery (MS.SI.9.1v1). This policy requires MS.SI.6.1v1.

### Resources

- [Learn about sensitivity labels \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/sensitivity-labels)
- [Create and publish sensitivity labels \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/create-sensitivity-labels)
- [Microsoft 365 Copilot and sensitivity labels \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/ai-microsoft-purview-considerations)

### License Requirements

- Manual sensitivity labeling is included with M365 E3/G3. Default labeling for sites and groups, and mandatory labeling, may require additional Microsoft Purview Information Protection licensing for some workloads.
<!-- VERIFY: licensing for default sensitivity label for SharePoint document libraries / sites. -->

### Implementation

#### MS.SI.7.1v1 Instructions

1. Sign in to the **Microsoft Purview portal** and select **Solutions** > **Information Protection** > **Publishing policies** (label policies).
2. Create or edit a label policy that includes the agency's full label taxonomy.
3. Under **Assign admin units** / **Users and groups**, select **All users and groups**.
4. Complete the wizard and select **Submit**.

To verify using Security & Compliance PowerShell:

```powershell
Get-LabelPolicy | Select-Object Name, Labels, ExchangeLocation, Mode
```

At least one enabled policy should have `ExchangeLocation` set to `All` and should include the taxonomy labels.

#### MS.SI.7.2v1 Instructions

1. Sign in to the **Microsoft Purview portal**, select **Information Protection** > **Publishing policies**, and edit the label policy published to all users.
2. On the **Default settings for documents** page, select a **Default label**.
3. On the **Default settings for emails** page, select a **Default label**.
4. On the **Default settings for meetings and calendar events** page, select a **Default label**.
5. On the **Default settings for sites and groups** page, select a **Default label**.
6. Save the policy.

#### MS.SI.7.3v1 Instructions

1. Sign in to the **Microsoft Purview portal**, select **Information Protection** > **Publishing policies**, and edit the label policy published to all users.
2. On the **Policy settings** page, select **Users must provide a justification to remove a label or lower its classification**.
3. Save the policy.

To verify, confirm that `Get-LabelPolicy` shows the advanced setting `requiredowngradejustification` set to `true` (or the equivalent policy setting).
<!-- VERIFY: property name exposed by Get-LabelPolicy for downgrade justification. -->

#### MS.SI.7.4v1 Instructions

1. Confirm that MS.SI.6.1v1 is implemented.
2. In the label policy published to all users, select **Require users to apply a label to their groups and sites**, so that new sites and Teams must be labeled.
3. For existing sites, use SharePoint Online PowerShell to find unlabeled sites:

```powershell
Get-SPOSite -Limit All | Where-Object { -not $_.SensitivityLabel } | Select-Object Url
```

4. Apply a label to each unlabeled site in AI scope:

```powershell
Set-SPOSite -Identity <SiteUrl> -SensitivityLabel <LabelGuid>
```

5. For Teams and Microsoft 365 Groups, apply labels in the **Teams admin center** or the **Microsoft 365 admin center** (Teams & groups > Active teams & groups), or with `Set-UnifiedGroup -SensitivityLabelId`.

## 8. SI Content Detection & Labeling

Manual labeling alone cannot classify the large volume of existing content that Copilot and agents can reach. Auto-labeling, custom sensitive information types (SITs), and trainable classifiers let an agency find and label sensitive content at scale. Because mislabeling can either expose data or block legitimate work, these mechanisms must be tested and their label-override behavior chosen deliberately.

### Policies
#### MS.SI.8.1v1
Auto-labeling policies SHALL be configured for SharePoint, OneDrive, and Exchange.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi81v1-instructions)

<!--Policy: MS.SI.8.1v1; Criticality: SHALL -->
- _Rationale:_ Large stores of existing content are often unlabeled, and Copilot can surface that content to any user who has access. Service-side auto-labeling classifies data at rest and in transit across the main sources Copilot grounds on, so label-based protections also apply to content users never labeled.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-4, RA-2, SI-4
- _MITRE ATT&CK TTP Mapping:_
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
    - [T1213.002: Sharepoint](https://attack.mitre.org/techniques/T1213/002/)
  - [T1114: Email Collection](https://attack.mitre.org/techniques/T1114/)
    - [T1114.002: Remote Email Collection](https://attack.mitre.org/techniques/T1114/002/)

#### MS.SI.8.2v1
Auto-labeling policies SHALL be run in simulation mode before they are turned on.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi82v1-instructions)

<!--Policy: MS.SI.8.2v1; Criticality: SHALL -->
- _Rationale:_ Untested auto-labeling can apply encryption or restrictive labels to the wrong content, which breaks business processes and Copilot access. It can also miss sensitive content. Simulation shows which items would be labeled, so administrators can tune conditions before enforcement.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ CM-3, CM-3(2), CM-4
- _MITRE ATT&CK TTP Mapping:_
  - None
- _Note:_ Agencies should record the simulation results and the decision to enforce for each auto-labeling policy.

#### MS.SI.8.3v1
The option to replace existing labels SHALL be explicitly configured for auto-labeling policies.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi83v1-instructions)

<!--Policy: MS.SI.8.3v1; Criticality: SHALL -->
- _Rationale:_ Whether auto-labeling may replace an existing label decides whether a user's manual (possibly downgraded) label wins over the automated classification. Leaving this at its default without a decision can let mislabeled sensitive content keep weaker protections, or let auto-labeling override deliberate user choices. The agency should make this decision on purpose and document it.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-4, CM-6
- _MITRE ATT&CK TTP Mapping:_
  - [T1562: Impair Defenses](https://attack.mitre.org/techniques/T1562/)
- _Note:_ For most agencies, allowing auto-labeling to replace labels of the same or lower priority is the recommended configuration.
<!-- VERIFY: current UI option name ("Replace existing labels that have the same or lower priority") and which workloads (Exchange vs SharePoint/OneDrive) support it. -->

#### MS.SI.8.4v1
Custom sensitive information types SHALL be defined for organization-specific identifiers.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi84v1-instructions)

<!--Policy: MS.SI.8.4v1; Criticality: SHALL -->
- _Rationale:_ Built-in SITs detect common identifiers such as Social Security and credit card numbers, but they do not recognize agency-specific data such as case numbers, employee IDs, grant or contract numbers, and system identifiers. Custom SITs let DLP, auto-labeling, and Copilot controls recognize and protect that data.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-4, RA-2, SI-4
- _MITRE ATT&CK TTP Mapping:_
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)

#### MS.SI.8.5v1
Trainable classifiers SHOULD be validated before use in enforcing policies.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi85v1-instructions)

<!--Policy: MS.SI.8.5v1; Criticality: SHOULD -->
- _Rationale:_ Trainable classifiers are probabilistic, and their accuracy depends on the agency's own content. Validating them before enforcement keeps false positives (which block legitimate work) and false negatives (which leave sensitive content unprotected) at acceptable levels.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ CM-4, SI-4
- _MITRE ATT&CK TTP Mapping:_
  - None
- _Note:_ This applies to both prebuilt and custom trainable classifiers.

### Resources

- [Automatically apply a sensitivity label to Microsoft 365 data \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/apply-sensitivity-label-automatically)
- [Create custom sensitive information types \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/create-a-custom-sensitive-information-type)
- [Learn about trainable classifiers \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/trainable-classifiers-learn-about)

### License Requirements

- Service-side auto-labeling and trainable classifiers require M365 E5/G5, E5/G5 Compliance, or E5/G5 Information Protection and Governance.

### Implementation

#### MS.SI.8.1v1 Instructions

1. Sign in to the **Microsoft Purview portal** and select **Solutions** > **Information Protection** > **Auto-labeling policies** (or **Policies** > **Auto-labeling policies**).
2. Select **Create auto-labeling policy**, choose a template or **Custom**, and define the conditions (SITs, trainable classifiers, or both).
3. On the **Locations** page, select **Exchange email**, **SharePoint sites**, and **OneDrive accounts**.
4. Select the label to apply, and leave the policy in simulation mode (see MS.SI.8.2v1).

To verify using Security & Compliance PowerShell:

```powershell
Get-AutoSensitivityLabelPolicy | Select-Object Name, Mode, ExchangeLocation, SharePointLocation, OneDriveLocation
```

#### MS.SI.8.2v1 Instructions

1. When creating an auto-labeling policy, select **Run policy in simulation mode** on the **Decide if you want to test out the policy now or later** page.
2. After simulation completes, review the matched items on the policy's **Items to review** tab, and refine the conditions to address false positives or false negatives.
3. Once the results are acceptable, select **Turn on policy**.
4. Using `Get-AutoSensitivityLabelPolicy`, confirm that newly created policies show `Mode` as `TestWithoutNotifications` or `TestWithNotifications` before they are set to `Enable`.

#### MS.SI.8.3v1 Instructions

1. Sign in to the **Microsoft Purview portal**, select **Auto-labeling policies**, and edit each policy.
2. On the label settings page, set **Replace existing labels that have the same or lower priority** to match the agency's documented decision.
3. Record the decision and rationale for each policy in the agency's labeling documentation.
4. Using `Get-AutoSensitivityLabelPolicy | Select-Object Name, OverwriteLabel`, confirm that the configured value matches the documented decision.
<!-- VERIFY: PowerShell property (OverwriteLabel) and portal label. -->

#### MS.SI.8.4v1 Instructions

1. Identify organization-specific identifiers with the agency's data owners and records officer.
2. Sign in to the **Microsoft Purview portal** and select **Solutions** > **Information Protection** > **Classifiers** > **Sensitive info types** (or **Data classification** > **Classifiers**).
3. Select **Create sensitive info type** and define the primary element (regular expression, keyword list, or dictionary), supporting elements, confidence levels, and proximity.
4. Use **Test** to validate the SIT against sample content.
5. Reference the custom SIT in DLP, auto-labeling, and Copilot DLP policies (Sections 8 and 10).

To verify using Security & Compliance PowerShell:

```powershell
Get-DlpSensitiveInformationType | Where-Object Publisher -ne "Microsoft Corporation"
```

#### MS.SI.8.5v1 Instructions

1. Sign in to the **Microsoft Purview portal** and select **Classifiers** > **Trainable classifiers**.
2. For a custom classifier, provide seed content and review the predicted matches. Mark each one as a match or not a match until the classifier reaches acceptable accuracy, and then publish it.
3. For a prebuilt classifier, first use it in an auto-labeling policy in simulation mode (MS.SI.8.2v1), or in a DLP policy in test mode, and review the matches in **Content explorer** or **Activity explorer**.
4. Document the validation results and the date before using the classifier in any enforcing policy.

## 9. SI Oversharing Containment

Copilot and agents return any content the requesting user has permission to access. Overshared sites (for example, sites shared with "Everyone except external users" or with broad groups) become available to every user through Copilot, even if no one would have found them by browsing. This section requires the agency to assess oversharing risk before enabling AI, to exclude unapproved sites from Copilot discovery, and to evaluate new sites on an ongoing basis.

### Policies
#### MS.SI.9.1v1
Restricted Content Discovery SHALL be applied to SharePoint sites not approved for Microsoft 365 Copilot.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi91v1-instructions)

<!--Policy: MS.SI.9.1v1; Criticality: SHALL -->
- _Rationale:_ Restricted Content Discovery (RCD) stops a site's content from being surfaced by Copilot and organization-wide search while leaving existing permissions in place. Applying it to every site not yet reviewed and approved for Copilot contains oversharing risk while permissions are fixed, so Copilot only grounds on content the agency has evaluated.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-3, AC-4, AC-6
- _MITRE ATT&CK TTP Mapping:_
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
    - [T1213.002: Sharepoint](https://attack.mitre.org/techniques/T1213/002/)
  - [T1619: Cloud Storage Object Discovery](https://attack.mitre.org/techniques/T1619/)
- _Note:_ This policy is an *oversharing containment* control. It applies RCD to sites that have not been approved, for any reason, until they have been reviewed. MS.SI.10.7v1 is a separate *data protection* control: it applies RCD to sites known to hold restricted data, whether or not their permissions are correct. RCD does not change permissions, and users with access can still open the content directly. RCD is not a substitute for fixing permissions.

#### MS.SI.9.2v1
A data risk assessment SHALL be completed before AI enablement.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi92v1-instructions)

<!--Policy: MS.SI.9.2v1; Criticality: SHALL -->
- _Rationale:_ Enabling Copilot or agents over a tenant that has not been assessed for oversharing can instantly expose sensitive content to every licensed user. A data risk assessment finds overshared sites, unlabeled sensitive content, and excessive permissions, so they can be fixed or contained (MS.SI.9.1v1) before AI is turned on.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ RA-3, RA-2, CA-2
- _MITRE ATT&CK TTP Mapping:_
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
    - [T1213.002: Sharepoint](https://attack.mitre.org/techniques/T1213/002/)
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)
- _Note:_ "AI enablement" includes assigning Microsoft 365 Copilot licenses, enabling Copilot Chat grounding on work data, and deploying agents with SharePoint or OneDrive knowledge sources. The assessment should be repeated before each significant expansion of AI scope.

#### MS.SI.9.3v1
A defined process SHALL evaluate newly created SharePoint sites for Restricted Content Discovery.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi93v1-instructions)

<!--Policy: MS.SI.9.3v1; Criticality: SHALL -->
- _Rationale:_ New sites are created all the time and may be overshared or hold sensitive data from the start. Without a defined evaluation process, new sites bypass the review that MS.SI.9.1v1 applies to existing ones and become available to Copilot by default.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ CM-8, RA-3, AC-3
- _MITRE ATT&CK TTP Mapping:_
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
    - [T1213.002: Sharepoint](https://attack.mitre.org/techniques/T1213/002/)
- _Note:_ The process should define who evaluates new sites, the criteria used (for example, sensitivity label, sharing scope, and content type), and the maximum time between site creation and evaluation.

### Resources

- [Restrict discovery of SharePoint sites and content \| Microsoft Learn](https://learn.microsoft.com/en-us/sharepoint/restricted-content-discovery)
- [Data risk assessments in DSPM for AI \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/dspm-for-ai-data-risk-assessment)
- [Data access governance reports \| Microsoft Learn](https://learn.microsoft.com/en-us/sharepoint/data-access-governance-reports)
<!-- VERIFY: DSPM for AI data risk assessment doc URL. -->

### License Requirements

- Restricted Content Discovery and data access governance reports require SharePoint Advanced Management, which is included with Microsoft 365 Copilot licenses or available as a standalone license.
- DSPM for AI data risk assessments may require M365 E5/G5 or E5/G5 Compliance.
<!-- VERIFY: SAM-included-with-Copilot status in GCC/GCC High. -->

### Implementation

#### MS.SI.9.1v1 Instructions

1. Maintain a list of SharePoint sites approved for Copilot, based on the data risk assessment (MS.SI.9.2v1).
2. For each site not on the approved list, using SharePoint Online PowerShell, run:

```powershell
Set-SPOSite -Identity <SiteUrl> -RestrictContentOrgWideSearch $true
```

3. Alternatively, sign in to the **SharePoint admin center**, select **Sites** > **Active sites**, select the site, and turn on **Restricted content discovery** in the **Settings** tab.
4. To verify, run:

```powershell
Get-SPOSite -Limit All | Select-Object Url, RestrictContentOrgWideSearch
```

#### MS.SI.9.2v1 Instructions

1. Sign in to the **Microsoft Purview portal** and select **Solutions** > **DSPM for AI** > **Data risk assessments**.
2. Review the default assessment and create a custom assessment that covers all SharePoint sites in scope for AI enablement.
3. In the **SharePoint admin center**, select **Reports** > **Data access governance** and run the oversharing reports (for example, sites shared with "Everyone except external users" and sharing links).
4. Record the findings, remediation actions, and residual risk, and get sign-off from the system owner and the information security function before enabling AI.

#### MS.SI.9.3v1 Instructions

1. Document a site evaluation process that names the responsible role, the evaluation criteria, and the maximum time from creation to evaluation.
2. Find new sites using the **SharePoint admin center** > **Sites** > **Active sites** (sorted by **Created** date), Purview audit records for site creation, or data access governance reports.
3. For each new site, apply Restricted Content Discovery (MS.SI.9.1v1) by default until the site has been evaluated and approved, or have the evaluation approve the site for Copilot.
4. Keep records of each evaluation.

## 10. DLP for SI Surfaces

Microsoft Purview DLP can be scoped to Microsoft 365 Copilot and Copilot Chat. It can stop Copilot from processing prompts that contain sensitive information, stop it from using labeled content, and limit its grounding sources. Endpoint DLP can also govern what users paste or upload into third-party generative AI sites. This section sets the DLP controls for SI surfaces and requires a documented decision on how each encrypting label interacts with SI.

### Policies
#### MS.SI.10.1v1
A defined SI disposition SHALL exist for every sensitivity label that applies encryption.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi101v1-instructions)

<!--Policy: MS.SI.10.1v1; Criticality: SHALL -->
- _Rationale:_ How Copilot treats encrypted content depends on the usage rights the label grants. For example, Copilot can return content only to users who hold the EXTRACT right. Without a documented decision, encrypted content may be summarized more widely than intended, or excluded in ways that break approved workflows.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-3, AC-4, SC-28
- _MITRE ATT&CK TTP Mapping:_
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
- _Note:_ An "SI disposition" is a documented decision, for each encrypting label, on whether Copilot and agents may process content with that label and how this is enforced. For example: allowed (users hold EXTRACT), blocked through DLP (MS.SI.10.6v1), or blocked by withholding EXTRACT. Double Key Encryption content cannot be processed by Copilot.

#### MS.SI.10.2v1
Microsoft 365 Copilot and Copilot Chat SHOULD be blocked from processing prompts containing sensitive information types.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi102v1-instructions)

<!--Policy: MS.SI.10.2v1; Criticality: SHOULD -->
- _Rationale:_ Users may paste sensitive data such as PII, CUI identifiers, or credentials into prompts. Blocking Copilot from processing those prompts keeps the sensitive data out of AI processing, generated responses, and downstream grounding or web queries.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-4, SC-7, SI-4
- _MITRE ATT&CK TTP Mapping:_
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
- _Note:_ Agencies should include both built-in SITs and the custom SITs defined under MS.SI.8.4v1.

#### MS.SI.10.3v1
Microsoft 365 Copilot and Copilot Chat SHOULD be blocked from using external web search as a grounding source for prompts containing sensitive information types.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi103v1-instructions)

<!--Policy: MS.SI.10.3v1; Criticality: SHOULD -->
- _Rationale:_ When Copilot grounds a response with web search, it sends a query derived from the prompt to an external search service. If the prompt contains sensitive information, that information can end up in the query and leave the agency's compliance boundary.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-4, SC-7
- _MITRE ATT&CK TTP Mapping:_
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
  - [T1048: Exfiltration Over Alternative Protocol](https://attack.mitre.org/techniques/T1048/)
- _Note:_ Agencies that do not need web grounding can instead disable web search for Copilot entirely in the Microsoft 365 admin center.
<!-- VERIFY: whether Purview DLP for Copilot offers a "block web search" action for SIT prompts, and its exact name. -->

#### MS.SI.10.4v1
Endpoint DLP SHOULD monitor third-party generative AI sites.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi104v1-instructions)

<!--Policy: MS.SI.10.4v1; Criticality: SHOULD -->
- _Rationale:_ Users may paste or upload agency data into consumer or third-party generative AI services that sit outside the agency's compliance boundary and contracts. Endpoint DLP gives visibility into, and optionally blocks, sensitive data shared with those sites from managed devices.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-4, SC-7, SI-4
- _MITRE ATT&CK TTP Mapping:_
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
- _Note:_ Agencies should begin in audit mode and move to block or block-with-override for sensitive content once the observed activity is understood. See also the DLP policies in the [Defender baseline](defender.md) (MS.DEFENDER.4).

#### MS.SI.10.5v1
Microsoft 365 Copilot and Copilot Chat SHOULD be blocked from using external email as grounding data.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi105v1-instructions)

<!--Policy: MS.SI.10.5v1; Criticality: SHOULD -->
- _Rationale:_ Email from outside the organization is attacker-controllable content. When Copilot grounds on external email, a crafted message can carry indirect prompt injection that manipulates Copilot's responses or actions, for example by inserting malicious links or steering it to exfiltrate data. Excluding external email from grounding removes this injection path.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-4, SI-3, SI-10
- _MITRE ATT&CK TTP Mapping:_
  - [T1566: Phishing](https://attack.mitre.org/techniques/T1566/)
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
- _Note:_ This threat is also described in MITRE ATLAS as [AML.T0051.001: LLM Prompt Injection: Indirect](https://atlas.mitre.org/techniques/AML.T0051.001).
<!-- VERIFY: control used to exclude external email from Copilot grounding (DLP condition on sender domain vs Copilot setting) and its name. -->

#### MS.SI.10.6v1
Microsoft 365 Copilot and Copilot Chat SHOULD be blocked from processing files, emails, or chats with designated sensitivity labels.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi106v1-instructions)

<!--Policy: MS.SI.10.6v1; Criticality: SHOULD -->
- _Rationale:_ Some classifications of content should never be summarized or reused by AI, regardless of user permissions. A DLP policy that blocks Copilot from processing items with those labels prevents the content from appearing in responses or generated artifacts.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-3, AC-4
- _MITRE ATT&CK TTP Mapping:_
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
  - [T1114: Email Collection](https://attack.mitre.org/techniques/T1114/)
    - [T1114.002: Remote Email Collection](https://attack.mitre.org/techniques/T1114/002/)
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
- _Note:_ The "designated" labels should be the ones whose SI disposition (MS.SI.10.1v1) is "blocked."

#### MS.SI.10.7v1
Restricted Content Discovery SHOULD be used to block Microsoft 365 Copilot from accessing restricted SharePoint sites.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi107v1-instructions)

<!--Policy: MS.SI.10.7v1; Criticality: SHOULD -->
- _Rationale:_ Some sites hold data that should not be surfaced by Copilot even to users with legitimate access, such as legal, HR investigation, or law enforcement sensitive content. Applying Restricted Content Discovery to these sites keeps their content out of Copilot responses and organization-wide search, adding protection on top of item-level labels.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-3, AC-4
- _MITRE ATT&CK TTP Mapping:_
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
    - [T1213.002: Sharepoint](https://attack.mitre.org/techniques/T1213/002/)
- _Note:_ This policy is a *data protection* control that applies RCD to sites known to hold restricted data, independent of permission hygiene. MS.SI.9.1v1 is the *oversharing containment* control that applies RCD to sites not yet approved for Copilot. A site may fall under both. RCD does not affect agents that are explicitly given the site as a knowledge source; govern those under MS.SI.13.2v1.
<!-- VERIFY: RCD behavior for Copilot Studio / declarative agents with explicit SharePoint knowledge sources. -->

### Resources

- [Microsoft Purview DLP for Microsoft 365 Copilot and Cowork \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/dlp-microsoft365-copilot-location-learn-about)

- [Restrict discovery of SharePoint sites and content \| Microsoft Learn](https://learn.microsoft.com/en-us/sharepoint/restricted-content-discovery)

- [Microsoft 365 Copilot and usage rights for encrypted content \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/ai-microsoft-purview-considerations)

- [Learn about Endpoint data loss prevention \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/endpoint-dlp-learn-about)

### License Requirements

- DLP for Microsoft 365 Copilot and Copilot Chat, and Endpoint DLP, require M365 E5/G5, E5/G5 Compliance, or E5/G5 Information Protection and Governance.
- Restricted Content Discovery requires SharePoint Advanced Management (included with Microsoft 365 Copilot licenses).
<!-- VERIFY: DLP-for-Copilot licensing (E5 vs Copilot license) and pay-as-you-go requirements for some Copilot DLP actions. -->

### Implementation

#### MS.SI.10.1v1 Instructions

1. Using Security & Compliance PowerShell, list the labels that apply encryption:

```powershell
Get-Label | Where-Object { $_.EncryptionEnabled -eq $true } | Select-Object DisplayName, Guid
```

2. For each label, document its SI disposition (allowed, blocked through DLP, or blocked by withholding usage rights) and the rationale.
3. For labels that are allowed, confirm that the intended users hold both the **VIEW** and **EXTRACT** usage rights.
4. For labels that are blocked through DLP, include them in the policy under [MS.SI.10.6v1](#mssi106v1-instructions).
5. Review the dispositions whenever a new encrypting label is created.

#### MS.SI.10.2v1 Instructions

1. Sign in to the **Microsoft Purview portal** and select **Solutions** > **Data loss prevention** > **Policies** > **Create policy**.
2. Choose **Custom** > **Custom policy**.
3. On the **Locations** page, select **Microsoft 365 Copilot and Copilot Chat** only.
4. Create a rule with the condition **Content contains** > **Sensitive info types**, and add the built-in and custom SITs in scope.
5. Under **Actions**, select **Prevent Copilot from processing content** (restrict Copilot from responding to the prompt).
6. Turn on the policy in simulation mode, review the matches, and then enforce it.
<!-- VERIFY: exact action name for prompt-based SIT blocking in the Copilot DLP location. -->

#### MS.SI.10.3v1 Instructions

1. In the **Microsoft Purview portal**, edit the DLP policy scoped to **Microsoft 365 Copilot and Copilot Chat** (MS.SI.10.2v1), or create a new one.
2. Create a rule with the condition **Content contains** > **Sensitive info types**.
3. Under **Actions**, select the action that prevents Copilot from using web search for matching prompts.
4. Alternatively, if web grounding is not required, sign in to the **Microsoft 365 admin center**, select **Copilot** > **Settings** > **Web search for Microsoft 365 Copilot and Copilot Chat**, and turn off web search.
<!-- VERIFY: DLP action name and M365 admin center setting path for web search. -->

#### MS.SI.10.4v1 Instructions

1. Onboard Windows and macOS devices to Microsoft Purview (through Microsoft Defender for Endpoint or the Purview onboarding package). For non-Edge browsers, deploy the Microsoft Purview browser extension.
2. Sign in to the **Microsoft Purview portal** and select **Settings** > **Data loss prevention** > **Endpoint DLP settings** > **Browser and domain restrictions to sensitive data** > **Sensitive service domain groups**.
3. Create a domain group for third-party generative AI sites (or use the generative AI groups provided by DSPM for AI).
4. Create a DLP policy scoped to **Devices**, with conditions for the agency's SITs and labels and the action **Audit** (initially) for **Paste to supported browsers** and **Upload to a restricted cloud service domain**, targeting the generative AI domain group.
5. Alternatively, in **DSPM for AI** > **Recommendations**, enable the one-click policies that detect sensitive information shared with AI sites.
6. Review the activity in **Activity explorer**, then move the actions to **Block** or **Block with override** as appropriate.
<!-- VERIFY: DSPM for AI one-click policy names and whether a built-in "Generative AI websites" domain group exists. -->

#### MS.SI.10.5v1 Instructions

1. Sign in to the **Microsoft Purview portal** and edit or create a DLP policy scoped to **Microsoft 365 Copilot and Copilot Chat**.
2. Create a rule that excludes email received from outside the organization from Copilot processing (for example, using a sender condition such as **Sender is external**, together with the action **Prevent Copilot from processing content**).
3. Turn on the policy in simulation mode, validate the results, and then enforce it.
<!-- VERIFY: whether this is achievable via DLP condition, Copilot admin setting, or not yet available; adjust instructions accordingly. -->

#### MS.SI.10.6v1 Instructions

1. Sign in to the **Microsoft Purview portal** and select **Data loss prevention** > **Policies** > **Create policy** > **Custom** > **Custom policy**.
2. On the **Locations** page, select **Microsoft 365 Copilot and Copilot Chat**.
3. Create a rule with the condition **Content contains** > **Sensitivity labels**, and select the labels whose SI disposition is "blocked" (MS.SI.10.1v1).
4. Under **Actions**, select **Prevent Copilot from processing content**.
5. Turn on the policy in simulation mode, validate the results, and then enforce it.
<!-- VERIFY: whether Teams chats are covered by the label-based Copilot DLP condition. -->

#### MS.SI.10.7v1 Instructions

1. Identify SharePoint sites that hold restricted data, based on sensitivity labels, data owner designation, or data access governance reports.
2. For each site, run `Set-SPOSite -Identity <SiteUrl> -RestrictContentOrgWideSearch $true`, or turn on **Restricted content discovery** in the **SharePoint admin center** (see [MS.SI.9.1v1](#mssi91v1-instructions)).
3. Keep a list of restricted sites, and review it whenever MS.SI.9.3v1 site evaluations identify new restricted sites.

## 11. DSPM, Audit & Records for AI

Microsoft Purview Data Security Posture Management (DSPM) for AI centralizes visibility into how users and agents interact with AI, identifies data-security risks, and recommends policies. AI interactions are also federal records that must be audited, retained, and discoverable. This section requires DSPM for AI to be activated and acted on, and requires AI interactions to be retained and discoverable in line with records and logging requirements.

### Policies
#### MS.SI.11.1v1
Data Security Posture Management SHALL be activated for AI apps and agents.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi111v1-instructions)

<!--Policy: MS.SI.11.1v1; Criticality: SHALL -->
- _Rationale:_ DSPM for AI gives the agency a single view of AI usage, sensitive data in prompts and responses, oversharing risks, and unprotected AI apps, across Copilot, agents, and third-party AI services. Without it, AI data-security risks are scattered across many tools and easy to miss.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ CA-7, RA-3, SI-4
- _MITRE ATT&CK TTP Mapping:_
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)
- _Note:_ "Activated" means the DSPM for AI prerequisites are met: auditing is enabled, devices are onboarded, and the browser extension is deployed where needed. It also means the DSPM for AI data-collection policies have been turned on.
<!-- VERIFY: product naming — DSPM for AI may be merged into Purview DSPM ("AI observability") in late 2026. -->

#### MS.SI.11.2v1
Data Security Posture Management recommendations for AI SHOULD be evaluated and either completed or dismissed on record.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi112v1-instructions)

<!--Policy: MS.SI.11.2v1; Criticality: SHOULD -->
- _Rationale:_ DSPM for AI recommendations identify specific missing protections. Each one should be either implemented or explicitly dismissed with a documented rationale, so that no identified risk goes unaddressed by default and the agency's risk acceptance decisions can be audited.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ CA-5, RA-7
- _MITRE ATT&CK TTP Mapping:_
  - None

#### MS.SI.11.3v1
Data Security Posture Management reports SHOULD be reviewed on a defined recurring cadence.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi113v1-instructions)

<!--Policy: MS.SI.11.3v1; Criticality: SHOULD -->
- _Rationale:_ AI usage and the risks that come with it change quickly as users adopt new tools and agents. Regular review of DSPM for AI reports catches emerging risks, such as rising sensitive-data sharing with AI apps or new unprotected agents, before they become incidents.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AU-6, CA-7
- _MITRE ATT&CK TTP Mapping:_
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
- _Note:_ DSPM for AI reports should be reviewed at least monthly, and the review should be documented.

#### MS.SI.11.4v1
Audit log retention for AI interactions SHALL meet records requirements.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi114v1-instructions)

<!--Policy: MS.SI.11.4v1; Criticality: SHALL -->
- _Rationale:_ Audit (Standard) keeps records for 180 days by default, which may be shorter than federal logging and records requirements. Audit retention policies for AI record types ensure that evidence of AI interactions is available for the full period required for investigations and compliance.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AU-4, AU-11
- _MITRE ATT&CK TTP Mapping:_
  - [T1562: Impair Defenses](https://attack.mitre.org/techniques/T1562/)
    - [T1562.008: Disable or Modify Cloud Logs](https://attack.mitre.org/techniques/T1562/008/)
  - [T1070: Indicator Removal](https://attack.mitre.org/techniques/T1070/)
- _Note:_ Retention should meet the requirements of M-26-14 (see MS.SI.5.1v1) and the agency's records schedules. Agencies may meet this requirement by keeping the records in their SIEM instead of, or in addition to, Purview Audit. MS.SI.6.2v1 is a prerequisite.

#### MS.SI.11.5v1
Retention policies SHALL cover AI interactions.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi115v1-instructions)

<!--Policy: MS.SI.11.5v1; Criticality: SHALL -->
- _Rationale:_ Copilot and agent prompts and responses may be federal records. Without a retention policy, they can be deleted by users or by default lifecycle processes before their required retention period ends. Retention policies keep the interaction *content* for as long as required and dispose of it when permitted.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AU-11, SI-12
- _MITRE ATT&CK TTP Mapping:_
  - [T1070: Indicator Removal](https://attack.mitre.org/techniques/T1070/)
- _Note:_ Retention periods should be set in consultation with the agency records officer and the applicable NARA records schedules. MS.SI.11.4v1 covers audit records of the interactions. This policy covers the interaction content itself.

#### MS.SI.11.6v1
AI interactions SHALL be discoverable through eDiscovery.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi116v1-instructions)

<!--Policy: MS.SI.11.6v1; Criticality: SHALL -->
- _Rationale:_ AI interactions may be subject to FOIA requests, litigation holds, congressional inquiries, and investigations. The agency must be able to find, preserve, and export them with the same eDiscovery tools it uses for email and chat.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AU-7, AU-9, SI-12
- _MITRE ATT&CK TTP Mapping:_
  - [T1070: Indicator Removal](https://attack.mitre.org/techniques/T1070/)
- _Note:_ Agencies should check that interactions with each AI surface in use (Microsoft 365 Copilot, Copilot Chat, Copilot Studio agents, and connected third-party AI apps) are discoverable, because coverage may differ between surfaces.

### Resources

- [Learn about Data Security Posture Management for AI \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/ai-microsoft-purview)
- [Manage audit log retention policies \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/audit-log-retention-policies)
- [Learn about retention for Copilot and AI apps \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/retention-policies-copilot)
- [Search for and delete Copilot data in eDiscovery \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/edisc-search-copilot-data)

### License Requirements

- DSPM for AI requires M365 E5/G5 or E5/G5 Compliance for full functionality.
- Audit retention policies and retention beyond the Audit (Standard) default require Microsoft Purview Audit (Premium) (M365 E5/G5 or E5/G5 Compliance). Retention up to 10 years requires the 10-Year Audit Log Retention add-on.
- eDiscovery (Premium) features such as review sets require M365 E5/G5 or E5/G5 eDiscovery and Audit.
<!-- VERIFY: retention policies for "Enterprise AI apps"/"Other AI apps" locations may require pay-as-you-go billing. -->

### Implementation

#### MS.SI.11.1v1 Instructions

1. Confirm that unified audit logging is enabled (MS.SI.6.2v1).
2. Sign in to the **Microsoft Purview portal** and select **Solutions** > **DSPM for AI**.
3. On the **Overview** page, complete the **Get started** steps: activate Microsoft Purview Audit, install the Microsoft Purview browser extension, onboard devices to Microsoft Purview, and extend insights for data discovery.
4. Under **Recommendations** (or **Policies**), turn on the data-collection policies for Microsoft Copilot experiences, enterprise AI apps, and other AI apps.

#### MS.SI.11.2v1 Instructions

1. Sign in to the **Microsoft Purview portal** and select **DSPM for AI** > **Recommendations**.
2. For each recommendation, either complete it (for example, create the recommended policy) or select **Dismiss**.
3. For each dismissed recommendation, record the rationale, the approver, and the date in the agency's risk register or system security plan.
4. Re-evaluate recommendations when new ones appear and at least during each monthly review (MS.SI.11.3v1).

#### MS.SI.11.3v1 Instructions

1. Assign responsibility for reviewing DSPM for AI reports.
2. At least monthly, sign in to the **Microsoft Purview portal**, select **DSPM for AI** > **Reports**, and review the AI interaction, sensitive data, and risky usage reports. Also review **Activity explorer**.
3. Document each review, including findings and follow-up actions.

#### MS.SI.11.4v1 Instructions

1. Sign in to the **Microsoft Purview portal** and select **Solutions** > **Audit** > **Audit retention policies** (or **Policies**).
2. Select **Create audit retention policy**.
3. Under **Record type**, select **CopilotInteraction** and any other AI-related record types (for example, Copilot Studio and AI app interaction record types).
4. Set **Duration** to meet M-26-14 and the agency's records requirements, and set a high **Priority**.
5. Save the policy.

Alternatively, using Security & Compliance PowerShell:

```powershell
New-UnifiedAuditLogRetentionPolicy -Name "AI Interactions" -RecordTypes CopilotInteraction -RetentionDuration <Duration> -Priority 100
```

#### MS.SI.11.5v1 Instructions

1. Sign in to the **Microsoft Purview portal** and select **Solutions** > **Data Lifecycle Management** > **Policies** > **Retention policies** > **New retention policy**.
2. On the **Locations** page, select the AI locations in use: **Microsoft Copilot experiences**, **Enterprise AI apps**, and **Other AI apps**.
3. Configure **Retain items for a specific period** (and optionally **Delete items automatically**) according to the applicable records schedule.
4. Complete the wizard and confirm that the policy status is **On**.
<!-- VERIFY: retention location names (previously "Teams chats and Copilot interactions"). -->

#### MS.SI.11.6v1 Instructions

1. Sign in to the **Microsoft Purview portal** and select **Solutions** > **eDiscovery** > **Cases**.
2. Create a test case, then add a search using the data sources (user mailboxes) of a test user who has used Copilot.
3. Add a condition to filter for Copilot interactions (for example, **Type** is **Copilot activity**, or the item class for Copilot interactions), and run the search.
4. Confirm that prompts and responses from each AI surface in use are returned, and that they can be held and exported.
5. Document the results, and repeat the test when new AI surfaces are adopted.
<!-- VERIFY: eDiscovery condition name for Copilot/AI interactions. -->

## 12. SI Communications Compliance & Insider Risk

Preventive controls cannot catch every misuse of AI. Users may try to jailbreak Copilot, generate inappropriate content, or use AI to collect and exfiltrate sensitive data, and some AI surfaces do not yet support preventive controls. This section requires detective controls through Communication Compliance and Insider Risk Management, with assigned reviewers and defined triage cadences, and compensating controls wherever preventive AI controls are unavailable.

### Policies
#### MS.SI.12.1v1
A Communication Compliance policy SHOULD be scoped to AI interactions.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi121v1-instructions)

<!--Policy: MS.SI.12.1v1; Criticality: SHOULD -->
- _Rationale:_ Communication Compliance can detect prompts and responses that contain sensitive information, attempts at prompt injection or jailbreaking, and inappropriate or policy-violating content. This gives the agency visibility into AI misuse that DLP alone does not provide.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AU-6, SI-4
- _MITRE ATT&CK TTP Mapping:_
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
- _Note:_ Agencies should consult privacy, legal, and labor relations staff before deploying Communication Compliance, and should turn on pseudonymization of user names for reviewers.

#### MS.SI.12.2v1
Reviewers SHALL be assigned and triage SHALL occur on a defined cadence.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi122v1-instructions)

<!--Policy: MS.SI.12.2v1; Criticality: SHALL -->
- _Rationale:_ Detective policies that nobody reviews give no protection. Assigning reviewers and requiring triage on a set cadence ensures that AI-related Communication Compliance and Insider Risk alerts are acted on while they still matter.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AU-6, IR-4, IR-5
- _MITRE ATT&CK TTP Mapping:_
  - None
- _Note:_ Alerts from Communication Compliance and Insider Risk Management policies scoped to AI interactions should be triaged at least weekly. Agencies should assign at least two reviewers per policy to provide coverage during absences.

#### MS.SI.12.3v1
Insider Risk Management policies SHOULD include risky AI usage indicators.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi123v1-instructions)

<!--Policy: MS.SI.12.3v1; Criticality: SHOULD -->
- _Rationale:_ Insiders can use AI to quickly find, aggregate, and extract sensitive information they would otherwise struggle to locate. Risky AI usage indicators, such as prompts seeking sensitive information, responses containing sensitive data, and prompt injection attempts, let Insider Risk Management connect AI activity with other risky behavior.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-2(12), AU-6, SI-4
- _MITRE ATT&CK TTP Mapping:_
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
- _Note:_ Agencies should consult privacy and legal staff before deploying Insider Risk Management, in line with the agency's insider threat program.

#### MS.SI.12.4v1
Compensating detective controls SHALL exist where preventive AI controls are unavailable.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi124v1-instructions)

<!--Policy: MS.SI.12.4v1; Criticality: SHALL -->
- _Rationale:_ Preventive SI controls, such as DLP for Copilot, agent Conditional Access, and threat detection for agents, may be in preview, unsupported in some clouds, or unavailable for some AI surfaces or third-party agents. Detective controls make sure that activity on those surfaces is at least monitored and alerted on, so the gap in preventive coverage is not a blind spot.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AU-6, CA-7, SI-4
- _MITRE ATT&CK TTP Mapping:_
  - [T1562: Impair Defenses](https://attack.mitre.org/techniques/T1562/)
- _Note:_ Agencies should keep a mapping of each SHALL or SHOULD policy in this baseline that cannot be implemented to the compensating detective control used in its place.

### Resources

- [Communication Compliance for Copilot and AI apps \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/communication-compliance-copilot)
- [Insider Risk Management policy templates \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/insider-risk-management-policy-templates)
- [Create alert policies \| Microsoft Learn](https://learn.microsoft.com/en-us/purview/alert-policies)

### License Requirements

- Communication Compliance and Insider Risk Management require M365 E5/G5, E5/G5 Compliance, or E5/G5 Insider Risk Management.

### Implementation

#### MS.SI.12.1v1 Instructions

1. Sign in to the **Microsoft Purview portal** and select **Solutions** > **Communication Compliance** > **Policies** > **Create policy**.
2. Select the template for detecting Microsoft 365 Copilot and AI interactions, or create a custom policy.
3. On the locations page, select the AI locations: **Microsoft Copilot experiences**, **Enterprise AI apps**, and **Other AI apps**.
4. Configure conditions such as sensitive information types, trainable classifiers (for example, prompt shields / jailbreak detection, or inappropriate content), and reviewers (see MS.SI.12.2v1).
5. Alternatively, in **DSPM for AI** > **Recommendations**, enable the one-click Communication Compliance policy for AI interactions.
<!-- VERIFY: Communication Compliance AI template name and AI location names. -->

#### MS.SI.12.2v1 Instructions

1. For each Communication Compliance and Insider Risk Management policy scoped to AI, confirm that at least two **Reviewers** (Communication Compliance) or **Insider Risk Management Analysts/Investigators** are assigned.
2. Document the triage cadence (at least weekly) and the escalation path to incident response.
3. Keep evidence of triage, such as alert status changes or review logs, for audit purposes.

#### MS.SI.12.3v1 Instructions

1. Sign in to the **Microsoft Purview portal** and select **Solutions** > **Insider Risk Management** > **Settings** > **Policy indicators**.
2. Under **Risky AI usage indicators**, select the indicators relevant to the agency (for example, prompts containing sensitive information, responses containing sensitive information, and prompt injection attempts).
3. Select **Policies** > **Create policy**, choose the **Risky AI usage** template (or add the indicators to existing data-theft or data-leak policies), and complete the wizard.
<!-- VERIFY: "Risky AI usage" template/indicator names and GA status. -->

#### MS.SI.12.4v1 Instructions

1. Review each policy in this baseline and identify any that cannot be implemented in the agency's tenant or cloud environment.
2. For each one, implement a compensating detective control. Options include Purview alert policies on AI audit record types (for example, `CopilotInteraction`), SIEM analytics rules on agent sign-ins and AI activities, Communication Compliance (MS.SI.12.1v1), Insider Risk Management (MS.SI.12.3v1), or Microsoft Defender for Cloud Apps discovery of AI apps.
3. Document the mapping between each unavailable preventive control and its compensating control in the system security plan.
4. Review the mapping at least quarterly, and when new preventive controls become available.

## 13. Copilot Studio Agent Governance

Copilot Studio lets users build agents with their own knowledge sources, connectors, actions, and publishing channels. Without governance, these agents can run up unmanaged costs, ground on unprotected data, reach external channels, and combine connectors in ways that move data out of the agency. This section governs Copilot Studio billing, knowledge sources, channels, DLP, connector policies, and runtime threat detection.

### Policies
#### MS.SI.13.1v1
Pay-as-you-go billing for agents SHALL NOT be enabled.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi131v1-instructions)

<!--Policy: MS.SI.13.1v1; Criticality: SHALL -->
- _Rationale:_ Pay-as-you-go billing lets agents be used, and costs be incurred, outside the agency's licensing and procurement controls. It can also let unlicensed users use agents grounded on organizational data. Disabling it keeps agent usage within approved, budgeted licenses.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ CM-7, CM-11, SA-4
- _MITRE ATT&CK TTP Mapping:_
  - [T1496: Resource Hijacking](https://attack.mitre.org/techniques/T1496/)
- _Note:_ Some Purview AI features, such as data security for non-Microsoft AI apps, may require pay-as-you-go billing. This policy applies only to pay-as-you-go billing for agent usage. Agencies needing pay-as-you-go for Purview features should configure it separately and document the exception.
<!-- VERIFY: scope of "pay-as-you-go billing for agents" setting(s) in M365 admin center and PPAC billing policies. -->

#### MS.SI.13.2v1
Agent knowledge sources SHALL be limited to those carrying required protection.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi132v1-instructions)

<!--Policy: MS.SI.13.2v1; Criticality: SHALL -->
- _Rationale:_ An agent's knowledge sources determine what data it can reveal to its users. Restricting knowledge sources to sensitivity-labeled, access-controlled locations ensures that an agent cannot become a channel for exposing unprotected or overshared data, or grounding on untrusted public content.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-3, AC-4
- _MITRE ATT&CK TTP Mapping:_
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
    - [T1213.002: Sharepoint](https://attack.mitre.org/techniques/T1213/002/)
  - [T1530: Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/)
- _Note:_ "Required protection" means the knowledge source carries a sensitivity label consistent with the agent's approved audience, and its permissions have been reviewed (Section 9). Public website knowledge sources should be restricted to approved domains.

#### MS.SI.13.3v1
Agents published on non-Microsoft channels SHALL be inventoried and approved.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi133v1-instructions)

<!--Policy: MS.SI.13.3v1; Criticality: SHALL -->
- _Rationale:_ Non-Microsoft channels such as custom websites, mobile apps, and third-party messaging or social platforms send agent conversations through services outside the agency's M365 compliance boundary. Inventory and approval make sure each such deployment has been assessed for data exposure and authentication.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ CA-3, CM-8, AC-20
- _MITRE ATT&CK TTP Mapping:_
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
  - [T1199: Trusted Relationship](https://attack.mitre.org/techniques/T1199/)
- _Note:_ Public publishing is prohibited by MS.SI.4.2v1. This policy covers authenticated, non-Microsoft channels that the agency has approved through its exception process.

#### MS.SI.13.4v1
DLP SHALL be scoped to cover agents where the knowledge source supports it.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi134v1-instructions)

<!--Policy: MS.SI.13.4v1; Criticality: SHALL -->
- _Rationale:_ Purview DLP policies scoped to Microsoft 365 Copilot can also govern agents whose knowledge sources and runtime support those controls. Extending DLP coverage to agents keeps the label and SIT protections that apply to Copilot from being bypassed by building a custom agent.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-4, SI-4
- _MITRE ATT&CK TTP Mapping:_
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
  - [T1213: Data from Information Repositories](https://attack.mitre.org/techniques/T1213/)
- _Note:_ Where an agent's knowledge source is not supported by Purview DLP, agencies should apply compensating controls (MS.SI.12.4v1) and restrict the knowledge source under MS.SI.13.2v1.
<!-- VERIFY: which agent types / knowledge sources honor the Copilot DLP location. -->

#### MS.SI.13.5v1
Power Platform data policies SHALL restrict connector combinations available to agent environments.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi135v1-instructions)

<!--Policy: MS.SI.13.5v1; Criticality: SHALL -->
- _Rationale:_ Copilot Studio agents can call connectors, HTTP requests, and flows. Without data policies, a single agent can read from a business system and write to a consumer or external service, creating an exfiltration path. Grouping connectors as Business, Non-business, or Blocked prevents agents from combining data across those groups.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ AC-4, CM-7, SC-7
- _MITRE ATT&CK TTP Mapping:_
  - [T1567: Exfiltration Over Web Service](https://attack.mitre.org/techniques/T1567/)
  - [T1048: Exfiltration Over Alternative Protocol](https://attack.mitre.org/techniques/T1048/)
- _Note:_ This policy builds on MS.POWERPLATFORM.2 in the [Power Platform baseline](powerplatform.md). It also covers the Copilot Studio-specific knowledge, channel, and authentication connectors used by MS.SI.4.1v1, MS.SI.4.2v1, and MS.SI.13.2v1.

#### MS.SI.13.6v1
The external threat detection error behavior for Copilot Studio custom agents SHOULD be set to Block the query.

[![Manual](https://img.shields.io/badge/Manual-046B9A)](#mssi136v1-instructions)

<!--Policy: MS.SI.13.6v1; Criticality: SHOULD -->
- _Rationale:_ External threat detection evaluates agent tool invocations at runtime and blocks those judged malicious, such as actions triggered by prompt injection. If the detection service fails or times out and the error behavior is set to allow, the action goes ahead without inspection. Setting it to **Block the query** makes the control fail closed.
- _Last modified:_ November 2026
- _NIST SP 800-53 Rev. 5 FedRAMP High Baseline Mapping:_ SI-3, SI-4, SI-10, SC-24
- _MITRE ATT&CK TTP Mapping:_
  - [T1190: Exploit Public-Facing Application](https://attack.mitre.org/techniques/T1190/)
- _Note:_ This threat is also described in MITRE ATLAS as [AML.T0051: LLM Prompt Injection](https://atlas.mitre.org/techniques/AML.T0051). This policy assumes external threat detection is configured. Agencies should monitor for blocked queries caused by detection-service errors to tell availability problems apart from actual threats.

### Resources

- [Configure data policies for agents \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-copilot-studio/admin-data-loss-prevention)
- [Knowledge sources in Copilot Studio \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-copilot-studio/knowledge-copilot-studio)
- [Publish agents to channels \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-copilot-studio/publication-fundamentals-publish-channels)
- [Enable external threat detection and protection for Copilot Studio custom agents \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-copilot-studio/external-security-provider)
- [Copilot Studio billing and pay-as-you-go \| Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-messages-management)
<!-- VERIFY: URLs for external threat detection and billing docs. -->

### License Requirements

- Copilot Studio requires Copilot Studio capacity (message packs) or Microsoft 365 Copilot licenses, depending on agent type.
- External threat detection requires a supported provider, for example Microsoft Defender (which may require Microsoft Defender for Cloud Apps) or a third-party provider.
<!-- VERIFY: Defender licensing for Copilot Studio runtime protection. -->

### Implementation

#### MS.SI.13.1v1 Instructions

1. Sign in to the **Microsoft 365 admin center**, select **Copilot** > **Billing & usage** (or **Settings** > **Pay-as-you-go**), and confirm that no pay-as-you-go billing policy is configured for agents or Copilot Chat agent usage.
2. Sign in to the **Power Platform admin center**, select **Licensing** (or **Billing**) > **Billing policies**, and confirm that no pay-as-you-go billing policy is linked to environments hosting Copilot Studio agents.
3. Remove any billing policies found that are not covered by a documented exception.
<!-- VERIFY: exact admin center paths for pay-as-you-go configuration. -->

#### MS.SI.13.2v1 Instructions

1. Sign in to the **Power Platform admin center**, select **Security** > **Data and privacy** > **Data policy**, and edit the policy that applies to agent environments.
2. Classify the Copilot Studio knowledge connectors according to agency policy. For example, move **Knowledge source with public websites and data in Copilot Studio** to **Blocked** (or limit it with endpoint filtering to approved domains), and allow **Knowledge source with SharePoint and OneDrive in Copilot Studio** only in the appropriate group.
3. For each agent, open **Copilot Studio** > **Knowledge**, and confirm that every knowledge source is labeled and approved under the site evaluation process (Section 9).
4. Document the approved knowledge sources for each agent alongside its registration (MS.SI.3.2v1).
<!-- VERIFY: knowledge source connector names in data policies. -->

#### MS.SI.13.3v1 Instructions

1. Using the **Power Platform admin center** inventory (or Copilot Studio agent list), identify agents published to non-Microsoft channels, such as Direct Line / custom website, mobile apps, Slack, or other third-party channels.
2. For each one, confirm there is an approval record covering the channel, the authentication method, the data exposed, and an accountable owner.
3. Block channel connectors for channels without approval through data policies (MS.SI.4.2v1), or unpublish the agent from those channels.
4. Review the inventory at least quarterly.

#### MS.SI.13.4v1 Instructions

1. Confirm that the DLP policies under MS.SI.10.2v1 and MS.SI.10.6v1 are scoped to the **Microsoft 365 Copilot and Copilot Chat** location, and that this location includes agents (for example, declarative and Copilot Studio agents built on Microsoft 365 Copilot).
2. For each agent, identify its knowledge sources and confirm whether Purview DLP enforcement applies to them (for example, SharePoint and OneDrive content with sensitivity labels).
3. For agents whose knowledge sources DLP does not support, document the gap and apply compensating controls (MS.SI.12.4v1).

#### MS.SI.13.5v1 Instructions

1. Sign in to the **Power Platform admin center** and select **Security** > **Data and privacy** > **Data policy**.
2. Create or edit a data policy that covers every environment where agents are built or run, including the default environment.
3. Classify connectors as **Business**, **Non-business**, or **Blocked** so that connectors with access to agency data cannot be combined with consumer, social, or unapproved external connectors. Block the **HTTP** connectors, or use endpoint filtering, unless they are specifically approved.
4. Include the Copilot Studio-specific connectors (authentication, knowledge source, channel, and skill connectors) in the classification.
5. Save the policy.

Alternatively, using the Power Apps administration PowerShell module, run `Get-DlpPolicy` (or `Get-AdminDlpPolicy`) to review existing policies and their connector groups.

#### MS.SI.13.6v1 Instructions

1. Sign in to the **Power Platform admin center** and select **Security** > **Threat detection** (or **Threat protection**).
2. Select **Additional threat detection and protection for Copilot Studio agents**.
3. Confirm that a provider is configured (for example, Microsoft Defender or an approved third-party provider), along with its Microsoft Entra app registration and endpoint.
4. Set **Error behavior** to **Block the query**.
5. Save the settings.
<!-- VERIFY: PPAC path, setting name, and error-behavior option labels. -->
