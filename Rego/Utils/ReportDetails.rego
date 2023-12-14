package utils.report
import future.keywords


#############
# Constants #
#############

default BASELINEVERSION := "main"

BASELINEVERSION := input.module_version

SCUBABASEURL := sprintf("https://github.com/cisagov/ScubaGear/blob/%v/baselines/", [BASELINEVERSION])


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
NotCheckedDetails(PolicyId) := Details if {
    Details := sprintf(
        "Not currently checked automatically. See %v for instructions on manual check",
        [PolicyLink(PolicyId)]
    )
}

# 3rd Party Not Implemented Report Details method
DefenderMirrorDetails(PolicyId) := Details if {
    Details := sprintf(
        concat(" ", [
        "A custom product can be used to fulfill this policy requirement.",
        "If custom product is used, a 3rd party assessment tool or manually review is needed to ensure compliance.",
        "See %v for instructions on manual check.",
        "If you are using Defender for Office 365 to implement this policy,",
        "ensure that when running ScubaGear defender is in the ProductNames parameter.",
        "Then, review the corresponding Defender for Office 365 policy that fulfills",
        "the requirements of this policy."
        ]),
        [PolicyLink(PolicyId)]
    )
}

# Reporting methods passed Status
ReportDetailsBoolean(true) := "Requirement met"

ReportDetailsBoolean(false) := "Requirement not met"

# Returns specified string if Status is false (good for error msg)
ReportDetailsString(true, _) := ReportDetailsBoolean(true) if {}

ReportDetailsString(false, String) := String if {}

# Returns string constructed from array if Status is false (good for error msg)
ReportDetailsArray(true, _, _) := ReportDetailsBoolean(true) if {}

ReportDetailsArray(false, Array, String) := Description([
    ArraySizeStr(Array),
    String,
    concat(", ", Array)]) if {}

# Returns string constructed from array if Status is false (good for error msg)
#
ReportDetailsArrayOutOf(true, _, _) := ReportDetailsBoolean(true) if {}

ReportDetailsArrayOutOf(false, NumeratorArr, DenominatorArr) := Description([
    concat(" of ", [ArraySizeStr(NumeratorArr), ArraySizeStr(DenominatorArr)]),
    "agency domain(s) found in violation:",
    concat(", ", NumeratorArr)
]) if {}


################################################
# Help Methods For Generic Reporting Functions #
################################################

# Returns string representation of number in base 10
ArraySizeStr(Array) := format_int(count(Array), 10)

# Trims the trailing whitespaces on array concatination
Description(Array) := trim(concat(" ", Array), " ")