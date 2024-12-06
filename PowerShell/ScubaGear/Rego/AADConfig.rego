package aad
import rego.v1
import data.utils.report.NotCheckedDetails
import data.utils.report.NotCheckedDeprecation
import data.utils.report.CheckedSkippedDetails
import data.utils.report.ReportDetailsBoolean
import data.utils.report.ReportDetailsString
import data.utils.key.IsEmptyContainer
import data.utils.key.Contains
import data.utils.key.FilterArray
import data.utils.key.ConvertToSetWithKey
import data.utils.key.ConvertToSet
import data.utils.aad.ReportFullDetailsArray
import data.utils.aad.ReportDetailsArrayLicenseWarningCap
import data.utils.aad.ReportDetailsArrayLicenseWarning
import data.utils.aad.UserExclusionsFullyExempt
import data.utils.aad.GroupExclusionsFullyExempt
import data.utils.aad.Aad2P2Licenses
import data.utils.aad.IsPhishingResistantMFA
import data.utils.aad.PolicyConditionsMatch
import data.utils.aad.CAPLINK
import data.utils.aad.DomainReportDetails
import data.utils.aad.INT_MAX


#############
# Constants #
#############

RESTRICTEDACCESS := "2af84b1e-32c8-42b7-82bc-daa82404023b" #gitleaks:allow

LIMITEDACCESS := "10dae51f-b6af-4016-8d66-8c2a99b929b3" #gitleaks:allow

MEMBERUSER := "a0b1b346-4d3e-4e8b-98f8-753987be4970"


############
# MS.AAD.1 #
############

#
# MS.AAD.1.1v1
#--

# If policy matches basic conditions, special conditions,
# & all exclusions are intentional, save the policy name
LegacyAuthentication contains CAPolicy.DisplayName if {
    some CAPolicy in input.conditional_access_policies

    # Match all simple conditions
    PolicyConditionsMatch(CAPolicy) == true
    "other" in CAPolicy.Conditions.ClientAppTypes
    "exchangeActiveSync" in CAPolicy.Conditions.ClientAppTypes
    "block" in CAPolicy.GrantControls.BuiltInControls

    # Only match policies with user and group exclusions if all exempted
    UserExclusionsFullyExempt(CAPolicy, "MS.AAD.1.1v1") == true
    GroupExclusionsFullyExempt(CAPolicy, "MS.AAD.1.1v1") == true
}

# Pass if at least 1 policy meets all conditions
tests contains {
    "PolicyId": "MS.AAD.1.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-MgBetaIdentityConditionalAccessPolicy"],
    "ActualValue": LegacyAuthentication,
    "ReportDetails": concat(". ", [ReportFullDetailsArray(LegacyAuthentication, DescriptionString), CAPLINK]),
    "RequirementMet": Status
} if {
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    Status := count(LegacyAuthentication) > 0
}
#--

############
# MS.AAD.2 #
############

#
# MS.AAD.2.1v1
#--

# If policy matches basic conditions, special conditions,
# & all exclusions are intentional, save the policy name
BlockHighRisk contains CAPolicy.DisplayName if {
    some CAPolicy in input.conditional_access_policies

    # Match all simple conditions
    PolicyConditionsMatch(CAPolicy) == true
    "high" in CAPolicy.Conditions.UserRiskLevels
    "block" in CAPolicy.GrantControls.BuiltInControls

    # Only match policies with user and group exclusions if all exempted
    UserExclusionsFullyExempt(CAPolicy, "MS.AAD.2.1v1") == true
    GroupExclusionsFullyExempt(CAPolicy, "MS.AAD.2.1v1") == true
}

# Pass if at least 1 policy meets all conditions & has correct
# licence.
tests contains {
    "PolicyId": "MS.AAD.2.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-MgBetaIdentityConditionalAccessPolicy"],
    "ActualValue": BlockHighRisk,
    "ReportDetails": ReportDetailsArrayLicenseWarningCap(BlockHighRisk, DescriptionString),
    "RequirementMet": Status
} if {
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    Conditions := [
        count(Aad2P2Licenses) > 0,
        count(BlockHighRisk) > 0
    ]
    Status := count(FilterArray(Conditions, false)) == 0
}
#--

#
# MS.AAD.2.2v1
#--

# At this time we are unable to test for X because of Y
tests contains {
    "PolicyId": "MS.AAD.2.2v1",
    "Criticality": "Should/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.AAD.2.2v1"),
    "RequirementMet": false
}
#--

#
# MS.AAD.2.3v1
#--

# If policy matches basic conditions, special conditions,
# & all exclusions are intentional, save the policy name
SignInBlocked contains CAPolicy.DisplayName if {
    some CAPolicy in input.conditional_access_policies

    # Match all simple conditions
    PolicyConditionsMatch(CAPolicy)
    "high" in CAPolicy.Conditions.SignInRiskLevels
    "block" in CAPolicy.GrantControls.BuiltInControls

    # Only match policies with user and group exclusions if all exempted
    UserExclusionsFullyExempt(CAPolicy, "MS.AAD.2.3v1") == true
    GroupExclusionsFullyExempt(CAPolicy, "MS.AAD.2.3v1") == true
}

