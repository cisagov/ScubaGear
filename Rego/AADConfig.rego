package aad
import future.keywords
import data.report.utils.NotCheckedDetails
import data.report.utils.Format
import data.report.utils.ReportDetailsBoolean
import data.policy.utils.IsEmptyContainer
import data.policy.utils.Contains
import data.policy.utils.Count

#############################################################################
# The report formatting functions below are generic and used throughout AAD #
#############################################################################

Description(String1, String2, String3) =  trim(concat(" ", [String1, String2, String3]), " ")

ReportDetailsArray(Array, String) = Description(Format(Array), String, "")

# Set to the maximum number of array items to be
# printed in the report details section
ReportArrayMaxCount := 20

ReportFullDetailsArray(Array, String) = Details {
    count(Array) == 0
    Details := ReportDetailsArray(Array, String)
}

ReportFullDetailsArray(Array, String) = Details {
    count(Array) > 0
    count(Array) <= ReportArrayMaxCount
    Details := Description(Format(Array), concat(":<br/>", [String, concat(", ", Array)]), "")
}

ReportFullDetailsArray(Array, String) = Details {
    count(Array) > ReportArrayMaxCount
    List := [ x | x := Array[_] ]

    TruncationWarning := "...<br/>Note: The list of matching items has been truncated.  Full details are available in the JSON results."
    TruncatedList := concat(", ", array.slice(List, 0, ReportArrayMaxCount))
    Details := Description(Format(Array), concat(":<br/>", [String, TruncatedList]), TruncationWarning)
}

CapLink := "<a href='#caps'>View all CA policies</a>."

##############################################################################################################
# The report formatting functions below are for policies that check the required Azure AD Premium P2 license #
##############################################################################################################

Aad2P2Licenses[ServicePlan.ServicePlanId] {
    ServicePlan = input.service_plans[_]
    ServicePlan.ServicePlanName == "AAD_PREMIUM_P2"
}

P2WarningString := "**NOTE: Your tenant does not have an Azure AD Premium P2 license, which is required for this feature**"

ReportDetailsArrayLicenseWarningCap(Array, String) = Description if {
  count(Aad2P2Licenses) > 0
  Description :=  concat(". ", [ReportFullDetailsArray(Array, String), CapLink])
}

ReportDetailsArrayLicenseWarningCap(_, _) = Description if {
  count(Aad2P2Licenses) == 0
  Description := P2WarningString
}

ReportDetailsArrayLicenseWarning(Array, String) = Description if {
  count(Aad2P2Licenses) > 0
  Description :=  ReportFullDetailsArray(Array, String)
}

ReportDetailsArrayLicenseWarning(_, _) = Description if {
  count(Aad2P2Licenses) == 0
  Description := P2WarningString
}

ReportDetailsBooleanLicenseWarning(Status) = Description if {
    count(Aad2P2Licenses) > 0
    Status == true
    Description := "Requirement met"
}

ReportDetailsBooleanLicenseWarning(Status) = Description if {
    count(Aad2P2Licenses) > 0
    Status == false
    Description := "Requirement not met"
}

ReportDetailsBooleanLicenseWarning(_) = Description if {
    count(Aad2P2Licenses) == 0
    Description := P2WarningString
}

##########################################
# User/Group Exclusion support functions #
##########################################

default UserExclusionsFullyExempt(_, _) := false
UserExclusionsFullyExempt(Policy, PolicyID) := true if {
    # Returns true when all user exclusions present in the conditional
    # access policy are exempted in matching config variable for the
    # baseline policy item.  Undefined if no exclusions AND no exemptions.
    ExemptedUsers := input.scuba_config.Aad[PolicyID].CapExclusions.Users
    ExcludedUsers := { x | x := Policy.Conditions.Users.ExcludeUsers[_] }
    AllowedExcludedUsers := { y | y := ExemptedUsers[_] }
    count(ExcludedUsers - AllowedExcludedUsers) == 0
}

UserExclusionsFullyExempt(Policy, PolicyID) := true if {
    # Returns true when user inputs are not defined or user exclusion lists are empty
    count({ x | x := Policy.Conditions.Users.ExcludeUsers[_] }) == 0
    count({ y | y := input.scuba_config.Aad[PolicyID].CapExclusions.Users }) == 0
}

