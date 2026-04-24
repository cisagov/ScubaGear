package powerbi_test
import rego.v1
import data.powerbi
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS
import data.utils.powerbi.PBILICENSEWARNSTR

#
# Policy MS.POWERBI.6.1v1
#--
test_RScript_Correct if {
    Output := powerbi.tests with input.rscript_setting as [RScript]
                            with input.powerbi_license as PowerBILicense

    TestResult("MS.POWERBI.6.1v1", Output, PASS, true) == true
}

test_RScript_Incorrect if {
    Setting := json.patch(RScript, [{"op": "add", "path": "enabled", "value": true}])

    Output := powerbi.tests with input.rscript_setting as [Setting]
                            with input.powerbi_license as PowerBILicense

    TestResult("MS.POWERBI.6.1v1", Output, FAIL, false) == true
}

test_RScript_Empty if {
    Output := powerbi.tests with input.rscript_setting as []
                            with input.powerbi_license as PowerBILicense

    TestResult("MS.POWERBI.6.1v1", Output, "PowerShell Error", false) == true
}

test_RScript_NoLicense if {
    Output := powerbi.tests with input.rscript_setting as [RScript]
                            with input.powerbi_license as false

    TestResult("MS.POWERBI.6.1v1", Output, PBILICENSEWARNSTR, true) == true
}
#--
