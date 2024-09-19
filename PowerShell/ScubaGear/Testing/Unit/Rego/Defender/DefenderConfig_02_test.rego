package defender_test
import rego.v1
import data.defender
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.DEFENDER.2.1v1
#--
test_TargetedUsers_Correct_V1 if {
    Output := defender.tests with input.anti_phish_policies as AntiPhishPolicies
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    TestResult("MS.DEFENDER.2.1v1", Output, PASS, true) == true
}

test_TargetedUsers_Correct_V2 if {
    Output := defender.tests with input.anti_phish_policies as AntiPhishPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.2.1v1"].SensitiveUsers as ["John Doe;jdoe@someemail.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.2.1v1", Output, PASS, true) == true
}

test_TargetedUsers_Correct_V3 if {
    Output := defender.tests with input.anti_phish_policies as AntiPhishPolicies
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    TestResult("MS.DEFENDER.2.1v1", Output, PASS, true) == true
}

test_TargetedUsers_Incorrect_V1 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "remove", "path": "0"}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := "Not all sensitive users are included for targeted protection in Standard policy."
    TestResult("MS.DEFENDER.2.1v1", Output, ReportDetailString, false) == true
}

test_TargetedUsers_Incorrect_V2 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "remove", "path": "1"}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := "Not all sensitive users are included for targeted protection in Strict policy."
    TestResult("MS.DEFENDER.2.1v1", Output, ReportDetailString, false) == true
}

test_TargetedUsers_Incorrect_V3 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "remove", "path": "1"},
                            {"op": "add", "path": "0/Identity", "value": "Some Preset Security Policy1659535429826"}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := "Not all sensitive users are included for targeted protection in Strict or Standard policy."
    TestResult("MS.DEFENDER.2.1v1", Output, ReportDetailString, false) == true
}

test_TargetedUsers_Incorrect_V4 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "add", "path": "0/Enabled", "value": false}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := "Not all sensitive users are included for targeted protection in Standard policy."
    TestResult("MS.DEFENDER.2.1v1", Output, ReportDetailString, false) == true
}

test_TargetedUsers_Incorrect_V5 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "add", "path": "0/EnableTargetedUserProtection", "value": false}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := "Not all sensitive users are included for targeted protection in Standard policy."
    TestResult("MS.DEFENDER.2.1v1", Output, ReportDetailString, false) == true
}

test_TargetedUsers_Incorrect_V6 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "remove", "path": "1/TargetedUsersToProtect/1"}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := "Not all sensitive users are included for targeted protection in Strict policy."
    TestResult("MS.DEFENDER.2.1v1", Output, ReportDetailString, false) == true
}

test_TargetedUsers_Incorrect_V7 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "remove", "path": "1/TargetedUsersToProtect/1"}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as false

    ReportDetailString := concat(" ", [
        "Requirement not met **NOTE: Either you do not have sufficient permissions or",
        "your tenant does not have a license for Microsoft Defender",
        "for Office 365 Plan 1 or Plan 2, which is required for this feature.**"
    ])
    TestResult("MS.DEFENDER.2.1v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.DEFENDER.2.2v1
#--
test_AgencyDomains_Correct_V1 if {
    Output := defender.tests with input.anti_phish_policies as AntiPhishPolicies
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    TestResult("MS.DEFENDER.2.2v1", Output, PASS, true) == true
}

test_AgencyDomains_Correct_V2 if {
    Output := defender.tests with input.anti_phish_policies as AntiPhishPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.2.2v1"].AgencyDomains as ["random.mail.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.2.2v1", Output, PASS, true) == true
}

test_AgencyDomains_Incorrect_V1 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "remove", "path": "0"}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := "Not all agency domains are included for targeted protection in Standard policy."
    TestResult("MS.DEFENDER.2.2v1", Output, ReportDetailString, false) == true
}

test_AgencyDomains_Incorrect_V2 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "remove", "path": "1"}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := "Not all agency domains are included for targeted protection in Strict policy."
    TestResult("MS.DEFENDER.2.2v1", Output, ReportDetailString, false) == true
}

test_AgencyDomains_Incorrect_V3 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "remove", "path": "1"},
                            {"op": "add", "path": "0/Identity", "value": "Some Preset Security Policy1659535429826"}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := "Not all agency domains are included for targeted protection in Strict or Standard policy."
    TestResult("MS.DEFENDER.2.2v1", Output, ReportDetailString, false) == true
}

test_AgencyDomains_Incorrect_V4 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "add", "path": "0/Enabled", "value": false}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := "Not all agency domains are included for targeted protection in Standard policy."
    TestResult("MS.DEFENDER.2.2v1", Output, ReportDetailString, false) == true
}

test_AgencyDomains_Incorrect_V5 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "add", "path": "0/EnableTargetedDomainsProtection", "value": false}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := "Not all agency domains are included for targeted protection in Standard policy."
    TestResult("MS.DEFENDER.2.2v1", Output, ReportDetailString, false) == true
}

test_AgencyDomains_Incorrect_V6 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "remove", "path": "1/TargetedDomainsToProtect/1"}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := "Not all agency domains are included for targeted protection in Strict policy."
    TestResult("MS.DEFENDER.2.2v1", Output, ReportDetailString, false) == true
}