default GroupExclusionsFullyExempt(_, _) := false
GroupExclusionsFullyExempt(Policy, PolicyID) := true if {
    # Returns true when all group exclusions present in the conditional
    # access policy are exempted in matching config variable for the
    # baseline policy item.  Undefined if no exclusions AND no exemptions.
    ExemptedGroups := input.scuba_config.Aad[PolicyID].CapExclusions.Groups
    ExcludedGroups := { x | x := Policy.Conditions.Users.ExcludeGroups[_] }
    AllowedExcludedGroups := { y | y:= ExemptedGroups[_] }
    count(ExcludedGroups - AllowedExcludedGroups) == 0
}

GroupExclusionsFullyExempt(Policy, PolicyID) := true if {
    # Returns true when user inputs are not defined or group exclusion lists are empty
    count({ x | x := Policy.Conditions.Users.ExcludeGroups[_] }) == 0
    count({ y | y := input.scuba_config.Aad[PolicyID].CapExclusions.Groups }) == 0
}

############
# MS.AAD.1 #
############

#
# MS.AAD.1.1v1
#--
default LegacyAuthenticationConditionsMatch(_) := false
LegacyAuthenticationConditionsMatch(Policy) := true if {
    "All" in Policy.Conditions.Users.IncludeUsers
    "All" in Policy.Conditions.Applications.IncludeApplications
    "other" in Policy.Conditions.ClientAppTypes
    "exchangeActiveSync" in Policy.Conditions.ClientAppTypes
    "block" in Policy.GrantControls.BuiltInControls
    count(Policy.Conditions.Users.ExcludeRoles) == 0
    Policy.State == "enabled"
}

LegacyAuthentication[Cap.DisplayName] {
    Cap := input.conditional_access_policies[_]

    # Match all simple conditions
    LegacyAuthenticationConditionsMatch(Cap)

    # Only match policies with user and group exclusions if all exempted
    UserExclusionsFullyExempt(Cap, "MS.AAD.1.1v1") == true
    GroupExclusionsFullyExempt(Cap, "MS.AAD.1.1v1") == true
}

tests[{
    "PolicyId" : "MS.AAD.1.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgIdentityConditionalAccessPolicy"],
    "ActualValue" : LegacyAuthentication,
    "ReportDetails" : concat(". ", [ReportFullDetailsArray(LegacyAuthentication, DescriptionString), CapLink]),
    "RequirementMet" : Status
}] {
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
default BlockHighRiskConditionsMatch(_) := false
BlockHighRiskConditionsMatch(Policy) := true if {
    "All" in Policy.Conditions.Users.IncludeUsers
    "All" in Policy.Conditions.Applications.IncludeApplications
    "high" in Policy.Conditions.UserRiskLevels
    "block" in Policy.GrantControls.BuiltInControls
    Policy.State == "enabled"
    count(Policy.Conditions.Users.ExcludeRoles) == 0
}

BlockHighRisk[Cap.DisplayName] {
    Cap := input.conditional_access_policies[_]

    # Match all simple conditions
    BlockHighRiskConditionsMatch(Cap)

    # Only match policies with user and group exclusions if all exempted
    UserExclusionsFullyExempt(Cap, "MS.AAD.2.1v1") == true
    GroupExclusionsFullyExempt(Cap, "MS.AAD.2.1v1") == true
}

tests[{
    "PolicyId" : "MS.AAD.2.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgIdentityConditionalAccessPolicy"],
    "ActualValue" : BlockHighRisk,
    "ReportDetails" : ReportDetailsArrayLicenseWarningCap(BlockHighRisk, DescriptionString),
    "RequirementMet" : Status
}] {
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    Status := count(BlockHighRisk) > 0
}
#--

