package securitysuite_test
import rego.v1
import data.securitysuite
import data.utils.key.TestResultContains

# anti_malware_rules sentinel value representing "no custom policies exist in tenant"
NullAntiMalwareRules := [null]

# =============================================================================
# Order of priority for anti-malware policies:
#   1  Strict Preset Security   - highest precedence
#   2  Standard Preset Security - Microsoft-managed baseline
#   3  Custom anti-malware policies - lowest Priority number wins; if the
#      winning-priority rule doesn't cover all recipients, there is NO
#      fallback to the next custom rule (known/accepted limitation - see
#      test_CustomRuleNotCoveringDomains_FallsToDefault below).
#   4  Default policy - applies if nothing else matches.
#
# Policies MS.SECURITYSUITE.1.1v1 and MS.SECURITYSUITE.1.2v1
# =============================================================================

# Strict preset is enabled, unscoped, and compliant -> Strict wins outright.
test_StrictWins_Compliant if {
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.protection_policy_rules as ProtectionPolicyRules
                                  with input.anti_malware_policies as AntiMalwarePolicies
                                  with input.anti_malware_rules as AntiMalwareRules

    ReportStrings1_1 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Strict Preset."]
    TestResultContains("MS.SECURITYSUITE.1.1v1", Output, ReportStrings1_1, true) == true

    ReportStrings1_2 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Strict Preset."]
    TestResultContains("MS.SECURITYSUITE.1.2v1", Output, ReportStrings1_2, true) == true
}

# Strict disabled entirely -> Standard wins.
test_StandardWins_Compliant if {
    ModifiedRules := json.patch(ProtectionPolicyRules, [{"op": "replace", "path": "1/State", "value": "Disabled"}])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.protection_policy_rules as ModifiedRules
                                  with input.anti_malware_policies as AntiMalwarePolicies
                                  with input.anti_malware_rules as AntiMalwareRules

    ReportStrings1_1 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Standard Preset."]
    TestResultContains("MS.SECURITYSUITE.1.1v1", Output, ReportStrings1_1, true) == true

    ReportStrings1_2 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Standard Preset."]
    TestResultContains("MS.SECURITYSUITE.1.2v1", Output, ReportStrings1_2, true) == true
}

# Strict enabled but scoped to specific users (SentTo populated) -> doesn't cover
# all recipients -> Standard wins.
test_PresetScopedNotAllRecipients_SkipsToStandard if {
    ModifiedRules := json.patch(ProtectionPolicyRules, [{"op": "replace", "path": "1/SentTo", "value": ["user@example.com"]}])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.protection_policy_rules as ModifiedRules
                                  with input.anti_malware_policies as AntiMalwarePolicies
                                  with input.anti_malware_rules as AntiMalwareRules

    ReportStrings1_1 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Standard Preset."]
    TestResultContains("MS.SECURITYSUITE.1.1v1", Output, ReportStrings1_1, true) == true

    ReportStrings1_2 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Standard Preset."]
    TestResultContains("MS.SECURITYSUITE.1.2v1", Output, ReportStrings1_2, true) == true
}

# Both presets enabled but BOTH scoped (not all-recipients) -> falls through
# both preset tiers to Custom1.
test_BothPresetsScoped_FallsThroughToCustom if {
    ModifiedRules := json.patch(ProtectionPolicyRules, [
        {"op": "replace", "path": "1/SentTo", "value": ["user@example.com"]},
        {"op": "replace", "path": "0/SentToMemberOf", "value": ["Group1"]}
    ])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.protection_policy_rules as ModifiedRules
                                  with input.anti_malware_policies as AntiMalwarePolicies
                                  with input.anti_malware_rules as AntiMalwareRules

    ReportStrings1_1 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Custom antimalware policy 1."]
    TestResultContains("MS.SECURITYSUITE.1.1v1", Output, ReportStrings1_1, true) == true

    ReportStrings1_2 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Custom antimalware policy 1."]
    TestResultContains("MS.SECURITYSUITE.1.2v1", Output, ReportStrings1_2, true) == true
}

