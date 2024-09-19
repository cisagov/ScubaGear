package defender_test

import data.defender
import data.utils.defender.DEFLICENSEWARNSTR
import data.utils.key.FAIL
import data.utils.key.PASS
import data.utils.key.TestResult
import rego.v1

#
# Policy MS.DEFENDER.1.1v1
#--
test_Enabled_Correct_V1 if {
    Output := defender.tests with input.protection_policy_rules as ProtectionPolicyRules
                            with input.atp_policy_rules as AtpPolicyRules
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.1v1", Output, PASS, true) == true
}

test_Enabled_Correct_V2 if {
    Output := defender.tests with input.protection_policy_rules as ProtectionPolicyRules
                            with input.atp_policy_rules as []
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.1v1", Output, PASS, true) == true
}

test_Enabled_Correct_V3 if {
    Output := defender.tests with input.protection_policy_rules as []
                            with input.atp_policy_rules as AtpPolicyRules
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.1v1", Output, PASS, true) == true
}

test_Enabled_Incorrect_V1 if {
    Output := defender.tests with input.protection_policy_rules as []
                            with input.atp_policy_rules as []
                            with input.defender_license as true

    ReportDetailString := "Standard and Strict preset policies are both disabled"
    TestResult("MS.DEFENDER.1.1v1", Output, ReportDetailString, false) == true
}

test_Enabled_Incorrect_V2 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "0/State", "value": "Disabled"},
                                {"op": "remove", "path": "1"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.atp_policy_rules as []
                            with input.defender_license as true

    ReportDetailString := "Standard and Strict preset policies are both disabled"
    TestResult("MS.DEFENDER.1.1v1", Output, ReportDetailString, false) == true
}

test_Enabled_Incorrect_V3 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "remove", "path": "1"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.atp_policy_rules as []
                            with input.defender_license as true

    ReportDetailString := "Strict preset policy is disabled"
    TestResult("MS.DEFENDER.1.1v1", Output, ReportDetailString, false) == true
}

test_Enabled_Incorrect_V4 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "0/State", "value": "Disabled"},
                                {"op": "add", "path": "1/State", "value": "Disabled"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.atp_policy_rules as []
                            with input.defender_license as true

    ReportDetailString := "Standard and Strict preset policies are both disabled"
    TestResult("MS.DEFENDER.1.1v1", Output, ReportDetailString, false) == true
}

#--

#
# Policy MS.DEFENDER.1.2v1
#--
test_AllEOP_Correct_V1 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "remove", "path": "1"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.2v1", Output, PASS, true) == true
}

test_AllEOP_Correct_V2 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.2v1", Output, PASS, true) == true
}

test_AllEOP_Correct_V3 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": ["user@example.com"]}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.2v1", Output, PASS, true) == true
}

test_AllEOP_Incorrect_V1 if {
    Output := defender.tests with input.protection_policy_rules as []

    TestResult("MS.DEFENDER.1.2v1", Output, FAIL, false) == true
}

test_AllEOP_Incorrect_V2 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": ["user@example.com"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.2v1", Output, FAIL, false) == true
}

test_AllEOP_Incorrect_V3 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "0/RecipientDomainIs", "value": ["example.com"]},
                                {"op": "add", "path": "1/SentTo", "value": ["user@example.com"]}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.2v1", Output, FAIL, false) == true
}

#--

#
# Policy MS.DEFENDER.1.3v1
#--
test_AllDefender_Correct_V1 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "remove", "path": "1"}])
    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.3v1", Output, PASS, true) == true
}

test_AllDefender_Correct_V2 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "remove", "path": "0"}])
    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.3v1", Output, PASS, true) == true
}

test_AllDefender_Correct_V3 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": ["user@example.com"]}])
    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.3v1", Output, PASS, true) == true
}

test_AllDefender_Incorrect_V1 if {
    Output := defender.tests with input.atp_policy_rules as []
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.3v1", Output, FAIL, false) == true
}

