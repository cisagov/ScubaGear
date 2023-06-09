# Introduction

Azure Active Directory, part of Microsoft Entra, is an enterprise identity service that provides single sign-on, multifactor authentication, and conditional access to guard against cybersecurity attacks.

## Key Terminology

The following are key terms and descriptions used in this document.

**Hybrid Azure Active Directory (AD)** – This term denotes the scenario
when an organization has an on-premises AD domain that contains the
master user directory but federates access to the cloud Microsoft 365
(M365) Azure AD tenant.

**Resource Tenant** – In scenarios where external users are involved
(e.g., guest users), the [resource tenant](https://docs.microsoft.com/en-us/azure/active-directory/external-identities/authentication-conditional-access)
hosts the M365 resources being used.

**Home Tenant** – In scenarios where external users are involved, the
[home tenant](https://docs.microsoft.com/en-us/azure/active-directory/external-identities/authentication-conditional-access)
is the one that owns the external user’s (e.g., guest) account.

## Highly Privilged Roles

The following built-in Azure AD roles are considered highly privileged at a minimum: Global Administrator, Privileged Role Administrator, User Administrator, SharePoint Administrator, Exchange Administrator, Hybrid Identity Administrator, Application Administrator, Cloud Application Administrator. Additional built-in roles that are considered highly privileged in the agency's environment can be added to this list.

## Assumptions

The agency has created emergency access accounts in Azure AD and implemented strong security measures to protect the credentials of those
accounts. Throughout Microsoft’s instructions, this entity is referred to as “emergency access or break-glass accounts.” Use the following Microsoft guidance to create and manage emergency access accounts.

[Manage emergency access accounts in Azure AD](https://docs.microsoft.com/en-us/azure/active-directory/roles/security-emergency-access)

The **License Requirements** sections of this document assume the
organization is using an [M365 E3](https://www.microsoft.com/en-us/microsoft-365/compare-microsoft-365-enterprise-plans)
or [G3](https://www.microsoft.com/en-us/microsoft-365/government)
license level. Therefore, only licenses not included in E3/G3 are
listed.

## Common guidance

### Conditional Access Policies

This section provides common guidance that should be applied when
implementing baseline instructions related to Azure AD Conditional
Access policies.

As described in Microsoft’s instructions and examples related to
conditional access policies, CISA recommends setting a policy to
**Report-only** when it is created and then performing thorough hands-on
testing to ensure that there are no unintended consequences before
toggling the policy from **Report-only** to **On**. One tool that can
assist with running test simulations is the [What If tool](https://docs.microsoft.com/en-us/azure/active-directory/conditional-access/what-if-tool).
Microsoft also describes [Conditional Access insights and reporting features](https://docs.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-insights-reporting)
that can assist with testing.

### Azure AD Privileged Identity Management

Some of the guidance in this baseline document leverages specific
features of the Azure AD Privileged Identity Management (PIM) service to
demonstrate how to improve the security of highly privileged Azure AD
roles. The PIM service provides what is referred to as “Privileged
Access Management (PAM)” capabilities in industry. As an alternative to
Azure AD PIM, there are third-party vendors that provide products or
services with privileged access management capabilities that can be
leveraged if an agency chooses to do so.

## Resources

<u>License Compliance and Copyright</u>

Portions of this document are adapted from documents in Microsoft’s
[Microsoft 365](https://github.com/MicrosoftDocs/microsoft-365-docs/blob/public/LICENSE)
and
[Azure](https://github.com/MicrosoftDocs/azure-docs/blob/main/LICENSE)
GitHub repositories. The respective documents are subject to copyright
and are adapted under the terms of the Creative Commons Attribution 4.0
International license. Source documents are linked throughout this
document. The United States government has adpted selections of these
documents to develop innovative and scalable configuration standards to
strengthen the security of widely used cloud-based software services.

# Baseline

## 1. Legacy Authentication

Block legacy authentication protocols using a conditional access policy.
Legacy authentication does not support multifactor authentication (MFA),
which is required to minimize the impact of user credential theft.

### Policies
#### MS.AAD.1.1v1
Legacy authentication SHALL be blocked.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Conditional Access: Block Legacy Authentication](https://docs.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-policy-block-legacy)

- [Five steps to securing your identity infrastructure](https://docs.microsoft.com/en-us/azure/security/fundamentals/steps-secure-identity)

### License Requirements

- N/A

### Implementation

1.  Before blocking legacy authentication across the entire application
    base, follow [these instructions](https://docs.microsoft.com/en-us/azure/active-directory/conditional-access/block-legacy-authentication#identify-legacy-authentication-use)
    to determine if any of the agency’s existing applications are
    presently using legacy authentication. This helps develop a plan to
    address policy impacts.

2.  Follow [the instructions on this page](https://docs.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-policy-block-legacy)
    to block legacy authentication. **Note:** The instructions suggest
    using Report-only mode which will not block legacy authentication.

## 2. High Risk Users

Azure AD Identity Protection uses various signals to detect the risk
level for each user and determine if an account has likely been
compromised. In addition to high risk users, high risk workload identies
may be mitigated by creating a conditional access policy that blocks medium
and high risk work load identities.
Follow [these instructions](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/workload-identity) to apply conditional access for workload identities.


### Policies
#### MS.AAD.2.1v1
Users detected as high risk SHALL be blocked.
- _Rationale:_ Users who are determined to be high risk are to be blocked
from accessing the system via Conditional Access until an administrator
remediates their account. Once a respective conditional access policy
with a block is implemented, if a high-risk user attempts to login, the
user will receive an error message with instructions to contact the
administrator to re-enable their access.
- _Last modified:_ June 2023

#### MS.AAD.2.2v1
A notification SHOULD be sent to the administrator when high-risk users are detected.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Conditional Access: User risk-based Conditional Access](https://docs.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-policy-risk-user)

- [User-linked detections](https://docs.microsoft.com/en-us/azure/active-directory/identity-protection/concept-identity-protection-risks#user-linked-detections)

- [Simulating risk detections in Identity Protection](https://docs.microsoft.com/en-us/azure/active-directory/identity-protection/howto-identity-protection-simulate-risk)

- [User experiences with Azure AD Identity Protection](https://docs.microsoft.com/en-us/azure/active-directory/identity-protection/concept-identity-protection-user-experience)
  (Examples of how these policies are applied in practice)

- [Five steps to securing your identity infrastructure](https://docs.microsoft.com/en-us/azure/security/fundamentals/steps-secure-identity)

### License Requirements

- Requires an AAD P2 license

### Implementation

**Policy MS.AAD.2.1v1:**

1.  To create the conditional access policy that implements the block
    for users at the risk level of High, follow the instructions in the
    [Enable with Conditional Access policy](https://docs.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-policy-risk-user#enable-with-conditional-access-policy)
    section, but set the policy to block access as follows:

2.  Under **Access Controls** -\> **Grant**, select **Block access**.

**Policy MS.AAD.2.2v1**:

1.  Follow the instructions in the [Configure users at risk detected alerts](https://docs.microsoft.com/en-us/azure/active-directory/identity-protection/howto-identity-protection-configure-notifications#configure-users-at-risk-detected-alerts)
    section to configure Azure AD Identity Protection to email the
    security operations team/administrator when a user account is
    determined to be high risk so that they can review and respond to
    threats.

## 3. High Risk Sign-ins

Azure AD Identity Protection uses various signals to detect the risk
level for each user sign-in. Sign-ins detected as high risk are to be
blocked via Conditional Access.

### Policies
#### MS.AAD.3.1v1
Sign-ins detected as high risk SHALL be blocked.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Conditional Access: Sign-in risk-based Conditional
  Access](https://docs.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-policy-risk)

- [Sign-in
  risk](https://docs.microsoft.com/en-us/azure/active-directory/identity-protection/concept-identity-protection-risks#sign-in-risk)

- [Simulating risk detections in Identity
  Protection](https://docs.microsoft.com/en-us/azure/active-directory/identity-protection/howto-identity-protection-simulate-risk)

- [User experiences with Azure AD Identity
  Protection](https://docs.microsoft.com/en-us/azure/active-directory/identity-protection/concept-identity-protection-user-experience)
  (Examples of how these policies are applied in practice)

### License Requirements

- Requires an AAD P2 license

### Implementation

To create the conditional access policy that implements the block for
sign-ins at the risk level of **High**, follow the instructions in the
[Enable with Conditional Access
policy](https://docs.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-policy-risk#enable-with-conditional-access-policy)
section, but set the risk level to **High** and block access.

1.  Under **Select the sign-in risk level this policy will apply to**,
    select **High.**

2.  Under **Access Controls** -\> **Grant**, select **Block access.**

**Note**: If after implementing this, it is observed that numerous
legitimate user sign-ins are consistently being blocked due to their
location being interpreted as suspicious and this creates an operational
burden on the agency, then [a Trusted Location can be
configured](https://docs.microsoft.com/en-us/azure/active-directory/conditional-access/location-condition#ip-address-ranges)
in the Conditional Access blade for each of the legitimate sign-in
locations. Azure AD Identity Protection considers the Trusted Location
data when it calculates sign-in risk, and this may help to prevent users
signing in from legitimate locations from being flagged as high risk.

## 4. Enforce Strong MFA and Secure the Registration Process
MFA is an important tool for preventing unauthorized access to federal systems, data, and other resources. Per
OMB M-22-09 and EO 14028, agencies must implement a minimum of two-factor authentication (MFA with a
minimum of two factors) whenever possible, and each authentication method must be phishing-resistant.
MFA  should be implemented to support a zero trust architecture. Figure 1 depicts MFA options from weak to strong.

**Note**: Figure adapted from [MS Build
Page](https://docs.microsoft.com/en-us/azure/active-directory/authentication/concept-authentication-methods)
article (12/29/2021).

<img src="/images/aad-mfa.png"
alt="Weak MFA (SMS/Voice) Stronger MFA (Push Notifications, Software OTP, Hardware Token OTP) Strongest MFA (FIDO2, PIV, Windows Hello)" />

Figure 1: Options for Weak MFA, Stronger MFA Options, and Strongest MFA

### Policies
#### MS.AAD.4.1v1
Phishing-resistant MFA SHALL be enforced for all users and apps.
At this time, Azure AD supports the three phishing-resistant methods listed below:
- Azure AD Certificate-Based Authentication (CBA) - supports Federal PIV cards
- FIDO2 Security Key
- Windows Hello for Business
- Federal Personal Identity Verification (PIV) card (Federated from
      agency Active Directory or other identity provider)
    - Federated PIV auth IS permitted by the plain text of the policy,
     but not preferred (versus other methods implemented in the cloud.)
     It is not possible to check this configuration via the ScubaGear tool.
     Implementation requires enforcing PIV usage on-prem via User Based Enforcement
      (https://playbooks.idmanagement.gov/piv/network/group/)

- _Rationale:_ Phishing-resistant multifactor authentication protects against
sophisticated phishing attacks. Recognizing the significant risk these
attacks present, the Office of Management and Budget (OMB), requires
federal agencies to [implement phishing-resistant
authentication](https://www.whitehouse.gov/wp-content/uploads/2022/01/M-22-09.pdf).
- _Last modified:_ June 2023

#### MS.AAD.4.2v1
If Phishing-resistant MFA is not implemented yet, then an alternative MFA method SHALL be enforced for all users and apps.

- _Rationale:_ Phishing-resistant MFA may not always be immediately available,
especially on mobile devices. If phishing-resistant MFA is unavailable,
one of the following options for multifactor authentication is permissible.
However, organizations must upgrade to a phishing-resistant MFA method as soon as
possible to become compliant with this policy and address the critical
security threat posed by modern phishing attacks.

    - Microsoft Authenticator – push notification or passwordless
    - Authenticator app or hardware token – code

- _Last modified:_ June 2023

#### MS.AAD.4.3v1
If Phishing-resistant MFA is not implemented yet and Microsoft Authenticator is enabled, it SHALL be
configured to show the user context information when logging in via the app

- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.AAD.4.4v1
The Authentication Methods Manage Migration feature SHALL be set to Migration Complete
- _Rationale:_ By configuring the Manage Migration feature to Migration Complete, we ensure
that the tenant has disabled the legacy authentication methods screen (which was not available
via the API to be checked by ScubaGear). This also ensures that the MFA and SSPR authentication
methods are both managed from a central screen thereby reducing administrative complexity and
reducing the chances of security misconfigurations.
- _Last modified:_ June 2023

#### MS.AAD.4.5v1
The authentication methods SMS, Voice Call and Email OTP SHALL be disabled
- _Rationale:_ This policy will only be checked if the tenant has their Manage Migration feature set
to Migration Complete because the configuration data is not available from the legacy authentication methods page.
- _Last modified:_ June 2023

#### MS.AAD.4.6v1
Phishing-resistant MFA SHALL be required for Highly Privileged Roles.
- _Rationale:_ This will be implemented and assessed using authentication strength just
as for policy bullet 1 above, except that this policy is scoped to privileged roles
- _Last modified:_ June 2023

#### MS.AAD.4.7v1
Managed Devices SHOULD be required to register MFA
- _Rationale:_ This can help mitigate scenarios where hackers steal unused account credentials
and then register their own MFA devices to access the tenant by meeting the MFA requirement.
- _Last modified:_ June 2023

### Resources

- [What authentication and verification methods are available in Azure
  Active
  Directory?](https://docs.microsoft.com/en-us/azure/active-directory/authentication/concept-authentication-methods)

- [Use additional context in Microsoft Authenticator notifications
  (Preview) - Azure Active Directory - Microsoft Entra \| Microsoft
  Docs](https://docs.microsoft.com/en-us/azure/active-directory/authentication/how-to-mfa-additional-context#enable-additional-context-in-the-portal)

- [M-22-09 Federal Zero Trust
  Strategy](https://www.whitehouse.gov/wp-content/uploads/2022/01/M-22-09.pdf)

- [What authentication and verification methods are available in Azure Active Directory?](  https://learn.microsoft.com/en-us/azure/active-directory/authentication/concept-authentication-methods)


### License Requirements

- N/A

### Implementation

**Policy  MS.AAD.4.1v1:**

Use the following instructions to configure a phishing-resistant MFA
method for all users.
1.  Follow the instructions at [this
    link](https://learn.microsoft.com/en-us/azure/active-directory/authentication/concept-authentication-methods-managed)
    to manage authentication strengths for all users.
2.  Under **Authentication Methods** select **Policies**
3.  Ensure the desired phishing-resistant method(s) **Target** "All users" and are set to **Enabled**
4.  For configuring **FIDO Security Key** MFA Follow the instructions at [this
    link](https://docs.microsoft.com/en-us/azure/active-directory/authentication/howto-authentication-passwordless-security-key#enable-fido2-security-key-method)
    to configure FIDO2.
5.  For configuring **Certificate Based Authentication** follow the instructions at [this
    link](https://docs.microsoft.com/en-us/azure/active-directory/authentication/how-to-certificate-based-authentication#steps-to-configure-and-test-azure-ad-cba)
6.  For configuring **Windows Hello** follow the instructions at [this
    link](https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-deployment-guide).


**Policy  MS.AAD.4.2v1:**

 If the agency is unable to use phishing-resistant MFA for all users, then
follow [these
    instructions](https://docs.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-policy-all-users-mfa)
    to create a conditional access policy that requires all users to
    authenticate with MFA.

**Policy  MS.AAD.4.3v1:**
If Phishing-resistant MFA is not implemented yet and Microsoft Authenticator is enabled, follow
[these instructions ](https://learn.microsoft.com/en-us/azure/active-directory/authentication/concept-authentication-authenticator-app).
To enable passwordless authentication using Microsoft Authenticator, follow
[these instructions ](https://learn.microsoft.com/en-us/azure/active-directory/authentication/howto-authentication-passwordless-phone).


**Policy  MS.AAD.4.4v1:**
To migrate from legacy MFA and Self-Service Password Reset (SSPR) Microsoft implementation options follow
[these instructions ](https://learn.microsoft.com/en-us/azure/active-directory/authentication/how-to-authentication-methods-manage).

In the **Microsoft Authenticator** settings, under **Configure**, select
- **No** for **Allow the use of Microsoft Authenticator OTP**
- **Enabled** for **All Users"** under **Show application name in push and passwordless notifications**
- **Enabled** for **All Users** under **Show geographic location in push and passwordless notifications**
- **Microsoft Managed** for **All Users** under  **Microsoft Authenticator on companion applications**

**Policy  MS.AAD.4.5v1:**
To disable SMS, Voice Call, and Email OTP, from the **Authentication Methods->Policy** page:
Set the **Enabled** status to **No** for each authentication method.

**Policy  MS.AAD.4.6v1:**
If the agency is implementing a phishing-resistant MFA method for all
users, follow the instructions in Policy #1 above. Otherwise use
the following instructions to configure a non-phishing resistant MFA
method for users that are not in highly privileged roles.

In the **Authentication Methods->Policies** page, select one of the phishing-resistant methods.
Under **Enable and Target**, under **Include->Target**, choose **Select groups**

Add the appropriate groups which include the users with highly privileged roles.
Note, Microsoft has released a new capability [(Public Preview) ](https://learn.microsoft.com/en-us/azure/active-directory/privileged-identity-management/concept-pim-for-group) for controlling access to highly privileged roles
using Privileged Identity Management (PIM) for Groups. Future revisions of this baseline may
include updates to this policy that take advantage of these new feautres.

**Policy  MS.AAD.4.7v1:**
To require managed devices to register for MFA, follow these instructions
To create the conditional access policy that requires managed devices to
register for MFA, follow the instructions in the
[Enable with Conditional Access policy](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-policy-registration) but require device to be marked as compliant or Hybrid Azure AD joined:

1.  Under **Access Controls** -\> **Grant access**, select **Require device to be marked as compliant** or **Require Hybrid Azure AD joined device**


## 5. Azure AD logs

Configure Azure AD to send critical logs to the agency’s centralized
SIEM and to CISA’s central analysis system so that they can be audited
and queried. Configure Azure AD to send logs to a storage account and
retain them for when incident response is needed.

### Policies
#### MS.AAD.5.1v1
The following critical logs SHALL be sent at a minimum: AuditLogs, SignInLogs, RiskyUsers, UserRiskEvents, NonInteractiveUserSignInLogs, ServicePrincipalSignInLogs, ADFSSignInLogs, RiskyServicePrincipals, ServicePrincipalRiskEvents.
- _Rationale:_ TODO
- _Last modified:_ June 2023

<!-- -->

#### MS.AAD.5.2v1
If managed identities are used for Azure resources, logs SHALL include the ManagedIdentitySignInLogs log type.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.AAD.5.3v1
If the Azure AD Provisioning Service is used to provision users to SaaS apps or other systems, also include the ProvisioningLogs log type.
- _Rationale:_ TODO
- _Last modified:_ June 2023

<!-- -->

#### MS.AAD.5.4v1
The logs SHALL be sent to the agency's SOC for monitoring.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Everything you wanted to know about Security and Audit Logging in
  Office
  365](https://thecloudtechnologist.com/2021/10/15/everything-you-wanted-to-know-about-security-and-audit-logging-in-office-365/)

- [Sign-in logs in Azure Active Directory -
  preview](https://docs.microsoft.com/en-us/azure/active-directory/reports-monitoring/concept-all-sign-ins)

- [National Cybersecurity Protection System-Cloud Interface Reference
  Architecture Volume
  1](https://www.cisa.gov/sites/default/files/publications/NCPS%20Cloud%20Interface%20RA%20Volume%20One%20%282021-05-14%29.pdf)

- [National Cybersecurity Protection System - Cloud Interface Reference
  Architecture Volume
  2](https://www.cisa.gov/sites/default/files/publications/NCPS%20Cloud%20Interface%20RA%20Volume%20Two%202021-06-11%20%28508%20COMPLIANT%29.pdf)

### License Requirements

- N/A

### Implementation

[Follow these instructions](https://docs.microsoft.com/en-us/azure/active-directory/reports-monitoring/quickstart-azure-monitor-route-logs-to-storage-account)
to configure sending the logs to a storage account:

1.  From the **Diagnostic settings** page, click **Add diagnostic**
    setting.

2.  Select the specific logs mentioned in the previous policy section.

3.  Under **Destination Details,** select the **Archive to a storage
    account** check box and select the storage account that was
    specifically created to host security logs.

4.  In the **Retention** field enter “365” days.

## 6. Register Third-Party Applications

Ensure that only administrators can register third-party applications
that can access the tenant.

### Policies
#### MS.AAD.6.1v1
Only administrators SHALL be allowed to register third-party applications.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Restrict Application Registration for Non-Privileged
  Users](https://www.trendmicro.com/cloudoneconformity/knowledge-base/azure/ActiveDirectory/users-can-register-applications.html)

### License Requirements

- N/A

### Implementation

1.  In the **Azure Portal**, navigate to **Azure Active Directory.**

<!-- -->

2. Under **Manage**, select **Users**.

3. Select **User settings**.

4. Under **App Registrations** -\> **Users can register applications**,
    select **No.**

5. Click **Save**.

## 7. Consenting to Third-Party Applications

Ensure that only administrators can consent to third-party applications
and only administrators can control which permissions are granted. An
admin consent workflow can be configured in Azure AD, otherwise users
will be blocked when they try to access an application that requires
permissions to access organizational data. Develop a process for
approving and managing third-party applications.

### Policies
#### MS.AAD.7.1v1
Only administrators SHALL be allowed to consent to third-party
  applications.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.AAD.7.2v1
An admin consent workflow SHALL be configured.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.AAD.7.3v1
Group owners SHALL NOT be allowed to consent to third-party applications.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Enforce Administrators to Provide Consent for Apps Before
  Use](https://www.trendmicro.com/cloudoneconformity/knowledge-base/azure/ActiveDirectory/users-can-consent-to-apps-accessing-company-data-on-their-behalf.html)

- [Configure the admin consent
  workflow](https://docs.microsoft.com/en-us/azure/active-directory/manage-apps/configure-admin-consent-workflow)

### License Requirements

- N/A

### Implementation

1.  In the **Azure Portal**, navigate to **Azure Active Directory.**

<!-- -->

2. Create a new Azure AD Group that contains admin users responsible
    for reviewing and adjudicating app requests.

3. Under **Manage**, select **Enterprise Applications.**

4. Under **Security**, select **Consent and permissions.**

5. Under **User consent for applications**, select **Do not allow user
    consent.**

6. Under **Group owner consent for apps accessing data**, select **Do
    not allow group owner consent.**

7. In the menu, navigate back to **Enterprise Applications**.

8. Under **Manage**, select **User Settings**.

9. Under **Admin consent requests** -\> **Users can request admin
    consent to apps they are unable to consent to**, select **Yes.**

10. Under **Who can review admin consent requests**, select the group
    created in step two that is responsible for reviewing and
    adjudicating app requests.

11. Click **Save**

## 8. Passwords

Ensure that user passwords do not expire. Both the National Institute of
Standards and Technology (NIST) and Microsoft emphasize MFA because they
indicate that mandated password changes make user accounts less secure.

### Policies
#### MS.AAD.8.1v1
User passwords SHALL NOT expire.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Password policy recommendations - Microsoft 365 admin \| Microsoft
  Docs](https://docs.microsoft.com/en-us/microsoft-365/admin/misc/password-policy-recommendations?view=o365-worldwide#password-expiration-requirements-for-users)

- [Eliminate bad passwords using Azure Active Directory Password
  Protection](https://docs.microsoft.com/en-us/azure/active-directory/authentication/concept-password-ban-bad)

- [NIST Special Publication 800-63B - Digital Identity
  Guidelines](https://pages.nist.gov/800-63-3/sp800-63b.html)

### License Requirements

- N/A

### Implementation

[Follow the instructions at this
link](https://docs.microsoft.com/en-us/microsoft-365/admin/manage/set-password-expiration-policy?view=o365-worldwide#set-password-expiration-policy)
to configure the password expiration policy.

## 11. Highly Privileged User Management and Monitoring

Limit the number of users, to include "breakglass" accounts, that are assigned the role
of Global Administrator to minimize risks of tenant compromise.

### Policies
#### MS.AAD.11.1v1
A minimum of two users and a maximum of eight users SHALL be provisioned with the Global Administrator role.
- _Rationale:_  Global Administrator is the highest privileged role in Azure AD because
it provides unfettered access to the tenant. Therefore, if a user’s
credential with these permissions were to be compromised, it would
present grave risks to the security of the tenant.
- _Last modified:_ June 2023

#### MS.AAD.11.2v1
Assign users to finer-grained administrative roles that they need to perform their duties instead of being assigned the
Global Administrator role.
- _Rationale:_  Applying principles of least privilege is a core security best practice.
- _Last modified:_ June 2023

#### MS.AAD.11.3v1
Users that need to be assigned to highly privileged Azure AD roles SHALL be provisioned cloud-only accounts that are separate from the on-premises directory or other federated identity providers.
- _Rationale:_ Assign users that need to perform highly privileged tasks to cloud-only
Azure AD accounts to minimize the collateral damage of an on-premises
identity compromise.[^1]
- _Last modified:_ June 2023

#### MS.AAD.11.4v1
MFA SHALL be required for user access to highly privileged roles.
- _Rationale:_ Requiring users to perform MFA to access highly privileged roles is
a backup policy to enforce MFA for highly privileged users in case the main
conditional access policy—which requires MFA for all users—is disabled or misconfigured.
- _Last modified:_ June 2023

#### MS.AAD.11.5v1
Permanent active role assignments SHALL NOT be allowed for highly privileged roles except for break-glass accounts, accounts that are explicity allowed by the agency, and service accounts that require perpetual access.
- _Rationale:_ Assigning highly privileged roles using permanent active role assignments increases risk of privilge escalation. Privilege escalation attacks can be mitigated by assigning users to eligible role assignments in a PAM system and providing an expiration period for active assignments requiring privileged users to reactivate their highly privileged roles upon expiration. **Note**: Although Azure AD PIM is referenced in the implementation instructions, an equivalent third-party PAM service may be used instead.
- _Last modified:_ June 2023

#### MS.AAD.11.6v1
Provisioning of users to highly privileged roles SHALL NOT occur outside of a PAM system, such as the Azure AD PIM service, because this bypasses the controls the PAM system provides.
- _Rationale:_ TODO
- _Last modified:_ June 2023

<!-- -->
#### MS.AAD.16.1v1
Eligible and Active highly privileged role assignments SHALL trigger an alert.
- _Rationale:_ TODO
- _Last modified:_ June 2023

**Note**: Although Azure AD PIM is referenced in the implementation
instructions, an equivalent third-party PAM service may be used instead.

#### MS.AAD.11.7v1
Activation of highly privileged roles SHOULD require approval.
- _Rationale:_ Requiring approval for a user to activate a highly privileged role, such
as Global Administrator makes it more challenging for an attacker
to leverage the stolen credentials of highly privileged users and
ensures that privileged access is monitored closely.
- _Last modified:_ June 2023

#### MS.AAD.11.8v1
Eligible and Active highly privileged role assignments SHALL trigger an alert.
- _Rationale:_ Since many cyber attacks leverage privileged access, it is imperative to
closely monitor the assignment and activation of the highest privileged
roles for signs of compromise. Creating alerts to trigger when a highly
privileged role is assigned to a user and when a user activates a highly
privileged role can help mitigate the threat.
Note: Although Azure AD PIM is referenced in the implementation
instructions, an equivalent third-party PAM service may be used instead.
- _Last modified:_ June 2023

#### MS.AAD.11.9v1
User activation of the Global Administrator role SHALL trigger an
  alert.
- _Rationale:_ For insights into PIM alert configuration see https://learn.microsoft.com/en-us/azure/active-directory/privileged-identity-management/pim-how-to-configure-security-alerts
- _Last modified:_ June 2023

#### MS.AAD.11.10v1
User activation of other highly privileged roles SHOULD trigger an alert.
- _Rationale:_ TODO
- _Last modified:_ June 2023

<!-- -->

  - Note: Alerts can be configured for user activation of other highly
  privileged roles as well but note that if users activate these other
  roles frequently, it can prompt a significant number of alerts.
  Therefore, for those other roles, it might be prudent to set up a
  separate monitoring mailbox from the one configured for the alerts
  associated with the Global Administrator role. This separate mailbox
  would be designed to store alerts for “review as necessary” purposes
  versus the mailbox configured for the Global Administrator role, which
  should be monitored closely since that role is sensitive.

### Resources

- [Best practices for Azure AD roles (Limit number of Global
  Administrators to less than 5)](https://docs.microsoft.com/en-us/azure/active-directory/roles/best-practices#5-limit-the-number-of-global-administrators-to-less-than-5)

- [About admin roles](https://docs.microsoft.com/en-us/microsoft-365/admin/add-users/about-admin-roles?view=o365-worldwide)

- [Securing privileged access for hybrid and cloud deployments in Azure AD](https://docs.microsoft.com/en-us/azure/active-directory/roles/security-planning#ensure-separate-user-accounts-and-mail-forwarding-for-global-administrator-accounts)

- [Five steps to securing your identity infrastructure](https://docs.microsoft.com/en-us/azure/security/fundamentals/steps-secure-identity)

- [M-22-09 Federal Zero Trust Strategy](https://www.whitehouse.gov/wp-content/uploads/2022/01/M-22-09.pdf)

- [Assign Azure AD roles in Privileged Identity Management](https://docs.microsoft.com/en-us/azure/active-directory/privileged-identity-management/pim-how-to-add-role-to-user)

- [Approve or deny requests for Azure AD roles in Privileged Identity Management](https://docs.microsoft.com/en-us/azure/active-directory/privileged-identity-management/azure-ad-pim-approval-workflow)

- [Assign Azure AD roles in Privileged Identity Management](https://docs.microsoft.com/en-us/azure/active-directory/privileged-identity-management/pim-how-to-add-role-to-user)

### License Requirements

- Use of an Azure AD PIM or an equivalent third-party PAM service.

- Azure AD PIM requires an AAD P2 license

### Implementation
#### Policy MS.AAD.11.1v1
1.  In the **Azure Portal**, navigate to **Azure Active Directory.**

<!-- -->

2. Select **Roles and administrators.**

3. Select the **Global administrator role.**

4. Under **Manage**, select **Assignments.**

5. Validate that between two to eight users are listed.

<!-- -->

6.  For those who have Azure AD PIM, they will need to check both the
    **Eligible assignments** and **Active assignments** tabs. There
    should be a total of two to eight users across both of these tabs
    (not individually).

7.  If any groups are listed, need to check how many users are members
    of each group and include that in the total count.

#### Policy MS.AAD.11.2v1
To establish finer-grained administrative roles:

1.  In the **Azure Portal**, navigate to **Azure Active Directory.**

<!-- -->

2.  Select **Security.**

3.  Under **Manage**, select **Identity Secure Score.**

4.  Click the **Columns** button and ensure that all the available
    columns are selected to display and click **Apply.**

5.  Review the score for the action named **Use least privileged administrative
    roles.**

6.  Ensure that the maximum score was achieved, and that the status is
    **Completed.**

7.  If the maximum score was not achieved, click the improvement action
    and Microsoft provides a pop-up page with detailed instructions on
    how to address the weakness. In short, to address the weakness,
    assign users to finer grained roles (e.g., SharePoint Administrator,
    Exchange Administrator) instead of Global Administrator. Only the
    minimum number of users necessary should be assigned to Global
    Administrator. Once the roles are reassigned according to the
    guidance, check the score again after 48 hours to ensure compliance.

#### Policy MS.AAD.11.3v1
Review [these](https://docs.microsoft.com/en-us/azure/active-directory/roles/view-assignments)
instructions to identify users assigned to highly privileged roles and
verify the account does not exist outside Azure AD.

#### Policy MS.AAD.11.4v1
[Follow these instructions](https://docs.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-policy-all-users-mfa)
to create a conditional access policy requiring MFA for access, but
under **Assignments,** use the following tailored steps to scope the
policy to privileged roles.

1.  Under **Assignments**, select **Users and groups.**

<!-- -->

2.  Under **Include**, choose **Select users and groups**, then click
    the **Directory roles** checkbox. Select each of the roles listed in
    the baseline statement, [Highly Privileged User Accounts SHALL be Cloud-Only](Policy MS.AAD.12.1v1).

3.  Under **Exclude**, follow Microsoft’s guidance from the previously
    provided instructions link.

#### Policy MS.AAD.11.5v1
Note: Any parts of the following implementation instructions that
reference the Azure AD PIM service will vary if using a third-party PAM
system.

1.  In the **Azure Portal**, navigate to **Azure AD Privileged Identity
    Management (PIM).**

<!-- -->

2. Under **Manage**, select **Azure AD roles**.

3. Under **Manage**, select **Roles**. This should bring up a list of
    all the Azure AD roles managed by the PIM service.

4. **Note**: Repeat this step and step 5 for each highly privileged role
    referenced in the policy section. The role “Exchange Administrator” is
    used as an example in these instructions.

<!-- fix -->
  1.  Click the **Exchange Administrator** role in the list.
  2.  Click **Settings**.
  3.  Click **Edit.**
  4.  Select the **Assignment** tab.
  5.  De-select the option named **Allow permanent active assignment.**
  6.  Click **Update.**

<!-- -->

<!-- -->

#### Policy MS.AAD.11.6v1
 In addition to checking for permanent assignments using the PIM Assignments, PIM also provides a report that lists all role assignments that were performed outside of PIM so that those assignments can be deleted and properly recreated using PIM.

<!-- -->

  1.  From the **PIM landing page**, under **Manage**, select **Azure AD
    roles.**
  2.  Under **Manage**, select **Alerts.**
  3.  Click the **Scan** button and wait for the scan to complete.
  4.  If there were any roles assigned outside of PIM, the report will
    display an alert named, **Roles are being assigned outside of
    Privileged Identity Management**; Click that alert.
  5.  PIM displays a list of users, their associated roles, and the
    date/time that they were assigned a role outside of PIM: Delete the
    non-compliant role assignments and then recreate them using the PIM
    service.

#### Policy MS.AAD.11.7v1
**Note**: Any parts of the following implementation instructions that
reference the Azure AD PIM service will vary if using a third-party PAM
system.

1.  In the **Azure Portal**, navigate to **Azure AD** and create a new
    group named “Privileged Escalation Approvers.” This group will
    contain users that will receive role activation approval requests
    and approve or deny them. Users in this group must, at least, have
    the permissions provided to the Privileged Role Administrators role
    to adjudicate requests.

2.  In the **Azure Portal**, navigate to **Azure AD Privileged Identity
    Management (PIM).**

<!-- -->

3. Under **Manage**, select **Azure AD roles**.

4. Under **Manage**, select **Roles**. This should bring up a list of
    all the Azure AD roles managed by the PIM service.

5. Repeat this step for the Privileged Role Administrator role, User
    Administrator role, and other roles that the agency has designated
    as highly privileged.

<!-- -->

  1.  Click the **Global Administrator** role in the list.
  2.  Click **Settings.**
  3.  Click **Edit**.
  4.  Select the **Require approval to activate** option.
  5.  Click **Select approver**s, select the group **Privileged Escalation
    Approvers**, and then click **Select**.
  6.  Click **Update**.

#### Policies MS.AAD.11.8v1, MS.AAD.11.9v1, MS.AAD.11.10v1

Note: Any parts of the following implementation instructions that
reference the Azure AD PIM service will vary if using a third-party PAM
system.

1.  In the **Azure Portal**, navigate to **Azure AD Privileged Identity
    Management (PIM).**

<!-- -->

2. Under **Manage**, select A**zure AD roles.**

3. Under **Manage**, select **Roles**. This should bring up a list of
    all the Azure AD roles managed by the PIM service.

4. Click the **Global Administrator** role.

5. Click **Settings** and then click **Edit.**

6. Click the **Notification** tab.

7. Under **Send notifications when members are assigned as eligible to
    this role**, in the **Role assignment alert** -\> **Additional
    recipients** textbox, enter the email address of the mailbox
    configured to receive the alerts for this role.

8. Under S**end notifications when members are assigned as active to
    this role**, in the **Role assignment alert** -\> **Additional
    recipients** textbox, enter the email address of the mailbox
    configured to receive the alerts for this role.

9. Under **Send notifications when eligible members activate this
    role**, in the **Role activation alert** -\> **Additional
    recipients** textbox, enter the email address of the mailbox
    configured to receive the alerts for this role.

10. Click **Update**.

11. Repeat steps 4 through 10 for each of the other highly privileged
    roles referenced in the policy section above, with one modification:

<!-- -->

  1.  When configuring the **Send notifications when eligible members
    activate this role** for these other roles, enter an email address
    of a mailbox that is different from the one used to monitor Global
    Administrator activations.

## 17. Managed Devices

Require that users connect to M365 from a device that is managed using
conditional access. Agencies that are implementing a hybrid Azure AD
environment will likely use the conditional access control option named
**Hybrid Azure AD joined**, whereas agencies that are using devices that
connect directly to the cloud and do not join an on-premises AD will use
the conditional access control option named, **Require device to be
marked as compliant**.

**Guest user access note**: This conditional access policy will impact
guest access to the tenant because guest users will be required to
authenticate from a managed device similar to regular Azure AD users.
For guest users, the organization that manages their home tenant is
responsible for managing their devices and the resource tenant must be
configured to trust the device claims from the home tenant, otherwise
guest users will be blocked by the policy. [This link](https://docs.microsoft.com/en-us/azure/active-directory/external-identities/authentication-conditional-access) describes the
detailed authentication flow for guest users and how conditional access
related to devices is applied.
The implementation section describes the cross-tenant settings that must
be configured in both the home and the resource tenants to facilitate
guest access with managed devices.

### Policies
#### MS.AAD.17.1v1
Managed devices SHOULD be required for authentication.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Configure hybrid Azure AD join](https://docs.microsoft.com/en-us/azure/active-directory/devices/howto-hybrid-azure-ad-join)

- [Azure AD joined devices](https://docs.microsoft.com/en-us/azure/active-directory/devices/concept-azure-ad-join)

- [Set up enrollment for Windows devices (for Intune)](https://docs.microsoft.com/en-us/mem/intune/enrollment/windows-enroll)

### License Requirements

- Use Microsoft Intune (if implementing the requirement for the device
  to be compliant).

### Implementation

[Follow these instructions](https://docs.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-policy-compliant-device#create-a-conditional-access-policy)
to create a conditional access policy that requires the device to be
either hybrid Azure AD joined or compliant during authentication.

Use the following instructions to facilitate guest access with managed
devices. Although the agency implementing this baseline only controls
the resource tenant and does not have control over the home tenant, CISA
provides our recommended security configuration for the home tenant in
this section.

Reference [this link](https://docs.microsoft.com/en-us/azure/active-directory/external-identities/cross-tenant-access-overview)
for a general description of cross-tenant access settings to become
familiar with the terminology and configurations.

For the resource tenant, use the following steps (for demonstration
purposes, the home tenant domain is named “home.onmicrosoft.com” —
replace this name with the actual name of the tenant):

<!-- -->

1.  Navigate to **Azure AD** -\> **External Identities** -\>
    **Cross-tenant access settings.**

<!-- -->

2.  In **Organizational Settings**, add a new organization –
    “home.onmicrosoft.com”.

3.  Open the **Inbound access** settings for the newly added
    organization.

4.  Click the **B2B collaboration** tab. Under **External users and
    Groups** -\> **Access status**, select **Allow access.**

5.  Under **External users and Groups** -\> **Applies to**, select **All
    external users and groups.**

6.  Click the **Trust settings** tab. Under **Customize settings** -\>
    select **Trust multi-factor authentication from Azure AD tenants**,
    **Trust compliant devices,** and **Trust hybrid Azure AD joined
    devices**

<!-- -->

For the home tenant, use the following steps (for demonstration
purposes the resource tenant domain is named
“resource.onmicrosoft.com” — replace this name with the actual name
of the tenant):

<!-- -->

1.  Navigate to **Azure AD** -\> **External Identities** -\>
    **Cross-tenant access settings.**

<!-- -->

2.  In **Organizational Settings**, Add a new organization –
    “resource.onmicrosoft.com”.

3.  Open the **Outbound access** settings for the newly added
    organization.

4.  Click the **B2B collaboration** tab. Under **Users and Groups** -\>
    **Access status**, select **Allow access.**

5.  Under **Users and Groups** -\> **Applies to**, select **All users.**

## 18. Guest User Access

Ensure that only users with specific privileges can invite guest users
to the tenant and that invites can only be sent to specific external
domains. Also ensure that guest users have limited access to Azure AD
directory objects.

#### MS.AAD.18.1v1
Only users with the Guest Inviter role SHOULD be able to invite guest users.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.AAD.18.2v1
Guest invites SHOULD only be allowed to specific external domains that have been authorized by the agency for legitimate business purposes.
- _Rationale:_ TODO
- _Last modified:_ June 2023

#### MS.AAD.18.3v1
Guest users SHOULD have limited or restricted access to Azure AD directory objects.
- _Rationale:_ TODO
- _Last modified:_ June 2023

### Resources

- [Configure external collaboration settings](https://docs.microsoft.com/en-us/azure/active-directory/external-identities/external-collaboration-settings-configure)

### License Requirements

- N/A

### Implementation

[Follow these instructions](https://docs.microsoft.com/en-us/azure/active-directory/external-identities/external-collaboration-settings-configure#configure-settings-in-the-portal)
to configure the Azure AD **External collaboration settings**.

1.  Under **Guest user access**, select **Guest users have limited
    access to properties and memberships of directory objects.** or
    **Guest user access is restricted to properties and memberships of their own directory
    objects (most restrictive)".**

2.  Under **Guest invite settings**, select **Only users assigned to
    specific admin roles can invite guest users**.

3.  Under **Collaboration restrictions**, select **Allow invitations
    only to the specified domains (most restrictive)**.

<!-- -->

4.  Select **Target domains** and enter the names of the external
    domains that have been authorized by the agency for guest user
    access.

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
environments. CISA is working on a separate document that addresses the
unique implementation requirements of hybrid Azure AD infrastructure,
including the on-premises components. Meanwhile, the following limited
set of hybrid Azure AD policies that include on-premises components are
provided:

- Azure AD Password Protection SHOULD be implemented for the on-premises
  directory.

<!-- -->

- [Enforce on-premises Azure AD Password Protection for Active Directory Domain Services](https://docs.microsoft.com/en-us/azure/active-directory/authentication/concept-password-ban-bad-on-premises)

- [Plan and deploy on-premises Azure Active Directory Password Protection](https://docs.microsoft.com/en-us/azure/active-directory/authentication/howto-password-ban-bad-on-premises-deploy)

<!-- -->

- Password hash synchronization with the on-premises directory SHOULD be
  implemented.

<!-- -->

- [Implement password hash synchronization with Azure AD Connect sync](https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-password-hash-synchronization)

<!-- -->

- Service accounts created in Azure AD to support the integration of
  Azure AD Connect SHOULD be restricted to originate from the IP address
  space of the network hosting the on-premises AD. This can be
  implemented via a conditional access policy that is applied to the
  Azure AD Connect service accounts and blocks access except from a
  specific Azure AD Named Location that is configured with respective
  on-premises IP address range.

<!-- -->

- [Using the location condition in a Conditional Access policy](https://docs.microsoft.com/en-us/azure/active-directory/conditional-access/location-condition)

- [Azure AD Connect: Accounts and permissions](https://docs.microsoft.com/en-us/azure/active-directory/hybrid/reference-connect-accounts-permissions)

[^1]: “Cloud-only” user accounts have no ties to the on-premises AD and
    are not federated – they are local to Azure AD only.