# Both presets disabled -> Custom1 (Priority 0, covers all tenant domains) wins.
test_CustomWins_Compliant if {
    PresetsDisabled := json.patch(ProtectionPolicyRules, [
        {"op": "replace", "path": "0/State", "value": "Disabled"},
        {"op": "replace", "path": "1/State", "value": "Disabled"}
    ])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.protection_policy_rules as PresetsDisabled
                                  with input.anti_malware_policies as AntiMalwarePolicies
                                  with input.anti_malware_rules as AntiMalwareRules

    ReportStrings1_1 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Custom antimalware policy 1."]
    TestResultContains("MS.SECURITYSUITE.1.1v1", Output, ReportStrings1_1, true) == true

    ReportStrings1_2 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Custom antimalware policy 1."]
    TestResultContains("MS.SECURITYSUITE.1.2v1", Output, ReportStrings1_2, true) == true
}

# Custom2 now has the lower Priority number -> Custom2 wins instead of Custom1.
test_CustomPriorityOrder_Policy2Wins if {
    PresetsDisabled := json.patch(ProtectionPolicyRules, [
        {"op": "replace", "path": "0/State", "value": "Disabled"},
        {"op": "replace", "path": "1/State", "value": "Disabled"}
    ])
    SwappedPriority := json.patch(AntiMalwareRules, [
        {"op": "replace", "path": "0/Priority", "value": 1},
        {"op": "replace", "path": "1/Priority", "value": 0}
    ])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.protection_policy_rules as PresetsDisabled
                                  with input.anti_malware_policies as AntiMalwarePolicies
                                  with input.anti_malware_rules as SwappedPriority

    ReportStrings1_1 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Custom antimalware policy 2."]
    TestResultContains("MS.SECURITYSUITE.1.1v1", Output, ReportStrings1_1, true) == true

    ReportStrings1_2 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Custom antimalware policy 2."]
    TestResultContains("MS.SECURITYSUITE.1.2v1", Output, ReportStrings1_2, true) == true
}

# Top-priority Custom1 no longer covers all tenant domains (missing one domain).
# There is NO fallback to Custom2 -> falls all the way to Default.
# NOTE: this pins down a known/accepted limitation, not a desired UX.
test_CustomRuleNotCoveringDomains_FallsToDefault if {
    PresetsDisabled := json.patch(ProtectionPolicyRules, [
        {"op": "replace", "path": "0/State", "value": "Disabled"},
        {"op": "replace", "path": "1/State", "value": "Disabled"}
    ])
    Custom1MissingDomain := json.patch(AntiMalwareRules, [
        {"op": "replace", "path": "0/RecipientDomainIs", "value": ["example.com"]}
    ])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.protection_policy_rules as PresetsDisabled
                                  with input.anti_malware_policies as AntiMalwarePolicies
                                  with input.anti_malware_rules as Custom1MissingDomain

    ReportStrings1_1 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Default."]
    TestResultContains("MS.SECURITYSUITE.1.1v1", Output, ReportStrings1_1, true) == true

    ReportStrings1_2 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Default."]
    TestResultContains("MS.SECURITYSUITE.1.2v1", Output, ReportStrings1_2, true) == true
}

# No enabled custom rules (both disabled) -> Default.
test_CustomRulesDisabled_FallsToDefault if {
    PresetsDisabled := json.patch(ProtectionPolicyRules, [
        {"op": "replace", "path": "0/State", "value": "Disabled"},
        {"op": "replace", "path": "1/State", "value": "Disabled"}
    ])
    RulesDisabled := json.patch(AntiMalwareRules, [
        {"op": "replace", "path": "0/State", "value": "Disabled"},
        {"op": "replace", "path": "1/State", "value": "Disabled"}
    ])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.protection_policy_rules as PresetsDisabled
                                  with input.anti_malware_policies as AntiMalwarePolicies
                                  with input.anti_malware_rules as RulesDisabled

    ReportStrings1_1 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Default."]
    TestResultContains("MS.SECURITYSUITE.1.1v1", Output, ReportStrings1_1, true) == true

    ReportStrings1_2 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Default."]
    TestResultContains("MS.SECURITYSUITE.1.2v1", Output, ReportStrings1_2, true) == true
}

