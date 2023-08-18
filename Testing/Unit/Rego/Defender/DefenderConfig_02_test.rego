package defender
import future.keywords

# TODO: Policy Id(s) needs to be resolved

#
# Policy 1
#--
# test_TargetedUsers_Correct if {
#     ControlNumber := "Defender 2.5"
#     Requirement := "User impersonation protection SHOULD be enabled for key agency leaders"

#     Output := tests with input as {
#         "anti_phish_policies": [
#             {
#                 "Name" : "Standard Preset Security Policy1659535429826",
#                 "Enabled" : true,
#                 "EnableTargetedUserProtection" : true,
#                 "TargetedUsersToProtect" : [
#                     "john doe;jdoe@someemail.com",
#                     "jane doe;jadoe@someemail.com"
#                 ],
#                 "TargetedUserProtectionAction": "Quarantine"
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement met"
# }

# test_Enabled_Incorrect if {
#     ControlNumber := "Defender 2.5"
#     Requirement := "User impersonation protection SHOULD be enabled for key agency leaders"

#     Output := tests with input as {
#         "anti_phish_policies" : [
#             {
#                 "Name" : "Standard Preset Security Policy1659535429826",
#                 "Enabled" : false,
#                 "EnableTargetedUserProtection" : true,
#                 "TargetedUsersToProtect" : [
#                     "john doe;jdoe@someemail.com",
#                     "jane doe;jadoe@someemail.com"
#                 ],
#                 "TargetedUserProtectionAction" : "Quarantine"
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "No users are included for targeted user protection."
# }

# test_EnableTargetedUserProtection_Incorrect if {
#     ControlNumber := "Defender 2.5"
#     Requirement := "User impersonation protection SHOULD be enabled for key agency leaders"

#     Output := tests with input as {
#         "anti_phish_policies" : [
#             {
#                 "Name" : "Standard Preset Security Policy1659535429826",
#                 "Enabled" : true,
#                 "EnableTargetedUserProtection" : false,
#                 "TargetedUsersToProtect" : [
#                     "john doe;jdoe@someemail.com",
#                     "jane doe;jadoe@someemail.com"
#                 ],
#                 "TargetedUserProtectionAction" : "Quarantine"
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "No users are included for targeted user protection."
# }

# test_TargetedUsersToProtect_Incorrect if {
#     ControlNumber := "Defender 2.5"
#     Requirement := "User impersonation protection SHOULD be enabled for key agency leaders"

#     Output := tests with input as {
#         "anti_phish_policies" : [
#             {
# 	            "Name" : "Standard Preset Security Policy1659535429826",
#                 "Enabled" : true,
#                 "EnableTargetedUserProtection" : true,
#                 "TargetedUsersToProtect" : [ ],
#                 "TargetedUserProtectionAction" : "Quarantine"
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "No users are included for targeted user protection."
# }

#
# Policy 2
#--
# test_OrganizationDomain_Correct if {
#     ControlNumber := "Defender 2.5"
#     Requirement := "Domain impersonation protection SHOULD be enabled for domains owned by the agency"

#     Output := tests with input as {
#         "anti_phish_policies" : [
#             {
# 	            "Name" : "Standard Preset Security Policy1659535429826",
#                 "Enabled" : true,
#                 "EnableOrganizationDomainsProtection" : true,
# 	            "EnableTargetedDomainsProtection" : true,
#                 "TargetedDomainProtectionAction" : "Quarantine",
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement met"
# }

# test_Enabled_Incorrect_V2 if {
#     ControlNumber := "Defender 2.5"
#     Requirement := "Domain impersonation protection SHOULD be enabled for domains owned by the agency"

#     Output := tests with input as {
#        "anti_phish_policies" : [
#             {
# 	            "Name" : "Standard Preset Security Policy1659535429826",
#                 "Enabled" : false,
#                 "EnableOrganizationDomainsProtection" : true,
# 	            "EnableTargetedDomainsProtection" : true,
#                 "TargetedDomainProtectionAction" : "Quarantine",
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement not met"
# }

