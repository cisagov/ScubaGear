# This file contains a sequence of stability (aka smoke) tests for ScubaGear to ensure that the tool functions at a basic level

############## Test that the tool created a TestResults.json file
Test-Path .\TestResults.json

############## Test that the TestResults.json file is a structurally valid JSON document
$JSONContent = Get-Content .\TestResults.json -Raw | ConvertFrom-Json