#
# MS.AAD.2.2v1
#--
# At this time we are unable to test for X because of Y
tests[{
    "PolicyId": PolicyId,
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.AAD.2.2v1"
    true
}
#--

#
# MS.AAD.2.3v1
#--
default SignInBlockedConditionsMatch(_) := false
SignInBlockedConditionsMatch(Policy) := true if {
    "All" in Policy.Conditions.Users.IncludeUsers
    "All" in Policy.Conditions.Applications.IncludeApplications
    "high" in Policy.Conditions.SignInRiskLevels
    "block" in Policy.GrantControls.BuiltInControls
    Policy.State == "enabled"
    count(Policy.Conditions.Users.ExcludeRoles) == 0
}

SignInBlocked[Cap.DisplayName] {
    Cap := input.conditional_access_policies[_]

    # Match all simple conditions
    SignInBlockedConditionsMatch(Cap)

    # Only match policies with user and group exclusions if all exempted
    UserExclusionsFullyExempt(Cap, "MS.AAD.2.3v1") == true
    GroupExclusionsFullyExempt(Cap, "MS.AAD.2.3v1") == true
}

tests[{
    "PolicyId": "MS.AAD.2.3v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgIdentityConditionalAccessPolicy"],
    "ActualValue" : SignInBlocked,
    "ReportDetails" : ReportDetailsArrayLicenseWarningCap(SignInBlocked, DescriptionString),
    "RequirementMet" : Status
}] {
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    Status := count(SignInBlocked) > 0
}
#--

############
# MS.AAD.3 #
############

#
# MS.AAD.3.1v1
#--

MS_AAD_3_1v1_CAP[Cap.DisplayName] {
    Cap := input.conditional_access_policies[_]

    Cap.State == "enabled"
    Contains(Cap.Conditions.Users.IncludeUsers, "All")
    IsEmptyContainer(Cap.Conditions.Applications.ExcludeApplications)
    Contains(Cap.Conditions.Applications.IncludeApplications, "All")
    GroupExclusionsFullyExempt(Cap, "MS.AAD.3.1v1") == true
    UserExclusionsFullyExempt(Cap, "MS.AAD.3.1v1") == true

    # Strength must be at least one of acceptable with no unacceptable strengths
    Strengths := { Strength | Strength := Cap.GrantControls.AuthenticationStrength.AllowedCombinations[_]}
    AcceptableMFA := {"windowsHelloForBusiness", "fido2", "x509CertificateMultiFactor"}
    MinusSet := Strengths - AcceptableMFA
    Count(MinusSet) == 0
    Count(Strengths) > 0
}

tests[{
    "PolicyId" : "MS.AAD.3.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgIdentityConditionalAccessPolicy"],
    "ActualValue" : MS_AAD_3_1v1_CAP,
    "ReportDetails" : concat(". ", [ReportFullDetailsArray(MS_AAD_3_1v1_CAP, DescriptionString), CapLink]),
    "RequirementMet" : Status
}] {
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    Status := count(MS_AAD_3_1v1_CAP) > 0
}
#--

#
# MS.AAD.3.2v1
#--
default AlternativeMFAConditionsMatch(_) := false
AlternativeMFAConditionsMatch(Policy) := true if {
    "All" in Policy.Conditions.Users.IncludeUsers
    "All" in Policy.Conditions.Applications.IncludeApplications
    "mfa" in Policy.GrantControls.BuiltInControls
    Policy.State == "enabled"
    count(Policy.Conditions.Users.ExcludeRoles) == 0
}

AlternativeMFA[Cap.DisplayName] {
    Cap := input.conditional_access_policies[_]

    # Match all simple conditions
    AlternativeMFAConditionsMatch(Cap)

    # Only match policies with user and group exclusions if all exempted
    UserExclusionsFullyExempt(Cap, "MS.AAD.3.2v1") == true
    GroupExclusionsFullyExempt(Cap, "MS.AAD.3.2v1") == true
}

tests[{
    "PolicyId" : "MS.AAD.3.2v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgIdentityConditionalAccessPolicy"],
    "ActualValue" : AlternativeMFA,
    "ReportDetails" : concat(". ", [ReportFullDetailsArray(AlternativeMFA, DescriptionString), CapLink]),
    "RequirementMet" : Status
}]{
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    Status := count(AlternativeMFA) > 0
}
#--

#
# MS.AAD.3.3v1
#--
# At this time we are unable to test for X because of NEW POLICY
tests[{
    "PolicyId": PolicyId,
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.AAD.3.3v1"
    true
}
#--

#
# MS.AAD.3.4v1
#--
# At this time we are unable to test for X because of NEW POLICY
tests[{
    "PolicyId": "MS.AAD.3.4v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgPolicyAuthenticationMethodPolicy"],
    "ActualValue" : [Policy.PolicyMigrationState],
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policy := input.authentication_method[_]
    Status := Policy.PolicyMigrationState == "migrationComplete"
}
#--

#
# MS.AAD.3.5v1
#--
# At this time we are unable to test for SMS/Voice settings due to lack of API to validate
# Awaiting API changes and feature updates from Microsoft for automated checking
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.AAD.3.5v1"
    true
}
#--

