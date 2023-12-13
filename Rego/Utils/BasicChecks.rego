package utils.policy
import future.keywords
import data.utils.report.FormatArray
import data.utils.report.ReportDetailsBoolean
import data.utils.report.Description

# Checks if set/array is null or empty
IsEmptyContainer(null) := true

IsEmptyContainer(container) := true if {
    Temp := {Item | some Item in container}
    count(Temp) == 0
} else := false

# Check if "All" is in the array
IsAllUsers(null) := false

IsAllUsers(array) := true if {
    not IsEmptyContainer(array)
    "All" in array
} else := false

# Check if string is in array
Contains(null, _) := false

Contains(array, item) := true if {
    not IsEmptyContainer(array)
    item in array
} else := false

# Returns size of set/array
Count(null) := 0

Count(Container) := count(Container) if {
    not IsEmptyContainer(Container)
} else := 0

ReportDetailsArray(true, _, _) := ReportDetailsBoolean(true) if {}

ReportDetailsArray(false, Array, String) := Description([FormatArray(Array), String, concat(", ", Array)]) if {}

FilterArray(Conditions, Boolean) := [Condition | some Condition in Conditions; Condition == Boolean]

CorrectTestResult(PolicyId, Output, ReportDetailString) := true if {
    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == true
    RuleOutput[0].ReportDetails == ReportDetailString
} else := false

IncorrectTestResult(PolicyId, Output, ReportDetailString) := true if {
    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == false
    RuleOutput[0].ReportDetails == ReportDetailString
} else := false

FAIL := ReportDetailsBoolean(false)

PASS := ReportDetailsBoolean(true)