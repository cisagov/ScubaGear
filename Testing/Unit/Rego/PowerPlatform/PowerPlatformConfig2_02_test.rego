package powerplatform
import future.keywords


#
# Policy 1
#--
test_name_Correct if {
    PolicyId := "MS.POWERPLATFORM.2.1v1"

    Output := tests with input as {
        "tenant_id": "Test Id",
        "dlp_policies": [{
            "value":  [{
                "displayName":  "Block Third-Party Connectors",
                "environments":  [{
                    "name":  "Default-Test Id"
                }]
            }]
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_name_Incorrect if {
    PolicyId := "MS.POWERPLATFORM.2.1v1"

    Output := tests with input as {
        "tenant_id": "Test Id",
        "dlp_policies": [{
            "value":  [{
                "displayName":  "Block Third-Party Connectors",
                "environments":  [{
                    "name":  "NotDefault-Test Id"
                }]
            }]
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No policy found that applies to default environment"
}

#
# Policy 2
#--
test_environment_list_Correct if {
    PolicyId := "MS.POWERPLATFORM.2.2v1"

    Output := tests with input as {
        "dlp_policies": [{
            "value":  [{
                "displayName":  "Block Third-Party Connectors",
                "environments":  [{
                    "name":  "Default-Test Id"
                }]
            }]
        }],
        "environment_list": [{
            "EnvironmentName":  "Default-Test Id"
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_environment_list_Incorrect if {
    PolicyId := "MS.POWERPLATFORM.2.2v1"

    Output := tests with input as {
        "dlp_policies": [{
            "value":  [{
                "displayName":  "Block Third-Party Connectors",
                "environments":  [{
                    "name":  "Default-Test Id"
                }]
            }]
        }],
        "environment_list": [{
            "EnvironmentName":  "Default-Test Id"

        },
        {
            "EnvironmentName":  "Test1"

        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 Subsequent environments without DLP policies: Test1"
}

#
# Policy 3
#--
test_classification_Correct_V1 if {
    PolicyId := "MS.POWERPLATFORM.2.3v1"

    Output := tests with input as {
        "tenant_id": "Test Id",
        "dlp_policies": [{
            "value":  [{
                "connectorGroups":  [{
                    "classification":  "Confidential",
                    "connectors":  [{
                        "id":  "/providers/Microsoft.PowerApps/apis/shared_powervirtualagents"
                    }]
                }],
                "environments":  [{
                    "name":  "Default-Test Id"
                }]
            }]
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_classification_Correct_V2 if {
    PolicyId := "MS.POWERPLATFORM.2.3v1"

    Output := tests with input as {
        "tenant_id": "Test Id",
        "dlp_policies": [{
            "value":  [{
                "connectorGroups":  [{
                    "classification":  "General",
                    "connectors":  [{
                        "id":  "/providers/Microsoft.PowerApps/apis/shared_powervirtualagents"
                    }]
                }],
                "environments":  [{
                    "name":  "Default-Test Id"
                }]
            }]
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_connectorGroups_Correct if {
    PolicyId := "MS.POWERPLATFORM.2.3v1"

    Output := tests with input as {
        "tenant_id": "Test Id",
        "dlp_policies": [{
            "value":  [{
                "connectorGroups":  [{
                    "classification":  "Confidential",
                    "connectors":  [{
                        "id":  "/providers/Microsoft.PowerApps/apis/shared_powervirtualagents"
                    }]
                },
                {
                    "classification":  "General",
                    "connectors":  [{
                        "id":  "/providers/Microsoft.PowerApps/apis/shared_powervirtualagents"
                    }]
                }],
                "environments":  [{
                    "name":  "Default-Test Id"
                }]
            }]
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_classification_Incorrect_V1 if {
    PolicyId := "MS.POWERPLATFORM.2.3v1"

    Output := tests with input as {
        "tenant_id": "Test Id",
        "dlp_policies": [{
            "value":  [{
                "connectorGroups":  [{
                    "classification":  "Confidential",
                    "connectors":  [{
                        "id":  "HttpWebhook"
                    }]
                }],
                "environments":  [{
                    "name":  "Default-Test Id"
                }]
            }]
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 Connectors are allowed that should be blocked: HttpWebhook"
}

test_classification_Incorrect_V2 if {
    PolicyId := "MS.POWERPLATFORM.2.3v1"

    Output := tests with input as {
        "tenant_id": "Test Id",
        "dlp_policies": [{
            "value":  [{
                "connectorGroups":  [{
                    "classification":  "General",
                    "connectors":  [{
                        "id":  "HttpWebhook"
                    }]
                }],
                "environments":  [{
                    "name":  "Default-Test Id"
                }]
            }]
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 Connectors are allowed that should be blocked: HttpWebhook"
}

test_connectorGroups_Incorrect if {
    PolicyId := "MS.POWERPLATFORM.2.3v1"

    Output := tests with input as {
        "tenant_id": "Test Id",
        "dlp_policies": [{
            "value":  [{
                "connectorGroups":  [{
                    "classification":  "Confidential",
                    "connectors":  [{
                        "id":  "HttpWebhook"
                    }]
                },
                {
                    "classification":  "General",
                    "connectors":  [{
                        "id":  "HttpWebhook"
                    }]
                }],
                "environments":  [{
                    "name":  "Default-Test Id"
                }]
            }]
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 Connectors are allowed that should be blocked: HttpWebhook"
}