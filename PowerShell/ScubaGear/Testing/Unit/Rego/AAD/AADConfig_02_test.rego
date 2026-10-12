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

test_ApplicationExclusions_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Applications/ExcludeApplications", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans


    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

# User exclusions test
test_UserExclusionNoExempt_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_UserExclusionConditions_Correct_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

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
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_UserExclusionsSingleExempt_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]}])

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
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]}])

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
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_GroupExclusionsConditions_Correct_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

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
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
    "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_GroupExclusionsSingleExempt_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]}])

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
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]}])

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
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

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
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_UserGroupExclusionUserExemptOnly_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

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
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

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
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

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
                [{"op": "add", "path": "Conditions/Applications/IncludeApplications", "value": ["Office365"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_IncludeUsers_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/IncludeUsers", "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_ExcludeUsers_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_ExcludeGroups_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_ExcludeRoles_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeRoles", "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_BuiltInControls_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": [""]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_State_Incorrect_V1 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "State", "value": "disabled"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_UserRiskLevels_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/UserRiskLevels", "value": [""]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

test_ServicePlans_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/UserRiskLevels", "value": [""]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as [ServicePlans[0]]

    ReportDetailStr :=
        "**NOTE: Your tenant does not have a Microsoft Entra ID P2 license, which is required for this feature**"
    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, false) == true
}

# tests for Application exclusions
test_AppExclusionConditions_Correct_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Applications/ExcludeApplications", "value": ["Office365"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v1"].CapExclusions.Applications as ["Office365"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, true) == true
}

# tests for guest user type exclusions
test_GuestUserTypeExclusionConditions_Correct_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGuestsOrExternalUsers",
                "value": {
                    "GuestOrExternalUserTypes": "b2bCollaborationGuest,internalGuest",
                    "ExternalTenants": {"MembershipKind": "all"}
                }}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v1"].CapExclusions.GuestUserTypes as [
                            "b2bCollaborationGuest",
                            "internalGuest"
                        ]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])

    TestResult("MS.AAD.2.1v1", Output, ReportDetailStr, true) == true
}

test_GuestUserTypeExclusionNoExempt_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGuestsOrExternalUsers",
                "value": {
                    "GuestOrExternalUserTypes": "b2bCollaborationGuest",
                    "ExternalTenants": {"MembershipKind": "all"}
                }}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

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
# Policy MS.AAD.2.3v2
#--
SignInRiskGroupA := "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"

SignInRiskGroupB := "65fea286-22d3-42f9-b4ca-93a6f75817d4"

SignInRiskUserA := "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"

SignInRiskBreakGlass := "8bc7c6ee-39a2-42a5-a31b-f77fb51db652"

SignInRiskEveryTime := {
    "AuthenticationType": "primaryAndSecondaryAuthentication",
    "FrequencyInterval": "everyTime",
    "IsEnabled": true,
    "Type": null,
    "Value": null
}

# Policy that meets MS.AAD.2.3v2: medium and high risk, phishing-resistant MFA, every time
SignInRiskPasswordless := json.patch(ConditionalAccessPolicies, [
    {"op": "replace", "path": "Conditions/SignInRiskLevels", "value": ["high", "medium"]},
    {"op": "replace", "path": "GrantControls/BuiltInControls", "value": []},
    {"op": "add", "path": "SessionControls", "value": {"SignInFrequency": SignInRiskEveryTime}}
])

# Policy that meets MS.AAD.2.4v1: medium and high risk, MFA, every time, targets a group
SignInRiskPassword := json.patch(SignInRiskPasswordless, [
    {"op": "replace", "path": "DisplayName", "value": "Password Policy"},
    {"op": "replace", "path": "Conditions/Users/IncludeUsers", "value": []},
    {"op": "add", "path": "Conditions/Users/IncludeGroups", "value": [SignInRiskGroupA]},
    {"op": "replace", "path": "GrantControls/AuthenticationStrength/AllowedCombinations",
    "value": ["password,microsoftAuthenticatorPush", "windowsHelloForBusiness", "fido2"]}
])

SignInRiskPassedStr(Name) := concat("", [
    "1 conditional access policy(s) found that meet(s) all requirements:",
    sprintf("<br/>%s. <a href='#caps'>View all CA policies</a>.", [Name])
])

SignInRiskFailedStr :=
    "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

