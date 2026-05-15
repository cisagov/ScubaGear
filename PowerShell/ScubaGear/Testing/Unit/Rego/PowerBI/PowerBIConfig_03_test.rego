package powerbi_test
import rego.v1
import data.powerbi
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS

#
# Policy MS.POWERBI.3.1v1
#--
test_ExternalSharing_Correct if {
    Output := powerbi.tests with input.external_sharing_setting as [ExternalSharing]

    TestResult("MS.POWERBI.3.1v1", Output, PASS, true) == true
}

test_ExternalSharing_Incorrect if {
    Setting := json.patch(ExternalSharing, [{"op": "add", "path": "enabled", "value": true}])

    Output := powerbi.tests with input.external_sharing_setting as [Setting]

    TestResult("MS.POWERBI.3.1v1", Output, FAIL, false) == true
}

test_ExternalSharing_Empty if {
    Output := powerbi.tests with input.external_sharing_setting as []

    TestResult("MS.POWERBI.3.1v1", Output, "PowerShell Error", false) == true
}
#--
