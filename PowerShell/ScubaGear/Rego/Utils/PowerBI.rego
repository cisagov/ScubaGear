package utils.powerbi

import data.utils.key.FAIL
import data.utils.report.ReportDetailsBoolean
import data.utils.report.ReportDetailsString
import rego.v1

# License warning string
PBILICENSEWARNSTR :=
    "**NOTE: Your tenant does not have a license for Power BI, which is required for this feature**"

#############################################
# Power BI Report Details License Functions #
#############################################

# If a Power BI license is present, return normal boolean result
ApplyLicenseWarning(Status) := ReportDetailsBoolean(Status) if {
    input.powerbi_license == true
}

# If no license, return failure with warning
ApplyLicenseWarning(_) := PBILICENSEWARNSTR if {
    input.powerbi_license == false
}

# String variant for policies with custom error messages
ApplyLicenseWarningString(Status, String) := ReportDetailsString(Status, String) if {
    input.powerbi_license == true
}

ApplyLicenseWarningString(_, _) := PBILICENSEWARNSTR if {
    input.powerbi_license == false
}
