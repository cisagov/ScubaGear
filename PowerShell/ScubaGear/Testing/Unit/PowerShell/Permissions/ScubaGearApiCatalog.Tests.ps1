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

    # --- Scan production module code so removing a catalog entry that code still calls fails a test. ---
    $ModulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules' -Resolve
    $CodeFiles = Get-ChildItem -Path $ModulesRoot -Include '*.psm1', '*.ps1' -Recurse -File

    $GraphCmdletRefs = [System.Collections.Generic.List[string]]::new()
    $RestHelperRefs = [System.Collections.Generic.List[string]]::new()
    foreach ($File in $CodeFiles) {
        $Text = Get-Content -Path $File.FullName -Raw
        # Graph cmdlets invoked via Invoke-GraphDirectly -Commandlet X (X optionally quoted; $variables are skipped).
        foreach ($m in [regex]::Matches($Text, '-Commandlet\s+["'']?([A-Za-z][A-Za-z0-9-]+)')) { $GraphCmdletRefs.Add($m.Groups[1].Value) }
        # Graph cmdlets resolved directly via Get-ScubaGearGraphEndpoint / Get-ScubaGearApiHeader -CmdletName X.
        foreach ($m in [regex]::Matches($Text, 'Get-ScubaGear(?:GraphEndpoint|ApiHeader)\s+-CmdletName\s+["'']?([A-Za-z][A-Za-z0-9-]+)')) { $GraphCmdletRefs.Add($m.Groups[1].Value) }
        # REST helper functions resolved via Get-ScubaGearRestEndpoint -FunctionName 'X'.
        foreach ($m in [regex]::Matches($Text, "Get-ScubaGearRestEndpoint\s+-FunctionName\s+'([^']+)'")) { $RestHelperRefs.Add($m.Groups[1].Value) }
    }
    $script:GraphCmdletCases = @($GraphCmdletRefs | Sort-Object -Unique | ForEach-Object { @{ Cmdlet = $_ } })
    $script:RestHelperRefCases = @($RestHelperRefs | Sort-Object -Unique | ForEach-Object { @{ FunctionName = $_ } })
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
            $null -ne (Compare-Object -ReferenceObject $script:ExpectedKeys -DifferenceObject $Keys)
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

    It 'contains the pinned number of entries per entryType (update deliberately when adding/removing an API)' {
        $ByType = @{}
        $script:Catalog | Group-Object entryType | ForEach-Object { $ByType[$_.Name] = $_.Count }
        $ByType['graphConnect']  | Should -Be 3  -Because 'Connect-MgGraph base URL, one per environment grouping'
        $ByType['graphResource'] | Should -Be 45 -Because 'one Graph cmdlet resource record each'
        $ByType['restBase']      | Should -Be 19 -Because 'per-product REST API host records across environments'
        $ByType['restHelper']    | Should -Be 12 -Because 'provider REST helper functions with a fixed path'
        $script:Catalog.Count    | Should -Be 79 -Because 'total catalog size; change this only when intentionally adding or removing an API'
    }

    It 'has a unique functionName for every graphResource (exactly one entry per Graph cmdlet)' {
        $GraphResource = @($script:Catalog | Where-Object { $_.entryType -eq 'graphResource' } | ForEach-Object { $_.functionName })
        ($GraphResource | Group-Object | Where-Object Count -gt 1 | ForEach-Object Name) | Should -BeNullOrEmpty -Because 'a cmdlet resolving to two different entries is ambiguous'
        $GraphResource.Count | Should -Be (@($GraphResource | Sort-Object -Unique).Count)
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

# Deeper per-field invariants so a malformed or partially-removed entry fails fast.
Describe -Tag 'PermissionsHelper' -Name 'ScubaGearApiCatalog.json schema integrity' {
    BeforeAll {
        $CatalogFile = Join-Path -Path $PSScriptRoot -ChildPath '../../../../schemas/ScubaGearApiCatalog.json' -Resolve
        $script:Catalog = @((Get-Content -Path $CatalogFile -Raw | ConvertFrom-Json) | ForEach-Object { $_ })
        $script:ValidEnvs = @('commercial', 'gcc', 'gcchigh', 'dod')
        $script:KnownProducts = @('aad', 'exo', 'securitysuite', 'teams', 'teamsunified', 'sharepoint', 'powerplatform', 'powerbi', 'scubatank', 'ServicePrincipal')
        $script:ArrayFields = @('scubaGearProduct', 'supportedEnv', 'parameters', 'apiHeader', 'leastPermissions', 'higherPermissions', 'spRolePermissions', 'poshModule', 'supportLinks')
        $script:StringFields = @('functionName', 'entryType', 'endpointPath', 'apiFilter', 'oauthScope')
    }

    It 'uses only known supportedEnv values' {
        $Bad = $script:Catalog | Where-Object { @($_.supportedEnv | Where-Object { $_ -notin $script:ValidEnvs }).Count -gt 0 }
        $Bad | ForEach-Object { $_.functionName } | Should -BeNullOrEmpty
    }

    It 'uses only known scubaGearProduct values' {
        $Bad = $script:Catalog | Where-Object { @($_.scubaGearProduct | Where-Object { $_ -notin $script:KnownProducts }).Count -gt 0 }
        $Bad | ForEach-Object { $_.functionName } | Should -BeNullOrEmpty
    }

    It 'keeps every array-typed field an array' {
        $Bad = foreach ($Entry in $script:Catalog) {
            foreach ($Field in $script:ArrayFields) {
                $Value = $Entry.$Field
                if ($null -ne $Value -and $Value -isnot [array]) { "$($Entry.functionName).$Field" }
            }
        }
        $Bad | Should -BeNullOrEmpty
    }

    It 'keeps every string-typed field a string' {
        $Bad = foreach ($Entry in $script:Catalog) {
            foreach ($Field in $script:StringFields) {
                if ($Entry.$Field -isnot [string]) { "$($Entry.functionName).$Field" }
            }
        }
        $Bad | Should -BeNullOrEmpty
    }

    It 'gives every graphConnect, graphResource and restBase a non-empty endpointPath' {
        $Bad = $script:Catalog |
            Where-Object { $_.entryType -in @('graphConnect', 'graphResource', 'restBase') -and [string]::IsNullOrWhiteSpace($_.endpointPath) }
        $Bad | ForEach-Object { $_.functionName } | Should -BeNullOrEmpty
    }

    It 'gives every restBase a non-empty oauthScope so a token can be minted' {
        $Bad = $script:Catalog | Where-Object { $_.entryType -eq 'restBase' -and [string]::IsNullOrWhiteSpace($_.oauthScope) }
        $Bad | ForEach-Object { $_.functionName } | Should -BeNullOrEmpty
    }

    It "keeps each entry's parameters in sync with the {placeholders} in its endpointPath / apiFilter / oauthScope" {
        $Bad = foreach ($Entry in $script:Catalog) {
            $Text = @($Entry.endpointPath, $Entry.apiFilter, $Entry.oauthScope) -join ' '
            $Found = @([regex]::Matches($Text, '\{([^}]+)\}') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
            $Declared = @($Entry.parameters | Sort-Object -Unique)
            if (Compare-Object -ReferenceObject $Found -DifferenceObject $Declared) { $Entry.functionName }
        }
        $Bad | Should -BeNullOrEmpty
    }
}

# Checks and balances: whatever production code calls MUST exist in the catalog, so deleting an entry
# (or adding a new call without a catalog entry) fails here instead of at runtime.
Describe -Tag 'PermissionsHelper' -Name 'ScubaGearApiCatalog.json covers every API production code calls' {
    BeforeAll {
        $CatalogFile = Join-Path -Path $PSScriptRoot -ChildPath '../../../../schemas/ScubaGearApiCatalog.json' -Resolve
        $script:Catalog = @((Get-Content -Path $CatalogFile -Raw | ConvertFrom-Json) | ForEach-Object { $_ })

        # Re-scan at run time (the BeforeDiscovery scan is only in scope for -ForEach generation).
        $ModulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules' -Resolve
        $Graph = [System.Collections.Generic.List[string]]::new()
        $Rest = [System.Collections.Generic.List[string]]::new()
        foreach ($File in (Get-ChildItem -Path $ModulesRoot -Include '*.psm1', '*.ps1' -Recurse -File)) {
            $Text = Get-Content -Path $File.FullName -Raw
            foreach ($m in [regex]::Matches($Text, '-Commandlet\s+["'']?([A-Za-z][A-Za-z0-9-]+)')) { $Graph.Add($m.Groups[1].Value) }
            foreach ($m in [regex]::Matches($Text, 'Get-ScubaGear(?:GraphEndpoint|ApiHeader)\s+-CmdletName\s+["'']?([A-Za-z][A-Za-z0-9-]+)')) { $Graph.Add($m.Groups[1].Value) }
            foreach ($m in [regex]::Matches($Text, "Get-ScubaGearRestEndpoint\s+-FunctionName\s+'([^']+)'")) { $Rest.Add($m.Groups[1].Value) }
        }
        $script:GraphRefCount = @($Graph | Sort-Object -Unique).Count
        $script:RestRefCount = @($Rest | Sort-Object -Unique).Count
    }

    It 'found Graph cmdlet references to validate' {
        $script:GraphRefCount | Should -BeGreaterThan 0
    }

    It 'has a graphConnect/graphResource entry for Graph cmdlet <Cmdlet> that production code invokes' -ForEach $script:GraphCmdletCases {
        @($script:Catalog | Where-Object { $_.functionName -eq $Cmdlet -and $_.entryType -in @('graphConnect', 'graphResource') }).Count |
            Should -BeGreaterThan 0 -Because "production code invokes '$Cmdlet' via Invoke-GraphDirectly/Get-ScubaGearGraphEndpoint"
    }

    It 'found REST helper references to validate' {
        $script:RestRefCount | Should -BeGreaterThan 0
    }

    It 'has a restHelper entry with a fixed path for <FunctionName> that production code requests' -ForEach $script:RestHelperRefCases {
        $Entry = @($script:Catalog | Where-Object { $_.functionName -eq $FunctionName -and $_.entryType -eq 'restHelper' })
        $Entry.Count | Should -BeGreaterThan 0 -Because "production code requests '$FunctionName' via Get-ScubaGearRestEndpoint"
        $Entry[0].endpointPath | Should -Match '^/' -Because 'the catalog must provide a fixed REST path'
    }
}

AfterAll {
    Remove-Module PermissionsHelper -ErrorAction SilentlyContinue
}
