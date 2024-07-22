# This package name is imported for unit tests
package sharepoint
# This import is default for all rego files to use keywords like if & in
import rego.v1
# These imports are the functions in the Utils/ReportDetails.rego
import data.utils.report.NotCheckedDetails
import data.utils.report.CheckedSkippedDetails
import data.utils.report.ReportDetailsBoolean
import data.utils.report.ReportDetailsBooleanWarning
import data.utils.report.ReportDetailsString
# These imports are the functions in the Utils/KeyFunctions.rego
import data.utils.key.FilterArray
import data.utils.key.FAIL
import data.utils.key.PASS
# We import each funtion individually for 2 reasons:
# 1) if we imported the file we would have to call the function as `utils.key.FAIL` instead of `FAIL`
# 2) it is considered bad practice in Rego to import functions that are not used, there is a linter warning for this.


#############
# Constants #
#############
# Not every product has constants. We only do this for values that are used repeatedly and may not be self descriptive.
# The admin center for sharepoint/onedrive has a slider for sharing settings. Each position on the slider has a correspoinding numerical value.
# There is notation in the comments below of there related values for functional test. This can be ignored for now as the training ground does not
# address functional tests at this time.
ONLYPEOPLEINORG := 0        # "Disabled" in functional tests
EXISTINGGUESTS := 3         # "ExistingExternalUserSharingOnly" in functional tests
NEWANDEXISTINGGUESTS := 1   # "ExternalUserSharingOnly" in functional tests
ANYONE := 2                 # "ExternalUserAndGuestSharing" in functional tests

######################################
# External sharing support functions #
######################################

# This is a type of function in Rego. In this case the exact value is in the parameter position of the function. So if the value passed to this
# function is `0`, the funtion will return "Only People In Your Organization". This is useful if you are guarranteed to be passed certain values.
# This works because duplicate names are treated similar to an if else train.
SliderSettings(0) := "Only People In Your Organization"

SliderSettings(1) := "New and Existing Guests"

SliderSettings(2) := "Anyone"

SliderSettings(3) := "Existing Guests"

# You must always have a default funtion, otherwise if the value passed is not one of the explicitaly stated value above, it will return undefined.
# Undefined is not great because it allows for false positive or negatives. There are times when an undefined is intended, but you should code so it
# dosn't appear when unintended. Functions and Rule Sets can return multiple results, in this case we are returning a scalar value (string).
# So if multiple values are returned, Rego will stop with an error. To prevent that we check if the value passed is one of the expected values [0,1,2,3]
# by using a array item check. Only then will the string "Unknown" be returned.
SliderSettings(Value) := "Unknown" if not Value in [0, 1, 2, 3]

# This is unique to SharePoint. The PowerShell script that pull from the tenant force the results into an array. Becuase we know that there should be only
# one item in the array on a normal run, we save that item in a variable called Tenant. This prevents the need to loop through the SPO_tenant array for
# each policy. This is a techique used to reduce extranious/duplicate code.
Tenant := input.SPO_tenant[0] if {
    count(input.SPO_tenant) == 1
}

# This value is used so much, someone decided to just store it in a variable. This is more of a nuetral code line/ personal choice.
SharingCapability := Tenant.SharingCapability

# This string is used in multiple policies as part of the report details. Becuase the string is dependent on the sharing capability set in
# the json concat is utilized instead of hard coding. The function concat takes a deliminater for between the strings and an array of stings to
# be concatanated. Because variables in Rego are imutable, you must save the function output to a new variable. In this case the deliminater is an
# empty string because we wanted to add a period. An example of the string save in `SharingString` is "External Sharing is set to Anyone."
SharingString := concat("", [
    "External Sharing is set to ",
    SliderSettings(SharingCapability),
    "."
])

# This is a report details string you will see often. We have some policies that are Not Applicable because the settings cannot be pulled from the
# tenant currently or the check is too complex to do cleanly & reliably. Similar to the function above concat is used to create a string that reflects
# the current sharing setting set in the tenant with an addition. The %v is a formatter, so when this string is fed to another function the %v will be
# replaced with a html link for the report generated.
NAString(SharingSetting) := concat("", [
        "This policy is only applicable if External Sharing is set to any value other than ",
        SharingSetting,
        ". ",
        "See %v for more info"
    ])