# Pass if at least 1 policy meets all conditions & has correct
# licence.
tests contains {
    "PolicyId": "MS.AAD.2.3v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-MgBetaIdentityConditionalAccessPolicy"],
    "ActualValue": SignInBlocked,
    "ReportDetails": ReportDetailsArrayLicenseWarningCap(SignInBlocked, DescriptionString),
    "RequirementMet": Status
} if {
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    Conditions := [
        count(Aad2P2Licenses) > 0,
        count(SignInBlocked) > 0
    ]
    Status := count(FilterArray(Conditions, false)) == 0
}
#--

############
# MS.AAD.3 #
############

#
# MS.AAD.3.1v1
#--

# If policy matches basic conditions, special conditions,
# all exclusions are intentional, & none but acceptable MFA
# are allowed, save the policy name
PhishingResistantMFAPolicies contains CAPolicy.DisplayName if {
    some CAPolicy in input.conditional_access_policies

    "All" in CAPolicy.Conditions.Users.IncludeUsers
    "All" in CAPolicy.Conditions.Applications.IncludeApplications
    CAPolicy.State == "enabled"
    count(CAPolicy.Conditions.Applications.ExcludeApplications) == 0

    GroupExclusionsFullyExempt(CAPolicy, "MS.AAD.3.1v1") == true
    UserExclusionsFullyExempt(CAPolicy, "MS.AAD.3.1v1") == true

    IsPhishingResistantMFA(CAPolicy) == true
}

# Pass if at least 1 policy meets all conditions
tests contains {
    "PolicyId": "MS.AAD.3.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-MgBetaIdentityConditionalAccessPolicy"],
    "ActualValue": PhishingResistantMFAPolicies,
    "ReportDetails": concat(". ", [ReportFullDetailsArray(PhishingResistantMFAPolicies, DescriptionString), CAPLINK]),
    "RequirementMet": Status
} if {
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    Status := count(PhishingResistantMFAPolicies) > 0
}
#--

#
# MS.AAD.3.2v1
#--

# Save all policy names if PhishingResistantMFAPolicies exist
AllMFA := NonSpecificMFAPolicies | PhishingResistantMFAPolicies

# If policy matches basic conditions, special conditions,
# & all exclusions are intentional, save the policy name
NonSpecificMFAPolicies contains CAPolicy.DisplayName if {
    some CAPolicy in input.conditional_access_policies

    # Match all simple conditions
    PolicyConditionsMatch(CAPolicy)
    "mfa" in CAPolicy.GrantControls.BuiltInControls

    # Only match policies with user and group exclusions if all exempted
    UserExclusionsFullyExempt(CAPolicy, "MS.AAD.3.2v1") == true
    GroupExclusionsFullyExempt(CAPolicy, "MS.AAD.3.2v1") == true
}

# Pass if at least 1 policy meets all conditions
tests contains {
    "PolicyId": "MS.AAD.3.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-MgBetaIdentityConditionalAccessPolicy"],
    "ActualValue": AllMFA,
    "ReportDetails": concat(". ", [ReportFullDetailsArray(AllMFA, DescriptionString), CAPLINK]),
    "RequirementMet": Status
} if {
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    Status := count(AllMFA) > 0
}
#--

#
# MS.AAD.3.3v1
#--

# Returns the MS Authenticator configuration settings
MSAuth := auth_setting if {
    some auth_method in input.authentication_method
    some auth_setting in auth_method.authentication_method_feature_settings

    auth_setting.Id == "MicrosoftAuthenticator"
}

# Returns true if MS Authenticator is enabled, false if it is not
default MSAuthEnabled := false
MSAuthEnabled := true if {
    MSAuth.State == "enabled"
}

# Returns true if MS Authenticator is configured per the baseline, false if it is not
default MSAuthProperlyConfigured := false
MSAuthProperlyConfigured := true if {
    MSAuth.State == "enabled"

    # Make sure that MS Auth shows the app name and geographic location
    Settings := MSAuth.AdditionalProperties.featureSettings
    Settings.displayAppInformationRequiredState.state == "enabled"
    Settings.displayLocationInformationRequiredState.state == "enabled"

    # Make sure that the configuration applies to all users
    some target in MSAuth.AdditionalProperties.includeTargets
    target.id == "all_users"
}

default AAD_3_3_Not_Applicable := false
# Returns true no matter what if phishing-resistant MFA is being enforced
AAD_3_3_Not_Applicable := true if {
    count(PhishingResistantMFAPolicies) > 0
}

# Returns true if phishing-resistant MFA is not being enforced but MS Auth is disabled
AAD_3_3_Not_Applicable := true if {
    count(PhishingResistantMFAPolicies) == 0
    MSAuthEnabled == false
}

# First test is for N/A case
tests contains {
    "PolicyId": PolicyId,
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": ["Get-MgBetaPolicyAuthenticationMethodPolicy"],
    "ActualValue": [],
    "ReportDetails": CheckedSkippedDetails(PolicyId, Reason),
    "RequirementMet": false
} if {
    PolicyId := "MS.AAD.3.3v1"
    # regal ignore:line-length
    Reason := "This policy is only applicable if phishing-resistant MFA is not enforced and MS Authenticator is enabled. See %v for more info"
    AAD_3_3_Not_Applicable == true
}

