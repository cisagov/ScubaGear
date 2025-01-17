# Add test with bad key vault URL
# Add test with bad cert name
# Add test that checks for zip file after compress

# The purpose of this test to ensure that the function properly signs the module.

Describe "Bad Inputs Check" {
  It "The root folder name should exist" {
    $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Build-SignRelease.ps1' -Resolve
    # Source the function
    . $ScriptPath
    # $RootFolderPath = Join-Path -Path $PSScriptRoot -Childpath '../..' -Resolve
    # Write-Warning "Root Folder Path: $RootFolderPath"
    # Copy to pester $TestDrive and put in repo folder
    # pass that repo folder to signature below
    New-ModuleSignature `
      -AzureKeyVaultUrl "https://www.cisa.gov" `
      -CertificateName "certificate name" `
      -ReleaseVersion "0.0.1" `
      -RootFolderName "nonexistantfoldername" | Should -Throw
  }
}
