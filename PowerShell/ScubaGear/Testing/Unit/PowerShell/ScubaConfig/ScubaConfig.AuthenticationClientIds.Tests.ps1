using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

Describe 'Authentication client ID defaults' {
    It 'returns a hashtable covering every ScubaGear product' {
        $ClientIdHash = [ScubaConfig]::ScubaDefault('AuthenticationClientIdHashtable')

        $ClientIdHash | Should -BeOfType [hashtable]
        @($ClientIdHash.Keys | Sort-Object) | Should -Be @([ScubaConfig]::ScubaDefault('AllProductNames') | Sort-Object)
    }

    It 'maps <Product> to its Microsoft public client' -TestCases @(
        @{ Product = 'aad'; ClientId = '14d82eec-204b-4c2f-b7e8-296a70dab67e' },
        @{ Product = 'exo'; ClientId = 'fb78d390-0c51-40cd-8e17-fdbfab77341b' },
        @{ Product = 'securitysuite'; ClientId = 'fb78d390-0c51-40cd-8e17-fdbfab77341b' },
        @{ Product = 'powerplatform'; ClientId = '1950a258-227b-4e31-a9cf-717495945fc2' },
        @{ Product = 'powerbi'; ClientId = '1950a258-227b-4e31-a9cf-717495945fc2' },
        @{ Product = 'sharepoint'; ClientId = '9bc3ab49-b65d-410a-85ad-de819febfddc' },
        @{ Product = 'teams'; ClientId = '12128f48-ec9e-42f0-b203-ea49fb6af367' }
    ) {
        param($Product, $ClientId)
        $ClientIdHash = [ScubaConfig]::ScubaDefault('AuthenticationClientIdHashtable')

        $ClientIdHash[$Product] | Should -Be $ClientId
    }
}
