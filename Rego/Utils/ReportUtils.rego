package report.utils
import future.keywords

#
default BaselineVersion := "main"

BaselineVersion := input.module_version

# baselineVersion := "3.0.0." # Baseline version is pinned to a module version
ScubaBaseUrl := sprintf("https://github.com/cisagov/ScubaGear/blob/v%v/baselines/", [BaselineVersion])

################
# Helper functions for this file
################

PolicyAnchor(PolicyId) := sprintf("#%v", [replace(lower(PolicyId), ".", "")])

PolicyProduct(PolicyId) := product if {
    dotIndexes := indexof_n(PolicyId, ".")
    product := lower(substring(PolicyId, 3, dotIndexes[1]-dotIndexes[0]-1))
}

PolicyLink(PolicyId) := sprintf("<a href=\"%v%v.md%v\" target=\"_blank\">Secure Configuration Baseline policy</a>", [ScubaBaseUrl, PolicyProduct(PolicyId), PolicyAnchor(PolicyId)])


################
# The report formatting functions below are generic and used throughout the policies #
################

#
NotCheckedDetails(PolicyId) := details if {
    link := PolicyLink(PolicyId)
    details := sprintf("Not currently checked automatically. See %v for instructions on manual check", [link])
}

DefenderMirrorDetails(PolicyId) := details if {
    link := PolicyLink(PolicyId)
    details := sprintf("A custom product can be used to fulfill this policy requirement. Use a 3rd party assessment tool or manually review to ensure compliance. See %v for instructions on manual check. If you are using Defender for Office 365 to implement this policy, ensure that you are running ScubaGear with defender included in the ProductNames parameter for an automated check. Then, review the corresponding Defender for Office 365 policy that fulfills the requirements of this EXO policy.", [link])
}

#
Format(Array) := format_int(count(Array), 10)

#
ReportDetailsBoolean(true) := "Requirement met"
ReportDetailsBoolean(false) := "Requirement not met"

#
Description(String1, String2, String3) := trim(concat(" ", [String1, concat(" ", [String2, String3])]), " ")

#
ReportDetailsString(Status, String) :=  Detail if {
    Status == true
    Detail := "Requirement met"
}
ReportDetailsString(Status, String) :=  Detail if {
    Status == false
    Detail := String
}