# If policy is not N/A then we check that the configuration matches the baseline
tests contains {
    "PolicyId": "MS.AAD.3.3v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-MgBetaPolicyAuthenticationMethodPolicy"],
    "ActualValue": MSAuth,
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    AAD_3_3_Not_Applicable == false

    Status := MSAuthProperlyConfigured == true
}

#
# MS.AAD.3.4v1
#--

# Returns the auth policy migration state object
AuthenticationPolicyMigrationState := PolicyMigrationState if {
    some Setting in input.authentication_method
    PolicyMigrationState := Setting.authentication_method_policy.PolicyMigrationState
}

# Returns true if the tenant has completed their authpolicy migration
default AuthenticationPolicyMigrationIsComplete := false
AuthenticationPolicyMigrationIsComplete if AuthenticationPolicyMigrationState == "migrationComplete"

tests contains {
    "PolicyId": "MS.AAD.3.4v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-MgBetaPolicyAuthenticationMethodPolicy"],
    "ActualValue": [AuthenticationPolicyMigrationState],
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    Status := AuthenticationPolicyMigrationIsComplete
}
#--

#
# MS.AAD.3.5v1
#--

# Returns all the config states for the methods Sms, Voice, Email
LowSecurityAuthMethods contains {
    "Id": Configuration.Id,
    "State": Configuration.State
} if {
    some Setting in input.authentication_method
    some Configuration in Setting.authentication_method_feature_settings
    Configuration.Id in ["Sms", "Voice", "Email"]
}

# Returns true only when all the low security auth methods are disabled per the policy
default LowSecurityAuthMethodsDisabled := false
LowSecurityAuthMethodsDisabled := true if {
    every Config in LowSecurityAuthMethods { Config.State == "disabled" }
}

# First test is for N/A case
tests contains {
    "PolicyId": PolicyId,
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": ["Get-MgBetaPolicyAuthenticationMethodPolicy"],
    "ActualValue": [],
    "ReportDetails": CheckedSkippedDetails("MS.AAD.3.4v1", Reason),
    "RequirementMet": false
} if {
    PolicyId := "MS.AAD.3.5v1"
    # regal ignore:line-length
    Reason := "This policy is only applicable if the tenant has their Manage Migration feature set to Migration Complete. See %v for more info"
    AuthenticationPolicyMigrationIsComplete != true
}

# If policy is not N/A then we check that the configuration matches the baseline
tests contains {
    "PolicyId": "MS.AAD.3.5v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-MgBetaPolicyAuthenticationMethodPolicy"],
    "ActualValue": [LowSecurityAuthMethods],
    "ReportDetails": ReportDetailsString(Status, ErrorMessage),
    "RequirementMet": Status
} if {
    ErrorMessage := "Sms, Voice, and Email authentication must be disabled."
    AuthenticationPolicyMigrationIsComplete == true
    Status := LowSecurityAuthMethodsDisabled
}
#--

#
# MS.AAD.3.6v1
#--

# First check if policy is enabled, then confirm that all
# privliged roles are included in policy & not excluded.
# If policy matches basic conditions, special conditions,
# & all exclusions are intentional, save the policy name
PhishingResistantMFAPrivilegedRoles contains CAPolicy.DisplayName if {
    some CAPolicy in input.conditional_access_policies

    CAPolicy.State == "enabled"
    PrivRolesSet := ConvertToSetWithKey(input.privileged_roles, "RoleTemplateId")

    # Filter: only include policies that meet all the requirements
    count(PrivRolesSet - ConvertToSet(CAPolicy.Conditions.Users.IncludeRoles)) == 0

    # Confirm excluded roles do not contain any of the privileged roles
    # (if it does, that means you are excluding it which leaves role unprotected)
    count(PrivRolesSet & ConvertToSet(CAPolicy.Conditions.Users.ExcludeRoles)) == 0

    # Basic & special conditions
    Contains(CAPolicy.Conditions.Applications.IncludeApplications, "All") == true
    IsEmptyContainer(CAPolicy.Conditions.Applications.ExcludeApplications) == true
    GroupExclusionsFullyExempt(CAPolicy, "MS.AAD.3.6v1") == true
    UserExclusionsFullyExempt(CAPolicy, "MS.AAD.3.6v1") == true

    # Policy has only acceptable MFA
    IsPhishingResistantMFA(CAPolicy) == true
}

# Pass if at least 1 policy meets all conditions
tests contains {
    "PolicyId": "MS.AAD.3.6v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-MgBetaIdentityConditionalAccessPolicy"],
    "ActualValue": PhishingResistantMFAPrivilegedRoles,
    "ReportDetails": concat(". ", [ReportFullDetailsArray(PhishingResistantMFAPrivilegedRoles, DescriptionString), CAPLINK]),
    "RequirementMet": Status
} if {
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    Status := count(PhishingResistantMFAPrivilegedRoles) > 0
}
#--

#
# MS.AAD.3.7v1
#--

