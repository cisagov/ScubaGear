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
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [hashtable]
        $ServicePrincipalParams
    )
    $EXOParams = @{
        ErrorAction = "Stop";
        ShowBanner = $false;
    }
    switch ($M365Environment) {
        "gcchigh" {
            $EXOParams += @{'ExchangeEnvironmentName' = "O365USGovGCCHigh";}
        }
        "dod" {
            $EXOParams += @{'ExchangeEnvironmentName' = "O365USGovDoD";}
        }
    }

    if ($ServicePrincipalParams.CertThumbprintParams) {
        $EXOParams += $ServicePrincipalParams.CertThumbprintParams
    }
    Connect-ExchangeOnline @EXOParams | Out-Null
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
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [hashtable]
        $ServicePrincipalParams
    )
    $IPPSParams = @{
        'ErrorAction' = 'Stop';
    }
    switch ($M365Environment) {
        "gcchigh" {
            $IPPSParams += @{'ConnectionUri' = "https://ps.compliance.protection.office365.us/powershell-liveid";}
            $IPPSParams += @{'AzureADAuthorizationEndpointUri' = "https://login.microsoftonline.us/common";}
        }
        "dod" {
            $IPPSParams += @{'ConnectionUri' = "https://l5.ps.compliance.protection.office365.us/powershell-liveid";}
            $IPPSParams += @{'AzureADAuthorizationEndpointUri' = "https://login.microsoftonline.us/common";}
        }
    }
    if ($ServicePrincipalParams.CertThumbprintParams) {
        $IPPSParams += $ServicePrincipalParams.CertThumbprintParams
    }
    Connect-IPPSSession @IPPSParams | Out-Null
}

Export-ModuleMember -Function @(
    'Connect-EXOHelper',
    'Connect-DefenderHelper'
)