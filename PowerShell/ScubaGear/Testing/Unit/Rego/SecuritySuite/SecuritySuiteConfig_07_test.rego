package securitysuite_test

import rego.v1
import data.securitysuite
import data.utils.key.TestResult
import data.utils.key.PASS
import data.utils.key.FAIL

#
# Policy MS.SECURITYSUITE.7
#--
# Test cases for all policies, consolidated to avoid redundancy

# Standard Preset Policy is enabled
test_StandardPresetPolicy_Correct if {
    StrictPresetPolicyDisabled := json.patch(ProtectionPolicyRules, [{"op": "replace", "path": "1/State", "value": false}])
    Output := securitysuite.tests with input.protection_policy_rules as StrictPresetPolicyDisabled
                                    with input.safe_links_policies as []
                                    with input.safe_links_rules as []

    TestResult("MS.SECURITYSUITE.7.1v1", Output, PASS, true) == true
    TestResult("MS.SECURITYSUITE.7.2v1", Output, PASS, true) == true
    TestResult("MS.SECURITYSUITE.7.3v1", Output, PASS, true) == true
}

# Strict Preset Policy is enabled
test_StrictPresetPolicy_Correct if {
    StandardPresetPolicyDisabled := json.patch(ProtectionPolicyRules, [{"op": "replace", "path": "0/State", "value": false}])
    Output := securitysuite.tests with input.protection_policy_rules as StandardPresetPolicyDisabled
                                    with input.safe_links_policies as []
                                    with input.safe_links_rules as []

    TestResult("MS.SECURITYSUITE.7.1v1", Output, PASS, true) == true
    TestResult("MS.SECURITYSUITE.7.2v1", Output, PASS, true) == true
    TestResult("MS.SECURITYSUITE.7.3v1", Output, PASS, true) == true
}

# Standard Preset Policy is enabled but SentTo field is not empty
test_StandardPresetPolicy_Incorrect_V1 if {
    ModifiedPresetPolicy := json.patch(ProtectionPolicyRules, [{"op": "replace", "path": "1/State", "value": false},
                                {"op": "replace", "path": "0/SentTo", "value":  ["test-user@test.onmicrosoft.com"]}])
    Output := securitysuite.tests with input.protection_policy_rules as ModifiedPresetPolicy
                                    with input.safe_links_policies as []
                                    with input.safe_links_rules as []

    TestResult("MS.SECURITYSUITE.7.1v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.2v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.3v1", Output, FAIL, false) == true
}

# Standard Preset Policy is enabled  but SentToMemberOf is not empty
test_StandardPresetPolicy_Incorrect_V2 if {
    ModifiedPresetPolicy := json.patch(ProtectionPolicyRules, [{"op": "replace", "path": "1/State", "value": false},
                                {"op": "replace", "path": "0/SentToMemberOf", "value":  ["test.onmicrosoft.com"]}])
    Output := securitysuite.tests with input.protection_policy_rules as ModifiedPresetPolicy
                                    with input.safe_links_policies as []
                                    with input.safe_links_rules as []

    TestResult("MS.SECURITYSUITE.7.1v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.2v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.3v1", Output, FAIL, false) == true
}

# Standard Preset Policy is enabled  but RecipientDomainIs is not empty
test_StandardPresetPolicy_Incorrect_V3 if {
    ModifiedPresetPolicy := json.patch(ProtectionPolicyRules, [{"op": "replace", "path": "1/State", "value": false},
                                {"op": "replace", "path": "0/RecipientDomainIs", "value":  ["test.onmicrosoft.com"]}])
    Output := securitysuite.tests with input.protection_policy_rules as ModifiedPresetPolicy
                                    with input.safe_links_policies as []
                                    with input.safe_links_rules as []

    TestResult("MS.SECURITYSUITE.7.1v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.2v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.3v1", Output, FAIL, false) == true
}

