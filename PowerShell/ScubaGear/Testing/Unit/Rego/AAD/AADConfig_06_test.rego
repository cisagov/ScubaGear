package aad_test
import rego.v1
import data.aad
import data.utils.key.TestResult
import data.utils.key.PASS
import data.utils.aad.FederatedDomainWarning


#
# Policy MS.AAD.6.1v1
#--

test_PasswordValidityPeriodInDays_Correct if {
    Settings := json.patch(DomainSettings, [
        {"op": "add", "path": "4/IsVerified", "value": false}
    ])
    Output := aad.tests with input.domain_settings as Settings

    TestResult("MS.AAD.6.1v1", Output, PASS, true) == true
}

test_PasswordValidityPeriodInDays_Incorrect if {
    Settings := json.patch(DomainSettings, [
        {"op": "add", "path": "0/PasswordValidityPeriodInDays", "value": 5},
        {"op": "add", "path": "1/PasswordValidityPeriodInDays", "value": 5},
        {"op": "add", "path": "4/IsVerified", "value": false}
    ])

    Output := aad.tests with input.domain_settings as Settings

    ReportDetailString := "2 domain(s) failed:<br/>test.url.com, test1.url.com"
    TestResult("MS.AAD.6.1v1", Output, ReportDetailString, false) == true
}

test_IsVerified_Correct if {
    Settings := json.patch(DomainSettings, [
        {"op": "add", "path": "0/PasswordValidityPeriodInDays", "value": 5},
        {"op": "add", "path": "1/PasswordValidityPeriodInDays", "value": 5},
        {"op": "add", "path": "0/IsVerified", "value": null},
        {"op": "add", "path": "1/IsVerified", "value": false},
        {"op": "add", "path": "2/IsVerified", "value": false},
        {"op": "add", "path": "4/IsVerified", "value": false}
    ])

    Output := aad.tests with input.domain_settings as Settings

    TestResult("MS.AAD.6.1v1", Output, PASS, true) == true
}

test_AuthenticationType_Correct if {
    Settings := json.patch(DomainSettings, [
        {"op": "add", "path": "0/AuthenticationType", "value": "Federated"},
        {"op": "add", "path": "1/AuthenticationType", "value": "Federated"},
        {"op": "add", "path": "2/AuthenticationType", "value": "Federated"},
        {"op": "add", "path": "1/IsVerified", "value": false}
    ])

    Output := aad.tests with input.domain_settings as Settings

    ReportDetailString := concat(" ", [
        "Requirement met; however, there are",
        FederatedDomainWarning(["test.url.com", "test2.url.com", "test4.url.com"])
    ])
    TestResult("MS.AAD.6.1v1", Output, ReportDetailString, true) == true
}

test_PasswordValidityPeriodInDays__ExcludeFederatedDomains_Incorrect if {
    Settings := json.patch(DomainSettings, [
        {"op": "add", "path": "0/PasswordValidityPeriodInDays", "value": 5},
        {"op": "add", "path": "1/AuthenticationType", "value": "Federated"},
        {"op": "add", "path": "2/AuthenticationType", "value": "Federated"},
        {"op": "add", "path": "3/AuthenticationType", "value": "Federated"},
        {"op": "add", "path": "1/IsVerified", "value": false},
        {"op": "add", "path": "4/IsVerified", "value": false}
    ])

    Output := aad.tests with input.domain_settings as Settings

    ReportDetailString := concat("<br/>", [
        "1 domain(s) failed:<br/>test.url.com<br/>",
        FederatedDomainWarning(["test2.url.com", "test3.url.com"])
    ])
    TestResult("MS.AAD.6.1v1", Output, ReportDetailString, false) == true
}
#--