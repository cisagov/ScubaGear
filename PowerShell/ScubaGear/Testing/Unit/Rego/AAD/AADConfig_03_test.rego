package aad_test
import rego.v1
import data.aad
import data.utils.report.CheckedSkippedDetails
import data.utils.key.TestResult
import data.utils.key.TestResultContains
import data.utils.key.FAIL
import data.utils.key.PASS


#
# Policy MS.AAD.3.1v1
#--
test_PhishingResistantAllMFA_Correct if {
    Output := aad.tests with input.conditional_access_policies as [ConditionalAccessPolicies]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.3.1v1", Output, ReportDetailStr, true) == true
}

test_PhishingResistantSingleMFA_Correct if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/AuthenticationStrength/AllowedCombinations",
                "value": ["x509CertificateMultiFactor"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.3.1v1", Output, ReportDetailStr, true) == true
}

test_PhishingResistantExtraMFA_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/AuthenticationStrength/AllowedCombinations",
                "value": [
                            "x509CertificateMultiFactor",
                            "SuperStrength"
                        ]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.1v1", Output, ReportDetailStr, false) == true
}

test_PhishingResistantNoneMFA_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/AuthenticationStrength/AllowedCombinations",
                "value": null}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.1v1", Output, ReportDetailStr, false) == true
}

test_PhishingResistantMFAExcludeApp_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Applications/ExcludeApplications",
                "value": ["Some App"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.1v1", Output, ReportDetailStr, false) == true
}

test_PhishingResistantMFAExcludeUser_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["me"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.1v1", Output, ReportDetailStr, false) == true
}

test_PhishingResistantMFAExcludeGroup_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["some"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.1v1", Output, ReportDetailStr, false) == true
}
#--

#
# Policy MS.AAD.3.2v1
#--
test_NoExclusionsConditions_Correct if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls",
                "value": ["mfa"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, true) == true
}

todo_test_3_1_Passes_3_2_Fails_Correct if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "DisplayName",
                "value": "Bad Test Policy"},
                {"op": "remove", "path": "GrantControls/BuiltInControls"}])
    CAP2 := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls",
                "value": [""]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP, CAP2]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, true) == true
}

todo_test_3_1_Fails_3_2_Passes_Correct if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "DisplayName",
                "value": "Bad Test Policy"},
                {"op": "remove", "path": "GrantControls/BuiltInControls"},
                {"op": "add", "path": "GrantControls/AuthenticationStrength/3", "value": "SuperStrength"}])
    CAP2 := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls",
                "value": ["mfa"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP, CAP2]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test name. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, true) == true
}

test_NoExclusionsExemptUsers_Correct if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls",
                "value": ["mfa"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.scuba_config.Aad["MS.AAD.3.2v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.3.2v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, true) == true
}

test_NoExclusionsExemptGroups_Correct if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.scuba_config.Aad["MS.AAD.3.2v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.3.2v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, true) == true
}

# User exclusions test
test_UserExclusionNoExempt_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, false) == true
}

test_UserExclusionConditions_Correct if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.scuba_config.Aad["MS.AAD.3.2v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.3.2v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, true) == true
}

test_UserExclusionsNoExempt_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, false) == true
}

test_UserExclusionsSingleExempt_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.scuba_config.Aad["MS.AAD.3.2v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.3.2v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, false) == true
}

test_MultiUserExclusionsConditions_Correct if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.scuba_config.Aad["MS.AAD.3.2v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.3.2v1"].CapExclusions.Users as [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, true) == true
}

# Group Exclusion tests
test_GroupExclusionNoExempt_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, false) == true
}

test_GroupExclusionsConditions_Correct if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.scuba_config.Aad["MS.AAD.3.2v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.3.2v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, true) == true
}

test_GroupExclusionsNoExempt_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, false) == true
}

test_GroupExclusionsSingleExempt_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.scuba_config.Aad["MS.AAD.3.2v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.3.2v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, false) == true
}

test_MultiGroupExclusionsConditions_Correct if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.scuba_config.Aad["MS.AAD.3.2v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.3.2v1"].CapExclusions.Groups as [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, true) == true
}

