function Copy-ScubaBaselineDocument {
    <#
    .SYNOPSIS
    Execute the SCuBAGear tool security baselines for specified M365 products.
    .Description
    This is the main function that runs the Providers, Rego, and Report creation all in one PowerShell script call.
    .Parameter ProductName
    A list of one or more M365 shortened product names that the tool will assess when it is executed. Acceptable product name values are listed below.
    To assess Azure Active Directory you would enter the value aad.
    To assess Exchange Online you would enter exo and so forth.
    - Azure Active Directory: aad
    - Defender for Office 365: defender
    - Exchange Online: exo
    - MS Power Platform: powerplatform
    - SharePoint Online: sharepoint
    - MS Teams: teams.
    Use '*' to run all baselines.
    .Example
    Invoke-SCuBA
    .Functionality
    Public
    #>
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", IgnoreCase = $false)]
        [string]
        $ProductName = "",
        [Parameter(Mandatory = $false)]
        [ValidateScript({Test-Path -Path $_ -IsValid})]
        [string]
        $Destination = (Join-Path -Path $env:USERPROFILE -ChildPath "ScubaGear"),
        [Parameter(Mandatory = $false)]
        [switch]
        $Force
    )

    if (-not (Test-Path -Path $Destination -PathType Container)){
        New-Item -ItemType Directory -Path $Destination
    }

    if ($ProductName){
        $FilesToGet = @($ProductName)
    }
    else{
        $FilesToGet = @("teams", "exo", "defender", "aad", "powerplatform", "sharepoint")
    }

    ForEach($Item in $FilesToGet){
        $FileName = Join-Path -Path $PSScriptRoot -ChildPath "$Item.md"
        Copy-Item -Path $FileName -Destination $Destination -Force:$Force
    }
}