package report.utils
import future.keywords

#
baselineVersion := "AutoBaselineSync"
#baselineVersion := input.module_version # Baseline version is pinned to a module version
scubaBaseUrl := sprintf("https://github.com/cisagov/ScubaGear/blob/%v/baselines/", [baselineVersion])

################
# Helper functions for this file
################

policyAnchor(PolicyId) := anchor {
    anchor := sprintf("#%v", [replace(lower(PolicyId), ".", "")])
}

policyProduct(PolicyId) := product {
    dotIndexes := indexof_n(PolicyId, ".")
    product := lower(substring(PolicyId, 3, dotIndexes[1]-dotIndexes[0]-1))
}

policyLink(PolicyId) := link {

    link := sprintf("<a href=\"%v%v.md%v\" target=\"_blank\">Secure Configuration Baseline policy</a>", [scubaBaseUrl, policyProduct(PolicyId), policyAnchor(PolicyId)])
}

################
# The report formatting functions below are generic and used throughout the policies #
################

#
notCheckedDetails(PolicyId) := details {
    details := sprintf("Not currently checked automatically. See %v for instructions on manual check", [policyLink(PolicyId)])
}
 
#  
Format(Array) = format_int(count(Array), 10) 

#
ReportDetailsBoolean(Status) = "Requirement met" if {Status == true}
ReportDetailsBoolean(Status) = "Requirement not met" if {Status == false}

#
Description(String1, String2, String3) = trim(concat(" ", [String1, concat(" ", [String2, String3])]), " ")

#
ReportDetailsString(Status, String) =  Detail if {
    Status == true
    Detail := "Requirement met"
}
ReportDetailsString(Status, String) =  Detail if {
    Status == false
    Detail := String
}