# anti_malware_rules == [null] sentinel (no custom policies exist in tenant) -> Default.
test_NoCustomRules_NullSentinel_FallsToDefault if {
    PresetsDisabled := json.patch(ProtectionPolicyRules, [
        {"op": "replace", "path": "0/State", "value": "Disabled"},
        {"op": "replace", "path": "1/State", "value": "Disabled"}
    ])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.protection_policy_rules as PresetsDisabled
                                  with input.anti_malware_policies as AntiMalwarePolicies
                                  with input.anti_malware_rules as NullAntiMalwareRules

    ReportStrings1_1 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Default."]
    TestResultContains("MS.SECURITYSUITE.1.1v1", Output, ReportStrings1_1, true) == true

    ReportStrings1_2 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Default."]
    TestResultContains("MS.SECURITYSUITE.1.2v1", Output, ReportStrings1_2, true) == true
}

# Custom1 lists an extra domain beyond the tenant's accepted domains -> still a
# valid superset -> still covers all recipients -> Custom1 wins.
test_CustomRuleDomainSupersetWithExtra_StillCovers if {
    PresetsDisabled := json.patch(ProtectionPolicyRules, [
        {"op": "replace", "path": "0/State", "value": "Disabled"},
        {"op": "replace", "path": "1/State", "value": "Disabled"}
    ])
    Custom1ExtraDomain := json.patch(AntiMalwareRules, [
        {"op": "replace", "path": "0/RecipientDomainIs", "value": ["example.com", "example.mail.onmicrosoft.com", "extra.example.com"]}
    ])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.protection_policy_rules as PresetsDisabled
                                  with input.anti_malware_policies as AntiMalwarePolicies
                                  with input.anti_malware_rules as Custom1ExtraDomain

    ReportStrings1_1 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Custom antimalware policy 1."]
    TestResultContains("MS.SECURITYSUITE.1.1v1", Output, ReportStrings1_1, true) == true

    ReportStrings1_2 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Custom antimalware policy 1."]
    TestResultContains("MS.SECURITYSUITE.1.2v1", Output, ReportStrings1_2, true) == true
}

# Custom1 active, EnableFileFilter off -> 1.1 fails (single reason), 1.2 unaffected.
test_CustomActive_FileFilterDisabled if {
    PresetsDisabled := json.patch(ProtectionPolicyRules, [
        {"op": "replace", "path": "0/State", "value": "Disabled"},
        {"op": "replace", "path": "1/State", "value": "Disabled"}
    ])
    Custom1FilterOff := json.patch(AntiMalwarePolicies, [
        {"op": "replace", "path": "2/EnableFileFilter", "value": false}
    ])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.protection_policy_rules as PresetsDisabled
                                  with input.anti_malware_policies as Custom1FilterOff
                                  with input.anti_malware_rules as AntiMalwareRules

    ReportStrings1_1 := [
        "Requirement not met. The highest priority anti-malware policy that applies to all users is: Custom antimalware policy 1.",
        "The common attachments filter is disabled."
    ]
    TestResultContains("MS.SECURITYSUITE.1.1v1", Output, ReportStrings1_1, false) == true

    ReportStrings1_2 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Custom antimalware policy 1."]
    TestResultContains("MS.SECURITYSUITE.1.2v1", Output, ReportStrings1_2, true) == true
}

# Custom1 active, 'exe' missing from FileTypes -> 1.1 fails (single reason), 1.2 unaffected.
test_CustomActive_MissingFileType if {
    PresetsDisabled := json.patch(ProtectionPolicyRules, [
        {"op": "replace", "path": "0/State", "value": "Disabled"},
        {"op": "replace", "path": "1/State", "value": "Disabled"}
    ])
    Custom1MissingExe := json.patch(AntiMalwarePolicies, [
        {"op": "replace", "path": "2/FileTypes", "value": ["cmd", "vbe"]}
    ])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.protection_policy_rules as PresetsDisabled
                                  with input.anti_malware_policies as Custom1MissingExe
                                  with input.anti_malware_rules as AntiMalwareRules

    ReportStrings1_1 := [
        "Requirement not met. The highest priority anti-malware policy that applies to all users is: Custom antimalware policy 1.",
        "The common attachments filter does not include exe."
    ]
    TestResultContains("MS.SECURITYSUITE.1.1v1", Output, ReportStrings1_1, false) == true

    ReportStrings1_2 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Custom antimalware policy 1."]
    TestResultContains("MS.SECURITYSUITE.1.2v1", Output, ReportStrings1_2, true) == true
}