# test_EnableOrganizationDomainsProtection_Incorrect if {
#     ControlNumber := "Defender 2.5"
#     Requirement := "Domain impersonation protection SHOULD be enabled for domains owned by the agency"

#     Output := tests with input as {
#        "anti_phish_policies" : [
#             {
# 	            "Name" : "Standard Preset Security Policy1659535429826",
#                 "Enabled" : true,
#                 "EnableOrganizationDomainsProtection" : false,
# 	            "EnableTargetedDomainsProtection" : true,
#                 "TargetedDomainProtectionAction" : "Quarantine",
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement not met"
# }

# test_EnableTargetedDomainsProtection_Incorrect if {
#     ControlNumber := "Defender 2.5"
#     Requirement := "Domain impersonation protection SHOULD be enabled for domains owned by the agency"

#     Output := tests with input as {
#        "anti_phish_policies" : [
#             {
# 	            "Name" : "Standard Preset Security Policy1659535429826",
#                 "Enabled" : true,
#                 "EnableOrganizationDomainsProtection" : true,
# 	            "EnableTargetedDomainsProtection" : false,
#                 "TargetedDomainProtectionAction" : "Quarantine",
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement not met"
# }

#
# Policy 3
#--
# test_CustomDomains_Correct if {
#     ControlNumber := "Defender 2.5"
#     Requirement := "Domain impersonation protection SHOULD be added for frequent partners"

#     Output := tests with input as {
#         "anti_phish_policies" : [
#             {
# 	            "Name" : "Standard Preset Security Policy1659535429826",
#                 "Enabled" : true,
#                 "EnableTargetedDomainsProtection" : true,
#                 "TargetedDomainsToProtect" : [ "test domain" ],
# 	            "TargetedDomainProtectionAction" : "Quarantine"
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement met"
# }

# test_Enabled_Incorrect_V3 if {
#     ControlNumber := "Defender 2.5"
#     Requirement := "Domain impersonation protection SHOULD be added for frequent partners"

#     Output := tests with input as {
#         "anti_phish_policies" : [
#             {
# 	            "Name" : "Standard Preset Security Policy1659535429826",
#                 "Enabled" : false,
#                 "EnableTargetedDomainsProtection" : true,
#                 "TargetedDomainsToProtect" : [ "test domain" ],
# 	            "TargetedDomainProtectionAction" : "Quarantine"
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "The Custom Domains protection policies: Enabled, EnableTargetedDomainsProtection, and TargetedDomainsToProtect are not set correctly"
# }

# test_EnableTargetedDomainsProtection_Incorrect if {
#     ControlNumber := "Defender 2.5"
#     Requirement := "Domain impersonation protection SHOULD be added for frequent partners"

#     Output := tests with input as {
#         "anti_phish_policies" : [
#             {
# 	            "Name" : "Standard Preset Security Policy1659535429826",
#                 "Enabled" : true,
#                 "EnableTargetedDomainsProtection" : false,
#                 "TargetedDomainsToProtect" : [ "test domain" ],
# 	            "TargetedDomainProtectionAction" : "Quarantine"
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "The Custom Domains protection policies: Enabled, EnableTargetedDomainsProtection, and TargetedDomainsToProtect are not set correctly"
# }

# test_TargetedDomainsToProtect_Incorrect if {
#     ControlNumber := "Defender 2.5"
#     Requirement := "Domain impersonation protection SHOULD be added for frequent partners"

#     Output := tests with input as {
#         "anti_phish_policies" : [
#             {
# 	            "Name" : "Standard Preset Security Policy1659535429826",
#                 "Enabled" : true,
#                 "EnableTargetedDomainsProtection" : true,
#                 "TargetedDomainsToProtect" : [ ],
# 	            "TargetedDomainProtectionAction" : "Quarantine"
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "The Custom Domains protection policies: Enabled, EnableTargetedDomainsProtection, and TargetedDomainsToProtect are not set correctly"
# }