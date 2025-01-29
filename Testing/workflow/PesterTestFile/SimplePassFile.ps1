# Ultra trivial Pester test that should always pass.

Describe "Pester Check" {
  It "Passing test should pass." {
    $true | Should -Be $true
  }
}