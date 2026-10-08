BeforeDiscovery {
    # Expected hosts per product and environment, pinned here so a catalog edit that changes a host fails a test.
    # SharePoint hosts use 'contoso' for the tenant name.
    $GraphHosts = @{ commercial = 'graph.microsoft.com'; gcc = 'graph.microsoft.com'; gcchigh = 'graph.microsoft.us'; dod = 'dod-graph.microsoft.us' }
    $ProductHosts = @{
        aad           = @{ commercial = @(); gcc = @(); gcchigh = @(); dod = @() }
        sharepoint    = @{ commercial = @('contoso-admin.sharepoint.com'); gcc = @('contoso-admin.sharepoint.com'); gcchigh = @('contoso-admin.sharepoint.us'); dod = @('contoso-admin.sharepoint-mil.us') }
        powerplatform = @{ commercial = @('api.bap.microsoft.com'); gcc = @('gov.api.bap.microsoft.us'); gcchigh = @('high.api.bap.microsoft.us'); dod = @('api.appsplatform.us') }
        teams         = @{
            commercial = @('api.interfaces.records.teams.microsoft.com', 'substrate.office.com')
            gcc        = @('api.interfaces.records.teams.microsoft.com', 'substrate.office.com')
            gcchigh    = @('api.interfaces.records.gov.teams.microsoft.us')
            dod        = @('api.interfaces.records.gov.teams.microsoft.us')
        }
        powerbi       = @{ commercial = @('api.powerbi.com'); gcc = @('api.powerbigov.us'); gcchigh = @('api.high.powerbigov.us'); dod = @('api.mil.powerbigov.us') }
        exo           = @{ commercial = @('outlook.office365.com'); gcc = @('outlook.office365.com'); gcchigh = @('outlook.office365.us'); dod = @('outlook-dod.office365.us') }
        securitysuite = @{
            commercial = @('ps.compliance.protection.outlook.com')
            gcc        = @('ps.compliance.protection.outlook.com')
            gcchigh    = @('ps.compliance.protection.office365.us')
            dod        = @('ps.compliance.protection.office365.us')
        }
    }

    $script:ProductEnvironmentCases = foreach ($Product in $ProductHosts.Keys) {
        foreach ($Environment in 'commercial', 'gcc', 'gcchigh', 'dod') {
            @{
                Product     = $Product
                Environment = $Environment
                Expected    = @(@($GraphHosts[$Environment]) + @($ProductHosts[$Product][$Environment]) | Sort-Object -Unique)
            }
        }
    }

    $script:EnvironmentCases = foreach ($Environment in 'commercial', 'gcc', 'gcchigh', 'dod') {
        @{
            Environment = $Environment
            Expected    = @(@($GraphHosts[$Environment]) + @($ProductHosts.Values | ForEach-Object { $_[$Environment] }) | Sort-Object -Unique)
        }
    }
}

