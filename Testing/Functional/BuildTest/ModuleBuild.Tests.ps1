param (
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ModuleName = "ScubaGear",
    [Parameter(Mandatory=$true)]
    [Version]
    $ModuleVersion,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RepositoryName = "PrivateScubaGearGallery"
)

Describe "Validate <ModuleName> module deployment" {
    BeforeAll {
        $Module = Find-Module -Name $ModuleName -Repository $RepositoryName
    }
    It "Verify version" {
        $Module.Version | Should -BeExactly $ModuleVersion
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