test_AgencyDomains_Incorrect_V7 if {
    Output := defender.tests with input.anti_phish_policies as AntiPhishPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.2.2v1"] as {}
                            with input.defender_license as true

    ReportDetailString := "Not all agency domains are included for targeted protection in Strict or Standard policy."
    TestResult("MS.DEFENDER.2.2v1", Output, ReportDetailString, false) == true
}

test_AgencyDomains_Incorrect_V8 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "add", "path": "0/TargetedDomainsToProtect", "value": null},
                            {"op": "add", "path": "1/TargetedDomainsToProtect", "value": null}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.2.2v1"] as {}
                            with input.defender_license as true

    ReportDetailString := concat(" ", [
        "No agency domains defined for impersonation protection assessment.",
        "See configuration file documentation for details on how to define."
    ])
    TestResult("MS.DEFENDER.2.2v1", Output, ReportDetailString, false) == true
}

test_AgencyDomains_Incorrect_V9 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "add", "path": "0/TargetedDomainsToProtect", "value": null},
                            {"op": "add", "path": "1/TargetedDomainsToProtect", "value": null}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.2.2v1"] as {}
                            with input.defender_license as false

    ReportDetailString := concat(" ", [
        "Requirement not met **NOTE: Either you do not have sufficient permissions or",
        "your tenant does not have a license for Microsoft Defender",
        "for Office 365 Plan 1 or Plan 2, which is required for this feature.**"
    ])
    TestResult("MS.DEFENDER.2.2v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.DEFENDER.2.3v1
#--
test_CustomDomains_Correct_V1 if {
    Output := defender.tests with input.anti_phish_policies as AntiPhishPolicies
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    TestResult("MS.DEFENDER.2.3v1", Output, PASS, true) == true
}

test_CustomDomains_Correct_V2 if {
    Output := defender.tests with input.anti_phish_policies as AntiPhishPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.2.3v1"].PartnerDomains as ["random.mail.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.2.3v1", Output, PASS, true) == true
}

test_CustomDomains_Correct_V3 if {
    Output := defender.tests with input.anti_phish_policies as AntiPhishPolicies
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    TestResult("MS.DEFENDER.2.3v1", Output, PASS, true) == true
}

test_CustomDomains_Correct_V4 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "add", "path": "0/TargetedDomainsToProtect", "value": null},
                            {"op": "add", "path": "1/TargetedDomainsToProtect", "value": null}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.2.3v1"] as {}
                            with input.defender_license as true

    TestResult("MS.DEFENDER.2.3v1", Output, PASS, true) == true
}

test_CustomDomains_Incorrect_V1 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "remove", "path": "0", "value": null}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := "Not all partner domains are included for targeted protection in Standard policy."
    TestResult("MS.DEFENDER.2.3v1", Output, ReportDetailString, false) == true
}

test_CustomDomains_Incorrect_V2 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "remove", "path": "1", "value": null}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := "Not all partner domains are included for targeted protection in Strict policy."
    TestResult("MS.DEFENDER.2.3v1", Output, ReportDetailString, false) == true
}

test_CustomDomains_Incorrect_V3 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "add", "path": "1/Identity", "value": "Some Preset Security Policy1659535429826"},
                                                {"op": "remove", "path": "0", "value": null}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := "Not all partner domains are included for targeted protection in Strict or Standard policy."
    TestResult("MS.DEFENDER.2.3v1", Output, ReportDetailString, false) == true
}

test_CustomDomains_Incorrect_V4 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "add", "path": "0/Enabled", "value": false}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := "Not all partner domains are included for targeted protection in Standard policy."
    TestResult("MS.DEFENDER.2.3v1", Output, ReportDetailString, false) == true
}

test_CustomDomains_Incorrect_V5 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "add", "path": "0/EnableTargetedDomainsProtection", "value": false}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := "Not all partner domains are included for targeted protection in Standard policy."
    TestResult("MS.DEFENDER.2.3v1", Output, ReportDetailString, false) == true
}

test_CustomDomains_Incorrect_V6 if {
    AntiPhish := json.patch(AntiPhishPolicies, [{"op": "remove", "path": "1/TargetedDomainsToProtect/1"}])
    Output := defender.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := "Not all partner domains are included for targeted protection in Strict policy."
    TestResult("MS.DEFENDER.2.3v1", Output, ReportDetailString, false) == true
}

test_CustomDomains_Incorrect_V7 if {
    Output := defender.tests with input.anti_phish_policies as AntiPhishPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.2.3v1"] as {}
                            with input.defender_license as true

    ReportDetailString := "Not all partner domains are included for targeted protection in Strict or Standard policy."
    TestResult("MS.DEFENDER.2.3v1", Output, ReportDetailString, false) == true
}

test_CustomDomains_Incorrect_V8 if {
    Output := defender.tests with input.anti_phish_policies as AntiPhishPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.2.3v1"] as {}
                            with input.defender_license as false

    ReportDetailString := concat(" ", [
        "Requirement not met **NOTE: Either you do not have sufficient permissions or",
        "your tenant does not have a license for Microsoft Defender",
        "for Office 365 Plan 1 or Plan 2, which is required for this feature.**"
    ])
    TestResult("MS.DEFENDER.2.3v1", Output, ReportDetailString, false) == true

}
#--
