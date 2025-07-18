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
    # Set "federated.domain.com" (index 5 in DomainSettings base configuration) to false to skip federated domain warning
    Settings := json.patch(DomainSettings, [
        {"op": "add", "path": "5/IsVerified", "value": false}
    ])
    Output := aad.tests with input.domain_settings as Settings

    TestResult("MS.AAD.6.1v1", Output, PASS, true) == true
}

test_PasswordValidityPeriodInDays_Incorrect if {
    # Set "federated.domain.com" (index 5 in DomainSettings base configuration) to false to skip federated domain warning
    Settings := json.patch(DomainSettings, [
        {"op": "add", "path": "0/PasswordValidityPeriodInDays", "value": null},
        {"op": "add", "path": "5/IsVerified", "value": false}
    ])

    Output := aad.tests with input.domain_settings as Settings

    ReportDetailString := "2 domain(s) failed:<br/>root1.com, sub.root1.com"
    TestResult("MS.AAD.6.1v1", Output, ReportDetailString, false) == true
}

test_IsVerified_Correct if {
    # Set "federated.domain.com" (index 5 in DomainSettings base configuration) to false to skip federated domain warning
    Settings := json.patch(DomainSettings, [
        {"op": "add", "path": "5/IsVerified", "value": false}
    ])
    Output := aad.tests with input.domain_settings as Settings

    TestResult("MS.AAD.6.1v1", Output, PASS, true) == true
}

test_AuthenticationType_Correct if {
    Output := aad.tests with input.domain_settings as DomainSettings

    ReportDetailString := concat(" ", [
        "Requirement met; however, there are",
        FederatedDomainWarning(["federated.domain.com"])
    ])
    TestResult("MS.AAD.6.1v1", Output, ReportDetailString, true) == true
}

test_PasswordValidityPeriodInDays_ExcludeFederatedDomains_Incorrect if {
    Settings := json.patch(DomainSettings, [
        {"op": "add", "path": "0/PasswordValidityPeriodInDays", "value": null},
        {"op": "add", "path": "1/AuthenticationType", "value": "Federated"},
        {"op": "add", "path": "3/AuthenticationType", "value": "Federated"},
    ])

    Output := aad.tests with input.domain_settings as Settings

    ReportDetailString := concat("<br/>", [
        "2 domain(s) failed:<br/>root1.com, sub.root1.com<br/>",
        FederatedDomainWarning(["federated.domain.com", "root2.com", "sub.root2.com"])
    ])
    TestResult("MS.AAD.6.1v1", Output, ReportDetailString, false) == true
}
#--