# If policy matches basic conditions, & needed strings
# are in bult in controls, save the policy name
ManagedDeviceAuth contains CAPolicy.DisplayName if {
    some CAPolicy in input.conditional_access_policies

    PolicyConditionsMatch(CAPolicy) == true

    "compliantDevice" in CAPolicy.GrantControls.BuiltInControls
    "domainJoinedDevice" in CAPolicy.GrantControls.BuiltInControls
    count(CAPolicy.GrantControls.BuiltInControls) == 2
    CAPolicy.GrantControls.Operator == "OR"

    # Only match policies with user and group exclusions if all exempted
    UserExclusionsFullyExempt(CAPolicy, "MS.AAD.3.7v1") == true
    GroupExclusionsFullyExempt(CAPolicy, "MS.AAD.3.7v1") == true
}

# Pass if at least 1 policy meets all conditions
tests contains {
    "PolicyId": "MS.AAD.3.7v1",
    "Criticality": "Should",
    "Commandlet": ["Get-MgBetaIdentityConditionalAccessPolicy"],
    "ActualValue": ManagedDeviceAuth,
    "ReportDetails": concat(". ", [ReportFullDetailsArray(ManagedDeviceAuth, DescriptionString), CAPLINK]),
    "RequirementMet": Status
} if {
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    Status := count(ManagedDeviceAuth) > 0
}
#--

#
# MS.AAD.3.8v1
#--

# If policy matches basic conditions, & needed strings
# are in bult in controls, save the policy name
RequireManagedDeviceMFA contains CAPolicy.DisplayName if {
    some CAPolicy in input.conditional_access_policies

    Contains(CAPolicy.Conditions.Users.IncludeUsers, "All") == true
    Contains(CAPolicy.Conditions.Applications.IncludeUserActions, "urn:user:registersecurityinfo") == true
    CAPolicy.State == "enabled"

    Conditions := [
        "compliantDevice" in CAPolicy.GrantControls.BuiltInControls,
        "domainJoinedDevice" in CAPolicy.GrantControls.BuiltInControls,
    ]
    count(FilterArray(Conditions, true)) > 0

    # Only match policies with user and group exclusions if all exempted
    UserExclusionsFullyExempt(CAPolicy, "MS.AAD.3.8v1") == true
    GroupExclusionsFullyExempt(CAPolicy, "MS.AAD.3.8v1") == true
}

# Pass if at least 1 policy meets all conditions
tests contains {
    "PolicyId": "MS.AAD.3.8v1",
    "Criticality": "Should",
    "Commandlet": ["Get-MgBetaIdentityConditionalAccessPolicy"],
    "ActualValue": RequireManagedDeviceMFA,
    "ReportDetails": concat(". ", [ReportFullDetailsArray(RequireManagedDeviceMFA, DescriptionString), CAPLINK]),
    "RequirementMet": Status
} if {
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    Status := count(RequireManagedDeviceMFA) > 0
}
#--

############
# MS.AAD.4 #
############

#
# MS.AAD.4.1v1
#--

# At this time we are unable to test for log collection until we integrate Azure Powershell capabilities
tests contains {
    "PolicyId": "MS.AAD.4.1v1",
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.AAD.4.1v1"),
    "RequirementMet": false
}
#--

############
# MS.AAD.5 #
############

#
# MS.AAD.5.1v1
#--

# If allowed to create apps, save the policy id
AuthPoliciesAppBad contains Policy.Id if {
    some Policy in input.authorization_policies
    Policy.DefaultUserRolePermissions.AllowedToCreateApps == true
}

# Get all policy ids
AllAuthPoliciesAllowedCreate contains {
    "DefaultUser_AllowedToCreateApps": Policy.DefaultUserRolePermissions.AllowedToCreateApps,
    "PolicyId": Policy.Id
} if {
    some Policy in input.authorization_policies
}

# If there is a policy that allows user to create apps, fail
tests contains {
    "PolicyId": "MS.AAD.5.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-MgBetaPolicyAuthorizationPolicy"],
    "ActualValue": {"all_allowed_create_values": AllAuthPoliciesAllowedCreate},
    "ReportDetails": ReportFullDetailsArray(BadPolicies, DescriptionString),
    "RequirementMet": Status
} if {
    BadPolicies := AuthPoliciesAppBad
    Status := count(BadPolicies) == 0
    DescriptionString := "authorization policies found that allow non-admin users to register third-party applications"
}
#--

#
# MS.AAD.5.2v1
#--

# Return the Id if non-compliant user consent policies
BadDefaultGrantPolicies contains Policy.Id if {
    some Policy in input.authorization_policies
    "ManagePermissionGrantsForSelf.microsoft-user-default-legacy" in Policy.PermissionGrantPolicyIdsAssignedToDefaultUserRole
}

BadDefaultGrantPolicies contains Policy.Id if {
    some Policy in input.authorization_policies
    "ManagePermissionGrantsForSelf.microsoft-user-default-low" in Policy.PermissionGrantPolicyIdsAssignedToDefaultUserRole
}

# Return all policy Ids
AllDefaultGrantPolicies contains {
    "DefaultUser_DefaultGrantPolicy": Policy.PermissionGrantPolicyIdsAssignedToDefaultUserRole,
    "PolicyId": Policy.Id
} if {
    some Policy in input.authorization_policies
}

