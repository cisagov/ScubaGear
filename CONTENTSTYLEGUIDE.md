# Content style guide for SCuBA <!-- omit in toc -->

Welcome to the content style guide for ScubaGear

These guidelines are specific to style rules for PowerShell and OPA Rego code. For general style questions or guidance on topics not covered here, ask or go with best guess and bring up at a later meeting.

Use menu icon on the top left corner of this document to get to a specific section of this guide quickly.

## The SCuBA approach to style

- Our style guide aims for simplicity. Guidelines should be easy to apply to a range of scenarios.
- Decisions aren’t about what’s right or wrong according to the rules, but about what’s best practice and improves readability. We're flexible and open to change while maintaining consistency.
- When making a style or structure decision, we consider the readability, maintainability and ability for consitancy in a range of situations.
- When a question specific to help documentation isn’t covered by the style guide, we think it through using these principles, then make a decision and bring it up in the next meeting for deliberation.

## OPA Rego

Because there isn't a standard style guide for the Rego language, we are creating one from scratch. For consistency, we will be using many of the same style rules as PowerShell. There are also a few best practice rules that this program will follow. These best practices were deliberated on and chosen to enhance readability. We recognize that the code is in a constant state of improvement, so the best practices are subject to change.

### Test Cases

Test names will use the syntax `test_mainVar_In/correct_*V#` to support brevity in naming that highlights the primary variable being tested. Furthermore, for tests with more than one version, the first test will also include a version as `_V1`. Consistent use of a version number promotes clarity and signals the presence of multiple test versions to reviewers. Version numbers are not used if there is only a single test of a given variable and type (Correct/Incorrect)

```
test_ExampleVar_Correct_V1 if {
    PolicyId := "MS.<Product>.<Policy #>.<Bulletpoint #>v<Version #>"

    Output := tests with input as {
        "example_policies" : [
            {
                "Example3" : "ExampleString",
                "Example2" : false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Example output"
}

test_ExampleVar_Correct_V2 if {
    ...
}

test_ExampleVar_Incorrect if {
    PolicyId := "MS.<Product>.<Policy #>.<Bulletpoint #>v<Version #>"

    Output := tests with input as {
        "example_policies" : [
            {
                "Example3" : "ExampleString",
                "Example2" : true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Example output"
}
```

### Not Implemented

If the policy bullet point is untestable at this time, use the templates below.

#### Config

The first one directs the user to the baseline document for manual checking. The second instructs the user to run a different script because the test is in another version. However, if they are unable to run the other script, they are also directed to the baseline like in the first template.

```
# At this time we are unable to test for X because of Y
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.<Product>.<Control Group #>.<Control #>v<Version #>"
    true
}
```

```
# At this time we are unable to test for X because of Y
tests[{
    "PolicyId" : "MS.<Product>.<Policy #>.<Bulletpoint #>v<Version #>",
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
```
#### Testing

```
test_NotImplemented_Correct if {
    PolicyId := "MS.<Product>.<Policy #>.<Bulletpoint #>v<Version #>"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}
```
```
test_3rdParty_Correct_V1 if {
    PolicyId := "MS.<Product>.<Policy #>.<Bulletpoint #>v<Version #>"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check"
}
```

### Naming

PascalCase - capitalize the first letter of each word. This is the same naming convention that is used for PowerShell.

```
ExampleVariable := true
```

### Brackets

One True Brace - requires that every braceable statement should have the opening brace on the end of a line, and the closing brace at the beginning of a line. This is the same bracket style that is used for PowerShell.

```
test_Example_Correct if {
    PolicyId := "MS.<Product>.<Policy #>.<Bulletpoint #>v<Version #>"

    Output := tests with input as {
        "example_tag" : {
            "ExampleVar" : false
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}
```

### Indentation

Indentation will be set at 4 spaces, make sure your Tabs == 4 spaces. We are working on finding a tool that will replace Tabs with spaces and clean up additional spacing mistakes. Until then it is checked manually in code review. Be kind to your reviewer!

### Spacing

1) A blank line between each major variable: references & rules

