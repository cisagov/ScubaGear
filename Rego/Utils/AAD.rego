package utils.aad
import future.keywords
import data.utils.report.FormatArray
import data.utils.report.Description
import data.utils.policy.IsEmptyContainer
import data.utils.policy.Contains
import data.utils.policy.Count
import data.utils.policy.FAIL
import data.utils.policy.PASS


# Set to the maximum number of array items to be
# printed in the report details section
REPORTARRAYMAXCOUNT := 20

#############################################################################
# The report formatting functions below are generic and used throughout AAD #
#############################################################################

ReportDetailsArray(Array, String) := Description([FormatArray(Array), String])

ReportFullDetailsArray(Array, String) := ReportDetailsArray(Array, String) if {
    count(Array) == 0
}

ReportFullDetailsArray(Array, String) := Details if {
    count(Array) > 0
    count(Array) <= REPORTARRAYMAXCOUNT
    Details := Description([FormatArray(Array), concat(":<br/>", [String, concat(", ", Array)])])
}

ReportFullDetailsArray(Array, String) := Details if {
    count(Array) > REPORTARRAYMAXCOUNT
    List := [x | some x in Array]

    TruncationWarning := "...<br/>Note: The list of matching items has been truncated.  Full details are available in the JSON results."
    TruncatedList := concat(", ", array.slice(List, 0, REPORTARRAYMAXCOUNT))
    Details := Description([FormatArray(Array), concat(":<br/>", [String, TruncatedList]), TruncationWarning])
}

##############################################################################################################
# The report formatting functions below are for policies that check the required Microsoft Entra ID P2 license #
##############################################################################################################

Aad2P2Licenses contains ServicePlan.ServicePlanId if {
    some ServicePlan in input.service_plans
    ServicePlan.ServicePlanName == "AAD_PREMIUM_P2"
}

P2WarningString := "**NOTE: Your tenant does not have a Microsoft Entra ID P2 license, which is required for this feature**"

CapLink := "<a href='#caps'>View all CA policies</a>."

ReportDetailsArrayLicenseWarningCap(Array, String) := Description if {
    count(Aad2P2Licenses) > 0
    Description := concat(". ", [ReportFullDetailsArray(Array, String), CapLink])
} else := P2WarningString

ReportDetailsArrayLicenseWarning(Array, String) := ReportFullDetailsArray(Array, String) if {
    count(Aad2P2Licenses) > 0
} else := P2WarningString

ReportDetailsBooleanLicenseWarning(true) := PASS if {
    count(Aad2P2Licenses) > 0
}

ReportDetailsBooleanLicenseWarning(false) := FAIL if {
    count(Aad2P2Licenses) > 0
}

ReportDetailsBooleanLicenseWarning(_) := P2WarningString if {
    count(Aad2P2Licenses) == 0
}

##########################################
# User/Group Exclusion support functions #
##########################################

default UserExclusionsFullyExempt(_, _) := false

# Returns true when all user exclusions present in the conditional
# access policy are exempted in matching config variable for the
# baseline policy item.  Undefined if no exclusions AND no exemptions.
UserExclusionsFullyExempt(Policy, PolicyID) := true if {
    ExemptedUsers := input.scuba_config.Aad[PolicyID].CapExclusions.Users
    ExcludedUsers := {x | some x in Policy.Conditions.Users.ExcludeUsers}
    AllowedExcludedUsers := {y | some y in ExemptedUsers}
    count(ExcludedUsers - AllowedExcludedUsers) == 0
}

# Returns true when user inputs are not defined or user exclusion lists are empty
UserExclusionsFullyExempt(Policy, PolicyID) := true if {
    count({x | some x in Policy.Conditions.Users.ExcludeUsers}) == 0
    count({y | y := input.scuba_config.Aad[PolicyID].CapExclusions.Users}) == 0
}

default GroupExclusionsFullyExempt(_, _) := false

# Returns true when all group exclusions present in the conditional
# access policy are exempted in matching config variable for the
# baseline policy item.  Undefined if no exclusions AND no exemptions.
GroupExclusionsFullyExempt(Policy, PolicyID) := true if {
    ExemptedGroups := input.scuba_config.Aad[PolicyID].CapExclusions.Groups
    ExcludedGroups := {x | some x in Policy.Conditions.Users.ExcludeGroups}
    AllowedExcludedGroups := {y | some y in ExemptedGroups}
    count(ExcludedGroups - AllowedExcludedGroups) == 0
}

# Returns true when user inputs are not defined or group exclusion lists are empty
GroupExclusionsFullyExempt(Policy, PolicyID) := true if {
    count({x | some x in Policy.Conditions.Users.ExcludeGroups}) == 0
    count({y | y := input.scuba_config.Aad[PolicyID].CapExclusions.Groups}) == 0
}


########################
# Refactored Functions #
########################

# Return true if policy matches all conditions:
# All for include users & applications,
# block for built in controls, enabled,
# & NO excluded roles.
PolicyConditionsMatch(Policy) := true if {
    Contains(Policy.Conditions.Users.IncludeUsers, "All") == true
    Contains(Policy.Conditions.Applications.IncludeApplications, "All") == true
    Policy.State == "enabled"
    IsEmptyContainer(Policy.Conditions.Users.ExcludeRoles) == true
} else := false

# Save the Allowed MFA items as a set, check if there are any MFA
# items allowed besides the acceptable ones & if there is at least
# 1 MFA item allowed. Return true
HasAcceptableMFA(Policy) := true if {
    # Strength must be at least one of acceptable with no unacceptable strengths
    Strengths := ConvertToSet(Policy.GrantControls.AuthenticationStrength.AllowedCombinations)
    AcceptableMFA := {"windowsHelloForBusiness", "fido2", "x509CertificateMultiFactor"}
    Count(Strengths - AcceptableMFA) == 0
    Count(Strengths) > 0
} else := false

ConvertToSet(Items) := NewSet if {
    NewSet := {Item | some Item in Items}
} else := set()

ConvertToSetWithKey(Items, Key) := NewSet if {
    NewSet := {Item[Key] | some Item in Items}
} else := set()