# Strict Preset Policy is enabled but SentTo field is not empty
test_StrictPresetPolicy_Incorrect_V1 if {
    ModifiedPresetPolicy := json.patch(ProtectionPolicyRules, [{"op": "replace", "path": "0/State", "value": false},
                                {"op": "replace", "path": "1/SentTo", "value":  ["test-user@test.onmicrosoft.com"]}])
    Output := securitysuite.tests with input.protection_policy_rules as ModifiedPresetPolicy
                                    with input.safe_links_policies as []
                                    with input.safe_links_rules as []

    TestResult("MS.SECURITYSUITE.7.1v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.2v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.3v1", Output, FAIL, false) == true
}

# Strict Preset Policy is enabled but SentToMemberOf is not empty
test_StrictPresetPolicy_Incorrect_V2 if {
    ModifiedPresetPolicy := json.patch(ProtectionPolicyRules, [{"op": "replace", "path": "0/State", "value": false},
                                {"op": "replace", "path": "1/SentToMemberOf", "value":  ["test.onmicrosoft.com"]}])
    Output := securitysuite.tests with input.protection_policy_rules as ModifiedPresetPolicy
                                    with input.safe_links_policies as []
                                    with input.safe_links_rules as []

    TestResult("MS.SECURITYSUITE.7.1v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.2v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.3v1", Output, FAIL, false) == true
}

# Strict Preset Policy is enabled but RecipientDomainIs is not empty
test_StrictPresetPolicy_Incorrect_V3 if {
    ModifiedPresetPolicy := json.patch(ProtectionPolicyRules, [{"op": "replace", "path": "0/State", "value": false},
                                {"op": "replace", "path": "1/RecipientDomainIs", "value":  ["test.onmicrosoft.com"]}])
    Output := securitysuite.tests with input.protection_policy_rules as ModifiedPresetPolicy
                                    with input.safe_links_policies as []
                                    with input.safe_links_rules as []

    TestResult("MS.SECURITYSUITE.7.1v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.2v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.3v1", Output, FAIL, false) == true
}

# Compliant Custom Policy is enabled
test_CustomPolicy_Correct if {
    Output := securitysuite.tests with input.protection_policy_rules as ProtectionPolicyRules
                                        with input.safe_links_policies as SafeLinksPolicies
                                        with input.safe_links_rules as SafeLinksRules

    TestResult("MS.SECURITYSUITE.7.1v1", Output, PASS, true) == true
    TestResult("MS.SECURITYSUITE.7.2v1", Output, PASS, true) == true
    TestResult("MS.SECURITYSUITE.7.3v1", Output, PASS, true) == true
}

# Compliant custom policy exists but is not enabled, non-compliant custom policy is applied
test_CustomPolicy_Incorrect_V1 if {
    PresetPoliciesDisabled := json.patch(ProtectionPolicyRules, 
                            [{"op": "replace", "path": "0/State", "value": false}, 
                            {"op": "replace", "path": "1/State", "value": false}])
    RuleDisabled :=  json.patch(SafeLinksRules, [{"op": "replace", "path": "0/State", "value": "Disabled"}])
    Output := securitysuite.tests with input.protection_policy_rules as PresetPoliciesDisabled
                                    with input.safe_links_policies as SafeLinksPolicies
                                    with input.safe_links_rules as RuleDisabled

    TestResult("MS.SECURITYSUITE.7.1v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.2v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.3v1", Output, FAIL, false) == true
}

# Compliant custom policy exists but is not the highest priority (lowest priority number) policy, non-compliant custom policy is applied
test_CustomPolicy_Incorrect_V2 if {
    PresetPoliciesDisabled := json.patch(ProtectionPolicyRules, 
                            [{"op": "replace", "path": "0/State", "value": false}, 
                            {"op": "replace", "path": "1/State", "value": false}])
    IncorrectRulePriority :=  json.patch(SafeLinksRules, [{"op": "replace", "path": "0/Priority", "value": 1},
                                    {"op": "replace", "path": "1/Priority", "value": 0}])
    Output := securitysuite.tests with input.protection_policy_rules as PresetPoliciesDisabled
                                    with input.safe_links_policies as SafeLinksPolicies
                                    with input.safe_links_rules as IncorrectRulePriority

    TestResult("MS.SECURITYSUITE.7.1v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.2v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.3v1", Output, FAIL, false) == true
}


