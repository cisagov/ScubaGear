package entraid_test
import future.keywords
import data.entraid
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS


#
# Policy MS.ENTRAID.5.1v1
#--
test_AllowedToCreateApps_Correct if {
    Output := entraid.tests with input as {
        "authorization_policies": [
            {
                "DefaultUserRolePermissions": {
                    "AllowedToCreateApps": false
                },
                "Id": "authorizationPolicy"
            }
        ]
    }

    ReportDetailStr := "0 authorization policies found that allow non-admin users to register third-party applications"
    TestResult("MS.ENTRAID.5.1v1", Output, ReportDetailStr, true) == true
}

test_AllowedToCreateApps_Incorrect_V1 if {
    Output := entraid.tests with input as {
        "authorization_policies": [
            {
                "DefaultUserRolePermissions": {
                    "AllowedToCreateApps": true
                },
                "Id": "Bad policy"
            }
        ]
    }

    ReportDetailStr := concat("", [
        "1 authorization policies found that allow non-admin users to register third-party applications:",
        "<br/>Bad policy"
    ])

    TestResult("MS.ENTRAID.5.1v1", Output, ReportDetailStr, false) == true
}

test_AllowedToCreateApps_Incorrect_V2 if {
    Output := entraid.tests with input as {
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

    ReportDetailStr := concat("", [
        "1 authorization policies found that allow non-admin users to register third-party applications:",
        "<br/>Bad policy"
    ])

    TestResult("MS.ENTRAID.5.1v1", Output, ReportDetailStr, false) == true
}
#--

#
# Policy MS.ENTRAID.5.2v1
#--
test_PermissionGrantPolicyIdsAssignedToDefaultUserRole_Correct if {
    Output := entraid.tests with input as {
        "authorization_policies": [
            {
                "PermissionGrantPolicyIdsAssignedToDefaultUserRole": [],
                "Id": "authorizationPolicy"
            }
        ]
    }

    ReportDetailStr :=
        "0 authorization policies found that allow non-admin users to consent to third-party applications"
    TestResult("MS.ENTRAID.5.2v1", Output, ReportDetailStr, true) == true
}

test_PermissionGrantPolicyIdsAssignedToDefaultUserRole_Incorrect_V1 if {
    Output := entraid.tests with input as {
        "authorization_policies": [
            {
                "PermissionGrantPolicyIdsAssignedToDefaultUserRole": [
                    "Test user"
                ],
                "Id": "authorizationPolicy"
            }
        ]
    }

    ReportDetailStr := concat("", [
        "1 authorization policies found that allow non-admin users to consent to third-party applications:",
        "<br/>authorizationPolicy"
    ])

    TestResult("MS.ENTRAID.5.2v1", Output, ReportDetailStr, false) == true
}

test_PermissionGrantPolicyIdsAssignedToDefaultUserRole_Incorrect_V2 if {
    Output := entraid.tests with input as {
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

    ReportDetailStr := concat("", [
        "1 authorization policies found that allow non-admin users to consent to third-party applications:",
        "<br/>Bad policy"
    ])

    TestResult("MS.ENTRAID.5.2v1", Output, ReportDetailStr, false) == true
}
#--

#
# Policy MS.ENTRAID.5.3v1
#--
test_IsEnabled_Correct if {
    Output := entraid.tests with input as {
        "directory_settings": [
            {
                "DisplayName": "Setting display name",
                "Values": [
                    {
                        "Name":  "EnableAdminConsentRequests",
                        "Value":  "true"
                    }
                ]
            }
        ]
    }

    TestResult("MS.ENTRAID.5.3v1", Output, PASS, true) == true
}

test_IsEnabled_Incorrect_Missing if {
    Output := entraid.tests with input as {
        "directory_settings": [
            {
                "DisplayName": "Setting display name",
                "Values": [
                    {
                        "Name":  "EnableGroupSpecificConsent",
                        "Value":  "false"
                    }
                ]
            }
        ]
    }

    TestResult("MS.ENTRAID.5.3v1", Output, FAIL, false) == true
}

test_IsEnabled_Incorrect if {
    Output := entraid.tests with input as {
        "directory_settings": [
            {
                "DisplayName": "Setting display name",
                "Values": [
                    {
                        "Name":  "EnableAdminConsentRequests",
                        "Value":  "false"
                    }
                ]
            }
        ]
    }

    TestResult("MS.ENTRAID.5.3v1", Output, FAIL, false) == true
}
#--

#
# Policy MS.ENTRAID.5.4v1
#--
test_Value_Correct_Lowercase if {
    Output := entraid.tests with input as {
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

    TestResult("MS.ENTRAID.5.4v1", Output, PASS, true) == true
}

test_Value_Correct_Uppercase if {
    Output := entraid.tests with input as {
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

    TestResult("MS.ENTRAID.5.4v1", Output, PASS, true) == true
}

test_Value_Incorrect_Lowercase if {
    Output := entraid.tests with input as {
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

    TestResult("MS.ENTRAID.5.4v1", Output, FAIL, false) == true
}

test_Value_Incorrect_Uppercase if {
    Output := entraid.tests with input as {
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

    TestResult("MS.ENTRAID.5.4v1", Output, FAIL, false) == true
}
#--