# Custom1 active, ZapEnabled off -> 1.2 fails, 1.1 unaffected.
test_CustomActive_ZapDisabled if {
    PresetsDisabled := json.patch(ProtectionPolicyRules, [
        {"op": "replace", "path": "0/State", "value": "Disabled"},
        {"op": "replace", "path": "1/State", "value": "Disabled"}
    ])
    Custom1ZapOff := json.patch(AntiMalwarePolicies, [
        {"op": "replace", "path": "2/ZapEnabled", "value": false}
    ])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.protection_policy_rules as PresetsDisabled
                                  with input.anti_malware_policies as Custom1ZapOff
                                  with input.anti_malware_rules as AntiMalwareRules

    ReportStrings1_1 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Custom antimalware policy 1."]
    TestResultContains("MS.SECURITYSUITE.1.1v1", Output, ReportStrings1_1, true) == true

    ReportStrings1_2 := [
        "Requirement not met. The highest priority anti-malware policy that applies to all users is: Custom antimalware policy 1.",
        "Zero-hour auto purge is disabled."
    ]
    TestResultContains("MS.SECURITYSUITE.1.2v1", Output, ReportStrings1_2, false) == true
}

# Custom1 active, BOTH EnableFileFilter off AND 'vbe' missing -> 1.1 fails with two
# co-occurring reasons. Order of the two reason strings in the actual ReportDetails
# is not guaranteed (set iteration), so we check both substrings independently via
# TestResultContains rather than asserting an exact concatenated string. 1.2 unaffected.
test_CustomActive_CombinedFailure if {
    PresetsDisabled := json.patch(ProtectionPolicyRules, [
        {"op": "replace", "path": "0/State", "value": "Disabled"},
        {"op": "replace", "path": "1/State", "value": "Disabled"}
    ])
    Custom1CombinedFailure := json.patch(AntiMalwarePolicies, [
        {"op": "replace", "path": "2/EnableFileFilter", "value": false},
        {"op": "replace", "path": "2/FileTypes", "value": ["exe", "cmd"]}
    ])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.protection_policy_rules as PresetsDisabled
                                  with input.anti_malware_policies as Custom1CombinedFailure
                                  with input.anti_malware_rules as AntiMalwareRules

    ReportStrings1_1 := [
        "Requirement not met. The highest priority anti-malware policy that applies to all users is: Custom antimalware policy 1.",
        "The common attachments filter is disabled.",
        "The common attachments filter does not include vbe."
    ]
    TestResultContains("MS.SECURITYSUITE.1.1v1", Output, ReportStrings1_1, false) == true

    ReportStrings1_2 := ["Requirement met. The highest priority anti-malware policy that applies to all users is: Custom antimalware policy 1."]
    TestResultContains("MS.SECURITYSUITE.1.2v1", Output, ReportStrings1_2, true) == true
}

# Default active (no preset/custom applies), both compliance checks fail independently.
test_DefaultActive_BothFail if {
    PresetsDisabled := json.patch(ProtectionPolicyRules, [
        {"op": "replace", "path": "0/State", "value": "Disabled"},
        {"op": "replace", "path": "1/State", "value": "Disabled"}
    ])
    RulesDisabled := json.patch(AntiMalwareRules, [
        {"op": "replace", "path": "0/State", "value": "Disabled"},
        {"op": "replace", "path": "1/State", "value": "Disabled"}
    ])
    DefaultBothFail := json.patch(AntiMalwarePolicies, [
        {"op": "replace", "path": "4/EnableFileFilter", "value": false},
        {"op": "replace", "path": "4/ZapEnabled", "value": false}
    ])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.protection_policy_rules as PresetsDisabled
                                  with input.anti_malware_policies as DefaultBothFail
                                  with input.anti_malware_rules as RulesDisabled

    ReportStrings1_1 := [
        "Requirement not met. The highest priority anti-malware policy that applies to all users is: Default.",
        "The common attachments filter is disabled."
    ]
    TestResultContains("MS.SECURITYSUITE.1.1v1", Output, ReportStrings1_1, false) == true

    ReportStrings1_2 := [
        "Requirement not met. The highest priority anti-malware policy that applies to all users is: Default.",
        "Zero-hour auto purge is disabled."
    ]
    TestResultContains("MS.SECURITYSUITE.1.2v1", Output, ReportStrings1_2, false) == true
}


# =============================================================================
# Policy MS.SECURITYSUITE.1.3v1
#
# Order of priority: Strict preset -> Standard preset -> single top-Priority
# custom rule (must cover all recipients, no fallback to next rule) ->
# Built-In Protection Policy (covers all recipients unless narrowed via
# ExceptIf* fields) -> null (nothing applies -> not compliant).
# =============================================================================