# User and group exclusions tests
test_UserGroupExclusionConditions_Correct if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["65fea286-22d3-42f9-b4ca-93a6f75817d4"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.scuba_config.Aad["MS.AAD.3.2v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.3.2v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]
                        with input.scuba_config.Aad["MS.AAD.3.2v1"].CapExclusions.Groups as ["65fea286-22d3-42f9-b4ca-93a6f75817d4"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, true) == true
}

test_UserGroupExclusionNoExempt_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["65fea286-22d3-42f9-b4ca-93a6f75817d4"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, false) == true
}

test_UserGroupExclusionUserExemptOnly_Incorrect if {CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["65fea286-22d3-42f9-b4ca-93a6f75817d4"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.scuba_config.Aad["MS.AAD.3.2v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.3.2v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, false) == true
}

test_UserGroupExclusionGroupExemptOnly_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["65fea286-22d3-42f9-b4ca-93a6f75817d4"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.scuba_config.Aad["MS.AAD.3.2v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.3.2v1"].CapExclusions.Groups as ["65fea286-22d3-42f9-b4ca-93a6f75817d4"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, false) == true
}

test_UserGroupExclusionTooFewUserExempts_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": [
                    "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                    "19b4dcdf-1j90-41a7c3649b425-9dd7-6x1"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["65fea286-22d3-42f9-b4ca-93a6f75817d4"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.scuba_config.Aad["MS.AAD.3.2v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.3.2v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]
                        with input.scuba_config.Aad["MS.AAD.3.2v1"].CapExclusions.Groups as ["65fea286-22d3-42f9-b4ca-93a6f75817d4"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, false) == true
}

# Other conditions
test_ConditionalAccessPolicies_Correct_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, true) == true
}

test_IncludeApplications_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "Conditions/Applications/IncludeApplications", "value": ["Office365"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, false) == true
}

test_IncludeUsers_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "Conditions/Users/IncludeUsers", "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, false) == true
}

test_ExcludeUsers_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, false) == true
}

test_ExcludeGroups_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, false) == true
}

test_ExcludeRoles_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "Conditions/Users/ExcludeRoles", "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, false) == true
}

test_BuiltInControls_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": [""]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, false) == true
}

test_State_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "add", "path": "State", "value": "disabled"},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.2v1", Output, ReportDetailStr, false) == true
}
#--

#
# Policy MS.AAD.3.3v1
#--
test_PhishingMFAEnforced_MicrosoftAuthEnabled_NotApplicable if {
    Output := aad.tests with input.conditional_access_policies as [ConditionalAccessPolicies]
                        with input.authentication_method as [AuthenticationMethod]

    PolicyId := "MS.AAD.3.3v1"
    ReportDetailStr := "This policy is only applicable if phishing-resistant MFA is not enforced and MS Authenticator is enabled. See %v for more info"
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailStr), false) == true
}

test_PhishingMFAEnforced_MicrosoftAuthDisabled_NotApplicable if {
    Auth := json.patch(AuthenticationMethod,
                [{"op": "add", "path": "authentication_method_feature_settings/0/State",
                "value": "disabled"}])

    Output := aad.tests with input.conditional_access_policies as [ConditionalAccessPolicies]
                        with input.authentication_method as [Auth]

    PolicyId := "MS.AAD.3.3v1"
    ReportDetailStr := "This policy is only applicable if phishing-resistant MFA is not enforced and MS Authenticator is enabled. See %v for more info"
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailStr), false) == true
}

test_PhishingMFANotEnforced_MicrosoftAuthDisabled_NotApplicable if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls",
                "value": ["mfa"]}])
    Auth := json.patch(AuthenticationMethod,
                [{"op": "add", "path": "authentication_method_feature_settings/0/State",
                "value": "disabled"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.authentication_method as [Auth]

    PolicyId := "MS.AAD.3.3v1"
    ReportDetailStr := "This policy is only applicable if phishing-resistant MFA is not enforced and MS Authenticator is enabled. See %v for more info"
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailStr), false) == true
}

