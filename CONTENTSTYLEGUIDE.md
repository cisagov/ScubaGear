# Content style guide for SCuBA <!-- omit in toc -->

Welcome to the content style guide for ScubaGear!

These guidelines are specific to style rules for PowerShell and OPA Rego code. For general style questions or guidance on topics not covered here, ask or go with best guess and bring up at a later meeting.

Use menu icon on the top left corner of this document to get to a specific section of this guide quickly.

## The SCuBA approach to style

- Our style guide aims for simplicity. Guidelines should be easy to apply to a range of scenarios.
- Decisions aren’t about what’s right or wrong according to the rules, but about what’s best practice and improves readability. We're flexible and open to change while maintaining consistency.
- When making a style or structure decision, we consider the readability, maintainability and ability for consistency in a range of situations.
- When a question specific to help documentation isn’t covered by the style guide, we think it through using these principles, then make a decision and bring it up in the next meeting for deliberation.

## OPA Rego

The project is adopting the following public Rego [style guide](https://docs.styra.com/opa/rego-style-guide), except where our guide specifically notes an exception (e.g., variable name case). For consistency, we will be using many of the same style rules as PowerShell. There are also a few best practice rules that this project will follow. These best practices were chosen to enhance readability. We recognize that the code is in a constant state of improvement, so the best practices are subject to change. The project is also integrating the [Regal](https://github.com/StyraInc/regal) linter into its automated checks to promote style guide adherence.

### Test Cases

Test names will use the syntax `test_mainVar_In/correct_*V#` to support brevity in naming that highlights the primary variable being tested. Furthermore, for tests with more than one version, the first test will also include a version as `_V1`. Consistent use of a version number promotes clarity and signals the presence of multiple test versions to reviewers. Version numbers are not used if there is only a single test of a given variable and type (Correct/Incorrect)

```
test_ExampleVar_Correct_V1 if {
    Output := <Product>.tests with input as {
        "example_policies" : [
            {
                "Example3" : "ExampleString",
                "Example2" : false
            }
        ]
    }

    TestResult("MS.<Product>.<Policy Group #>.<Policy #>v<Version #>", Output, "ReportDetailString", true) == true
}

test_ExampleVar_Correct_V2 if {
    ...
}

test_ExampleVar_Incorrect if {
    Output := <Product>.tests with input as {
        "example_policies" : [
            {
                "Example3" : "ExampleString",
                "Example2" : true
            }
        ]
    }

    TestResult("MS.<Product>.<Policy Group #>.<Policy #>v<Version #>", Output, "ReportDetailString", false) == true
}

test_ExampleVar_UnknownReportString_Incorrect if {
    Output := <Product>.tests with input as {
        "example_policies" : [
            {
                "Example3" : "ExampleString",
                "Example2" : true
            }
        ]
    }

    ReportDetailArrayStrs := [
        "Part of string",
        "Second part",
        "Third part"
    ]
    TestResultContains("MS.<Product>.<Policy Group #>.<Policy #>v<Version #>", Output, ReportDetailArrayStrs, false) == true
}
```

### Not Implemented

If the policy is untestable at this time, use the templates below.

#### Config

The first one directs the user to the baseline document for manual checking. The second instructs the user to run a different script because the test is in another version. However, if they are unable to run the other script, they are also directed to the baseline like in the first template.

```
# At this time we are unable to test for X because of Y
tests contains {
    "PolicyId": "MS.<Product>.<Policy Group #>.<Policy #>v<Version #>",
    "Criticality": "Should/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.<Product>.<Policy Group #>.<Policy #>v<Version #>"),
    "RequirementMet": false,
}
```

```
# At this time we are unable to test for X because of Y
tests contains {
    "PolicyId": "MS.<Product>.<Policy Group #>.<Policy #>v<Version #>,
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.<Product>.<Policy Group #>.<Policy #>v<Version #>"),
    "RequirementMet": false,
}
```
#### Testing

```
test_NotImplemented_Correct if {
    PolicyId := "MS.<Product>.<Policy Group #>.<Policy #>v<Version #>"

    Output := <Product>.tests with input as { }

    TestResult(PolicyId, Output, NotCheckedDetails(PolicyId), false) == true
}
```
```
test_3rdParty_Correct_V1 if {
    PolicyId := "MS.<Product>.<Policy Group #>.<Policy #>v<Version #>"

    Output := <Product>.tests with input as { }

    TestResult(PolicyId, Output, DefenderMirrorDetails(PolicyId), false) == true
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
    Output := <Product>.tests with input as {
        "example_tag" : {
            "ExampleVar" : false
        }
    }

    TestResult("MS.<Product>.<Policy Group #>.<Policy #>v<Version #>", Output, "ReportDetailString", true) == true
}
```

### Indentation

Indentation will be set at 4 spaces, make sure your Tabs == 4 spaces. We are working on finding a tool that will replace Tabs with spaces and clean up additional spacing mistakes. Until then it is checked manually in code review. Be kind to your reviewer!

### Spacing

1) A blank line between each major variable: references & rules

