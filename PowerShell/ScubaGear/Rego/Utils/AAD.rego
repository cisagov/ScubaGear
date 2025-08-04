package utils.aad
import rego.v1
import data.utils.report.ArraySizeStr
import data.utils.report.Description
import data.utils.key.Count
import data.utils.key.ConvertToSet
import data.utils.key.FAIL
import data.utils.key.PASS


#############
# Constants #
#############

# Set to the maximum number of array items to be
# printed in the report details section
REPORTARRAYMAXCOUNT := 20

# License warning string
P2WARNINGSTR :=
    "**NOTE: Your tenant does not have a Microsoft Entra ID P2 license, which is required for this feature**"

CAPLINK := "<a href='#caps'>View all CA policies</a>."

INT_MAX := 2147483647

########################################
# Specific AAD Report Details Function #
########################################

# Function returns the string that indicates the number of fails & each item that fails.
# If the number of items is greater than our REPORTARRAYMAXCOUNT, the item list is
# truncated for readability purposes.
ReportFullDetailsArray(Array, String) := Description([ArraySizeStr(Array), String]) if {
    count(Array) == 0
}

ReportFullDetailsArray(Array, String) := Details if {
    count(Array) > 0
    count(Array) <= REPORTARRAYMAXCOUNT
    Details := Description([
        ArraySizeStr(Array),
        concat(":<br/>", [String, concat(", ", Array)])
    ])
}

ReportFullDetailsArray(Array, String) := Details if {
    count(Array) > REPORTARRAYMAXCOUNT

    TruncationWarning :=
        "...<br/>Note: The list of matching items has been truncated. Full details are available in the JSON results."

    TruncatedList := concat(", ", array.slice(
        [x | some x in Array],
        0,
        REPORTARRAYMAXCOUNT
    ))
    Details := Description([
        ArraySizeStr(Array),
        concat(":<br/>", [String, TruncatedList]),
        TruncationWarning
    ])
}

#################################################################################
# Report Detail Functions for check that required Microsoft Entra ID P2 license #
#################################################################################

Aad2P2Licenses contains ServicePlan.ServicePlanId if {
    some ServicePlan in input.service_plans
    ServicePlan.ServicePlanName == "AAD_PREMIUM_P2"
}

# Returns license warning if license not present as results may be wrong,
# Othewise returns report string with link to table at bottom of report
ReportDetailsArrayLicenseWarningCap(Array, String) := Description if {
    count(Aad2P2Licenses) > 0
    Description := concat(". ", [ReportFullDetailsArray(Array, String), CAPLINK])
} else := P2WARNINGSTR

# Returns license warning if license not present as results may be wrong,
# Othewise returns report string
ReportDetailsArrayLicenseWarning(Array, String) := ReportFullDetailsArray(Array, String) if {
    count(Aad2P2Licenses) > 0
} else := P2WARNINGSTR

# Returns license warning if license not present as results may be wrong,
# Othewise returns basic report string
ReportDetailsBooleanLicenseWarning(true) := PASS if {
    count(Aad2P2Licenses) > 0
}

ReportDetailsBooleanLicenseWarning(false) := FAIL if {
    count(Aad2P2Licenses) > 0
}

ReportDetailsBooleanLicenseWarning(_) := P2WARNINGSTR if {
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
    ExcludedUsers := ConvertToSet(Policy.Conditions.Users.ExcludeUsers)
    AllowedExcludedUsers := ConvertToSet(ExemptedUsers)
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
    ExcludedGroups := ConvertToSet(Policy.Conditions.Users.ExcludeGroups)
    AllowedExcludedGroups := ConvertToSet(ExemptedGroups)
    count(ExcludedGroups - AllowedExcludedGroups) == 0
}

# Returns true when user inputs are not defined or group exclusion lists are empty
GroupExclusionsFullyExempt(Policy, PolicyID) := true if {
    count({x | some x in Policy.Conditions.Users.ExcludeGroups}) == 0
    count({y | y := input.scuba_config.Aad[PolicyID].CapExclusions.Groups}) == 0
}


