package defender_test
import future.keywords
import data.defender
import data.report.utils.NotCheckedDetails


#
# Policy 1
#--
test_Disabled_Correct_V1 if {
    PolicyId := "MS.DEFENDER.5.1v1"

    Output := defender.tests with input as {
        "protection_alerts": [
            {
                "Name": "Suspicious email sending patterns detected",
                "Disabled": false
            },
            {
                "Name": "Unusual increase in email reported as phish",
                "Disabled": false
            },
            {
                "Name": "Suspicious Email Forwarding Activity",
                "Disabled": false
            },
            {
                "Name": "Messages have been delayed",
                "Disabled": false
            },
            {
                "Name": "Tenant restricted from sending unprovisioned email",
                "Disabled": false
            },
            {
                "Name": "User restricted from sending email",
                "Disabled": false
            },
            {
                "Name": "Malware campaign detected after delivery",
                "Disabled": false
            },
            {
                "Name": "A potentially malicious URL click was detected",
                "Disabled": false
            },
            {
                "Name": "Suspicious connector activity",
                "Disabled": false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Disabled_Correct_V2 if {
    PolicyId := "MS.DEFENDER.5.1v1"

    Output := defender.tests with input as {
        "protection_alerts": [
            {
                "Name": "Suspicious email sending patterns detected",
                "Disabled": false
            },
            {
                "Name": "Unusual increase in email reported as phish",
                "Disabled": false
            },
            {
                "Name": "Suspicious Email Forwarding Activity",
                "Disabled": false
            },
            {
                "Name": "Messages have been delayed",
                "Disabled": false
            },
            {
                "Name": "Tenant restricted from sending unprovisioned email",
                "Disabled": false
            },
            {
                "Name": "User restricted from sending email",
                "Disabled": false
            },
            {
                "Name": "Malware campaign detected after delivery",
                "Disabled": false
            },
            {
                "Name": "A potentially malicious URL click was detected",
                "Disabled": false
            },
            {
                "Name": "Suspicious connector activity",
                "Disabled": false
            },
            {
                "Name": "Successful exact data match upload",
                "Disabled": false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Disabled_Inorrect_V1 if {
    PolicyId := "MS.DEFENDER.5.1v1"

    Output := defender.tests with input as {
        "protection_alerts": [
            {
                "Name": "Suspicious email sending patterns detected",
                "Disabled": true
            },
            {
                "Name": "Unusual increase in email reported as phish",
                "Disabled": false
            },
            {
                "Name": "Suspicious Email Forwarding Activity",
                "Disabled": false
            },
            {
                "Name": "Messages have been delayed",
                "Disabled": false
            },
            {
                "Name": "Tenant restricted from sending unprovisioned email",
                "Disabled": false
            },
            {
                "Name": "User restricted from sending email",
                "Disabled": false
            },
            {
                "Name": "Malware campaign detected after delivery",
                "Disabled": false
            },
            {
                "Name": "A potentially malicious URL click was detected",
                "Disabled": false
            },
            {
                "Name": "Suspicious connector activity",
                "Disabled": false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 disabled required alert(s) found: Suspicious email sending patterns detected"
}

test_Disabled_Inorrect_V2 if {
    PolicyId := "MS.DEFENDER.5.1v1"

    Output := defender.tests with input as {
        "protection_alerts": [
            {
                "Name": "Unusual increase in email reported as phish",
                "Disabled": false
            },
            {
                "Name": "Suspicious Email Forwarding Activity",
                "Disabled": false
            },
            {
                "Name": "Messages have been delayed",
                "Disabled": false
            },
            {
                "Name": "Tenant restricted from sending unprovisioned email",
                "Disabled": false
            },
            {
                "Name": "User restricted from sending email",
                "Disabled": false
            },
            {
                "Name": "Malware campaign detected after delivery",
                "Disabled": false
            },
            {
                "Name": "A potentially malicious URL click was detected",
                "Disabled": false
            },
            {
                "Name": "Suspicious connector activity",
                "Disabled": false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 disabled required alert(s) found: Suspicious email sending patterns detected"
}
#--

#
# Policy 2
#--
test_NotImplemented_Correct_V2 if {
    PolicyId := "MS.DEFENDER.5.2v1"

    Output := defender.tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}
#--