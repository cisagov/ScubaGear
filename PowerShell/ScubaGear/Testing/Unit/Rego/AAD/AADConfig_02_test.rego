package aad_test
import rego.v1
import data.aad
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult


#
# Policy MS.AAD.2.1v2
#--
MeetsRequirementsDetails := concat("", [
    "1 conditional access policy(s) found that meet(s) all requirements:",
    "<br/>Test Policy. <a href='#caps'>View all CA policies</a>"
])

NoPolicyDetails := concat("", [
    "0 conditional access policy(s) found that meet(s) all requirements.",
    " <a href='#caps'>View all CA policies</a>"
])

NearMissDetails(exclusions) := concat("", [
    "0 conditional access policy(s) found that meet(s) all requirements.",
    " <br/><br/><strong>Near miss: </strong> Test Policy would pass if ",
    "the config file is updated to include:",
    sprintf(" %s. <a href='#caps'>View all CA policies</a>. ", [exclusions]),
    "<a href=\"https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/scubaconfiganalyzer.md\" ",
    "target=\"_blank\">Run the Start-SCuBAConfigAnalyzer cmdlet</a> ",
    "and import your ScubaResults JSON file to determine which specific exclusions to add to the configuration file."
])

# Policy that requires risk remediation for high user risk with sign-in frequency set to every time
UserRiskPolicy := json.patch(ConditionalAccessPolicies, [
    {"op": "add", "path": "GrantControls/BuiltInControls", "value": ["riskRemediation"]},
    {"op": "add", "path": "GrantControls/Operator", "value": "AND"},
    {"op": "add", "path": "Conditions/SignInRiskLevels", "value": []},
    {"op": "add", "path": "SessionControls", "value": {
        "SignInFrequency": {
            "IsEnabled": true,
            "FrequencyInterval": "everyTime",
            "AuthenticationType": "primaryAndSecondaryAuthentication",
            "Type": null,
            "Value": null
        }
    }}
])

test_NoExclusionsConditions_Correct_V1 if {
    Output := aad.tests with input.conditional_access_policies as [UserRiskPolicy]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, MeetsRequirementsDetails, true) == true
}

test_NoExclusionsExemptUsers_Correct_V1 if {
    Output := aad.tests with input.conditional_access_policies as [UserRiskPolicy]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v2"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    TestResult("MS.AAD.2.1v2", Output, MeetsRequirementsDetails, true) == true
}

test_NoExclusionsExemptGroups_Correct_V1 if {
    Output := aad.tests with input.conditional_access_policies as [UserRiskPolicy]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v2"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    TestResult("MS.AAD.2.1v2", Output, MeetsRequirementsDetails, true) == true
}

test_ApplicationExclusions_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Applications/ExcludeApplications", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NearMissDetails("app exclusions"), false) == true
}

# User exclusions test
test_UserExclusionNoExempt_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NearMissDetails("user exclusions"), false) == true
}

test_UserExclusionConditions_Correct_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v2"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    TestResult("MS.AAD.2.1v2", Output, MeetsRequirementsDetails, true) == true
}

test_UserExclusionsNoExempt_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NearMissDetails("user exclusions"), false) == true
}

test_UserExclusionsSingleExempt_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v2"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    TestResult("MS.AAD.2.1v2", Output, NearMissDetails("user exclusions"), false) == true
}

test_MultiUserExclusionsConditions_Correct_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v2"].CapExclusions.Users as [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]

    TestResult("MS.AAD.2.1v2", Output, MeetsRequirementsDetails, true) == true
}

# Group Exclusion tests #
test_GroupExclusionNoExempt_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NearMissDetails("group exclusions"), false) == true
}

test_GroupExclusionsConditions_Correct_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v2"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    TestResult("MS.AAD.2.1v2", Output, MeetsRequirementsDetails, true) == true
}

test_GroupExclusionsNoExempt_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NearMissDetails("group exclusions"), false) == true
}

