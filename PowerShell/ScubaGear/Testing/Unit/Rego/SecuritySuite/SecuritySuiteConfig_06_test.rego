package securitysuite_test
import rego.v1
import data.securitysuite
import data.utils.key.TestResult

#
# Policy MS.SECURITYSUITE.6.1v1
#--
test_SpamPolicy_Correct_DefaultOnly if {
    # Only default policy exists with compliant actions
    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as []

    ReportDetailString := "Requirement met. No active compliant preset or Custom policy. All active policies evaluated"
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, true) == true
}

test_SpamPolicy_Correct_DefaultAndStandard if {
    # Default and standard preset policies exist with compliant actions
    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, StandardPresetPolicy]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as ProtectionPolicyRulesEnabled

    ReportDetailString := "Requirement met. Standard preset is active and compliant (Strict not active or non-compliant). Custom and Default policies not evaluated"
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, true) == true
}

test_SpamPolicy_Correct_DefaultAndBothPresets if {
    # Default, standard and strict preset policies exist with compliant actions
    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, StandardPresetPolicy, StrictPresetPolicy]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as ProtectionPolicyRulesEnabled

    ReportDetailString := "Requirement met. Strict preset is active and compliant. Standard preset, Custom, and Default policies not evaluated"
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, true) == true
}

test_SpamPolicy_Correct_DefaultAndCustom if {
    # Default and custom policies exist with compliant actions
    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, CustomPolicy]
        with input.hosted_content_filter_rules as CustomPolicyRuleEnabled
        with input.protection_policy_rules as []

    ReportDetailString := "Requirement met. No active compliant preset. Custom policy evaluation applied; Default policy not evaluated"
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, true) == true
}

test_SpamPolicy_Correct_AllPolicyTypes if {
    # Default, standard and strict preset, and custom policies exist with compliant actions
    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, StandardPresetPolicy, StrictPresetPolicy, CustomPolicy]
        with input.hosted_content_filter_rules as CustomPolicyRuleEnabled
        with input.protection_policy_rules as ProtectionPolicyRulesEnabled

    ReportDetailString := "Requirement met. Strict preset is active and compliant. Standard preset, Custom, and Default policies not evaluated"
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, true) == true
}

test_SpamPolicy_Correct_NonCompliantCustomRuleDisabled if {
    # Non-compliant custom policy exists that is disabled
    BadCustom := json.patch(CustomPolicy, [{"op": "add", "path": "SpamAction", "value": "AddXHeader"}])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, BadCustom]
        with input.hosted_content_filter_rules as CustomPolicyRuleDisabled
        with input.protection_policy_rules as []

    ReportDetailString := "Requirement met. No active compliant preset or Custom policy. All active policies evaluated"
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, true) == true
}

test_SpamPolicy_Correct_NonCompliantPresetRulesDisabled if {
    # Non-compliant standard preset policy exists that is disabled
    BadStandard := json.patch(StandardPresetPolicy, [{"op": "add", "path": "SpamAction", "value": "AddXHeader"}])
    ProtectionRulesDisabled := [
        json.patch(ProtectionPolicyRulesEnabled[0], [{"op": "add", "path": "State", "value": "Disabled"}]),
        json.patch(ProtectionPolicyRulesEnabled[1], [{"op": "add", "path": "State", "value": "Disabled"}])
    ]

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, BadStandard]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as ProtectionRulesDisabled

    ReportDetailString := "Requirement met. No active compliant preset or Custom policy. All active policies evaluated"
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, true) == true
}

test_SpamPolicy_Correct_AllRulesDisabledExceptDefault if {
    # Default policy is active; non-compliant standard/strict preset and custom policies exist that are disabled
    BadCustom := json.patch(CustomPolicy, [{"op": "add", "path": "SpamAction", "value": "AddXHeader"}])
    BadStandard := json.patch(StandardPresetPolicy, [{"op": "add", "path": "SpamAction", "value": "AddXHeader"}])
    ProtectionRulesDisabled := [
        json.patch(ProtectionPolicyRulesEnabled[0], [{"op": "add", "path": "State", "value": "Disabled"}]),
        json.patch(ProtectionPolicyRulesEnabled[1], [{"op": "add", "path": "State", "value": "Disabled"}])
    ]

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, BadStandard, BadCustom]
        with input.hosted_content_filter_rules as CustomPolicyRuleDisabled
        with input.protection_policy_rules as ProtectionRulesDisabled

    ReportDetailString := "Requirement met. No active compliant preset or Custom policy. All active policies evaluated"
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, true) == true
}

