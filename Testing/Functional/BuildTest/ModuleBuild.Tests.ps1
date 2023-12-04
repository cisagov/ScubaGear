<#
    .SYNOPSIS
    Test script to verify module is published to private package repository.
    .DESCRIPTION
    Test script finds a module in a package repository and verifies meta data.
    .PARAMETER ModuleName
    Name of the module
    .PARAMETER RepositoryName
    Name of the private repository
    .EXAMPLE
    Get-Location
    $TestContainers = @()
    $TestContainers += New-PesterContainer -Path "src/Testing/Functional/BuildTest" -Data @{ }
    $PesterConfig = @{
        Run = @{
            Container = $TestContainers
        }
        Output = @{
            Verbosity = 'Detailed'
        }
    }
    $Config = New-PesterConfiguration -Hashtable $PesterConfig
    Invoke-Pester -Configuration $Config
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ModuleName', Justification = 'False positive as rule does not scan child scopes')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'RepositoryName', Justification = 'False positive as rule does not scan child scopes')]
param (
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ModuleName = "ScubaGear",
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RepositoryName = "PrivateScubaGearGallery"
)

Describe "Validate <ModuleName> module deployment" {
    BeforeAll {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Module', Justification = 'False positive as rule does not scan child scopes')]
        $Module = Find-Module -Name $ModuleName -Repository $RepositoryName
    }
    It "Verify version" {
        $Module.Version | Should -Not -BeNullOrEmpty
        {[version]($Module.Version)} | Should -Not -Throw
    }
    It "Verify name" {
        $Module.Name | Should -BeExactly $ModuleName
    }
    It "Verify module type" {
        $Module.Type | Should -BeExactly 'Module'
    }
    It "Verify module description" {
        $Module.Description | Should -Not -BeNullOrEmpty
    }
    It "Verify module author" {
        $Module.Author | Should -BeExactly "CISA"
    }
    It "Verify module tags" {
        $Module.Tags | Should -Not -BeNullOrEmpty
    }
    It "Verify module copyright" {
        $Module.CopyRight | Should -Not -BeNullOrEmpty
    }
    It "Verify Project Uri" {
        [uri]::IsWellFormedUriString($Module.ProjectUri, 'Absolute') -and ([uri] $Module.ProjectUri).Scheme -in 'https' |
        Should -BeTrue
    }
    It "Verify License Uri" {
        [uri]::IsWellFormedUriString($Module.LicenseUri, 'Absolute') -and ([uri] $Module.LicenseUri).Scheme -in 'https' |
        Should -BeTrue
    }
}