SignInRiskNotTargetedStr(Prefix, Ids) := concat("", [
    Prefix,
    ". The following user(s) or group(s) are excluded from the MS.AAD.2.3v2 policy ",
    "but not targeted by a policy that meets this requirement: ",
    Ids,
    ". <a href='#caps'>View all CA policies</a>."
])

SignInRiskNoLicenseStr :=
    "**NOTE: Your tenant does not have a Microsoft Entra ID P2 license, which is required for this feature**"

test_PasswordlessSignInRisk_Correct if {
    Output := aad.tests with input.conditional_access_policies as [SignInRiskPasswordless]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.3v2", Output, SignInRiskPassedStr("Test Policy"), true) == true
}

test_PasswordlessSignInRisk_ExemptUsers_Correct if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": [SignInRiskUserA]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v2"].CapExclusions.Users as [SignInRiskUserA]

    TestResult("MS.AAD.2.3v2", Output, SignInRiskPassedStr("Test Policy"), true) == true
}

test_PasswordlessSignInRisk_ExemptGroups_Correct if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": [SignInRiskGroupA]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v2"].CapExclusions.Groups as [SignInRiskGroupA]

    TestResult("MS.AAD.2.3v2", Output, SignInRiskPassedStr("Test Policy"), true) == true
}

test_PasswordlessSignInRisk_ExemptApplications_Correct if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Applications/ExcludeApplications", "value": ["Office365"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v2"].CapExclusions.Applications as ["Office365"]

    TestResult("MS.AAD.2.3v2", Output, SignInRiskPassedStr("Test Policy"), true) == true
}

test_PasswordlessSignInRisk_ExemptGuestUserTypes_Correct if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/ExcludeGuestsOrExternalUsers",
                "value": {
                    "GuestOrExternalUserTypes": "b2bCollaborationGuest,internalGuest",
                    "ExternalTenants": {"MembershipKind": "all"}
                }}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v2"].CapExclusions.GuestUserTypes as [
                            "b2bCollaborationGuest",
                            "internalGuest"
                        ]

    TestResult("MS.AAD.2.3v2", Output, SignInRiskPassedStr("Test Policy"), true) == true
}

SignInRiskUnexemptedStr(Ids) := concat("", [
    "0 conditional access policy(s) found that meet(s) all requirements. ",
    "The following user(s) or group(s) are excluded from the policy but do not match ",
    "the MS.AAD.2.3v2 exclusions in the configuration file: ",
    Ids,
    ". <a href='#caps'>View all CA policies</a>."
])

test_PasswordlessSignInRisk_UserNoExempt_Incorrect if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": [SignInRiskUserA]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.3v2", Output, SignInRiskUnexemptedStr(SignInRiskUserA), false) == true
}

test_PasswordlessSignInRisk_UserPartialExempt_Incorrect if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": [SignInRiskUserA, SignInRiskBreakGlass]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v2"].CapExclusions.Users as [SignInRiskUserA]

    TestResult("MS.AAD.2.3v2", Output, SignInRiskUnexemptedStr(SignInRiskBreakGlass), false) == true
}

test_PasswordlessSignInRisk_GroupNoExempt_Incorrect if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": [SignInRiskGroupA]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.3v2", Output, SignInRiskUnexemptedStr(SignInRiskGroupA), false) == true
}

test_PasswordlessSignInRisk_GroupPartialExempt_Incorrect if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": [SignInRiskGroupA, SignInRiskGroupB]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v2"].CapExclusions.Groups as [SignInRiskGroupA]

    TestResult("MS.AAD.2.3v2", Output, SignInRiskUnexemptedStr(SignInRiskGroupB), false) == true
}

# Unexempted users and groups are all listed
test_PasswordlessSignInRisk_UserAndGroupNoExempt_Incorrect if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": [SignInRiskUserA]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": [SignInRiskGroupA]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr := SignInRiskUnexemptedStr(concat(", ", [SignInRiskGroupA, SignInRiskUserA]))
    TestResult("MS.AAD.2.3v2", Output, ReportDetailStr, false) == true
}

# The note only appears when the policy is otherwise correct
test_PasswordlessSignInRisk_UnexemptedWithOtherFailure_Incorrect if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": [SignInRiskUserA]},
                {"op": "replace", "path": "Conditions/SignInRiskLevels", "value": ["high"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.3v2", Output, SignInRiskFailedStr, false) == true
}

test_PasswordlessSignInRisk_ApplicationNoExempt_Incorrect if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Applications/ExcludeApplications", "value": ["Office365"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.3v2", Output, SignInRiskFailedStr, false) == true
}

