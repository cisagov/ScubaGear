<#
    .SYNOPSIS
    Test script to verify Invoke-SCuBA generates valid HTML products.
    .DESCRIPTION
    Test script to test Scuba HTML reports validity.
    .PARAMETER OrganizationDomain
    The Organizations domain name (e.g., abc.onmicrosoft.com)
    .PARAMETER OrganizationName
    The Organizations friendly name (e.g., The ABC Corporation)
    .EXAMPLE
    $TestContainer = New-PesterContainer -Path "SmokeTest002.Tests.ps1" -Data @{ OrganizationDomain = "example.onmicrosoft.com"; OrganizationName = "Example Tenant" }
    Invoke-Pester -Container $TestContainer -Output Detailed
    .NOTES
    The test expects the Scuba output files to exists from a previous run of Invoke-Scuba for the same tenant and all products.

#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'OrganizationDomain', Justification = 'False positive as rule does not scan child scopes')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'OrganizationName', Justification = 'False positive as rule does not scan child scopes')]
param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Alias = 'TenantAlias',
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

Describe -Tag "UI","Chrome" -Name "Test Report with <Browser> for $Alias" -ForEach @(
    @{ Browser = "Chrome"; Driver = Start-SeChrome -Headless -Quiet -Arguments @('start-maximized', 'AcceptInsecureCertificates') 2>$null }
){
	BeforeAll {
        $ReportFolders = Get-ChildItem . -directory -Filter "M365BaselineConformance*" | Sort-Object -Property LastWriteTime -Descending
        $OutputFolder = $ReportFolders[0]
        $BaselineReports = Join-Path -Path $OutputFolder -ChildPath 'BaselineReports.html'
        #$script:url = ([System.Uri](Get-Item $BaselineReports).FullName).AbsoluteUri
        $script:url = (Get-Item $BaselineReports).FullName
        Open-SeUrl $script:url -Driver $Driver | Out-Null
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

        It "Verify Domain"{
            $Domain = $TenantDataColumns[1].Text
            $Domain | Should -Be $OrganizationDomain -Because "Domain is $Domain"
        }
    }

    Context "Navigation to detailed reports" {
        It "Navigate to <Product> (<LinkText>) details" -ForEach @(
            @{Product = "aad"; LinkText = "Azure Active Directory"}
            @{Product = "defender"; LinkText = "Microsoft 365 Defender"}
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

    Context "Verify Table are populated" {
        BeforeEach{
            Open-SeUrl $script:url -Driver $Driver 2>$null
        }
        It "Check <Product> (<LinkText>) tables" -ForEach @(
            @{Product = "aad"; LinkText = "Azure Active Directory"}
            @{Product = "defender"; LinkText = "Microsoft 365 Defender"}
            @{Product = "exo"; LinkText = "Exchange Online"}
            @{Product = "powerplatform"; LinkText = "Microsoft Power Platform"}
            @{Product = "sharepoint"; LinkText = "SharePoint Online"}
            @{Product = "teams"; LinkText = "Microsoft Teams"}
        ){
            $DetailLink = Get-SeElement -Driver $Driver -Wait -By LinkText $LinkText
            $DetailLink | Should -Not -BeNullOrEmpty
            Invoke-SeClick -Element $DetailLink

            # For better performance turn off implict wait
            $Driver.Manage().Timeouts().ImplicitWait = New-TimeSpan -Seconds 0

            $Tables = Get-SeElement -Driver $Driver -By TagName 'table'
            $Tables.Count | Should -BeGreaterThan 1

            ForEach ($Table in $Tables){
                $Rows = Get-SeElement -Element $Table -By TagName 'tr'
                $Rows.Count | Should -BeGreaterThan 0

                # First Table in report is generally tenant data
                if ($Table.GetProperty("id") -eq "tenant-data"){
                    $Rows.Count | Should -BeExactly 2
                    $TenantDataColumns = Get-SeElement -Target $Rows[1] -By TagName "td"
                    $Tenant = $TenantDataColumns[0].Text
                    $Tenant | Should -Be $OrganizationName -Because "Tenant is $Tenant"

                    $RowHeaders = Get-SeElement -Element $Rows[0] -By TagName 'th'

                    ForEach ($Header in $RowHeaders){
                        $Header.GetAttribute("scope") | Should -Be "col" -Because 'Each <th> tag must have a scope attribute set to "col"'
                    }

                    For ($i = 1; $i -lt $Rows.length; $i++){
                        $RowData = Get-SeElement -Element $Rows[$i] -By TagName 'td'
                        For($j = 0; $j -lt $RowData.length; $j++){
                            if($j -eq 0){
                                $RowData[$j].GetAttribute("scope") | Should -Be "row" -Because "There should only be one scope attribute set for each data row"
                            }
                            else{
                                $RowData[$j].GetAttribute("scope") | Should -Not -Be "row"
                            }
                        }
                    }
                }
                # AAD detailed report has a Conditional Access Policy table
                elseif ($Table.GetAttribute("class") -eq "caps_table"){
                    ForEach ($Row in $Rows){
                        $RowHeaders = Get-SeElement -Element $Row -By TagName 'th'
                        $RowData = Get-SeElement -Element $Row -By TagName 'td'

                        ($RowHeaders.Count -eq 0 ) -xor ($RowData.Count -eq 0) | Should -BeTrue -Because "Any given row should be homogenious"

                        # NOTE: Checking for 8 columns since first is 'expand' column
                        if ($RowHeaders.Count -gt 0){
                            $RowHeaders.Count | Should -BeExactly 8
                            $RowHeaders[1].text | Should -BeLikeExactly "Name"
                        }

                        if ($RowData.Count -gt 0){
                            $RowData.Count | Should -BeExactly 8
                        }
                    }

                    ForEach ($Header in $RowHeaders){
                        $Header.GetAttribute("scope") | Should -Be "col" -Because 'Each <th> tag must have a scope attribute set to "col"'
                    }

                    For ($i = 1; $i -lt $Rows.length; $i++){
                        $RowData = Get-SeElement -Element $Rows[$i] -By TagName 'td'
                        For($j = 0; $j -lt $RowData.length; $j++){
                            if($j -eq 1){
                                $RowData[$j].GetAttribute("scope") | Should -Be "row" -Because "There should only be one scope attribute set for each data row"
                            }
                            else{
                                $RowData[$j].GetAttribute("scope") | Should -Not -Be "row"
                            }
                        }
                    }
                }
                elseif ($Table.GetProperty("id") -eq "license-info"){

                    # Iterate through each row in the table ensuring there are 3 columns
                    foreach ($Row in $Rows) {
                        $RowHeaders = Get-SeElement -Element $Row -By TagName 'th'
                        $RowData = Get-SeElement -Element $Row -By TagName 'td'

                        if ($RowHeaders.Count -gt 0){
                            $RowHeaders.Count | Should -BeExactly 4
                        }

                        if ($RowData.Count -gt 0){
                            $RowData.Count | Should -BeExactly 4
                        }
                    }
                }
                elseif ($Table.GetProperty("id") -eq "privileged-service-principals"){

                    # Iterate through each row in the table ensuring there are 4 columns
                    foreach ($Row in $Rows) {
                        $RowHeaders = Get-SeElement -Element $Row -By TagName 'th'
                        $RowData = Get-SeElement -Element $Row -By TagName 'td'

                        if ($RowHeaders.Count -gt 0){
                            $RowHeaders.Count | Should -BeExactly 4
                            $RowHeaders[0].text | Should -BeLikeExactly "Display Name"
                        }

                        if ($RowData.Count -gt 0){
                            $RowData.Count | Should -BeExactly 4
                        }
                    }
                }
                # Default is normal policy results table
                else {
                    # Control report tables
                    ForEach ($Row in $Rows){
                        $RowHeaders = Get-SeElement -Element $Row -By TagName 'th'
                        $RowData = Get-SeElement -Element $Row -By TagName 'td'

                        ($RowHeaders.Count -eq 0 ) -xor ($RowData.Count -eq 0) | Should -BeTrue -Because "Any given row should be homogenious"

                        if ($RowHeaders.Count -gt 0){
                            $RowHeaders.Count | Should -BeExactly 5
                            $RowHeaders[0].text | Should -BeLikeExactly "Control ID"
                        }

                        if ($RowData.Count -gt 0){
                            $RowData.Count | Should -BeExactly 5
                            $RowData[2].text | Should -Not -BeLikeExactly "Error - Test results missing" -Because "All policies should have implementations: $($RowData[0].text)"
                        }
                    }

                    ForEach ($Header in $RowHeaders){
                        $Header.GetAttribute("scope") | Should -Be "col" -Because 'Each <th> tag must have a scope attribute set to "col"'
                    }

                    For ($i = 1; $i -lt $Rows.length; $i++){
                        $RowData = Get-SeElement -Element $Rows[$i] -By TagName 'td'
                        For($j = 0; $j -lt $RowData.length; $j++){
                            if($j -eq 0){
                                $RowData[$j].GetAttribute("scope") | Should -Be "row" -Because "There should only be one scope attribute set for each data row"
                            }
                            else{
                                $RowData[$j].GetAttribute("scope") | Should -Not -Be "row"
                            }
                        }
                    }
                }
            }

            # Turn implict wait back on
            $Driver.Manage().Timeouts().ImplicitWait = New-TimeSpan -Seconds 10
        }
    }

	AfterAll {
		Stop-SeDriver -Driver $Driver | Out-Null
	}
}