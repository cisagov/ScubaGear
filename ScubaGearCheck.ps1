<#
    .Synopsis
        Script that helps automatically run ScubaGear functional tests against a given baseline.

    .Description
        This script parameterizes values to allow a tester to target functional testing of one
        ScubaGear baseline against a specified test tenant using either user-based or service
        principal authentication.

    .Parameter Baseline
        Specifies the name of the SCuBA M365 baseline to test. Only tests associated with this
        baseline will be run.
        Valid baseline values are 'aad', 'defender', 'exo', 'powerplatform', 'sharepoint', and 'teams'.

    .Parameter Filter
        Regular expression string used to filter tests based on their tag.  Test are tagged with their
        policy IDs such that a valid filter regular expression should be of the same form as a policy
        ID.  Examples include "MS.AAD.1.1v1", "MS.EXO.[123]*", and "MS.DEFENDER.[24].*v*"

    .Parameter ScubaHome
        The root of the ScubaGear project folder under which the ScubaGear functional tests are stored.
        Default: '.' (current folder)

    .Parameter Tenant
        Integer specifying the index of the test tenant to target for functional testing run.
        Tenants values are:
            1 - cisaent (CISA G5 GCC)
            2 - scubag3forthee (CISA G3 GCC)
            3 - y2zj1 (MITRE E5 Commercial)
            4 - vt02s (Sandia E5 Commercial)
            5 - Mitredev (MITRE E3 + AAD P1 Commercial)
            6 - scubagcchigh (CISA G5 GCC High)
        Tenant 1 (cisaent) is the default test tenant.

    .Parameter Thumbprint
        Hexadecimal string that represents the fingerprint of an X509 certificate associated with both
        a service principal in the test tenant and a private key stored on the executing test machine.
        Specifying a thumbprint causes the functional testing to use the thumbprint for service principal
        authentication to the test tenant.  By default, when no thumbprint is specified, user authentication
        is used.

    .Parameter UserAuth
        Boolean switch that indicates whether user authentication should be used when a thumbprint is
        already defined. If a thumbprint is not defined, this switch has no effect as the script will
        default to user authentication.

    .Parameter Variant
        Test plan variant to be run by the functional testing script. Not all variants are present in
        each product.  A blank or unspecified variant will run the standard baseline test plan.
        Valid variants are 'e#', 'gcc', 'g3', 'g5', 'pnp', and 'spo'.

    .Example
        .\ScubaGearCheck.ps1 -Baseline aad -Thumbprint 0123456789abcdeffdecba98765432101111ba22
        Runs every standard functional test for Azure AD using a service principal that
        accepts the certificate identified by the given thumbprint against test tenant 1 (default).

    .Example
        .\ScubaGearCheck.ps1 -Baseline powerplatform -Variant pnp -ScubaHome git\ScubaGear -Tenant 6
        Runs every pnp variant functional test for Power Platform using user authentication
        specifying the tests exist under the git\ScubaGear folder against GCC high test tenant.

    .Example
        .\ScubaGearCheck.ps1 -Baseline defender -Variant g3 -Filter "MS.DEFENDER.[24]*" -UserAuth -Tenant 2
        Run all g3 variant functional tests for defender that match the given filter using
        user authentication against G3 test tenant.
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("aad", "defender", "exo", "powerplatform", "sharepoint", "teams")]
    [string]
    $Baseline,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Filter = "",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ScubaHome = ".",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateRange(1, 6)]
    [int32]
    $Tenant = 1,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Thumbprint = "<ADD_YOUR_THUMBPRINT_HERE>",   # Set default to your thumbprint to make it easier to use

    [Parameter(Mandatory = $false)]
    [switch]
    $UserAuth = $false,

    [Parameter(Mandatory = $false)]
    [ValidateSet("", "e#", "g3", "g5", "gcc", "pnp", "spo")]
    [string]
    $Variant = ""
)

try {
    $TestPath = Join-Path -Path $ScubaHome -ChildPath "Testing/Functional/Products" -Resolve -ErrorAction Stop
}
catch [System.Management.Automation.ItemNotFoundException] {
    Write-Error("Functional test path not found or does not exist: $ScubaHome\$TestPath")
    exit(-1)
}

# Default to user auth when no thumbprint is present
# even if user auth not enabled
if(-Not $UserAuth -And -Not $Thumbprint) {
    $UserAuth = $true
}

# Fail if tenant index is not currently implemented
if($Tenant -eq 4 -Or $Tenant -eq 5) {
    $TenantError = "Automated testing for test tenant specified not available.`r`n"
    $TenantError += "Please specify a different test tenant."

    Write-Error($TenantError)
    exit(-2)
}

