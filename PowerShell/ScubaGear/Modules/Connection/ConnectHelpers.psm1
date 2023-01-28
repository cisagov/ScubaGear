function Connect-EXOHelper {
    <#
    .Description
    This function is used for assisting in connecting to different M365 Environments for EXO.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [string]
        $M365Environment
    )
    switch ($M365Environment) {
        {($_ -eq "commercial") -or ($_ -eq "gcc")} {
            Connect-ExchangeOnline -ShowBanner:$false -ErrorAction "Stop" | Out-Null
        }
        "gcchigh" {
            Connect-ExchangeOnline -ShowBanner:$false -ExchangeEnvironmentName "O365USGovGCCHigh" -ErrorAction "Stop" | Out-Null
        }
        "dod" {
            Connect-ExchangeOnline -ShowBanner:$false -ExchangeEnvironmentName "O365USGovDoD" -ErrorAction "Stop" | Out-Null
        }

    }
}

function Connect-DefenderHelper {
    <#
    .Description
    This function is used for assisting in connecting to different M365 Environments for EXO.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [string]
        $M365Environment
    )
    $IPPSParams = @{
        'ErrorAction' = 'Stop';
    }
    switch ($M365Environment) {
        "gcchigh" {
            $IPPSParams = $IPPSParams + @{'ConnectionUri' = "https://outlook.office365.us/powershell-liveID";}
        }
        "dod" {
            $IPPSParams = $IPPSParams + @{'ConnectionUri' = "https://webmail.apps.mil/powershell-liveID";}
        }
    }
    Connect-IPPSSession @IPPSParams | Out-Null
}

Export-ModuleMember -Function @(
    'Connect-EXOHelper',
    'Connect-DefenderHelper'
)