# Compliant custom policy is enabled but SentTo field is not empty, non-compliant custom policy is applied
test_CustomPolicy_Incorrect_V3 if {
    PresetPoliciesDisabled := json.patch(ProtectionPolicyRules, 
                            [{"op": "replace", "path": "0/State", "value": false}, 
                            {"op": "replace", "path": "1/State", "value": false}])
    ModifiedRules :=  json.patch(SafeLinksRules, [{"op": "replace", "path": "0/SentTo", "value": ["test-user@test.onmicrosoft.com"]}])
    Output := securitysuite.tests with input.protection_policy_rules as PresetPoliciesDisabled
                                    with input.safe_links_policies as SafeLinksPolicies
                                    with input.safe_links_rules as ModifiedRules

    TestResult("MS.SECURITYSUITE.7.1v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.2v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.3v1", Output, FAIL, false) == true
}

# Compliant custom policy is enabled but SentToMemberOf is not empty, non-compliant custom policy is applied
test_CustomPolicy_Incorrect_V4 if {
    PresetPoliciesDisabled := json.patch(ProtectionPolicyRules, 
                            [{"op": "replace", "path": "0/State", "value": false}, 
                            {"op": "replace", "path": "1/State", "value": false}])
    ModifiedRules :=  json.patch(SafeLinksRules, [{"op": "replace", "path": "0/SentToMemberOf", "value": ["test.onmicrosoft.com"]}])
    Output := securitysuite.tests with input.protection_policy_rules as PresetPoliciesDisabled
                                    with input.safe_links_policies as SafeLinksPolicies
                                    with input.safe_links_rules as ModifiedRules

    TestResult("MS.SECURITYSUITE.7.1v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.2v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.3v1", Output, FAIL, false) == true
}

# Compliant custom policy is enabled but RecipientDomainIs is not empty, non-compliant custom policy is applied
test_CustomPolicy_Incorrect_V5 if {
    PresetPoliciesDisabled := json.patch(ProtectionPolicyRules, 
                            [{"op": "replace", "path": "0/State", "value": false}, 
                            {"op": "replace", "path": "1/State", "value": false}])
    ModifiedRules :=  json.patch(SafeLinksRules, [{"op": "replace", "path": "0/RecipientDomainIs", "value": ["test.onmicrosoft.com"]}])
    Output := securitysuite.tests with input.protection_policy_rules as PresetPoliciesDisabled
                                    with input.safe_links_policies as SafeLinksPolicies
                                    with input.safe_links_rules as ModifiedRules

    TestResult("MS.SECURITYSUITE.7.1v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.2v1", Output, FAIL, false) == true
    TestResult("MS.SECURITYSUITE.7.3v1", Output, FAIL, false) == true
}
#--

#
# Policy MS.SECURITYSUITE.7.1v1
#--

# Custom policy does not have EnableSafeLinksfoEmail enabled
test_SafeLinks_CustomPolicy_Incorrect_V1 if {
    PresetPoliciesDisabled := json.patch(ProtectionPolicyRules, 
                            [{"op": "replace", "path": "0/State", "value": false}, 
                            {"op": "replace", "path": "1/State", "value": false}])
    IncorrectPolicy :=  json.patch(SafeLinksPolicies, [{"op": "replace", "path": "0/EnableSafeLinksForEmail", "value": false}])
    Output := securitysuite.tests with input.protection_policy_rules as PresetPoliciesDisabled
                                    with input.safe_links_policies as IncorrectPolicy
                                    with input.safe_links_rules as SafeLinksRules

    TestResult("MS.SECURITYSUITE.7.1v1", Output, FAIL, false) == true
}

