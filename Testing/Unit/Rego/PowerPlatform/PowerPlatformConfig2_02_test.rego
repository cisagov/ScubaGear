package powerplatform
import future.keywords


#
# Policy 1
#--
test_name_Correct if {
    ControlNumber := "Power Platform 2.2"
    Requirement := "A DLP policy SHALL be created to restrict connector access in the default Power Platform environment"

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

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_name_Incorrect if {
    ControlNumber := "Power Platform 2.2"
    Requirement := "A DLP policy SHALL be created to restrict connector access in the default Power Platform environment"

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

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No policy found that applies to default environment"
}

#
# Policy 2
#--
test_environment_list_Correct if {
    ControlNumber := "Power Platform 2.2"
    Requirement := "Non-default environments SHOULD have at least one DLP policy that affects them"

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

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_environment_list_Incorrect if {
    ControlNumber := "Power Platform 2.2"
    Requirement := "Non-default environments SHOULD have at least one DLP policy that affects them"

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

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 Subsequent environments without DLP policies: Test1"
}

#
# Policy 3
#--
test_classification_Correct_V1 if {
    ControlNumber := "Power Platform 2.2"
    Requirement := "All connectors except those listed...[see Power Platform secure configuration baseline for list]...SHOULD be added to the Blocked category in the default environment policy"

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

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_classification_Correct_V2 if {
    ControlNumber := "Power Platform 2.2"
    Requirement := "All connectors except those listed...[see Power Platform secure configuration baseline for list]...SHOULD be added to the Blocked category in the default environment policy"

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

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_connectorGroups_Correct if {
    ControlNumber := "Power Platform 2.2"
    Requirement := "All connectors except those listed...[see Power Platform secure configuration baseline for list]...SHOULD be added to the Blocked category in the default environment policy"

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

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_classification_Incorrect_V1 if {
    ControlNumber := "Power Platform 2.2"
    Requirement := "All connectors except those listed...[see Power Platform secure configuration baseline for list]...SHOULD be added to the Blocked category in the default environment policy"

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

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 Connectors are allowed that should be blocked: HttpWebhook"
}

test_classification_Incorrect_V2 if {
    ControlNumber := "Power Platform 2.2"
    Requirement := "All connectors except those listed...[see Power Platform secure configuration baseline for list]...SHOULD be added to the Blocked category in the default environment policy"

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

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 Connectors are allowed that should be blocked: HttpWebhook"
}

test_connectorGroups_Incorrect if {
    ControlNumber := "Power Platform 2.2"
    Requirement := "All connectors except those listed...[see Power Platform secure configuration baseline for list]...SHOULD be added to the Blocked category in the default environment policy"

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

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 Connectors are allowed that should be blocked: HttpWebhook"
}