# The purpose of this test is to have a trivial Pester test that passes.
# This simply verifies that Pester is running.

Describe "Pester Check" {
  It "Passing test should pass." {
    $TestFile = Join-Path -Path $PSScriptRoot -ChildPath '../../Testing/PesterTestFile/SimplePassFile.ps1' -Resolve
    # Source the function
    . utils/workflow/Invoke-PesterTests.ps1
    Invoke-PesterTests -Path $TestFile
  }
}