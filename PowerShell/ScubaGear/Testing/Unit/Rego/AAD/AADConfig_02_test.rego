package aad_test
import rego.v1
import data.aad
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult


#
# Policy MS.AAD.2.1v1
#--
test_NoExclusionsConditions_Correct_V1 if {
    Output := aad.tests with input.conditional_access_policies as [ConditionalAccessPolicies]
                        with input.service_plans as ServicePlans

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, true) == true
}

test_NoExclusionsExemptUsers_Correct_V1 if {
    Output := aad.tests with input.conditional_access_policies as [ConditionalAccessPolicies]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, true) == true
}

test_NoExclusionsExemptGroups_Correct_V1 if {
    Output := aad.tests with input.conditional_access_policies as [ConditionalAccessPolicies]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, true) == true
}

# User exclusions test
test_UserExclusionNoExempt_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_UserExclusionConditions_Correct_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, true) == true
}

test_UserExclusionsNoExempt_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_UserExclusionsSingleExempt_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_MultiUserExclusionsConditions_Correct_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v1"].CapExclusions.Users as [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, true) == true
}

# Group Exclusion tests #
test_GroupExclusionNoExempt_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_GroupExclusionsConditions_Correct_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, true) == true
}

test_GroupExclusionsNoExempt_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
    "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_GroupExclusionsSingleExempt_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    ReportDetailStr :=
    "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_MultiGroupExclusionsConditions_Correct_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v1"].CapExclusions.Groups as [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, true) == true
}

# User and group exclusions tests
test_UserGroupExclusionConditions_Correct_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]
                        with input.scuba_config.Aad["MS.AAD.2.1v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, true) == true
}

test_UserGroupExclusionNoExempt_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_UserGroupExclusionUserExemptOnly_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_UserGroupExclusionGroupExemptOnly_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_UserGroupExclusionTooFewUserExempts_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v1"].CapExclusions.Users as ["65fea286-22d3-42f9-b4ca-93a6f75817d4"]
                        with input.scuba_config.Aad["MS.AAD.2.1v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

# Other Conditions tests
test_IncludeApplications_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Applications/IncludeApplications",
                "value": ["Office365"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_IncludeUsers_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/IncludeUsers",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_ExcludeUsers_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_ExcludeGroups_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_ExcludeRoles_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeRoles",
                "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_BuiltInControls_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls",
                "value": [""]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_State_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "State",
                "value": "disabled"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_UserRiskLevels_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/UserRiskLevels",
                "value": [""]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_ServicePlans_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/UserRiskLevels",
                "value": [""]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as [ServicePlans[0]]

    ReportDetailStr :=
        "**NOTE: Your tenant does not have a Microsoft Entra ID P2 license, which is required for this feature**"
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}
#--

#
# Policy MS.AAD.2.2v1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.AAD.2.2v1"

    Output := aad.tests with input as { }

    ReportDetailStr := NotCheckedDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailStr, false) == true
}
#--

#
# Policy MS.AAD.2.3v1
#--
test_NoExclusionsConditions_Correct_V2 if {
    Output := aad.tests with input.conditional_access_policies as [ConditionalAccessPolicies]
                        with input.service_plans as ServicePlans

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

test_NoExclusionsExemptUsers_Correct_V2 if {
    Output := aad.tests with input.conditional_access_policies as [ConditionalAccessPolicies]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

test_NoExclusionsExemptGroups_Correct_V2 if {
    Output := aad.tests with input.conditional_access_policies as [ConditionalAccessPolicies]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

# User exclusions test
test_UserExclusionNoExempt_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_UserExclusionConditions_Correct_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

test_UserExclusionsNoExempt_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_UserExclusionsSingleExempt_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_MultiUserExclusionsConditions_Correct_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Users as [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

# Group Exclusion tests
test_GroupExclusionNoExempt_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_GroupExclusionsConditions_Correct_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

test_GroupExclusionsNoExempt_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_GroupExclusionsSingleExempt_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_MultiGroupExclusionsConditions_Correct_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Groups as [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

# User and group exclusions tests
test_UserGroupExclusionConditions_Correct_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

test_UserGroupExclusionNoExempt_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_UserGroupExclusionUserExemptOnly_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_UserGroupExclusionGroupExemptOnly_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_UserGroupExclusionTooFewUserExempts_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": [
                    "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                    "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                    ]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["65fea286-22d3-42f9-b4ca-93a6f75817d4"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Groups as ["65fea286-22d3-42f9-b4ca-93a6f75817d4"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

# Other Conditions
test_Conditions_Correct if {
    Output := aad.tests with input.conditional_access_policies as [ConditionalAccessPolicies]
                        with input.service_plans as ServicePlans

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

test_IncludeApplications_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Applications/IncludeApplications",
                "value": ["Office365"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_IncludeUsers_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/IncludeUsers",
                "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_ExcludeUsers_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_ExcludeGroups_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_ExcludeRoles_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeRoles",
                "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_SignInRiskLevels_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/SignInRiskLevels",
                "value": [""]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_BuiltInControls_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls",
                "value": [""]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_State_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "State",
                "value": "disabled"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}
#--