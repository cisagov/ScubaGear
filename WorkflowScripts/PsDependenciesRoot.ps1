#Purpose: Called by ps_dependencies_root.yaml to update the PowerShell versions in the dependencies.psd1 file in the root directory.

$dependencies = Import-PowerShellDataFile -Path './dependencies.psd1'
$updated = $false

foreach ($dependency in $dependencies.Modules) {
    $latestVersion = Find-Module -Name $dependency.Name | Select-Object -ExpandProperty Version
    if ($latestVersion -ne $null -and $latestVersion -ne $dependency.Version) {
        $dependency.Version = $latestVersion
        $updated = $true
    }
}

if ($updated) {
    # Use StringBuilder for efficient string concatenation
    $sb = [System.Text.StringBuilder]::new()

    # Start the output
    $sb.AppendLine("@{") | Out-Null
    $sb.AppendLine("    Modules = @(") | Out-Null

    # Iterate through dependencies and format them
    for ($i = 0; $i -lt $dependencies.Modules.Count; $i++) {
        $dependency = $dependencies.Modules[$i]
        $sb.AppendLine("        @{") | Out-Null
        $sb.AppendLine("            Name    = '$($dependency.Name)'") | Out-Null
        $sb.AppendLine("            Version = '$($dependency.Version)'") | Out-Null
        $sb.Append("        }") | Out-Null

        # Add a comma only if it's not the last item
        if ($i -lt $dependencies.Modules.Count - 1) {
            $sb.Append(",") | Out-Null
        }
        $sb.AppendLine() | Out-Null
    }

    # Close the output
    $sb.AppendLine("    )") | Out-Null
    $sb.AppendLine("}") | Out-Null

    # Write the content to the file
    $output = $sb.ToString()
    Set-Content -Path './dependencies.psd1' -Value $output
}
