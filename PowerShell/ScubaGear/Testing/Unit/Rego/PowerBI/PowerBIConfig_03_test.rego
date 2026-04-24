package powerbi_test
import rego.v1
import data.powerbi
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS
import data.utils.powerbi.PBILICENSEWARNSTR

#
# Policy MS.POWERBI.3.1v1
#--
test_ExternalSharing_Correct if {
    Output := powerbi.tests with input.external_sharing_setting as [ExternalSharing]
                            with input.powerbi_license as PowerBILicense

    TestResult("MS.POWERBI.3.1v1", Output, PASS, true) == true
}

test_ExternalSharing_Incorrect if {
    Setting := json.patch(ExternalSharing, [{"op": "add", "path": "enabled", "value": true}])

    Output := powerbi.tests with input.external_sharing_setting as [Setting]
                            with input.powerbi_license as PowerBILicense

    TestResult("MS.POWERBI.3.1v1", Output, FAIL, false) == true
}

test_ExternalSharing_Empty if {
    Output := powerbi.tests with input.external_sharing_setting as []
                            with input.powerbi_license as PowerBILicense

    TestResult("MS.POWERBI.3.1v1", Output, "PowerShell Error", false) == true
}

test_ExternalSharing_NoLicense if {
    Output := powerbi.tests with input.external_sharing_setting as [ExternalSharing]
                            with input.powerbi_license as false

    TestResult("MS.POWERBI.3.1v1", Output, PBILICENSEWARNSTR, true) == true
}
#--
