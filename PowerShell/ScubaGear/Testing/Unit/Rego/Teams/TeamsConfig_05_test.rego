package teams_test
import rego.v1
import data.teams
import data.utils.key.TestResult
import data.utils.key.TestResultContains
import data.utils.key.PASS


#
# Policy MS.TEAMS.5.1v1
#--
test_DefaultCatalogAppsType_Correct_V1 if {
    Output := teams.tests with input as {
        "app_policies": [
            {
                "Identity": "Global",
                "DefaultCatalogAppsType": "AllowedAppList"
            }
        ]
    }

    TestResult("MS.TEAMS.5.1v1", Output, PASS, true) == true
}

test_DefaultCatalogAppsType_Correct_V2 if {
    Output := teams.tests with input as {
        "app_policies": [
            {
                "Identity": "Tag:TestPolicy",
                "DefaultCatalogAppsType": "AllowedAppList"
            }
        ]
    }

    TestResult("MS.TEAMS.5.1v1", Output, PASS, true) == true
}

test_DefaultCatalogAppsType_Incorrect_V1 if {
    Output := teams.tests with input as {
        "app_policies": [
            {
                "Identity": "Global",
                "DefaultCatalogAppsType": "BlockedAppList"
            }
        ]
    }

    ReportDetailStr :=
    "1 meeting policy(ies) found that does not restrict installation of Microsoft Apps by default: Global"

    TestResult("MS.TEAMS.5.1v1", Output, ReportDetailStr, false) == true
}

test_DefaultCatalogAppsType_Incorrect_V2 if {
    Output := teams.tests with input as {
        "app_policies": [
            {
                "Identity": "Tag:TestPolicy",
                "DefaultCatalogAppsType": "BlockedAppList"
            }
        ]
    }

    ReportDetailStr :=
    "1 meeting policy(ies) found that does not restrict installation of Microsoft Apps by default: Tag:TestPolicy"

    TestResult("MS.TEAMS.5.1v1", Output, ReportDetailStr, false) == true
}

test_DefaultCatalogAppsType_Multiple if {
    Output := teams.tests with input as {
        "app_policies": [
            {
                "Identity": "Global",
                "DefaultCatalogAppsType": "AllowedAppList"
            },
            {
                "Identity": "Tag:TestPolicy1",
                "DefaultCatalogAppsType": "BlockedAppList"
            },
            {
                "Identity": "Tag:TestPolicy2",
                "DefaultCatalogAppsType": "BlockedAppList"
            }
        ]
    }

    ReportDetailArrayStrs := [
        "2 meeting policy(ies) found that does not restrict installation of Microsoft Apps by default: ",
        "Tag:TestPolicy1",
        "Tag:TestPolicy2"
    ]
    TestResultContains("MS.TEAMS.5.1v1", Output, ReportDetailArrayStrs, false) == true
}
#--

#
# Policy MS.TEAMS.5.2v1
#--
test_GlobalCatalogAppsType_Correct_V1 if {
    Output := teams.tests with input as {
        "app_policies": [
            {
                "Identity": "Global",
                "GlobalCatalogAppsType": "AllowedAppList"
            }
        ]
    }

    TestResult("MS.TEAMS.5.2v1", Output, PASS, true) == true
}

test_GlobalCatalogAppsType_Correct_V2 if {
    Output := teams.tests with input as {
        "app_policies": [
            {
                "Identity": "Tag:TestPolicy",
                "GlobalCatalogAppsType": "AllowedAppList"
            }
        ]
    }

    TestResult("MS.TEAMS.5.2v1", Output, PASS, true) == true
}

test_GlobalCatalogAppsType_Incorrect_V1 if {
    Output := teams.tests with input as {
        "app_policies": [
            {
                "Identity": "Global",
                "GlobalCatalogAppsType": "BlockedAppList"
            }
        ]
    }

    ReportDetailStr :=
    "1 meeting policy(ies) found that does not restrict installation of third-party apps by default: Global"

    TestResult("MS.TEAMS.5.2v1", Output, ReportDetailStr, false) == true
}

