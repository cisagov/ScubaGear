package powerbi_test
import rego.v1
import data.powerbi
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS

#
# Policy MS.POWERBI.5.1v1
#--
test_ResourceKey_Correct if {
    Output := powerbi.tests with input.resource_key_setting as [ResourceKey]

    TestResult("MS.POWERBI.5.1v1", Output, PASS, true) == true
}

test_ResourceKey_Incorrect if {
    Setting := json.patch(ResourceKey, [{"op": "add", "path": "enabled", "value": false}])

    Output := powerbi.tests with input.resource_key_setting as [Setting]

    TestResult("MS.POWERBI.5.1v1", Output, FAIL, false) == true
}

test_ResourceKey_Empty if {
    Output := powerbi.tests with input.resource_key_setting as []

    TestResult("MS.POWERBI.5.1v1", Output, "PowerShell Error", false) == true
}
#--
