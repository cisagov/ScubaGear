<#
 # Due to how the Error handling was implemented, mocked API calls have to be mocked inside a
 # mocked CommandTracker class
#>

$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportSecuritySuiteProvider.psm1") -Function Export-SecuritySuiteProvider -Force

InModuleScope -ModuleName ExportSecuritySuiteProvider {
    Describe -Tag 'ExportSecuritySuiteProvider' -Name "Export-SecuritySuiteProvider" -ForEach @(
        "commercial",
        "gcc",
        "gcchigh",
        "dod"
    ){
        BeforeAll {
            class MockCommandTracker {
                [string[]]$SuccessfulCommands = @()
                [string[]]$UnSuccessfulCommands = @()

                [System.Object[]] TryCommand([string]$Command, [hashtable]$CommandArgs) {
                    # This is where you decide where you mock functions called by CommandTracker :)
                    try {
                        switch ($Command) {
                            "Get-AdminAuditLogConfig" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-EOPProtectionPolicyRule" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-MalwareFilterPolicy" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-AntiPhishPolicy" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-HostedConnectionFilterPolicy" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-AcceptedDomain" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-SafeAttachmentPolicy" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-SafeAttachmentRule" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-SafeLinksPolicy" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-SafeLinksRule" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-AtpPolicyForO365" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-DlpCompliancePolicy" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-DlpComplianceRule" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-ProtectionAlert" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-ATPProtectionPolicyRule" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-MgBetaUser" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
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
            Mock -ModuleName ExportSecuritySuiteProvider Import-Module {}
            function Get-CommandTracker {}
            Mock -ModuleName ExportSecuritySuiteProvider Get-CommandTracker {
                return [MockCommandTracker]::New()
            }
            function Connect-EXOHelper {}
            Mock -ModuleName ExportSecuritySuiteProvider Connect-EXOHelper {}
            function Connect-DefenderHelper {}
            Mock -ModuleName ExportSecuritySuiteProvider Connect-DefenderHelper {}
            function Get-OrganizationConfig {}
            Mock -ModuleName ExportSecuritySuiteProvider Get-OrganizationConfig { [pscustomobject]@{
                    "mockkey" = "mockvalue";
                } }
            function Get-SafeAttachmentPolicy {}
            Mock -ModuleName ExportSecuritySuiteProvider Get-SafeAttachmentPolicy {}
            function Get-AtpPolicyForO365 {throw 'this will be mocked'}
            Mock -ModuleName ExportSecuritySuiteProvider Get-AtpPolicyForO365 {}
            function Get-MgBetaUser {}
            Mock -ModuleName ExportSecuritySuiteProvider Get-MgBetaUser {}
            # Added to silence tenant warning on O365 and DLP 
            Mock -ModuleName ExportSecuritySuiteProvider Get-Command {
                [pscustomobject]@{ Name = @($Name)[0] }
            } -ParameterFilter {
                @($Name)[0] -in @(
                    "Get-AtpPolicyForO365",
                    "Get-DlpCompliancePolicy"
                )
            }

            function Write-ScubaLog {}
            Mock -ModuleName ExportSecuritySuiteProvider Write-ScubaLog {}

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
        It "When called with -M365Environment '<_>', returns valid JSON" {
            $Json = Export-SecuritySuiteProvider -M365Environment $_
            $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
    }
}
AfterAll {
    Remove-Module ExportSecuritySuiteProvider -Force -ErrorAction SilentlyContinue
    Remove-Module CommandTracker -Force -ErrorAction SilentlyContinue
}
