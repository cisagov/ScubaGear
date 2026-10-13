Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/Support')

InModuleScope 'Support' {
    Describe "Install-ScubaDependencies PSGallery trust" {
        BeforeAll {
            # Set-PSRepository has dynamic parameters that Pester cannot mock directly,
            # so mock a stub with the parameters the function uses
            function Set-PSRepository {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
                param($Name, $InstallationPolicy)
                throw 'this will be mocked'
            }
        }

        BeforeEach {
            # Mock output functions
            Mock Write-Information { }
            Mock Write-Output { }
            Mock Write-Debug { }

            # Skip module installation so only the repository trust logic runs
            Mock Get-ScubaRequiredModuleList { return @() }
            Mock Install-Module { }
            Mock Set-PSRepository { }
        }

        It "Should not change PSGallery when it is already trusted" {
            Mock Get-PSRepository { return [PSCustomObject]@{ Name = 'PSGallery'; InstallationPolicy = 'Trusted' } }

            Install-ScubaDependencies -NoOPA

            Assert-MockCalled Set-PSRepository -Times 0 -Exactly
        }

        It "Should trust PSGallery when it is untrusted" {
            Mock Get-PSRepository { return [PSCustomObject]@{ Name = 'PSGallery'; InstallationPolicy = 'Untrusted' } }

            Install-ScubaDependencies -NoOPA

            Assert-MockCalled Set-PSRepository -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'PSGallery' -and $InstallationPolicy -eq 'Trusted'
            }
        }

        It "Should not change PSGallery when DoNotAutoTrustRepository is set" {
            Mock Get-PSRepository { return [PSCustomObject]@{ Name = 'PSGallery'; InstallationPolicy = 'Untrusted'; Trusted = $false } }

            Install-ScubaDependencies -NoOPA -DoNotAutoTrustRepository

            Assert-MockCalled Set-PSRepository -Times 0 -Exactly
        }
    }
}
