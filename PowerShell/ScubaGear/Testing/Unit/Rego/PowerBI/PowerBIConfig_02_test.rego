package powerbi_test
import rego.v1
import data.powerbi
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS

#
# Policy MS.POWERBI.2.1v1
#--
test_GuestAccess_Correct if {
    Output := powerbi.tests with input.guest_access_setting as [GuestAccess]

    TestResult("MS.POWERBI.2.1v1", Output, PASS, true) == true
}

test_GuestAccess_Incorrect if {
    Setting := json.patch(GuestAccess, [{"op": "add", "path": "enabled", "value": true}])

    Output := powerbi.tests with input.guest_access_setting as [Setting]

    TestResult("MS.POWERBI.2.1v1", Output, FAIL, false) == true
}

test_GuestAccess_Empty if {
    Output := powerbi.tests with input.guest_access_setting as []

    TestResult("MS.POWERBI.2.1v1", Output, "PowerShell Error", false) == true
}
#--
