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

PolicyLink(PolicyId) := sprintf("<a href=\"%v%v.md%v\" target=\"_blank\">Secure Configuration Baseline policy</a>", [SCUBABASEURL, PolicyProduct(PolicyId), PolicyAnchor(PolicyId)])

###############################
# Generic Reporting Functions #
###############################

# Not Implemented Report methods
NotCheckedDetails(PolicyId) := Details if {
    Link := PolicyLink(PolicyId)
    Details := sprintf("Not currently checked automatically. See %v for instructions on manual check", [Link])
}

DefenderMirrorDetails(PolicyId) := Details if {
    Link := PolicyLink(PolicyId)
    String := [
        "A custom product can be used to fulfill this policy requirement.",
        "If custom product is used, a 3rd party assessment tool or manually review is needed to ensure compliance.",
        "See %v for instructions on manual check.",
        "If you are using Defender for Office 365 to implement this policy,",
        "ensure that when running ScubaGear defender is in the ProductNames parameter.",
        "Then, review the corresponding Defender for Office 365 policy that fulfills the requirements of this EXO policy."
    ]

    Details := sprintf(concat(" ", String), [Link])
}

# Returns string representation of number in base 10
FormatArray(Array) := format_int(count(Array), 10)

# Reporting methods passed Status
ReportDetailsBoolean(true) := "Requirement met"

ReportDetailsBoolean(false) := "Requirement not met"

# Trims the trailing whitespaces on array concatination
Description(Array) := trim(concat(" ", Array), " ")

# Returns specified string if Status is false (good for error msg)
ReportDetailsString(true, _) := ReportDetailsBoolean(true) if {}

ReportDetailsString(false, String) := String if {}
