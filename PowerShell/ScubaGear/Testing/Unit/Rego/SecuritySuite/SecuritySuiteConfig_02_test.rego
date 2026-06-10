package securitysuite_test
import rego.v1
import data.securitysuite
import data.utils.key.TestResult
import data.utils.key.PASS

#
# Policy MS.SECURITYSUITE.2.1v1
#--
test_SensitiveUsers_EmptyConfig if {
    Output := securitysuite.tests with input.scuba_config as ScubaConfig
                            with input.scuba_config.SecuritySuite["MS.SECURITYSUITE.2.1v1"] as {}
                            with input.defender_license as true

    ReportDetailString := "No users defined as sensitive users in the ScubaGear config file."
    TestResult("MS.SECURITYSUITE.2.1v1", Output, ReportDetailString, false) == true
}

test_SensitiveUsers_DefenderConfigAlias if {
    Output := securitysuite.tests with input.anti_phish_policies as AntiPhishPolicies
                            with input.anti_phish_rules as AntiPhishRules
                            with input.protection_policy_rules as ProtectionPolicyRules
                            with input.accepted_domains as AcceptedDomains
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.SecuritySuite as {}
                            with input.scuba_config.Defender["MS.DEFENDER.2.1v1"].SensitiveUsers as [
                                "John Doe;jdoe@someemail.com",
                                "Jane Doe;jadoe@someemail.com"
                            ]
                            with input.defender_license as true

    TestResult("MS.SECURITYSUITE.2.1v1", Output, PASS, true) == true
}

test_SensitiveUsers_EmailOnlyConfig if {
    Output := securitysuite.tests with input.anti_phish_policies as AntiPhishPolicies
                            with input.anti_phish_rules as AntiPhishRules
                            with input.protection_policy_rules as ProtectionPolicyRules
                            with input.accepted_domains as AcceptedDomains
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.SecuritySuite["MS.SECURITYSUITE.2.1v1"].SensitiveUsers as [
                                "jdoe@someemail.com"
                            ]
                            with input.defender_license as true

    TestResult("MS.SECURITYSUITE.2.1v1", Output, PASS, true) == true
}

test_SensitiveUsers_DefaultPolicy_AllRecipients if {
    Output := securitysuite.tests with input.anti_phish_policies as [DefaultAntiPhishPolicy]
                            with input.anti_phish_rules as []
                            with input.protection_policy_rules as []
                            with input.accepted_domains as AcceptedDomains
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    TestResult("MS.SECURITYSUITE.2.1v1", Output, PASS, true) == true
}

test_SensitiveUsers_NoActionFails if {
    BadPolicy := json.patch(DefaultAntiPhishPolicy, [{"op": "replace", "path": "TargetedUserProtectionAction", "value": "NoAction"}])
    Output := securitysuite.tests with input.anti_phish_policies as [BadPolicy]
                            with input.anti_phish_rules as []
                            with input.protection_policy_rules as []
                            with input.accepted_domains as AcceptedDomains
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := "No anti-phish policy that includes all sensitive users."
    TestResult("MS.SECURITYSUITE.2.1v1", Output, ReportDetailString, false) == true
}

test_SensitiveUsers_PartialRecipientsMessage if {
    Rule := json.patch(AntiPhishRules[0], [
        {"op": "replace", "path": "AntiPhishPolicy", "value": "Custom AntiPhish"},
        {"op": "replace", "path": "RecipientDomainIs", "value": ["example.com"]}
    ])
    Output := securitysuite.tests with input.anti_phish_policies as [CustomAntiPhishPolicy]
                            with input.anti_phish_rules as [Rule]
                            with input.protection_policy_rules as []
                            with input.accepted_domains as AcceptedDomains
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := concat(" ", [
        "1 anti-phish policy found that includes all sensitive users ('Custom AntiPhish'),",
        "but not all users have been added as recipients.",
    ])
    TestResult("MS.SECURITYSUITE.2.1v1", Output, ReportDetailString, false) == true
}

