$TestPlanPath = Join-Path -Path $PSScriptRoot -ChildPath "TestPlans/$ProductName.testplan.yaml"
Test-Path -Path $TestPlanPath -PathType Leaf

$YamlString = Get-Content -Path $TestPlanPath | Out-String
$ProductTestPlan = ConvertFrom-Yaml $YamlString
$TestPlan = $ProductTestPlan.TestPlan.ToArray()
$Tests = $TestPlan.Tests