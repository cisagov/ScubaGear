# The purpose of this test is to verify that the DeployUtils can successfully publish ScubaGear.

# Suppress PSSA warnings here at the root of the test file.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

BeforeAll {
  Write-Warning $PSScriptRoot
  . $PSScriptRoot/../../utils/DeployUtils.ps1
}

Describe "Check creating an array of file paths" {
  # Note: This is test is brittle.  If someone adds more
  # files to the utils folder, this test will start 
  # failing.
  It "The array should have a length of 2" {
    $ArrayOfFilePaths = CreateArrayOfFilePaths -SourcePath $PSScriptRoot/../../utils -Extensions "*.ps1"
    $ArrayOfFilePaths.Length | Should -Be 2
  }
}

Describe "Check creating a file list" {
  It "The list should have all the files in it" {
    $Location = Get-Location
    # For a location, get all the MarkDown files at the base of the repo.
    $Files = Get-ChildItem -Path $Location -Filter "*.md"
    $ArrayOfMarkdownFiles += $Files
    Write-Warning "Length of array is $($ArrayOfMarkdownFiles.Length)"
    $FileList = CreateFileList -FileNames $ArrayOfMarkdownFiles
    $Content = Get-Content -Path $FileList
    $Matches = $Content | Select-String -Pattern '.md'
    # The resulting file should not be empty.
    $Content | Should -Not -BeNullOrEmpty
    # It should have as many files as we sent to the function.
    $Matches.Length | Should -Be $ArrayOfMarkdownFiles.Length
  }
}