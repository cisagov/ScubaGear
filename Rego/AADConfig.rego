package aad
import future.keywords

################
# The report formatting functions below are generic and used throughout the policies #
################
Format(Array) = format_int(count(Array), 10)

Description(String1, String2, String3) =  trim(concat(" ", [String1, String2, String3]), " ")

ReportDetailsBoolean(Status) = "Requirement met" if {Status == true}

ReportDetailsBoolean(Status) = "Requirement not met" if {Status == false}

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

################
# The report formatting functions below are for policies that check the required Azure AD Premium P2 license #
################
Aad2P2Licenses[ServicePlan.ServicePlanId] {
    ServicePlan = input.service_plans[_]
    ServicePlan.ServicePlanName == "AAD_PREMIUM_P2"
}

P2WarningString := "**NOTE: Your tenant does not have an Azure AD Premium P2 license, which is required for this feature**"

ReportDetailsArrayLicenseWarningCap(Array, String) = Description if {
  count(Aad2P2Licenses) > 0
  Description :=  concat(". ", [ReportFullDetailsArray(Array, String), CapLink])
}

ReportDetailsArrayLicenseWarningCap(Array, String) = Description if {
  count(Aad2P2Licenses) == 0
  Description := P2WarningString
}

ReportDetailsArrayLicenseWarning(Array, String) = Description if {
  count(Aad2P2Licenses) > 0
  Description :=  ReportFullDetailsArray(Array, String)
}

ReportDetailsArrayLicenseWarning(Array, String) = Description if {
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

ReportDetailsBooleanLicenseWarning(Status) = Description if {
    count(Aad2P2Licenses) == 0
    Description := P2WarningString
}

################
# Baseline 2.1 #
################

#
# Baseline 2.1: Policy 1
#--
Policies2_1[Cap.DisplayName] {
    Cap := input.conditional_access_policies[_]
    # Filter: only include policies that meet all the requirements
    "All" in Cap.Conditions.Users.IncludeUsers
    "All" in Cap.Conditions.Users.IncludeGroups
    "All" in Cap.Conditions.Users.IncludeRoles
    count(Cap.Conditions.Users.ExcludeUsers) == 0
    count(Cap.Conditions.Users.ExcludeGroups) == 0
    count(Cap.Conditions.Users.ExcludeRoles) == 0
    "All" in Cap.Conditions.Applications.IncludeApplications
    "other" in Cap.Conditions.ClientAppTypes
    "exchangeActiveSync" in Cap.Conditions.ClientAppTypes
    "block" in Cap.GrantControls.BuiltInControls
    Cap.State == "enabled"
}

tests[{
    "Requirement" : "Legacy authentication SHALL be blocked",
    "Control" : "AAD 2.1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgIdentityConditionalAccessPolicy"],
    "ActualValue" : Policies2_1,
    "ReportDetails" : concat(". ", [ReportFullDetailsArray(Policies2_1, DescriptionString), CapLink]),
    "RequirementMet" : count(Policies2_1) > 0
}] {
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    true
}
#--


################
# Baseline 2.2 #
################

#
# Baseline 2.2: Policy 1
#--
Policies2_2[Cap.DisplayName] {
    Cap := input.conditional_access_policies[_]
    # Filter: only include policies that meet all the requirements
    "All" in Cap.Conditions.Users.IncludeUsers
    "All" in Cap.Conditions.Users.IncludeGroups
    "All" in Cap.Conditions.Users.IncludeRoles
    count(Cap.Conditions.Users.ExcludeUsers) == 0
    count(Cap.Conditions.Users.ExcludeGroups) == 0
    count(Cap.Conditions.Users.ExcludeRoles) == 0
    "All" in Cap.Conditions.Applications.IncludeApplications
    "high" in Cap.Conditions.UserRiskLevels
    "block" in Cap.GrantControls.BuiltInControls
    Cap.State == "enabled"
}

