Function New-GlobalSettingsControls {
    <#
    .SYNOPSIS
    Creates UI controls for global settings using New-FieldListCard with direct save to GlobalSettingsData.
    .DESCRIPTION
    This Function creates global settings using New-FieldListCard with the -OutPolicyOnly parameter
    to save data directly to the flat GlobalSettingsData structure without nesting.
    #>

    if (-not $syncHash.UIConfigs.settingsControl.GlobalTab.sectionControl.GlobalSettingsContainer -or
        -not $syncHash.UIConfigs.settingsControl.GlobalTab.sectionControl.GlobalSettingsContainer.fields) {
        Write-DebugOutput -Message "No global settings fields defined in configuration" -Source $MyInvocation.MyCommand -Level "Info"
        return
    }

    # Clear existing controls
    $syncHash.GlobalSettingsContainer.Children.Clear()

    # Initialize global settings data structure if not exists
    if (-not $syncHash.GlobalSettingsData) {
        $syncHash.GlobalSettingsData = @{}
    }

    $globalFields = $syncHash.UIConfigs.settingsControl.GlobalTab.sectionControl.GlobalSettingsContainer.fields
    Write-DebugOutput -Message "Creating global settings controls for $($globalFields.Count) fields" -Source $MyInvocation.MyCommand -Level "Info"

    foreach ($fieldName in $globalFields) {
        $inputType = $syncHash.UIConfigs.inputTypes.$fieldName

        if (-not $inputType) {
            Write-DebugOutput -Message "Input type not found for global settings field: $fieldName" -Source $MyInvocation.MyCommand -Level "Error"
            continue
        }

        Write-DebugOutput -Message "Creating field list card for global settings field: $fieldName" -Source $MyInvocation.MyCommand -Level "Info"

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
            -OutputData $syncHash.GlobalSettingsData `
            -SettingsTypeName "GlobalSettingsData" `
            -ShowFieldType:$false `
            -ShowDescription:$true `
            -OutPolicyOnly


        if ($card) {
            $syncHash.GlobalSettingsContainer.Children.Add($card)
            Write-DebugOutput -Message "Successfully created card for global setting: $fieldName" -Source $MyInvocation.MyCommand -Level "Info"
        } else {
            Write-DebugOutput -Message "Failed to create card for global setting: $fieldName" -Source $MyInvocation.MyCommand -Level "Error"
        }
    }

    # Global settings now use -OutPolicyOnly parameter for direct saving
    # No additional setup needed - integrates directly with the centralized AutoSave system

    Write-DebugOutput -Message "Global settings integrated with centralized AutoSave system using -OutPolicyOnly parameter" -Source $MyInvocation.MyCommand -Level "Info"
}