test_SensitiveUsers_NoLicense if {
    Output := securitysuite.tests with input.anti_phish_policies as AntiPhishPolicies
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as false

    ReportDetailString := concat(" ", [
        "Requirement not met **NOTE: Either you do not have sufficient permissions or",
        "your tenant does not have a license for Microsoft Defender",
        "for Office 365 Plan 1 or Plan 2, which is required for this feature.**"
    ])
    TestResult("MS.SECURITYSUITE.2.1v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.SECURITYSUITE.2.2v1
#--
test_OrganizationDomains_PresetPolicy_AllRecipients if {
    Output := securitysuite.tests with input.anti_phish_policies as AntiPhishPolicies
                            with input.anti_phish_rules as AntiPhishRules
                            with input.protection_policy_rules as ProtectionPolicyRules
                            with input.accepted_domains as AcceptedDomains
                            with input.defender_license as true

    TestResult("MS.SECURITYSUITE.2.2v1", Output, PASS, true) == true
}

test_OrganizationDomains_DefaultPolicy_AllRecipients if {
    Output := securitysuite.tests with input.anti_phish_policies as [DefaultAntiPhishPolicy]
                            with input.anti_phish_rules as []
                            with input.protection_policy_rules as []
                            with input.accepted_domains as AcceptedDomains
                            with input.defender_license as true

    TestResult("MS.SECURITYSUITE.2.2v1", Output, PASS, true) == true
}

test_OrganizationDomains_CustomPolicy_AllRecipients if {
    Output := securitysuite.tests with input.anti_phish_policies as [CustomAntiPhishPolicy]
                            with input.anti_phish_rules as AntiPhishRules
                            with input.protection_policy_rules as []
                            with input.accepted_domains as AcceptedDomains
                            with input.defender_license as true

    TestResult("MS.SECURITYSUITE.2.2v1", Output, PASS, true) == true
}

test_OrganizationDomains_PartialRecipientsMessage if {
    Rule := json.patch(AntiPhishRules[0], [
        {"op": "replace", "path": "AntiPhishPolicy", "value": "Custom AntiPhish"},
        {"op": "replace", "path": "RecipientDomainIs", "value": ["example.com"]}
    ])
    Output := securitysuite.tests with input.anti_phish_policies as [CustomAntiPhishPolicy]
                            with input.anti_phish_rules as [Rule]
                            with input.protection_policy_rules as []
                            with input.accepted_domains as AcceptedDomains
                            with input.defender_license as true

    ReportDetailString := concat(" ", [
        "1 anti-phish policy found that has 'Include domains I own' enabled ('Custom AntiPhish'),",
        "but not all users have been added as recipients.",
    ])
    TestResult("MS.SECURITYSUITE.2.2v1", Output, ReportDetailString, false) == true
}

test_OrganizationDomains_PresetNotAllRecipients if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "0/SentTo", "value": ["user@example.com"]},
                                {"op": "add", "path": "1/SentTo", "value": ["user@example.com"]}])

    Output := securitysuite.tests with input.anti_phish_policies as AntiPhishPolicies
                            with input.anti_phish_rules as AntiPhishRules
                            with input.protection_policy_rules as ProtectionPolicies
                            with input.accepted_domains as AcceptedDomains
                            with input.defender_license as true

    ReportDetailString := "No anti-phish policy has 'Include domains I own' enabled for all recipients."
    TestResult("MS.SECURITYSUITE.2.2v1", Output, ReportDetailString, false) == true
}

