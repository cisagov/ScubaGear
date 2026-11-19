BeforeAll {
    $HelperPath = Join-Path $PSScriptRoot '../../../../../Modules/Providers/ProviderHelpers/LicenseHelper.psm1'
    Import-Module $HelperPath -Force

    function New-TestSku {
        param (
            [string]$PlanId = 'a62f8878-de10-42f3-b68f-6149a25ceb97',
            [string]$PartNumber = 'Microsoft_365_Copilot',
            [string]$Status = 'Enabled',
            [int]$Enabled = 10,
            [int]$Warning = 0,
            [string]$ProvisioningStatus = 'Success'
        )

        [PSCustomObject]@{
            SkuPartNumber = $PartNumber
            CapabilityStatus = $Status
            ConsumedUnits = 0
            PrepaidUnits = [PSCustomObject]@{
                Enabled = $Enabled
                Warning = $Warning
                Suspended = 0
                LockedOut = 0
            }
            ServicePlans = @(
                [PSCustomObject]@{
                    ServicePlanId = $PlanId
                    ServicePlanName = 'M365_COPILOT_APPS'
                    ProvisioningStatus = $ProvisioningStatus
                }
            )
        }
    }
}

Describe 'Get-CopilotLicense' {
    It 'detects a core Copilot plan by ID: <PlanId>' -TestCases @(
        @{ PlanId = 'a62f8878-de10-42f3-b68f-6149a25ceb97' }
        @{ PlanId = '3f30311c-6b1e-48a4-ab79-725b469da960' }
        @{ PlanId = 'b95945de-b3bd-46db-8437-f2beb6ea2347' }
        @{ PlanId = '0aedf20c-091d-420b-aadf-30c042609612' }
    ) {
        param ($PlanId)
        $Sku = New-TestSku -PlanId $PlanId
        $Sku.ServicePlans[0].ServicePlanName = 'Renamed plan'

        Get-CopilotLicense -SubscribedSku $Sku | Should -BeTrue
    }

    It 'detects Copilot without a standalone SKU in <Scenario>' -TestCases @(
        @{ Scenario = 'an E7 bundle'; PartNumber = 'E7-bundle-test-fixture' }
        @{ Scenario = 'a future bundle'; PartNumber = 'Unknown-future-bundle' }
        @{ Scenario = 'GCC'; PartNumber = 'COPILOT_FOR_MICROSOFT_365_GCC' }
    ) {
        param ($PartNumber)
        $Sku = New-TestSku -PartNumber $PartNumber

        Get-CopilotLicense -SubscribedSku $Sku | Should -BeTrue
    }

    It 'counts enabled licenses even when none are assigned' {
        $Sku = New-TestSku
        $Sku.ConsumedUnits | Should -Be 0

        $Result = @(Get-CopilotLicense -SubscribedSku $Sku)
        $Result.Count | Should -Be 1
        $Result[0] | Should -BeOfType ([bool])
        $Result[0] | Should -BeTrue
    }

    It 'counts licenses in their warning grace period' {
        $Sku = New-TestSku -Status Warning -Enabled 0 -Warning 10

        Get-CopilotLicense -SubscribedSku $Sku | Should -BeTrue
    }

    It 'counts the entitlement when the plan is <ProvisioningStatus>' -TestCases @(
        @{ ProvisioningStatus = 'Disabled' }
        @{ ProvisioningStatus = 'PendingProvisioning' }
        @{ ProvisioningStatus = 'Error' }
    ) {
        param ($ProvisioningStatus)
        $Sku = New-TestSku -ProvisioningStatus $ProvisioningStatus

        Get-CopilotLicense -SubscribedSku $Sku | Should -BeTrue
    }

    It 'rejects a SKU whose capability status is <Status>' -TestCases @(
        @{ Status = 'Suspended' }
        @{ Status = 'Deleted' }
        @{ Status = 'LockedOut' }
    ) {
        param ($Status)
        $Sku = New-TestSku -Status $Status

        Get-CopilotLicense -SubscribedSku $Sku | Should -BeFalse
    }

    It 'rejects a SKU with no enabled or warning seats even if users remain assigned' {
        $Sku = New-TestSku -Enabled 0
        $Sku.PrepaidUnits.Suspended = 10
        $Sku.PrepaidUnits.LockedOut = 5
        $Sku.ConsumedUnits = 10

        Get-CopilotLicense -SubscribedSku $Sku | Should -BeFalse
    }

    It 'does not infer Copilot from its name or a related plan: <Scenario>' -TestCases @(
        @{ Scenario = 'free Copilot Chat'; PlanId = '00000000-0000-0000-0000-000000000000'; Name = 'COPILOT_CHAT' }
        @{ Scenario = 'Copilot Studio'; PlanId = 'fe6c28b3-d468-44ea-bbd0-a10a5167435c'; Name = 'COPILOT_STUDIO_IN_COPILOT_FOR_M365' }
        @{ Scenario = 'Power Platform connectors'; PlanId = '89f1c4c8-0878-40f7-804d-869c9128ab5d'; Name = 'M365_COPILOT_CONNECTORS' }
        @{ Scenario = 'Graph connectors'; PlanId = '82d30987-df9b-4486-b146-198b21d164c7'; Name = 'GRAPH_CONNECTORS_COPILOT' }
        @{ Scenario = 'an unrelated service'; PlanId = 'eec0eb4f-6444-4f95-aba0-50c24d67f998'; Name = 'AAD_PREMIUM_P2' }
    ) {
        param ($PlanId, $Name)
        $Sku = New-TestSku -PlanId $PlanId
        $Sku.ServicePlans[0].ServicePlanName = $Name

        Get-CopilotLicense -SubscribedSku $Sku | Should -BeFalse
    }

    It 'checks seats on the matching SKU instead of borrowing seats from another SKU' {
        $InactiveCopilot = New-TestSku -Enabled 0
        $ActiveEntra = New-TestSku -PlanId 'eec0eb4f-6444-4f95-aba0-50c24d67f998'

        Get-CopilotLicense -SubscribedSku @($InactiveCopilot, $ActiveEntra) | Should -BeFalse
    }

    It 'finds Copilot after an unrelated SKU and unrelated plan' {
        $Entra = New-TestSku -PlanId 'eec0eb4f-6444-4f95-aba0-50c24d67f998'
        $Copilot = New-TestSku
        $Copilot.ServicePlans = @($Entra.ServicePlans[0], $Copilot.ServicePlans[0])

        Get-CopilotLicense -SubscribedSku @($null, $Entra, $Copilot) | Should -BeTrue
    }

    It 'supports camelCase hashtables from direct Graph calls' {
        $Sku = @{
            capabilityStatus = 'Enabled'
            prepaidUnits = @{ enabled = 10; warning = 0 }
            servicePlans = @(@{ servicePlanId = 'A62F8878-DE10-42F3-B68F-6149A25CEB97' })
        }

        Get-CopilotLicense -SubscribedSku $Sku | Should -BeTrue
    }

    It 'returns one false Boolean for missing license data: <Scenario>' -TestCases @(
        @{ Scenario = 'null'; Skus = $null }
        @{ Scenario = 'empty collection'; Skus = @() }
        @{ Scenario = 'empty SKU'; Skus = @([PSCustomObject]@{}) }
    ) {
        param ($Skus)
        $Result = @(Get-CopilotLicense -SubscribedSku $Skus)

        $Result.Count | Should -Be 1
        $Result[0] | Should -BeOfType ([bool])
        $Result[0] | Should -BeFalse
    }
}
