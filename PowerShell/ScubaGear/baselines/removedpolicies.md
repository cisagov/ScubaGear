**`TLP:CLEAR`**
# Removed CISA M365 Security Configuration Baseline Policies

This document tracks policies that have been removed from the security configuration baselines. The removal of a policy from the baselines does not necessarily imply that whatever configuration recommended by the removed policy should not be used. In each case, review the "Removal rationale" section of the removed policy in this document for more details.

The Secure Cloud Business Applications (SCuBA) project run by the Cybersecurity and Infrastructure Security Agency (CISA) provides guidance and capabilities to secure federal civilian executive branch (FCEB) agencies' cloud business application environments and protect federal information that is created, accessed, shared, and stored in those environments.

The CISA SCuBA SCBs for M365 help secure federal information assets stored within M365 cloud business application environments through consistent, effective, and manageable security configurations. CISA created baselines tailored to the federal government's threats and risk tolerance with the knowledge that every organization has different threat models and risk tolerance. Non-governmental organizations may also find value in applying these baselines to reduce risks.

The information in this document is provided "as is" for INFORMATIONAL PURPOSES ONLY. CISA does not endorse any commercial product or service, including any subjects of analysis. Any reference to specific commercial entities or commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise does not constitute or imply endorsement, recommendation, or favoritism by CISA. This document does not address, ensure compliance with, or supersede any law, regulation, or other authority. Entities are responsible for complying with any recordkeeping, privacy, and other laws that may apply to the use of technology. This document is not intended to, and does not, create any right or benefit for anyone against the United States, its departments, agencies, or entities, its officers, employees, or agents, or any other person.

> This document is marked TLP:CLEAR. Recipients may share this information without restriction. Information is subject to standard copyright rules. For more information on the Traffic Light Protocol, see https://www.cisa.gov/tlp.

## Key Terminology
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

Additional terminology in this document specific to their respective SCBs are to be interpreted as described in the following:

1. [AAD](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/aad.md#key-terminology)
2. [Defender](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/defender.md#key-terminology)
3. [Exo](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/exo.md#key-terminology)
4. [Power BI](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/powerbi.md#key-terminology)
5. [PowerPlatform](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/powerplatform.md#key-terminology)
6. [SharePoint](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/sharepoint.md#key-terminology)
7. [Teams](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/teams.md#key-terminology)

# Azure Active Directory / Entra ID

### Removed Policies 

N/A

# Defender

### Removed Policies 

N/A

# Exchange Online

### Removed Policies 
#### MS.EXO.2.1v1
A list of approved IP addresses for sending mail SHALL be maintained.
- _Removal date:_ May 2024
- _Removal rationale:_ MS.EXO.2.1v1 is not a security configuration that can be audited and acts as a step in implementation of policy MS.EXO.2.2. Having the list of approved IPs will be added as a part of implementation of policy MS.EXO.2.2 and removed as a policy in the baseline.

# Power BI

### Removed Policies 

N/A


# PowerPlatform

### Removed Policies 

N/A

# SharePoint Online

### Removed Policies 

N/A