tests[{
    "Requirement" : "Users detected as high risk SHALL be blocked",
    "Control" : "AAD 2.2",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgIdentityConditionalAccessPolicy"],
    "ActualValue" : Policies2_2,
    "ReportDetails" : ReportDetailsArrayLicenseWarningCap(Policies2_2, DescriptionString),
    "RequirementMet" : Status
}] {
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    Status := count(Policies2_2) > 0
}
#--

#
# Baseline 2.2: Policy 2
#--
# At this time we are unable to test for X because of Y
tests[{
    "Requirement" : "A notification SHOULD be sent to the administrator when high-risk users are detected",
    "Control" : "AAD 2.2",
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Azure Active Directory Secure Configuration Baseline policy 2.2 for instructions on manual check",
    "RequirementMet" : false
}] {
    true
}
#--


################
# Baseline 2.3 #
################

#
# Baseline 2.3: Policy 1
#--
Policies2_3[Cap.DisplayName] {
    Cap := input.conditional_access_policies[_]
    # Filter: only include policies that meet all the requirements
    "All" in Cap.Conditions.Users.IncludeUsers
    "All" in Cap.Conditions.Users.IncludeGroups
    "All" in Cap.Conditions.Users.IncludeRoles
    count(Cap.Conditions.Users.ExcludeUsers) == 0
    count(Cap.Conditions.Users.ExcludeGroups) == 0
    count(Cap.Conditions.Users.ExcludeRoles) == 0
    "All" in Cap.Conditions.Applications.IncludeApplications
    "high" in Cap.Conditions.SignInRiskLevels
    "block" in Cap.GrantControls.BuiltInControls
    Cap.State == "enabled"
}

tests[{
    "Requirement" : "Sign-ins detected as high risk SHALL be blocked",
    "Control" : "AAD 2.3",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgIdentityConditionalAccessPolicy"],
    "ActualValue" : Policies2_3,
    "ReportDetails" : ReportDetailsArrayLicenseWarningCap(Policies2_3, DescriptionString),
    "RequirementMet" : Status
}] {
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    Status := count(Policies2_3) > 0
}
#--


################
# Baseline 2.4 #
################

#
# Baseline 2.4: Policy 1
#--
Policies2_4_1[Cap.DisplayName] {
    Cap := input.conditional_access_policies[_]
    # Filter: only include policies that meet all the requirements
    "All" in Cap.Conditions.Users.IncludeUsers
    "All" in Cap.Conditions.Users.IncludeGroups
    "All" in Cap.Conditions.Users.IncludeRoles
    count(Cap.Conditions.Users.ExcludeUsers) == 0
    count(Cap.Conditions.Users.ExcludeGroups) == 0
    count(Cap.Conditions.Users.ExcludeRoles) == 0
    "All" in Cap.Conditions.Applications.IncludeApplications
    "mfa" in Cap.GrantControls.BuiltInControls
    Cap.State == "enabled"
}

tests[{
    "Requirement" : "MFA SHALL be required for all users",
    "Control" : "AAD 2.4",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgIdentityConditionalAccessPolicy"],
    "ActualValue" : Policies2_4_1,
    "ReportDetails" : concat(". ", [ReportFullDetailsArray(Policies2_4_1, DescriptionString), CapLink]),
    "RequirementMet" : count(Policies2_4_1) > 0
}]{
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    true
}
#--