test_GlobalCatalogAppsType_Incorrect_V2 if {
    Output := teams.tests with input as {
        "app_policies": [
            {
                "Identity": "Tag:TestPolicy",
                "GlobalCatalogAppsType": "BlockedAppList"
            }
        ]
    }

    ReportDetailStr :=
    "1 meeting policy(ies) found that does not restrict installation of third-party apps by default: Tag:TestPolicy"

    TestResult("MS.TEAMS.5.2v1", Output, ReportDetailStr, false) == true
}

test_GlobalCatalogAppsType_Multiple if {
    Output := teams.tests with input as {
        "app_policies": [
            {
                "Identity": "Global",
                "GlobalCatalogAppsType": "BlockedAppList"
            },
            {
                "Identity": "Tag:TestPolicy1",
                "GlobalCatalogAppsType": "AllowedAppList"
            },
            {
                "Identity": "Tag:TestPolicy2",
                "GlobalCatalogAppsType": "BlockedAppList"
            }
        ]
    }

    ReportDetailArrayStrs := [
        "2 meeting policy(ies) found that does not restrict installation of third-party apps by default: ",
        "Global",
        "Tag:TestPolicy2"
    ]
    TestResultContains("MS.TEAMS.5.2v1", Output, ReportDetailArrayStrs, false) == true
}
#--

#
# Policy MS.TEAMS.5.3v1
#--
test_PrivateCatalogAppsType_Correct_V1 if {
    Output := teams.tests with input as {
        "app_policies": [
            {
                "Identity": "Global",
                "PrivateCatalogAppsType": "AllowedAppList"
            }
        ]
    }

    TestResult("MS.TEAMS.5.3v1", Output, PASS, true) == true
}

test_PrivateCatalogAppsType_Correct_V2 if {
    Output := teams.tests with input as {
        "app_policies": [
            {
                "Identity": "Tag:TestPolicy",
                "PrivateCatalogAppsType": "AllowedAppList"
            }
        ]
    }

    TestResult("MS.TEAMS.5.3v1", Output, PASS, true) == true
}

test_PrivateCatalogAppsType_Incorrect_V1 if {
    Output := teams.tests with input as {
        "app_policies": [
            {
                "Identity": "Global",
                "PrivateCatalogAppsType": "BlockedAppList"
            }
        ]
    }

    ReportDetailStr :=
    "1 meeting policy(ies) found that does not restrict installation of custom apps by default: Global"

    TestResult("MS.TEAMS.5.3v1", Output, ReportDetailStr, false) == true
}

test_PrivateCatalogAppsType_Incorrect_V2 if {
    Output := teams.tests with input as {
        "app_policies": [
            {
                "Identity": "Tag:TestPolicy",
                "PrivateCatalogAppsType": "BlockedAppList"
            }
        ]
    }

    ReportDetailStr :=
    "1 meeting policy(ies) found that does not restrict installation of custom apps by default: Tag:TestPolicy"

    TestResult("MS.TEAMS.5.3v1", Output, ReportDetailStr, false) == true
}

test_PrivateCatalogAppsType_Multiple if {
    Output := teams.tests with input as {
        "app_policies": [
            {
                "Identity": "Global",
                "PrivateCatalogAppsType": "BlockedAppList"
            },
            {
                "Identity": "Tag:TestPolicy1",
                "PrivateCatalogAppsType": "AllowedAppList"
            },
            {
                "Identity": "Tag:TestPolicy2",
                "PrivateCatalogAppsType": "BlockedAppList"
            }
        ]
    }

    ReportDetailArrayStrs := [
        "2 meeting policy(ies) found that does not restrict installation of custom apps by default: ",
        "Global",
        "Tag:TestPolicy2"
    ]
    TestResultContains("MS.TEAMS.5.3v1", Output, ReportDetailArrayStrs, false) == true
}
#--