```
Example contains Example.Id if {
    Example := input.ExampleVar[_]
    Example.State == "Enabled"
}

tests contains {
    "PolicyId" : "MS.<Product>.<Policy Group #>.<Policy #>v<Version #>",
    "Criticality" : "Shall",
    "Commandlet" : "Example-Command",
    "ActualValue" : ExampleVar.ExampleSetting,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
} if {
    ExampleVar := input.ExampleVar
    Status := ExampleVar == 15
}

tests {
    "PolicyId" : "MS.<Product>.<Policy Group #>.<Policy #>v<Version #>",,
...
```

2) Two blank lines between subsections

```
tests contains {
    "PolicyId" : "MS.<Product>.<Policy Group #>.<Policy #>v<Version #>",,
    "Criticality" : "Should",
    "Commandlet" : "Example-Command",
    "ActualValue" : ExampleVar.ExampleSetting,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
} if {
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
2) Indicate the beginning of every policy.

```
#
# MS.<Product>.<Policy Group #>.<Policy #>v<Version #>
#--
```

3) Indicate the end of every policy.

```
#--
```

4) Indicate why placeholder test is blank/untestable

```
# At this time we are unable to test for X because of Y
```

### Booleans

In the interest of consistency across policy tests and human readability of the test, boolean-valued variables should be set via a comparison test against a boolean constant (true/false) for variables.

#### Correct

```
tests contains {
    "PolicyId" : "MS.<Product>.<Policy Group #>.<Policy #>v<Version #>",,
    "Criticality" : "Should",
    "Commandlet" : "Example-Command",
    "ActualValue" : ExampleVar.ExampleSetting,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
} if {
    ExampleVar := input.ExampleVar
    Status := ExampleVar == true
}

tests contains {
    "PolicyId" : "MS.<Product>.<Policy Group #>.<Policy #>v<Version #>",,
    "Criticality" : "Should",
    "Commandlet" : "Example-Command",
    "ActualValue" : ExampleVar.ExampleSetting,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
} if {
    ExampleVar := input.ExampleVar
    Status := ExampleVar == false
}
```

#### Incorrect

```
tests contains {
    ...
} if {
    ExampleVar := input.ExampleVar
    Status := ExampleVar # Missing == true
}