test_SpamPolicy_Incorrect_DefaultSpamAction if {
    # Default policy has non-compliant SpamAction set
    BadDefault := json.patch(DefaultPolicy, [{"op": "add", "path": "SpamAction", "value": "AddXHeader"}])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [BadDefault]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as []

    ReportDetailString := "No active compliant preset or Custom policy. All active policies evaluated. 1 anti-spam polic(ies) that may deliver spam/phishing to inbox: Default"
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, false) == true
}

test_SpamPolicy_Incorrect_DefaultHighConfidenceSpamAction if {
    # Default policy has non-compliant HighConfidenceSpamAction set
    BadDefault := json.patch(DefaultPolicy, [{"op": "add", "path": "HighConfidenceSpamAction", "value": "AddXHeader"}])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [BadDefault]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as []

    ReportDetailString := "No active compliant preset or Custom policy. All active policies evaluated. 1 anti-spam polic(ies) that may deliver spam/phishing to inbox: Default"
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, false) == true
}

test_SpamPolicy_Incorrect_DefaultPhishSpamAction if {
    # Default policy has non-compliant PhishSpamAction set
    BadDefault := json.patch(DefaultPolicy, [{"op": "add", "path": "PhishSpamAction", "value": "AddXHeader"}])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [BadDefault]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as []

    ReportDetailString := "No active compliant preset or Custom policy. All active policies evaluated. 1 anti-spam polic(ies) that may deliver spam/phishing to inbox: Default"
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, false) == true
}

test_SpamPolicy_Incorrect_DefaultHighConfidencePhishAction if {
    # Default policy has non-compliant HighConfidencePhishAction set
    BadDefault := json.patch(DefaultPolicy, [{"op": "add", "path": "HighConfidencePhishAction", "value": "AddXHeader"}])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [BadDefault]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as []

    ReportDetailString := "No active compliant preset or Custom policy. All active policies evaluated. 1 anti-spam polic(ies) that may deliver spam/phishing to inbox: Default"
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, false) == true
}

test_SpamPolicy_Incorrect_StandardPresetSpamAction if {
    # Standard preset policy has non-compliant SpamAction set
    BadStandard := json.patch(StandardPresetPolicy, [{"op": "add", "path": "SpamAction", "value": "AddXHeader"}])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, BadStandard]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as ProtectionPolicyRulesEnabled

    ReportDetailString := concat("", [
        "No active compliant preset or Custom policy. All active policies evaluated. 1 anti-spam polic(ies) that may deliver spam/phishing to inbox: ",
        StandardPresetPolicy.Identity
    ])
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, false) == true
}

test_SpamPolicy_Incorrect_StrictPresetPhishSpamAction if {
    # Strict preset policy has non-compliant PhishSpamAction set
    BadStrict := json.patch(StrictPresetPolicy, [{"op": "add", "path": "PhishSpamAction", "value": "AddXHeader"}])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, BadStrict]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as ProtectionPolicyRulesEnabled

    ReportDetailString := concat("", [
        "No active compliant preset or Custom policy. All active policies evaluated. 1 anti-spam polic(ies) that may deliver spam/phishing to inbox: ",
        StrictPresetPolicy.Identity
    ])
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, false) == true
}

test_SpamPolicy_Incorrect_ActiveCustomSpamAction if {
    # Custom policy has non-compliant SpamAction set
    BadCustom := json.patch(CustomPolicy, [{"op": "add", "path": "SpamAction", "value": "AddXHeader"}])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, BadCustom]
        with input.hosted_content_filter_rules as CustomPolicyRuleEnabled
        with input.protection_policy_rules as []

    ReportDetailString := "No active compliant preset or Custom policy. All active policies evaluated. 1 anti-spam polic(ies) that may deliver spam/phishing to inbox: Custom Policy A"
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, false) == true
}

test_SpamPolicy_Incorrect_TwoPoliciesFail if {
    # Default and custom policies have non-compliant SpamAction set
    BadDefault := json.patch(DefaultPolicy, [{"op": "add", "path": "SpamAction", "value": "AddXHeader"}])
    BadCustom := json.patch(CustomPolicy, [{"op": "add", "path": "SpamAction", "value": "AddXHeader"}])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [BadDefault, BadCustom]
        with input.hosted_content_filter_rules as CustomPolicyRuleEnabled
        with input.protection_policy_rules as []

    ReportDetailString := concat("", [
        "No active compliant preset or Custom policy. All active policies evaluated. 2 anti-spam polic(ies) that may deliver spam/phishing to inbox: ",
        concat(", ", {"Custom Policy A", "Default"})
    ])
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, false) == true
}

