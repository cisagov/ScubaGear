# Types of Unit Tests

## Basic Top Down

```Rego
test_ExampleVar_Correct if {
    Output := <Product>.tests with input as {
        "Example_Key": [
            {
                "AnotherKey": 0
            }
        ]
    }

    TestResult("MS.<Product>.1.1v1", Output, <String>, true) == true
}

test_ExampleVar_Incorrect_V1 if {
    Output := <Product>.tests with input as {
        "Example_Key": [
            {
                "AnotherKey": 1
            }
        ]
    }

    TestResult("MS.<Product>.1.1v1", Output, <String>, false) == true
}

test_ExampleVar_Incorrect_V2 if {
    Output := <Product>.tests with input as {
        "Example_Key": [
            {
                "AnotherKey": 2
            }
        ]
    }

    TestResult("MS.<Product>.1.1v1", Output, <String>, false) == true
}
```

## Condensed Top Down

```Rego
test_ExampleVar_Correct if {
    Output := <Product>.tests with input.example_key as [BaseJsonVariable]

    TestResult("MS.<Product>.1.1v1", Output, <String>, true) == true
}

test_ExampleVar_Incorrect_V1 if {
    Var := json.patch(BaseJsonVariable,
                [{"op": "add", "path": "AnotherKey", "value": ["Something"]}])
    Output := <Product>.tests with input.example_key as [Var]

    TestResult("MS.<Product>.1.1v1", Output, <String>, false) == true
}

test_ExampleVar_Incorrect_V2 if {
    Output := <Product>.tests with input.example_key as [BaseJsonVariable]
                                with input.scuba_config.Aad["MS.<Product>.1.1v1"] as ScubaConfig

    TestResult("MS.<Product>.1.1v1", Output, <String>, false) == true
}

```

## Bottom Up

```Rego

```
