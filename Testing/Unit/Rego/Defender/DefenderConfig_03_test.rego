package defender
import future.keywords

#
# Policy 1
#--
# test_Spot_Correct if {
#     ControlNumber := "Defender 2.8"
#     Requirement := "Safe attachments SHOULD be enabled for SharePoint, OneDrive, and Microsoft Teams"

#     Output := tests with input as {
#         "atp_policy_for_o365" : [
#             {
#                 "EnableATPForSPOTeamsODB" : true,
#                 "Identity" : "Default"
#             }
#         ],
#         "defender_license" : true
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement met"
# }

# test_Spot_Incorrect if {
#     ControlNumber := "Defender 2.8"
#     Requirement := "Safe attachments SHOULD be enabled for SharePoint, OneDrive, and Microsoft Teams"

#     Output := tests with input as {
#         "atp_policy_for_o365" : [
#             {
#                 "EnableATPForSPOTeamsODB" : false,
#                 "Identity" : "Default"
#             }
#         ],
#         "defender_license" : true
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement not met"
# }