# IMPORTANT comment structure, read the CONTENTSTYLEGUIDE.md!
###################
# MS.SHAREPOINT.1 #
###################

#
# MS.SHAREPOINT.1.1v1
#--

# Sharepoint Rego Example
#
# Policy logic: If SharingCapability is set to Only People In Organization OR Existing Guests, the policy should pass.
#
# Code logic: Each policy in SCuBA is tested in a tests rule set. Rule sets are CASE SENSITIVE. It must be tests, not: Tests, test, etc.
# the contains keyword allows multiple values to be returned (not to be confused with the contains() function). Each tests rule set (policy)
# returns: policy id, criticality, commandlet, actual value, report details, and requirement met. The policy id, criticality can be found in
# the baseline. The commandlet is the Powershell command used to pull the tenant settings needed to test compliance with this policy.
# The last 3: actual value, report details, and requirement met are determined by the rego code. Actual vaule is the setting information the
# user would need to fix the tenant if the policy check fails. The report details is a descriptive string to better explain the policy pass/fail.
# The requrement met is a boolean, true == pass, false == fail. Continuing logic explination in rule set.
tests contains {
    "PolicyId": "MS.SHAREPOINT.1.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [SharingCapability],
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    # The policy is an OR comparison. If SharingCapability is set to ONLYPEOPLEINORG OR EXISTINGGUESTS. In rego there are a few ways to do this.
    # Because the check is so simple we chose to use a comprehension. Comprehensions are shorthand rule sets. For example:
    #
    # Rule Set
    # default ExampleRuleSet := false
    # ExampleRuleSet := true if {
    #   SharingCapability == ONLYPEOPLEINORG
    #}
    # ExampleRuleSet := true if {
    #   SharingCapability == EXISTINGGUESTS
    #}
    #
    # Comprehension
    # Result := [Condition | some Condition in [SharingCapability == ONLYPEOPLEINORG, SharingCapability == EXISTINGGUESTS]; Condition == true]
    #
    # The rule set returns true if either case is true, otherwise false. The comprehension is split into three parts. Result is the variable the
    # the result of the comprehension is saved in like ExampleRuleSet is for the rule set. Condition on the left side of the pipe is the value that
    # will be saved in result if the condition passes. The right side of the array to the ; is the loop. It is a some in loop use to declare a mutable
    # temporary variable for the loop. In this case we are looping through an array of booleans created by comparing the SharingCapability value to
    # constants. Everything after the FIRST ; is a condition, you can have multiple conditions in a comprehension. In the comprehension, it is incased
    # by [] making the return value an array, you can also return a set by using {}. All together this returns an array of true values for each true value
    # in the array we are looping through.
    #
    # Because this tpe of comprehension is used often, we have a key function named FilterArray.
    Conditions := [
        SharingCapability == ONLYPEOPLEINORG,
        SharingCapability == EXISTINGGUESTS
    ]
    # We pass it an array of booleans ( our OR comparisons) and we are checking if any are true, so the boolean value passed is true. FilterArray returns
    # an array, so we use count() (NOT Count) to get the size. In this instance we can only get 2 sizes, 0 or 1. For the policy to pass we need a size
    # of 1. We store the result of that comparison in status so we can pass the result to report details & requirement met.
    Status := count(FilterArray(Conditions, true)) == 1
}
#--

#
# MS.SHAREPOINT.1.2v1
#--

# Sharepoint Rego Challenge
#
# Policy logic: If OneDriveSharingCapability is set to Only People In Organization OR Existing Guests, the policy should pass.
#
# Level 1: Easy
#
# Code Note: you should notice there are two tests rule sets for this policy. This policy has a case where the test is Not Applicable. I have left
# in the logic for the Not Applicable portion. The challange for this policy is to code the oplicy logic above, look for the TODOs & use the previous
# example as a guide.
tests contains {
    "PolicyId": "MS.SHAREPOINT.1.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [TODO],
    "ReportDetails": TODO,
    "RequirementMet": Status
} if {
    # If there is a secondary check for a policy for any reason, not only an N/A check, you MUST add a filter condition. We only want this check
    # runing if the `OneDrive_PnP_Flag` is not set (i.e., false). If this is not present this file might return 2 policy results for this policy.
    input.OneDrive_PnP_Flag == false
    TODO
}