# If there is a policy that allows user to consent to third party apps, fail
tests contains {
    "PolicyId": "MS.AAD.5.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-MgBetaPolicyAuthorizationPolicy"],
    "ActualValue": {"all_grant_policy_values": AllDefaultGrantPolicies},
    "ReportDetails": ReportFullDetailsArray(BadPolicies, DescriptionStr),
    "RequirementMet": Status
} if {
    BadPolicies := BadDefaultGrantPolicies
    Status := count(BadPolicies) == 0
    DescriptionStr := "authorization policies found that allow non-admin users to consent to third-party applications"
}
#--

#
# MS.AAD.5.3v1
#--

# For specific setting, save the value & group.
AllAdminConsentSettings contains {
    "SettingsGroup": SettingGroup.DisplayName,
    "Name": Setting.Name,
    "Value": Setting.Value
} if {
    some SettingGroup in input.directory_settings
    some Setting in SettingGroup.Values
    Setting.Name == "EnableAdminConsentRequests"
}

# Save all settings that have a value of false
GoodAdminConsentSettings contains {
    "SettingsGroup": Setting.SettingsGroup,
    "Name": Setting.Name,
    "Value": Setting.Value
} if {
    some Setting in AllAdminConsentSettings
    lower(Setting.Value) == "true"
}

# Save all settings that have a value of true
BadAdminConsentSettings contains {
    "SettingsGroup": Setting.SettingsGroup,
    "Name": Setting.Name,
    "Value": Setting.Value
} if {
    some Setting in AllAdminConsentSettings
    lower(Setting.Value) == "false"
}

# If there is a policy that is not enabled, fail
tests contains {
    "PolicyId": "MS.AAD.5.3v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-MgBetaDirectorySetting"],
    "ActualValue": {"all_admin_consent_policies": AllAdminConsentSettings},
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    Conditions := [
        count(BadAdminConsentSettings) == 0,
        count(GoodAdminConsentSettings) > 0
    ]
    Status := count(FilterArray(Conditions, false)) == 0
}
#--

#
# MS.AAD.5.4v1
#--

# Microsoft has removed this configuration option
# We are setting this policy to not-implemented and will likely remove it 
# from the baseline in the next version.

tests contains {
    "PolicyId": "MS.AAD.5.4v1",
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": ["Get-MgBetaDirectorySetting"],
    "ActualValue": [],
    "ReportDetails": NotCheckedDeprecation,
    "RequirementMet": false
}
#--


############
# MS.AAD.6 #
############

#
# MS.AAD.6.1v1
#--

# User passwords are set to not expire if they equal INT_MAX
UserPasswordsSetToNotExpire contains Domain.Id if {
    some Domain in input.domain_settings
    Domain.PasswordValidityPeriodInDays == INT_MAX
    Domain.IsVerified == true

    # Ignore federated domains
    Domain.AuthenticationType == "Managed"
}

UserPasswordsSetToExpire contains Domain.Id if {
    some Domain in input.domain_settings
    Domain.PasswordValidityPeriodInDays != INT_MAX
    Domain.IsVerified == true

    # Ignore federated domains
    Domain.AuthenticationType == "Managed"
}

FederatedDomains contains Domain.Id if {
    some Domain in input.domain_settings
    Domain.IsVerified == true
    Domain.AuthenticationType == "Federated"
}

tests contains {
    "PolicyId": "MS.AAD.6.1v1",
    "Criticality": "Shall",
    "Commandlet": [ "Get-MgBetaDomain" ],
    # Track invalid/valid/federated domains for use in TestResults.json
    "ActualValue": { 
        "invalid_domains": UserPasswordsSetToExpire, 
        "valid_domains": UserPasswordsSetToNotExpire,
        "federated_domains": FederatedDomains
    },
    "ReportDetails": DomainReportDetails(Status, Metadata),
    "RequirementMet": Status
} if {
    # For the rule to pass:
    # User passwords for all domains shall not expire
    # Then check if at least 1 or more domains with user passwords set to expire exist
    Conditions := [
        count(UserPasswordsSetToExpire) == 0, 
        count(UserPasswordsSetToNotExpire) > 0
    ]
    Status := count(FilterArray(Conditions, true)) == 2
    Metadata := {
        "UserPasswordsSetToExpire": UserPasswordsSetToExpire,
        "FederatedDomains": FederatedDomains
    }
}
#--


############
# MS.AAD.7 #
############

#
# MS.AAD.7.1v1
#--

# Save all users that have the Global Admin role
GlobalAdmins contains User.DisplayName if {
    some User in input.privileged_users
    "Global Administrator" in User.roles
}

# Set conditions under which this policy will pass
default IsGlobalAdminCountGood := false
IsGlobalAdminCountGood := true if {
    count(GlobalAdmins) <= 8
    count(GlobalAdmins) >= 2
}

# Pass if there are at least 2, but no more than 8
# users with Global Admin role.
tests contains {
    "PolicyId": "MS.AAD.7.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-MgBetaSubscribedSku", "Get-PrivilegedUser"],
    "ActualValue": GlobalAdmins,
    "ReportDetails": ReportFullDetailsArray(GlobalAdmins, DescriptionString),
    "RequirementMet": Status
} if {
    DescriptionString := "global admin(s) found"
    Status := IsGlobalAdminCountGood
}
#--

# MS.AAD.7.2v1
#--