test_OrganizationDomains_Incorrect if {
    AntiPhish := json.patch(AntiPhishPolicies, [
        {"op": "replace", "path": "0/EnableOrganizationDomainsProtection", "value": false},
        {"op": "replace", "path": "1/EnableOrganizationDomainsProtection", "value": false}
    ])
    Output := securitysuite.tests with input.anti_phish_policies as AntiPhish
                            with input.defender_license as true

    ReportDetailString := "No anti-phish policy has 'Include domains I own' enabled."
    TestResult("MS.SECURITYSUITE.2.2v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.SECURITYSUITE.2.3v1
#--
test_PartnerDomains_EmptyConfig if {
    Output := securitysuite.tests with input.scuba_config as ScubaConfig
                            with input.scuba_config.SecuritySuite["MS.SECURITYSUITE.2.3v1"] as {}
                            with input.defender_license as true

    ReportDetailString := "No partner domains defined in the ScubaGear config file."
    TestResult("MS.SECURITYSUITE.2.3v1", Output, ReportDetailString, false) == true
}

test_PartnerDomains_Correct if {
    Output := securitysuite.tests with input.anti_phish_policies as AntiPhishPolicies
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    TestResult("MS.SECURITYSUITE.2.3v1", Output, PASS, true) == true
}

test_PartnerDomains_Incorrect if {
    AntiPhish := json.patch(AntiPhishPolicies, [
        {"op": "replace", "path": "0/TargetedDomainsToProtect", "value": []},
        {"op": "replace", "path": "1/TargetedDomainsToProtect", "value": []}
    ])
    Output := securitysuite.tests with input.anti_phish_policies as AntiPhish
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    ReportDetailString := "No anti-phish policy that includes all partner domains."
    TestResult("MS.SECURITYSUITE.2.3v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.SECURITYSUITE.2.4v1
#--
test_UserWarnings_PresetPolicy_AllRecipients if {
    Output := securitysuite.tests with input.anti_phish_policies as []
                            with input.anti_phish_rules as []
                            with input.protection_policy_rules as ProtectionPolicyRules
                            with input.accepted_domains as AcceptedDomains
                            with input.defender_license as true

    TestResult("MS.SECURITYSUITE.2.4v1", Output, PASS, true) == true
}

test_UserWarnings_CustomPolicy_AllRecipients if {
    Output := securitysuite.tests with input.anti_phish_policies as [CustomAntiPhishPolicy]
                            with input.anti_phish_rules as AntiPhishRules
                            with input.protection_policy_rules as []
                            with input.accepted_domains as AcceptedDomains
                            with input.defender_license as true

    TestResult("MS.SECURITYSUITE.2.4v1", Output, PASS, true) == true
}

test_UserWarnings_DefaultPolicy_AllSafetyTips if {
    Output := securitysuite.tests with input.anti_phish_policies as [DefaultAntiPhishPolicy]
                            with input.anti_phish_rules as []
                            with input.protection_policy_rules as []
                            with input.accepted_domains as AcceptedDomains
                            with input.defender_license as true

    TestResult("MS.SECURITYSUITE.2.4v1", Output, PASS, true) == true
}

test_UserWarnings_CustomPolicy_PartialRecipients if {
    Rule := json.patch(AntiPhishRules[0], [
        {"op": "replace", "path": "AntiPhishPolicy", "value": "Custom AntiPhish"},
        {"op": "replace", "path": "RecipientDomainIs", "value": ["example.com"]}
    ])
    Output := securitysuite.tests with input.anti_phish_policies as [CustomAntiPhishPolicy]
                            with input.anti_phish_rules as [Rule]
                            with input.protection_policy_rules as []
                            with input.accepted_domains as AcceptedDomains
                            with input.defender_license as true

    ReportDetailString := concat(" ", [
        "1 anti-phish policy found with all safety tips enabled ('Custom AntiPhish'),",
        "but not all users have been added as recipients.",
    ])
    TestResult("MS.SECURITYSUITE.2.4v1", Output, ReportDetailString, false) == true
}

test_UserWarnings_CustomPolicy_MissingSafetyTips if {
    BadPolicy := json.patch(CustomAntiPhishPolicy, [
        {"op": "replace", "path": "EnableSuspiciousSafetyTip", "value": false}
    ])
    Output := securitysuite.tests with input.anti_phish_policies as [BadPolicy]
                            with input.anti_phish_rules as AntiPhishRules
                            with input.protection_policy_rules as []
                            with input.accepted_domains as AcceptedDomains
                            with input.defender_license as true

    ReportDetailString := "No anti-phish policy applies safety tips to all recipients."
    TestResult("MS.SECURITYSUITE.2.4v1", Output, ReportDetailString, false) == true
}

test_UserWarnings_PresetNotAllRecipients if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "0/SentTo", "value": ["user@example.com"]},
                                {"op": "add", "path": "1/SentTo", "value": ["user@example.com"]}])

    Output := securitysuite.tests with input.anti_phish_policies as []
                            with input.anti_phish_rules as []
                            with input.protection_policy_rules as ProtectionPolicies
                            with input.accepted_domains as AcceptedDomains
                            with input.defender_license as true

    ReportDetailString := "No anti-phish policy applies safety tips to all recipients."
    TestResult("MS.SECURITYSUITE.2.4v1", Output, ReportDetailString, false) == true
}

test_UserWarnings_Incorrect_NoPolicy if {
    Output := securitysuite.tests with input.anti_phish_policies as []
                            with input.anti_phish_rules as []
                            with input.protection_policy_rules as []
                            with input.accepted_domains as AcceptedDomains
                            with input.defender_license as true

    ReportDetailString := "No anti-phish policy applies safety tips to all recipients."
    TestResult("MS.SECURITYSUITE.2.4v1", Output, ReportDetailString, false) == true
}
#--