test_SpamPolicy_Incorrect_OnlyStrictFails if {
    # All four policy types are active; Strict has a non-compliant action.
    # Standard is compliant and shields Custom and Default.
    BadStrict := json.patch(StrictPresetPolicy, [{"op": "add", "path": "HighConfidencePhishAction", "value": "AddXHeader"}])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, StandardPresetPolicy, BadStrict, CustomPolicy]
        with input.hosted_content_filter_rules as CustomPolicyRuleEnabled
        with input.protection_policy_rules as ProtectionPolicyRulesEnabled

    ReportDetailString := concat("", [
        "Standard preset is active and compliant (Strict not active or non-compliant). Custom and Default policies not evaluated. 1 anti-spam polic(ies) that may deliver spam/phishing to inbox: ",
        StrictPresetPolicy.Identity
    ])
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, false) == true
}

test_SpamPolicy_Incorrect_AllPoliciesFail if {
    # All four policy types are active and have non-compliant SpamAction set
    BadDefault := json.patch(DefaultPolicy, [{"op": "add", "path": "SpamAction", "value": "AddXHeader"}])
    BadStandard := json.patch(StandardPresetPolicy, [{"op": "add", "path": "SpamAction", "value": "AddXHeader"}])
    BadStrict := json.patch(StrictPresetPolicy, [{"op": "add", "path": "SpamAction", "value": "AddXHeader"}])
    BadCustom := json.patch(CustomPolicy, [{"op": "add", "path": "SpamAction", "value": "AddXHeader"}])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [BadDefault, BadStandard, BadStrict, BadCustom]
        with input.hosted_content_filter_rules as CustomPolicyRuleEnabled
        with input.protection_policy_rules as ProtectionPolicyRulesEnabled

    ReportDetailString := concat("", [
        "No active compliant preset or Custom policy. All active policies evaluated. 4 anti-spam polic(ies) that may deliver spam/phishing to inbox: ",
        concat(", ", {
            "Custom Policy A",
            "Default",
            StandardPresetPolicy.Identity,
            StrictPresetPolicy.Identity
        })
    ])
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, false) == true
}

test_SpamPolicy_Correct_StrictCompliantShieldsNonCompliantStandard if {
    # Strict preset is active and compliant; Standard is active but non-compliant.
    # Per precedence, Strict shields Standard, Custom, and Default.
    BadStandard := json.patch(StandardPresetPolicy, [{"op": "add", "path": "SpamAction", "value": "AddXHeader"}])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, BadStandard, StrictPresetPolicy]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as ProtectionPolicyRulesEnabled

    ReportDetailString := "Requirement met. Strict preset is active and compliant. Standard preset, Custom, and Default policies not evaluated"
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, true) == true
}

test_SpamPolicy_Correct_PresetCompliantShieldsNonCompliantCustom if {
    # Standard preset is active and compliant; Custom is active but non-compliant.
    # Per precedence, Standard shields Custom and Default.
    BadCustom := json.patch(CustomPolicy, [{"op": "add", "path": "SpamAction", "value": "AddXHeader"}])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, StandardPresetPolicy, BadCustom]
        with input.hosted_content_filter_rules as CustomPolicyRuleEnabled
        with input.protection_policy_rules as ProtectionPolicyRulesEnabled

    ReportDetailString := "Requirement met. Standard preset is active and compliant (Strict not active or non-compliant). Custom and Default policies not evaluated"
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, true) == true
}

test_SpamPolicy_Correct_StrictCompliantShieldsDefault if {
    # Strict preset is active and compliant; Default has non-compliant spam actions.
    # Per precedence, Strict shields Standard, Custom, and Default — Default is not evaluated.
    BadDefault := json.patch(DefaultPolicy, [{"op": "add", "path": "SpamAction", "value": "AddXHeader"}])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [BadDefault, StrictPresetPolicy]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as ProtectionPolicyRulesEnabled

    ReportDetailString := "Requirement met. Strict preset is active and compliant. Standard preset, Custom, and Default policies not evaluated"
    TestResult("MS.SECURITYSUITE.6.1v1", Output, ReportDetailString, true) == true
}
#--

