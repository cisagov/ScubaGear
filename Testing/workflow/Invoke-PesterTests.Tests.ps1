# The purpose of this test is to verify that the Pester test function
# is being called against a path and either failing or passing as expected.

Describe "Pester Check" {
  It "Pester should fail" {
    # This file has intentional problems in it.
    $FailFilePath = Join-Path -Path $PSScriptRoot -ChildPath '../../Testing/PesterTestFiles/DummyFail.ps1' -Resolve
    # Source the function
    . $PSScriptRoot/../../utils/workflow/Invoke-PesterTests.ps1
    $exitCode = Invoke-PesterTests -Path $FailFilePath
    $exitCode | Should -Be 1
  }
  It "Pester should pass" {
    # This file has no problems.
    $PassFilePath = Join-Path -Path $PSScriptRoot -ChildPath '../../Testing/PesterTestFiles/DummyPass.ps1' -Resolve
    # Source the function
    . $PSScriptRoot/../../utils/workflow/Invoke-PesterTests.ps1
    $exitCode = Invoke-PesterTests -Path $PassFilePath
    $exitCode | Should -Be 0
  }
}