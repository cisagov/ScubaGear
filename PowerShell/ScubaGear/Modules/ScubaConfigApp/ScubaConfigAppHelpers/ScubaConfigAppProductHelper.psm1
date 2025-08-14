# Function to collect ProductNames from UI checkboxes and update GeneralSettings
Function Update-ProductNames {
    <#
    .SYNOPSIS
    Collects checked product checkboxes from UI and updates $syncHash.GeneralSettingsData.ProductNames

    .DESCRIPTION
    This Function scans the UI for checked product checkboxes and updates the GeneralSettings
    with the actual list of selected products. This is used for UI-to-data synchronization.
    #>

    # Collect ProductNames from checked checkboxes
    $selectedProducts = @()
    $allProductCheckboxes = $syncHash.ProductsGrid.Children | Where-Object {
        $_ -is [System.Windows.Controls.CheckBox] -and $_.Name -like "*ProductCheckBox"
    }

    foreach ($checkbox in $allProductCheckboxes) {
        if ($checkbox.IsChecked) {
            $selectedProducts += $checkbox.Tag
            Write-DebugOutput -Message "Checked checkbox: $($checkbox.Tag)" -Source $MyInvocation.MyCommand -Level "Info"
        }
    }

    # Update the GeneralSettings with actual product list
    if ($selectedProducts.Count -gt 0) {
        $syncHash.GeneralSettingsData["ProductNames"] = $selectedProducts
    } else {
        # Remove ProductNames if no products are selected
        $syncHash.GeneralSettingsData.Remove("ProductNames")
    }

    Write-DebugOutput -Message ("Updated ProductNames in GeneralSettings: {0}" -f ($selectedProducts -join ', ')) -Source $MyInvocation.MyCommand -Level "Verbose"
}



# Function to get ProductNames formatted for YAML output
Function Get-ProductNamesForYaml {
    <#
    .SYNOPSIS
    Returns ProductNames formatted appropriately for YAML output

    .DESCRIPTION
    This Function determines the correct format for ProductNames in YAML output.
    If all available products are selected, returns ['*'].
    Otherwise, returns the actual list of selected products.
    #>

    # Check if we have any selected products
    if (-not $syncHash.GeneralSettingsData.ProductNames -or $syncHash.GeneralSettingsData.ProductNames.Count -eq 0) {
        Write-DebugOutput -Message "No ProductNames selected, returning empty array for YAML" -Source $MyInvocation.MyCommand -Level "Verbose"
        return @()
    }

    # Get all available product IDs
    $allProductIds = $syncHash.UIConfigs.products | Select-Object -ExpandProperty id

    # Check if all products are selected
    $selectedProducts = $syncHash.GeneralSettingsData.ProductNames | Sort-Object
    $availableProducts = $allProductIds | Sort-Object
    $isAllProductsSelected = ($selectedProducts.Count -eq $availableProducts.Count) -and
                            (-not (Compare-Object $selectedProducts $availableProducts))

    if ($isAllProductsSelected) {
        Write-DebugOutput -Message "All products selected, returning '*' for YAML output" -Source $MyInvocation.MyCommand -Level "Verbose"
        return "`nProductNames: ['*']"
    } else {
        Write-DebugOutput -Message ("Returning specific product list for YAML: {0}" -f ($selectedProducts -join ', ')) -Source $MyInvocation.MyCommand -Level "Verbose"
        Return ("`nProductNames: " + ($selectedProducts | ForEach-Object { "`n  - $_" }) -join '')
    }
}

# Function to populate cards for product policies
Function New-ProductPolicyCards {
    <#
    .SYNOPSIS
    Creates policy cards for baselineControl.
    .DESCRIPTION
    This Function generates UI cards for each policy baseline of a product, allowing users to configure baselines.
    #>
    param(
        [string]$ProductName,
        [System.Windows.Controls.StackPanel]$Container,
        [string]$ControlType
    )

    $Container.Children.Clear()

    # Get the baseline control configuration for this type
    $baselineControl = $syncHash.UIConfigs.baselineControls | Where-Object { $_.controlType -eq $ControlType }

    if (-not $baselineControl) {
        Write-DebugOutput -Message ("No baseline control configuration found for: {0}" -f $ControlType) -Source $MyInvocation.MyCommand -Level "Error"
        return
    }

    # Get baselines for this product
    $baselines = $syncHash.Baselines.$ProductName

    if ($null -ne $baselines) {
        # Filter baselines based on the control type
        $filteredBaselines = switch ($ControlType) {
            "Exclusions" {
                $baselines | Where-Object { $_.$($baselineControl.fieldControlName) -ne 'none' }
            }
            default {
                $baselines  # Omissions and Annotations use all baselines
            }
        }

        if ($null -ne $filteredBaselines) {
            foreach ($baseline in $filteredBaselines) {
                # Get the field list for this baseline
                $fieldList = if ($baseline.PSObject.Properties.Name -contains $baselineControl.fieldControlName) {
                    $baseline.$($baselineControl.fieldControlName)
                } else {
                    $baselineControl.defaultFields
                }

                # Get the output data hashtable dynamically
                $outputData = $syncHash.$($baselineControl.dataControlOutput)

                $card = New-FieldListCard `
                            -CardName $baselineControl.CardName `
                            -PolicyId $baseline.id `
                            -ProductName $ProductName `
                            -PolicyName $baseline.name `
                            -PolicyDescription $baseline.rationale `
                            -Criticality $baseline.criticality `
                            -FieldList $fieldList `
                            -OutputData $outputData `
                            -ShowFieldType:$baselineControl.showFieldType `
                            -ShowDescription:$baselineControl.showDescription `
                            -FlipFieldValueAndPolicyId:$baselineControl.supportsAllProducts

                if ($card) {
                    [void]$Container.Children.Add($card)
                }
            }
        } else {
            # No applicable baselines
            $noDataText = New-Object System.Windows.Controls.TextBlock
            $noDataText.Text = $syncHash.UIConfigs.LocaleInfoMessages.NoPoliciesAvailable
            $noDataText.Foreground = $syncHash.Window.FindResource("MutedTextBrush")
            $noDataText.FontStyle = "Italic"
            $noDataText.HorizontalAlignment = "Center"
            $noDataText.Margin = "0,50,0,0"
            [void]$Container.Children.Add($noDataText)
        }
    } else {
        # No baselines available for this product
        $noDataText = New-Object System.Windows.Controls.TextBlock
        $noDataText.Text = $syncHash.UIConfigs.LocaleInfoMessages.NoPoliciesAvailable
        $noDataText.Foreground = $syncHash.Window.FindResource("MutedTextBrush")
        $noDataText.FontStyle = "Italic"
        $noDataText.HorizontalAlignment = "Center"
        $noDataText.Margin = "0,50,0,0"
        [void]$Container.Children.Add($noDataText)
    }
}