test_PasswordlessSignInRisk_GuestUserTypeNoExempt_Incorrect if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/ExcludeGuestsOrExternalUsers",
                "value": {
                    "GuestOrExternalUserTypes": "b2bCollaborationGuest",
                    "ExternalTenants": {"MembershipKind": "all"}
                }}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.3v2", Output, SignInRiskFailedStr, false) == true
}

test_PasswordlessSignInRisk_IncludeApplications_Incorrect if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Applications/IncludeApplications", "value": ["Office365"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.3v2", Output, SignInRiskFailedStr, false) == true
}

test_PasswordlessSignInRisk_IncludeUsers_Incorrect if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/IncludeUsers", "value": [SignInRiskBreakGlass]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.3v2", Output, SignInRiskFailedStr, false) == true
}

test_PasswordlessSignInRisk_ExcludeRoles_Incorrect if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/ExcludeRoles", "value": [SignInRiskBreakGlass]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.3v2", Output, SignInRiskFailedStr, false) == true
}

test_PasswordlessSignInRisk_OnlyHighRisk_Incorrect if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "replace", "path": "Conditions/SignInRiskLevels", "value": ["high"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.3v2", Output, SignInRiskFailedStr, false) == true
}

test_PasswordlessSignInRisk_OnlyMediumRisk_Incorrect if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "replace", "path": "Conditions/SignInRiskLevels", "value": ["medium"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.3v2", Output, SignInRiskFailedStr, false) == true
}

test_PasswordlessSignInRisk_NoSignInFrequency_Incorrect if {
    CAP := json.patch(SignInRiskPasswordless, [{"op": "remove", "path": "SessionControls"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.3v2", Output, SignInRiskFailedStr, false) == true
}

test_PasswordlessSignInRisk_TimeBasedSignInFrequency_Incorrect if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "replace", "path": "SessionControls/SignInFrequency/FrequencyInterval", "value": "timeBased"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.3v2", Output, SignInRiskFailedStr, false) == true
}

test_PasswordlessSignInRisk_SignInFrequencyDisabled_Incorrect if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "replace", "path": "SessionControls/SignInFrequency/IsEnabled", "value": false}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.3v2", Output, SignInRiskFailedStr, false) == true
}

test_PasswordlessSignInRisk_GeneralMFAStrength_Incorrect if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "replace", "path": "GrantControls/AuthenticationStrength/AllowedCombinations",
                "value": ["password,microsoftAuthenticatorPush", "windowsHelloForBusiness"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.3v2", Output, SignInRiskFailedStr, false) == true
}

