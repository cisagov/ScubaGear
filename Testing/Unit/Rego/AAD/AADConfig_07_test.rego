package aad
import future.keywords


#
# Policy 1
#--
test_PermissionGrantPolicyIdsAssignedToDefaultUserRole_Correct if {
    PolicyId := "MS.AAD.7.1v1"

    Output := tests with input as {
        "authorization_policies": [
            {
                "PermissionGrantPolicyIdsAssignedToDefaultUserRole": [],
                "Id": "authorizationPolicy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 authorization policies found that allow non-admin users to consent to third-party applications"
}

test_PermissionGrantPolicyIdsAssignedToDefaultUserRole_Incorrect_V1 if {
    PolicyId := "MS.AAD.7.1v1"

    Output := tests with input as {
        "authorization_policies": [
            {
                "PermissionGrantPolicyIdsAssignedToDefaultUserRole": ["Test user"],
                "Id": "authorizationPolicy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
    print(RuleOutput)
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 authorization policies found that allow non-admin users to consent to third-party applications:<br/>authorizationPolicy"
}

test_PermissionGrantPolicyIdsAssignedToDefaultUserRole_Incorrect_V2 if {
    PolicyId := "MS.AAD.7.1v1"

    Output := tests with input as {
        "authorization_policies": [
            {
                "PermissionGrantPolicyIdsAssignedToDefaultUserRole": [],
                "Id": "Good policy"
            },
            {
                "PermissionGrantPolicyIdsAssignedToDefaultUserRole": ["Test user"],
                "Id": "Bad policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
    print(RuleOutput)
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 authorization policies found that allow non-admin users to consent to third-party applications:<br/>Bad policy"
}


#
# Policy 2
#--
test_IsEnabled_Correct if {
    PolicyId := "MS.AAD.7.2v1"

    Output := tests with input as {
        "admin_consent_policies": [
            {
                "IsEnabled" : true,
                "Id": "policy ID"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_IsEnabled_Incorrect if {
    PolicyId := "MS.AAD.7.2v1"

    Output := tests with input as {
        "admin_consent_policies": [
            {
                "IsEnabled" : false,
                "Id": null
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

#
# Policy 3
#--
test_Value_Correct if {
    PolicyId := "MS.AAD.7.3v1"

    Output := tests with input as {
        "directory_settings": [
            {
                "DisplayName" : "Setting display name",
                "Values" : [
                    {
                        "Name" : "EnableGroupSpecificConsent",
                        "Value" : "false"
                    }
                ]
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Value_Incorrect if {
    PolicyId := "MS.AAD.7.3v1"

    Output := tests with input as {
        "directory_settings": [
            {
                "DisplayName" : "Setting display name",
                "Values" : [
                    {
                        "Name" : "EnableGroupSpecificConsent",
                        "Value" : "true"
                    }
                ]
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}