Describe -Tag 'PermissionsHelper' -Name 'Get-ScubaGearEndpointRest' {
    BeforeAll {
        # Load the module here instead of relying on discovery: other test files remove it in AfterAll.
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/Permissions/PermissionsHelper.psm1') -Force
        $script:Hosts = { param($Environment, $Product) @(Get-ScubaGearEndpointRest -ProductNames $Product -M365Environment $Environment -Domain contoso -Format Hosts) -split '\r?\n' | Where-Object { $_ } }
    }

    Context 'Hosts for each product and environment' {
        It 'lists the expected hosts for <Product> in <Environment>' -ForEach $script:ProductEnvironmentCases {
            @(& $script:Hosts $Environment $Product | Sort-Object -Unique) | Should -Be $Expected
        }

        It 'lists the expected hosts for every product in <Environment> by default' -ForEach $script:EnvironmentCases {
            @(Get-ScubaGearEndpointRest -M365Environment $Environment -Domain contoso | ForEach-Object { $_.Host } | Sort-Object -Unique) | Should -Be $Expected
        }

        It 'treats defender as securitysuite' {
            @(& $script:Hosts 'commercial' 'defender') | Should -Be @(& $script:Hosts 'commercial' 'securitysuite')
        }

        It 'treats * as every product Invoke-SCuBA tests' {
            $All = 'aad', 'securitysuite', 'exo', 'powerplatform', 'sharepoint', 'teams', 'powerbi'
            @(Get-ScubaGearEndpointRest -ProductNames '*' -M365Environment gcc -Domain contoso -Format Hosts) |
                Should -Be @(Get-ScubaGearEndpointRest -ProductNames $All -M365Environment gcc -Domain contoso -Format Hosts)
        }

        It 'does not list hosts for products that were not selected' {
            @(& $script:Hosts 'commercial' 'exo') | Should -Not -Contain 'api.powerbi.com'
        }

        It 'lists Microsoft Graph once and names every product that uses it' {
            $Graph = @(Get-ScubaGearEndpointRest -ProductNames exo, teams -Domain contoso | Where-Object { $_.Host -eq 'graph.microsoft.com' })
            $Graph.Count | Should -Be 1
            $Graph[0].Products | Should -Be 'exo, teams'
        }

        It 'labels the Teams unified settings host as Teams' {
            (Get-ScubaGearEndpointRest -ProductNames teams | Where-Object { $_.Host -eq 'substrate.office.com' }).Products | Should -Be 'teams'
        }
    }

    Context 'Object output' {
        It 'uses HTTPS and port 443 for every host' {
            $Rows = @(Get-ScubaGearEndpointRest -Domain contoso)
            $Rows.Count | Should -BeGreaterThan 0
            foreach ($Row in $Rows) {
                $Row.Port | Should -Be 443
                $Row.BaseUrl | Should -Be "https://$($Row.Host)"
                $Row.Environment | Should -Be 'commercial'
                $Row.Purpose | Should -Not -BeNullOrEmpty
            }
        }

        It 'names the API rather than repeating the whole catalog note' {
            (Get-ScubaGearEndpointRest -ProductNames sharepoint -Domain contoso | Where-Object { $_.Host -like '*sharepoint*' }).Purpose | Should -Be 'SharePoint Admin API'
        }
    }

    Context 'SharePoint tenant name' {
        It 'shows a <tenant> placeholder and a note when -Domain is not supplied' {
            $Row = Get-ScubaGearEndpointRest -ProductNames sharepoint | Where-Object { $_.Host -like '*sharepoint*' }
            $Row.Host | Should -Be '<tenant>-admin.sharepoint.com'
            $Row.Note | Should -Match 'Replace <tenant>'
        }

        It 'uses the supplied tenant name and no note' {
            $Row = Get-ScubaGearEndpointRest -ProductNames sharepoint -Domain contoso | Where-Object { $_.Host -like '*sharepoint*' }
            $Row.Host | Should -Be 'contoso-admin.sharepoint.com'
            $Row.Note | Should -BeNullOrEmpty
        }

        It 'rejects a -Domain value that is not a plain tenant name: <Value>' -ForEach @(
            @{ Value = 'a/b' }
            @{ Value = 'a b' }
            @{ Value = 'evil.com/x?' }
            @{ Value = 'contoso.onmicrosoft.com' }
        ) {
            { Get-ScubaGearEndpointRest -Domain $Value } | Should -Throw
        }
    }

    Context 'Text formats' {
        It 'Hosts returns unique host names, one per line, sorted' {
            $Text = Get-ScubaGearEndpointRest -Domain contoso -Format Hosts
            $Lines = $Text -split '\r?\n'
            $Lines | Should -Be @($Lines | Sort-Object -Unique)
            $Lines | Should -Contain 'graph.microsoft.com'
        }

        It 'Csv has a header and one row per object' {
            $Rows = @(Get-ScubaGearEndpointRest -Domain contoso)
            $Parsed = @(Get-ScubaGearEndpointRest -Domain contoso -Format Csv | ConvertFrom-Csv)
            $Parsed.Count | Should -Be $Rows.Count
            $Parsed[0].PSObject.Properties.Name | Should -Be @('Host', 'Port', 'BaseUrl', 'Products', 'Environment', 'Purpose', 'Note')
        }

        It 'Json parses to one entry per object' {
            $Rows = @(Get-ScubaGearEndpointRest -Domain contoso)
            # Assign first: Windows PowerShell 5.1 sends the parsed array down a pipeline as a single item.
            $Parsed = Get-ScubaGearEndpointRest -Domain contoso -Format Json | ConvertFrom-Json
            @($Parsed).Count | Should -Be $Rows.Count
        }

        It 'Json is still an array when only one host matches' {
            (Get-ScubaGearEndpointRest -ProductNames aad -Format Json) | Should -Match '^\s*\['
        }

        It 'Markdown has a header row, a separator row and one row per object' {
            $Rows = @(Get-ScubaGearEndpointRest -Domain contoso)
            $Lines = @(Get-ScubaGearEndpointRest -Domain contoso -Format Markdown) -split '\r?\n'
            $Lines[0] | Should -Be '| Host | Port | Products | Purpose | Note |'
            $Lines[1] | Should -Be '| --- | --- | --- | --- | --- |'
            $Lines.Count | Should -Be ($Rows.Count + 2)
        }
    }

    Context 'OutFile and Clipboard' {
        It 'writes the Hosts format to -OutFile when -Format is Object, without a byte order mark' {
            $Path = Join-Path -Path $TestDrive -ChildPath 'hosts.txt'
            $null = Get-ScubaGearEndpointRest -Domain contoso -OutFile $Path
            $Bytes = [System.IO.File]::ReadAllBytes($Path)
            ($Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB) | Should -BeFalse
            (Get-Content -Path $Path -Raw).TrimEnd() | Should -Be (Get-ScubaGearEndpointRest -Domain contoso -Format Hosts)
        }

        It 'writes the requested format to -OutFile' {
            $Path = Join-Path -Path $TestDrive -ChildPath 'hosts.md'
            $null = Get-ScubaGearEndpointRest -Domain contoso -Format Markdown -OutFile $Path
            (Get-Content -Path $Path)[0] | Should -Be '| Host | Port | Products | Purpose | Note |'
        }

        It 'copies the output to the clipboard' -Skip:(-not (Get-Command -Name Set-Clipboard -ErrorAction SilentlyContinue)) {
            Mock -ModuleName PermissionsHelper Set-Clipboard {}
            $null = Get-ScubaGearEndpointRest -Domain contoso -Clipboard
            Should -Invoke -ModuleName PermissionsHelper Set-Clipboard -Times 1 -Exactly -ParameterFilter { $Value -match 'graph\.microsoft\.com' }
        }
    }

    Context 'Stays in step with the catalog and the module manifest' {
        It 'lists every graphConnect and restBase host in the catalog for some product and environment' {
            $CatalogFile = Join-Path -Path $PSScriptRoot -ChildPath '../../../../schemas/ScubaGearApiCatalog.json'
            # Assign first: Windows PowerShell 5.1 sends the parsed array down a pipeline as a single item.
            $CatalogEntries = Get-Content -Path $CatalogFile -Raw | ConvertFrom-Json
            $FromCatalog = @($CatalogEntries) |
                Where-Object { $_.entryType -in 'graphConnect', 'restBase' } |
                ForEach-Object { ($_.endpointPath -replace '\{domain\}', 'contoso' -replace '^https?://', '') -replace '/.*$', '' } |
                Sort-Object -Unique
            $FromFunction = foreach ($Environment in 'commercial', 'gcc', 'gcchigh', 'dod') {
                Get-ScubaGearEndpointRest -M365Environment $Environment -Domain contoso | ForEach-Object { $_.Host }
            }
            @($FromFunction | Sort-Object -Unique) | Should -Be @($FromCatalog) -Because 'a host added to the catalog should either appear here or be deliberately excluded'
        }

        It 'is exported by the ScubaGear module manifest' {
            $Manifest = Import-PowerShellDataFile -Path (Join-Path -Path $PSScriptRoot -ChildPath '../../../../ScubaGear.psd1')
            $Manifest.FunctionsToExport | Should -Contain 'Get-ScubaGearEndpointRest'
        }

        It 'is exported by the Permissions module' {
            (Get-Module PermissionsHelper).ExportedFunctions.Keys | Should -Contain 'Get-ScubaGearEndpointRest'
        }
    }
}

AfterAll {
    Remove-Module PermissionsHelper -ErrorAction SilentlyContinue
}