#
# Baseline 2.4: Policy 2
#--
# At this time we are unable to fully test for MFA due to conflicting and multiple ways to configure authentication methods
# Awaiting API changes and feature updates from Microsoft for automated checking
tests[{
    "Requirement" : "Phishing-resistant MFA SHALL be used for all users",
    "Control" : "AAD 2.4",
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Azure Active Directory Secure Configuration Baseline policy 2.4 for instructions on manual check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.4: Policy 3
#--
# At this time we are unable to test for all users due to conflicting and multiple ways to configure authentication methods
# Awaiting API changes and feature updates from Microsoft for automated checking
tests[{
    "Requirement" : "If phishing-resistant MFA cannot be used, an MFA method from the list [see AAD baseline 2.4] SHALL be used in the interim",
    "Control" : "AAD 2.4",
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Azure Active Directory Secure Configuration Baseline policy 2.4 for instructions on manual check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.4: Policy 4
#--
# At this time we are unable to test for SMS/Voice settings due to lack of API to validate
# Awaiting API changes and feature updates from Microsoft for automated checking
tests[{
    "Requirement" : "SMS or Voice as the MFA method SHALL NOT be used",
    "Control" : "AAD 2.4",
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Azure Active Directory Secure Configuration Baseline policy 2.4 for instructions on manual check",
    "RequirementMet" : false
}] {
    true
}
#--


################
# Baseline 2.5 #
################

#
# Baseline 2.5: Policy 1
#--
# At this time we are unable to test for log collection until we integrate Azure Powershell capabilities
tests[{
    "Requirement" : "The following critical logs SHALL be sent at a minimum: AuditLogs, SignInLogs, RiskyUsers, UserRiskEvents, NonInteractiveUserSignInLogs, ServicePrincipalSignInLogs, ADFSSignInLogs, RiskyServicePrincipals, ServicePrincipalRiskEvents",
    "Control" : "AAD 2.5",
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Azure Active Directory Secure Configuration Baseline policy 2.5 for instructions on manual check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.5: Policy 2
#--
# At this time we are unable to test for X because of Y
tests[{
    "Requirement" : "The logs SHALL be sent to the agency's SOC for monitoring",
    "Control" : "AAD 2.5",
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Azure Active Directory Secure Configuration Baseline policy 2.5 for instructions on manual check",
    "RequirementMet" : false
}] {
    true
}
#--


################
# Baseline 2.6 #
################

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

#
# Baseline 2.6: Policy 1
#--
tests[{
    "Requirement" : "Only administrators SHALL be allowed to register third-party applications",
    "Control" : "AAD 2.6",
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


################
# Baseline 2.7 #
################

#
# Baseline 2.7: Policy 1
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
    "Requirement" : "Only administrators SHALL be allowed to consent to third-party applications",
    "Control" : "AAD 2.7",
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
# Baseline 2.7: Policy 2
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
    "Requirement" : "An admin consent workflow SHALL be configured",
    "Control" : "AAD 2.7",
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
# Baseline 2.7: Policy 3
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
    "Requirement" : "Group owners SHALL NOT be allowed to consent to third-party applications",
    "Control" : "AAD 2.7",
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


################
# Baseline 2.8 #
################

#
# Baseline 2.8: Policy 1
#--
# At this time we are unable to test for X because of Y
tests[{
    "Requirement" : "User passwords SHALL NOT expire",
    "Control" : "AAD 2.8",
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Azure Active Directory Secure Configuration Baseline policy 2.8 for instructions on manual check",
    "RequirementMet" : false
}] {
    true
}
#--


################
# Baseline 2.9 #
################

#
# Baseline 2.9: Policy 1
#--
Policies2_9[Cap.DisplayName] {
    Cap := input.conditional_access_policies[_]
    # Filter: only include policies that meet all the requirements
    "All" in Cap.Conditions.Users.IncludeUsers
    "All" in Cap.Conditions.Users.IncludeGroups
    "All" in Cap.Conditions.Users.IncludeRoles
    count(Cap.Conditions.Users.ExcludeUsers) == 0
    count(Cap.Conditions.Users.ExcludeGroups) == 0
    count(Cap.Conditions.Users.ExcludeRoles) == 0
    "All" in Cap.Conditions.Applications.IncludeApplications
    Cap.SessionControls.SignInFrequency.IsEnabled == true
    Cap.SessionControls.SignInFrequency.Type == "hours"
    Cap.SessionControls.SignInFrequency.Value == 12
    Cap.State == "enabled"
}

tests[{
    "Requirement" : "Sign-in frequency SHALL be configured to 12 hours",
    "Control" : "AAD 2.9",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgIdentityConditionalAccessPolicy"],
    "ActualValue" : Policies2_9,
    "ReportDetails" : concat(". ", [ReportFullDetailsArray(Policies2_9, DescriptionString), CapLink]),
    "RequirementMet" : count(Policies2_9) > 0
}] {
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    true
}
#--


#################
# Baseline 2.10 #
#################

#
# Baseline 2.10: Policy 1
#--
Policies2_10[Cap.DisplayName] {
    Cap := input.conditional_access_policies[_]
    # Filter: only include policies that meet all the requirements
    "All" in Cap.Conditions.Users.IncludeUsers
    "All" in Cap.Conditions.Users.IncludeGroups
    "All" in Cap.Conditions.Users.IncludeRoles
    count(Cap.Conditions.Users.ExcludeUsers) == 0
    count(Cap.Conditions.Users.ExcludeGroups) == 0
    count(Cap.Conditions.Users.ExcludeRoles) == 0
    "All" in Cap.Conditions.Applications.IncludeApplications
    Cap.SessionControls.PersistentBrowser.IsEnabled == true
    Cap.SessionControls.PersistentBrowser.Mode == "never"
    Cap.State == "enabled"
}

tests[{
    "Requirement" : "Browser sessions SHALL not be persistent",
    "Control" : "AAD 2.10",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgIdentityConditionalAccessPolicy"],
    "ActualValue" : Policies2_10,
    "ReportDetails" : concat(". ", [ReportFullDetailsArray(Policies2_10, DescriptionString), CapLink]),
    "RequirementMet" : count(Policies2_10) > 0
}] {
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    true
}
#--


#################
# Baseline 2.11 #
#################

#
# Baseline 2.11: Policy 1
#--
GlobalAdmins[User.DisplayName] {
    some id
    User := input.privileged_users[id]
    "Global Administrator" in User.roles
}

tests[{
    "Requirement" : "A minimum of two users and a maximum of four users SHALL be provisioned with the Global Administrator role",
    "Control" : "AAD 2.11",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgSubscribedSku", "Get-PrivilegedUser"],
    "ActualValue" : GlobalAdmins,
    "ReportDetails" : ReportFullDetailsArray(GlobalAdmins, DescriptionString),
    "RequirementMet" : Status
}] {
    DescriptionString := "global admin(s) found"
    Conditions := [count(GlobalAdmins) < 5, count(GlobalAdmins) >= 2]
    Status := count([Condition | Condition = Conditions[_]; Condition == false]) == 0
}
#--


#################
# Baseline 2.12 #
#################

#
# Baseline 2.12: Policy 1
#--
FederatedAdmins[User.DisplayName] {
    some id
    User := input.privileged_users[id]
    not is_null(User.OnPremisesImmutableId)
}

tests[{
    "Requirement" : "Users that need to be assigned to highly privileged Azure AD roles SHALL be provisioned cloud-only accounts that are separate from the on-premises directory or other federated identity providers",
    "Control" : "AAD 2.12",
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

#################
# Baseline 2.13 #
#################

#
# Baseline 2.13: Policy 1
#--
Policies2_13[Cap.DisplayName] {
    Cap := input.conditional_access_policies[_]
    PrivRolesSet := { Role.RoleTemplateId | Role = input.privileged_roles[_] }
    CondIncludedRolesSet := { Y | Y = Cap.Conditions.Users.IncludeRoles[_] }
    MissingRoles := PrivRolesSet - CondIncludedRolesSet
    # Filter: only include policies that meet all the requirements
    count(MissingRoles) == 0
    "All" in Cap.Conditions.Applications.IncludeApplications
    "mfa" in Cap.GrantControls.BuiltInControls
    Cap.State == "enabled"
}

tests[{
    "Requirement" : "MFA SHALL be required for user access to highly privileged roles",
    "Control" : "AAD 2.13",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MgSubscribedSku", "Get-PrivilegedRole", "Get-MgIdentityConditionalAccessPolicy"],
    "ActualValue" : Policies2_13,
    "ReportDetails" : concat(". ", [ReportFullDetailsArray(Policies2_13, DescriptionString), CapLink]),
    "RequirementMet" : count(Policies2_13) > 0
}] {
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
}
#--


#################
# Helper functions for policies 2.14, 2.15, 2.16
#################

# DoPIMRoleRulesExist will return true when the JSON privileged_roles.Rules element exists and false when it does not.
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

# DoPIMRoleAssignmentsExist will return true when the JSON privileged_roles.Assignments element exists and false when it does not.
DoPIMRoleAssignmentsExist {
    _ = input.privileged_roles[_]["Assignments"]
}

default check_if_role_assignments_exist := false
check_if_role_assignments_exist := DoPIMRoleAssignmentsExist

#################
# Baseline 2.14 #
#################

#
# Baseline 2.14: Policy 1
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
    "Requirement" : "Permanent active role assignments SHALL NOT be allowed for highly privileged roles. Active assignments SHALL have an expiration period.",
    "Control" : "AAD 2.14",
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
# Baseline 2.14: Policy 2
#--
RolesAssignedOutsidePim[Role.DisplayName] {
    Role := input.privileged_roles[_]
    NoStartAssignments := { is_null(X.StartDateTime) | X = Role.Assignments[_] }

    count([Condition | Condition = NoStartAssignments[_]; Condition == true]) > 0
}

tests[{
    "Requirement" : "Provisioning of users to highly privileged roles SHALL NOT occur outside of a PAM system, such as the Azure AD PIM service, because this bypasses the controls the PAM system provides",
    "Control" : "AAD 2.14",
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


#################
# Baseline 2.15 #
#################

#
# Baseline 2.15: Policy 1
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
    "Requirement" : "Activation of highly privileged roles SHOULD require approval",
    "Control" : "AAD 2.15",
    "Criticality" : "Should",
    "Commandlet" : ["Get-MgSubscribedSku", "Get-PrivilegedRole"],
    "ActualValue" : RolesWithoutApprovalRequired,
    "ReportDetails" : ReportDetailsArrayLicenseWarning(RolesWithoutApprovalRequired, DescriptionString),
    "RequirementMet" : Status
}] {
    DescriptionString := "role(s) that do not require approval to activate found"
    Conditions := [count(RolesWithoutApprovalRequired) == 0, check_if_role_rules_exist]
    Status := count([Condition | Condition = Conditions[_]; Condition == false]) == 0
}
#--


#################
# Baseline 2.16 #
#################

#
# Baseline 2.16: Policy 1
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
    "Requirement" : "Eligible and Active highly privileged role assignments SHALL trigger an alert",
    "Control" : "AAD 2.16",
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
# Baseline 2.16: Policy 2
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
    "Requirement" : "User activation of the Global Administrator role SHALL trigger an alert",
    "Control" : "AAD 2.16",
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
# Baseline 2.16: Policy 3
#--
tests[{
    "Requirement" : "User activation of other highly privileged roles SHOULD trigger an alert",
    "Control" : "AAD 2.16",
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


#################
# Baseline 2.17 #
#################

#
# Baseline 2.17: Policy 1
#--
Policies2_17[Cap.DisplayName] {
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
    "Requirement" : "Managed devices SHOULD be required for authentication",
    "Control" : "AAD 2.17",
    "Criticality" : "Should",
    "Commandlet" : ["Get-MgIdentityConditionalAccessPolicy"],
    "ActualValue" : Policies2_17,
    "ReportDetails" : concat(". ", [ReportFullDetailsArray(Policies2_17, DescriptionString), CapLink]),
    "RequirementMet" : count(Policies2_17) > 0
}] {
    DescriptionString := "conditional access policy(s) found that meet(s) all requirements"
    true
}
#--


#################
# Baseline 2.18 #
#################

#
# Baseline 2.18: Policy 1
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
    "Requirement" : "Only users with the Guest Inviter role SHOULD be able to invite guest users",
    "Control" : "AAD 2.18",
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
# Baseline 2.18: Policy 2
#--
# At this time we are unable to test for X because of Y
tests[{
    "Requirement" : "Guest invites SHOULD only be allowed to specific external domains that have been authorized by the agency for legitimate business purposes",
    "Control" : "AAD 2.18",
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Azure Active Directory Secure Configuration Baseline policy 2.18 for instructions on manual check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.18: Policy 3
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
    "Requirement" : "Guest users SHOULD have limited access to Azure AD directory objects",
    "Control" : "AAD 2.18",
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