```
Example[Example.Id] {
    Example := input.ExampleVar[_]
    Example.State == "Enabled"
}

tests[{
    "PolicyId" : "MS.<Product>.<Policy #>.<Bulletpoint #>v<Version #>",
    "Criticality" : "Shall",
    "Commandlet" : "Example-Command",
    "ActualValue" : ExampleVar.ExampleSetting,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    ExampleVar := input.ExampleVar
    Status := ExampleVar == 15
}

tests[{
    "PolicyId" : "MS.<Product>.<Policy #>.<Bulletpoint #>v<Version #>",,
...
```

2) Two blank lines between subsections

```
tests[{
    "PolicyId" : "MS.<Product>.<Policy #>.<Bulletpoint #>v<Version #>",,
    "Criticality" : "Should",
    "Commandlet" : "Example-Command",
    "ActualValue" : ExampleVar.ExampleSetting,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    ExampleVar := input.ExampleVar
    Status := ExampleVar == 15
}


################
# Baseline 2.2 #
################
...
```

### Comments

1) Indicate beginning of every policy: 1, 2, etc.

```
###################
# MS.<Product>.1  #
###################
```
2) Indicate the beginning of every policy bullet point.

```
#
# MS.<Product>.<Policy #>.<Bulletpoint #>v<Version #>
#--
```

3) Indicate the end of every policy bullet point.

```
#--
```

4) Indicate why placeholder test is blank/untestable

```
# At this time we are unable to test for X because of Y
```

### Booleans

In the interest of consistency across policy tests and human readability of the test, boolean-valued variables should be set via a comparison test against a boolean constant (true/false).

#### Correct

```
tests[{
    "PolicyId" : "MS.<Product>.<Policy #>.<Bulletpoint #>v<Version #>",,
    "Criticality" : "Should",
    "Commandlet" : "Example-Command",
    "ActualValue" : ExampleVar.ExampleSetting,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    ExampleVar := input.ExampleVar
    Status := ExampleVar == true
}

tests[{
    "PolicyId" : "MS.<Product>.<Policy #>.<Bulletpoint #>v<Version #>",,
    "Criticality" : "Should",
    "Commandlet" : "Example-Command",
    "ActualValue" : ExampleVar.ExampleSetting,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    ExampleVar := input.ExampleVar
    Status := ExampleVar == false
}
```

#### Incorrect

```
tests[{
    ...
}] {
    ExampleVar := input.ExampleVar
    Status := ExampleVar # Mising == true
}

tests[{
    ...
}] {
    ExampleVar := input.ExampleVar
    Status := ExampleVar == false
}
```

### Taking input

We will always store the input in a variable first thing. It can sometimes be easier to only use `input.ExampleVar` repeatedly, but for consistancy this is best practice. the `[_]` is added to the end for when you are anticipating an array, so the program has to loop through the input. There are other ways to take in input, but OPA Documents states `input.VariableName` is recommended. As such we will only use this method for consistancy. If there is a problem, it can be taken up on a case by case basis for disscussion.

```
tests[{
    ...
}] {
    ExampleVar := input.ExampleVar[_]
    Status := "Example" in ExampleVar
}

tests[{
    ...
}] {
    ExampleVar := input.ExampleVar
    Status := ExampleVar == true
}
```

### ActualValue

It can be tempting to put the status variable in the ActualValue spot when you are anticipating a boolean. DON'T! For consistancy and as best practice put `ExampleVar.ExampleSetting`.

#### InCorrect
```
tests[{
    "PolicyId" : "MS.<Product>.<Policy #>.<Bulletpoint #>v<Version #>",,
    "Criticality" : "Should",
    "Commandlet" : "Example-Command",
    "ActualValue" : Status,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    ExampleVar := input.ExampleVar
    Status := ExampleVar == true
}
```

#### Correct
```
tests[{
    "PolicyId" : "MS.<Product>.<Policy #>.<Bulletpoint #>v<Version #>",,
    "Criticality" : "Should",
    "Commandlet" : "Example-Command",
    "ActualValue" : ExampleVar.ExampleSetting,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    ExampleVar := input.ExampleVar
    Status := ExampleVar == true
}
```
## PowerShell
[PoshCode's The PowerShell Best Practices and Style Guide](https://github.com/PoshCode/PowerShellPracticeAndStyle)