# This is a Not Applicable policy, in this case if the `OneDrive_PnP_Flag` is set (i.e., true), the policy cannot be checked. As a result
# `/Not-Implemented` should be added to the criticality for the html report coloring. The actual value should be []. The report
# details should be passed the result of our NotCheckedDetails(). Lastly requirement met MUST be false.
tests contains {
    "PolicyId": PolicyId,
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails(PolicyId),
    "RequirementMet": false
} if {
    PolicyId := "MS.SHAREPOINT.1.2v1"
    input.OneDrive_PnP_Flag == true
}
#--

#
# MS.SHAREPOINT.1.3v1
#--

# At this time we are unable to test for approved security groups because we have yet to find the setting to check.
# So we must warn our users that this policy check does not check everything. This note must be present in the report details. Because the
# note is so long, we use the concat() to get around the line length limit (unlike python there is no current known method to have a string
# span multiple lines or block comment).
NoteArray := [
    "Note that we currently only check for approved external domains.",
    "Approved security groups are currently not being checked,",
    "see the baseline policy for instructions on a manual check."
]
NOTESTRING := concat(" ", NoteArray)

# Sharepoint Rego Challenge
#
# Policy logic: If Sharing Domain Restriction Mode is enabled AND SharingCapability != Only People In Your Organization, the policy should pass.
# SharingDomainRestrictionMode == 0 Unchecked
# SharingDomainRestrictionMode == 1 Checked
#
# Level 1: Easy
#
# Code Note: Try previous challenge first
#
tests contains {
    "PolicyId": "MS.SHAREPOINT.1.3v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [TODO],
    "ReportDetails": ReportDetailsBooleanWarning(Status, NOTESTRING),
    "RequirementMet": Status
} if {
    TODO
}

tests contains {
    "PolicyId": PolicyId,
    "Criticality": "Shall"TODO,
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [],
    "ReportDetails": CheckedSkippedDetails(PolicyId, Reason),
    "RequirementMet": false
} if {
    TODO
}
#--

#
# MS.SHAREPOINT.1.4v1
#--

# Sharepoint Rego Challenge
#
# Policy logic: If SharingCapability is not set to Only People In Organization and require account login to be the one on the invite enabled,
# the policy should pass.
#
# Level 1: Easy
#
# Code Note: Try previous challenge first. Don't get scared of the increase of TODOs, nothing new, same info goes in as the previous with slight
# variation. Look at the json value `RequireAcceptingAccountMatchInvitedAccount`.
#
tests contains {
    "PolicyId": "MS.SHAREPOINT.1.4v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [TODO],
    "ReportDetails": TODO,
    "RequirementMet": TODO
} if {
    TODO
}

tests contains {
    "PolicyId": PolicyId,
    "Criticality": "Shall"TODO,
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": TODO,
    "ReportDetails": TODO,
    "RequirementMet": TODO
} if {
    TODO
}
#--

###################
# MS.SHAREPOINT.2 #
###################

#
# MS.SHAREPOINT.2.1v1
#--

# Sharepoint Rego Challenge
#
# Policy logic: If default sharing link type is for specific people, the policy should pass.
# DefaultSharingLinkType == 1 for Specific People
# DefaultSharingLinkType == 2 for Only people in your organization
#
# Level 1: Easy
#
# Code Note: Review the example. This is the most basic case you will come across in SCuBA.
#
tests contains {
    "PolicyId": "MS.SHAREPOINT.2.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [TODO],
    "ReportDetails": TODO,
    "RequirementMet": Status
} if {
    Status := TODO
}
#--

#
# MS.SHAREPOINT.2.2v1
#--

# Sharepoint Rego Challenge
#
# Policy logic: If Default link permission is set to view, the policy should pass.
# DefaultLinkPermission == 1 view
# DefaultLinkPermission == 2 edit
#
# Level 1: Easy
#
# Code Note: Review the example. This is the most basic case you will come across in SCuBA.
#
tests contains {
    "PolicyId": "MS.SHAREPOINT.2.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": TODO,
    "ReportDetails": TODO,
    "RequirementMet": TODO
} if {
    TODO
}
#--

###################
# MS.SHAREPOINT.3 #
###################

#
# MS.SHAREPOINT.3.1v1
#--