test_PhishingMFANotEnforced_MicrosoftAuthEnabled_Correct if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])
    Auth := json.patch(AuthenticationMethod,
                [{"op": "add", "path": "authentication_method_feature_settings/3/State", "value": "enabled"},
                {"op": "remove", "path": "authentication_method_feature_settings/2"},
                {"op": "remove", "path": "authentication_method_feature_settings/1"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.authentication_method as [Auth]

    TestResult("MS.AAD.3.3v1", Output, PASS, true) == true
}

test_PhishingMFANotEnforced_MicrosoftAuthEnabled_AppnameDisabled_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])
    Auth := json.patch(AuthenticationMethod,
                [{"op": "add", "path": "authentication_method_feature_settings/3/State", "value": "enabled"},
                {"op": "remove", "path": "authentication_method_feature_settings/2"},
                {"op": "remove", "path": "authentication_method_feature_settings/1"},
                {"op": "add", "path": "authentication_method_feature_settings/0/AdditionalProperties/featureSettings/displayAppInformationRequiredState/state", "value": "disabled"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.authentication_method as [Auth]

    TestResult("MS.AAD.3.3v1", Output, FAIL, false) == true
}

test_PhishingMFANotEnforced_MicrosoftAuthEnabled_GeolocationDisabled_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])
    Auth := json.patch(AuthenticationMethod,
                [{"op": "add", "path": "authentication_method_feature_settings/3/State", "value": "enabled"},
                {"op": "remove", "path": "authentication_method_feature_settings/2"},
                {"op": "remove", "path": "authentication_method_feature_settings/1"},
                {"op": "add", "path": "authentication_method_feature_settings/0/AdditionalProperties/featureSettings/displayLocationInformationRequiredState/state", "value": "disabled"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.authentication_method as [Auth]

    TestResult("MS.AAD.3.3v1", Output, FAIL, false) == true
}

test_PhishingMFANotEnforced_MicrosoftAuthEnabled_AppNameDisabled_GeolocationDisabled_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])
    Auth := json.patch(AuthenticationMethod,
                [{"op": "add", "path": "authentication_method_feature_settings/3/State", "value": "enabled"},
                {"op": "remove", "path": "authentication_method_feature_settings/2"},
                {"op": "remove", "path": "authentication_method_feature_settings/1"},
                {"op": "add", "path": "authentication_method_feature_settings/0/AdditionalProperties/featureSettings/displayAppInformationRequiredState/state", "value": "disabled"},
                {"op": "add", "path": "authentication_method_feature_settings/0/AdditionalProperties/featureSettings/displayLocationInformationRequiredState/state", "value": "disabled"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.authentication_method as [Auth]

    TestResult("MS.AAD.3.3v1", Output, FAIL, false) == true
}

test_PhishingMFANotEnforced_MicrosoftAuthEnabled_includeTargetsNotAll_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "remove", "path": "GrantControls/AuthenticationStrength"}])
    Auth := json.patch(AuthenticationMethod,
                [{"op": "add", "path": "authentication_method_feature_settings/3/State", "value": "enabled"},
                {"op": "remove", "path": "authentication_method_feature_settings/2"},
                {"op": "remove", "path": "authentication_method_feature_settings/1"},
                {"op": "add", "path": "authentication_method_feature_settings/0/AdditionalProperties/includeTargets/0/id", "value": "not_all_users"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.authentication_method as [Auth]

    TestResult("MS.AAD.3.3v1", Output, FAIL, false) == true
}

#--

#
# Policy MS.AAD.3.4v1
#--
test_PolicyMigrationState_Correct if {
    Output := aad.tests with input.authentication_method as [AuthenticationMethod]

    TestResult("MS.AAD.3.4v1", Output, PASS, true) == true
}

test_PolicyMigrationState_preMigration_Incorrect if {
    Auth := json.patch(AuthenticationMethod,
                [{"op": "add", "path": "authentication_method_policy/PolicyMigrationState",
                "value": "preMigration"}])

    Output := aad.tests with input.authentication_method as [Auth]

    TestResult("MS.AAD.3.4v1", Output, FAIL, false) == true
}

test_PolicyMigrationState_migrationInProgress_Incorrect if {
    Auth := json.patch(AuthenticationMethod,
                [{"op": "add", "path": "authentication_method_policy/PolicyMigrationState",
                "value": "migrationInProgress"}])

    Output := aad.tests with input.authentication_method as [Auth]

    TestResult("MS.AAD.3.4v1", Output, FAIL, false) == true
}
#--

#
# Policy MS.AAD.3.5v1
#--
test_LowSecurityAuthMethods_SmsEnabled_Incorrect if {
    Auth := json.patch(AuthenticationMethod,
                [{"op": "add", "path": "authentication_method_feature_settings/1/State",
                "value": "enabled"}])

    Output := aad.tests with input.authentication_method as [Auth]

    ReportDetails := "Sms, Voice, and Email authentication must be disabled."
    TestResult("MS.AAD.3.5v1", Output, ReportDetails, false) == true
}

test_LowSecurityAuthMethods_VoiceEnabled_Incorrect if {
    Auth := json.patch(AuthenticationMethod,
                [{"op": "add", "path": "authentication_method_feature_settings/2/State",
                "value": "enabled"}])

    Output := aad.tests with input.authentication_method as [Auth]

    ReportDetails := "Sms, Voice, and Email authentication must be disabled."
    TestResult("MS.AAD.3.5v1", Output, ReportDetails, false) == true
}

test_LowSecurityAuthMethods_EmailEnabled_Incorrect if {
    Auth := json.patch(AuthenticationMethod,
                [{"op": "add", "path": "authentication_method_feature_settings/3/State",
                "value": "enabled"}])

    Output := aad.tests with input.authentication_method as [Auth]

    ReportDetails := "Sms, Voice, and Email authentication must be disabled."
    TestResult("MS.AAD.3.5v1", Output, ReportDetails, false) == true
}

test_LowSecurityAuthMethods_TwoMethodsEnabled_Incorrect if {
    Auth := json.patch(AuthenticationMethod,
                [{"op": "add", "path": "authentication_method_feature_settings/1/State",
                "value": "enabled"},
                {"op": "add", "path": "authentication_method_feature_settings/2/State",
                "value": "enabled"}])

    Output := aad.tests with input.authentication_method as [Auth]

    ReportDetails := "Sms, Voice, and Email authentication must be disabled."
    TestResult("MS.AAD.3.5v1", Output, ReportDetails, false) == true
}

test_LowSecurityAuthMethods_AllMethodsEnabled_Incorrect if {
    Auth := json.patch(AuthenticationMethod,
                [{"op": "add", "path": "authentication_method_feature_settings/1/State",
                "value": "enabled"},
                {"op": "add", "path": "authentication_method_feature_settings/2/State",
                "value": "enabled"},
                {"op": "add", "path": "authentication_method_feature_settings/3/State",
                "value": "enabled"}])

    Output := aad.tests with input.authentication_method as [Auth]

    ReportDetails := "Sms, Voice, and Email authentication must be disabled."
    TestResult("MS.AAD.3.5v1", Output, ReportDetails, false) == true
}

test_LowSecurityAuthMethods_PreMigration_NotImplemented if {
    Auth := json.patch(AuthenticationMethod,
                [{"op": "add", "path": "authentication_method_policy/PolicyMigrationState",
                "value": "preMigration"}])

    Output := aad.tests with input.authentication_method as [Auth]

    # regal ignore:line-length
    Reason := "This policy is only applicable if the tenant has their Manage Migration feature set to Migration Complete. See %v for more info"
    TestResult("MS.AAD.3.5v1", Output, CheckedSkippedDetails("MS.AAD.3.4v1", Reason), false) == true
}

test_LowSecurityAuthMethods_MigrationComplete_Correct if {
    Output := aad.tests with input.authentication_method as [AuthenticationMethod]

    TestResult("MS.AAD.3.5v1", Output, PASS, true) == true
}
#--

#
# Policy MS.AAD.3.6v1
#--
test_ConditionalAccessPolicies_Correct_all_strengths if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/IncludeRoles",
                "value": [
                            "Role1",
                            "Role2"
                        ]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.privileged_roles as PrivilegedRoles

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.3.6v1", Output, ReportDetailStr, true) == true
}

test_ConditionalAccessPolicies_Correct_windowsHelloForBusiness_only if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/IncludeRoles",
                "value": [
                            "Role1",
                            "Role2"
                        ]},
                {"op": "add", "path": "GrantControls/AuthenticationStrength/AllowedCombinations",
                "value": ["windowsHelloForBusiness"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.privileged_roles as PrivilegedRoles

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.3.6v1", Output, ReportDetailStr, true) == true
}

test_ConditionalAccessPolicies_Correct_fido2_only if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/IncludeRoles",
                "value": [
                            "Role1",
                            "Role2"
                        ]},
                {"op": "add", "path": "GrantControls/AuthenticationStrength/AllowedCombinations",
                "value": ["fido2"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.privileged_roles as PrivilegedRoles

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.3.6v1", Output, ReportDetailStr, true) == true
}

test_ConditionalAccessPolicies_Correct_x509_only if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/IncludeRoles",
                "value": [
                            "Role1",
                            "Role2"
                        ]},
                {"op": "add", "path": "GrantControls/AuthenticationStrength/AllowedCombinations",
                "value": ["x509CertificateMultiFactor"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.privileged_roles as PrivilegedRoles

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.3.6v1", Output, ReportDetailStr, true) == true
}

test_ConditionalAccessPolicies_Incorrect_not_all_apps if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/IncludeRoles",
                "value": [
                            "Role1",
                            "Role2"
                        ]},
                {"op": "add", "path": "Conditions/Applications/IncludeApplications",
                "value": []}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.privileged_roles as PrivilegedRoles

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.6v1", Output, ReportDetailStr, false) == true
}

