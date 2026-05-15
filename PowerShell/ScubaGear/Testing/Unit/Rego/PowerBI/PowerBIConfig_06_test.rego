package powerbi_test
import rego.v1
import data.powerbi
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS

#
# Policy MS.POWERBI.6.1v1
#--
test_RScript_Correct if {
    Output := powerbi.tests with input.rscript_setting as [RScript]

    TestResult("MS.POWERBI.6.1v1", Output, PASS, true) == true
}

test_RScript_Incorrect if {
    Setting := json.patch(RScript, [{"op": "add", "path": "enabled", "value": true}])

    Output := powerbi.tests with input.rscript_setting as [Setting]

    TestResult("MS.POWERBI.6.1v1", Output, FAIL, false) == true
}

test_RScript_Empty if {
    Output := powerbi.tests with input.rscript_setting as []

    TestResult("MS.POWERBI.6.1v1", Output, "PowerShell Error", false) == true
}
#--
