package defender
import future.keywords

# TODO: Policy Id(s) needs to be resolved

#
# Policy 1
#--
# test_EnableFileFilter_Correct if {
#     ControlNumber := "Defender 2.3"
#     Requirement := "The common attachments filter SHALL be enabled in the default anti-malware policy and in all existing policies"

#     Output := tests with input as {
#         "malware_filter_policies": [
#             {
#                 "EnableFileFilter" : true,
#                 "Name": "Default"
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement met"
# }

# test_EnableFileFilter_Incorrect if {
#     ControlNumber := "Defender 2.3"
#     Requirement := "The common attachments filter SHALL be enabled in the default anti-malware policy and in all existing policies"

#     Output := tests with input as {
#         "malware_filter_policies": [
#             {
#                 "EnableFileFilter" : false,
#                 "Name": "Default"
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "1 malware policy(ies) found that do(es) not have the common attachments filter enabled: Default"
# }

# test_EnableFileFilterMultiple_Incorrect if {
#     ControlNumber := "Defender 2.3"
#     Requirement := "The common attachments filter SHALL be enabled in the default anti-malware policy and in all existing policies"

#     Output := tests with input as {
#         "malware_filter_policies": [
#             {
#                 "EnableFileFilter" : true,
#                 "Name": "Default"
#             },
#             {
#                 "EnableFileFilter" : false,
#                 "Name": "Custom 1"
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "1 malware policy(ies) found that do(es) not have the common attachments filter enabled: Custom 1"
# }

#
# Policy 2
#--
# test_FileTypes_Correct_V1 if {
#     ControlNumber := "Defender 2.3"
#     Requirement := "Disallowed file types SHALL be determined and set. At a minimum, click-to-run files SHOULD be blocked: exe files"

#     Output := tests with input as {
#         "malware_filter_policies": [
#             {
#                 "FileTypes" : ["exe"],
#                 "EnableFileFilter" : true,
#                 "Name": "Default"
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
#     count(RuleOutput) == 1
#     RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement met"
# }

# test_FileTypes_Incorrect_V1 if {
#     ControlNumber := "Defender 2.3"
#     Requirement := "Disallowed file types SHALL be determined and set. At a minimum, click-to-run files SHOULD be blocked: exe files"

#     Output := tests with input as {
#         "malware_filter_policies": [
#             {
#                 "FileTypes" : ["cmd", "vbe"],
#                 "EnableFileFilter" : true,
#                 "Name": "Default"
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "No malware policies found that block .exe files."
# }

# test_FileTypes_Correct_V2 if {
#     ControlNumber := "Defender 2.3"
#     Requirement := "Disallowed file types SHALL be determined and set. At a minimum, click-to-run files SHOULD be blocked: cmd files"

#     Output := tests with input as {
#         "malware_filter_policies": [
#             {
#                 "FileTypes" : ["cmd"],
#                 "EnableFileFilter" : true,
#                 "Name": "Default"
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement met"
# }

# test_FileTypes_Incorrect_V2 if {
#     ControlNumber := "Defender 2.3"
#     Requirement := "Disallowed file types SHALL be determined and set. At a minimum, click-to-run files SHOULD be blocked: cmd files"

#     Output := tests with input as {
#         "malware_filter_policies": [
#             {
#                 "FileTypes" : ["exe", "vbe"],
#                 "EnableFileFilter" : true,
#                 "Name": "Default"
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "No malware policies found that block .cmd files."
# }

# test_FileTypes_Correct_V3 if {
#     ControlNumber := "Defender 2.3"
#     Requirement := "Disallowed file types SHALL be determined and set. At a minimum, click-to-run files SHOULD be blocked: vbe files"

#     Output := tests with input as {
#         "malware_filter_policies": [
#             {
#                 "FileTypes" : ["vbe"],
#                 "EnableFileFilter" : true,
#                 "Name": "Default"
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement met"
# }

# test_FileTypes_Incorrect_V3 if {
#     ControlNumber := "Defender 2.3"
#     Requirement := "Disallowed file types SHALL be determined and set. At a minimum, click-to-run files SHOULD be blocked: vbe files"

#     Output := tests with input as {
#         "malware_filter_policies": [
#             {
#                 "FileTypes" : ["exe", "cmd"],
#                 "EnableFileFilter" : true,
#                 "Name": "Default"
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "No malware policies found that block .vbe files."
# }