# Strict preset active, Action compliant (Block) -> met.
test_StrictWins_Compliant_1_3 if {
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.atp_policy_rules as ProtectionPolicyRules
                                  with input.safe_attachment_policies as SafeAttachmentPolicies
                                  with input.safe_attachment_rules as SafeAttachmentRules
                                  with input.built_in_protection_rules as BuiltInProtectionRules
                                  with input.defender_license as true

    ReportStrings := ["Requirement met. The highest priority safe attachments policy that applies to all users is: Strict Preset."]
    TestResultContains("MS.SECURITYSUITE.1.3v1", Output, ReportStrings, true) == true
}

# Strict preset active, Action non-compliant (Allow) -> not met.
test_StrictWins_NonCompliant_1_3 if {
    NonCompliantAction := json.patch(SafeAttachmentPolicies, [{"op": "replace", "path": "0/Action", "value": "Allow"}])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.atp_policy_rules as ProtectionPolicyRules
                                  with input.safe_attachment_policies as NonCompliantAction
                                  with input.safe_attachment_rules as SafeAttachmentRules
                                  with input.built_in_protection_rules as BuiltInProtectionRules
                                  with input.defender_license as true

    ReportStrings := [
        "Requirement not met. The highest priority safe attachments policy that applies to all users is: Strict Preset.",
        "Safe Attachments unknown malware response is set to Allow."
    ]
    TestResultContains("MS.SECURITYSUITE.1.3v1", Output, ReportStrings, false) == true
}

# Strict disabled -> Standard active, Action compliant -> met.
test_StandardWins_Compliant_1_3 if {
    StrictDisabled := json.patch(ProtectionPolicyRules, [{"op": "replace", "path": "1/State", "value": "Disabled"}])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.atp_policy_rules as StrictDisabled
                                  with input.safe_attachment_policies as SafeAttachmentPolicies
                                  with input.safe_attachment_rules as SafeAttachmentRules
                                  with input.built_in_protection_rules as BuiltInProtectionRules
                                  with input.defender_license as true

    ReportStrings := ["Requirement met. The highest priority safe attachments policy that applies to all users is: Standard Preset."]
    TestResultContains("MS.SECURITYSUITE.1.3v1", Output, ReportStrings, true) == true
}

# Both presets disabled -> Custom1 (covers all tenant domains), Action compliant -> met.
test_CustomWins_Compliant_1_3 if {
    PresetsDisabled := json.patch(ProtectionPolicyRules, [
        {"op": "replace", "path": "0/State", "value": "Disabled"},
        {"op": "replace", "path": "1/State", "value": "Disabled"}
    ])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.atp_policy_rules as PresetsDisabled
                                  with input.safe_attachment_policies as SafeAttachmentPolicies
                                  with input.safe_attachment_rules as SafeAttachmentRules
                                  with input.built_in_protection_rules as BuiltInProtectionRules
                                  with input.defender_license as true

    ReportStrings := ["Requirement met. The highest priority safe attachments policy that applies to all users is: Custom Safe Attachment Policy 1."]
    TestResultContains("MS.SECURITYSUITE.1.3v1", Output, ReportStrings, true) == true
}

# Both presets disabled -> Custom1 active, Action non-compliant (Off) -> not met.
test_CustomWins_NonCompliant_1_3 if {
    PresetsDisabled := json.patch(ProtectionPolicyRules, [
        {"op": "replace", "path": "0/State", "value": "Disabled"},
        {"op": "replace", "path": "1/State", "value": "Disabled"}
    ])
    NonCompliantAction := json.patch(SafeAttachmentPolicies, [{"op": "replace", "path": "2/Action", "value": "Off"}])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.atp_policy_rules as PresetsDisabled
                                  with input.safe_attachment_policies as NonCompliantAction
                                  with input.safe_attachment_rules as SafeAttachmentRules
                                  with input.built_in_protection_rules as BuiltInProtectionRules
                                  with input.defender_license as true

    ReportStrings := [
        "Requirement not met. The highest priority safe attachments policy that applies to all users is: Custom Safe Attachment Policy 1.",
        "Safe Attachments unknown malware response is set to Off."
    ]
    TestResultContains("MS.SECURITYSUITE.1.3v1", Output, ReportStrings, false) == true
}

