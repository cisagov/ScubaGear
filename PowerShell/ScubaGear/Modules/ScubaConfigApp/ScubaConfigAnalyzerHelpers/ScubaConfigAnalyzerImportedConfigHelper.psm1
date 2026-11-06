<#
.SYNOPSIS
    Analyzer helper: reads the configuration a ScubaGear run actually used (Raw.scuba_config
    in a ScubaResults file) so the generated YAML carries it forward, plus a small YAML writer.
.NOTES
    Imported (Import-Module) by Start-SCuBAConfigAnalyzer alongside the other analyzer
    helpers. Shared analyzer state lives on the synchronized $syncHash ($syncHash.ScA*), so
    every helper module reads/writes the same caches (mirrors how ScubaConfigApp shares
    state). Populated at scan time by Import-ScA*.
    Part of the ScubaGear project - https://github.com/cisagov/ScubaGear
#>

function Test-ScAYamlList {
    <#
    .SYNOPSIS
    True when the value should be written as a YAML sequence (any non-string, non-dictionary collection).
    #>
    param([AllowNull()]$Value)
    return ($null -ne $Value -and $Value -is [System.Collections.IEnumerable] -and $Value -isnot [string] -and $Value -isnot [System.Collections.IDictionary])
}

function Test-ScAConfigValueEmpty {
    <#
    .SYNOPSIS
    True for values that carry no configuration (null, blank strings, empty lists/objects).
    #>
    param([AllowNull()]$Value)
    if ($null -eq $Value) { return $true }
    if ($Value -is [string]) { return [string]::IsNullOrWhiteSpace($Value) }
    if ($Value -is [System.Collections.IDictionary]) { return $Value.Count -eq 0 }
    if (Test-ScAYamlList $Value) { return @($Value).Count -eq 0 }
    return $false
}

