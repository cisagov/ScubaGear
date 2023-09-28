package aad
import future.keywords

#
# MS.AAD.5.1v1
#--
test_AllowedToCreateApps_Correct if {
    PolicyId := "MS.AAD.5.1v1"

    Output := tests with input as {
        "authorization_policies" : [
            {
                "DefaultUserRolePermissions" : {
                    "AllowedToCreateApps" : false
                },
                "Id" : "authorizationPolicy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 authorization policies found that allow non-admin users to register third-party applications"
}

test_AllowedToCreateApps_Incorrect_V1 if {
    PolicyId := "MS.AAD.5.1v1"

    Output := tests with input as {
        "authorization_policies" : [
            {
                "DefaultUserRolePermissions" : {
                    "AllowedToCreateApps" : true
                },
                "Id" : "Bad policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 authorization policies found that allow non-admin users to register third-party applications:<br/>Bad policy"
}

test_AllowedToCreateApps_Incorrect_V2 if {
    PolicyId := "MS.AAD.5.1v1"

    Output := tests with input as {
        "authorization_policies" : [
            {
                "DefaultUserRolePermissions" : {
                    "AllowedToCreateApps" : true
                },
                "Id" : "Bad policy"
            },
            {
                "DefaultUserRolePermissions" : {
                    "AllowedToCreateApps" : false
                },
                "Id" : "Good policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 authorization policies found that allow non-admin users to register third-party applications:<br/>Bad policy"
}
#--

#
# MS.AAD.5.2v1
#--
test_PermissionGrantPolicyIdsAssignedToDefaultUserRole_Correct if {
    PolicyId := "MS.AAD.5.2v1"

    Output := tests with input as {
        "authorization_policies" : [
            {
                "PermissionGrantPolicyIdsAssignedToDefaultUserRole" : [],
                "Id" : "authorizationPolicy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 authorization policies found that allow non-admin users to consent to third-party applications"
}

test_PermissionGrantPolicyIdsAssignedToDefaultUserRole_Incorrect_V1 if {
    PolicyId := "MS.AAD.5.2v1"

    Output := tests with input as {
        "authorization_policies" : [
            {
                "PermissionGrantPolicyIdsAssignedToDefaultUserRole" : ["Test user"],
                "Id" : "authorizationPolicy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 authorization policies found that allow non-admin users to consent to third-party applications:<br/>authorizationPolicy"
}

test_PermissionGrantPolicyIdsAssignedToDefaultUserRole_Incorrect_V2 if {
    PolicyId := "MS.AAD.5.2v1"

    Output := tests with input as {
        "authorization_policies" : [
            {
                "PermissionGrantPolicyIdsAssignedToDefaultUserRole" : [],
                "Id" : "Good policy"
            },
            {
                "PermissionGrantPolicyIdsAssignedToDefaultUserRole" : ["Test user"],
                "Id" : "Bad policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 authorization policies found that allow non-admin users to consent to third-party applications:<br/>Bad policy"
}
#--

#
# MS.AAD.5.3v1
#--
test_IsEnabled_Correct if {
    PolicyId := "MS.AAD.5.3v1"

    Output := tests with input as {
        "admin_consent_policies" : [
            {
                "IsEnabled" : true,
                "Id" : "policy ID"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_IsEnabled_Incorrect if {
    PolicyId := "MS.AAD.5.3v1"

    Output := tests with input as {
        "admin_consent_policies" : [
            {
                "IsEnabled" : false,
                "Id" : null
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}
#--

#
# MS.AAD.5.4v1
#--
test_Value_Correct_Lowercase if {
    PolicyId := "MS.AAD.5.4v1"

    Output := tests with input as {
        "directory_settings" : [
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

test_Value_Correct_Uppercase if {
    PolicyId := "MS.AAD.5.4v1"

    Output := tests with input as {
        "directory_settings" : [
            {
                "DisplayName" : "Setting display name",
                "Values" : [
                    {
                        "Name" : "EnableGroupSpecificConsent",
                        "Value" : "False"
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

test_Value_Incorrect_Lowercase if {
    PolicyId := "MS.AAD.5.4v1"

    Output := tests with input as {
        "directory_settings" : [
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

test_Value_Incorrect_Uppercase if {
    PolicyId := "MS.AAD.5.4v1"

    Output := tests with input as {
        "directory_settings" : [
            {
                "DisplayName" : "Setting display name",
                "Values" : [
                    {
                        "Name" : "EnableGroupSpecificConsent",
                        "Value" : "True"
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
#--