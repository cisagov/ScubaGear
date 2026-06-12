param(
    [Parameter(Mandatory = $true)]
    [string]$BaselinePath,

    [Parameter(Mandatory = $true)]
    [string]$PostPath
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $BaselinePath)) {
    throw "Baseline file not found: $BaselinePath"
}
if (-not (Test-Path $PostPath)) {
    throw "Post-change file not found: $PostPath"
}

$baseline = Get-Content -Path $BaselinePath -Raw | ConvertFrom-Json
$post = Get-Content -Path $PostPath -Raw | ConvertFrom-Json

$functions = @(
    "Get-ApplicationsWithRiskyPermissions",
    "Get-ServicePrincipalsWithRiskyPermissions"
)

$rows = foreach ($fn in $functions) {
    $b = $baseline.Metrics.$fn
    $p = $post.Metrics.$fn

    $bMean = if ($null -eq $b.MeanMs) { $null } else { [double]$b.MeanMs }
    $pMean = if ($null -eq $p.MeanMs) { $null } else { [double]$p.MeanMs }

    $delta = if ($null -eq $bMean -or $null -eq $pMean) { $null } else { [Math]::Round(($pMean - $bMean), 2) }
    $pct = if ($null -eq $delta -or $bMean -eq 0) { $null } else { [Math]::Round((($delta / $bMean) * 100), 2) }

    [PSCustomObject]@{
        Function = $fn
        BaselineMeanMs = $bMean
        PostMeanMs = $pMean
        DeltaMs = $delta
        DeltaPercent = $pct
    }
}

$summary = [PSCustomObject]@{
    BaselineLabel = $baseline.Label
    PostLabel = $post.Label
    ComparedAt = (Get-Date).ToString("o")
    Results = $rows
}

$summary | ConvertTo-Json -Depth 6
