<#
    .SYNOPSIS
    Test script to verify Invoke-SCuBA generates valid HTML products.
    .DESCRIPTION
    Test script to test Scuba HTML reports validity.
    .PARAMETER OrganizationDomain
    The Organizations domain name (e.g., abd.onmicrosoft.com)
    .PARAMETER OrganizationName
    The Organizations friendly name (e.g., The ABC Corporation)
    .EXAMPLE
    $TestContainer = New-PesterContainer -Path "SmokeTest002.Tests.ps1" -Data @{ OrganizationDomain = "cisaent.onmicrosoft.com"; OrganizationName = "Cybersecurity and Infrastructure Security Agency" }
    Invoke-Pester -Container $TestContainer -Output Detailed
    .NOTES
    The test expects the Scuba output files to exists from a previous run of Invoke-Scuba for the same tenant and all products.

#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'OrganizationDomain', Justification = 'False positive as rule does not scan child scopes')]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $OrganizationDomain,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $OrganizationName
)

Import-Module Selenium

Describe -Tag "UI","Chrome" -Name "Test Report with <Browser> for $OrganizationName" -ForEach @(
    @{ Browser = "Chrome"; Driver = Start-SeChrome -Arguments @('start-maximized') 2>$null }
){
	BeforeAll {
        $ReportFolders = Get-ChildItem . -directory -Filter "M365BaselineConformance*" | Sort-Object -Property LastWriteTime -Descending
        $OutputFolder = $ReportFolders[0]
        $BaselineReports = Join-Path -Path $OutputFolder -ChildPath 'BaselineReports.html'
        #$script:url = ([System.Uri](Get-Item $BaselineReports).FullName).AbsoluteUri
        $script:url = (Get-Item $BaselineReports).FullName
        Open-SeUrl $script:url -Driver $Driver 2>$null
	}

    Context "Check Main HTML" {
        BeforeAll {
            $TenantDataElement = Get-SeElement -Driver $Driver -Wait -ClassName "tenantdata"
            $TenantDataRows = Get-SeElement -Target $TenantDataElement -By TagName "tr"
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'TenantDataColumns',
                Justification = 'Variable is used in another scope')]
            $TenantDataColumns = Get-SeElement -Target $TenantDataRows[1] -By TagName "td"        }
        It "Verify Tenant"{

            $Tenant = $TenantDataColumns[0].Text
            $Tenant | Should -Be $OrganizationName -Because $Tenant
        }

        It "Verify  Domain"{
            $Domain = $TenantDataColumns[1].Text
            $Domain | Should -Be $OrganizationDomain -Because "Domain is $Domain"
        }
    }

    Context "Navigation to detailed reports" {
        It "Navigate to <Product> (<LinkText>) details" -ForEach @(
            @{Product = "aad"; LinkText = "Azure Active Directory"}
            @{Product = "defender"; LinkText = "Microsoft 365 Defender"}
            @{Product = "onedrive"; LinkText = "OneDrive for Business"}
            @{Product = "exo"; LinkText = "Exchange Online"}
            @{Product = "powerplatform"; LinkText = "Microsoft Power Platform"}
            @{Product = "sharepoint"; LinkText = "SharePoint Online"}
            @{Product = "teams"; LinkText = "Microsoft Teams"}
        ){
            $DetailLink = Get-SeElement -Driver $Driver -Wait -By LinkText $LinkText
            $DetailLink | Should -Not -BeNullOrEmpty
            Invoke-SeClick -Element $DetailLink

            Open-SeUrl -Back -Driver $Driver
        }
    }

    Context "Dark Mode test"{
        It "Toggle to Dark Mode" {
            $ToggleCheckbox = Get-SeElement -Driver $Driver -Wait -By XPath "//input[@id='toggle']"
            $ToggleText = Get-SeElement -Driver $Driver -Wait -Id "toggle-text"

            $ToggleCheckbox.Selected | Should -Be $false
            $ToggleText.Text | Should -Be 'Light Mode'

            $ToggleSwitch = Get-SeElement -Driver $Driver -Wait -ClassName "switch"
            Invoke-SeClick -Element $ToggleSwitch

            $ToggleText.Text | Should -Be 'Dark Mode'
            $ToggleCheckbox.Selected | Should -Be $true
        }

        It "Navigate to <Product> (<LinkText>) details - Switch to Light Mode" -ForEach @(
            @{Product = "aad"; LinkText = "Azure Active Directory"}
        ){
            $DetailLink = Get-SeElement -Driver $Driver -Wait -By LinkText $LinkText
            $DetailLink | Should -Not -BeNullOrEmpty
            Invoke-SeClick -Element $DetailLink

            $ToggleCheckbox = Get-SeElement -Driver $Driver -Wait -By XPath "//input[@id='toggle']"
            $ToggleText = Get-SeElement -Driver $Driver -Wait -Id "toggle-text"

            $ToggleText.Text | Should -Be 'Dark Mode'
            $ToggleCheckbox.Selected | Should -Be $true

            $ToggleSwitch = Get-SeElement -Driver $Driver -Wait -ClassName "switch"
            Invoke-SeClick -Element $ToggleSwitch

            $ToggleText.Text | Should -Be 'Light Mode'
            $ToggleCheckbox.Selected | Should -Be $false
        }

        It "Go Back to main page - Is Dark mode in correct state"{
            Open-SeUrl -Back -Driver $Driver
            $ToggleCheckbox = Get-SeElement -Driver $Driver -Wait -By XPath "//input[@id='toggle']"
            $ToggleText = Get-SeElement -Driver $Driver -Wait -Id "toggle-text"
            $ToggleText.Text | Should -Be 'Light Mode'
            $ToggleCheckbox.Selected | Should -Be $false
        }
    }

	AfterAll {
		Stop-SeDriver -Driver $Driver 2>$null
	}
}