#
# MS.AAD.3.6v1
#--
PhishingResistantMFA[Cap.DisplayName] {
    Cap := input.conditional_access_policies[_]
    PrivRolesSet := { Role.RoleTemplateId | Role = input.privileged_roles[_] }
    CondIncludedRolesSet := { Y | Y = Cap.Conditions.Users.IncludeRoles[_] }
    MissingRoles := PrivRolesSet - CondIncludedRolesSet
    # Filter: only include policies that meet all the requirements
    count(MissingRoles) == 0
    CondExcludedRolesSet := { Y | Y = Cap.Conditions.Users.ExcludeRoles[_] }
    #make sure excluded roles do not contain any of the privileged roles (if it does, that means you are excluding it which is not what the policy says)
    MatchingExcludeRoles := PrivRolesSet & CondExcludedRolesSet
    #only succeeds if there is no intersection, i.e., excluded roles are none of the privileged roles
    count(MatchingExcludeRoles) == 0
    "All" in Cap.Conditions.Applications.IncludeApplications
    "mfa" in Cap.GrantControls.BuiltInControls
    Cap.State == "enabled"
}

tests[{
    "PolicyId" : "MS.AAD.3.6v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgSubscribedSku", "Get-PrivilegedRole", "Get-MgIdentityConditionalAccessPolicy"],
    "ActualValue" : PhishingResistantMFA,
    "ReportDetails" : concat(". ", [ReportFullDetailsArray(PhishingResistantMFA, DescriptionString), CapLink]),
    "RequirementMet" : Status
}] {
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    Status := count(PhishingResistantMFA) > 0
}
#--

#
# MS.AAD.3.7v1
#--
ManagedDeviceAuth[Cap.DisplayName] {
    Cap := input.conditional_access_policies[_]
    CompliantDevice := "compliantDevice" in Cap.GrantControls.BuiltInControls
    HybridJoin := "domainJoinedDevice" in Cap.GrantControls.BuiltInControls
    Conditions := [CompliantDevice, HybridJoin]
    # Filter: only include policies that meet all the requirements
    "All" in Cap.Conditions.Users.IncludeUsers
    "All" in Cap.Conditions.Applications.IncludeApplications
    count([Condition | Condition = Conditions[_]; Condition == true]) > 0
    Cap.State == "enabled"
}

tests[{
    "PolicyId" : "MS.AAD.3.7v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-MgIdentityConditionalAccessPolicy"],
    "ActualValue" : ManagedDeviceAuth,
    "ReportDetails" : concat(". ", [ReportFullDetailsArray(ManagedDeviceAuth, DescriptionString), CapLink]),
    "RequirementMet" : Status
}] {
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    Status := count(ManagedDeviceAuth) > 0
}
#--

#
# MS.AAD.3.8v1
#--
RequireManagedDeviceMFA[Cap.DisplayName] {
    Cap := input.conditional_access_policies[_]
    CompliantDevice := "compliantDevice" in Cap.GrantControls.BuiltInControls
    HybridJoin := "domainJoinedDevice" in Cap.GrantControls.BuiltInControls
    Conditions := [CompliantDevice, HybridJoin]
    "All" in Cap.Conditions.Users.IncludeUsers
    "urn:user:registersecurityinfo" in Cap.Conditions.Applications.IncludeUserActions
    count([Condition | Condition = Conditions[_]; Condition == true]) > 0
    Cap.State == "enabled"

    # Only match policies with user and group exclusions if all exempted
    UserExclusionsFullyExempt(Cap, "MS.AAD.3.8v1") == true
    GroupExclusionsFullyExempt(Cap, "MS.AAD.3.8v1") == true
}

tests[{
    "PolicyId": "MS.AAD.3.8v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-MgIdentityConditionalAccessPolicy"],
    "ActualValue" : RequireManagedDeviceMFA,
    "ReportDetails" : concat(". ", [ReportFullDetailsArray(RequireManagedDeviceMFA, DescriptionString), CapLink]),
    "RequirementMet" : Status
}] {
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
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.AAD.4.1v1"
    true
}
#--

############
# MS.AAD.5 #
############

