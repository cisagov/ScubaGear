package aad_test
import rego.v1
import data.aad
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.AAD.6.1v1
#--

test_PasswordValidityPeriodInDays_Correct if {
    Output := aad.tests with input.domain_settings as DomainSettings

    TestResult("MS.AAD.6.1v1", Output, PASS, true) == true
}

test_PasswordValidityPeriodInDays_Incorrect if {
    Settings := json.patch(DomainSettings,
                [{"op": "add", "path": "0/PasswordValidityPeriodInDays", "value": 0},
                {"op": "add", "path": "1/PasswordValidityPeriodInDays", "value": 0}])

    Output := aad.tests with input.domain_settings as Settings

    ReportDetailString := "2 domain(s) failed:<br/>test.url.com, test1.url.com"
    TestResult("MS.AAD.6.1v1", Output, ReportDetailString, false) == true
}

test_IsVerified_Correct if {
    Settings := json.patch(DomainSettings,
                [{"op": "add", "path": "0/IsVerified", "value": null},
                {"op": "add", "path": "1/IsVerified", "value": false},
                {"op": "add", "path": "0/PasswordValidityPeriodInDays", "value": 0},
                {"op": "add", "path": "1/PasswordValidityPeriodInDays", "value": 0}])

    Output := aad.tests with input.domain_settings as Settings

    TestResult("MS.AAD.6.1v1", Output, PASS, true) == true
}
#--