Import-Module -Name $PSScriptRoot/../Utility/Utility.psm1 -Function Invoke-GraphDirectly

function Export-SIProvider {
    <#
    .DESCRIPTION
        Gets the Super Intelligence (SI) and SI Agents settings that are relevant
        to the SCuBA SI baseline.
        This is a shell: no settings are exported yet.
    .PARAMETER M365Environment
        The M365 environment to run against (for example commercial, gcc, gcchigh, or dod).
        It selects the Graph endpoints used when retrieving the tenant configuration.
    .FUNCTIONALITY
        Internal
    #>

    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment
    )

    $HelperFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "ProviderHelpers"
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "CommandTracker.psm1")
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "LicenseHelper.psm1")
    $Tracker = Get-CommandTracker

    # Fetch license data
    $SubscribedSku = $Tracker.TryCommand("Get-MgBetaSubscribedSku", @{"M365Environment"=$M365Environment; "GraphDirect"=$true})
    # Determine if tenant has Copilot license based on subscribed SKUs/service plans
    $HasCopilotLicense = ConvertTo-Json (Get-CopilotLicense -SubscribedSku $SubscribedSku)

    $SuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $UnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

    $json = @"
    "has_copilot_license": $HasCopilotLicense,
    "si_successful_commands": $SuccessfulCommands,
    "si_unsuccessful_commands": $UnSuccessfulCommands,
"@

    $json
}
