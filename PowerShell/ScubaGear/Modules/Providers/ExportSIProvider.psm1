function Export-SIProvider {
    <#
    .Description
    Gets the Super Intelligence (SI) and SI Agents settings that are relevant
    to the SCuBA SI baseline.
    This is a shell: no settings are exported yet.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param ()

    $HelperFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "ProviderHelpers"
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "CommandTracker.psm1")
    $Tracker = Get-CommandTracker

    $SuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $UnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

    $json = @"
    "si_successful_commands": $SuccessfulCommands,
    "si_unsuccessful_commands": $UnSuccessfulCommands,
"@

    $json
}