test_BuiltInControls_Incorrect_No_Authentication_Strength if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/IncludeRoles",
                "value": [
                            "Role1",
                            "Role2"
                        ]},
                {"op": "add", "path": "GrantControls/AuthenticationStrength/AllowedCombinations",
                "value": null}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.privileged_roles as PrivilegedRoles

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.6v1", Output, ReportDetailStr, false) == true
}

test_ConditionalAccessPolicies_Incorrect_disabled if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/IncludeRoles",
                "value": [
                            "Role1",
                            "Role2"
                        ]},
                {"op": "add", "path": "State",
                "value": "disabled"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.privileged_roles as PrivilegedRoles

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.6v1", Output, ReportDetailStr, false) == true
}

test_ConditionalAccessPolicies_Incorrect_Covered_Roles if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/IncludeRoles",
                "value": [
                            "Role1"
                        ]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.privileged_roles as PrivilegedRoles

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.6v1", Output, ReportDetailStr, false) == true
}

test_ConditionalAccessPolicies_Incorrect_Wrong_Roles if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/IncludeRoles",
                "value": [
                            "Role1"
                        ]}])
    Roles := json.patch(PrivilegedRoles, [{"op": "remove", "path": "0"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.privileged_roles as Roles

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.6v1", Output, ReportDetailStr, false) == true
}

test_ExcludeRoles_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/IncludeRoles",
                "value": [
                            "Role1",
                            "Role2"
                        ]},
                {"op": "add", "path": "Conditions/Users/ExcludeRoles",
                "value": [
                            "Role1"
                        ]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.privileged_roles as PrivilegedRoles

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.6v1", Output, ReportDetailStr, false) == true
}
#--

#
# Policy MS.AAD.3.7v1
#--
test_ConditionalAccessPolicies_Correct_V3 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls",
                "value": ["domainJoinedDevice"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.3.7v1", Output, ReportDetailStr, true) == true
}

test_BuiltInControls_Correct if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls",
                "value": ["compliantDevice"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.3.7v1", Output, ReportDetailStr, true) == true
}

test_IncludeApplications_Incorrect_V3 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Applications/IncludeApplications",
                "value": [""]},
                {"op": "add", "path": "GrantControls/BuiltInControls",
                "value": ["compliantDevice"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.7v1", Output, ReportDetailStr, false) == true
}

test_IncludeUsers_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/IncludeUsers",
                "value": [""]},
                {"op": "add", "path": "GrantControls/BuiltInControls",
                "value": ["compliantDevice"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.7v1", Output, ReportDetailStr, false) == true
}

test_BuiltInControls_Incorrect_V3 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls",
                "value": [""]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.7v1", Output, ReportDetailStr, false) == true
}

