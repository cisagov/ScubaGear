# CISA M365 Security Configuration Baseline for Azure Active Directory

Azure Active Directory (AAD) is a cloud-based identity and access control service that provides security and functional capabilities to Microsoft 365. This security baseline provides policies to help secure AAD. 

## License Compliance and Copyright

Portions of this document are adapted from documents in Microsoft’s
[Microsoft 365](https://github.com/MicrosoftDocs/microsoft-365-docs/blob/public/LICENSE)
and
[Azure](https://github.com/MicrosoftDocs/azure-docs/blob/main/LICENSE)
GitHub repositories. The respective documents are subject to copyright
and are adapted under the terms of the Creative Commons Attribution 4.0
International license. Source documents are linked throughout this
document. The United States government has adapted selections of these
documents to develop innovative and scalable configuration standards to
strengthen the security of widely used cloud-based software services.

## Assumptions

The **License Requirements** sections of this document assume the
organization is using an [M365 E3](https://www.microsoft.com/en-us/microsoft-365/compare-microsoft-365-enterprise-plans)
or [G3](https://www.microsoft.com/en-us/microsoft-365/government)
license level. Therefore, only licenses not included in E3/G3 are
listed.

Some of the policies in this baseline may link to Microsoft instruction pages which assume that an agency has created emergency access accounts in AAD and [implemented strong security measures](https://learn.microsoft.com/en-us/azure/active-directory/roles/security-emergency-access) to protect the credentials of those accounts.

## Key Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

The following are key terms and descriptions used in this document.

**Hybrid Azure Active Directory (AD)** – This term denotes the scenario
when an organization has an on-premises AD domain that contains the
master user directory but federates access to the cloud Microsoft 365
(M365) Azure AD tenant.

**Resource Tenant & Home Tenant** – In scenarios where [guest users are involved](https://learn.microsoft.com/en-us/azure/active-directory/external-identities/authentication-conditional-access) the **resource tenant** hosts the M365 target resources that the guest user is accessing. The **home tenant** is the one that hosts the guest user's identity.

## Highly Privileged Roles

This section provides a list of what CISA considers highly privileged [built-in roles in Azure Active Directory](https://learn.microsoft.com/en-us/azure/active-directory/roles/permissions-reference). This list is referenced in numerous baseline policies throughout this document. Agencies should consider this reference as a minimum list and can apply the respective baseline policies to additional AAD roles as necessary.

- Global Administrator, Privileged Role Administrator, User Administrator, SharePoint Administrator, Exchange Administrator, Hybrid Identity Administrator, Application Administrator, Cloud Application Administrator.

## Conditional Access Policies

Numerous policies in this baseline rely on AAD Conditional Access. This section provides guidance and tools when implementing baseline policies which rely on AAD Conditional Access.

As described in Microsoft’s literature related to conditional access policies, CISA recommends initially setting a policy to
**Report-only** when it is created and then performing thorough hands-on
testing to ensure that there are no unintended consequences before
toggling the policy from **Report-only** to **On**. The policy will only be enforced when it is set to **On**. One tool that can assist with running test simulations is the [What If tool](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/what-if-tool). Microsoft also describes [Conditional Access insights and reporting features](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-insights-reporting) that can assist with testing.

# Baseline Policies

## 1. Legacy Authentication

This section provides policies that help reduce security risks related to legacy authentication protocols that do not support MFA.

### Policies
#### MS.AAD.1.1v1
Legacy authentication SHALL be blocked.

- _Rationale:_ The security risk of allowing legacy authentication protocols is that they do not support MFA. By blocking legacy protocols the impact of user credential theft is minimized.
- _Last modified:_ June 2023

### Resources

- [Conditional Access: Block Legacy Authentication](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-policy-block-legacy)

- [Five steps to securing your identity infrastructure](https://learn.microsoft.com/en-us/azure/security/fundamentals/steps-secure-identity)

### License Requirements

- N/A

### Implementation

#### MS.AAD.1.1v1 instructions:

1.  Before blocking legacy authentication across the entire application
base, follow [these instructions](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/block-legacy-authentication#identify-legacy-authentication-use) to determine if any of the agency’s existing applications are presently using legacy authentication.

2.  Follow [the instructions on this page](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-policy-block-legacy) to create a conditional access policy that blocks legacy authentication.

## 2. Risk Based Policies

This section provides policies that help reduce security risks related to user accounts that may have been compromised. These policies use a combination of AAD Identity Protection and AAD Conditional Access. AAD Identity Protection uses numerous signals to detect the risk level for each user or sign-in to determine if an account may have been compromised. 

- _Additional mitigations to secure Workload Identities:_ Although not covered in this baseline due to the need for an additional non-standard license, Microsoft also provides support for mitigating risks related to workload identities (AAD applications or service principals). Agencies should strongly consider implementing this feature because workload identities present many of the same risks as interactive user access and are commonly used in modern systems. Follow [these instructions](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/workload-identity) to apply conditional access policies to workload identities.

- _Note:_ The term "high risk" in the context of this section denotes the risk level applied by the AAD Identity Protection service to a user account or sign-in event. See the Resources section for a link to a detailed description of AAD Identity Protection risk and the factors that comprise it.

### Policies
#### MS.AAD.2.1v1
Users detected as high risk SHALL be blocked.

- _Rationale:_ By blocking users determined as high risk, this prevents accounts that are likely compromised from accessing the tenant.
- _Last modified:_ June 2023
- _Note:_ Users who are determined to be high risk by AAD Identity Protection can be blocked from accessing the system via an AAD Conditional Access policy. A high risk user will be blocked until an administrator remediates their account.

#### MS.AAD.2.2v1
A notification SHOULD be sent to the administrator when high-risk users are detected.
- _Rationale:_ By alerting an administrator when high risk detections are made, the admin can respond to monitor the event and remediate the risk. This helps the organization proactively respond to cyber intrusions in action.
- _Last modified:_ June 2023

#### MS.AAD.2.3v1
Sign-ins detected as high risk SHALL be blocked.
- _Rationale:_ By blocking sign-ins determined as high risk, this prevents accounts that are likely compromised from accessing the tenant.
- _Last modified:_ June 2023

### Resources

- [What are risk detections?](https://learn.microsoft.com/en-us/azure/active-directory/identity-protection/concept-identity-protection-risks)

- [Simulating risk detections in Identity Protection](https://learn.microsoft.com/en-us/azure/active-directory/identity-protection/howto-identity-protection-simulate-risk)

- [User experiences with Azure AD Identity Protection](https://learn.microsoft.com/en-us/azure/active-directory/identity-protection/concept-identity-protection-user-experience)
  (Examples of how these policies are applied in practice)

### License Requirements

- Requires an AAD P2 license

### Implementation

####  MS.AAD.2.1v1 instructions:

1.  Create a conditional access policy that blocks users determined to be high risk by the Identity Protection service.

Follow the conditional access policy template below:

    Users > Include > All users

    Target resources > Cloud apps > All cloud apps

    Conditions > User risk > High
    
    Access controls > Grant > Block Access

#### MS.AAD.2.2v1 instructions:

1.  Follow the instructions in the [Configure users at risk detected alerts](https://learn.microsoft.com/en-us/azure/active-directory/identity-protection/howto-identity-protection-configure-notifications#configure-users-at-risk-detected-alerts) section to configure Azure AD Identity Protection to email a regularly monitored security mailbox when a user account is determined to be high risk.

#### MS.AAD.2.3v1 instructions:

1. Create a conditional access policy that blocks sign-ins determined to be high risk by the Identity Protection service.

Follow the conditional access policy template below:

    Users > Include > All users

    Target resources > Cloud apps > All cloud apps

    Conditions > Sign-in risk > High
    
    Access controls > Grant > Block Access

## 3. Strong Authentication and a Secure Registration Process

This section provides policies that help reduce security risks related to  user authentication and registration.

- _Phishing-resistant MFA:_ Per [OMB memorandum M-22-09](https://www.whitehouse.gov/wp-content/uploads/2022/01/M-22-09.pdf), MFA is required and it must be phishing-resistant. Since there may be gaps in the implementation of enforcing phishing-resistant MFA for all users for various reasons, we also provide some additional backup security policies to help mitigate the risks associated with lesser forms of MFA. One example of this is the second policy below which enforces MFA but does not stipulate the specific MFA method. That said, phishing-resistant MFA is the overarching requirement.

<img src="/images/aad-mfa.png"
alt="Weak MFA (SMS/Voice) Stronger MFA (Push Notifications, Software OTP, Hardware Token OTP) Strongest MFA (FIDO2, PIV, Windows Hello)" />

Figure 1: Depiction of MFA methods from weakest to strongest. _Adapted from [MS Build Page](https://learn.microsoft.com/en-us/azure/active-directory/authentication/concept-authentication-methods)_

### Policies
#### MS.AAD.3.1v1
Phishing-resistant MFA SHALL be enforced for all users.

**Preferred phishing-resistant methods**

The methods **AAD Certificate-Based Authentication (CBA)**, **FIDO2 Security Key** and **Windows Hello for Business** are the recommended options since they offer forms of MFA with the least potential weaknesses. AAD CBA supports Federal PIV cards when they authenticate directly to Azure AD and is likely the most appropriate option for agencies to authenticate their users.

**Non-preferred phishing-resistant methods**

The option **Federal PIV card (federated from agency on-premises Active Directory Federation Services or other identity provider)**, although technically phishing-resistant presents significant risks if the on-premises authentication infrastructure (e.g. ADFS) is compromised. Therefore federated PIV is not a preferred option and agencies should migrate to the options listed in the preferred section above. If an agency does use an on-premises PIV authentication and federate to AAD, reference the [guidance at this link](https://playbooks.idmanagement.gov/piv/network/group/) to enforce PIV logon via AD group policy.

- _Rationale:_ The security risk of allowing weaker forms of MFA is that they do not protect against sophisticated phishing attacks. By enforcing methods which are resistant to phishing those risks are minimized.
- _Last modified:_ June 2023

#### MS.AAD.3.2v1
If Phishing-resistant MFA has not been enforced yet, then an alternative MFA method SHALL be enforced for all users.

- _Rationale:_ This is a backup security policy to help protect the tenant in the event that phishing-resistant MFA has not been enforced yet. This policy requires that MFA is enforced and thus reduces the risks of single form authentication.
- _Last modified:_ June 2023
- _Note:_ If a conditional access policy has been created that enforces phishing-resistant MFA, then this policy is not necessary. This policy does not dictate the specific MFA method.

#### MS.AAD.3.3v1
If Phishing-resistant MFA has not been enforced yet and Microsoft Authenticator is enabled, it SHALL be configured to show login context information.

- _Rationale:_ This is a backup security policy to help protect the tenant in the event that phishing-resistant MFA has not been enforced yet and Microsoft Authenticator is being used. This policy helps improve the security of Microsoft Authenticator by showing the user context information which helps reduce MFA phishing compromises.
- _Last modified:_ June 2023

#### MS.AAD.3.4v1
The Authentication Methods Manage Migration feature SHALL be set to Migration Complete.

- _Rationale:_ By configuring the Manage Migration feature to Migration Complete, we ensure that the tenant has disabled the legacy authentication methods screen. The MFA and SSPR authentication methods are both managed from a central admin page thereby reducing administrative complexity and
reducing the chances of security misconfigurations.
- _Last modified:_ June 2023

#### MS.AAD.3.5v1
The authentication methods SMS, Voice Call and Email OTP SHALL be disabled.

- _Rationale:_ This policy helps reduce the possibility for users to  register and authenticate with the weakest authenticators. Thus users are forced to use stronger MFA methods.
- _Last modified:_ June 2023
- _Note:_ This policy is only applicable if the tenant has their Manage Migration feature set to Migration Complete because that is required to manage the respective configuration options from the combined MFA / SSPR authentication methods page.

#### MS.AAD.3.6v1
Phishing-resistant MFA SHALL be required for Highly Privileged Roles.

- _Rationale:_ This is a backup security policy to help protect privileged access to the tenant in the event that the conditional access policy which requires MFA for all users is disabled or misconfigured.
- _Last modified:_ June 2023
- _Note:_ Refer to the Highly Privileged Roles section at the top of this document for a reference list of roles considered highly privileged.

#### MS.AAD.3.7v1
Managed devices SHOULD be required for authentication.

- _Rationale:_ The security risk of an adversary authenticating to the tenant from their own device is reduced by requiring a managed device to authenticate. Managed devices are under the provisioning and control of the agency. OMB-22-09 specifically states "When authorizing users to access resources, agencies must consider at least one device-level signal alongside identity information about the authenticated user".
- _Last modified:_ June 2023

#### MS.AAD.3.8v1
Managed Devices SHOULD be required to register MFA.

- _Rationale:_ The security risk of an adversary using stolen user credentials and then registering their own MFA devices to access the tenant is reduced by requiring a managed device to perform registration actions. Thus the adversary cannot perform the registration from their own unmanaged device. Managed devices are under the provisioning and control of the agency.
- _Last modified:_ June 2023

### Resources

- [What authentication and verification methods are available in Azure Active Directory?](https://learn.microsoft.com/en-us/azure/active-directory/authentication/concept-authentication-methods)

- [How to use additional context in Microsoft Authenticator notifications Authentication methods policy](https://learn.microsoft.com/en-us/azure/active-directory/authentication/how-to-mfa-additional-context#enable-additional-context-in-the-portal)

- [M-22-09 Federal Zero Trust Strategy](https://www.whitehouse.gov/wp-content/uploads/2022/01/M-22-09.pdf)

- [Configure hybrid Azure AD join](https://learn.microsoft.com/en-us/azure/active-directory/devices/howto-hybrid-azure-ad-join)

- [Azure AD joined devices](https://learn.microsoft.com/en-us/azure/active-directory/devices/concept-azure-ad-join)

- [Set up enrollment for Windows devices (for Intune)](https://learn.microsoft.com/en-us/mem/intune/enrollment/windows-enroll)

### License Requirements

- Microsoft Intune (if implementing the authentication policies for the device to be managed).

### Implementation

#### MS.AAD.3.1v1 instructions:

1. Create a conditional access policy that enforces phishing-resistant MFA for all users. 

Follow the conditional access policy template below:

    Users > Include > All users

    Target resources > Cloud apps > All cloud apps
    
    Access controls > Grant > Grant Access > Require authentication strength > Phishing-resistant MFA

#### MS.AAD.3.2v1 instructions:

1. If hishing-resistant MFA has not been enforced for all users yet, create a conditional access policy that enforces MFA but does not dictate the MFA method. 

Follow the conditional access policy template below.

    Users > Include > All users

    Target resources > Cloud apps > All cloud apps
    
    Access controls > Grant > Grant Access > Require multifactor authentication

#### MS.AAD.3.3v1 instructions:
If phishing-resistant MFA has not been deployed yet and Microsoft Authenticator is in use, configure Authenticator to display context information to users when they login.

1. In **Azure Active Directory**, click **Security > Authentication methods > Microsoft Authenticator**.
2. Click the **Configure** tab.
3. For **Allow use of Microsoft Authenticator OTP** select *No*.
4. Under **Show application name in push and passwordless notifications** select **Status > Enabled** and **Target > Include > All users**.
5. Under **Show geographic location in push and passwordless notifications** select **Status > Enabled** and **Target > Include > All users**.
6. Select **Save**


#### MS.AAD.3.4v1 instructions:
1. Go through the process of migrating from the legacy AAD MFA and Self-Service Password Reset (SSPR) administration pages to the new unified Authentication Methods policy page. Follow [these instructions ](https://learn.microsoft.com/en-us/azure/active-directory/authentication/how-to-authentication-methods-manage).
2. Once ready to finish the migration, follow [these instructions ](https://learn.microsoft.com/en-us/azure/active-directory/authentication/how-to-authentication-methods-manage#finish-the-migration) and set the **Manage Migration** option to **Migration Complete**.

#### MS.AAD.3.5v1 instructions:
1. In **Azure Active Directory**, click **Security > Authentication methods**
2. Click on the **SMS**, **Voice Call**, and **Email OTP** authentication methods and disable each of them. Their statuses should be **Enabled > No** on the **Authentication methods > Policies** page.

#### MS.AAD.3.6v1 instructions:

1. Create a conditional access policy that enforces phishing-resistant MFA for highly privileged roles. 

Follow the conditional access policy template below:

    Users > Include > Select users and groups > Directory roles > select each of the roles listed in the Highly Privileged Roles section at the top of this document

    Target resources > Cloud apps > All cloud apps
    
    Access controls > Grant > Grant Access > Require authentication strength > Phishing-resistant MFA

#### MS.AAD.3.7v1 instructions:

1. Create a conditional access policy that requires a user's device to be
either hybrid Azure AD joined or compliant during authentication. 

Follow the conditional access policy template below.

    Users > Include > All users

    Target resources > Cloud apps > All cloud apps
    
    Access controls > Grant > Grant Access > "Require device to be marked as compliant" and "Require Hybrid Azure AD joined device" > Require one of the selected controls

#### MS.AAD.3.8v1 instructions:

1. Create a conditional access policy that requires a user to be on a managed device when registering for MFA. 

Follow the conditional access policy template below.

    Users > Include > All users

    Target resources > User actions > Register security information
    
    Access controls > Grant > Grant Access > "Require device to be marked as compliant" and "Require Hybrid Azure AD joined device" > Require one of the selected controls

## 4. Centralized Log Collection

This section provides policies that help reduce security risks related to  the lack of security logs which hampers security visibility.

### Policies
#### MS.AAD.4.1v1
Security logs SHALL be sent to the agency's Security Operations Center for monitoring.

- _Rationale:_ The security risk of not having visibility into cyber attacks is reduced by collecting the logs into the agency's centralized security detection infrastructure. Thus security events can be audited,  queried and available for incident response. 
- _Last modified:_ June 2023
- _Scope:_ The following logs (configured in Azure AD diagnostic settings), are required: AuditLogs, SignInLogs, RiskyUsers, UserRiskEvents, NonInteractiveUserSignInLogs, ServicePrincipalSignInLogs, ADFSSignInLogs, RiskyServicePrincipals, ServicePrincipalRiskEvents, EnrichedOffice365AuditLogs, MicrosoftGraphActivityLogs. If managed identities are used for Azure resources, also send the ManagedIdentitySignInLogs log type. If the Azure AD Provisioning Service is used to provision users to SaaS apps or other systems, also send the ProvisioningLogs log type.
- _Federal Agencies:_ It is also recommended to send the logs to the CISA CLAW system so that agencies can benefit from the security detection capabilities offered there. Contact CISA to request integration instructions.

### Resources

- [Everything you wanted to know about Security and Audit Logging in
  Office 365](https://thecloudtechnologist.com/2021/10/15/everything-you-wanted-to-know-about-security-and-audit-logging-in-office-365/)

- [Sign-in logs in Azure Active Directory -
  preview](https://learn.microsoft.com/en-us/azure/active-directory/reports-monitoring/concept-all-sign-ins)

- [National Cybersecurity Protection System-Cloud Interface Reference
  Architecture Volume
  1](https://www.cisa.gov/sites/default/files/publications/NCPS%20Cloud%20Interface%20RA%20Volume%20One%20%282021-05-14%29.pdf)

### License Requirements

- An Azure subscription is required to send the logs to an external system such as the agency's SIEM.

### Implementation

#### MS.AAD.4.1v1 instructions:

[Follow these instructions](https://learn.microsoft.com/en-us/azure/active-directory/reports-monitoring/quickstart-azure-monitor-route-logs-to-storage-account)
to configure sending the logs to a storage account:

1.  From the **Diagnostic settings** page, click **Add diagnostic**
    setting.

2.  Select the specific logs mentioned in the previous policy section.

3.  Under **Destination Details,** select the **Archive to a storage
    account** check box and select the storage account that was
    specifically created to host security logs.

4.  In the **Retention** field enter “365” days.

## 5. Application Registration and Consent

This section provides policies that help reduce security risks related to  non privileged users adding malicious applications or service principals to the tenant. Malicious applications can perform many of the same operations as interactive users and can access data "on behalf of" compromised users. These policies apply to custom-developed applications and applications published by third-party vendors.

### Policies
#### MS.AAD.5.1v1
Only administrators SHALL be allowed to register applications.

- _Rationale:_ Application access to the tenant presents a heightened security risk compared to interactive user access because applications are typically not subject to critical security protections such as MFA policies and others. Ensuring that only specific privileged users can register applications reduces the risks of unauthorized users installing malicious applications into the tenant.
- _Last modified:_ June 2023

#### MS.AAD.5.2v1
Only administrators SHALL be allowed to consent to applications.

- _Rationale:_ Ensuring that only specific privileged users can consent to applications reduces the risks of users giving insecure applications access to their data via [consent grant attacks](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/detect-and-remediate-illicit-consent-grants?view=o365-worldwide).
- _Last modified:_ June 2023

#### MS.AAD.5.3v1
An admin consent workflow SHALL be configured for applications.

- _Rationale:_ Configuring an admin consent workflow helps support the risk reduction of the previous policy by setting up a process for users to securely request access to applications necessary for business purposes. Administrators get the opportunity to review the permissions requested by new applications and approve or deny access based on a risk assessment.
- _Last modified:_ June 2023

#### MS.AAD.5.4v1
Group owners SHALL NOT be allowed to consent to applications.

- _Rationale:_ In M365 group and team owners can consent to applications accessing data in the tenant, thus by preventing this and requiring consent requests to go through an approval consent workflow, the risks of exposure to malicious applications is reduced.
- _Last modified:_ June 2023

### Resources

- [Restrict Application Registration for Non-Privileged
  Users](https://www.trendmicro.com/cloudoneconformity/knowledge-base/azure/ActiveDirectory/users-can-register-applications.html)

- [Enforce Administrators to Provide Consent for Apps Before
  Use](https://www.trendmicro.com/cloudoneconformity/knowledge-base/azure/ActiveDirectory/users-can-consent-to-apps-accessing-company-data-on-their-behalf.html)

- [Configure the admin consent
  workflow](https://learn.microsoft.com/en-us/azure/active-directory/manage-apps/configure-admin-consent-workflow)

### License Requirements

- N/A

### Implementation

#### MS.AAD.5.1v1 instructions:

1.  In **Azure Active Directory**, under **Manage**, select **Users**.

2. Select **User settings**.

3. For **Users can register applications**, select **No.**

4. Click **Save**.

#### MS.AAD.5.2v1 instructions:

1.  In **Azure Active Directory** under **Manage**, select **Enterprise Applications.**

2. Under **Security**, select **Consent and permissions.**

3. Under **User consent for applications**, select **Do not allow user consent.**

4. Click **Save**.

#### MS.AAD.5.3v1 instructions:

1.  In **Azure Active Directory** create a new Azure AD Group that contains admin users responsible for reviewing and adjudicating application consent requests. Users in this group will be notified when users request consent for new applications.

2. Then in **Azure Active Directory** under **Manage**, select **Enterprise Applications.**

3. Select **Admin consent settings**.

4. Under **Admin consent requests** > **Users can request admin consent to apps they are unable to consent to**, select **Yes**.

5. Under **Who can review admin consent requests**, select the group created in step 1 that is responsible for reviewing and adjudicating app requests.

6. Click **Save**.

#### MS.AAD.5.4v1 instructions:

1.  In **Azure Active Directory** under **Manage**, select **Enterprise Applications.**

2. Under **Security**, select **Consent and permissions.**

3. Under **Group owner consent for apps accessing data**, select **Do not allow group owner consent.**

4. Click **Save**.

## 6. Passwords

This section provides policies that help reduce security risks associated with legacy password practices that are no longer supported by research. 

### Policies
#### MS.AAD.6.1v1
User passwords SHALL NOT expire.

- _Rationale:_ At a minimum, NIST, OMB and Microsoft have published guidance indicating that mandated periodic password changes make user accounts less secure. OMB-22-09 specifically states "Password policies must not require use of special characters or regular rotation".

- _Last modified:_ June 2023

### Resources

- [Password policy recommendations - Microsoft 365 admin \| Microsoft
  Docs](https://learn.microsoft.com/en-us/microsoft-365/admin/misc/password-policy-recommendations?view=o365-worldwide#password-expiration-requirements-for-users)

- [Eliminate bad passwords using Azure Active Directory Password
  Protection](https://learn.microsoft.com/en-us/azure/active-directory/authentication/concept-password-ban-bad)

- [NIST Special Publication 800-63B - Digital Identity
  Guidelines](https://pages.nist.gov/800-63-3/sp800-63b.html)

### License Requirements

- N/A

### Implementation

#### MS.AAD.6.1v1 instructions:

1. [Follow the instructions at this link](https://learn.microsoft.com/en-us/microsoft-365/admin/manage/set-password-expiration-policy?view=o365-worldwide#set-password-expiration-policy) and configure the **Password expiration policy** to **Set passwords to never expire**.

## 7. Highly Privileged User Access

This section provides policies that help reduce security risks related to the usage of highly privileged AAD built-in roles. Privileged administrative users have access to operations that can undermine the security of the tenant by changing configurations and security policies, thus special protections are necessary to secure this level of access.

- _Note:_ Refer to the Highly Privileged Roles section at the top of this document for a reference list of roles considered highly privileged.

- _Implementation Alternatives:_ Some of the policy implementations in this section reference specific features of the AAD Privileged Identity Management (PIM) service which provides “Privileged Access Management (PAM)” capabilities. As an alternative to AAD PIM, there are third-party products and services with equivalent PAM capabilities that can be leveraged if an agency chooses to do so.

### Policies
#### MS.AAD.7.1v1
A minimum of two users and a maximum of eight users SHALL be provisioned with the Global Administrator role.
- _Rationale:_  The Global Administrator role provides unfettered access to the tenant. Therefore, reducing the number of users with this access makes it more challenging for an adversary to compromise a tenant. Microsoft recommends fewer than five users and CISA decided on fewer than eight based on the data from federal agency pilots.
- _Last modified:_ June 2023

#### MS.AAD.7.2v1
Privileged users SHALL be provisioned with finer-grained roles instead Global Administrator.
- _Rationale:_ Many privileged administrative users do not need unfettered access to the tenant to perform their duties. By assigning them to roles based on least privilege, the risks associated with having their accounts compromised are reduced.
- _Last modified:_ June 2023

#### MS.AAD.7.3v1
Privileged users SHALL be provisioned cloud-only accounts that are separate from an on-premises directory or other federated identity providers.
- _Rationale:_ By provisioning cloud-only AAD user accounts to privileged users, the risks associated with a compromise of on-premises federation infrastructure are reduced. It is more challenging for the adversary to pivot from the compromised environment to the cloud with privileged access.
- _Last modified:_ June 2023

#### MS.AAD.7.4v1
Permanent active role assignments SHALL NOT be allowed for highly privileged roles except for emergency and service accounts.

- _Rationale:_ Instead of giving users permanent assignments to privileged roles, provisioning access "just in time" lessens the exposure period if those accounts become compromised. In AAD PIM or an alternative PAM system, just in time access can be provisioned by assigning users to roles as "eligible" instead of perpetually "active".
- _Last modified:_ June 2023
- _Note:_ There are a couple of exceptions to this policy. Emergency access accounts need perpetual access to the tenant in the rare event of system degradation or other scenarios. Some types of service accounts require a user account with privileged roles and since those are software they cannot perform role activation.

#### MS.AAD.7.5v1
Provisioning users to highly privileged roles SHALL NOT occur outside of a PAM system.
- _Rationale:_ By provisioning users to privileged roles within a PAM system, numerous privileged access policies and monitoring can be enforced. If privileged users are assigned directly to roles in the M365 admin center or via Powershell outside of the context of a PAM system, a significant set of critical security capabilities are bypassed.
- _Last modified:_ June 2023

#### MS.AAD.7.6v1
Activation of the Global Administrator role SHALL require approval.

- _Rationale:_ Requiring approval for a user to activate Global Administrator which provided unfettered access, makes it more challenging for an attacker to compromise the tenant with stolen credentials and it provides visibility of activities that may indicate a compromise is taking place.
- _Last modified:_ June 2023

#### MS.AAD.7.7v1
Eligible and Active highly privileged role assignments SHALL trigger an alert.

- _Rationale:_ It is imperative to closely monitor the assignment of the highest privileged roles for signs of compromise. Sending alerts when these assignments occur provides the security monitoring team a chance to detect potential compromises in action.
- _Last modified:_ June 2023

#### MS.AAD.7.8v1
User activation of the Global Administrator role SHALL trigger an alert.

- _Rationale:_ The rationale for this policy is identical to the previous one, except that this policy applies to user activations. "Activation" occurs when a user that is assigned as eligible, "turns on" their access for a specific period of time. Monitoring this action closely for Global Administrator helps to detect events with significant security implications in action.
- _Last modified:_ June 2023
- _Note:_ It is recommended to prioritize user activation of Global Administrator as one of the most important events to monitor and respond to.

#### MS.AAD.7.9v1
User activation of other highly privileged roles SHOULD trigger an alert.

- _Rationale:_ The rationale for this policy is identical to the previous one, except that this policy applies to user activations of privileged roles that are not Global Administrator (i.e. the other privileged roles). CISA separated this policy from the previous one and designated it as a "SHOULD" item because in some environments activation of privileged roles can generate a significant number of alerts.
- _Last modified:_ June 2023

### Resources

- [Best practices for Azure AD roles (Limit number of Global Administrators to less than 5)](https://learn.microsoft.com/en-us/azure/active-directory/roles/best-practices#5-limit-the-number-of-global-administrators-to-less-than-5)

- [Implement Privilege Access Management](https://learn.microsoft.com/en-us/azure/security/fundamentals/steps-secure-identity#implement-privilege-access-management)

- [Assign Azure AD roles in Privileged Identity Management](https://learn.microsoft.com/en-us/azure/active-directory/privileged-identity-management/pim-how-to-add-role-to-user)

- [Approve or deny requests for Azure AD roles in Privileged Identity Management](https://learn.microsoft.com/en-us/azure/active-directory/privileged-identity-management/azure-ad-pim-approval-workflow)

- [Configure security alerts for Azure AD roles in Privileged Identity Management](https://learn.microsoft.com/en-us/azure/active-directory/privileged-identity-management/pim-how-to-configure-security-alerts)

### License Requirements

- Azure AD PIM or an equivalent third-party PAM service.

- Azure AD PIM requires an AAD P2 license

### Implementation

- _Note:_ Steps in the following implementation instructions that reference the AAD PIM service will vary if using a third-party PAM system instead.

- _Future revisions:_ Some of the implementation instructions associated with this group of policies may be revised in the next release to incorporate functionality provided by the the AAD PIM for Groups feature.

#### MS.AAD.7.1v1 instructions:

1. In **Azure Active Directory** select **Roles and administrators.**

2. Select the **Global administrator role.**

3. Under **Manage**, select **Assignments.**

4. Validate that between two to eight users are listed.

5.  If you have AAD PIM, count the number of users in both the **Eligible assignments** and **Active assignments** tabs. There should be a total of two to eight users across both of these tabs (not individually). Do not count the same username twice. If any groups are listed, count the number of users that are members of the group and include it in the total count.

#### MS.AAD.7.2v1 instructions:

1.  In **Azure Active Directory** select **Security.**

2.  Under **Manage**, select **Identity Secure Score.**

3.  Click the **Columns** button and select all the available columns and click **Apply.**

4.  Review the score for the action named **Use least privileged administrative roles.**

5.  Review the **current score** value and compare it to the **max score**. 
If the current score is not the maximum value and the status is not **Completed**, you must perform the improvement actions. If that is the case, follow the detailed action steps and then check the score again after 48 hours to ensure compliance.

#### MS.AAD.7.3v1 instructions:
Note: Performing a manual review of highly privileged users to determine which ones are not cloud-only is labor intensive so we recommend running the ScubaGear tool instead. ScubaGear will provide a list of the highly privileged users that are not cloud-only.

1. Perform the steps below for each highly privileged role. We reference the Global Administrator role as an example.

2. In **Azure Active Directory** select **Roles and administrators.**

3. Select the **Global administrator role.**

4. Under **Manage**, select **Assignments.** If you have AAD PIM, repeat the steps below for both the **Eligible** and the **Active** assignments. If a group is listed, you will need to determine the members of the group and perform the steps for each group member.

5. For each highly privileged user, execute the Powershell code below but replace the **username@somedomain.com** sample data value with the principal name of the user that is specific to your environment. You can get the data value from the **Principal name** field displayed in the Azure Active Directory portal.

```
Connect-MgGraph
Select-Mgprofile beta
Get-MgUser -Filter "userPrincipalName eq 'username@somedomain.com'" | FL
```

6. Review the output field named **OnPremisesImmutableId**. If this field has a data value, it means that this specific user is not cloud-only. If the user is not cloud-only, create a cloud-only account for that user, assign the user to their respective roles and then remove the account that is not cloud-only from AAD.

#### MS.AAD.7.4v1 instructions:

1. In **Azure Active Directory** select **Roles and administrators**. Perform the steps below for each highly privileged role. We reference the Global Administrator role as an example.

2. Select the **Global administrator role.**

3. Under **Manage**, select **Assignments** and click the **Active assignments** tab.

4. Verify that there are no users or groups with a value of **Permanent** in the **End time** column. If there are any, recreate those assignments to have an expiration date using AAD PIM or an alternative PAM system. The only exception to this policy are emergency access accounts and service accounts that require perpetual active assignments. See policy for details.

#### MS.AAD.7.5v1 instructions:
 
1. Perform the steps below for each highly privileged role. We reference the Global Administrator role as an example.

2. In **Azure Active Directory** select **Roles and administrators.**

3. Select the **Global administrator role.**

4. Under **Manage**, select **Assignments.** Repeat the steps below for both the **Eligible** and the **Active** AAD PIM assignments. 

5. For each user or group listed, examine the value in the **Start time** column. If it contains a value of **-**, this indicates that the respective user / group was assigned to that role outside of AAD PIM. If the role was assigned outside of AAD PIM, delete the assignment and recreate it using AAD PIM.


#### MS.AAD.7.6v1 instructions:

1. In **Azure Active Directory** create a new group named **Privileged Escalation Approvers**. This group will contain users that will receive role activation approval requests and approve or deny them. 

2. Assign this new group to the AAD role **Privileged Role Administrators**. This permission is required so that users in this group can adjudicate role activation approval requests.

3. Assign the users responsible for reviewing approval requests to the new **Privileged Escalation Approvers** group via the [PIM for Groups feature](https://learn.microsoft.com/en-us/azure/active-directory/privileged-identity-management/concept-pim-for-groups).

4. In **AAD Privileged Identity Management (PIM)**, under **Manage**, select **Azure AD roles**.

5. Under **Manage**, select **Roles**.

  1.  Select the **Global Administrator** role in the list.
  2.  Click **Settings**.
  3.  Click **Edit**.
  4.  Select the **Require approval to activate** option.
  5.  Click **Select approvers** and select the group **Privileged Escalation Approvers**, and then click **Select**.
  6.  Click **Update**.

#### MS.AAD.7.7v1 instructions:

1.  In **AAD Privileged Identity Management (PIM)**, under **Manage**, select **Azure AD roles.**

2. Under **Manage**, select **Roles**. Perform the steps below for each highly privileged role. We reference the Global Administrator role as an example.

3. Click the **Global Administrator** role.

4. Click **Settings** and then click **Edit.**

5. Click the **Notification** tab.

6. Under **Send notifications when members are assigned as eligible to this role**, in the **Role assignment alert > Additional recipients** textbox, enter the email address of the security monitoring mailbox configured to receive privileged role assignment alerts.

7. Under **Send notifications when members are assigned as active to this role**, in the **Role assignment alert > Additional recipients** textbox, enter the email address of the security monitoring mailbox configured to receive privileged role assignment alerts.

8. Click **Update**.

#### MS.AAD.7.8v1 instructions:

1. In **AAD Privileged Identity Management (PIM)**, under **Manage**, select **Azure AD roles.**

2. Under **Manage**, select **Roles**.

3. Click the **Global Administrator** role.

4. Click **Settings** and then click **Edit.**

5. Click the **Notification** tab.

6. Under **Send notifications when eligible members activate this role**, in the **Role activation alert > Additional recipients** textbox, enter the email address of the security monitoring mailbox configured to receive Global Administrator activation alerts.

7. Click **Update**.

#### MS.AAD.7.9v1 instructions:
 
 1. Follow the same instructions as MS.AAD.7.8v1 for each of the highly privileged roles (other than Global Administrator) but enter a security monitoring mailbox that is different from the one used to monitor Global Administrator activations.

## 8. Guest User Access

This section provides policies that help reduce security risks related to the integration of M365 guest users. A guest user is a specific type of external user that belongs to a separate organization but can access files, meetings, teams and other data in the target tenant. It is common to invite guest users to a tenant for cross-agency collaboration purposes.

#### MS.AAD.8.1v1
Guest users SHOULD have limited or restricted access to Azure AD directory objects.

- _Rationale:_ By limiting the amount of information about objects in the tenant that is available to guest users, this reduces the malicious reconnaissance exposure if a guest account is compromised or created by an adversary.
- _Last modified:_ June 2023

#### MS.AAD.8.2v1
Only users with the Guest Inviter role SHOULD be able to invite guest users.

- _Rationale:_ By only allowing an authorized groups of individuals to invite guest users to create accounts in the tenant, this helps an agency enforce a guest user account approval process which reduces the risk of unauthorized accounts being created.
- _Last modified:_ June 2023

#### MS.AAD.8.3v1
Guest invites SHOULD only be allowed to specific external domains that have been authorized by the agency for legitimate business purposes.

- _Rationale:_ Limiting which domains can be invited to create guest accounts in the tenant helps reduce the risk of users from unauthorized external organizations getting access.
- _Last modified:_ June 2023

### Resources

- [Configure external collaboration settings](https://learn.microsoft.com/en-us/azure/active-directory/external-identities/external-collaboration-settings-configure)

- [Compare member and guest default permissions](https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/users-default-permissions#compare-member-and-guest-default-permissions)

### License Requirements

- N/A

### Implementation

#### MS.AAD.8.1v1 instructions:

1. In **Azure Active Directory** select **External Identities > External collaboration settings**.

2. Under **Guest user access**, select either **Guest users have limited access to properties and memberships of directory objects** or **Guest user access is restricted to properties and memberships of their own directory objects (most restrictive)**.

3. Click **Save**.

#### MS.AAD.8.2v1 instructions:

1. In **Azure Active Directory** select **External Identities > External collaboration settings**.

2.  Under **Guest invite settings**, select **Only users assigned to specific admin roles can invite guest users**.

3. Click **Save**.

#### MS.AAD.8.3v1 instructions:

1. In **Azure Active Directory** select **External Identities > External collaboration settings**.

2. Under **Collaboration restrictions**, select **Allow invitations
    only to the specified domains (most restrictive)**.

3. Select **Target domains** and enter the names of the external domains that have been authorized by the agency for guest user access.

4. Click **Save**.


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

# Appendix A: Hybrid Azure AD Guidance

The majority of this document does not focus on securing hybrid Azure AD
environments. CISA released a separate [Hybrid Identity Solutions Architecture](https://www.cisa.gov/resources-tools/services/secure-cloud-business-applications-scuba-project) document that addresses the unique implementation requirements of hybrid Azure AD infrastructure. In addition, a limited set of hybrid Azure AD policies that include on-premises components are
provided below:

- [On-premises Azure AD Password Protection for Active Directory Domain Services](https://learn.microsoft.com/en-us/azure/active-directory/authentication/concept-password-ban-bad-on-premises) SHOULD be enforced.

- [Password hash synchronization](https://learn.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-password-hash-synchronization) with the on-premises directory SHOULD be implemented.

# Appendix B: Cross-tenant Access Guidance

Some of the conditional access policies contained in this security baseline, if implemented as described herein, will impact guest user access to a tenant. For example, the policies require users to perform MFA and originate from a managed device to gain access. These requirements are also enforced for guest users. For these policies to work effectively with guest users, both the home tenant (the one that the guest user belongs to) and the resource tenant (the target tenant) may need to configure their AAD cross-tenant access settings.

[Refer to this article](https://learn.microsoft.com/en-us/azure/active-directory/external-identities/authentication-conditional-access) to gain an understanding of how MFA and device claims are passed from the home tenant to the resource tenant. [Refer to this article](https://learn.microsoft.com/en-us/azure/active-directory/external-identities/cross-tenant-access-overview) to configure the inbound and outbound cross-tenant access settings in AAD.
