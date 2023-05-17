package report.utils
import future.keywords

#
baselineVersion() := moduleVersion if {
    not input.module_version
    moduleVersion := "main" 
}

baselineVersion() := moduleVersion if {
    moduleVersion := input.module_version
}

#baselineVersion := "3.0.0." # Baseline version is pinned to a module version
scubaBaseUrl := sprintf("https://github.com/cisagov/ScubaGear/blob/%v/baselines/", [baselineVersion()])

################
# Helper functions for this file
################

policyAnchor(PolicyId) := anchor if {
    anchor := sprintf("#%v", [replace(lower(PolicyId), ".", "")])
}

policyProduct(PolicyId) := product if {
    dotIndexes := indexof_n(PolicyId, ".")
    product := lower(substring(PolicyId, 3, dotIndexes[1]-dotIndexes[0]-1))
}

policyLink(PolicyId) := link if {
    link := sprintf("<a href=\"%v%v.md%v\" target=\"_blank\">Secure Configuration Baseline policy</a>", [scubaBaseUrl, policyProduct(PolicyId), policyAnchor(PolicyId)])
}

################
# The report formatting functions below are generic and used throughout the policies #
################

#
notCheckedDetails(PolicyId) := details if {
    link := policyLink(PolicyId)
    details := sprintf("Not currently checked automatically. See %v for instructions on manual check", [link])
}
 
#  
Format(Array) := format_int(count(Array), 10) 

#
ReportDetailsBoolean(Status) := "Requirement met" if {Status == true}
ReportDetailsBoolean(Status) := "Requirement not met" if {Status == false}

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