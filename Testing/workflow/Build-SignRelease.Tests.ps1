# The purpose of this test to ensure that the function fails
# gracefully if the root folder name does not exist.
# Note:  Functional testing (not unit testing) should be used
#        to verify that AST itself actually works.

Describe "Bad Inputs Check" {
  It "The root folder name should exist" {
    $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Build-SignRelease.ps1' -Resolve
    # Source the function
    . $ScriptPath
    # The function should throw an exception if the root folder name does not exist.
    { New-ModuleSignature `
      -AzureKeyVaultUrl "https://www.cisa.gov" `
      -CertificateName "certificate name" `
      -ReleaseVersion "0.0.1" `
      -RootFolderName "nonexistantfoldername" } | Should -Throw
  }
}
