<#
 # Due to how the Error handling was implemented, mocked API calls have to be mocked inside a
 # mocked CommandTracker class
#>

$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportDefenderProvider.psm1") -Function Export-DefenderProvider -Force

InModuleScope -ModuleName ExportDefenderProvider {
    Describe -Tag 'ExportDefenderProvider' -Name "Export-DefenderProvider" -ForEach @(
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
                            "Get-HostedContentFilterPolicy" {
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
            Mock -ModuleName ExportDefenderProvider Import-Module {}
            function Get-CommandTracker {}
            Mock -ModuleName ExportDefenderProvider Get-CommandTracker {
                return [MockCommandTracker]::New()
            }
            function Connect-EXOHelper {}
            Mock -ModuleName ExportDefenderProvider Connect-EXOHelper {}
            function Connect-DefenderHelper {}
            Mock -ModuleName ExportDefenderProvider Connect-DefenderHelper {}
            function Get-OrganizationConfig {}
            Mock -ModuleName ExportDefenderProvider Get-OrganizationConfig { [pscustomobject]@{
                    "mockkey" = "mockvalue";
                } }
            function Get-SafeAttachmentPolicy {}
            Mock -ModuleName ExportDefenderProvider Get-SafeAttachmentPolicy {}
            function Get-AtpPolicyForO365 {throw 'this will be mocked'}
            Mock -ModuleName ExportDefenderProvider Get-AtpPolicyForO365 {}
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
            $Json = Export-DefenderProvider -M365Environment $_
            $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
    }
}
AfterAll {
    Remove-Module ExportDefenderProvider -Force -ErrorAction SilentlyContinue
    Remove-Module CommandTracker -Force -ErrorAction SilentlyContinue
}
