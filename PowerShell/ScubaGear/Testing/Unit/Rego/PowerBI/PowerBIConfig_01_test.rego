package powerbi_test
import rego.v1
import data.powerbi
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS

#
# Policy MS.POWERBI.1.1v1
#--
test_PublishToWeb_Correct if {
    Output := powerbi.tests with input.publish_to_web_setting as [PublishToWeb]

    TestResult("MS.POWERBI.1.1v1", Output, PASS, true) == true
}

test_PublishToWeb_Incorrect if {
    Setting := json.patch(PublishToWeb, [{"op": "add", "path": "enabled", "value": true}])

    Output := powerbi.tests with input.publish_to_web_setting as [Setting]

    TestResult("MS.POWERBI.1.1v1", Output, FAIL, false) == true
}

test_PublishToWeb_Empty if {
    Output := powerbi.tests with input.publish_to_web_setting as []

    TestResult("MS.POWERBI.1.1v1", Output, "PowerShell Error", false) == true
}
#--