# Save all users that don't have Global Admin role
NotGlobalAdmins contains User.DisplayName if {
    some User in input.privileged_users
    not "Global Administrator" in User.roles
}

default GetScoreDescription := "All privileged users are Global Admin"
GetScoreDescription := concat("", ["Least Privilege Score = ", Score, " (should be 1 or less)"]) if {
    count(NotGlobalAdmins) > 0
    RawRatio := sprintf("%v", [count(GlobalAdmins)/count(NotGlobalAdmins)])
    CutOff := min([4, count(RawRatio)])
    Score := substring(RawRatio, 0, CutOff)
}

# calculate least privilege score as ratio of priv users with global admin role to priv users without global admin role
LeastPrivilegeScore := "Policy MS.AAD.7.1 failed so score not computed" if {
    IsGlobalAdminCountGood == false
} else := GetScoreDescription

# Pass if 7.1 passed and Least Privilege Score < 1, fail if 7.1 failed or Least Privilege score is >= 1
tests contains {
    "PolicyId": "MS.AAD.7.2v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgBetaSubscribedSku", "Get-PrivilegedUser"],
    "ActualValue" : GlobalAdmins,
    "ReportDetails" : concat(": ", [ReportDetailsBoolean(Status), LeastPrivilegeScore]),
    "RequirementMet" : Status
} if {
    Conditions := [
        IsGlobalAdminCountGood,
        count(GlobalAdmins) <= count(NotGlobalAdmins)
    ]
    Status := count(FilterArray(Conditions, false)) == 0
}
#--

#
# MS.AAD.7.3v1
#--

# Save privileged users that do not have cloud
# only accounts
FederatedAdmins contains User.DisplayName if {
    some User in input.privileged_users
    not is_null(User.OnPremisesImmutableId)
}

# Pass if all privileged users have cloud only accounts
tests contains {
    "PolicyId": "MS.AAD.7.3v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-MgBetaSubscribedSku", "Get-PrivilegedUser"],
    "ActualValue": AdminNames,
    "ReportDetails": ReportFullDetailsArray(FederatedAdmins, DescriptionString),
    "RequirementMet": Status
} if {
    DescriptionString := "admin(s) that are not cloud-only found"
    Status := count(FederatedAdmins) == 0
    AdminNames := concat(", ", FederatedAdmins)
}
#--

#
# MS.AAD.7.4v1
#--
default PrivilegedRoleExclusions(_, _) := false

# Get all privileged roles that have permenant assignment.
# Get all users that are allowed permenant assignment from config
# for users & groups. If there are users with permenant assignment
# return true if all users + groups are in the config.
PrivilegedRoleExclusions(PrivilegedRole, PolicyID) := true if {
    PrivilegedRoleAssignedPrincipals := {x.principalId | some x in PrivilegedRole.Assignments; x.endDateTime == null}

    AllowedPrivilegedRoleUsers := {y | some y in input.scuba_config.Aad[PolicyID].RoleExclusions.Users; y != null}
    AllowedPrivilegedRoleGroups := {y | some y in input.scuba_config.Aad[PolicyID].RoleExclusions.Groups; y != null}

    count(PrivilegedRoleAssignedPrincipals) > 0
    count(PrivilegedRoleAssignedPrincipals - (AllowedPrivilegedRoleUsers | AllowedPrivilegedRoleGroups)) != 0
}

# if no users with permenant assignment & config empty, return true
PrivilegedRoleExclusions(PrivilegedRole, PolicyID) := true if {
    count({x.principalId | some x in PrivilegedRole.Assignments; x.endDateTime == null}) > 0
    count({y | some y in input.scuba_config.Aad[PolicyID].RoleExclusions.Users; y != null}) == 0
    count({y | some y in input.scuba_config.Aad[PolicyID].RoleExclusions.Groups; y != null}) == 0
}

# Save role name if there are rouge privileged roles
PrivilegedRolesWithoutExpirationPeriod contains Role.DisplayName if {
    some Role in input.privileged_roles
    PrivilegedRoleExclusions(Role, "MS.AAD.7.4v1") == true
}

# If you have the correct license & no rouge roles with permenant assignment, pass
tests contains {
    "PolicyId": "MS.AAD.7.4v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-MgBetaSubscribedSku", "Get-PrivilegedRole"],
    "ActualValue": PrivilegedRolesWithoutExpirationPeriod,
    "ReportDetails": ReportDetailsArrayLicenseWarning(PrivilegedRolesWithoutExpirationPeriod, DescriptionString),
    "RequirementMet": Status
} if {
    DescriptionString := "role(s) that contain users with permanent active assignment"
    Conditions := [
        count(Aad2P2Licenses) > 0,
        count(PrivilegedRolesWithoutExpirationPeriod) == 0
    ]
    Status := count(FilterArray(Conditions, false)) == 0
}

#
# MS.AAD.7.5v1
#--

# Get all privileged roles that do not have a start date
RolesAssignedOutsidePim contains Role.DisplayName if {
    some Role in input.privileged_roles
    NoStartAssignments := {is_null(X.startDateTime) | some X in Role.Assignments}

    count(FilterArray(NoStartAssignments, true)) > 0
}

