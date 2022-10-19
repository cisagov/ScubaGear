package defender
import future.keywords


#
# Policy 1
#--
test_BulkThreshold_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "The bulk complaint level (BCL) threshold SHOULD be set to six or lower: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "BulkThreshold":  6,
                "Identity" : "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_BulkThreshold_CorrectV2 if {
    ControlNumber := "Defender 2.6"
    Requirement := "The bulk complaint level (BCL) threshold SHOULD be set to six or lower: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "BulkThreshold":  5,
                "Identity" : "Default"                
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_BulkThreshold_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "The bulk complaint level (BCL) threshold SHOULD be set to six or lower: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "BulkThreshold":  7,
                "Identity" : "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

###

test_NonDefBulkThreshold_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "The bulk complaint level (BCL) threshold SHOULD be set to six or lower: non-default policies"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "BulkThreshold":  6,
                "Identity":"Not Default"
            },
            {
 	            "BulkThreshold":  6,
                "Identity":"Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_NonDefBulkThreshold_CorrectV2 if {
    ControlNumber := "Defender 2.6"
    Requirement := "The bulk complaint level (BCL) threshold SHOULD be set to six or lower: non-default policies"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "BulkThreshold":  5,
                "Identity":"Not Default"
            },
            {
 	            "BulkThreshold":  5,
                "Identity":"Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_NonDefBulkThreshold_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "The bulk complaint level (BCL) threshold SHOULD be set to six or lower: non-default policies"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "BulkThreshold":  7,
                "Identity":"Not Default"
            },
            {
 	            "BulkThreshold":  7,
                "Identity":"Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 custom anti-spam policy(ies) found where bulk complaint level threshold is set to 7 or more: Not Default"
}

#
# Policy 2
#--
test_SpamAction_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "Spam SHALL be moved to either the junk email folder or the quarantine folder: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "SpamAction":  "Quarantine",
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SpamAction_CorrectV2 if {
    ControlNumber := "Defender 2.6"
    Requirement := "Spam SHALL be moved to either the junk email folder or the quarantine folder: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "SpamAction":  "MoveToJmf",
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SpamAction_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "Spam SHALL be moved to either the junk email folder or the quarantine folder: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "SpamAction":  "Not MoveToJmf",
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SpamAction_Incorrect_V2 if {
    ControlNumber := "Defender 2.6"
    Requirement := "Spam SHALL be moved to either the junk email folder or the quarantine folder: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "SpamAction":  "Not Quarantine",
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_HighConfSpamAction_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "High confidence spam SHALL be moved to either the junk email folder or the quarantine folder: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "HighConfidenceSpamAction":  "Quarantine",
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_HighConfSpamAction_CorrectV2 if {
    ControlNumber := "Defender 2.6"
    Requirement := "High confidence spam SHALL be moved to either the junk email folder or the quarantine folder: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "HighConfidenceSpamAction":  "MoveToJmf",
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_HighConfSpamAction_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "High confidence spam SHALL be moved to either the junk email folder or the quarantine folder: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "HighConfidenceSpamAction":  "Not MoveToJmf",
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_HighConfSpamAction_Incorrect_V2 if {
    ControlNumber := "Defender 2.6"
    Requirement := "High confidence spam SHALL be moved to either the junk email folder or the quarantine folder: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "HighConfidenceSpamAction":  "Not Quarantine",
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_Non_Def_SpamAction_Correct if {
    ControlNumber := "Defender 2.6" 
    Requirement := "Spam SHOULD be moved to either the junk email folder or the quarantine folder: non-default policies"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "SpamAction":  "Quarantine",
                "Identity": "Not Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Non_Def_SpamAction_CorrectV2 if {
    ControlNumber := "Defender 2.6"
    Requirement := "Spam SHOULD be moved to either the junk email folder or the quarantine folder: non-default policies"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "SpamAction":  "MoveToJmf",
                "Identity": "Not Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Non_Def_SpamAction_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "Spam SHOULD be moved to either the junk email folder or the quarantine folder: non-default policies"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "SpamAction":  "Not MoveToJmf",
                "Identity": "Not Default"
            },
            {
 	            "SpamAction":  "Not MoveToJmf",
                "Identity": "Default"
            }        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 custom anti-spam policy(ies) found where spam is not being sent to the Quarantine folder or the Junk Mail Folder: Not Default"
}

test_Non_Def_SpamAction_Incorrect_V2 if {
    ControlNumber := "Defender 2.6"
    Requirement := "Spam SHOULD be moved to either the junk email folder or the quarantine folder: non-default policies"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "SpamAction": "Not Quarantine",
                "Identity": "Not Default"
            },
            {
 	            "SpamAction": "Not Quarantine",
                "Identity": "Default"
            }        
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 custom anti-spam policy(ies) found where spam is not being sent to the Quarantine folder or the Junk Mail Folder: Not Default"
}

test_Non_Def_HighConfSpamAction_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "High confidence spam SHOULD be moved to either the junk email folder or the quarantine folder: non-default policies"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "HighConfidenceSpamAction":  "Quarantine",
                "Identity": "Not Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Non_Def_HighConfSpamAction_CorrectV2 if {
    ControlNumber := "Defender 2.6"
    Requirement := "High confidence spam SHOULD be moved to either the junk email folder or the quarantine folder: non-default policies"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "HighConfidenceSpamAction":  "MoveToJmf",
                "Identity": "Not Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Non_Def_HighConfSpamAction_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "High confidence spam SHOULD be moved to either the junk email folder or the quarantine folder: non-default policies"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "HighConfidenceSpamAction":  "Not MoveToJmf",
                "Identity": "Not Default"
            },
            {
 	            "HighConfidenceSpamAction":  "Not MoveToJmf",
                "Identity": "Default"
            }        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 custom anti-spam policy(ies) found where high confidence spam is not being sent to the Quarantine folder or the Junk Mail Folder: Not Default"}

test_Non_Def_HighConfSpamAction_Incorrect_V2 if {
    ControlNumber := "Defender 2.6"
    Requirement := "High confidence spam SHOULD be moved to either the junk email folder or the quarantine folder: non-default policies"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "HighConfidenceSpamAction":  "Not Quarantine",
                "Identity": "Not Default"
            },
            {
 	            "HighConfidenceSpamAction":  "Not Quarantine",
                "Identity": "Default"
            }   
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 custom anti-spam policy(ies) found where high confidence spam is not being sent to the Quarantine folder or the Junk Mail Folder: Not Default"}

#
# Policy 3
#--
test_PhishingSpamAction_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "Phishing SHALL be quarantined: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "PhishSpamAction":  "Quarantine",
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_PhishingSpamAction_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "Phishing SHALL be quarantined: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "PhishSpamAction":  "Not Quarantine",
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_HighConfidencePhishAction_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "High confidence phishing SHALL be quarantined: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "HighConfidencePhishAction":  "Quarantine",
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_HighConfidencePhishAction_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "High confidence phishing SHALL be quarantined: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "HighConfidencePhishAction":  "Not Quarantine",
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_Non_Def_PhishingSpamAction_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "Phishing SHOULD be quarantined: non-default policies"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "PhishSpamAction":  "Quarantine",
                "Identity": "Not Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Non_Def_PhishingSpamAction_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "Phishing SHOULD be quarantined: non-default policies"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "PhishSpamAction":  "Not Quarantine",
                "Identity": "Not Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 custom anti-spam policy(ies) found where phishing isn't moved to the quarantine folder: Not Default"
}

