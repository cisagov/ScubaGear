# Add test with bad key vault URL
# Add test with bad cert name
# Add test that checks for zip file after compress

# The purpose of this test to ensure that the function properly signs the module.

Describe "Sign Module Check" {
  It "Bad key vault URL should be handled gracefully" {
    $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Build-SignRelease.ps1' -Resolve
    # Source the function
    . $ScriptPath
    $RootFolderPath = Join-Path -Path $PSScriptRoot -Childpath '../..'
    $RootFolderName = $RootFolderPath.Name
    New-ModuleSignature `
      -AzureKeyVaultUrl "https://www.cisa.gov" `
      -CertificateName "certificate name" `
      -ReleaseVersion "0.0.1" `
      -RootFolderName $RootFolderName
  }
}

Describe "Bad Inputs Check" {
  It "Bad inputs should be handled gracefully" {
    $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Build-SignRelease.ps1' -Resolve
    # Source the function
    . $ScriptPath
    New-ModuleSignature `
      -AzureKeyVaultUrl "https://www.example.com" `
      -CertificateName "certificate name" `
      -ReleaseVersion "0.0.1" `
      -RootFolderName .
  }
}