# If you have the correct license & no roles without start date, pass
tests contains {
    "PolicyId": "MS.AAD.7.5v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-MgBetaSubscribedSku", "Get-PrivilegedRole"],
    "ActualValue": RolesAssignedOutsidePim,
    "ReportDetails": ReportDetailsArrayLicenseWarning(RolesAssignedOutsidePim, DescriptionString),
    "RequirementMet": Status
} if {
    DescriptionString := "role(s) assigned to users outside of PIM"
    Conditions := [
        count(Aad2P2Licenses) > 0,
        count(RolesAssignedOutsidePim) == 0
    ]
    Status := count(FilterArray(Conditions, false)) == 0
}
#--

#
# MS.AAD.7.6v1
#--

# Save role name if id is a specific string and approval is
# not required.
RolesWithoutApprovalRequired contains Offender if {
    some Role in input.privileged_roles
    some Rule in Role.Rules

    Offender := sprintf("%v(%v)", [Rule.RuleSource, Rule.RuleSourceType])
    Role.DisplayName == "Global Administrator"
    # Filter: only include policies that meet all the requirements
    Rule.Id == "Approval_EndUser_Assignment"
    Rule.AdditionalProperties.setting.isApprovalRequired == false
}

# If you have the correct license & Global Administor
# is not in RolesWithoutApprovalRequired, pass
tests contains {
    "PolicyId": "MS.AAD.7.6v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-MgBetaSubscribedSku", "Get-PrivilegedRole"],
    "ActualValue": RolesWithoutApprovalRequired,
    "ReportDetails": ReportDetailsArrayLicenseWarning(RolesWithoutApprovalRequired, DescriptionString),
    "RequirementMet": Status
} if {
    DescriptionString := "role(s) or group(s) allowing activation without approval found"
    Conditions := [
        count(Aad2P2Licenses) > 0,
        count(RolesWithoutApprovalRequired) == 0
    ]
    Status := count(FilterArray(Conditions, false)) == 0
}
#--

#
# MS.AAD.7.7v1
#--

# Save role name if id is a specific string and no
# notification recipients.
RolesWithoutActiveAssignmentAlerts contains Offender if {
    some Role in input.privileged_roles
    some Rule in Role.Rules

    Offender := sprintf("%v(%v)", [Rule.RuleSource, Rule.RuleSourceType])
    # Filter: only include policies that meet all the requirements
    Rule.Id == "Notification_Admin_Admin_Assignment"
    count(Rule.AdditionalProperties.notificationRecipients) == 0
}

# Save role name if id is a specific string and no
# notification recipients.
RolesWithoutEligibleAssignmentAlerts contains Offender if {
    some Role in input.privileged_roles
    some Rule in Role.Rules

    Offender := sprintf("%v(%v)", [Rule.RuleSource, Rule.RuleSourceType])
    # Filter: only include policies that meet all the requirements
    Rule.Id == "Notification_Admin_Admin_Eligibility"
    count(Rule.AdditionalProperties.notificationRecipients) == 0
}

# If you have the correct license & all roles have assignment
# alerts, pass
tests contains {
    "PolicyId": "MS.AAD.7.7v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-MgBetaSubscribedSku", "Get-PrivilegedRole"],
    "ActualValue": RolesWithoutAssignmentAlerts,
    "ReportDetails": ReportDetailsArrayLicenseWarning(RolesWithoutAssignmentAlerts, DescriptionString),
    "RequirementMet": Status
} if {
    DescriptionString := "role(s) or group(s) without notification e-mail configured for role assignments found"
    RolesWithoutAssignmentAlerts := RolesWithoutActiveAssignmentAlerts | RolesWithoutEligibleAssignmentAlerts
    Conditions := [
        count(Aad2P2Licenses) > 0,
        count(RolesWithoutAssignmentAlerts) == 0
    ]
    Status := count(FilterArray(Conditions, false)) == 0
}
#--

#
# MS.AAD.7.8v1
#--

# Save role name if id is a specific string, notification
# type is a specific string, & no notification recipients.
GlobalAdminsWithoutActivationAlert contains Offender if {
    some Role in input.privileged_roles
    some Rule in Role.Rules

    Offender := sprintf("%v(%v)", [Rule.RuleSource, Rule.RuleSourceType])
    Role.DisplayName == "Global Administrator"
    # Filter: only include policies that meet all the requirements
    Rule.Id == "Notification_Admin_EndUser_Assignment"
    Rule.AdditionalProperties.notificationType == "Email"
    count(Rule.AdditionalProperties.notificationRecipients) == 0
}

# If you have the correct license & Global Admin
# has activation alert, pass
tests contains {
    "PolicyId": "MS.AAD.7.8v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-MgBetaSubscribedSku", "Get-PrivilegedRole"],
    "ActualValue": GlobalAdminsWithoutActivationAlert,
    "ReportDetails": ReportDetailsArrayLicenseWarning(GlobalAdminsWithoutActivationAlert, DescriptionString),
    "RequirementMet": Status
} if {
    DescriptionString := "role(s) or group(s) without notification e-mail configured for Global Administrator activations found"
    Conditions := [
        count(Aad2P2Licenses) > 0,
        count(GlobalAdminsWithoutActivationAlert) == 0
    ]
    Status := count(FilterArray(Conditions, false)) == 0
}
#--