test_Non_Def_HighConfidencePhishAction_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "High confidence phishing SHOULD be quarantined: non-default policies"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "HighConfidencePhishAction":  "Quarantine",
                "Identity": "Not Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Non_Def_HighConfidencePhishAction_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "High confidence phishing SHOULD be quarantined: non-default policies"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "HighConfidencePhishAction":  "Not Quarantine",
                "Identity": "Not Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 custom anti-spam policy(ies) found where high-confidence phishing isn't moved to quarantine folder: Not Default"
}

#
# Policy 4
#--
test_BulkSpamAction_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "Bulk email SHOULD be moved to either the junk email folder or the quarantine folder: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "BulkSpamAction":  "Quarantine",
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_BulkSpamAction_CorrectV2 if {
    ControlNumber := "Defender 2.6"
    Requirement := "Bulk email SHOULD be moved to either the junk email folder or the quarantine folder: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "BulkSpamAction":  "MoveToJmf",
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_BulkSpamAction_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "Bulk email SHOULD be moved to either the junk email folder or the quarantine folder: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "BulkSpamAction":  "Not Quarantine",
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_BulkSpamAction_Incorrect_V2 if {
    ControlNumber := "Defender 2.6"
    Requirement := "Bulk email SHOULD be moved to either the junk email folder or the quarantine folder: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "BulkSpamAction":  "Not MoveToJmf",
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

#
# Policy 5
#--
test_QuarantineRetentionPeriod_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "Spam in quarantine SHOULD be retained for at least 30 days: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "QuarantineRetentionPeriod":  30,
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_QuarantineRetentionPeriod_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "Spam in quarantine SHOULD be retained for at least 30 days: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "QuarantineRetentionPeriod":  31,
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_QuarantineRetentionPeriod_Incorrect_V2 if {
    ControlNumber := "Defender 2.6"
    Requirement := "Spam in quarantine SHOULD be retained for at least 30 days: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "QuarantineRetentionPeriod":  29,
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_QuarantineRetentionPeriodCustom_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "Spam in quarantine SHOULD be retained for at least 30 days: non-default policies"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "QuarantineRetentionPeriod":  30,
                "Identity": "Custom 1"
            },
            {
 	            "QuarantineRetentionPeriod":  3,
                "Identity": "Default" # This policy should be ignored
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_QuarantineRetentionPeriodCustom_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "Spam in quarantine SHOULD be retained for at least 30 days: non-default policies"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "QuarantineRetentionPeriod":  30,
                "Identity": "Custom 1"
            },
            {
 	            "QuarantineRetentionPeriod":  29,
                "Identity": "Custom 2"
            },
            {
 	            "QuarantineRetentionPeriod":  3,
                "Identity": "Default" # This policy should be ignored
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 custom anti-spam policy(ies) found where spam in quarantine isn't retained for 30 days: Custom 2"
}

#
# Policy 6
#--
test_InlineSafetyTipsEnabled_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "Spam safety tips SHOULD be turned on: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "InlineSafetyTipsEnabled":  true,
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_InlineSafetyTipsEnabled_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "Spam safety tips SHOULD be turned on: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "InlineSafetyTipsEnabled":  false,
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_InlineSafetyTipsEnabledCustom_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "Spam safety tips SHOULD be turned on: non-default policies"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "InlineSafetyTipsEnabled":  false,
                "Identity": "Default" # should be ignored
            },
            {
 	            "InlineSafetyTipsEnabled":  true,
                "Identity": "Custom 1"
            },
            {
 	            "InlineSafetyTipsEnabled":  true,
                "Identity": "Custom 2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_InlineSafetyTipsEnabledCustom_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "Spam safety tips SHOULD be turned on: non-default policies"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "InlineSafetyTipsEnabled":  false,
                "Identity": "Default" # should be ignored
            },
            {
 	            "InlineSafetyTipsEnabled":  false,
                "Identity": "Custom 1"
            },
            {
 	            "InlineSafetyTipsEnabled":  true,
                "Identity": "Custom 2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 custom anti-spam policy(ies) found where spam safety tips is disabled: Custom 1"
}

#
# Policy 7
#--
test_ZapEnabled_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "Zero-hour auto purge (ZAP) SHALL be enabled: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "ZapEnabled":  true,
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ZapEnabled_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "Zero-hour auto purge (ZAP) SHALL be enabled: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "ZapEnabled":  false,
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SpamZapEnabled_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "Zero-hour auto purge (ZAP) SHALL be enabled for spam messages: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "SpamZapEnabled":  true,
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SpamZapEnabled_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "Zero-hour auto purge (ZAP) SHALL be enabled for spam messages: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "SpamZapEnabled":  false,
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_PhishZapEnabled_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "Zero-hour auto purge (ZAP) SHALL be enabled for phishing: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "PhishZapEnabled":  true,
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_PhishZapEnabled_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "Zero-hour auto purge (ZAP) SHALL be enabled for phishing: default policy"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "PhishZapEnabled":  false,
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_ZapEnabledCustom_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "Zero-hour auto purge (ZAP) SHOULD be enabled: non-default"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "ZapEnabled":  true,
                "Identity": "Not Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ZapEnabledCustom_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "Zero-hour auto purge (ZAP) SHOULD be enabled: non-default"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "ZapEnabled":  false,
                "Identity": "Not Default"
            },
            {
 	            "ZapEnabled":  false,
                "Identity": "Default" # SHOULD be ignored
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 custom anti-spam policies found where Zero-hour auto purge is disabled: Not Default"
}