#
# MS.SECURITYSUITE.6.2v1
#--

test_AllowedDomains_Correct_DefaultOnly if {
    # Default policy is active with no allowed domains
    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as []

    ReportDetailString := "Requirement met. No active compliant preset or Custom policy. All active policies evaluated"
    TestResult("MS.SECURITYSUITE.6.2v1", Output, ReportDetailString, true) == true
}

test_AllowedDomains_Correct_BothPresetsEnabled if {
    # Default and standard/strict preset policies are active with no allowed domains
    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, StandardPresetPolicy, StrictPresetPolicy]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as ProtectionPolicyRulesEnabled

    ReportDetailString := "Requirement met. Strict preset is active and compliant. Standard preset, Custom, and Default policies not evaluated"
    TestResult("MS.SECURITYSUITE.6.2v1", Output, ReportDetailString, true) == true
}

test_AllowedDomains_Correct_ActiveCustom if {
    # Default and custom policies are active with no allowed domains
    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, CustomPolicy]
        with input.hosted_content_filter_rules as CustomPolicyRuleEnabled
        with input.protection_policy_rules as []

    ReportDetailString := "Requirement met. No active compliant preset. Custom policy evaluation applied; Default policy not evaluated"
    TestResult("MS.SECURITYSUITE.6.2v1", Output, ReportDetailString, true) == true
}

test_AllowedDomains_Correct_CustomWithDomainButDisabled if {
    # Custom policy set with allowed domains but its rule is disabled
    CustomWithDomains := json.patch(CustomPolicy, [
        {"op": "add", "path": "AllowedSenderDomains", "value": ["example.com"]}
    ])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, CustomWithDomains]
        with input.hosted_content_filter_rules as CustomPolicyRuleDisabled
        with input.protection_policy_rules as []

    ReportDetailString := "Requirement met. No active compliant preset or Custom policy. All active policies evaluated"
    TestResult("MS.SECURITYSUITE.6.2v1", Output, ReportDetailString, true) == true
}

test_AllowedDomains_Correct_PresetWithDomainButRulesDisabled if {
    # Standard policy set with allowed domains but rules are disabled
    StandardWithDomains := json.patch(StandardPresetPolicy, [
        {"op": "add", "path": "AllowedSenderDomains", "value": ["example.com"]}
    ])
    ProtectionRulesDisabled := [
        json.patch(ProtectionPolicyRulesEnabled[0], [{"op": "add", "path": "State", "value": "Disabled"}]),
        json.patch(ProtectionPolicyRulesEnabled[1], [{"op": "add", "path": "State", "value": "Disabled"}])
    ]

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, StandardWithDomains]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as ProtectionRulesDisabled

    ReportDetailString := "Requirement met. No active compliant preset or Custom policy. All active policies evaluated"
    TestResult("MS.SECURITYSUITE.6.2v1", Output, ReportDetailString, true) == true
}

test_AllowedDomains_Correct_AllPolicyTypes if {
    # All four policies active with no allowed domains
    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, StandardPresetPolicy, StrictPresetPolicy, CustomPolicy]
        with input.hosted_content_filter_rules as CustomPolicyRuleEnabled
        with input.protection_policy_rules as ProtectionPolicyRulesEnabled

    ReportDetailString := "Requirement met. Strict preset is active and compliant. Standard preset, Custom, and Default policies not evaluated"
    TestResult("MS.SECURITYSUITE.6.2v1", Output, ReportDetailString, true) == true
}

test_AllowedDomains_Incorrect_Default if {
    # Default policy active with allowed domains
    BadDefault := json.patch(DefaultPolicy, [
        {"op": "add", "path": "AllowedSenderDomains", "value": ["example.com"]}
    ])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [BadDefault]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as []

    ReportDetailString := "No active compliant preset or Custom policy. All active policies evaluated. 1 anti-spam polic(ies) with allowed domains: Default"
    TestResult("MS.SECURITYSUITE.6.2v1", Output, ReportDetailString, false) == true
}

