package defender
import future.keywords

# TODO: Policy Id(s) needs to be resolved
#
# Policy 1
#--
# test_Disabled_Correct if {
#     ControlNumber := "Defender 2.9"
#     Requirement := "At a minimum, the alerts required by the Exchange Online Minimum Viable Secure Configuration Baseline SHALL be enabled"

#     Output := tests with input as {
#         "protection_alerts": [
#             {
#                 "Name": "Suspicious email sending patterns detected",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Unusual increase in email reported as phish",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Suspicious Email Forwarding Activity",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Messages have been delayed",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Tenant restricted from sending unprovisioned email",
#                 "Disabled": false
#             },
#             {
#                 "Name": "User restricted from sending email",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Malware campaign detected after delivery",
#                 "Disabled": false
#             },
#             {
#                 "Name": "A potentially malicious URL click was detected",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Suspicious connector activity",
#                 "Disabled": false
#             },
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement met"
# }

# test_Disabled_Correct_V2 if {
#     # Test having extra alerts enabled that aren't required by the baseline
#     # SHOULDn't matter
#     ControlNumber := "Defender 2.9"
#     Requirement := "At a minimum, the alerts required by the Exchange Online Minimum Viable Secure Configuration Baseline SHALL be enabled"

#     Output := tests with input as {
#         "protection_alerts": [
#             {
#                 "Name": "Suspicious email sending patterns detected",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Unusual increase in email reported as phish",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Suspicious Email Forwarding Activity",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Messages have been delayed",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Tenant restricted from sending unprovisioned email",
#                 "Disabled": false
#             },
#             {
#                 "Name": "User restricted from sending email",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Malware campaign detected after delivery",
#                 "Disabled": false
#             },
#             {
#                 "Name": "A potentially malicious URL click was detected",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Suspicious connector activity",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Successful exact data match upload", # Not required
#                 "Disabled": false 
#             },
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement met"
# }

# test_Disabled_Incorrect if {
#     ControlNumber := "Defender 2.9"
#     Requirement := "At a minimum, the alerts required by the Exchange Online Minimum Viable Secure Configuration Baseline SHALL be enabled"

#     Output := tests with input as {
#         "protection_alerts": [
#             {
#                 "Name": "Suspicious email sending patterns detected",
#                 "Disabled": true # SHOULD be false
#             },
#             {
#                 "Name": "Unusual increase in email reported as phish",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Suspicious Email Forwarding Activity",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Messages have been delayed",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Tenant restricted from sending unprovisioned email",
#                 "Disabled": false
#             },
#             {
#                 "Name": "User restricted from sending email",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Malware campaign detected after delivery",
#                 "Disabled": false
#             },
#             {
#                 "Name": "A potentially malicious URL click was detected",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Suspicious connector activity",
#                 "Disabled": false
#             },
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "1 disabled required alert(s) found: Suspicious email sending patterns detected"
# }

# test_Disabled_Incorrect_V2 if {
#     # What happens if the alert is entirely missing instead of just disabled?
#     ControlNumber := "Defender 2.9"
#     Requirement := "At a minimum, the alerts required by the Exchange Online Minimum Viable Secure Configuration Baseline SHALL be enabled"

#     Output := tests with input as {
#         "protection_alerts": [
#             {
#                 "Name": "Unusual increase in email reported as phish",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Suspicious Email Forwarding Activity",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Messages have been delayed",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Tenant restricted from sending unprovisioned email",
#                 "Disabled": false
#             },
#             {
#                 "Name": "User restricted from sending email",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Malware campaign detected after delivery",
#                 "Disabled": false
#             },
#             {
#                 "Name": "A potentially malicious URL click was detected",
#                 "Disabled": false
#             },
#             {
#                 "Name": "Suspicious connector activity",
#                 "Disabled": false
#             },
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "1 disabled required alert(s) found: Suspicious email sending patterns detected"
# }

#
# Policy 2
#--
# test_NotImplemented_Correct if {
#     ControlNumber := "Defender 2.9"
#     PolicyId := "MS.DEFENDER.TBD"
#     Requirement := "The alerts SHOULD be sent to a monitored address or incorporated into a SIEM"

#     Output := tests with input as { }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
# }