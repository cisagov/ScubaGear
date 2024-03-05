package utils.report
import rego.v1
import data.utils.key.PASS


#############
# Constants #
#############

default BASELINEVERSION := "main"

BASELINEVERSION := input.module_version

# regal ignore:line-length
SCUBABASEURL := sprintf("https://github.com/cisagov/ScubaGear/blob/v%v/PowerShell/ScubaGear/baselines/", [BASELINEVERSION])

########################
# Not Implemented Link #
########################

PolicyAnchor(PolicyId) := sprintf("#%v", [replace(lower(PolicyId), ".", "")])

PolicyProduct(PolicyId) := Product if {
    DotIndexes := indexof_n(PolicyId, ".")
    Product := lower(substring(PolicyId, 3, (DotIndexes[1] - DotIndexes[0]) - 1))
}

PolicyLink(PolicyId) := sprintf(
    "<a href=\"%v%v.md%v\" target=\"_blank\">Secure Configuration Baseline policy</a>",
    [SCUBABASEURL, PolicyProduct(PolicyId), PolicyAnchor(PolicyId)]
)


###############################
# Generic Reporting Functions #
###############################

# Not Implemented Report Details methods
NotCheckedDetails(PolicyId) := sprintf(
    concat(" ", [
    "This product does not currently have the capability to check compliance for this policy.",
    "See %v for instructions on manual check"
    ]),
    [PolicyLink(PolicyId)]
)

# Note: Reason must include %v to reference policy in document.
CheckedSkippedDetails(PolicyId, Reason) := sprintf(
    concat(" ", [Reason]), [PolicyLink(PolicyId)]
)

# 3rd Party Report Details method
DefenderMirrorDetails(PolicyId) := sprintf(
    concat(" ", [
    "A custom product can be used to fulfill this policy requirement.",
    "If a custom product is used, a 3rd party assessment tool or manually review is needed to ensure compliance.",
    "If you are using Defender for Office 365 to implement this policy,",
    "ensure that when running ScubaGear defender is in the ProductNames parameter.",
    "Then, manually review the corresponding Defender for Office 365 policy that fulfills",
    "the requirements of this policy.",
    "See %v for instructions on manual check."
    ]),
    [PolicyLink(PolicyId)]
)

# Reporting methods passed Status
ReportDetailsBoolean(true) := "Requirement met"

ReportDetailsBoolean(false) := "Requirement not met"

# Returns specified string if Status is false (good for error msg)
ReportDetailsString(true, _) := PASS

ReportDetailsString(false, String) := String

# Returns string constructed from array if Status is false (good for error msg)
ReportDetailsArray(true, _, _) := PASS

ReportDetailsArray(false, Array, String) := Description([
    ArraySizeStr(Array),
    String,
    concat(", ", Array)
])


################################################
# Help Methods For Generic Reporting Functions #
################################################

# Returns string representation of number in base 10
ArraySizeStr(Array) := format_int(count(Array), 10)

# Trims the trailing whitespaces on array concatination
Description(Array) := trim(concat(" ", Array), " ")