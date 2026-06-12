param(
    [int]$Iterations = 30,
    [string]$OutputPath = "Testing/Performance/aadrisky-benchmark-baseline.json"
)

$ErrorActionPreference = "Stop"

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../PowerShell/ScubaGear/Modules/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module $modulePath -Force

$snippetsBase = Join-Path -Path $PSScriptRoot -ChildPath "../../PowerShell/ScubaGear/Testing/Unit/PowerShell/Providers/AADProvider/RiskyPermissionsSnippets"
$mockApplications = Get-Content (Join-Path $snippetsBase "MockApplications.json") -Raw | ConvertFrom-Json
$mockFederatedCredentials = Get-Content (Join-Path $snippetsBase "MockFederatedCredentials.json") -Raw | ConvertFrom-Json
$mockServicePrincipals = Get-Content (Join-Path $snippetsBase "MockServicePrincipals.json") -Raw | ConvertFrom-Json
$mockServicePrincipalAppRoleAssignments = Get-Content (Join-Path $snippetsBase "MockServicePrincipalAppRoleAssignments.json") -Raw | ConvertFrom-Json
$mockResourcePermissionCacheJson = Get-Content (Join-Path $snippetsBase "MockResourcePermissionCache.json") -Raw | ConvertFrom-Json

$mockResourcePermissionCache = @{}
foreach ($prop in $mockResourcePermissionCacheJson.PSObject.Properties) {
    $mockResourcePermissionCache[$prop.Name] = $prop.Value
}

# Global stubs for commands resolved outside the helper module.
function Get-ScubaGearPermissions {
    param(
        [string]$CmdletName,
        [string]$Environment,
        [string]$OutAs
    )

    $null = $CmdletName
    $null = $Environment

    if ($OutAs -eq "endpoint") {
        return "https://graph.microsoft.com"
    }

    return $null
}

function Invoke-MgGraphRequest {
    param(
        [string]$Method,
        [string]$Uri,
        [string]$Body
    )

    $null = $Method
    $null = $Uri

    $parsed = $Body | ConvertFrom-Json
    $responses = @()
    foreach ($request in $parsed.Requests) {
        $responses += [PSCustomObject]@{
            id = $request.id
            status = 200
            body = [PSCustomObject]@{
                value = $mockServicePrincipalAppRoleAssignments
            }
        }
    }

    return [PSCustomObject]@{ responses = $responses }
}

# Override the helper module's private Invoke-GraphDirectly within module session state.
$helperModule = Get-Module AADRiskyPermissionsHelper
& $helperModule {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'apps')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'feds')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'sps')]
    param($apps, $feds, $sps)

    function Invoke-GraphDirectly {
        param(
            [string]$commandlet,
            [string]$M365Environment,
            [hashtable]$QueryParams,
            [string]$ID,
            [object]$Body,
            [string]$Uri
        )

        $null = $M365Environment
        $null = $QueryParams
        $null = $Body
        $null = $Uri

        if ($commandlet -eq "Get-MgBetaApplication") {
            return [PSCustomObject]@{
                value = $apps
                '@odata.context' = 'https://graph.microsoft.com/beta/$metadata#applications'
            }
        }

        if ($commandlet -eq "Get-MgBetaApplicationFederatedIdentityCredential") {
            return [PSCustomObject]@{
                value = $feds
                '@odata.context' = "https://graph.microsoft.com/beta/`$metadata#applications/$ID/federatedIdentityCredentials"
            }
        }

        if ($commandlet -eq "Get-MgBetaServicePrincipal") {
            return [PSCustomObject]@{
                value = $sps
                '@odata.context' = 'https://graph.microsoft.com/beta/$metadata#servicePrincipals'
            }
        }

        return [PSCustomObject]@{ value = $null }
    }
} -ArgumentList $mockApplications, $mockFederatedCredentials, $mockServicePrincipals

function Get-Stats {
    param([double[]]$Data)
    [PSCustomObject]@{
        MeanMs = [Math]::Round((($Data | Measure-Object -Average).Average), 2)
        MinMs = [Math]::Round((($Data | Measure-Object -Minimum).Minimum), 2)
        MaxMs = [Math]::Round((($Data | Measure-Object -Maximum).Maximum), 2)
    }
}

$appTimes = New-Object System.Collections.Generic.List[double]
$spTimes = New-Object System.Collections.Generic.List[double]

for ($i = 1; $i -le $Iterations; $i++) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $null = Get-ApplicationsWithRiskyPermissions -M365Environment "gcc" -ResourcePermissionCache $mockResourcePermissionCache
    $sw.Stop()
    $appTimes.Add($sw.Elapsed.TotalMilliseconds)

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $null = Get-ServicePrincipalsWithRiskyPermissions -M365Environment "gcc" -ResourcePermissionCache $mockResourcePermissionCache
    $sw.Stop()
    $spTimes.Add($sw.Elapsed.TotalMilliseconds)
}

$result = [PSCustomObject]@{
    Timestamp = (Get-Date).ToString("o")
    Iterations = $Iterations
    Cmdlets = [PSCustomObject]@{
        GetApplicationsWithRiskyPermissions = Get-Stats -Data $appTimes.ToArray()
        GetServicePrincipalsWithRiskyPermissions = Get-Stats -Data $spTimes.ToArray()
    }
}

$resultDir = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($resultDir) -and -not (Test-Path $resultDir)) {
    New-Item -ItemType Directory -Path $resultDir -Force | Out-Null
}

$result | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
$result | Format-List | Out-String | Write-Output
Write-Output "Baseline benchmark saved to $OutputPath"

Remove-Module AADRiskyPermissionsHelper -Force -ErrorAction SilentlyContinue