test_SpamZapEnabled_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "Zero-hour auto purge (ZAP) SHOULD be enabled for Spam: non-default"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "SpamZapEnabled":  true,
                "Identity": "Not Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SpamZapEnabledCustom_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "Zero-hour auto purge (ZAP) SHOULD be enabled for Spam: non-default"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "SpamZapEnabled":  false,
                "Identity": "Not Default"
            },
            {
 	            "SpamZapEnabled":  false, # should be ignored 
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 custom anti-spam policies found where Zero-hour auto purge for spam is disabled: Not Default"
}

test_PhishZapEnabledCustom_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "Zero-hour auto purge (ZAP) SHOULD be enabled for phishing: non-default"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "PhishZapEnabled":  true,
                "Identity": "Not Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_PhishZapEnabledCustom_Incorrect if {
    ControlNumber := "Defender 2.6"
    Requirement := "Zero-hour auto purge (ZAP) SHOULD be enabled for phishing: non-default"

    Output := tests with input as {
        "hosted_content_filter_policies": [
            {
 	            "PhishZapEnabled":  false,
                "Identity": "Not Default"
            },
            {
 	            "PhishZapEnabled":  false, # should be ignored
                "Identity": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 custom anti-spam policy(ies) found where Zero-hour auto purge for phishing is disabled: Not Default"
}

#
# Policy 8
#--
test_NotImplemented_Correct if {
    ControlNumber := "Defender 2.6"
    Requirement := "Allowed senders MAY be added but allowed domains SHALL NOT be added"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Currently cannot be checked automatically. See Defender Secure Configuration Baseline policy 2.8 for instructions on manual check"
}