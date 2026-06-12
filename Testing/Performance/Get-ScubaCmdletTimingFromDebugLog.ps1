param(
    [Parameter(Mandatory = $true)]
    [string]$DebugLogPath,

    [string]$OutputPath = "",

    [string]$Label = "gcc-baseline"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $DebugLogPath)) {
    throw "Debug log path not found: $DebugLogPath"
}

$targetFunctions = @(
    "Get-ApplicationsWithRiskyPermissions",
    "Get-ServicePrincipalsWithRiskyPermissions"
)

$entryPattern = '^\[(?<Timestamp>[^\]]+)\]\s+\[(?<Level>[^\]]+)\]\s+\[(?<Source>[^\]]+)\]\s+(?<Message>.*)$'
$dataPattern = '^\s*Data:\s+(?<Json>\{.*\})\s*$'

$entries = New-Object System.Collections.Generic.List[object]
$current = $null

Get-Content -Path $DebugLogPath | ForEach-Object {
    $line = $_

    if ($line -match $entryPattern) {
        if ($null -ne $current) {
            $entries.Add($current)
        }

        $current = [PSCustomObject]@{
            Timestamp = $Matches.Timestamp
            Level = $Matches.Level.Trim()
            Source = $Matches.Source.Trim()
            Message = $Matches.Message.Trim()
            Data = $null
        }
        return
    }

    if ($null -ne $current -and $line -match $dataPattern) {
        try {
            $current.Data = ($Matches.Json | ConvertFrom-Json)
        }
        catch {
            Write-Verbose "Skipped malformed JSON data line: $line"
        }
    }
}

if ($null -ne $current) {
    $entries.Add($current)
}

function Get-Stats {
    param([double[]]$Data)

    if ($null -eq $Data -or $Data.Count -eq 0) {
        return [PSCustomObject]@{
            Count = 0
            MeanMs = $null
            MinMs = $null
            MaxMs = $null
            ValuesMs = @()
        }
    }

    return [PSCustomObject]@{
        Count = $Data.Count
        MeanMs = [Math]::Round((($Data | Measure-Object -Average).Average), 2)
        MinMs = [Math]::Round((($Data | Measure-Object -Minimum).Minimum), 2)
        MaxMs = [Math]::Round((($Data | Measure-Object -Maximum).Maximum), 2)
        ValuesMs = @($Data | ForEach-Object { [Math]::Round($_, 2) })
    }
}

$perFunction = @{}
foreach ($fn in $targetFunctions) {
    $times = @(
        $entries |
            Where-Object {
                $_.Source -like '*FunctionTrace*' -and
                $_.Message -match "^EXIT:\s+$fn(\s+\(ERROR\))?$" -and
                $null -ne $_.Data -and
                $null -ne $_.Data.ExecutionTimeMs
            } |
            ForEach-Object { [double]$_.Data.ExecutionTimeMs }
    )

    $perFunction[$fn] = Get-Stats -Data $times
}

$result = [PSCustomObject]@{
    Label = $Label
    GeneratedAt = (Get-Date).ToString("o")
    DebugLogPath = (Resolve-Path $DebugLogPath).Path
    Metrics = [PSCustomObject]$perFunction
}

if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $outDir = Split-Path -Parent $OutputPath
    if (-not [string]::IsNullOrWhiteSpace($outDir) -and -not (Test-Path $outDir)) {
        New-Item -Path $outDir -ItemType Directory -Force | Out-Null
    }
    $result | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Output "Timing summary saved to $OutputPath"
}

$result | ConvertTo-Json -Depth 8
