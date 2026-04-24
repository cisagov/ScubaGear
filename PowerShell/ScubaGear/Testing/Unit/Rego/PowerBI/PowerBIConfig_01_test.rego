package powerbi_test
import rego.v1
import data.powerbi
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS
import data.utils.powerbi.PBILICENSEWARNSTR

#
# Policy MS.POWERBI.1.1v1
#--
test_PublishToWeb_Correct if {
    Output := powerbi.tests with input.publish_to_web_setting as [PublishToWeb]
                            with input.powerbi_license as PowerBILicense

    TestResult("MS.POWERBI.1.1v1", Output, PASS, true) == true
}

test_PublishToWeb_Incorrect if {
    Setting := json.patch(PublishToWeb, [{"op": "add", "path": "enabled", "value": true}])

    Output := powerbi.tests with input.publish_to_web_setting as [Setting]
                            with input.powerbi_license as PowerBILicense

    TestResult("MS.POWERBI.1.1v1", Output, FAIL, false) == true
}

test_PublishToWeb_Empty if {
    Output := powerbi.tests with input.publish_to_web_setting as []
                            with input.powerbi_license as PowerBILicense

    TestResult("MS.POWERBI.1.1v1", Output, "PowerShell Error", false) == true
}

test_PublishToWeb_NoLicense if {
    Output := powerbi.tests with input.publish_to_web_setting as [PublishToWeb]
                            with input.powerbi_license as false

    TestResult("MS.POWERBI.1.1v1", Output, PBILICENSEWARNSTR, true) == true
}
#--