test_AllDefender_Incorrect_V2 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": ["user@example.com"]},
                                {"op": "remove", "path": "0"}])
    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.3v1", Output, FAIL, false) == true
}

test_AllDefender_Incorrect_V3 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "0/RecipientDomainIs", "value": ["example.com"]},
                                {"op": "add", "path": "1/SentTo", "value": ["user@example.com"]}])
    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.3v1", Output, FAIL, false) == true
}

test_AllDefender_Incorrect_V4 if {
    Output := defender.tests with input.atp_policy_rules as []
                            with input.defender_license as false

    ReportDetailString := concat(" ", [FAIL, DEFLICENSEWARNSTR])

    TestResult("MS.DEFENDER.1.3v1", Output, ReportDetailString, false) == true
}

#--

#
# Policy MS.DEFENDER.1.4v1
#--
test_SensitiveEOP_Correct_V1 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V2 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts as {}
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V3 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": ["johndoe@random.example.com"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedUsers as ["johndoe@random.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V4 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": [
                                                                            "johndoe@random.example.com",
                                                                            "janedoe@random.example.com"
                                                                            ]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedUsers as [
                                                                                                        "johndoe@random.example.com",
                                                                                                        "janedoe@random.example.com"
                                                                                                        ]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V5 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/ExceptIfSentTo", "value": ["johndoe@random.example.com"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedUsers as ["johndoe@random.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V6 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/ExceptIfSentTo", "value": [
                                                                                        "johndoe@random.example.com",
                                                                                        "janedoe@random.example.com"
                                                                                    ]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedUsers as [
                                                                                                                        "johndoe@random.example.com",
                                                                                                                        "janedoe@random.example.com"
                                                                                                                    ]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V7 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/SentToMemberOf", "value": ["Dune"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedGroups as ["Dune"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V8 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/SentToMemberOf", "value": [
                                                                                        "Dune",
                                                                                        "Dune12"
                                                                                    ]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedGroups as [
                                                                                                                        "Dune",
                                                                                                                        "Dune12"
                                                                                                                    ]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V9 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/ExceptIfSentToMemberOf", "value": ["Dune"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedGroups as ["Dune"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V10 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/ExceptIfSentToMemberOf", "value": [
                                                                                                "Dune",
                                                                                                "Dune12"
                                                                                            ]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedGroups as [
                                                                                                                        "Dune",
                                                                                                                        "Dune12"
                                                                                                                    ]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V11 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/RecipientDomainIs", "value": ["random.mail.example.com"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedDomains as ["random.mail.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V12 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/RecipientDomainIs", "value": [
                                                                                            "random.mail.example.com",
                                                                                            "random.example.com"
                                                                                        ]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedDomains as [
                                                                                                                        "random.mail.example.com",
                                                                                                                        "random.example.com"
                                                                                                                        ]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V13 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/ExceptIfRecipientDomainIs", "value": ["random.mail.example.com"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedDomains as ["random.mail.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V14 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/ExceptIfRecipientDomainIs", "value": [
                                                                                            "random.mail.example.com",
                                                                                            "random.example.com"
                                                                                        ]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedDomains as [
                                                                                                                        "random.mail.example.com",
                                                                                                                        "random.example.com"
                                                                                                                        ]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V15 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": ["johndoe@random.example.com"]},
                                {"op": "add", "path": "1/ExceptIfSentTo", "value": ["janedoe@random.example.com"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedUsers as ["johndoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedUsers as ["janedoe@random.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V16 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/SentToMemberOf", "value": ["Dune"]},
                                {"op": "add", "path": "1/ExceptIfSentToMemberOf", "value": ["Dune12"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedGroups as ["Dune"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedGroups as ["Dune12"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V17 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/RecipientDomainIs", "value": ["random.example.com"]},
                                {"op": "add", "path": "1/ExceptIfRecipientDomainIs", "value": ["random.mail.example.com"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedDomains as ["random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedDomains as ["random.mail.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V18 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": ["johndoe@random.example.com"]},
                                {"op": "add", "path": "1/SentToMemberOf", "value": ["Dune"]},
                                {"op": "add", "path": "1/ExceptIfSentTo", "value": ["janedoe@random.example.com"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedUsers as ["johndoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedUsers as ["janedoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedGroups as ["Dune"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V19 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": ["johndoe@random.example.com"]},
                                {"op": "add", "path": "1/ExceptIfSentToMemberOf", "value": ["Dune12"]},
                                {"op": "add", "path": "1/ExceptIfSentTo", "value": ["janedoe@random.example.com"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedUsers as ["johndoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedUsers as ["janedoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedGroups as ["Dune12"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V20 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": ["johndoe@random.example.com"]},
                                {"op": "add", "path": "1/RecipientDomainIs", "value": ["random.example.com"]},
                                {"op": "add", "path": "1/ExceptIfSentTo", "value": ["janedoe@random.example.com"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedUsers as ["johndoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedUsers as ["janedoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedDomains as ["random.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V21 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": ["johndoe@random.example.com"]},
                                {"op": "add", "path": "1/ExceptIfRecipientDomainIs", "value": ["random.mail.example.com"]},
                                {"op": "add", "path": "1/ExceptIfSentTo", "value": ["janedoe@random.example.com"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedUsers as ["johndoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedUsers as ["janedoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedDomains as ["random.mail.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V22 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/SentToMemberOf", "value": ["Dune"]},
                                {"op": "add", "path": "1/RecipientDomainIs", "value": ["random.example.com"]},
                                {"op": "add", "path": "1/ExceptIfSentToMemberOf", "value": ["Dune12"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedGroups as ["Dune"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedGroups as ["Dune12"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedDomains as ["random.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V23 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/SentToMemberOf", "value": ["Dune"]},
                                {"op": "add", "path": "1/ExceptIfRecipientDomainIs", "value": ["random.mail.example.com"]},
                                {"op": "add", "path": "1/ExceptIfSentToMemberOf", "value": ["Dune12"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedGroups as ["Dune"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedGroups as ["Dune12"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedDomains as ["random.mail.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Correct_V24 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": ["johndoe@random.example.com"]},
                                {"op": "add", "path": "1/RecipientDomainIs", "value": ["random.example.com"]},
                                {"op": "add", "path": "1/SentToMemberOf", "value": ["Dune"]},
                                {"op": "add", "path": "1/ExceptIfSentTo", "value": ["janedoe@random.example.com"]},
                                {"op": "add", "path": "1/ExceptIfSentToMemberOf", "value": ["Dune12"]},
                                {"op": "add", "path": "1/ExceptIfRecipientDomainIs", "value": ["random.mail.example.com"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedUsers as ["johndoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedUsers as ["janedoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedGroups as ["Dune"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedGroups as ["Dune12"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedDomains as ["random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedDomains as ["random.mail.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, PASS, true) == true
}

test_SensitiveEOP_Incorrect_V1 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/State", "value": "Disabled"},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, FAIL, false) == true
}

test_SensitiveEOP_Incorrect_V2 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "remove", "path": "1"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, FAIL, false) == true
}

test_SensitiveEOP_Incorrect_V3 if {
    Output := defender.tests with input.protection_policy_rules as [{}]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, FAIL, false) == true
}

test_SensitiveEOP_Incorrect_V4 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/ExceptIfSentTo", "value": ["johndoe@random.example.com"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, FAIL, false) == true
}

test_SensitiveEOP_Incorrect_V5 if {
    ProtectionPolicies := json.patch(ProtectionPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": ["johndoe@random.example.com"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.protection_policy_rules as ProtectionPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedUsers as ["johndoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedUsers as ["janedoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedGroups as ["Dune"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedGroups as ["Dune12"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.IncludedDomains as ["random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.4v1"].SensitiveAccounts.ExcludedDomains as ["random.mail.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.4v1", Output, FAIL, false) == true
}

#--

#
# Policy MS.DEFENDER.1.5v1
#--
test_SensitiveATP_Correct_V1 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V2 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V3 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": ["johndoe@random.example.com"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedUsers as ["johndoe@random.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V4 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": [
                                                                                "johndoe@random.example.com",
                                                                                "janedoe@random.example.com"
                                                                            ]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedUsers as [
                                                                                                                        "johndoe@random.example.com",
                                                                                                                        "janedoe@random.example.com"
                                                                                                                    ]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V5 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/ExceptIfSentTo", "value": ["johndoe@random.example.com"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedUsers as ["johndoe@random.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V6 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/ExceptIfSentTo", "value": [
                                                                                        "johndoe@random.example.com",
                                                                                        "janedoe@random.example.com"
                                                                                    ]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedUsers as [
                                                                                                                        "johndoe@random.example.com",
                                                                                                                        "janedoe@random.example.com"
                                                                                                                    ]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V7 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/SentToMemberOf", "value": ["Dune"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedGroups as ["Dune"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V8 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/SentToMemberOf", "value": [
                                                                                        "Dune",
                                                                                        "Dune12"
                                                                                    ]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedGroups as [
                                                                                                                        "Dune",
                                                                                                                        "Dune12"
                                                                                                                    ]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V9 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/ExceptIfSentToMemberOf", "value": ["Dune"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedGroups as ["Dune"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V10 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/ExceptIfSentToMemberOf", "value": [
                                                                                        "Dune",
                                                                                        "Dune12"
                                                                                    ]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedGroups as [
                                                                                                                        "Dune",
                                                                                                                        "Dune12"
                                                                                                                    ]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V11 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/RecipientDomainIs", "value": ["random.mail.example.com"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedDomains as ["random.mail.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V12 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/RecipientDomainIs", "value": [
                                                                                            "random.mail.example.com",
                                                                                            "random.example.com"
                                                                                        ]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedDomains as [
                                                                                                                            "random.mail.example.com",
                                                                                                                            "random.example.com"
                                                                                                                        ]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V13 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/ExceptIfRecipientDomainIs", "value": ["random.mail.example.com"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedDomains as ["random.mail.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V14 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/ExceptIfRecipientDomainIs", "value": [
                                                                                                    "random.mail.example.com",
                                                                                                    "random.example.com"
                                                                                                ]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedDomains as [
                                                                                                                            "random.mail.example.com",
                                                                                                                            "random.example.com"
                                                                                                                        ]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V15 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": ["johndoe@random.example.com"]},
                                {"op": "add", "path": "1/ExceptIfSentTo", "value": ["janedoe@random.example.com"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedUsers as ["johndoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedUsers as ["janedoe@random.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V16 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/SentToMemberOf", "value": ["Dune"]},
                                {"op": "add", "path": "1/ExceptIfSentToMemberOf", "value": ["Dune12"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedGroups as ["Dune"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedGroups as ["Dune12"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V17 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/RecipientDomainIs", "value": ["random.example.com"]},
                                {"op": "add", "path": "1/ExceptIfRecipientDomainIs", "value": ["random.mail.example.com"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedDomains as ["random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedDomains as ["random.mail.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V18 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": ["johndoe@random.example.com"]},
                                {"op": "add", "path": "1/SentToMemberOf", "value": ["Dune"]},
                                {"op": "add", "path": "1/ExceptIfSentTo", "value": ["janedoe@random.example.com"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedUsers as ["johndoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedUsers as ["janedoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedGroups as ["Dune"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V19 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": ["johndoe@random.example.com"]},
                                {"op": "add", "path": "1/ExceptIfSentToMemberOf", "value": ["Dune12"]},
                                {"op": "add", "path": "1/ExceptIfSentTo", "value": ["janedoe@random.example.com"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedUsers as ["johndoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedUsers as ["janedoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedGroups as ["Dune12"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V20 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": ["johndoe@random.example.com"]},
                                {"op": "add", "path": "1/RecipientDomainIs", "value": ["random.example.com"]},
                                {"op": "add", "path": "1/ExceptIfSentTo", "value": ["janedoe@random.example.com"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedUsers as ["johndoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedUsers as ["janedoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedDomains as ["random.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V21 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": ["johndoe@random.example.com"]},
                                {"op": "add", "path": "1/ExceptIfRecipientDomainIs", "value": ["random.mail.example.com"]},
                                {"op": "add", "path": "1/ExceptIfSentTo", "value": ["janedoe@random.example.com"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedUsers as ["johndoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedUsers as ["janedoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedDomains as ["random.mail.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V22 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/SentToMemberOf", "value": ["Dune"]},
                                {"op": "add", "path": "1/RecipientDomainIs", "value": ["random.example.com"]},
                                {"op": "add", "path": "1/ExceptIfSentToMemberOf", "value": ["Dune12"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedGroups as ["Dune"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedGroups as ["Dune12"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedDomains as ["random.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V23 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/SentToMemberOf", "value": ["Dune"]},
                                {"op": "add", "path": "1/ExceptIfRecipientDomainIs", "value": ["random.mail.example.com"]},
                                {"op": "add", "path": "1/ExceptIfSentToMemberOf", "value": ["Dune12"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedGroups as ["Dune"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedGroups as ["Dune12"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedDomains as ["random.mail.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Correct_V24 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": ["johndoe@random.example.com"]},
                                {"op": "add", "path": "1/SentToMemberOf", "value": ["Dune"]},
                                {"op": "add", "path": "1/RecipientDomainIs", "value": ["random.example.com"]},
                                {"op": "add", "path": "1/ExceptIfSentTo", "value": ["janedoe@random.example.com"]},
                                {"op": "add", "path": "1/ExceptIfSentToMemberOf", "value": ["Dune12"]},
                                {"op": "add", "path": "1/ExceptIfRecipientDomainIs", "value": ["random.mail.example.com"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedUsers as ["johndoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedUsers as ["janedoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedGroups as ["Dune"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedGroups as ["Dune12"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedDomains as ["random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedDomains as ["random.mail.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, PASS, true) == true
}

test_SensitiveATP_Incorrect_V1 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/State", "value": "Disabled"},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, FAIL, false) == true
}

test_SensitiveATP_Incorrect_V2 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "remove", "path": "1"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, FAIL, false) == true
}

test_SensitiveATP_Incorrect_V3 if {
    Output := defender.tests with input.atp_policy_rules as [{}]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, FAIL, false) == true
}

test_SensitiveATP_Incorrect_V4 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/ExceptIfSentTo", "value": ["johndoe@random.example.com"]},
                                {"op": "add", "path": "1/Exceptions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, FAIL, false) == true
}

test_SensitiveATP_Incorrect_V5 if {
    AtpPolicies := json.patch(AtpPolicyRules,
                                [{"op": "add", "path": "1/SentTo", "value": ["johndoe@random.example.com"]},
                                {"op": "add", "path": "1/Conditions", "value": ["Rules.Tasks"]},
                                {"op": "remove", "path": "0"}])

    Output := defender.tests with input.atp_policy_rules as AtpPolicies
                            with input.scuba_config as ScubaConfig
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedUsers as ["johndoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedUsers as ["janedoe@random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedGroups as ["Dune"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedGroups as ["Dune12"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.IncludedDomains as ["random.example.com"]
                            with input.scuba_config.Defender["MS.DEFENDER.1.5v1"].SensitiveAccounts.ExcludedDomains as ["random.mail.example.com"]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.1.5v1", Output, FAIL, false) == true
}

#--