#
# MS.AAD.5.1v1
#--
AuthPoliciesBad_2_6[Policy.Id] {
    Policy = input.authorization_policies[_]
    Policy.DefaultUserRolePermissions.AllowedToCreateApps == true
}

AllAuthPoliciesAllowedCreate[{
    "DefaultUser_AllowedToCreateApps" : Policy.DefaultUserRolePermissions.AllowedToCreateApps,
    "PolicyId" : Policy.Id
}] {
    Policy := input.authorization_policies[_]
}

tests[{
    "PolicyId" : "MS.AAD.5.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgPolicyAuthorizationPolicy"],
    "ActualValue" : {"all_allowed_create_values": AllAuthPoliciesAllowedCreate},
    "ReportDetails" : ReportFullDetailsArray(BadPolicies, DescriptionString),
    "RequirementMet" : Status
}] {
    BadPolicies := AuthPoliciesBad_2_6
    Status := count(BadPolicies) == 0
    DescriptionString := "authorization policies found that allow non-admin users to register third-party applications"
}
#--

#
# MS.AAD.5.2v1
#--
BadDefaultGrantPolicies[Policy.Id] {
    Policy = input.authorization_policies[_]
    count(Policy.PermissionGrantPolicyIdsAssignedToDefaultUserRole) != 0
}

AllDefaultGrantPolicies[{
    "DefaultUser_DefaultGrantPolicy" : Policy.PermissionGrantPolicyIdsAssignedToDefaultUserRole,
    "PolicyId" : Policy.Id
}] {
    Policy := input.authorization_policies[_]
}

tests[{
    "PolicyId" : "MS.AAD.5.2v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgPolicyAuthorizationPolicy"],
    "ActualValue" : {"all_grant_policy_values": AllDefaultGrantPolicies},
    "ReportDetails" : ReportFullDetailsArray(BadPolicies, DescriptionString),
    "RequirementMet" : Status
}] {
    BadPolicies := BadDefaultGrantPolicies
    Status := count(BadPolicies) == 0
    DescriptionString := "authorization policies found that allow non-admin users to consent to third-party applications"
}
#--

#
# MS.AAD.5.3v1
#--
BadConsentPolicies[Policy.Id] {
    Policy := input.admin_consent_policies[_]
    Policy.IsEnabled == false
}

AllConsentPolicies[{
    "PolicyId" : Policy.Id,
    "IsEnabled" : Policy.IsEnabled
}] {
    Policy := input.admin_consent_policies[_]
}


tests[{
    "PolicyId" : "MS.AAD.5.3v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgPolicyAdminConsentRequestPolicy"],
    "ActualValue" : {"all_consent_policies": AllConsentPolicies},
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    BadPolicies := BadConsentPolicies
    Status := count(BadPolicies) == 0
}
#--

#
# MS.AAD.5.4v1
#--
AllConsentSettings[{
    "SettingsGroup": SettingGroup.DisplayName,
    "Name": Setting.Name,
    "Value": Setting.Value
}] {
    SettingGroup := input.directory_settings[_]
    Setting := SettingGroup.Values[_]
    Setting.Name == "EnableGroupSpecificConsent"
}

GoodConsentSettings[{
    "SettingsGroup": Setting.SettingsGroup,
    "Name": Setting.Name,
    "Value": Setting.Value
}] {
    Setting := AllConsentSettings[_]
    Setting.Value == "false"
}

BadConsentSettings[{
    "SettingsGroup": Setting.SettingsGroup,
    "Name": Setting.Name,
    "Value": Setting.Value
}] {
    Setting := AllConsentSettings[_]
    Setting.Value == "true"
}

tests[{
    "PolicyId" : "MS.AAD.5.4v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgDirectorySetting"],
    "ActualValue" : AllConsentSettings,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Conditions := [count(BadConsentSettings) == 0, count(GoodConsentSettings) > 0]
    Status := count([Condition | Condition = Conditions[_]; Condition == false]) == 0
}
#--

############
# MS.AAD.6 #
############

#
# MS.AAD.6.1v1
#--
# At this time we are unable to test for X because of Y
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.AAD.6.1v1"
    true
}
#--

############
# MS.AAD.7 #
############

#################################
# Helper functions for policies #
#################################

