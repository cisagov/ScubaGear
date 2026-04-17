<#
 # Tests for SharePoint Provider using REST API
#>

$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportSharePointProvider.psm1") -Force
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ProviderHelpers/CommandTracker.psm1") -Force

InModuleScope -ModuleName ExportSharePointProvider {
    Describe -Tag 'SharePointProvider' -Name "Export-SharePointProvider" {
        BeforeAll {
            class MockCommandTracker {
                [string[]]$SuccessfulCommands = @()
                [string[]]$UnSuccessfulCommands = @()

                [System.Object[]] TryCommand([string]$Command, [hashtable]$CommandArgs) {
                    try {
                        switch ($Command) {
                            "Get-MgBetaOrganization" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{
                                    VerifiedDomains = @(
                                        @{
                                            "isInitial" = $true;
                                            "Name"      = "contoso.onmicrosoft.com";
                                        }
                                        @{
                                            "isInitial" = $false;
                                            "Name"      = "example.onmicrosoft.com";
                                        }
                                    )
                                }
                            }
                            default {
                                throw "ERROR you forgot to create a mock method for this cmdlet: $($Command)"
                            }
                        }
                        $Result = @()
                        $this.SuccessfulCommands += $Command
                        return $Result
                    }
                    catch {
                        Write-Warning "Error running $($Command). $($_)"
                        $this.UnSuccessfulCommands += $Command
                        $Result = @()
                        return $Result
                    }
                }

                [System.Object[]] TryCommand([string]$Command) {
                    return $this.TryCommand($Command, @{})
                }

                [void] AddSuccessfulCommand([string]$Command) {
                    $this.SuccessfulCommands += $Command
                }

                [void] AddUnSuccessfulCommand([string]$Command) {
                    $this.UnSuccessfulCommands += $Command
                }

                [string[]] GetUnSuccessfulCommands() {
                    return $this.UnSuccessfulCommands
                }

                [string[]] GetSuccessfulCommands() {
                    return $this.SuccessfulCommands
                }
            }

            function Get-CommandTracker {}
            Mock -ModuleName ExportSharePointProvider Get-CommandTracker {
                return [MockCommandTracker]::New()
            }

            # Mock REST API functions
            function Get-SPOTenantRest {}
            Mock -ModuleName ExportSharePointProvider Get-SPOTenantRest {
                return [pscustomobject]@{
                    SharingCapability = 0
                    ODBSharingCapability = 0
                    SharingDomainRestrictionMode = 0
                    DefaultSharingLinkType = 1
                    DefaultLinkPermission = 1
                    RequireAnonymousLinksExpireInDays = 30
                    FileAnonymousLinkType = 2
                    FolderAnonymousLinkType = 2
                    EmailAttestationRequired = $true
                    EmailAttestationReAuthDays = 30
                }
            }

            function Get-SPOSiteRest {}
            Mock -ModuleName ExportSharePointProvider Get-SPOSiteRest {
                return [pscustomobject]@{}
            }

            function Test-SCuBAValidProviderJson {
                param (
                    [string]
                    $Json
                )
                $Json = $Json.TrimEnd(",")
                $Json = "{$($Json)}"
                $ValidJson = $true
                try {
                    ConvertFrom-Json $Json -ErrorAction Stop | Out-Null
                }
                catch {
                    $ValidJson = $false;
                }
                $ValidJson
            }
        }
        Context 'When Running Interactively with REST API' {
            It "with -M365Environment 'commercial', returns valid JSON" {
                $Json = Export-SharePointProvider -M365Environment 'commercial' -AccessToken 'mock-access-token' -AdminUrl 'https://contoso-admin.sharepoint.com'
                $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It "with -M365Environment 'gcc', returns valid JSON" {
                $Json = Export-SharePointProvider -M365Environment 'gcc' -AccessToken 'mock-access-token' -AdminUrl 'https://contoso-admin.sharepoint.com'
                $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It "with -M365Environment 'gcchigh', returns valid JSON" {
                $Json = Export-SharePointProvider -M365Environment 'gcchigh' -AccessToken 'mock-access-token' -AdminUrl 'https://contoso-admin.sharepoint.us'
                $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It "with -M365Environment 'dod', returns valid JSON" {
                $Json = Export-SharePointProvider -M365Environment 'dod' -AccessToken 'mock-access-token' -AdminUrl 'https://contoso-admin.sharepoint-mil.us'
                $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
        }
        Context 'When running with Service Principals via REST API' {
            It "with -M365Environment commercial, returns valid JSON" {
                $Json = Export-SharePointProvider -M365Environment commercial -AccessToken 'mock-access-token' -AdminUrl 'https://contoso-admin.sharepoint.com'
                $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
        }
    }
}
AfterAll {
    Remove-Module ExportSharePointProvider -Force -ErrorAction SilentlyContinue
    Remove-Module CommandTracker -Force -ErrorAction SilentlyContinue
}