test_State_Incorrect_V3 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "State",
                "value": "disabled"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.7v1", Output, ReportDetailStr, false) == true
}
#--

#
# Policy MS.AAD.3.8v1
#--
test_Correct_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls",
                "value": [
                    "compliantDevice",
                    "domainJoinedDevice"
                ]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailArrayStrs := ["conditional access policy(s) found that meet(s) all requirements:"]
    TestResultContains("MS.AAD.3.8v1", Output, ReportDetailArrayStrs, true) == true
}

test_ExcludeUserCorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls",
                "value": [
                    "compliantDevice",
                    "domainJoinedDevice"
                ]},
                {"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["SpecialPerson"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.scuba_config.Aad["MS.AAD.3.8v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.3.8v1"].CapExclusions.Users as ["SpecialPerson"]

    ReportDetailArrayStrs := ["conditional access policy(s) found that meet(s) all requirements:"]
    TestResultContains("MS.AAD.3.8v1", Output, ReportDetailArrayStrs, true) == true
}

test_ExcludeGroup_Correct_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls",
                "value": [
                    "compliantDevice",
                    "domainJoinedDevice"
                ]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["SpecialGroup"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.scuba_config.Aad["MS.AAD.3.8v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.3.8v1"].CapExclusions.Groups as ["SpecialGroup"]

    ReportDetailArrayStrs := ["conditional access policy(s) found that meet(s) all requirements:"]
    TestResultContains("MS.AAD.3.8v1", Output, ReportDetailArrayStrs, true) == true
}

