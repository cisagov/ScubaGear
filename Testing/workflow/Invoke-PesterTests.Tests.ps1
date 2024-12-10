# The purpose of this test is to have trivial Pester tests that pass and fail as expected.

Describe "Pester Check" {
  It "Passing test should pass." {
    $true | Should -Be $true
  }
}