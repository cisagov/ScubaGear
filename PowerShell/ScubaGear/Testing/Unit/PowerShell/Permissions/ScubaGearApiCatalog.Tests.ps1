BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/Permissions' -Resolve
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'PermissionsHelper.psm1') -Force

    $CatalogFile = Join-Path -Path $PSScriptRoot -ChildPath '../../../../schemas/ScubaGearApiCatalog.json' -Resolve
    $CatalogEntries = @((Get-Content -Path $CatalogFile -Raw | ConvertFrom-Json) | ForEach-Object { $_ })

    $script:RestHelperCases = @(
        $CatalogEntries |
            Where-Object { $_.entryType -eq 'restHelper' } |
            ForEach-Object { @{ FunctionName = $_.functionName; Entry = $_ } }
    )
    $script:ProductCases = 'aad', 'exo', 'securitysuite', 'teams', 'sharepoint', 'powerplatform' | ForEach-Object { @{ Product = $_ } }
}

# The catalog is a single uniform array. Every entry has the same 16 keys and an entryType of
# graphConnect | graphResource | restBase | restHelper. Get-ScubaGearPermissions (and the dedicated
# Get-ScubaGear* lookup functions) read every entry except restHelper; Get-ScubaGearRestEndpoint reads
# only restHelper entries.
Describe -Tag 'PermissionsHelper' -Name 'ScubaGearApiCatalog.json structure' {
    BeforeAll {
        $CatalogFile = Join-Path -Path $PSScriptRoot -ChildPath '../../../../schemas/ScubaGearApiCatalog.json' -Resolve
        $script:Catalog = @((Get-Content -Path $CatalogFile -Raw | ConvertFrom-Json) | ForEach-Object { $_ })
        $script:ExpectedKeys = @(
            'functionName', 'entryType', 'scubaGearProduct', 'supportedEnv', 'endpointPath', 'parameters',
            'apiFilter', 'apiHeader', 'leastPermissions', 'higherPermissions', 'spRolePermissions',
            'resourceAPIAppId', 'oauthScope', 'poshModule', 'supportLinks', 'notes'
        )
        $script:ValidTypes = @('graphConnect', 'graphResource', 'restBase', 'restHelper')
    }

    It 'parses as a JSON array' {
        $script:Catalog.Count | Should -BeGreaterThan 0
    }

    It 'gives every entry the same 16 keys' {
        $Bad = $script:Catalog | Where-Object {
            $Keys = $_.PSObject.Properties.Name
            (Compare-Object -ReferenceObject $script:ExpectedKeys -DifferenceObject $Keys) -ne $null
        }
        $Bad | Should -BeNullOrEmpty
    }

    It 'gives every entry a non-empty functionName and a valid entryType' {
        $Bad = $script:Catalog | Where-Object {
            [string]::IsNullOrWhiteSpace($_.functionName) -or ($script:ValidTypes -notcontains $_.entryType)
        }
        $Bad | Should -BeNullOrEmpty
    }

    It 'has at least one entry of each entryType' {
        foreach ($Type in $script:ValidTypes) {
            @($script:Catalog | Where-Object { $_.entryType -eq $Type }).Count | Should -BeGreaterThan 0 -Because "entryType '$Type' should exist"
        }
    }

    It 'has no duplicate restHelper functionName (Get-ScubaGearRestEndpoint resolves by functionName)' {
        $Names = $script:Catalog | Where-Object { $_.entryType -eq 'restHelper' } | ForEach-Object { $_.functionName }
        ($Names | Group-Object | Where-Object Count -gt 1 | ForEach-Object Name) | Should -BeNullOrEmpty
    }

    It 'gives every restHelper a fixed endpointPath beginning with /' {
        $Bad = $script:Catalog | Where-Object { $_.entryType -eq 'restHelper' -and ($_.endpointPath -notlike '/*') }
        $Bad | Should -BeNullOrEmpty
    }
}

Describe -Tag 'PermissionsHelper' -Name 'REST helpers resolve and declare their permissions in ScubaGearApiCatalog.json' {
    BeforeAll {
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/Permissions/PermissionsHelper.psm1') -Force
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/Utility/Utility.psm1') -Force
    }

    Context 'Every restHelper endpoint resolves' {
        It 'resolves an endpointPath for <FunctionName>' -ForEach $script:RestHelperCases {
            # Supply any declared placeholders so resolution does not fail on missing path parameters.
            $PathParameters = @{}
            foreach ($Key in @($Entry.parameters)) { if ($Key) { $PathParameters[$Key] = 'value' } }
            $Resolved = if ($PathParameters.Count -gt 0) {
                Get-ScubaGearRestEndpoint -FunctionName $FunctionName -PathParameters $PathParameters
            } else {
                Get-ScubaGearRestEndpoint -FunctionName $FunctionName
            }
            $Resolved | Should -Not -BeNullOrEmpty
            $Resolved | Should -Not -Match '\{.+\}' -Because 'all placeholders should be substituted'
        }
    }

    Context 'REST (restHelper) records do not leak into permission lookups' {
        It 'returns only non-restHelper records for <Product>' -ForEach $script:ProductCases {
            $Records = @(Get-ScubaGearProductRecord -Product $Product)
            $Records.Count | Should -BeGreaterThan 0
            @($Records | Where-Object { $_.entryType -eq 'restHelper' }) | Should -BeNullOrEmpty
        }
    }
}

AfterAll {
    Remove-Module PermissionsHelper -ErrorAction SilentlyContinue
}
