Function New-GlobalSettingsControls {
    <#
    .SYNOPSIS
    Creates UI controls for global settings using New-FieldListCard with custom save handling.
    .DESCRIPTION
    This Function creates global settings using the working New-FieldListCard but redirects saves to the flat GlobalSettingsData structure.
    #>

    if (-not $syncHash.UIConfigs.globalSettings -or -not $syncHash.UIConfigs.globalSettings.fields) {
        Write-DebugOutput -Message "No global settings fields defined in configuration" -Source $MyInvocation.MyCommand -Level "Info"
        return
    }

    # Clear existing controls
    $syncHash.GlobalSettingsContainer.Children.Clear()

    # Initialize global settings data structure if not exists
    if (-not $syncHash.GlobalSettingsData) {
        $syncHash.GlobalSettingsData = @{}
    }

    Write-DebugOutput -Message "Creating global settings controls for $($syncHash.UIConfigs.globalSettings.fields.Count) fields" -Source $MyInvocation.MyCommand -Level "Info"

    foreach ($fieldName in $syncHash.UIConfigs.globalSettings.fields) {
        $inputType = $syncHash.UIConfigs.inputTypes.$fieldName

        if (-not $inputType) {
            Write-DebugOutput -Message "Input type not found for global settings field: $fieldName" -Source $MyInvocation.MyCommand -Level "Error"
            continue
        }

        Write-DebugOutput -Message "Creating field list card for global settings field: $fieldName" -Source $MyInvocation.MyCommand -Level "Info"

        # Create a temporary data structure that New-FieldListCard can use
        if (-not $syncHash.TempGlobalData) {
            $syncHash.TempGlobalData = @{}
        }

        # Use a fake policy ID for global settings
        $globalPolicyId = "GlobalSettings"

        $card = New-FieldListCard `
            -CardName "GlobalSettings" `
            -PolicyId $globalPolicyId `
            -ProductName "Global" `
            -PolicyName $inputType.name `
            -PolicyDescription $inputType.description `
            -Criticality "N/A" `
            -FieldList $fieldName `
            -OutputData $syncHash.TempGlobalData `
            -ShowFieldType:$false `
            -ShowDescription:$true

        if ($card) {
            $syncHash.GlobalSettingsContainer.Children.Add($card)
            Write-DebugOutput -Message "Successfully created card for global setting: $fieldName" -Source $MyInvocation.MyCommand -Level "Info"
        } else {
            Write-DebugOutput -Message "Failed to create card for global setting: $fieldName" -Source $MyInvocation.MyCommand -Level "Error"
        }
    }

    # Now add auto-save Functionality by watching the temp data structure
    Add-GlobalSettingsAutoSave

    Write-DebugOutput -Message "Global settings controls created successfully" -Source $MyInvocation.MyCommand -Level "Info"
}

Function Add-GlobalSettingsAutoSave {
    <#
    .SYNOPSIS
    Adds auto-save Functionality to monitor global settings changes and copy to the main data structure.
    #>

    # Set up a timer to periodically check for changes and auto-save
    if (-not $syncHash.GlobalSettingsTimer) {
        $syncHash.GlobalSettingsTimer = New-Object System.Windows.Threading.DispatcherTimer
        $syncHash.GlobalSettingsTimer.Interval = [TimeSpan]::FromMilliseconds(500)

        $syncHash.GlobalSettingsTimer.Add_Tick({
            try {
                if ($syncHash.TempGlobalData -and $syncHash.TempGlobalData["Global"]) {
                    foreach ($policyId in $syncHash.TempGlobalData["Global"].Keys) {
                        if ($policyId -like "GlobalSettings.*") {
                            #$fieldName = $policyId -replace "^GlobalSettings\.", ""
                            $policyData = $syncHash.TempGlobalData["Global"][$policyId]

                            # Extract the actual field values
                            foreach ($key in $policyData.Keys) {
                                if ($policyData[$key] -is [hashtable]) {
                                    # Handle nested structure (like input types with multiple fields)
                                    foreach ($innerKey in $policyData[$key].Keys) {
                                        $value = $policyData[$key][$innerKey]
                                        if ($null -ne $value) {
                                            $syncHash.GlobalSettingsData[$innerKey] = $value
                                        }
                                    }
                                } else {
                                    # Handle direct values
                                    $value = $policyData[$key]
                                    if ($null -ne $value) {
                                        $syncHash.GlobalSettingsData[$key] = $value
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                Write-DebugOutput -Message "Error in global settings auto-save: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
            }
        })

        $syncHash.GlobalSettingsTimer.Start()
        Write-DebugOutput -Message "Global settings auto-save timer started" -Source $MyInvocation.MyCommand -Level "Info"
    }
}