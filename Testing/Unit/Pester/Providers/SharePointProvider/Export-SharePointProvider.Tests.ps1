<#
 # Due to how the Error handling was implemented mocked API calls have to be mocked inside a
 # mocked CommandTracker class
#>
BeforeAll {
    Import-Module ../../../../../PowerShell/ScubaGear/Modules/Providers/ExportSharePointProvider.psm1 -Force
    Import-Module ../../../../../PowerShell/ScubaGear/Modules/Providers/ProviderHelpers/CommandTracker.psm1 -Force
}
Describe "Export-SharePointProvider" {
        InModuleScope -ModuleName ExportSharePointProvider {
        BeforeEach {
            class MockCommandTracker {
                [string[]]$SuccessfulCommands = @()
                [string[]]$UnSuccessfulCommands = @()
        
                [System.Object[]] TryCommand([string]$Command, [hashtable]$CommandArgs) {
                    if (-Not $CommandArgs.ContainsKey("ErrorAction")) {
                        $CommandArgs.ErrorAction = "Stop"
                    }
                # This is where you start mocking your functions
                try {
                    switch ($Command) {
                        "Get-MgOrganization" {
                            $this.SuccessfulCommands += $Command
                            return $this.MockGetMgOrganization()
                        }
                        "Get-SPOSite" {
                            $this.SuccessfulCommands += $Command
                            return $this.MockGetSPOSite()
                        }
                        "Get-SPOTenant" {
                            $this.SuccessfulCommands += $Command
                            return $this.MockGetSPOTenant()
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

            # note how each function is mocked here
            [System.Object[]] MockGetMgOrganization() {
                return [pscustomobject]@{
                    VerifiedDomains = @(
                        @{
                            "isInitial" = $true;
                            "Name" = "contoso.onmicrosoft.com";
                        }
                        @{
                            "isInitial" = $false;
                            "Name" = "example.onmicrosoft.com";
                        }
                        )
                    } 
            }

            [System.Object[]] MockGetSPOSite() {
                return [pscustomobject]@{
                    sharepointsite = "sharepointSite"
                }
            }

            [System.Object[]] MockGetSPOTenant() {
                return [pscustomobject]@{
                    sharepointsite = "sharepointtenant"
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

        Mock -ModuleName ExportSharePointProvider Get-CommandTracker {
            return [MockCommandTracker]::New()
        }
    }
    It "When running interactively with PnPFlag set to 'false' it should return JSON" {
        $json = Export-SharePointProvider -M365Environment gcc
        $json = $json.TrimEnd(",")
        $json = "{$($json)}"
        $ValidJson = $true
        try {
            ConvertFrom-Json $json -ErrorAction Stop
        }
        catch {
            $ValidJson = $false;
        }
        $ValidJson| Should -Be $true
    }

    It "When running with Service Principals and PnPFlag set to 'true' it should return JSON" { #todo convert this to PnP
        $json = Export-SharePointProvider -M365Environment commercial
        $json = $json.TrimEnd(",")
        $json = "{$($json)}"
        $ValidJson = $true
        try {
            ConvertFrom-Json $json -ErrorAction Stop
        }
        catch {
            $ValidJson = $false;
        }
        $ValidJson| Should -Be $true
    }
}
}

