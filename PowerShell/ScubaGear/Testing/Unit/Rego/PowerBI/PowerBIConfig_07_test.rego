package powerbi_test
import rego.v1
import data.powerbi
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS
import data.utils.powerbi.PBILICENSEWARNSTR

#
# Policy MS.POWERBI.7.1v1
#--
test_SensitivityLabel_Correct if {
    Output := powerbi.tests with input.sensitivity_label_setting as [SensitivityLabel]
                            with input.powerbi_license as PowerBILicense

    TestResult("MS.POWERBI.7.1v1", Output, PASS, true) == true
}

test_SensitivityLabel_Incorrect if {
    Setting := json.patch(SensitivityLabel, [{"op": "add", "path": "enabled", "value": false}])

    Output := powerbi.tests with input.sensitivity_label_setting as [Setting]
                            with input.powerbi_license as PowerBILicense

    TestResult("MS.POWERBI.7.1v1", Output, FAIL, false) == true
}

test_SensitivityLabel_Empty if {
    Output := powerbi.tests with input.sensitivity_label_setting as []
                            with input.powerbi_license as PowerBILicense

    TestResult("MS.POWERBI.7.1v1", Output, "PowerShell Error", false) == true
}

test_SensitivityLabel_NoLicense if {
    Output := powerbi.tests with input.sensitivity_label_setting as [SensitivityLabel]
                            with input.powerbi_license as false

    TestResult("MS.POWERBI.7.1v1", Output, PBILICENSEWARNSTR, true) == true
}
#--