test_GroupExclusionsSingleExempt_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v2"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    TestResult("MS.AAD.2.1v2", Output, NearMissDetails("group exclusions"), false) == true
}

test_MultiGroupExclusionsConditions_Correct_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v2"].CapExclusions.Groups as [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]

    TestResult("MS.AAD.2.1v2", Output, MeetsRequirementsDetails, true) == true
}

# User and group exclusions tests
test_UserGroupExclusionConditions_Correct_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v2"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]
                        with input.scuba_config.Aad["MS.AAD.2.1v2"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    TestResult("MS.AAD.2.1v2", Output, MeetsRequirementsDetails, true) == true
}

test_UserGroupExclusionNoExempt_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NearMissDetails("user exclusions, group exclusions"), false) == true
}

test_UserGroupExclusionUserExemptOnly_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v2"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    TestResult("MS.AAD.2.1v2", Output, NearMissDetails("group exclusions"), false) == true
}

test_UserGroupExclusionGroupExemptOnly_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v2"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    TestResult("MS.AAD.2.1v2", Output, NearMissDetails("user exclusions"), false) == true
}

test_UserGroupExclusionTooFewUserExempts_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v2"].CapExclusions.Users as ["65fea286-22d3-42f9-b4ca-93a6f75817d4"]
                        with input.scuba_config.Aad["MS.AAD.2.1v2"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    TestResult("MS.AAD.2.1v2", Output, NearMissDetails("user exclusions"), false) == true
}

# Other Conditions tests
test_IncludeApplications_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Applications/IncludeApplications", "value": ["Office365"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NoPolicyDetails, false) == true
}

test_IncludeUsers_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/IncludeUsers", "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NoPolicyDetails, false) == true
}

test_ExcludeUsers_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NearMissDetails("user exclusions"), false) == true
}

test_ExcludeGroups_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NearMissDetails("group exclusions"), false) == true
}

test_ExcludeRoles_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/ExcludeRoles", "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NoPolicyDetails, false) == true
}

test_BuiltInControls_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": [""]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NoPolicyDetails, false) == true
}

# The previous block-based policy no longer satisfies the baseline
test_BlockBuiltInControl_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "GrantControls/BuiltInControls", "value": ["block"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NoPolicyDetails, false) == true
}

test_NoAuthenticationStrength_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "GrantControls/AuthenticationStrength", "value": null}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NoPolicyDetails, false) == true
}

test_OperatorOr_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "GrantControls/Operator", "value": "OR"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NoPolicyDetails, false) == true
}

test_NoOperator_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "remove", "path": "GrantControls/Operator"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NoPolicyDetails, false) == true
}

test_SignInRiskLevelsSet_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/SignInRiskLevels", "value": ["high"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NoPolicyDetails, false) == true
}

test_SignInRiskLevelsNull_Correct_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/SignInRiskLevels", "value": null}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, MeetsRequirementsDetails, true) == true
}

test_SignInRiskLevelsMissing_Correct_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "remove", "path": "Conditions/SignInRiskLevels"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, MeetsRequirementsDetails, true) == true
}

test_NoSessionControls_Incorrect_V1 if {
    Output := aad.tests with input.conditional_access_policies as [ConditionalAccessPolicies]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NoPolicyDetails, false) == true
}

test_SignInFrequencyNotEnabled_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "SessionControls/SignInFrequency/IsEnabled", "value": false}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NoPolicyDetails, false) == true
}

test_SignInFrequencyTimeBased_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "SessionControls/SignInFrequency/FrequencyInterval", "value": "timeBased"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NoPolicyDetails, false) == true
}

test_State_Incorrect_V1 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "State", "value": "disabled"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NoPolicyDetails, false) == true
}

test_UserRiskLevels_Incorrect if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/UserRiskLevels", "value": [""]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NoPolicyDetails, false) == true
}

