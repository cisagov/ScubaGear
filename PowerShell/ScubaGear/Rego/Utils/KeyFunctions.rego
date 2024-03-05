package utils.key
import rego.v1
import data.utils.report.ReportDetailsBoolean


#############
# Constants #
#############

# Used so often, converted to a constant
FAIL := ReportDetailsBoolean(false)

PASS := ReportDetailsBoolean(true)


####################
# Helper Functions #
####################

# Checks if set/array is null or empty
IsEmptyContainer(null) := true

IsEmptyContainer(container) := true if {
    count({Item | some Item in container}) == 0
} else := false

# Check if string is in array
Contains(null, _) := false

Contains(array, item) := true if {
    item in array
} else := false

# Returns size of set/array
Count(null) := 0

Count(Container) := count(Container)

# Returns all conditions that match passed value (true/false)
# Commonly used for OR/Any conditions
FilterArray(Conditions, Boolean) := [Condition | some Condition in Conditions; Condition == Boolean]

# Return set of values pulled from array
ConvertToSet(Items) := NewSet if {
    NewSet := {Item | some Item in Items}
} else := set()

# Return set of values pulled from array with additional key
ConvertToSetWithKey(Items, Key) := NewSet if {
    NewSet := {Item[Key] | some Item in Items}
} else := set()


###########
# Testing #
###########

# Basic test that has anticipated string for Report Details
TestResult(PolicyId, Output, ReportDetailString, RequirementMet) := true if {
    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == RequirementMet
    RuleOutput[0].ReportDetails == ReportDetailString
} else := false

# Test that has multiple strings with an unknown order for Report Details
TestResultContains(PolicyId, Output, ReportDetailArrayStrings, RequirementMet) := true if {
    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == RequirementMet
    Conditions :=  [
        (contains(RuleOutput[0].ReportDetails, String) == true) |
        some String in ReportDetailArrayStrings
    ]
    count(FilterArray(Conditions, false)) == 0
} else := false