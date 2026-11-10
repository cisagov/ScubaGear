<#
.SYNOPSIS
    As an aid to cleanup, this script generates a list of module dependencies for retired releases of 
    ScubaGear with the aim of targeting modules that are no longer required to run the current release of ScubaGear.

.DESCRIPTION
    Generates a list of the module dependencies for retired releases of ScubaGear, optionally fetched
    dynamically, for versions specified in ReleaseTags. A list of the release tags of major releases of 
    ScubaGear, taken from the ScubaGear repository in GitHub, is the default. The primary input is an array 
    of strings reflecting release tags, and the output is an array of strings reflecting module names.

.EXAMPLE
    . .\RetiredDependencies.ps1 -ReleaseTags "v1.0.0","v1.5.0" -Online $true

    .EXAMPLE
    . .\RetiredDependencies.ps1 -AllowCurrent $true -Online $false

.PARAMETER ReleaseTags
    The release tags for a set of retired versions to clean up. The default set is all releases after 
    v0.1.0 and prior to the current release of ScubaGear, derived from:
    https://github.com/cisagov/ScubaGear/tags .
.PARAMETER Online
    Default: $false. Indicates whether to fetch the set of module dependencies dynamically from the GitHub repository.
.PARAMETER AllowCurrent
    Default: $false. Indicates whether to include a dependency for a retired release that is also a 
    dependency of the current  release, which may necessitate running the Reset-ScubaGearDependencies 
    function after cleanup is done.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("v0.2.0","v0.2.1","0.3.0","v1.0.0","v1.1.0","v1.1.1","v1.2.0","v1.3.0","v1.4.0",
        "v1.5.0","v1.6.0","v1.7.0","v1.7.1","v1.8.0")]
    [string[]] $ReleaseTags = @(
        "v0.2.0",
        "v0.2.1",
        "0.3.0",
        "v1.0.0",
        "v1.1.0",
        "v1.1.1",
        "v1.2.0",
        "v1.3.0",
        "v1.4.0",
        "v1.5.0",
        "v1.6.0",
        "v1.7.0",
        "v1.7.1",
        "v1.8.0"
    ),
    [bool]$Online = $false,
    [bool]$AllowCurrent = $false
)
# v2.0.0 dependencies for ScubaGear
[string[]]$CurrentModuleNames = @(
    "Microsoft.Graph.Authentication",
    "powershell-yaml"
) 
# Pre- v2.0.0 dependencies for ScubaGear
[string[]] $StaticModuleList = @(
    "ExchangeOnlineManagement",
    "Microsoft.Graph.Applications",
    "Microsoft.Graph.Authentication",
    "Microsoft.Graph.Beta.Applications",
    "Microsoft.Graph.Beta.DirectoryObjects",
    "Microsoft.Graph.Beta.Groups",
    "Microsoft.Graph.Beta.Identity.DirectoryManagement",
    "Microsoft.Graph.Beta.Identity.Governance",
    "Microsoft.Graph.Beta.Identity.SignIns",
    "Microsoft.Graph.Beta.Users",
    "Microsoft.Graph.DeviceManagement",
    "Microsoft.Graph.DeviceManagement.Administration",
    "Microsoft.Graph.DeviceManagement.Enrolment",
    "Microsoft.Graph.Devices.CorporateManagement",
    "Microsoft.Graph.Groups",
    "Microsoft.Graph.Identity.DirectoryManagement",
    "Microsoft.Graph.Identity.Governance",
    "Microsoft.Graph.Identity.SignIns",
    "Microsoft.Graph.Planner",
    "Microsoft.Graph.Teams",
    "Microsoft.Graph.Users",
    "Microsoft.Online.SharePoint.PowerShell",
    "Microsoft.PowerApps.Administration.PowerShell",
    "Microsoft.PowerApps.PowerShell",
    "MicrosoftTeams",
    "PnP.PowerShell",
    "powershell-yaml"
)
if ($Online) {
    Write-Verbose "Online mode is enabled. Downloading RequiredVersions.ps1 for each version tag in $ReleaseTags."
    $ModuleList         = @()
    $ModuleListCombined = @()
    $FirstPass, $SecondPass = $true,$false
    foreach  ($ReleaseTag in $ReleaseTags) {
        $Uri = "https://raw.githubusercontent.com/cisagov/ScubaGear/refs/tags/$ReleaseTag/PowerShell/ScubaGear/RequiredVersions.ps1"
        try {
            if ($SecondPass) {
                Write-Verbose "Waiting 1 second between downloads."
                $SecondPass = $false
            }
            if ($FirstPass) {
                $FirstPass, $SecondPass = $false,$true
            }
            Start-Sleep -Seconds 1
            Write-Verbose "Fetching RequiredVersions.ps1 with tag $ReleaseTag."            
            Invoke-Expression (Invoke-WebRequest -Uri $Uri).Content
        }
        catch {
            Write-Error "An error occurred downloading $Uri : $($_.Exception.Message)"
        }
        foreach ($Module in $ModuleList) {
            if ($Module -and -not ($ModuleListCombined -contains $Module)) {
                $ModuleListCombined += $ModuleList | Select-Object ModuleName
            }
        }
    }
} else {
    Write-Verbose ("Online mode is disabled. A sorted list of modules from retired ScubaGear versions will " +
    "be fetched statically.")
    if ( $($PSBoundParameters.ContainsKey('ReleaseTags'))) {
        Write-Warning ("ReleaseTags parameter was passed, but will be ignored. Use -Online $True to receive " +
        "results for the specified version tags.")
    }
    $ModuleListCombined = @{
        ModuleName = @(
            $StaticModuleList
        )
    }
}
# Limit results by AllowCurrent parameter
$Result = $ModuleListCombined.ModuleName | 
    Where-Object { 
        $AllowCurrent -eq $true -or $_ -notin @( $CurrentModuleNames ) 
    } | Sort-Object -Unique
# Return results
$Result
