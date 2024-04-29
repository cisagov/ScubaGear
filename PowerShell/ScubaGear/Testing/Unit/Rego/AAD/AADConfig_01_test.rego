package aad_test
import rego.v1
import data.aad
import data.utils.key.TestResult
import data.test.assert


#
# Policy MS.AAD.1.1v1
#--
test_NoExclusionsConditions_Correct if {
    Output := aad.tests with input as AADConfig

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
    ])

    TestOutput := TestResult("MS.AAD.1.1v1", Output, true)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_NoExclusionsIncludeApplications_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Applications/IncludeApplications",
                "value": ["Office365"]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]



    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_NoExclusionsIncludeUsers_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/IncludeUsers",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_NoExclusionsExcludeUsers_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_NoExclusionsExcludeGroups_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_NoExclusionsClientAppTypes_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/ClientAppTypes",
                "value": [""]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_NoExclusionsBuiltInControls_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "GrantControls/BuiltInControls",
                "value": []}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_NoExclusionsState_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "State",
                "value": "disabled"}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

# tests for user exclusions and no group exclusions
test_NoExclusionsExemptUsers_Correct if {
    Output := aad.tests with input as AADConfig
                        with input.scuba_config as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.1.1v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
    ])

    TestOutput := TestResult("MS.AAD.1.1v1", Output, true)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_UserExclusionsConditions_Correct if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]
                        with input.scuba_config as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.1.1v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
    ])

    TestOutput := TestResult("MS.AAD.1.1v1", Output, true)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_MultiUserExclusionsConditions_Correct if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": [
                        "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                        "df269963-a081-4315-b7de-172755221504"
                        ]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]
                        with input.scuba_config as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.1.1v1"].CapExclusions.Users as [
                            "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                            "df269963-a081-4315-b7de-172755221504"
                        ]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
    ])

    TestOutput := TestResult("MS.AAD.1.1v1", Output, true)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_UserExclusionNoExempt_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_UserExclusionsSingleExempt_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": [
                        "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                        "df269963-a081-4315-b7de-172755221504"
                        ]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]
                        with input.scuba_config as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.1.1v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_UserExclusionsNoExempt_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": [
                        "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                        "df269963-a081-4315-b7de-172755221504"
                        ]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]
                        with input.scuba_config as ScubaConfig

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_UserExclusionsIncludeApplications_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Applications/IncludeApplications",
                "value": ["Office365"]},
                {"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]
                        with input.scuba_config as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.1.1v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_UserExclusionsIncludeUsers_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/IncludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]
                        with input.scuba_config as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.1.1v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_UserExclusionsExcludeGroups_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]
                        with input.scuba_config as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.1.1v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_UserExclusionsClientAppTypes_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/ClientAppTypes",
                "value": [""]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]
                        with input.scuba_config as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.1.1v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_UserExclusionsBuiltInControls_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "GrantControls/BuiltInControls",
                "value": []}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]
                        with input.scuba_config as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.1.1v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_UserExclusionsState_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "State",
                "value": "disabled"}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]
                        with input.scuba_config as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.1.1v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

# tests for group exclusions and no user exclusions
test_NoExclusionsExemptGroups_Correct if {
    Output := aad.tests with input as AADConfig
                        with input.scuba_config as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.1.1v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
    ])

    TestOutput := TestResult("MS.AAD.1.1v1", Output, true)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_GroupExclusionNoExempt_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]
                        with input.scuba_config as ScubaConfig

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_GroupExclusionsNoExempt_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": [
                        "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423",
                        "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]
                        with input.scuba_config as ScubaConfig

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_GroupExclusionsSingleExempt_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": [
                        "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423",
                        "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]
                        with input.scuba_config as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.1.1v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_GroupExclusionConditions_Correct if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]
                        with input.scuba_config as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.1.1v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
    ])

    TestOutput := TestResult("MS.AAD.1.1v1", Output, true)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_MultiGroupExclusionsConditions_Correct if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": [
                        "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423",
                        "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]
                        with input.scuba_config as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.1.1v1"].CapExclusions.Groups as [
                            "49b4dcdf-1f90-41a5-9dd7-5e7c3609b423",
                            "65fea286-22d3-42f9-b4ca-93a6f75817d4"
                        ]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
    ])

    TestOutput := TestResult("MS.AAD.1.1v1", Output, true)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

# tests when both group and user exclusions present
test_UserGroupExclusionConditions_Correct if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]
                        with input.scuba_config as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.1.1v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                        with input.scuba_config.Aad["MS.AAD.1.1v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
    ])

    TestOutput := TestResult("MS.AAD.1.1v1", Output, true)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_UserGroupExclusionNoExempt_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_UserGroupExclusionUserExemptOnly_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]
                        with input.scuba_config as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.1.1v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_UserGroupExclusionGroupExemptOnly_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]
                        with input.scuba_config as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.1.1v1"].CapExclusions.Groups as ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}

test_UserGroupExclusionTooFewUserExempts_Incorrect if {
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/Users/ExcludeUsers",
                "value": [
                        "49b4dcdf-1f90-41a7c3609b425-9dd7-5e3",
                        "df269963-a081-4315-b7de-172755221504"
                        ]},
                {"op": "add", "path": "Conditions/Users/ExcludeGroups",
                "value": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]}])

    Output := aad.tests with input as AADConfig
                        with input.conditional_access_policies as [CAP]
                        with input.scuba_config as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.1.1v1"].CapExclusions.Users as ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"]

    ReportDetailStr :=
        "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."

    TestOutput := TestResult("MS.AAD.1.1v1", Output, false)
    TestOutput.Result == true
    print("** Checking ReportDetails **")
    assert.equals(ReportDetailStr, TestOutput.Test.ReportDetails)
}
#--