package teams_test
import future.keywords
import data.teams
import data.utils.policy.CorrectTestResult
import data.utils.policy.IncorrectTestResult
import data.utils.policy.PASS


#
# MS.TEAMS.5.1v1
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

    CorrectTestResult("MS.TEAMS.5.1v1", Output, PASS) == true
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

    CorrectTestResult("MS.TEAMS.5.1v1", Output, PASS) == true
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

    ReportDetailString := "1 meeting policy(ies) found that does not restrict installation of Microsoft Apps by default: Global"
    IncorrectTestResult("MS.TEAMS.5.1v1", Output, ReportDetailString) == true
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

    ReportDetailString := "1 meeting policy(ies) found that does not restrict installation of Microsoft Apps by default: Tag:TestPolicy"
    IncorrectTestResult("MS.TEAMS.5.1v1", Output, ReportDetailString) == true
}

test_DefaultCatalogAppsType_Multiple if {
    PolicyId := "MS.TEAMS.5.1v1"

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

    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == false
    startswith(RuleOutput[0].ReportDetails, "2 meeting policy(ies) found that does not restrict installation of Microsoft Apps by default: ")
    contains(RuleOutput[0].ReportDetails, "Tag:TestPolicy1")
    contains(RuleOutput[0].ReportDetails, "Tag:TestPolicy2")
}
#--

#
# MS.TEAMS.5.2v1
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

    CorrectTestResult("MS.TEAMS.5.2v1", Output, PASS) == true
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

    CorrectTestResult("MS.TEAMS.5.2v1", Output, PASS) == true
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

    ReportDetailString := "1 meeting policy(ies) found that does not restrict installation of third-party apps by default: Global"
    IncorrectTestResult("MS.TEAMS.5.2v1", Output, ReportDetailString) == true
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

    ReportDetailString := "1 meeting policy(ies) found that does not restrict installation of third-party apps by default: Tag:TestPolicy"
    IncorrectTestResult("MS.TEAMS.5.2v1", Output, ReportDetailString) == true
}

test_GlobalCatalogAppsType_Multiple if {
    PolicyId := "MS.TEAMS.5.2v1"

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

    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == false
    startswith(RuleOutput[0].ReportDetails, "2 meeting policy(ies) found that does not restrict installation of third-party apps by default: ")
    contains(RuleOutput[0].ReportDetails, "Global")
    contains(RuleOutput[0].ReportDetails, "Tag:TestPolicy2")
}
#--

#
# MS.TEAMS.5.3v1
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

    CorrectTestResult("MS.TEAMS.5.3v1", Output, PASS) == true
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

    CorrectTestResult("MS.TEAMS.5.3v1", Output, PASS) == true
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

    ReportDetailString := "1 meeting policy(ies) found that does not restrict installation of custom apps by default: Global"
    IncorrectTestResult("MS.TEAMS.5.3v1", Output, ReportDetailString) == true
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

    ReportDetailString := "1 meeting policy(ies) found that does not restrict installation of custom apps by default: Tag:TestPolicy"
    IncorrectTestResult("MS.TEAMS.5.3v1", Output, ReportDetailString) == true
}

test_PrivateCatalogAppsType_Multiple if {
    PolicyId := "MS.TEAMS.5.3v1"

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

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == false
    startswith(RuleOutput[0].ReportDetails, "2 meeting policy(ies) found that does not restrict installation of custom apps by default: ")
    contains(RuleOutput[0].ReportDetails, "Global")
    contains(RuleOutput[0].ReportDetails, "Tag:TestPolicy2")
}
#--