# Sharepoint Rego Challenge
#
# Policy logic: If external sharing is set to "Anyone" and Anonymous Links Expire in 30 or less days, the policy should pass.
#
# Level 1: Easy
#
# Code Note: Try MS.SHAREPOINT.1.2v1 first. Look at json key `RequireAnonymousLinksExpireInDays`
#
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant"],
    "ActualValue": [TODO],
    "ReportDetails": TODO,
    "RequirementMet": TODO
} if {
    TODO
}

tests contains {
    "PolicyId": PolicyId,
    "Criticality": "Shall"TODO,
    "Commandlet": ["Get-SPOTenant"],
    "ActualValue": TODO,
    "ReportDetails": TODO,
    "RequirementMet": TODO
} if {
    TODO
}
#--


#
# MS.SHAREPOINT.3.2v1
#--

# This policy is only applicable if
# Both link types must be 1 & OneDrive_PnP_Flag must be false for policy to pass
# Sharepoint Rego Challenge
#
# Policy logic: If external sharing is set to "Anyone", OneDrive_PnP_Flag is not set, and File And Folder Link Permission is set to view,
# the policy should pass.
# FileLinkType == 1 view
# FolderLinkType == 1 view
#
# Level 1: Easy
#
# Code Note: Try MS.SHAREPOINT.1.3v1 first. Try making a rule set or function that gives the user more information on what to fix in report details.
# Remember in this case you have 2 N/A cases.
#
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [TODO],
    "ReportDetails": TODO,
    "RequirementMet": TODO
} if {
    TODO
}

# Test for N/A case
tests contains {
    "PolicyId": PolicyId,
    "Criticality": "Shall"TODO,
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": TODO,
    "ReportDetails": TODO,
    "RequirementMet": tODO
} if {
    TODO
}

tests contains {
    "PolicyId": PolicyId,
    "Criticality": "Shall"TODO,
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": TODO,
    "ReportDetails": TODO,
    "RequirementMet": TODO
} if {
    TODO
}
#--

#
# MS.SHAREPOINT.3.3v1
#--

# Sharepoint Rego Challenge
#
# Policy logic: This policy is only applicable if external sharing is set to "Anyone", or "New and existing guests". If verification code
# reauthentication is enabled, and if the verification time is valid (less than or equal to 30 days), the policy should pass.
#
# Level 1: Easy
#
# Code Note: Try previous challenge first. Look at json keys `EmailAttestationRequired` and `EmailAttestationReAuthDays`. Try making a seperate
# rule set for getting result of verification pass. Keep in mind you need to tell the user in report details what exactly failed if anything.
#
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.3v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [TODO],
    "ReportDetails": TODO,
    "RequirementMet": TODO
} if {
    TODO
}

# Test for N/A case
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.3v1",
    "Criticality": "Shall"TODO,
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": TODO,
    "ReportDetails": TODO,
    "RequirementMet": TODO
} if {
    TODO
}
#--

###################
# MS.SHAREPOINT.4 #
###################

#
# MS.SHAREPOINT.4.1v1
#--

# Sharepoint Rego Challenge
#
# Policy logic: # At this time we are unable to test for running custom scripts on personal sites because we have yet to find the setting to check
#
# Level 1: Easy
#
# Code Note: Try MS.SHAREPOINT.1.2v1 first
#
tests contains {
    "PolicyId": "MS.SHAREPOINT.4.1v1",
    "Criticality": "Shall"TODO,
    "Commandlet": [],
    "ActualValue": TODO,
    "ReportDetails": TODO,
    "RequirementMet": TODO
}
#--

#
# MS.SHAREPOINT.4.2v1
#--

# Sharepoint Rego Challenge
#
# Policy logic: If users are preventedfrom running custom script on self-service created sites, the policy should pass.
#
# Level 1: Easy
#
# Code Note: Try MS.SHAREPOINT.1.2v1 first. This uses a different input key `SPO_site`. I left in the some in loop, in the case like `SPO_tenant`
# there is only one item, but this key is only used once. So we did not create a additonal variable to hold the item & opted for a loop instead.
# Look at json key `DenyAddAndCustomizePages`.
# 1 == Allow users to run custom script on self-service created sites
# 2 == Prevent users from running custom script on self-service created sites
#
tests contains {
    "PolicyId": "MS.SHAREPOINT.4.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOSite", "Get-PnPTenantSite"],
    "ActualValue": [TODO],
    "ReportDetails": TODO,
    "RequirementMet": TODO
} if {
    some SitePolicy in input.SPO_site
    Status := TODO
}
#--