#########################
# General AAD Functions #
#########################

# Save the Allowed MFA items as a set, check if there are any MFA
# items allowed besides the acceptable ones & if there is at least
# 1 MFA item allowed. Return true
IsPhishingResistantMFA(Policy) := true if {
    # Strength must be at least one of acceptable with no unacceptable strengths
    Strengths := ConvertToSet(Policy.GrantControls.AuthenticationStrength.AllowedCombinations)
    AcceptableMFA := {"windowsHelloForBusiness", "fido2", "x509CertificateMultiFactor"}
    Count(Strengths - AcceptableMFA) == 0
    Count(Strengths) > 0
} else := false

# Returns true if the policy enforces general MFA (either through built-in controls
# or authentication strength that includes MFA methods)
IsGeneralMFA(Policy) := true if {
    # Check for traditional MFA built-in control
    "mfa" in Policy.GrantControls.BuiltInControls
} else := true if {
    # Check for authentication strength that includes MFA methods
    Strengths := ConvertToSet(Policy.GrantControls.AuthenticationStrength.AllowedCombinations)
    # Check if any of the allowed combinations contain MFA methods
    # This includes combinations like "password, microsoftAuthenticatorPush", "password, softwareOath", etc.
    MFACombinations := {
        "windowsHelloForBusiness",
        "fido2", 
        "x509CertificateMultiFactor",
        "deviceBasedPush",
        "temporaryAccessPassOneTime",
        "temporaryAccessPassMultiUse",
        "password, microsoftAuthenticatorPush",
        "password, softwareOath",
        "password, hardwareOath", 
        "password, sms",
        "password, voice",
        "federatedMultiFactor",
        "microsoftAuthenticatorPush, federatedSingleFactor",
        "softwareOath, federatedSingleFactor",
        "hardwareOath, federatedSingleFactor",
        "sms, federatedSingleFactor",
        "voice, federatedSingleFactor"
    }
    Count(Strengths & MFACombinations) > 0
} else := false


############################################################################
# Report formatting functions for MS.AAD.6.1v1                             #
############################################################################

FederatedDomainWarningString := concat(" ", [
    "ScubaGear is unable to read the user password expiration settings for federated",
    "domains because it is controlled in a system external to the tenant.",
    "Check with your identity provider on how to configure this policy in a federated context.",
])

FailureString := "domain(s) failed"

FederatedDomainWarning(domains) := concat("<br/><br/>", [
    ReportFullDetailsArray(domains, "federated domain(s) present"),
    FederatedDomainWarningString
])

# Case 1: Pass; all valid domains, no federated domains
# Case 2: Pass; all valid domains, federated domains
# Case 3: Fail; invalid domains exist, no federated domains
# Case 4: Fail; invalid domains exist, federated domains
# Default: Fail

DomainReportDetails(Status, Metadata) := PASS if {
    Status == true
    Count(Metadata.FederatedDomains) == 0
} else := Description if {
    Status == true
    Count(Metadata.FederatedDomains) > 0
    Description := concat("", [
        PASS, 
        "; however, there are ", 
        FederatedDomainWarning(Metadata.FederatedDomains)
    ])
} else := Description if {
    Status == false
    Count(Metadata.InvalidDomains) > 0
    Count(Metadata.FederatedDomains) == 0
    Description := ReportFullDetailsArray(Metadata.InvalidDomains, FailureString)
} else := Description if {
    Status == false
    Count(Metadata.InvalidDomains) > 0
    Count(Metadata.FederatedDomains) > 0
    Description := concat("<br/><br/>", [
        ReportFullDetailsArray(Metadata.InvalidDomains, FailureString),
        FederatedDomainWarning(Metadata.FederatedDomains)
    ])
} else := FAIL