test_PasswordlessSignInRisk_BlockOnly_Incorrect if {
    CAP := json.patch(SignInRiskPasswordless,
                [{"op": "replace", "path": "GrantControls/BuiltInControls", "value": ["block"]},
                {"op": "replace", "path": "GrantControls/AuthenticationStrength", "value": null}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.3v2", Output, SignInRiskFailedStr, false) == true
}

test_PasswordlessSignInRisk_State_Incorrect if {
    CAP := json.patch(SignInRiskPasswordless, [{"op": "replace", "path": "State", "value": "disabled"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.3v2", Output, SignInRiskFailedStr, false) == true
}

test_PasswordlessSignInRisk_NoLicense_Incorrect if {
    Output := aad.tests with input.conditional_access_policies as [SignInRiskPasswordless]
                        with input.service_plans as [ServicePlans[0]]

    TestResult("MS.AAD.2.3v2", Output, SignInRiskNoLicenseStr, false) == true
}
#--

#
# Policy MS.AAD.2.4v1
#--
test_PasswordSignInRisk_GroupTargeted_Correct if {
    PasswordlessCAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": [SignInRiskGroupA]}])

    Output := aad.tests with input.conditional_access_policies as [PasswordlessCAP, SignInRiskPassword]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v2"].CapExclusions.Groups as [SignInRiskGroupA]

    TestResult("MS.AAD.2.4v1", Output, SignInRiskPassedStr("Password Policy"), true) == true
}

test_PasswordSignInRisk_UserTargeted_Correct if {
    PasswordlessCAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": [SignInRiskUserA]}])
    PasswordCAP := json.patch(SignInRiskPassword,
                [{"op": "replace", "path": "Conditions/Users/IncludeUsers", "value": [SignInRiskUserA]},
                {"op": "replace", "path": "Conditions/Users/IncludeGroups", "value": []}])

    Output := aad.tests with input.conditional_access_policies as [PasswordlessCAP, PasswordCAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v2"].CapExclusions.Users as [SignInRiskUserA]

    TestResult("MS.AAD.2.4v1", Output, SignInRiskPassedStr("Password Policy"), true) == true
}

test_PasswordSignInRisk_AllUsersTargeted_Correct if {
    PasswordlessCAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": [SignInRiskGroupA]}])
    PasswordCAP := json.patch(SignInRiskPassword,
                [{"op": "replace", "path": "Conditions/Users/IncludeUsers", "value": ["All"]},
                {"op": "replace", "path": "Conditions/Users/IncludeGroups", "value": []}])

    Output := aad.tests with input.conditional_access_policies as [PasswordlessCAP, PasswordCAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v2"].CapExclusions.Groups as [SignInRiskGroupA]

    TestResult("MS.AAD.2.4v1", Output, SignInRiskPassedStr("Password Policy"), true) == true
}

# Exclusions are split across multiple policies for this control
test_PasswordSignInRisk_MultiplePoliciesTargeted_Correct if {
    PasswordlessCAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": [SignInRiskGroupA, SignInRiskGroupB]}])
    PasswordCAPB := json.patch(SignInRiskPassword,
                [{"op": "replace", "path": "DisplayName", "value": "Password Policy B"},
                {"op": "replace", "path": "Conditions/Users/IncludeGroups", "value": [SignInRiskGroupB]}])

    Output := aad.tests with input.conditional_access_policies as [PasswordlessCAP, SignInRiskPassword, PasswordCAPB]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v2"].CapExclusions.Groups as [SignInRiskGroupA, SignInRiskGroupB]

    ReportDetailStr := concat("", [
        "2 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Password Policy, Password Policy B. <a href='#caps'>View all CA policies</a>."
    ])
    TestResult("MS.AAD.2.4v1", Output, ReportDetailStr, true) == true
}

test_PasswordSignInRisk_NoPasswordlessExclusions_Correct if {
    Output := aad.tests with input.conditional_access_policies as [SignInRiskPasswordless, SignInRiskPassword]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.4v1", Output, SignInRiskPassedStr("Password Policy"), true) == true
}

# Emergency access accounts excluded from both policies are not required to be targeted
test_PasswordSignInRisk_ExcludedFromBoth_Correct if {
    PasswordlessCAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": [SignInRiskGroupA]},
                {"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": [SignInRiskBreakGlass]}])
    PasswordCAP := json.patch(SignInRiskPassword,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": [SignInRiskBreakGlass]}])

    Output := aad.tests with input.conditional_access_policies as [PasswordlessCAP, PasswordCAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v2"].CapExclusions.Groups as [SignInRiskGroupA]
                        with input.scuba_config.Aad["MS.AAD.2.3v2"].CapExclusions.Users as [SignInRiskBreakGlass]
                        with input.scuba_config.Aad["MS.AAD.2.4v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.4v1"].CapExclusions.Users as [SignInRiskBreakGlass]

    TestResult("MS.AAD.2.4v1", Output, SignInRiskPassedStr("Password Policy"), true) == true
}

test_PasswordSignInRisk_BuiltInMFA_Correct if {
    CAP := json.patch(SignInRiskPassword,
                [{"op": "replace", "path": "GrantControls/BuiltInControls", "value": ["mfa"]},
                {"op": "replace", "path": "GrantControls/AuthenticationStrength", "value": null}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.4v1", Output, SignInRiskPassedStr("Password Policy"), true) == true
}

test_PasswordSignInRisk_ExemptExclusions_Correct if {
    CAP := json.patch(SignInRiskPassword,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": [SignInRiskGroupB]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.4v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.4v1"].CapExclusions.Groups as [SignInRiskGroupB]

    TestResult("MS.AAD.2.4v1", Output, SignInRiskPassedStr("Password Policy"), true) == true
}

test_PasswordSignInRisk_ExclusionNoExempt_Incorrect if {
    CAP := json.patch(SignInRiskPassword,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": [SignInRiskGroupB]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.4v1", Output, SignInRiskFailedStr, false) == true
}

test_PasswordSignInRisk_ExcludedUserNotTargeted_Incorrect if {
    PasswordlessCAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": [SignInRiskGroupA, SignInRiskGroupB]}])

    Output := aad.tests with input.conditional_access_policies as [PasswordlessCAP, SignInRiskPassword]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v2"].CapExclusions.Groups as [SignInRiskGroupA, SignInRiskGroupB]

    ReportDetailStr := SignInRiskNotTargetedStr(
        "1 conditional access policy(s) found that meet(s) all requirements:<br/>Password Policy",
        SignInRiskGroupB
    )
    TestResult("MS.AAD.2.4v1", Output, ReportDetailStr, false) == true
}

# The MS.AAD.2.3v2 policy fails because an exclusion is not in the config file, the excluded users
# must still be targeted by this control
test_PasswordSignInRisk_PasswordlessExclusionNotInConfigNotTargeted_Incorrect if {
    PasswordlessCAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": [SignInRiskUserA, SignInRiskBreakGlass]}])
    PasswordCAP := json.patch(SignInRiskPassword,
                [{"op": "replace", "path": "Conditions/Users/IncludeUsers", "value": [SignInRiskUserA]},
                {"op": "replace", "path": "Conditions/Users/IncludeGroups", "value": []}])

    Output := aad.tests with input.conditional_access_policies as [PasswordlessCAP, PasswordCAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v2"].CapExclusions.Users as [SignInRiskUserA]

    Output23 := SignInRiskUnexemptedStr(SignInRiskBreakGlass)
    TestResult("MS.AAD.2.3v2", Output, Output23, false) == true

    ReportDetailStr := SignInRiskNotTargetedStr(
        "1 conditional access policy(s) found that meet(s) all requirements:<br/>Password Policy",
        SignInRiskBreakGlass
    )
    TestResult("MS.AAD.2.4v1", Output, ReportDetailStr, false) == true
}

test_PasswordSignInRisk_PasswordlessExclusionNotInConfigTargeted_Correct if {
    PasswordlessCAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": [SignInRiskUserA]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": [SignInRiskGroupB]}])
    PasswordCAP := json.patch(SignInRiskPassword,
                [{"op": "replace", "path": "Conditions/Users/IncludeUsers", "value": [SignInRiskUserA]},
                {"op": "replace", "path": "Conditions/Users/IncludeGroups", "value": [SignInRiskGroupB]}])

    Output := aad.tests with input.conditional_access_policies as [PasswordlessCAP, PasswordCAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.3v2", Output, SignInRiskUnexemptedStr(    concat(", ", [SignInRiskUserA, SignInRiskGroupB])), false) == true
    TestResult("MS.AAD.2.4v1", Output, SignInRiskPassedStr("Password Policy"), true) == true
}

test_PasswordSignInRisk_NoPolicy_Incorrect if {
    PasswordlessCAP := json.patch(SignInRiskPasswordless,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": [SignInRiskGroupA]}])

    Output := aad.tests with input.conditional_access_policies as [PasswordlessCAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v2"].CapExclusions.Groups as [SignInRiskGroupA]

    ReportDetailStr := SignInRiskNotTargetedStr(
        "0 conditional access policy(s) found that meet(s) all requirements",
        SignInRiskGroupA
    )
    TestResult("MS.AAD.2.4v1", Output, ReportDetailStr, false) == true
}

SignInRiskNotRequiredStr := concat("", [
    "No users or groups are excluded from the MS.AAD.2.3v2 policy, ",
    "so a separate policy for password users is not required. <a href='#caps'>View all CA policies</a>."
])

# All users are covered by the MS.AAD.2.3v2 policy with no exclusions, no policy for password users is needed
test_PasswordSignInRisk_NoPolicyNoExclusions_Correct if {
    Output := aad.tests with input.conditional_access_policies as [SignInRiskPasswordless]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.4v1", Output, SignInRiskNotRequiredStr, true) == true
}

test_PasswordSignInRisk_NoPolicyNoExclusionsInvalidPolicy_Correct if {
    CAP := json.patch(SignInRiskPassword, [{"op": "replace", "path": "Conditions/SignInRiskLevels", "value": ["high"]}])

    Output := aad.tests with input.conditional_access_policies as [SignInRiskPasswordless, CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.4v1", Output, SignInRiskNotRequiredStr, true) == true
}

# The exclusions are only unnecessary when the MS.AAD.2.3v2 policy meets its requirements
test_PasswordSignInRisk_PasswordlessPolicyInvalid_Incorrect if {
    CAP := json.patch(SignInRiskPasswordless, [{"op": "replace", "path": "State", "value": "disabled"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.4v1", Output, SignInRiskFailedStr, false) == true
}

test_PasswordSignInRisk_NoPolicies_Incorrect if {
    Output := aad.tests with input.conditional_access_policies as []
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.4v1", Output, SignInRiskFailedStr, false) == true
}

test_PasswordSignInRisk_NoExclusionsNoLicense_Incorrect if {
    Output := aad.tests with input.conditional_access_policies as [SignInRiskPasswordless]
                        with input.service_plans as [ServicePlans[0]]

    TestResult("MS.AAD.2.4v1", Output, SignInRiskNoLicenseStr, false) == true
}

test_PasswordSignInRisk_PhishingResistantOnly_Incorrect if {
    CAP := json.patch(SignInRiskPassword,
                [{"op": "replace", "path": "GrantControls/AuthenticationStrength/AllowedCombinations",
                "value": ["windowsHelloForBusiness", "fido2", "x509CertificateMultiFactor"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.4v1", Output, SignInRiskFailedStr, false) == true
}

test_PasswordSignInRisk_BlockOnly_Incorrect if {
    CAP := json.patch(SignInRiskPassword,
                [{"op": "replace", "path": "GrantControls/BuiltInControls", "value": ["block"]},
                {"op": "replace", "path": "GrantControls/AuthenticationStrength", "value": null}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.4v1", Output, SignInRiskFailedStr, false) == true
}

test_PasswordSignInRisk_OnlyHighRisk_Incorrect if {
    CAP := json.patch(SignInRiskPassword,
                [{"op": "replace", "path": "Conditions/SignInRiskLevels", "value": ["high"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.4v1", Output, SignInRiskFailedStr, false) == true
}

test_PasswordSignInRisk_OnlyMediumRisk_Incorrect if {
    CAP := json.patch(SignInRiskPassword,
                [{"op": "replace", "path": "Conditions/SignInRiskLevels", "value": ["medium"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.4v1", Output, SignInRiskFailedStr, false) == true
}

test_PasswordSignInRisk_NoSignInFrequency_Incorrect if {
    CAP := json.patch(SignInRiskPassword, [{"op": "remove", "path": "SessionControls"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.4v1", Output, SignInRiskFailedStr, false) == true
}

test_PasswordSignInRisk_TimeBasedSignInFrequency_Incorrect if {
    CAP := json.patch(SignInRiskPassword,
                [{"op": "replace", "path": "SessionControls/SignInFrequency/FrequencyInterval", "value": "timeBased"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.4v1", Output, SignInRiskFailedStr, false) == true
}

test_PasswordSignInRisk_NoUsersTargeted_Incorrect if {
    CAP := json.patch(SignInRiskPassword,
                [{"op": "replace", "path": "Conditions/Users/IncludeGroups", "value": []}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.4v1", Output, SignInRiskFailedStr, false) == true
}

test_PasswordSignInRisk_IncludeNone_Incorrect if {
    CAP := json.patch(SignInRiskPassword,
                [{"op": "replace", "path": "Conditions/Users/IncludeUsers", "value": ["None"]},
                {"op": "replace", "path": "Conditions/Users/IncludeGroups", "value": []}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.4v1", Output, SignInRiskFailedStr, false) == true
}

test_PasswordSignInRisk_IncludeApplications_Incorrect if {
    CAP := json.patch(SignInRiskPassword,
                [{"op": "add", "path": "Conditions/Applications/IncludeApplications", "value": ["Office365"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.4v1", Output, SignInRiskFailedStr, false) == true
}

test_PasswordSignInRisk_ExcludeRoles_Incorrect if {
    CAP := json.patch(SignInRiskPassword,
                [{"op": "add", "path": "Conditions/Users/ExcludeRoles", "value": [SignInRiskBreakGlass]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.4v1", Output, SignInRiskFailedStr, false) == true
}

test_PasswordSignInRisk_State_Incorrect if {
    CAP := json.patch(SignInRiskPassword, [{"op": "replace", "path": "State", "value": "disabled"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.4v1", Output, SignInRiskFailedStr, false) == true
}

test_PasswordSignInRisk_NoLicense_Incorrect if {
    Output := aad.tests with input.conditional_access_policies as [SignInRiskPassword]
                        with input.service_plans as [ServicePlans[0]]

    TestResult("MS.AAD.2.4v1", Output, SignInRiskNoLicenseStr, false) == true
}
#--

