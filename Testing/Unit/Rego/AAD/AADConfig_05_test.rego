package aad_test
import future.keywords
import data.aad
import data.utils.policy.CorrectTestResult
import data.utils.policy.IncorrectTestResult
import data.utils.policy.FAIL
import data.utils.policy.PASS


#
# MS.AAD.5.1v1
#--
test_AllowedToCreateApps_Correct if {
    Output := aad.tests with input as {
        "authorization_policies": [
            {
                "DefaultUserRolePermissions": {
                    "AllowedToCreateApps": false
                },
                "Id": "authorizationPolicy"
            }
        ]
    }

    ReportDetailString := "0 authorization policies found that allow non-admin users to register third-party applications"
    CorrectTestResult("MS.AAD.5.1v1", Output, ReportDetailString) == true
}

test_AllowedToCreateApps_Incorrect_V1 if {
    Output := aad.tests with input as {
        "authorization_policies": [
            {
                "DefaultUserRolePermissions": {
                    "AllowedToCreateApps": true
                },
                "Id": "Bad policy"
            }
        ]
    }

    ReportDetailString := "1 authorization policies found that allow non-admin users to register third-party applications:<br/>Bad policy"
    IncorrectTestResult("MS.AAD.5.1v1", Output, ReportDetailString) == true
}

test_AllowedToCreateApps_Incorrect_V2 if {
    Output := aad.tests with input as {
        "authorization_policies": [
            {
                "DefaultUserRolePermissions": {
                    "AllowedToCreateApps": true
                },
                "Id": "Bad policy"
            },
            {
                "DefaultUserRolePermissions": {
                    "AllowedToCreateApps": false
                },
                "Id": "Good policy"
            }
        ]
    }

    ReportDetailString := "1 authorization policies found that allow non-admin users to register third-party applications:<br/>Bad policy"
    IncorrectTestResult("MS.AAD.5.1v1", Output, ReportDetailString) == true
}
#--

#
# MS.AAD.5.2v1
#--
test_PermissionGrantPolicyIdsAssignedToDefaultUserRole_Correct if {
    Output := aad.tests with input as {
        "authorization_policies": [
            {
                "PermissionGrantPolicyIdsAssignedToDefaultUserRole": [],
                "Id": "authorizationPolicy"
            }
        ]
    }

    ReportDetailString := "0 authorization policies found that allow non-admin users to consent to third-party applications"
    CorrectTestResult("MS.AAD.5.2v1", Output, ReportDetailString) == true
}

test_PermissionGrantPolicyIdsAssignedToDefaultUserRole_Incorrect_V1 if {
    Output := aad.tests with input as {
        "authorization_policies": [
            {
                "PermissionGrantPolicyIdsAssignedToDefaultUserRole": [
                    "Test user"
                ],
                "Id": "authorizationPolicy"
            }
        ]
    }

    ReportDetailString := "1 authorization policies found that allow non-admin users to consent to third-party applications:<br/>authorizationPolicy"
    IncorrectTestResult("MS.AAD.5.2v1", Output, ReportDetailString) == true
}

test_PermissionGrantPolicyIdsAssignedToDefaultUserRole_Incorrect_V2 if {
    Output := aad.tests with input as {
        "authorization_policies": [
            {
                "PermissionGrantPolicyIdsAssignedToDefaultUserRole": [],
                "Id": "Good policy"
            },
            {
                "PermissionGrantPolicyIdsAssignedToDefaultUserRole": [
                    "Test user"
                ],
                "Id": "Bad policy"
            }
        ]
    }

    ReportDetailString := "1 authorization policies found that allow non-admin users to consent to third-party applications:<br/>Bad policy"
    IncorrectTestResult("MS.AAD.5.2v1", Output, ReportDetailString) == true
}
#--

#
# MS.AAD.5.3v1
#--
test_IsEnabled_Correct if {
    Output := aad.tests with input as {
        "admin_consent_policies": [
            {
                "IsEnabled": true,
                "Id": "policy ID"
            }
        ]
    }

    CorrectTestResult("MS.AAD.5.3v1", Output, PASS) == true
}

test_IsEnabled_Incorrect if {
    Output := aad.tests with input as {
        "admin_consent_policies": [
            {
                "IsEnabled": false,
                "Id": null
            }
        ]
    }

    IncorrectTestResult("MS.AAD.5.3v1", Output, FAIL) == true
}
#--

#
# MS.AAD.5.4v1
#--
test_Value_Correct_Lowercase if {
    Output := aad.tests with input as {
        "directory_settings": [
            {
                "DisplayName": "Setting display name",
                "Values": [
                    {
                        "Name": "EnableGroupSpecificConsent",
                        "Value": "false"
                    }
                ]
            }
        ]
    }

    CorrectTestResult("MS.AAD.5.4v1", Output, PASS) == true
}

test_Value_Correct_Uppercase if {
    Output := aad.tests with input as {
        "directory_settings": [
            {
                "DisplayName": "Setting display name",
                "Values": [
                    {
                        "Name": "EnableGroupSpecificConsent",
                        "Value": "False"
                    }
                ]
            }
        ]
    }

    CorrectTestResult("MS.AAD.5.4v1", Output, PASS) == true
}

test_Value_Incorrect_Lowercase if {
    Output := aad.tests with input as {
        "directory_settings": [
            {
                "DisplayName": "Setting display name",
                "Values": [
                    {
                        "Name": "EnableGroupSpecificConsent",
                        "Value": "true"
                    }
                ]
            }
        ]
    }

    IncorrectTestResult("MS.AAD.5.4v1", Output, FAIL) == true
}

test_Value_Incorrect_Uppercase if {
    Output := aad.tests with input as {
        "directory_settings": [
            {
                "DisplayName": "Setting display name",
                "Values": [
                    {
                        "Name": "EnableGroupSpecificConsent",
                        "Value": "True"
                    }
                ]
            }
        ]
    }

    IncorrectTestResult("MS.AAD.5.4v1", Output, FAIL) == true
}
#--