tests contains {
    ...
} if {
    ExampleVar := input.ExampleVar
    Status := ExampleVar == false
}
```

Because methods can return undefined, use `not` instead of false comparison when dealing with booleans. `not` will still pass if the you want the false result, i.e. `== false`, but will also pass if the result is undefined. This is important because the default keyword does not work for methods, only variables. So you write your methods for the true cases & treat false/undefined results as failing cases.

#### Correct


```
ExampleVariable contains SomeVariable.DisplayName if {
    some X
    SomeVariable := input.example_key[X]
    not is_null(SomeVariable.OnPremisesImmutableId)
}
```

#### Incorrect

```
ExampleVariable contains SomeVariable.DisplayName if {
    some X
    SomeVariable := input.example_key[X]
    is_null(SomeVariable.OnPremisesImmutableId) == false
}
```

Opa will use implicit true in some cases. For example, if the variable contained a true/false boolean, you did not need `== true` to check if the boolean contained is true. This is also true in method returns. Opa assumes methods return true/false & if not specified, will return true. For readability purposes, we enforce explicitly stating `:= true`.

#### Correct
```
ExampleMethod(Variable) := true if {
    count({x | some x in Variable}) == 0
}
```

#### Incorrect

```
ExampleMethod(Variable) if {
    count({x | some x in Variable}) == 0
}
```

### Taking input

We will always store the input in a variable first thing. It can sometimes be easier to only use `input.ExampleVar` repeatedly, but for consistency this is best practice. the `some var in` is added to the end for when you are anticipating an array, so the program has to loop through the input. There are other ways to take in input, but OPA Documents states `input.VariableName` is recommended. As such we will only use this method for consistency. If there is a problem, it can be taken up on a case by case basis for discussion.

```
tests contains {
    ...
} if {
    some ExampleVar in input.example_var
    Status := "Example" in ExampleVar
}

tests contains {
    ...
} if {
    some ExampleVar in input.example_var[_].nested_var
    Status := "Example" in ExampleVar
}

tests contains {
    ...
} if {
    ExampleVar := input.example_var
    Status := ExampleVar == true
}
```

### ActualValue

It can be tempting to put the status variable in the ActualValue spot when you are anticipating a boolean. DON'T! For consistency and as best practice put `ExampleVar.ExampleSetting`.

#### Incorrect
```
tests contains {
    "PolicyId" : "MS.<Product>.<Policy Group #>.<Policy #>v<Version #>",,
    "Criticality" : "Should",
    "Commandlet" : "Example-Command",
    "ActualValue" : Status,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
} if {
    ExampleVar := input.example_var
    Status := ExampleVar == true
}
```

#### Correct
```
tests contains {
    "PolicyId" : "MS.<Product>.<Policy Group #>.<Policy #>v<Version #>",,
    "Criticality" : "Should",
    "Commandlet" : "Example-Command",
    "ActualValue" : ExampleVar.ExampleSetting,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
} if {
    ExampleVar := input.example_var
    Status := ExampleVar == true
}
```

### Linter Warnings

For the most part warnings can and should be fixed. However, there are times where the fix would make the code more difficult to maintain and understand. In these rare cases,
add a comment indicating to ignore the specific linter warning.

#### Example
```
ExampleArray contains OtherVar.name if {
    # regal ignore:<rule_name>
    some Var in input.some_key[_].value
    some OtherVar in Var.example_key
}
```

## PowerShell
[PoshCode's The PowerShell Best Practices and Style Guide](https://github.com/PoshCode/PowerShellPracticeAndStyle)

## README Formatting
This section is for standardizing how to format the README and it's table of contents (toc) for legibility.
The formatting guidelines described in the sections below take formatting syntax from the VSCode [Markdown All in One](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one) extension into account. The extension is not required for ScubaGear development but is used as the basis of this guide.
To keep the README as a consistently formatted and compact resource for users, please follow the guidelines below.

### Character Limit
If the section header is at a level 2 or level 3 i.e.`## Getting Started` `### Download the Latest Release` keep the section header to at most around 55 characters.

This is to limit text stretching in the toc in the README.

### Omit the Section Headers Including and Above the Table of Contents
Add the ` <!-- omit in toc -->` comment to the `## Table of Contents` and `# ScubaGear` headers.

**Example**
```
 # ScubaGear <!-- omit in toc -->
```
These sections are located above the table of contents and are thus unnecessary.
The comment will prevent the Markdown All in One extension from auto formatting the README with these headers.
This should already be implemented in the current README but this guideline is to reinforce the decision.

### Omit the Section Headers Level 4+
If the section header is a level 4+ header i.e `#### Power Platform App Registration` add a omit comment.

**Example**
```
#### Power Platform App Registration <!-- omit in toc -->
```
This is to prevent the depth of the table of contents in the README from becoming too deeply nested.
Deeply nested sections disrupt legibility of the toc and should be avoided.