test_ServicePlans_Incorrect if {
    Output := aad.tests with input.conditional_access_policies as [UserRiskPolicy]
                        with input.service_plans as [ServicePlans[0]]

    ReportDetailStr := concat("", [
        "**NOTE: Your tenant does not have a Microsoft Entra ID P2 license, which is required for this feature**.",
        " <a href='#caps'>View all CA policies</a>"
    ])
    TestResult("MS.AAD.2.1v2", Output, ReportDetailStr, false) == true
}

# tests for Application exclusions
test_AppExclusionConditions_Correct_V2 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Applications/ExcludeApplications", "value": ["Office365"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v2"].CapExclusions.Applications as ["Office365"]

    TestResult("MS.AAD.2.1v2", Output, MeetsRequirementsDetails, true) == true
}

# tests for guest user type exclusions
test_GuestUserTypeExclusionConditions_Correct_V2 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/ExcludeGuestsOrExternalUsers",
                "value": {
                    "GuestOrExternalUserTypes": "b2bCollaborationGuest,internalGuest",
                    "ExternalTenants": {"MembershipKind": "all"}
                }}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.1v2"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.1v2"].CapExclusions.GuestUserTypes as [
                            "b2bCollaborationGuest",
                            "internalGuest"
                        ]

    TestResult("MS.AAD.2.1v2", Output, MeetsRequirementsDetails, true) == true
}

test_GuestUserTypeExclusionNoExempt_Incorrect_V2 if {
    CAP := json.patch(UserRiskPolicy,
                [{"op": "add", "path": "Conditions/Users/ExcludeGuestsOrExternalUsers",
                "value": {
                    "GuestOrExternalUserTypes": "b2bCollaborationGuest",
                    "ExternalTenants": {"MembershipKind": "all"}
                }}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    TestResult("MS.AAD.2.1v2", Output, NearMissDetails("guest exclusions"), false) == true
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
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>"
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
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>"
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
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>"
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}
test_ApplicationExclusions_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Applications/ExcludeApplications",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans


    ReportDetailStr := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <br/><br/><strong>Near miss: </strong> Test Policy would pass if ",
        "the config file is updated to include:",
        " app exclusions. <a href='#caps'>View all CA policies</a>. ",
        "<a href=\"https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/scubaconfiganalyzer.md\" ",
        "target=\"_blank\">Run the Start-SCuBAConfigAnalyzer cmdlet</a> ",
        "and import your ScubaResults JSON file to determine which specific exclusions to add to the configuration file."
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

# User exclusions test
test_UserExclusionNoExempt_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <br/><br/><strong>Near miss: </strong> Test Policy would pass if ",
        "the config file is updated to include:",
        " user exclusions. <a href='#caps'>View all CA policies</a>. ",
        "<a href=\"https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/scubaconfiganalyzer.md\" ",
        "target=\"_blank\">Run the Start-SCuBAConfigAnalyzer cmdlet</a> ",
        "and import your ScubaResults JSON file to determine which specific exclusions to add to the configuration file."
    ])
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_UserExclusionConditions_Correct_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>"
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

test_UserExclusionsNoExempt_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <br/><br/><strong>Near miss: </strong> Test Policy would pass if ",
        "the config file is updated to include:",
        " user exclusions. <a href='#caps'>View all CA policies</a>. ",
        "<a href=\"https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/scubaconfiganalyzer.md\" ",
        "target=\"_blank\">Run the Start-SCuBAConfigAnalyzer cmdlet</a> ",
        "and import your ScubaResults JSON file to determine which specific exclusions to add to the configuration file."
    ])
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_UserExclusionsSingleExempt_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <br/><br/><strong>Near miss: </strong> Test Policy would pass if ",
        "the config file is updated to include:",
        " user exclusions. <a href='#caps'>View all CA policies</a>. ",
        "<a href=\"https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/scubaconfiganalyzer.md\" ",
        "target=\"_blank\">Run the Start-SCuBAConfigAnalyzer cmdlet</a> ",
        "and import your ScubaResults JSON file to determine which specific exclusions to add to the configuration file."
    ])
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_MultiUserExclusionsConditions_Correct_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Users as [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>"
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

# Group Exclusion tests
test_GroupExclusionNoExempt_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <br/><br/><strong>Near miss: </strong> Test Policy would pass if ",
        "the config file is updated to include:",
        " group exclusions. <a href='#caps'>View all CA policies</a>. ",
        "<a href=\"https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/scubaconfiganalyzer.md\" ",
        "target=\"_blank\">Run the Start-SCuBAConfigAnalyzer cmdlet</a> ",
        "and import your ScubaResults JSON file to determine which specific exclusions to add to the configuration file."
    ])
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_GroupExclusionsConditions_Correct_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>"
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