# Custom policy does not have EnableSafeLinksforTeams enabled
test_SafeLinks_CustomPolicy_Incorrect_V2 if {
    PresetPoliciesDisabled := json.patch(ProtectionPolicyRules, 
                            [{"op": "replace", "path": "0/State", "value": false}, 
                            {"op": "replace", "path": "1/State", "value": false}])
    IncorrectPolicy :=  json.patch(SafeLinksPolicies, [{"op": "replace", "path": "0/EnableSafeLinksForTeams", "value": false}])
    Output := securitysuite.tests with input.protection_policy_rules as PresetPoliciesDisabled
                                    with input.safe_links_policies as IncorrectPolicy
                                    with input.safe_links_rules as SafeLinksRules

    TestResult("MS.SECURITYSUITE.7.1v1", Output, FAIL, false) == true
}

# Custom policy does not have EnableSafeLinksforOffice enabled
test_SafeLinks_CustomPolicy_Incorrect_V3 if {
    PresetPoliciesDisabled := json.patch(ProtectionPolicyRules, 
                            [{"op": "replace", "path": "0/State", "value": false}, 
                            {"op": "replace", "path": "1/State", "value": false}])
    IncorrectPolicy :=  json.patch(SafeLinksPolicies, [{"op": "replace", "path": "0/EnableSafeLinksForOffice", "value": false}])
    Output := securitysuite.tests with input.protection_policy_rules as PresetPoliciesDisabled
                                    with input.safe_links_policies as IncorrectPolicy
                                    with input.safe_links_rules as SafeLinksRules

    TestResult("MS.SECURITYSUITE.7.1v1", Output, FAIL, false) == true
}

# Custom policy does not have EnableforInternalSenders enabled
test_SafeLinks_CustomPolicy_Incorrect_V4 if {
    PresetPoliciesDisabled := json.patch(ProtectionPolicyRules, 
                            [{"op": "replace", "path": "0/State", "value": false}, 
                            {"op": "replace", "path": "1/State", "value": false}])
    IncorrectPolicy :=  json.patch(SafeLinksPolicies, [{"op": "replace", "path": "0/EnableForInternalSenders", "value": false}])
    Output := securitysuite.tests with input.protection_policy_rules as PresetPoliciesDisabled
                                    with input.safe_links_policies as IncorrectPolicy
                                    with input.safe_links_rules as SafeLinksRules

    TestResult("MS.SECURITYSUITE.7.1v1", Output, FAIL, false) == true
}

# All custom policies are disabled, built-in protection policy is applied
test_SafeLinks_BuiltInPoilicy_Incorrect if {
    PresetPoliciesDisabled := json.patch(ProtectionPolicyRules, 
                            [{"op": "replace", "path": "0/State", "value": false}, 
                            {"op": "replace", "path": "1/State", "value": false}])
    RuleDisabled :=  json.patch(SafeLinksRules, [{"op": "replace", "path": "0/State", "value": "Disabled"},
                                                {"op": "replace", "path": "1/State", "value": "Disabled"}])
    Output := securitysuite.tests with input.protection_policy_rules as PresetPoliciesDisabled
                                    with input.safe_links_policies as SafeLinksPolicies
                                    with input.safe_links_rules as RuleDisabled

    TestResult("MS.SECURITYSUITE.7.1v1", Output, FAIL, false) == true
}
#--

#
# Policy MS.SECURITYSUITE.7.2v1
#--

