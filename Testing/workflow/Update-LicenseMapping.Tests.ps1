# The purpose of these tests is to verify that the license mapping update helpers work.

Describe "Update License Mapping" {
    BeforeAll {
        $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Update-LicenseMapping.ps1' -Resolve
        . $ScriptPath
    }

    It "Downloads, normalizes, and overwrites the mapping file in place" {
        $RepoRootPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ("license-mapping-repo-{0}" -f [guid]::NewGuid())
        $MappingDir = Join-Path -Path $RepoRootPath -ChildPath 'PowerShell/ScubaGear/Modules/CreateReport'
        $MappingPath = Join-Path -Path $MappingDir -ChildPath 'MicrosoftLicenseToProductNameMappings.csv'
        New-Item -ItemType Directory -Path $MappingDir -Force | Out-Null
        # Seed an existing (stale) mapping file, as would exist in a real checkout.
        'Product_Display_Name,String_Id,GUID' | Set-Content -Path $MappingPath

        Mock -CommandName Invoke-WebRequest -MockWith {
            param($Uri, $OutFile, $UseBasicParsing)
            @(
                'Product_Display_Name,String_Id,GUID,Service_Plan_Name,Service_Plan_Id,Service_Plans_Included_Friendly_Names'
                'Microsoft 365 E7,MICROSOFT_365_E7,9A18296A-025F-4E37-9FFA-30BF8D1CE775,PLAN_A,11111111-1111-1111-1111-111111111111,Plan A'
                'Microsoft 365 E7,MICROSOFT_365_E7,9A18296A-025F-4E37-9FFA-30BF8D1CE775,PLAN_B,22222222-2222-2222-2222-222222222222,Plan B'
                'Product B , PROD_B ,bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb,PLAN_C,33333333-3333-3333-3333-333333333333,Plan C'
            ) -join "`n" | Set-Content -Path $OutFile
        }

        try {
            $Count = Update-LicenseMappingFile -RepoPath $RepoRootPath

            # The two Microsoft 365 E7 service-plan rows collapse into one product mapping.
            $Count | Should -Be 2

            $Updated = @(Import-Csv -Path $MappingPath)
            $Updated.Count | Should -Be 2

            $E7 = $Updated | Where-Object { $_.String_Id -eq 'MICROSOFT_365_E7' }
            $E7.Product_Display_Name | Should -Be 'Microsoft 365 E7'
            $E7.GUID | Should -Be '9a18296a-025f-4e37-9ffa-30bf8d1ce775'

            $ProductB = $Updated | Where-Object { $_.String_Id -eq 'PROD_B' }
            $ProductB.Product_Display_Name | Should -Be 'Product B'
        }
        finally {
            Remove-Item -Path $RepoRootPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Throws when the destination mapping file does not exist" {
        $MissingRepoPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ("license-mapping-missing-{0}" -f [guid]::NewGuid())
        { Update-LicenseMappingFile -RepoPath $MissingRepoPath } | Should -Throw "*Couldn't find license mapping CSV*"
    }
}