#   DoPIMRoleRulesExist will return true when the JSON privileged_roles.Rules element exists and false when it does not.
#   This was created to add special logic for the scenario where the Azure AD premium P2 license is missing and therefore
#   the JSON Rules element will not exist in that case because there is no PIM service.
#   This is necessary to avoid false negatives when a policy checks for zero instances of a specific condition.
#   For example, if a policy checks for count(RolesWithoutLimitedExpirationPeriod) == 0 and that normally means compliant, when a
#   tenant does not have the license, a count of 0 does not mean compliant because 0 is the result of not having the Rules element
#   in the JSON.
DoPIMRoleRulesExist {
    _ = input.privileged_roles[_]["Rules"]
}

default check_if_role_rules_exist := false
check_if_role_rules_exist := DoPIMRoleRulesExist

#
# MS.AAD.7.1v1
#--
GlobalAdmins[User.DisplayName] {
    some id
    User := input.privileged_users[id]
    "Global Administrator" in User.roles
}

tests[{
    "PolicyId" : "MS.AAD.7.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgSubscribedSku", "Get-PrivilegedUser"],
    "ActualValue" : GlobalAdmins,
    "ReportDetails" : ReportFullDetailsArray(GlobalAdmins, DescriptionString),
    "RequirementMet" : Status
}] {
    DescriptionString := "global admin(s) found"
    Conditions := [count(GlobalAdmins) <= 8, count(GlobalAdmins) >= 2]
    Status := count([Condition | Condition = Conditions[_]; Condition == false]) == 0
}
#--

#
# MS.AAD.7.2v1
#--
# At this time we are unable to test for user association to fine-grained privileged roles
# rather than Global Administrator due to runtime and data response size constraints
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.AAD.7.2v1"
    true
}
#--

#
# MS.AAD.7.3v1
#--
FederatedAdmins[User.DisplayName] {
    some id
    User := input.privileged_users[id]
    not is_null(User.OnPremisesImmutableId)
}

tests[{
    "PolicyId" : "MS.AAD.7.3v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgSubscribedSku", "Get-PrivilegedUser"],
    "ActualValue" : AdminNames,
    "ReportDetails" : ReportFullDetailsArray(FederatedAdmins, DescriptionString),
    "RequirementMet" : Status
}] {
    DescriptionString := "admin(s) that are not cloud-only found"
    Status := count(FederatedAdmins) == 0
    AdminNames := concat(", ", FederatedAdmins)
}
#--

#
# MS.AAD.7.4v1
#--
RolesWithoutLimitedExpirationPeriod[Role.DisplayName] {
    Role := input.privileged_roles[_]
    Rule := Role.Rules[_]
    RuleMatch := Rule.Id == "Expiration_Admin_Assignment"
    ExpirationNotRequired := Rule.AdditionalProperties.isExpirationRequired == false
    MaximumDurationCorrect := Rule.AdditionalProperties.maximumDuration == "P15D"

    # Role policy does not require assignment expiration
    Conditions1 := [RuleMatch == true, ExpirationNotRequired == true]
    Case1 := count([Condition | Condition = Conditions1[_]; Condition == false]) == 0

    # Role policy requires assignment expiration, but maximum duration is not 15 days
    Conditions2 := [RuleMatch == true, ExpirationNotRequired == false, MaximumDurationCorrect == false]
    Case2 := count([Condition | Condition = Conditions2[_]; Condition == false]) == 0

    # Filter: only include rules that meet one of the two cases
    Conditions := [Case1, Case2]
    count([Condition | Condition = Conditions[_]; Condition == true]) > 0
}

tests[{
    "PolicyId" : "MS.AAD.7.4v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgSubscribedSku", "Get-PrivilegedRole"],
    "ActualValue" : RolesWithoutLimitedExpirationPeriod,
    "ReportDetails" : ReportDetailsArrayLicenseWarning(RolesWithoutLimitedExpirationPeriod, DescriptionString),
    "RequirementMet" : Status
}] {
    DescriptionString := "role(s) configured to allow permanent active assignment or expiration period too long"
    Conditions := [count(RolesWithoutLimitedExpirationPeriod) == 0, check_if_role_rules_exist]
    Status := count([Condition | Condition = Conditions[_]; Condition == false]) == 0
}
#--

#
# MS.AAD.7.5v1
#--
RolesAssignedOutsidePim[Role.DisplayName] {
    Role := input.privileged_roles[_]
    NoStartAssignments := { is_null(X.StartDateTime) | X = Role.Assignments[_] }

    count([Condition | Condition = NoStartAssignments[_]; Condition == true]) > 0
}

