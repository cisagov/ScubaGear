Describe "Pester Check" {
  It "Passing test should pass." {
    $true | Should -Be $true
  }
}