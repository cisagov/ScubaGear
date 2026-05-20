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
    # root1.com has an explicit expiry of 90 days (non-null, non-INT_MAX) so it fails.
    # sub.root1.com fails because its root domain fails.
    # Set "federated.domain.com" (index 5 in DomainSettings base configuration) to false to skip federated domain warning
    Settings := json.patch(DomainSettings, [
        {"op": "add", "path": "0/PasswordValidityPeriodInDays", "value": 90},
        {"op": "add", "path": "5/IsVerified", "value": false}
    ])

    Output := aad.tests with input.domain_settings as Settings

    ReportDetailString := "2 domain(s) failed:<br/>root1.com, sub.root1.com"
    TestResult("MS.AAD.6.1v1", Output, ReportDetailString, false) == true
}

test_PasswordValidityPeriodInDays_NullRootDomain_Correct if {
    # Post-Oct 2021 tenants have null for PasswordValidityPeriodInDays by default, which
    # Microsoft treats as "passwords never expire" (equivalent to INT_MAX / 2147483647).
    # root1.com and sub.root1.com must both be valid when root1.com is set to null.
    Settings := json.patch(DomainSettings, [
        {"op": "add", "path": "0/PasswordValidityPeriodInDays", "value": null},
        {"op": "add", "path": "5/IsVerified", "value": false}
    ])
    Output := aad.tests with input.domain_settings as Settings

    TestResult("MS.AAD.6.1v1", Output, PASS, true) == true
}

test_PasswordValidityPeriodInDays_AllNullRootDomains_Correct if {
    # All root domains have null PasswordValidityPeriodInDays (fully post-Oct 2021 tenant).
    # All managed, verified domains should be valid.
    Settings := json.patch(DomainSettings, [
        {"op": "add", "path": "0/PasswordValidityPeriodInDays", "value": null},
        {"op": "add", "path": "1/PasswordValidityPeriodInDays", "value": null},
        {"op": "add", "path": "5/IsVerified", "value": false}
    ])
    Output := aad.tests with input.domain_settings as Settings

    TestResult("MS.AAD.6.1v1", Output, PASS, true) == true
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
    # root1.com has an explicit expiry of 90 days so it and sub.root1.com fail.
    # root2.com and sub.root2.com become Federated and are excluded from the validity check.
    Settings := json.patch(DomainSettings, [
        {"op": "add", "path": "0/PasswordValidityPeriodInDays", "value": 90},
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