#
# MS.AAD.7.9v1
#--

OtherAdminsWithoutActivationAlert contains Offender if {
    some Role in input.privileged_roles
    some Rule in Role.Rules

    Offender := sprintf("%v(%v)", [Rule.RuleSource, Rule.RuleSourceType])
    not Role.DisplayName == "Global Administrator"
    # Filter: only include policies that meet all the requirements
    Rule.Id == "Notification_Admin_EndUser_Assignment"
    Rule.AdditionalProperties.notificationType == "Email"
    count(Rule.AdditionalProperties.notificationRecipients) == 0
}

# If there are no roles without activation alert &
# correct license, pass
tests contains {
    "PolicyId": "MS.AAD.7.9v1",
    "Criticality": "Should",
    "Commandlet": ["Get-MgBetaSubscribedSku", "Get-PrivilegedRole"],
    "ActualValue": OtherAdminsWithoutActivationAlert,
    "ReportDetails": ReportDetailsArrayLicenseWarning(OtherAdminsWithoutActivationAlert, DescriptionString),
    "RequirementMet": Status
} if {
    DescriptionString := "role(s) or group(s) without notification e-mail configured for role activations found"
    Conditions := [
        count(Aad2P2Licenses) > 0,
        count(OtherAdminsWithoutActivationAlert) == 0
    ]
    Status := count(FilterArray(Conditions, false)) == 0
}
#--

############
# MS.AAD.8 #
############

#
# MS.AAD.8.1v1
#--

# must hardcode the ID. See
# https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/users-restrict-guest-permissions
# pattern matching on function args: https://docs.styra.com/regal/rules/idiomatic/equals-pattern-matching
# return specified string based on id passed to method.
LevelAsString("2af84b1e-32c8-42b7-82bc-daa82404023b") := "Restricted access"

LevelAsString("10dae51f-b6af-4016-8d66-8c2a99b929b3") := "Limited access"

LevelAsString("a0b1b346-4d3e-4e8b-98f8-753987be4970") := "Same as member users"

LevelAsString(Id) := "Unknown" if not Id in [
    RESTRICTEDACCESS,
    LIMITEDACCESS,
    MEMBERUSER
]

# save the policy ids that do not have the specified
# guest role ids
AuthPoliciesBadRoleId contains Policy.Id if {
    some Policy in input.authorization_policies
    not Policy.GuestUserRoleId in [
        LIMITEDACCESS,
        RESTRICTEDACCESS
    ]
}

# Get role ids & associated levels for all policies
AllAuthPoliciesRoleIds contains {
    "GuestUserRoleIdString": Level,
    "GuestUserRoleId": Policy.GuestUserRoleId,
    "Id": Policy.Id
} if {
    some Policy in input.authorization_policies
    Level := LevelAsString(Policy.GuestUserRoleId)
}

# Create string for all policies with role level
RoleIdByPolicy contains concat("", ["\"", Level, "\"", " (", Policy.Id, ")"]) if {
    some Policy in input.authorization_policies
    Level := LevelAsString(Policy.GuestUserRoleId)
}

# If no roles with bad roles, pass
tests contains {
    "PolicyId": "MS.AAD.8.1v1",
    "Criticality": "Should",
    "Commandlet": ["Get-MgBetaPolicyAuthorizationPolicy"],
    "ActualValue": {"all_roleid_values": AllAuthPoliciesRoleIds},
    "ReportDetails": ReportDetail,
    "RequirementMet": Status
} if {
    Status := count(AuthPoliciesBadRoleId) == 0
    ReportDetail := concat("", ["Permission level set to ", concat(", ", RoleIdByPolicy)])
}
#--

#
# MS.AAD.8.2v1
#--

# Get all policies that allow invites from guests & admins
AuthPoliciesBadAllowInvites contains Policy.Id if {
    some Policy in input.authorization_policies
    Policy.AllowInvitesFrom != "adminsAndGuestInviters"
}

# Get invite setting for all policies
AllAuthPoliciesAllowInvites contains {
    "AllowInvitesFromValue": Policy.AllowInvitesFrom,
    "PolicyId": Policy.Id
} if {
    some Policy in input.authorization_policies
}

# Create string for all policies with invite setting
AllowInvitesByPolicy contains concat("", ["\"", Policy.AllowInvitesFrom, "\"", " (", Policy.Id, ")"]) if {
    some Policy in input.authorization_policies
}

# If no roles with bad invite setting, pass
tests contains {
    "PolicyId": "MS.AAD.8.2v1",
    "Criticality": "Should",
    "Commandlet": ["Get-MgBetaPolicyAuthorizationPolicy"],
    "ActualValue": {"all_allow_invite_values": AllAuthPoliciesAllowInvites},
    "ReportDetails": ReportDetail,
    "RequirementMet": Status
} if {
    Status := count(AuthPoliciesBadAllowInvites) == 0
    ReportDetail := concat("", ["Permission level set to ", concat(", ", AllowInvitesByPolicy)])
}
#--

#
# MS.AAD.8.3v1
#--

# At this time we are unable to test for X because of Y
tests contains {
    "PolicyId": "MS.AAD.8.3v1",
    "Criticality": "Should/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.AAD.8.3v1"),
    "RequirementMet": false
}
#--
