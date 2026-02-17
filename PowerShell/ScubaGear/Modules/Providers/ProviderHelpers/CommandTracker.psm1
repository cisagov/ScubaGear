Import-Module -Name $PSScriptRoot/../ExportEXOProvider.psm1 -Function Get-ScubaSpfRecord, Get-ScubaDkimRecord, Get-ScubaDmarcRecord
Import-Module -Name $PSScriptRoot/../ExportAADProvider.psm1 -Function Get-PrivilegedRole, Get-PrivilegedUser
Import-Module -Name $PSScriptRoot/AADRiskyPermissionsHelper.psm1 -Function Get-ApplicationsWithRiskyPermissions, Get-ServicePrincipalsWithRiskyPermissions, Format-RiskyApplications, Format-RiskyThirdPartyServicePrincipals
Import-Module -Name $PSScriptRoot/../../Utility/Utility.psm1 -Function Invoke-GraphDirectly, ConvertFrom-GraphHashtable

class CommandTracker {
    [string[]]$SuccessfulCommands = @()
    [string[]]$UnSuccessfulCommands = @()

    [System.Object[]] TryCommand([string]$Command, [hashtable]$CommandArgs, [bool]$SuppressWarning = $false) {
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

        $isGraphDirect = $false
        $Result = @()

        # Pre-process command arguments
        if ($CommandArgs.ContainsKey("GraphDirect")) {
            # Check if GraphDirect is set to true, if so set $isGraphDirect to true and remove the key. This will make a Graph API call using Invoke-GraphDirectly
            $isGraphDirect = $CommandArgs['GraphDirect'] -eq $true
            $CommandArgs.Remove("GraphDirect") # Remove GraphDirect as it is not needed for the command, its just a flag to indicate we want to use the Graph API directly

            if (-not $isGraphDirect) {
                # For standard PowerShell commands, remove M365Environment if present
                $CommandArgs.Remove("M365Environment")
            }
        }

        try {
            if ($isGraphDirect) {
                # This will pull the Graph API vice the PowerShell module
                Write-Verbose "Running $($Command) API Call"
                $ModCommand = Invoke-GraphDirectly -Commandlet $Command @CommandArgs
                $Result = $ModCommand

                # Check if $Result.value exists, if it does, return it if not return just $Result
                if ($Result.value) {
                    $Result = $Result.value
                }
            }
            else {
                Write-Verbose "Running $($Command) with arguments: $($CommandArgs)"
                $Result = & $Command @CommandArgs
            }

            $this.SuccessfulCommands += $Command
        }
        catch {
            if (-not $SuppressWarning) {
                Write-Warning "Error running $($Command): $($_.Exception.Message)`n$($_.ScriptStackTrace)"
            }

            $this.UnSuccessfulCommands += $Command
            $Result = @()
        }

        return $Result
    }

    [System.Object[]] TryCommand([string]$Command, [hashtable]$CommandArgs) {
        <#
        .Description
        Wraps the given Command inside a try/catch, run with the provided
        arguments, and tracks successes/failures. SuppressWarning defaults to false.
        .Functionality
        Internal
        #>

        return $this.TryCommand($Command, $CommandArgs, $false)
    }

    [System.Object[]] TryCommand([string]$Command) {
        <#
        .Description
        Wraps the given Command inside a try/catch and tracks successes/
        failures. No command arguments are specified beyond ErrorAction=Stop
        .Functionality
        Internal
        #>

        return $this.TryCommand($Command, @{}, $false)
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