test_ExcludeUserIncorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls",
                "value": [
                    "compliantDevice",
                    "domainJoinedDevice"
                ]},
                {"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["SpecialPerson"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.scuba_config.Aad["MS.AAD.3.8v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.3.8v1"].CapExclusions.Users as ["NotSpecialPerson"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.8v1", Output, ReportDetailStr, false) == true
}

test_ExcludeGroupIncorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls",
                "value": [
                    "compliantDevice",
                    "domainJoinedDevice"
                ]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["SpecialGroup"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.scuba_config.Aad["MS.AAD.3.8v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.3.8v1"].CapExclusions.Groups as ["NotSpecialGroup"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.8v1", Output, ReportDetailStr, false) == true
}

test_InCorrect_ReportOnly if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls",
                "value": [
                    "compliantDevice",
                    "domainJoinedDevice"
                ]},
                {"op": "add", "path": "State",
                "value": "enabledForReportingButNotEnforced"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.8v1", Output, ReportDetailStr, false) == true
}

test_Correct_OnlyCompliantDevice if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls",
                "value": ["compliantDevice"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailArrayStrs := ["conditional access policy(s) found that meet(s) all requirements:"]
    TestResultContains("MS.AAD.3.8v1", Output, ReportDetailArrayStrs, true) == true
}

test_Correct_OnlyDomainJoinedDevice if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls",
                "value": ["domainJoinedDevice"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailArrayStrs := ["conditional access policy(s) found that meet(s) all requirements:"]
    TestResultContains("MS.AAD.3.8v1", Output, ReportDetailArrayStrs, true) == true
}

test_Incorrect_EmptyGrantControls if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls",
                "value": []}])

    Output := aad.tests with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.8v1", Output, ReportDetailStr, false) == true
}

test_InCorrect_No_Policy if {
    Output := aad.tests with input.conditional_access_policies as []

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.3.8v1", Output, ReportDetailStr, false) == true
}
#--