test_GroupExclusionsNoExempt_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <br/><br/><strong>Near miss: </strong> Test Policy would pass if ",
        "the config file is updated to include:",
        " group exclusions. <a href='#caps'>View all CA policies</a>. ",
        "<a href=\"https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/scubaconfiganalyzer.md\" ",
        "target=\"_blank\">Run the Start-SCuBAConfigAnalyzer cmdlet</a> ",
        "and import your ScubaResults JSON file to determine which specific exclusions to add to the configuration file."
    ])
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_GroupExclusionsSingleExempt_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    ReportDetailStr := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <br/><br/><strong>Near miss: </strong> Test Policy would pass if ",
        "the config file is updated to include:",
        " group exclusions. <a href='#caps'>View all CA policies</a>. ",
        "<a href=\"https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/scubaconfiganalyzer.md\" ",
        "target=\"_blank\">Run the Start-SCuBAConfigAnalyzer cmdlet</a> ",
        "and import your ScubaResults JSON file to determine which specific exclusions to add to the configuration file."
    ])
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_MultiGroupExclusionsConditions_Correct_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Groups as [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>"
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

# User and group exclusions tests
test_UserGroupExclusionConditions_Correct_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>"
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

test_UserGroupExclusionNoExempt_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig

    ReportDetailStr := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <br/><br/><strong>Near miss: </strong> Test Policy would pass if ",
        "the config file is updated to include:",
        " user exclusions, group exclusions. <a href='#caps'>View all CA policies</a>. ",
        "<a href=\"https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/scubaconfiganalyzer.md\" ",
        "target=\"_blank\">Run the Start-SCuBAConfigAnalyzer cmdlet</a> ",
        "and import your ScubaResults JSON file to determine which specific exclusions to add to the configuration file."
    ])
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_UserGroupExclusionUserExemptOnly_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <br/><br/><strong>Near miss: </strong> Test Policy would pass if ",
        "the config file is updated to include:",
        " group exclusions. <a href='#caps'>View all CA policies</a>. ",
        "<a href=\"https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/scubaconfiganalyzer.md\" ",
        "target=\"_blank\">Run the Start-SCuBAConfigAnalyzer cmdlet</a> ",
        "and import your ScubaResults JSON file to determine which specific exclusions to add to the configuration file."
    ])
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_UserGroupExclusionGroupExemptOnly_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    ReportDetailStr := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <br/><br/><strong>Near miss: </strong> Test Policy would pass if ",
        "the config file is updated to include:",
        " user exclusions. <a href='#caps'>View all CA policies</a>. ",
        "<a href=\"https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/scubaconfiganalyzer.md\" ",
        "target=\"_blank\">Run the Start-SCuBAConfigAnalyzer cmdlet</a> ",
        "and import your ScubaResults JSON file to determine which specific exclusions to add to the configuration file."
    ])
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_UserGroupExclusionTooFewUserExempts_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["65fea286-22d3-42f9-b4ca-93a6f75817d4"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Groups as ["65fea286-22d3-42f9-b4ca-93a6f75817d4"]

    ReportDetailStr := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <br/><br/><strong>Near miss: </strong> Test Policy would pass if ",
        "the config file is updated to include:",
        " user exclusions. <a href='#caps'>View all CA policies</a>. ",
        "<a href=\"https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/scubaconfiganalyzer.md\" ",
        "target=\"_blank\">Run the Start-SCuBAConfigAnalyzer cmdlet</a> ",
        "and import your ScubaResults JSON file to determine which specific exclusions to add to the configuration file."
    ])
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