tests[{
    "PolicyId" : "MS.AAD.7.5v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgSubscribedSku", "Get-PrivilegedRole"],
    "ActualValue" : RolesAssignedOutsidePim,
    "ReportDetails" : ReportDetailsArrayLicenseWarning(RolesAssignedOutsidePim, DescriptionString),
    "RequirementMet" : Status
}] {
    DescriptionString := "role(s) assigned to users outside of PIM"
    Conditions := [count(RolesAssignedOutsidePim) == 0, check_if_role_rules_exist]
    Status := count([Condition | Condition = Conditions[_]; Condition == false]) == 0
}
#--

#
# MS.AAD.7.6v1
#--
RolesWithoutApprovalRequired[RoleName] {
    Role := input.privileged_roles[_]
    RoleName := Role.DisplayName
    Rule := Role.Rules[_]
    # Filter: only include policies that meet all the requirements
    Rule.Id == "Approval_EndUser_Assignment"
    Rule.AdditionalProperties.setting.isApprovalRequired == false
}

tests[{
    "PolicyId" : "MS.AAD.7.6v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-MgSubscribedSku", "Get-PrivilegedRole"],
    "ActualValue" : RolesWithoutApprovalRequired,
    "ReportDetails" : ReportDetailsBooleanLicenseWarning(Status),
    "RequirementMet" : Status
}] {
    ApprovalNotRequired := "Global Administrator" in RolesWithoutApprovalRequired
    Conditions := [ApprovalNotRequired == false, check_if_role_rules_exist]
    Status := count([Condition | Condition = Conditions[_]; Condition == false]) == 0
}
#--

#
# MS.AAD.7.7v1
#--
RolesWithoutActiveAssignmentAlerts[RoleName] {
    Role := input.privileged_roles[_]
    RoleName := Role.DisplayName
    Rule := Role.Rules[_]
    # Filter: only include policies that meet all the requirements
    Rule.Id == "Notification_Admin_Admin_Assignment"
    count(Rule.AdditionalProperties.notificationRecipients) == 0
}

RolesWithoutEligibleAssignmentAlerts[RoleName] {
    Role := input.privileged_roles[_]
    RoleName := Role.DisplayName
    Rule := Role.Rules[_]
    # Filter: only include policies that meet all the requirements
    Rule.Id == "Notification_Admin_Admin_Eligibility"
    count(Rule.AdditionalProperties.notificationRecipients) == 0
}

tests[{
    "PolicyId" : "MS.AAD.7.7v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgSubscribedSku", "Get-PrivilegedRole"],
    "ActualValue" : RolesWithoutAssignmentAlerts,
    "ReportDetails" : ReportDetailsArrayLicenseWarning(RolesWithoutAssignmentAlerts, DescriptionString),
    "RequirementMet" : Status
}] {
    DescriptionString := "role(s) without notification e-mail configured for role assignments found"
    RolesWithoutAssignmentAlerts := RolesWithoutActiveAssignmentAlerts | RolesWithoutEligibleAssignmentAlerts
    Conditions := [count(RolesWithoutAssignmentAlerts) == 0, check_if_role_rules_exist]
    Status := count([Condition | Condition = Conditions[_]; Condition == false]) == 0
}
#--

#
# MS.AAD.7.8v1
#--
AdminsWithoutActivationAlert[RoleName] {
    Role := input.privileged_roles[_]
    RoleName := Role.DisplayName
    Rule := Role.Rules[_]
    # Filter: only include policies that meet all the requirements
    Rule.Id == "Notification_Admin_EndUser_Assignment"
    Rule.AdditionalProperties.notificationType == "Email"
    count(Rule.AdditionalProperties.notificationRecipients) == 0
}

tests[{
    "PolicyId" : "MS.AAD.7.8v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgSubscribedSku", "Get-PrivilegedRole"],
    "ActualValue" : AdminsWithoutActivationAlert,
    "ReportDetails" : ReportDetailsBooleanLicenseWarning(Status),
    "RequirementMet" : Status
}] {
    GlobalAdminNotMonitored := "Global Administrator" in AdminsWithoutActivationAlert
    Conditions := [GlobalAdminNotMonitored == false, check_if_role_rules_exist]
    Status := count([Condition | Condition = Conditions[_]; Condition == false]) == 0
}
#--

