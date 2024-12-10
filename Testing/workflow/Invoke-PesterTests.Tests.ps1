# The purpose of this test is to verify that the Pester test function
# is being called against a path and either failing or passing as expected.

Describe "Pester Check" {
  It "Pester should fail" {
    # Source the function
    . $PSScriptRoot/../../utils/workflow/Invoke-PesterTests.ps1
    { Invoke-PesterTests -Path 'Testing/PesterTestFiles/DummyFail.ps1' } | Should -Throw -Because "directory does not exist."
  }
  It "Pester should pass" {
    # Source the function
    . $PSScriptRoot/../../utils/workflow/Invoke-PesterTests.ps1
    { Invoke-PesterTests -Path 'Testing/PesterTestFiles/DummyPass.ps1' } | Should -Not -Throw
  }
}