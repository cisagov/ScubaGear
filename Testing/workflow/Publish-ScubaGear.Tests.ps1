# The purpose of this test is to verify that (most of) the Publish-ScubaGear functions are working correctly.

# Suppress PSSA warnings here at the root of the test file.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

BeforeAll {
  # Souce the publish script.
  # Write-Warning $PSScriptRoot
  . $PSScriptRoot/../../utils/workflow/Publish-ScubaGear.ps1
  # Global variables, so that one Pester test can reuse the output of previous tests.
  $global:ModuleDestinationPath = ""
}

Describe "Copy-ModuleToTempLocation" {
  It "copies the ScubaGear module to the specified location" {
    $Location = Get-Location
    $ModuleSourcePath = Join-Path -Path $Location -ChildPath "/PowerShell/ScubaGear"
    Write-Warning "The module location is $ModuleSourcePath"
    $NumberOfFilesInSource = (Get-ChildItem $ModuleSourcePath -Recurse -File | Measure-Object).Count;
    $TheTempLocation = $env:TEMP
    Write-Warning "The temp location is $TheTempLocation"
    # This should copy the module to the temp location.
    $global:ModuleDestinationPath = Copy-ModuleToTempLocation `
      -ModuleSourcePath $ModuleSourcePath `
      -ModuleTempPath $env:TEMP
    # Verify that the folder is actually there.
    $TheFolderExists = Test-Path -Path $ModuleSourcePath
    $TheFolderExists | Should -Be $true
    # Verify that the right number of files are there.
    $NumberOfFilesInSource = (Get-ChildItem $TheTempLocation -Recurse -File | Measure-Object).Count;
    $NumberOfFilesInSource | Should -BeExactly $NumberOfFilesInSource
  }
}

Describe "Edit-ManifestFile" {
  It "updates the manifest file with the specified, valid data" {
    Write-Warning "The module destination path is $global:ModuleDestinationPath"
    ForEach ($FilePath in $global:ModuleDestinationPath) {
      Write-Warning "File path is $FilePath"
    }
    $ManifestFilePath = Join-Path -Path $global:ModuleDestinationPath -ChildPath "ScubaGear.psd1"
    Write-Warning "The manifest file path is $ManifestFilePath"
    # Verify that the manifest file exists
    if (Test-Path -Path $ManifestFilePath) {
      Write-Warning "The manifest file exists."
    }
    Edit-ManifestFile `
      -ModuleDestinationPath $global:ModuleDestinationPath `
      -OverrideModuleVersion '1.2.3' `
      -PrereleaseTag 'HelloWorld'
    Import-LocalizedData -BaseDirectory $global:ModuleDestinationPath -FileName ScubaGear.psd1 -BindingVariable UpdatedManifest
    $Version = [version]$UpdatedManifest.ModuleVersion
    $Version.Major | Should -BeExactly 1
    $Version.Minor | Should -BeExactly 2
    $Version.Build | Should -BeExactly 3
    $Version.Revision | Should -BeExactly -1
    $Version | Should -BeExactly "1.2.3"
    $UpdatedManifest.PrivateData.PSData.Prerelease | Should -BeExactly 'HelloWorld'
  }
  It "catches invalid PowerShell versions" {
    $Location = Get-Location
    # Old folder
    $ModuleFolderPath = Join-Path -Path $Location -ChildPath "/PowerShell/ScubaGear"
    # New folder
    $ManifestFilePath = Join-Path -Path $global:ModuleDestinationPath -ChildPath "ScubaGear.psd1"
    Write-Warning "The manifest file path is $ManifestFilePath"
    # 99.1 is an intentionally invalid number
    Get-Content "$ModuleFolderPath\ScubaGear.psd1" | ForEach-Object { $_ -replace '5.1', '99.1' } | Set-Content $ManifestFilePath
    $AnErrorWasCaught = $false
    # This function should throw an error.
    try {
      Edit-ManifestFile `
        -ModuleDestinationPath $global:ModuleDestinationPath `
        -OverrideModuleVersion '4.5.6' `
        -PrereleaseTag 'GoodbyeWorld'
    }
    catch {
      $AnErrorWasCaught = $true
      $Error.Count | Should -BeGreaterThan 0
    }
    # Double-check to make sure there was an exception
    $AnErrorWasCaught | Should -Be $true
  }
}

Describe "New-ArrayOfFilePaths" {
  It "should copy of the files paths into the array" {
    # Pick any location, doesn't matter.
    $Location = Get-Location
    $SourcePath = Join-Path -Path $Location -ChildPath "/PowerShell/ScubaGear/Modules/Connection"
    # For this location, count the PowerShell files.
    # There are 2 (at this time).
    # Create an array with the method
    $ArrayOfFilePaths = New-ArrayOfFilePaths -ModuleDestinationPath $SourcePath
    # The resulting array should not be empty.
    $ArrayOfFilePaths | Should -Not -BeNullOrEmpty
    # It should 2 files.
    $ArrayOfFilePaths.Length | Should -Be 2
  }
}

Describe "New-FileList" {
  It "add all of the file paths in the array into the filelist" {
    # Pick any location, doesn't matter.  For now, get current location.
    $Location = Get-Location
    # For this location, get all the MarkDown files at the base of the repo.
    # This could be any type of file; it doesn't really matter.
    $Files = Get-ChildItem -Path $Location -Filter "*.md"
    # Add the files to an array.
    $ArrayOfMarkdownFiles += $Files
    # For debugging
    Write-Warning "Length of array is $($ArrayOfMarkdownFiles.Length)"
    # Create a filelist with the function.
    $FileList = New-FileList -ArrayOfFilePaths $ArrayOfMarkdownFiles
    # Get the content in the filelist
    $Content = Get-Content -Path $FileList
    $MarkdownMatches = $Content | Select-String -Pattern '.md'
    # For debugging
    Write-Warning "Length new file array is $($MarkdownMatches.Length)"
    # The new list file should not be empty.
    $Content | Should -Not -BeNullOrEmpty
    # It should have as many files as we sent to the function.
    $MarkdownMatches.Length | Should -Be $ArrayOfMarkdownFiles.Length
  }
}

Describe "New-ScubaCatalogFile" {
  It "should create two files" {
    $ReturnObject = New-ScubaCatalogFile -ModuleDestinationPath $global:ModuleDestinationPath
    $CatalogFilePath = $($ReturnObject.CatalogFilePath)
    $CatalogList = $($ReturnObject.TempCatalogList)
    Test-Path -Path $CatalogFilePath | Should -Be $true
    $CatalogList | Should -Not -BeNullOrEmpty
  }
}