#
# MS.AAD.7.9v1
#--
tests[{
    "PolicyId" : "MS.AAD.7.9v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-MgSubscribedSku", "Get-PrivilegedRole"],
    "ActualValue" : NonGlobalAdminsWithoutActivationAlert,
    "ReportDetails" : ReportDetailsArrayLicenseWarning(NonGlobalAdminsWithoutActivationAlert, DescriptionString),
    "RequirementMet" : Status
}] {
    DescriptionString := "role(s) without notification e-mail configured for role activations found"
    NonGlobalAdminsWithoutActivationAlert = AdminsWithoutActivationAlert - {"Global Administrator"}
    Conditions := [count(NonGlobalAdminsWithoutActivationAlert) == 0, check_if_role_rules_exist]
    Status := count([Condition | Condition = Conditions[_]; Condition == false]) == 0
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
LevelAsString(Id) := "Restricted access" if {Id == "2af84b1e-32c8-42b7-82bc-daa82404023b"}
LevelAsString(Id) := "Limited access" if {Id == "10dae51f-b6af-4016-8d66-8c2a99b929b3"}
LevelAsString(Id) := "Same as member users" if {Id == "a0b1b346-4d3e-4e8b-98f8-753987be4970"}
LevelAsString(Id) := "Unknown" if {not Id in ["2af84b1e-32c8-42b7-82bc-daa82404023b", "10dae51f-b6af-4016-8d66-8c2a99b929b3", "a0b1b346-4d3e-4e8b-98f8-753987be4970"]}

AuthPoliciesBadRoleId[Policy.Id] {
    Policy = input.authorization_policies[_]
    not Policy.GuestUserRoleId in ["10dae51f-b6af-4016-8d66-8c2a99b929b3", "2af84b1e-32c8-42b7-82bc-daa82404023b"]
}

AllAuthPoliciesRoleIds[{
    "GuestUserRoleIdString" : Level,
    "GuestUserRoleId" : Policy.GuestUserRoleId,
    "Id" : Policy.Id
}] {
    Policy = input.authorization_policies[_]
    Level := LevelAsString(Policy.GuestUserRoleId)
}

RoleIdByPolicy[concat("", ["\"", Level, "\"", " (", Policy.Id, ")"])] {
    Policy := input.authorization_policies[_]
    Level := LevelAsString(Policy.GuestUserRoleId)
}

tests[{
    "PolicyId" : "MS.AAD.8.1v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-MgPolicyAuthorizationPolicy"],
    "ActualValue" : {"all_roleid_values" : AllAuthPoliciesRoleIds},
    "ReportDetails" : ReportDetail,
    "RequirementMet" : Status
}] {
    BadPolicies := AuthPoliciesBadRoleId
    Status := count(BadPolicies) == 0
    ReportDetail := concat("", ["Permission level set to ", concat(", ", RoleIdByPolicy)])
}
#--

#
# MS.AAD.8.2v1
#--
AuthPoliciesBadAllowInvites[Policy.Id] {
    Policy = input.authorization_policies[_]
    Policy.AllowInvitesFrom != "adminsAndGuestInviters"
}

AllowInvitesByPolicy[concat("", ["\"", Policy.AllowInvitesFrom, "\"", " (", Policy.Id, ")"])] {
    Policy := input.authorization_policies[_]
}

AllAuthPoliciesAllowInvites[{
    "AllowInvitesFromValue" : Policy.AllowInvitesFrom,
    "PolicyId" : Policy.Id
}] {
    Policy := input.authorization_policies[_]
}

tests[{
    "PolicyId" : "MS.AAD.8.2v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-MgPolicyAuthorizationPolicy"],
    "ActualValue" : {"all_allow_invite_values": AllAuthPoliciesAllowInvites},
    "ReportDetails" : ReportDetail,
    "RequirementMet" : Status
}] {
    BadPolicies := AuthPoliciesBadAllowInvites
    Status := count(BadPolicies) == 0
    ReportDetail := concat("", ["Permission level set to ", concat(", ", AllowInvitesByPolicy)])
}
#--

#
# MS.AAD.8.3v1
#--
# At this time we are unable to test for X because of Y
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.AAD.8.3v1"
    true
}
#--