test_AllowedDomains_Incorrect_StandardPreset if {
    # Standard preset policy active with allowed domains
    BadStandard := json.patch(StandardPresetPolicy, [
        {"op": "add", "path": "AllowedSenderDomains", "value": ["example.com"]}
    ])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, BadStandard]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as ProtectionPolicyRulesEnabled

    ReportDetailString := concat("", [
        "No active compliant preset or Custom policy. All active policies evaluated. 1 anti-spam polic(ies) with allowed domains: ",
        StandardPresetPolicy.Identity
    ])
    TestResult("MS.SECURITYSUITE.6.2v1", Output, ReportDetailString, false) == true
}

test_AllowedDomains_Incorrect_StrictPreset if {
    # Strict preset policy active with allowed domains
    BadStrict := json.patch(StrictPresetPolicy, [
        {"op": "add", "path": "AllowedSenderDomains", "value": ["example.com"]}
    ])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, BadStrict]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as ProtectionPolicyRulesEnabled

    ReportDetailString := concat("", [
        "No active compliant preset or Custom policy. All active policies evaluated. 1 anti-spam polic(ies) with allowed domains: ",
        StrictPresetPolicy.Identity
    ])
    TestResult("MS.SECURITYSUITE.6.2v1", Output, ReportDetailString, false) == true
}

test_AllowedDomains_Incorrect_ActiveCustom if {
    # Custom policy active with allowed domains
    BadCustom := json.patch(CustomPolicy, [
        {"op": "add", "path": "AllowedSenderDomains", "value": ["example.com"]}
    ])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, BadCustom]
        with input.hosted_content_filter_rules as CustomPolicyRuleEnabled
        with input.protection_policy_rules as []

    ReportDetailString := "No active compliant preset or Custom policy. All active policies evaluated. 1 anti-spam polic(ies) with allowed domains: Custom Policy A"
    TestResult("MS.SECURITYSUITE.6.2v1", Output, ReportDetailString, false) == true
}

test_AllowedDomains_Correct_StrictCompliantShieldsNonCompliantStandardAndDefault if {
    # Strict preset is active and compliant, shielding non-compliant Standard and Default per precedence.
    BadDefault := json.patch(DefaultPolicy, [
        {"op": "add", "path": "AllowedSenderDomains", "value": ["example.com"]}
    ])
    BadStandard := json.patch(StandardPresetPolicy, [
        {"op": "add", "path": "AllowedSenderDomains", "value": ["example.com"]}
    ])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [BadDefault, BadStandard, StrictPresetPolicy]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as ProtectionPolicyRulesEnabled

    ReportDetailString := "Requirement met. Strict preset is active and compliant. Standard preset, Custom, and Default policies not evaluated"
    TestResult("MS.SECURITYSUITE.6.2v1", Output, ReportDetailString, true) == true
}

test_AllowedDomains_Correct_StrictCompliantShieldsAll if {
    # Both presets are active and compliant, shielding non-compliant Custom and Default per precedence.
    BadDefault := json.patch(DefaultPolicy, [
        {"op": "add", "path": "AllowedSenderDomains", "value": ["example.com"]}
    ])
    BadCustom := json.patch(CustomPolicy, [
        {"op": "add", "path": "AllowedSenderDomains", "value": ["example.com"]}
    ])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [BadDefault, StandardPresetPolicy, StrictPresetPolicy, BadCustom]
        with input.hosted_content_filter_rules as CustomPolicyRuleEnabled
        with input.protection_policy_rules as ProtectionPolicyRulesEnabled

    ReportDetailString := "Requirement met. Strict preset is active and compliant. Standard preset, Custom, and Default policies not evaluated"
    TestResult("MS.SECURITYSUITE.6.2v1", Output, ReportDetailString, true) == true
}

test_AllowedDomains_Incorrect_AllPoliciesFail if {
    # All four policies active with allowed domains
    BadDefault := json.patch(DefaultPolicy, [
        {"op": "add", "path": "AllowedSenderDomains", "value": ["example.com"]}
    ])
    BadStandard := json.patch(StandardPresetPolicy, [
        {"op": "add", "path": "AllowedSenderDomains", "value": ["example.com"]}
    ])
    BadStrict := json.patch(StrictPresetPolicy, [
        {"op": "add", "path": "AllowedSenderDomains", "value": ["example.com"]}
    ])
    BadCustom := json.patch(CustomPolicy, [
        {"op": "add", "path": "AllowedSenderDomains", "value": ["example.com"]}
    ])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [BadDefault, BadStandard, BadStrict, BadCustom]
        with input.hosted_content_filter_rules as CustomPolicyRuleEnabled
        with input.protection_policy_rules as ProtectionPolicyRulesEnabled

    ReportDetailString := concat("", [
        "No active compliant preset or Custom policy. All active policies evaluated. 4 anti-spam polic(ies) with allowed domains: ",
        concat(", ", {
            "Custom Policy A",
            "Default",
            StandardPresetPolicy.Identity,
            StrictPresetPolicy.Identity
        })
    ])
    TestResult("MS.SECURITYSUITE.6.2v1", Output, ReportDetailString, false) == true
}

