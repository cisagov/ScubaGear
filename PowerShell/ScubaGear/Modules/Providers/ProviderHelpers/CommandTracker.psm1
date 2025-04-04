Import-Module -Name $PSScriptRoot/../ExportEXOProvider.psm1 -Function Get-ScubaSpfRecord, Get-ScubaDkimRecord, Get-ScubaDmarcRecord
Import-Module -Name $PSScriptRoot/../ExportAADProvider.psm1 -Function Get-PrivilegedRole, Get-PrivilegedUser
Import-Module -Name $PSScriptRoot/AADRiskyPermissionsHelper.psm1 -Function Get-ApplicationsWithRiskyPermissions, Get-ServicePrincipalsWithRiskyPermissions, Format-RiskyApplications, Format-RiskyThirdPartyServicePrincipals
Import-Module -Name $PSScriptRoot/../../Utility/Utility.psm1 -Function Invoke-GraphDirectly, ConvertFrom-GraphHashtable

class CommandTracker {
    [string[]]$SuccessfulCommands = @()
    [string[]]$UnSuccessfulCommands = @()

    [System.Object[]] TryCommand([string]$Command, [hashtable]$CommandArgs) {
        <#
        .Description
        Wraps the given Command inside a try/catch, run with the provided
        arguments, and tracks successes/failures. Unless otherwise specified,
        ErrorAction defaults to "Stop"
        .Functionality
        Internal
        #>

        if (-Not $CommandArgs.ContainsKey("ErrorAction")) {
            $CommandArgs.ErrorAction = "Stop"
        }

        if ($CommandArgs['GraphDirect'] -eq $true) {
            # This will pull the Graph API vice the PowerShell module
            try {
                # Remove GraphDirect Key, this is just needed to trigger the logic
                $CommandArgs.Remove("GraphDirect")
                Write-Verbose "Running $($Command) API Call"
                $ModCommand = Invoke-GraphDirectly -Commandlet $Command @CommandArgs
                $Result = $ModCommand
                $this.SuccessfulCommands += $Command

                # Check if $Result.value exists, if it does, return it if not return just $Result
                if ($Result.value) {
                    $Result = $Result.value
                }else{
                    $Result = $Result
                }

                return $Result
            }
            catch {
                Write-Warning "Error running $($Command): $($_.Exception.Message)`n$($_.ScriptStackTrace)"
                $this.UnSuccessfulCommands += $Command
                $Result = @()
                return $Result
            }
        }else{
            if($CommandArgs.Contains("GraphDirect")) {
                $CommandArgs.Remove("M365Environment")
                $CommandArgs.Remove("GraphDirect") # Remove the GraphDirect key to avoid confusion when calling PowerShell commands. This should only be used for API calls.
            }
            try {
                Write-Verbose "Running $($Command) with arguments: $($CommandArgs)"
                $Result = & $Command @CommandArgs
                $this.SuccessfulCommands += $Command
                return $Result
            }
            catch {
                Write-Warning "Error running $($Command): $($_.Exception.Message)`n$($_.ScriptStackTrace)"
                $this.UnSuccessfulCommands += $Command
                $Result = @()
                return $Result
            }
        }
    }

    [System.Object[]] TryCommand([string]$Command) {
        <#
        .Description
        Wraps the given Command inside a try/catch and tracks successes/
        failures. No command arguments are specified beyond ErrorAction=Stop
        .Functionality
        Internal
        #>

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

function Get-CommandTracker {
    [CommandTracker]::New()
}