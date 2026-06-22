package utils.securitysuite

import data.utils.key.FAIL
import data.utils.report.ReportDetailsString
import rego.v1

#############
# Constants #
#############

DEFLICENSEWARNSTR := concat(" ", [
    "**NOTE: Either you do not have sufficient permissions or",
    "your tenant does not have a license for Microsoft Defender",
    "for Office 365 Plan 1 or Plan 2, which is required for this feature.**"
])

DLPLICENSEWARNSTR := concat(" ", [
    "**NOTE: Either you do not have sufficient permissions or",
    "your tenant does not have a license for Microsoft Purview",
    "Data Loss Prevention, which is required for this feature.",
    "This feature is included in E3/G3/E5/G5 licenses.**"
])
#################################################################################
# Report Detail Functions for check that required Defender license #
#################################################################################
# If a defender license is present, don't apply the warning
# and leave the message unchanged
ApplyLicenseWarningString(Status, String) := ReportDetailsString(Status, String) if {
    input.defender_license == true
}

ApplyLicenseWarningString(_, _) := concat(" ", [FAIL, DEFLICENSEWARNSTR]) if {
    input.defender_license == false
}

DLPLicenseWarningString(Status, String) := ReportDetailsString(Status, String) if {
    input.defender_dlp_license == true
}

DLPLicenseWarningString(_, _) := concat(" ", [FAIL, DLPLICENSEWARNSTR]) if {
    input.defender_dlp_license == false
}