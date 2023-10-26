package teams
import future.keywords

#--
# MS.TEAMS.5.1v1
#--
test_DefaultCatalogAppsType_Correct_V1 if {
    PolicyId := "MS.TEAMS.5.1v1"

    Output := tests with input as {
        "app_policies": [
            {
                "Identity": "Global",
                "DefaultCatalogAppsType": "AllowedAppList"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_DefaultCatalogAppsType_Correct_V2 if {
    PolicyId := "MS.TEAMS.5.1v1"

    Output := tests with input as {
        "app_policies": [
            {
                "Identity": "Tag:TestPolicy",
                "DefaultCatalogAppsType": "AllowedAppList"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_DefaultCatalogAppsType_Incorrect_V1 if {
    PolicyId := "MS.TEAMS.5.1v1"

    Output := tests with input as {
        "app_policies": [
            {
                "Identity": "Global",
                "DefaultCatalogAppsType": "BlockedAppList"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 meeting policy(ies) found that does not restrict installation of Microsoft Apps by default: Global"
}

test_DefaultCatalogAppsType_Incorrect_V2 if {
    PolicyId := "MS.TEAMS.5.1v1"

    Output := tests with input as {
        "app_policies": [
            {
                "Identity": "Tag:TestPolicy",
                "DefaultCatalogAppsType": "BlockedAppList"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 meeting policy(ies) found that does not restrict installation of Microsoft Apps by default: Tag:TestPolicy"
}

test_DefaultCatalogAppsType_Multiple if {
    PolicyId := "MS.TEAMS.5.1v1"

    Output := tests with input as {
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

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    startswith(RuleOutput[0].ReportDetails, "2 meeting policy(ies) found that does not restrict installation of Microsoft Apps by default: ")
    contains(RuleOutput[0].ReportDetails, "Tag:TestPolicy1")
    contains(RuleOutput[0].ReportDetails, "Tag:TestPolicy2")
}
#--

#--
# MS.TEAMS.5.2v1
#--
test_GlobalCatalogAppsType_Correct_V1 if {
    PolicyId := "MS.TEAMS.5.2v1"

    Output := tests with input as {
        "app_policies": [
            {
                "Identity": "Global",
                "GlobalCatalogAppsType": "AllowedAppList"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_GlobalCatalogAppsType_Correct_V2 if {
    PolicyId := "MS.TEAMS.5.2v1"

    Output := tests with input as {
        "app_policies": [
            {
                "Identity": "Tag:TestPolicy",
                "GlobalCatalogAppsType": "AllowedAppList"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_GlobalCatalogAppsType_Incorrect_V1 if {
    PolicyId := "MS.TEAMS.5.2v1"

    Output := tests with input as {
        "app_policies": [
            {
                "Identity": "Global",
                "GlobalCatalogAppsType": "BlockedAppList"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 meeting policy(ies) found that does not restrict installation of third-party apps by default: Global"
}

test_GlobalCatalogAppsType_Incorrect_V2 if {
    PolicyId := "MS.TEAMS.5.2v1"

    Output := tests with input as {
        "app_policies": [
            {
                "Identity": "Tag:TestPolicy",
                "GlobalCatalogAppsType": "BlockedAppList"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 meeting policy(ies) found that does not restrict installation of third-party apps by default: Tag:TestPolicy"
}

test_GlobalCatalogAppsType_Multiple if {
    PolicyId := "MS.TEAMS.5.2v1"

    Output := tests with input as {
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

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    startswith(RuleOutput[0].ReportDetails, "2 meeting policy(ies) found that does not restrict installation of third-party apps by default: ")
    contains(RuleOutput[0].ReportDetails, "Global")
    contains(RuleOutput[0].ReportDetails, "Tag:TestPolicy2")
}
#--

#--
# MS.TEAMS.5.3v1
#--
test_PrivateCatalogAppsType_Correct_V1 if {
    PolicyId := "MS.TEAMS.5.3v1"

    Output := tests with input as {
        "app_policies": [
            {
                "Identity": "Global",
                "PrivateCatalogAppsType": "AllowedAppList"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_PrivateCatalogAppsType_Correct_V2 if {
    PolicyId := "MS.TEAMS.5.3v1"

    Output := tests with input as {
        "app_policies": [
            {
                "Identity": "Tag:TestPolicy",
                "PrivateCatalogAppsType": "AllowedAppList"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_PrivateCatalogAppsType_Incorrect_V1 if {
    PolicyId := "MS.TEAMS.5.3v1"

    Output := tests with input as {
        "app_policies": [
            {
                "Identity": "Global",
                "PrivateCatalogAppsType": "BlockedAppList"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 meeting policy(ies) found that does not restrict installation of custom apps by default: Global"
}

test_PrivateCatalogAppsType_Incorrect_V2 if {
    PolicyId := "MS.TEAMS.5.3v1"

    Output := tests with input as {
        "app_policies": [
            {
                "Identity": "Tag:TestPolicy",
                "PrivateCatalogAppsType": "BlockedAppList"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 meeting policy(ies) found that does not restrict installation of custom apps by default: Tag:TestPolicy"
}

test_PrivateCatalogAppsType_Multiple if {
    PolicyId := "MS.TEAMS.5.3v1"

    Output := tests with input as {
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
    not RuleOutput[0].RequirementMet
    startswith(RuleOutput[0].ReportDetails, "2 meeting policy(ies) found that does not restrict installation of custom apps by default: ")
    contains(RuleOutput[0].ReportDetails, "Global")
    contains(RuleOutput[0].ReportDetails, "Tag:TestPolicy2")
}
#--