# Other Conditions
test_Conditions_Correct if {
    Output := aad.tests with input.conditional_access_policies as [ConditionalAccessPolicies]
                        with input.service_plans as ServicePlans

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>"
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

test_IncludeApplications_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Applications/IncludeApplications", "value": ["Office365"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <a href='#caps'>View all CA policies</a>"
    ])
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_IncludeUsers_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/IncludeUsers", "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <a href='#caps'>View all CA policies</a>"
    ])
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_ExcludeUsers_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers", "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <br/><br/><strong>Near miss: </strong> Test Policy would pass if ",
        "the config file is updated to include:",
        " user exclusions. <a href='#caps'>View all CA policies</a>. ",
        "<a href=\"https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/scubaconfiganalyzer.md\" ",
        "target=\"_blank\">Run the Start-SCuBAConfigAnalyzer cmdlet</a> ",
        "and import your ScubaResults JSON file to determine which specific exclusions to add to the configuration file."
    ])
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_ExcludeGroups_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups", "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <br/><br/><strong>Near miss: </strong> Test Policy would pass if ",
        "the config file is updated to include:",
        " group exclusions. <a href='#caps'>View all CA policies</a>. ",
        "<a href=\"https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/scubaconfiganalyzer.md\" ",
        "target=\"_blank\">Run the Start-SCuBAConfigAnalyzer cmdlet</a> ",
        "and import your ScubaResults JSON file to determine which specific exclusions to add to the configuration file."
    ])
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_ExcludeRoles_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeRoles", "value": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <a href='#caps'>View all CA policies</a>"
    ])
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_SignInRiskLevels_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies, [{"op": "add", "path": "Conditions/SignInRiskLevels", "value": [""]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <a href='#caps'>View all CA policies</a>"
    ])
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_BuiltInControls_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies, [{"op": "add", "path": "GrantControls/BuiltInControls", "value": [""]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <a href='#caps'>View all CA policies</a>"
    ])
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

test_State_Incorrect_V2 if {
    CAP := json.patch(ConditionalAccessPolicies, [{"op": "add", "path": "State", "value": "disabled"}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <a href='#caps'>View all CA policies</a>"
    ])
    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}

# tests for Application exclusions
test_AppExclusionConditions_Correct_V3 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Applications/ExcludeApplications", "value": ["Office365"]}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.Applications as ["Office365"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>"
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

# tests for guest user type exclusions
test_GuestUserTypeExclusionConditions_Correct_V3 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGuestsOrExternalUsers",
                "value": {
                    "GuestOrExternalUserTypes": "b2bCollaborationGuest,internalGuest",
                    "ExternalTenants": {"MembershipKind": "all"}
                }}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.2.3v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.2.3v1"].CapExclusions.GuestUserTypes as [
                            "b2bCollaborationGuest",
                            "internalGuest"
                        ]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>"
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, true) == true
}

test_GuestUserTypeExclusionNoExempt_Incorrect_V3 if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGuestsOrExternalUsers",
                "value": {
                    "GuestOrExternalUserTypes": "b2bCollaborationGuest",
                    "ExternalTenants": {"MembershipKind": "all"}
                }}])

    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans

    ReportDetailStr := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <br/><br/><strong>Near miss: </strong> Test Policy would pass if ",
        "the config file is updated to include:",
        " guest exclusions. <a href='#caps'>View all CA policies</a>. ",
        "<a href=\"https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/scubaconfiganalyzer.md\" ",
        "target=\"_blank\">Run the Start-SCuBAConfigAnalyzer cmdlet</a> ",
        "and import your ScubaResults JSON file to determine which specific exclusions to add to the configuration file."
    ])

    TestResult("MS.AAD.2.3v1", Output, ReportDetailStr, false) == true
}
#--