# Custom1's domain list is a superset (one extra domain beyond the tenant's) ->
# still covers all recipients -> Custom1 still wins.
test_CustomRuleDomainSupersetWithExtra_StillCovers_1_3 if {
    PresetsDisabled := json.patch(ProtectionPolicyRules, [
        {"op": "replace", "path": "0/State", "value": "Disabled"},
        {"op": "replace", "path": "1/State", "value": "Disabled"}
    ])
    ExtraDomain := json.patch(SafeAttachmentRules, [
        {"op": "replace", "path": "0/RecipientDomainIs", "value": ["example.com", "example.mail.onmicrosoft.com", "extra.example.com"]}
    ])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.atp_policy_rules as PresetsDisabled
                                  with input.safe_attachment_policies as SafeAttachmentPolicies
                                  with input.safe_attachment_rules as ExtraDomain
                                  with input.built_in_protection_rules as BuiltInProtectionRules
                                  with input.defender_license as true

    ReportStrings := ["Requirement met. The highest priority safe attachments policy that applies to all users is: Custom Safe Attachment Policy 1."]
    TestResultContains("MS.SECURITYSUITE.1.3v1", Output, ReportStrings, true) == true
}

# Top-priority (only) custom rule is scoped (SentTo populated) -> doesn't cover
# all recipients -> falls through to Built-In Protection Policy.
test_CustomRuleScoped_FallsToBuiltIn_1_3 if {
    PresetsDisabled := json.patch(ProtectionPolicyRules, [
        {"op": "replace", "path": "0/State", "value": "Disabled"},
        {"op": "replace", "path": "1/State", "value": "Disabled"}
    ])
    ScopedCustomRule := json.patch(SafeAttachmentRules, [
        {"op": "replace", "path": "0/SentTo", "value": ["user@example.com"]}
    ])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.atp_policy_rules as PresetsDisabled
                                  with input.safe_attachment_policies as SafeAttachmentPolicies
                                  with input.safe_attachment_rules as ScopedCustomRule
                                  with input.built_in_protection_rules as BuiltInProtectionRules
                                  with input.defender_license as true

    ReportStrings := ["Requirement met. The highest priority safe attachments policy that applies to all users is: Built-In Protection Policy."]
    TestResultContains("MS.SECURITYSUITE.1.3v1", Output, ReportStrings, true) == true
}

# No custom rules at all -> falls through to Built-In Protection Policy.
test_NoCustomRules_FallsToBuiltIn_1_3 if {
    PresetsDisabled := json.patch(ProtectionPolicyRules, [
        {"op": "replace", "path": "0/State", "value": "Disabled"},
        {"op": "replace", "path": "1/State", "value": "Disabled"}
    ])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.atp_policy_rules as PresetsDisabled
                                  with input.safe_attachment_policies as SafeAttachmentPolicies
                                  with input.safe_attachment_rules as []
                                  with input.built_in_protection_rules as BuiltInProtectionRules
                                  with input.defender_license as true

    ReportStrings := ["Requirement met. The highest priority safe attachments policy that applies to all users is: Built-In Protection Policy."]
    TestResultContains("MS.SECURITYSUITE.1.3v1", Output, ReportStrings, true) == true
}

# Nothing applies: no presets, no custom rules, no built-in protection rule
# present -> HighestPriorityActiveSafeAttachmentPolicyName is null -> not met.
test_NullActivePolicy_NoBuiltIn_1_3 if {
    PresetsDisabled := json.patch(ProtectionPolicyRules, [
        {"op": "replace", "path": "0/State", "value": "Disabled"},
        {"op": "replace", "path": "1/State", "value": "Disabled"}
    ])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.atp_policy_rules as PresetsDisabled
                                  with input.safe_attachment_policies as SafeAttachmentPolicies
                                  with input.safe_attachment_rules as []
                                  with input.built_in_protection_rules as []
                                  with input.defender_license as true

    ReportStrings := ["Requirement not met. No safe attachments policy applies to all users, including built-in protection."]
    TestResultContains("MS.SECURITYSUITE.1.3v1", Output, ReportStrings, false) == true
}

