Import-Module Selenium

Describe -Tag "UI","Chrome" -Name "Test Report with <Browser>" -ForEach @(
    @{ Browser = "Chrome"; Driver = Start-SeChrome -Arguments @('start-maximized') 2>$null }
){
	BeforeAll {
        $ReportFolders = Get-ChildItem . -directory -Filter "M365BaselineConformance*" | Sort-Object -Property LastWriteTime -Descending
        $OutputFolder = $ReportFolders[0]
        $BaselineReports = Join-Path -Path $OutputFolder -ChildPath 'BaselineReports.html'
        #$script:url = ([System.Uri](Get-Item $BaselineReports).FullName).AbsoluteUri
        $script:url = (Get-Item $BaselineReports).FullName
        Enter-SeUrl $script:url -Driver $Driver 2>$null
	}

    Context "Check Main HTML" {
        It "Verify Tenant"{
            $TenantDataElement = Find-SeElement -Driver $Driver -Wait -ClassName "tenantdata"
            $TenantDataRows = Find-SeElement -Target $TenantDataElement -By TagName "tr"
            $TenantDataColumns = Find-SeElement -Target $TenantDataRows[1] -By TagName "td"
            $Tenant = $TenantDataColumns[0].Text
            $Tenant | Should -Be "Cybersecurity and Infrastructure Security Agency" -Because $Tenant
        }

        It "Verify  Domain"{
            $TenantDataElement = Find-SeElement -Driver $Driver -Wait -ClassName "tenantdata"
            $TenantDataRows = Find-SeElement -Target $TenantDataElement -By TagName "tr"
            $TenantDataColumns = Find-SeElement -Target $TenantDataRows[1] -By TagName "td"
            $Domain = $TenantDataColumns[1].Text
            $Domain | Should -Be "cisaent.onmicrosoft.com" -Because "Domain is $Domain"
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
            $DetailLink = Find-SeElement -Driver $Driver -Wait -By LinkText $LinkText
            $DetailLink | Should -Not -BeNullOrEmpty
            Invoke-SeClick -Element $DetailLink

            Open-SeUrl -Back -Driver $Driver
        }
    }

    Context "Dark Mode test"{
        It "Toggle to Dark Mode" {
            $ToggleCheckbox = Find-SeElement -Driver $Driver -Wait -By XPath "//input[@id='toggle']"
            $ToggleText = Find-SeElement -Driver $Driver -Wait -Id "toggle-text"

            $ToggleCheckbox.Selected | Should -Be $false
            $ToggleText.Text | Should -Be 'Light Mode'

            $ToggleSwitch = Find-SeElement -Driver $Driver -Wait -ClassName "switch"
            Invoke-SeClick -Element $ToggleSwitch

            $ToggleText.Text | Should -Be 'Dark Mode'
            $ToggleCheckbox.Selected | Should -Be $true
        }

        It "Navigate to <Product> (<LinkText>) details - Switch to Light Mode" -ForEach @(
            @{Product = "aad"; LinkText = "Azure Active Directory"}
        ){
            $DetailLink = Find-SeElement -Driver $Driver -Wait -By LinkText $LinkText
            $DetailLink | Should -Not -BeNullOrEmpty
            Invoke-SeClick -Element $DetailLink

            $ToggleCheckbox = Find-SeElement -Driver $Driver -Wait -By XPath "//input[@id='toggle']"
            $ToggleText = Find-SeElement -Driver $Driver -Wait -Id "toggle-text"

            $ToggleText.Text | Should -Be 'Dark Mode'
            $ToggleCheckbox.Selected | Should -Be $true

            $ToggleSwitch = Find-SeElement -Driver $Driver -Wait -ClassName "switch"
            Invoke-SeClick -Element $ToggleSwitch

            $ToggleText.Text | Should -Be 'Light Mode'
            $ToggleCheckbox.Selected | Should -Be $false
        }

        It "Go Back to main page - Is Dark mode in correct state"{
            Open-SeUrl -Back -Driver $Driver
            $ToggleCheckbox = Find-SeElement -Driver $Driver -Wait -By XPath "//input[@id='toggle']"
            $ToggleText = Find-SeElement -Driver $Driver -Wait -Id "toggle-text"
            $ToggleText.Text | Should -Be 'Light Mode'
            $ToggleCheckbox.Selected | Should -Be $false
        }
    }

	AfterAll {
		Stop-SeDriver -Driver $Driver 2>$null
	}
}
