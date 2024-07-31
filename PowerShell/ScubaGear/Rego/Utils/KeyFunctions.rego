package utils.key
import rego.v1
import data.utils.report.ReportDetailsBoolean
import data.test.assert


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
TestResult(PolicyId, Output, ReportDetailStr, Status) := true  if {
    # Comprehension that filters for the tests rule set result for the policy that we care about. See MS.SHAREPOINT.1.1v1 or training videos for
    # more explination about comprehensions.
    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    # regal ignore: print-or-trace-call
    print("\n** Checking if only one test result **")
    # Checks that there was actualy a result returned (tests for undefined)
    assert.NotEmpty(RuleOutput)
    # Checks for only one result returned (Concern for improperly coded Not-Implemented/Not Applicable checks)
    assert.Equals(1, count(RuleOutput))

    # regal ignore: print-or-trace-call
    print("** Checking RequirementMet **")
    # Checks that requrement met is true or false as indicated by the variable passed
    assert.Equals(Status, RuleOutput[0].RequirementMet)

    # regal ignore: print-or-trace-call
    print("** Checking ReportDetails **")
    # Checks if report details is an EXACT match, can be thrown by extra spaces, wrong letter caps, and different plurals. Most fails are cause by
    # human error in the test, not incorrect logic
    assert.Equals(ReportDetailStr, RuleOutput[0].ReportDetails)
} else := false

# Test that has multiple strings with an unknown order for Report Details
TestResultContains(PolicyId, Output, ReportDetailArrayStrings, RequirementMet) := true if {
    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    # regal ignore: print-or-trace-call
    print("\n** Checking if only one test result **")
    assert.NotEmpty(RuleOutput)
    assert.Equals(count(RuleOutput), 1)

    # regal ignore: print-or-trace-call
    print("** Checking RequirementMet **")
    assert.Equals(RuleOutput[0].RequirementMet, RequirementMet)

    # regal ignore: print-or-trace-call
    print("** Checking ReportDetails **")
    Conditions :=  [
        (assert.DoesContains(RuleOutput[0].ReportDetails, String)) |
        some String in ReportDetailArrayStrings
    ]
    count(FilterArray(Conditions, false)) == 0
} else := false