if($Variant -eq "pnp" -Or $Variant -eq "spo" -And $Baseline -ne "sharepoint") {
    $VariantError = "$Variant is only valid for the SharePoint/OneDrive baseline.`r`n"
    $VariantError += "Please select another variant or choose the sharepoint baseline."

    Write-Error($VariantError)
    exit(-4)
}

$TestContainers = @()

##--
# Tenant 1 - CISA G5 (cisaent)
##--

if($Tenant -eq 1) {

    if(-Not $UserAuth) {
        # Test in CISA G5 tenant using service principal
        $TestContainers += New-PesterContainer -Path $TestPath -Data @{ Thumbprint = $Thumbprint; TenantDomain = "cisaent.onmicrosoft.com"; TenantDisplayName = "Cybersecurity and Infrastructure Security Agency"; AppId = "29730b8be22241afa94f905bcdeaf7a3"; ProductName = $Baseline; M365Environment = "gcc"; Variant=$Variant }
    }
    else {
        # Test in CISA G5 tenant using user credentials
        $TestContainers += New-PesterContainer -Path $TestPath -Data @{ TenantDomain = "cisaent.onmicrosoft.com"; TenantDisplayName = "Cybersecurity and Infrastructure Security Agency"; ProductName = $Baseline; M365Environment = "gcc"; Variant=$Variant }
    }
}
##--

##--
# Tenant 2 - CISA G3 (scubag3forthee)
##--

if($Tenant -eq 2) {

    if(-Not $UserAuth) {
        # Test in CISA G3 tenant using service principal
        $TestContainers += New-PesterContainer -Path $TestPath -Data @{ Thumbprint = $Thumbprint; TenantDomain = "scubag3forthee.onmicrosoft.com"; TenantDisplayName = "SCuBA G3 For Thee"; AppId = "ed2cb57b92084abeb99c3acf35c91f5f"; ProductName = $Baseline; M365Environment = "gcc";  Variant=$Variant}
    }
    else {
        # Test in CISA G3 tenant using user credentials
        $TestContainers += New-PesterContainer -Path $TestPath -Data @{ TenantDomain = "scubag3forthee.onmicrosoft.com"; TenantDisplayName = "SCuBA G3 For Thee"; ProductName = $Baseline; M365Environment = "gcc"; Variant=$Variant }
    }
}

##--

##--
# Tenant 3 - MITRE E5 (y2zj1)
##--
if($Tenant -eq 3) {

    if(-Not $UserAuth) {
        # Test in MITRE E5 tenant using service principal
        $TestContainers += New-PesterContainer -Path $TestPath -Data @{ Thumbprint = $Thumbprint; TenantDomain = "y2zj1.onmicrosoft.com"; TenantDisplayName = "y2zj1"; AppId = "db791fde1ff0493fbe3d03d9ba6cb087"; ProductName = $Baseline; M365Environment = "commercial"; Variant=$Variant }
    }
    else {
        # Test in MITRE E5 tenant using user credentials
        $TestContainers += New-PesterContainer -Path $TestPath -Data @{ TenantDomain = "y2zj1.onmicrosoft.com"; TenantDisplayName = "y2zj1"; ProductName = $Baseline; M365Environment = "commercial"; Variant=$Variant }
    }
}
##--

##--
# CISA G5 GCC high (scubagcchigh)
##--
if($Tenant -eq 6) {

    if(-Not $UserAuth) {
        # Test in CISA G5 high tenant using service principal
        $TestContainers += New-PesterContainer -Path $TestPath -Data @{ Thumbprint = $Thumbprint; TenantDomain = "scubagcchigh.onmicrosoft.us"; TenantDisplayName = "scubagcchigh"; AppId = "0734a54de2c84bccb074639f39e35fd7"; ProductName = $Baseline; M365Environment = "gcchigh"; Variant=$Variant }
    }
    else {
        # Test in CISA G5 high tenant using user credentials
        $TestContainers += New-PesterContainer -Path $TestPath -Data @{ TenantDomain = "scubagcchigh.onmicrosoft.us"; TenantDisplayName = "scubagcchigh"; ProductName = $Baseline; M365Environment = "gcchigh"; Variant=$Variant }
    }
}

$PesterConfig = @{
    Run = @{
        Container = $TestContainers
    }
    Filter = @{
        Tag = @($Filter)
    }
    Output = @{
        Verbosity = 'Detailed'
    }
    Debug = @{
        ShowFullErrors = $false
        WriteDebugMessages = $true
    }
}

$Config = New-PesterConfiguration -Hashtable $PesterConfig
Invoke-Pester -Configuration $Config