# Built-In Protection rule present but narrowed via ExceptIfSentTo -> no longer
# covers all recipients -> falls through to null, same as no built-in rule at all.
test_BuiltInHasExceptions_NullActivePolicy_1_3 if {
    PresetsDisabled := json.patch(ProtectionPolicyRules, [
        {"op": "replace", "path": "0/State", "value": "Disabled"},
        {"op": "replace", "path": "1/State", "value": "Disabled"}
    ])
    BuiltInWithException := json.patch(BuiltInProtectionRules, [
        {"op": "replace", "path": "0/ExceptIfSentTo", "value": ["user@example.com"]}
    ])
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.atp_policy_rules as PresetsDisabled
                                  with input.safe_attachment_policies as SafeAttachmentPolicies
                                  with input.safe_attachment_rules as []
                                  with input.built_in_protection_rules as BuiltInWithException
                                  with input.defender_license as true

    ReportStrings := ["Requirement not met. No safe attachments policy applies to all users, including built-in protection."]
    TestResultContains("MS.SECURITYSUITE.1.3v1", Output, ReportStrings, false) == true
}

# Tenant has no Defender for Office 365 Plan 1/2 license -> no ATP nodes exist
# (all empty) -> HighestPriorityActiveSafeAttachmentPolicyName resolves to null
# naturally (not an override) -> RequirementMet is false because the policy
# logic itself finds nothing, and ReportDetails is replaced entirely with the
# license warning text.
test_NoLicense_1_3 if {
    Output := securitysuite.tests with input.accepted_domains as AcceptedDomains
                                  with input.atp_policy_rules as []
                                  with input.safe_attachment_policies as []
                                  with input.safe_attachment_rules as []
                                  with input.built_in_protection_rules as []
                                  with input.defender_license as false

    # regal ignore:line-length
    ReportStrings := ["**NOTE: Either you do not have sufficient permissions or your tenant does not have a license for Microsoft Defender for Office 365 Plan 1 or Plan 2, which is required for this feature.**"]
    TestResultContains("MS.SECURITYSUITE.1.3v1", Output, ReportStrings, false) == true
}
#--


#
# Policy MS.SECURITYSUITE.1.4v1
#--

# At least one atp_policy_for_o365 entry has EnableATPForSPOTeamsODB == true -> met.
test_ATPPolicy_Compliant if {
    Output := securitysuite.tests with input.atp_policy_for_o365 as AtpPolicyForO365
                                  with input.defender_license as true

    ReportStrings := ["Requirement met"]
    TestResultContains("MS.SECURITYSUITE.1.4v1", Output, ReportStrings, true) == true
}

# The Default entry's EnableATPForSPOTeamsODB is false -> not met.
test_ATPPolicy_NonCompliant if {
    DefaultDisabled := json.patch(AtpPolicyForO365, [{"op": "replace", "path": "0/EnableATPForSPOTeamsODB", "value": false}])
    Output := securitysuite.tests with input.atp_policy_for_o365 as DefaultDisabled
                                  with input.defender_license as true

    ReportStrings := ["Requirement not met"]
    TestResultContains("MS.SECURITYSUITE.1.4v1", Output, ReportStrings, false) == true
}

# The compliant entry's EnableATPForSPOTeamsODB field is missing entirely
# (not just false) -> that entry can't match -> not met.
test_ATPPolicy_FieldMissing if {
    FieldRemoved := json.patch(AtpPolicyForO365, [{"op": "remove", "path": "0/EnableATPForSPOTeamsODB"}])
    Output := securitysuite.tests with input.atp_policy_for_o365 as FieldRemoved
                                  with input.defender_license as true

    ReportStrings := ["Requirement not met"]
    TestResultContains("MS.SECURITYSUITE.1.4v1", Output, ReportStrings, false) == true
}

# Tenant has no Defender license -> atp_policy_for_o365 is empty -> count(ATPPolicies)
# == 0 -> RequirementMet is false because the policy logic itself finds nothing,
# and ReportDetails is replaced entirely with the license warning text.
test_NoLicense_1_4 if {
    Output := securitysuite.tests with input.atp_policy_for_o365 as []
                                  with input.defender_license as false

    # regal ignore:line-length
    ReportStrings := ["**NOTE: Either you do not have sufficient permissions or your tenant does not have a license for Microsoft Defender for Office 365 Plan 1 or Plan 2, which is required for this feature.**"]
    TestResultContains("MS.SECURITYSUITE.1.4v1", Output, ReportStrings, false) == true
}
