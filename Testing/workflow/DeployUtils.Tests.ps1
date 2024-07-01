# The purpose of this test is to verify that some of the DeployUtils functions, used to publish ScubaGear, are working correctly.

# Suppress PSSA warnings here at the root of the test file.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

BeforeAll {
  # Write-Warning $PSScriptRoot
  . $PSScriptRoot/../../utils/DeployUtils.ps1
}

Describe "Check ConfigureScubaGearModule" {
  It "The manifest file should be altered" {
    # Get contents of manifest file.
    $Location = Get-Location
    $ManifestFilePath = Join-Path -Path $Location -ChildPath "PowerShell/ScubaGear/ScubaGear.psd1"
    $OriginalContent = Get-Content -Path $ManifestFilePath
    # ForEach ($Line in $OriginalContent) { Write-Warning $Line }
    # Setup input parameters.
    $ModuleDir = Join-Path -Path $Location -ChildPath "/PowerShell/ScubaGear"
    $ModuleVersion = "9.9.9"
    $Tag = "help"
    ConfigureScubaGearModule -ModulePath $ModuleDir -OverrideModuleVersion $ModuleVersion -PrereleaseTag $Tag
    # Get the new contents of the manifest file
    $ModifiedContent = Get-Content -Path $ManifestFilePath
    # ForEach ($Line in $ModifiedContent) { Write-Warning $Line }
    # Diff the original with the modified
    $Diff = Compare-Object -ReferenceObject $OriginalContent -DifferenceObject $ModifiedContent
    # Look for changes for a new module version
    $ModuleVersionDiff = $Diff | Out-String | Select-String -Pattern $ModuleVersion
    # There should be only 1 match.
    ForEach ($Match in $ModuleVersionDiff.Matches) {
      $Match | Should -Be $ModuleVersion
    }
    # Look for changes for a new tag
    $TagDiff = $Diff | Out-String | Select-String -Pattern $Tag
    ForEach ($Match in $TagDiff.Matches) {
      $Match | Should -Be $Tag
    }
  }
}

Describe "Check CreateArrayOfFilePaths" {
  It "The array should have all the files in it" {
    # Pick any location, doesn't matter.  For now, get utils folder.
    $Location = Get-Location
    $UtilsFolder = Join-Path -Path $Location -ChildPath "utils"
    # For this location, get all the PS files.
    # This could be any type of file; it doesn't really matter.
    $Files = Get-ChildItem -Path $UtilsFolder -Filter "*.ps1"
    # Add the files to an array.
    $ArrayOfPowerShellFiles += $Files
    # Write-Warning "Length of array is $($ArrayOfPowerShellFiles.Length)"
    # Create an array with the method
    $ArrayOfFilePaths = CreateArrayOfFilePaths -SourcePath $UtilsFolder -Extensions "*.ps1"
    # The resulting file should not be empty.
    $ArrayOfFilePaths | Should -Not -BeNullOrEmpty
    # It should have as many files as we sent to the function.
    $ArrayOfFilePaths.Length | Should -Be $ArrayOfPowerShellFiles.Length
  }
}

Describe "Check CreateFileList" {
  It "The list should have all the files in it" {
    # Pick any location, doesn't matter.  For now, get current location.
    $Location = Get-Location
    # For this location, get all the MarkDown files at the base of the repo.
    # This could be any type of file; it doesn't really matter.
    $Files = Get-ChildItem -Path $Location -Filter "*.md"
    # Add the files to an array.
    $ArrayOfMarkdownFiles += $Files
    # Write-Warning "Length of array is $($ArrayOfMarkdownFiles.Length)"
    # Create a filelist with the function.
    $FileList = CreateFileList -FileNames $ArrayOfMarkdownFiles
    # Get the content in the filelist
    $Content = Get-Content -Path $FileList
    $MarkdownMatches = $Content | Select-String -Pattern '.md'
    # The resulting file should not be empty.
    $Content | Should -Not -BeNullOrEmpty
    # It should have as many files as we sent to the function.
    $MarkdownMatches.Length | Should -Be $ArrayOfMarkdownFiles.Length
  }
}