# Custom policy does not have ScanUrls enabled
test_CheckUrls_CustomPolicy_Incorrect_V1 if {
    PresetPoliciesDisabled := json.patch(ProtectionPolicyRules, 
                            [{"op": "replace", "path": "0/State", "value": false}, 
                            {"op": "replace", "path": "1/State", "value": false}])
    IncorrectPolicy :=  json.patch(SafeLinksPolicies, [{"op": "replace", "path": "0/ScanUrls", "value": false}])
    Output := securitysuite.tests with input.protection_policy_rules as PresetPoliciesDisabled
                                    with input.safe_links_policies as IncorrectPolicy
                                    with input.safe_links_rules as SafeLinksRules

    TestResult("MS.SECURITYSUITE.7.2v1", Output, FAIL, false) == true
}

# Custom policy does not have DeliverMessageAfterScan enabled
test_CheckUrls_CustomPolicy_Incorrect_V2 if {
    PresetPoliciesDisabled := json.patch(ProtectionPolicyRules, 
                            [{"op": "replace", "path": "0/State", "value": false}, 
                            {"op": "replace", "path": "1/State", "value": false}])
    IncorrectPolicy :=  json.patch(SafeLinksPolicies, [{"op": "replace", "path": "0/DeliverMessageAfterScan", "value": false}])
    Output := securitysuite.tests with input.protection_policy_rules as PresetPoliciesDisabled
                                    with input.safe_links_policies as IncorrectPolicy
                                    with input.safe_links_rules as SafeLinksRules

    TestResult("MS.SECURITYSUITE.7.2v1", Output, FAIL, false) == true
}

# All custom policies are disabled, built-in protection policy is applied
test_CheckUrls_BuiltInPoilicy_Correct if {
    PresetPoliciesDisabled := json.patch(ProtectionPolicyRules, 
                            [{"op": "replace", "path": "0/State", "value": false}, 
                            {"op": "replace", "path": "1/State", "value": false}])
    RuleDisabled :=  json.patch(SafeLinksRules, [{"op": "replace", "path": "0/State", "value": "Disabled"},
                                                {"op": "replace", "path": "1/State", "value": "Disabled"}])
    Output := securitysuite.tests with input.protection_policy_rules as PresetPoliciesDisabled
                                    with input.safe_links_policies as SafeLinksPolicies
                                    with input.safe_links_rules as RuleDisabled

    TestResult("MS.SECURITYSUITE.7.2v1", Output, PASS, true) == true
}
#--

#
# Policy MS.SECURITYSUITE.7.3v1
#--

# Custom policy does not have TrackChecks enabled
test_TrackChecks_CustomPolicy_Incorrect if {
    PresetPoliciesDisabled := json.patch(ProtectionPolicyRules, 
                            [{"op": "replace", "path": "0/State", "value": false}, 
                            {"op": "replace", "path": "1/State", "value": false}])
    IncorrectPolicy :=  json.patch(SafeLinksPolicies, [{"op": "replace", "path": "0/TrackClicks", "value": false}])
    Output := securitysuite.tests with input.protection_policy_rules as PresetPoliciesDisabled
                                    with input.safe_links_policies as IncorrectPolicy
                                    with input.safe_links_rules as SafeLinksRules

    TestResult("MS.SECURITYSUITE.7.3v1", Output, FAIL, false) == true
}

# All custom policies are disabled, built-in protection policy is applied
test_TrackChecks_BuiltInPoilicy_Incorrect if {
    PresetPoliciesDisabled := json.patch(ProtectionPolicyRules, 
                            [{"op": "replace", "path": "0/State", "value": false}, 
                            {"op": "replace", "path": "1/State", "value": false}])
    RuleDisabled :=  json.patch(SafeLinksRules, [{"op": "replace", "path": "0/State", "value": "Disabled"},
                                                {"op": "replace", "path": "1/State", "value": "Disabled"}])
    Output := securitysuite.tests with input.protection_policy_rules as PresetPoliciesDisabled
                                    with input.safe_links_policies as SafeLinksPolicies
                                    with input.safe_links_rules as RuleDisabled

    TestResult("MS.SECURITYSUITE.7.3v1", Output, PASS, true) == true
}
#--