test_AllowedDomains_Correct_StrictCompliantShieldsNonCompliantStandard if {
    # Strict preset is active and compliant; Standard is active but has allowed domains.
    # Per precedence, Strict shields Standard, Custom, and Default.
    BadStandard := json.patch(StandardPresetPolicy, [
        {"op": "add", "path": "AllowedSenderDomains", "value": ["example.com"]}
    ])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, BadStandard, StrictPresetPolicy]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as ProtectionPolicyRulesEnabled

    ReportDetailString := "Requirement met. Strict preset is active and compliant. Standard preset, Custom, and Default policies not evaluated"
    TestResult("MS.SECURITYSUITE.6.2v1", Output, ReportDetailString, true) == true
}

test_AllowedDomains_Correct_PresetCompliantShieldsNonCompliantCustom if {
    # Standard preset is active and compliant; Custom is active but has allowed domains.
    # Per precedence, Standard shields Custom and Default.
    BadCustom := json.patch(CustomPolicy, [
        {"op": "add", "path": "AllowedSenderDomains", "value": ["example.com"]}
    ])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, StandardPresetPolicy, BadCustom]
        with input.hosted_content_filter_rules as CustomPolicyRuleEnabled
        with input.protection_policy_rules as ProtectionPolicyRulesEnabled

    ReportDetailString := "Requirement met. Standard preset is active and compliant (Strict not active or non-compliant). Custom and Default policies not evaluated"
    TestResult("MS.SECURITYSUITE.6.2v1", Output, ReportDetailString, true) == true
}

test_AllowedDomains_Correct_StrictCompliantShieldsDefault if {
    # Strict preset is active and compliant; Default has allowed domains.
    # Per precedence, Strict shields Standard, Custom, and Default — Default is not evaluated.
    BadDefault := json.patch(DefaultPolicy, [
        {"op": "add", "path": "AllowedSenderDomains", "value": ["example.com"]}
    ])

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [BadDefault, StrictPresetPolicy]
        with input.hosted_content_filter_rules as []
        with input.protection_policy_rules as ProtectionPolicyRulesEnabled

    ReportDetailString := "Requirement met. Strict preset is active and compliant. Standard preset, Custom, and Default policies not evaluated"
    TestResult("MS.SECURITYSUITE.6.2v1", Output, ReportDetailString, true) == true
}

test_AllowedDomains_Incorrect_TwoCustomPoliciesOneDisabledOneEnabled if {
    # Two custom policies: Policy A is compliant but rule is disabled; Policy B has allowed domains and is enabled.
    # Since Policy A's rule is disabled it is not active, so AnyCustomIsCompliantForDomains is false.
    # Policy B is active and non-compliant; Default has no shielding.
    CustomPolicy2 := {
        "Identity": "Custom Policy B",
        "IsDefault": false,
        "RecommendedPolicyType": "Custom",
        "SpamAction": "MoveToJmf",
        "HighConfidenceSpamAction": "Quarantine",
        "PhishSpamAction": "Quarantine",
        "HighConfidencePhishAction": "Quarantine",
        "AllowedSenderDomains": ["example.com"]
    }
    CustomPolicy2RuleEnabled := [
        {
            "Identity": "Custom Policy B Rule",
            "HostedContentFilterPolicy": "Custom Policy B",
            "State": "Enabled"
        }
    ]

    Output := securitysuite.tests
        with input.hosted_content_filter_policies as [DefaultPolicy, CustomPolicy, CustomPolicy2]
        with input.hosted_content_filter_rules as array.concat(CustomPolicyRuleDisabled, CustomPolicy2RuleEnabled)
        with input.protection_policy_rules as []

    ReportDetailString := "No active compliant preset or Custom policy. All active policies evaluated. 1 anti-spam polic(ies) with allowed domains: Custom Policy B"
    TestResult("MS.SECURITYSUITE.6.2v1", Output, ReportDetailString, false) == true
}