function ConvertTo-ScAConfigValue {
    <#
    .SYNOPSIS
    Normalizes a value parsed from Raw.scuba_config into plain ordered dictionaries, arrays and scalars.
    .DESCRIPTION
    scuba_config is the in-memory ScubaGear config serialized with ConvertTo-Json, so:
      - switch parameters arrive as { "IsPresent": true } and are folded back to a boolean;
      - YAML dates (OmitPolicy Expiration, AnnotatePolicy RemediationDate) arrive as midnight
        timestamps (a string in Windows PowerShell, a DateTime in PowerShell 7) and are
        returned as yyyy-MM-dd, the format the config schema requires;
      - empty lists/objects are dropped so they don't produce noise in the YAML.
    #>
    param([AllowNull()]$Value)

    if ($null -eq $Value) { return $null }

    if ($Value -is [datetime]) {
        # A date may have been shifted to UTC or local time on the way through JSON; use whichever reading is midnight.
        $date = @($Value, $Value.ToLocalTime(), $Value.ToUniversalTime()) | Where-Object { $_.TimeOfDay -eq [TimeSpan]::Zero } | Select-Object -First 1
        if (-not $date) { $date = $Value }
        return $date.ToString('yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
    }
    if ($Value -is [string]) {
        if ($Value -match '^(\d{4}-\d{2}-\d{2})T00:00:00(\.0+)?(Z|[+-]\d{2}:\d{2})?$') { return $Matches[1] }
        return $Value
    }
    if ($Value -is [ValueType]) { return $Value }

    if ($Value -is [System.Collections.IDictionary]) {
        $out = [ordered]@{}
        foreach ($k in @($Value.Keys)) {
            $v = ConvertTo-ScAConfigValue -Value $Value[$k]
            if (-not (Test-ScAConfigValueEmpty $v)) { $out[[string]$k] = $v }
        }
        return $out
    }

    if (Test-ScAYamlList $Value) {
        $items = @(foreach ($item in $Value) {
            $v = ConvertTo-ScAConfigValue -Value $item
            if ($null -ne $v) { ,$v }
        })
        return ,$items
    }

    # PSCustomObject (from ConvertFrom-Json).
    $props = @($Value.PSObject.Properties)
    if ($props.Count -eq 1 -and $props[0].Name -eq 'IsPresent') { return [bool]$props[0].Value }
    $obj = [ordered]@{}
    foreach ($p in $props) {
        $v = ConvertTo-ScAConfigValue -Value $p.Value
        if (-not (Test-ScAConfigValueEmpty $v)) { $obj[$p.Name] = $v }
    }
    return $obj
}

function Get-ScAImportedConfig {
    <#
    .SYNOPSIS
    Reads the configuration ScubaGear ran with from an imported ScubaResults file
    (Raw.scuba_config) so the generated YAML keeps the user's settings, omissions,
    annotations and exclusions instead of only what the analyzer detected.
    .DESCRIPTION
    Only keys defined by the ScubaGear config schema are kept (scuba_config also holds
    run-time values that are not config). Values equal to the ScubaGear defaults
    (ScubaConfigDefaults.json, next to the schema) are dropped because Invoke-SCuBA applies
    them anyway, except for the keys in -KeepDefaultKeys. Keys are returned with the
    schema's casing.
    .OUTPUTS
    [ordered] dictionary of config key -> value (product sections and OmitPolicy/AnnotatePolicy
    are nested ordered dictionaries), or $null when the results carry no scuba_config.
    #>
    param(
        [AllowNull()]$Raw,
        [string]$ConfigSchemaPath,
        [string[]]$KeepDefaultKeys = @('M365Environment', 'ProductNames')
    )

    if (-not $Raw -or -not ($Raw.PSObject.Properties.Name -contains 'scuba_config') -or -not $Raw.scuba_config) { return $null }

    # The schema's top-level properties are the only valid config keys; the defaults file
    # lives alongside it in Modules/ScubaConfig.
    $allowedKeys = @()
    $defaults    = $null
    if ($ConfigSchemaPath -and (Test-Path $ConfigSchemaPath)) {
        try {
            $allowedKeys = @((Get-Content $ConfigSchemaPath -Raw | ConvertFrom-Json).properties.PSObject.Properties.Name)
        } catch {
            Write-Warning "Failed to read config schema '$ConfigSchemaPath': $($_.Exception.Message)"
        }
        $defaultsPath = Join-Path (Split-Path $ConfigSchemaPath -Parent) 'ScubaConfigDefaults.json'
        if (Test-Path $defaultsPath) {
            try {
                $defaults = (Get-Content $defaultsPath -Raw | ConvertFrom-Json).defaults
            } catch {
                Write-Warning "Failed to read config defaults '$defaultsPath': $($_.Exception.Message)"
            }
        }
    }

    $config = [ordered]@{}
    foreach ($p in @($Raw.scuba_config.PSObject.Properties)) {
        $key = [string]$p.Name
        if (@($allowedKeys).Count -gt 0) {
            $canonical = @($allowedKeys | Where-Object { $_ -eq $key }) | Select-Object -First 1
            if (-not $canonical) {
                Write-Verbose "Imported config: skipping '$key' (not a ScubaGear config key)."
                continue
            }
            $key = [string]$canonical
        }

        $value = ConvertTo-ScAConfigValue -Value $p.Value
        if (Test-ScAConfigValueEmpty $value) { continue }

        if ($defaults -and $KeepDefaultKeys -notcontains $key -and ($defaults.PSObject.Properties.Name -contains $key)) {
            $defaultValue = ConvertTo-ScAConfigValue -Value $defaults.$key
            if ((ConvertTo-Json -InputObject $value -Depth 10 -Compress) -eq (ConvertTo-Json -InputObject $defaultValue -Depth 10 -Compress)) { continue }
        }
        $config[$key] = $value
    }
    return $config
}

function Format-ScAYamlScalar {
    <#
    .SYNOPSIS
    Formats a scalar for YAML, quoting strings that would otherwise be read as another type
    (numbers, dates, booleans, null) or that contain YAML syntax characters.
    #>
    param([AllowNull()]$Value)

    if ($null -eq $Value) { return "''" }
    if ($Value -is [bool]) { return $Value.ToString().ToLowerInvariant() }
    if ($Value -is [System.IFormattable] -and $Value -isnot [datetime]) {
        return ([System.IFormattable]$Value).ToString($null, [System.Globalization.CultureInfo]::InvariantCulture)
    }

    $s = [string]$Value
    if ($s -match "[`r`n`t]") {
        return '"' + ($s -replace '\\', '\\' -replace '"', '\"' -replace "`r", '\r' -replace "`n", '\n' -replace "`t", '\t') + '"'
    }
    $needsQuotes = (
        $s -eq '' -or
        $s -ne $s.Trim() -or
        $s -match '^[-?:,\[\]{}#&*!|>''"%@`]' -or
        $s -match ':(\s|$)' -or
        $s -match '\s#' -or
        $s -match '^(true|false|yes|no|on|off|y|n|null|~)$' -or
        $s -match '^[-+]?(\d[\d_]*(\.\d*)?|\.\d+)([eE][-+]?\d+)?$' -or
        $s -match '^0[xXoO][0-9a-fA-F]+$' -or
        $s -match '^\d{4}-\d{2}-\d{2}'
    )
    if ($needsQuotes) { return "'" + ($s -replace "'", "''") + "'" }
    return $s
}

function Add-ScAYamlNode {
    <#
    .SYNOPSIS
    Appends a value (ordered dictionary, list or scalar) to a StringBuilder as block-style YAML.
    .PARAMETER DisplayNameLookup
    Optional object id -> display name map; list items found in it get a '# name' comment.
    #>
    param(
        [Parameter(Mandatory)][System.Text.StringBuilder]$Builder,
        [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()]$Value,
        [int]$Indent = 0,
        [hashtable]$DisplayNameLookup = @{}
    )

    $pad = ' ' * $Indent

    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($k in @($Value.Keys)) {
            $child = $Value[$k]
            if ($child -is [System.Collections.IDictionary]) {
                if ($child.Count -eq 0) { [void]$Builder.AppendLine("$pad$($k): {}"); continue }
                [void]$Builder.AppendLine("$pad$($k):")
                Add-ScAYamlNode -Builder $Builder -Value $child -Indent ($Indent + 2) -DisplayNameLookup $DisplayNameLookup
            } elseif (Test-ScAYamlList $child) {
                if (@($child).Count -eq 0) { [void]$Builder.AppendLine("$pad$($k): []"); continue }
                [void]$Builder.AppendLine("$pad$($k):")
                Add-ScAYamlNode -Builder $Builder -Value $child -Indent ($Indent + 2) -DisplayNameLookup $DisplayNameLookup
            } else {
                [void]$Builder.AppendLine("$pad$($k): $(Format-ScAYamlScalar $child)")
            }
        }
        return
    }

    if (Test-ScAYamlList $Value) {
        foreach ($item in @($Value)) {
            if ($item -is [System.Collections.IDictionary] -and $item.Count -gt 0) {
                # Render the mapping one level deeper, then turn its first line's indent into '- '.
                $inner = [System.Text.StringBuilder]::new()
                Add-ScAYamlNode -Builder $inner -Value $item -Indent ($Indent + 2) -DisplayNameLookup $DisplayNameLookup
                [void]$Builder.Append("$pad- " + $inner.ToString().Substring($Indent + 2))
            } else {
                $key = [string]$item
                $comment = if ($DisplayNameLookup.ContainsKey($key)) { "  # $($DisplayNameLookup[$key])" } else { "" }
                [void]$Builder.AppendLine("$pad- $(Format-ScAYamlScalar $item)$comment")
            }
        }
        return
    }

    [void]$Builder.AppendLine("$pad$(Format-ScAYamlScalar $Value)")
}

Export-ModuleMember -Function @(
    'Test-ScAYamlList',
    'Test-ScAConfigValueEmpty',
    'ConvertTo-ScAConfigValue',
    'Get-ScAImportedConfig',
    'Format-ScAYamlScalar',
    'Add-ScAYamlNode'
)
