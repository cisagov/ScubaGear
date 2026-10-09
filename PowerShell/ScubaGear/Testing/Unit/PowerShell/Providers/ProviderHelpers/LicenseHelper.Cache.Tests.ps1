# CC0 1.0 - Pester 5+ tests for Get-CachedSubscribedSku/Clear-SkuCache. Offline, mocked Graph.
# Run: Invoke-Pester -Path 'PowerShell/ScubaGear/Testing/Unit/PowerShell/Providers/ProviderHelpers'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../../../../Modules/Providers/ProviderHelpers/LicenseHelper.psm1") -Force

InModuleScope -ModuleName LicenseHelper {
    Describe -Tag 'LicenseHelper' -Name 'Get-CachedSubscribedSku' {
        BeforeAll {
            $script:Hits = 0
            function Invoke-GraphDirectly {
                [CmdletBinding()]
                param($Commandlet, $M365Environment)
                $null = $Commandlet, $M365Environment # mock body; assignments keep PSSA quiet
                $script:Hits++
                return @{ Value = @(@{ SkuPartNumber = 'DEMO' }) }
            }
            function New-Fetcher {
                return {
                    param($Env)
                    (Invoke-GraphDirectly -Commandlet Get-MgBetaSubscribedSku -M365Environment $Env).Value
                }
            }
            function New-EmptyFetcher {
                # Emulates CommandTracker.TryCommand() on failure: returns @(), no throw.
                return {
                    param($Env)
                    $null = $Env # fixed stub data; assignment keeps PSSA quiet
                    $script:Hits++
                    @()
                }
            }
        }

        BeforeEach {
            $script:Hits = 0
            Clear-SkuCache
        }

        It 'calls Graph once for two logical calls (same env)' {
            Get-CachedSubscribedSku -M365Environment 'commercial' -Fetcher (New-Fetcher) | Out-Null
            Get-CachedSubscribedSku -M365Environment 'commercial' -Fetcher (New-Fetcher) | Out-Null
            $script:Hits | Should -Be 1
        }

        It 'calls Graph per distinct environment' {
            Get-CachedSubscribedSku -M365Environment 'commercial' -Fetcher (New-Fetcher) | Out-Null
            Get-CachedSubscribedSku -M365Environment 'gcc' -Fetcher (New-Fetcher) | Out-Null
            $script:Hits | Should -Be 2
        }

        It 'Reset clears only the given environment' {
            Get-CachedSubscribedSku -M365Environment 'commercial' -Fetcher (New-Fetcher) | Out-Null
            Get-CachedSubscribedSku -M365Environment 'gcc' -Fetcher (New-Fetcher) | Out-Null
            Get-CachedSubscribedSku -M365Environment 'commercial' -Reset | Out-Null
            $script:Hits = 0
            Get-CachedSubscribedSku -M365Environment 'commercial' -Fetcher (New-Fetcher) | Out-Null
            Get-CachedSubscribedSku -M365Environment 'gcc' -Fetcher (New-Fetcher) | Out-Null
            $script:Hits | Should -Be 1   # gcc still cached, commercial refetched
        }

        It 'Clear-SkuCache empties all environments' {
            Get-CachedSubscribedSku -M365Environment 'commercial' -Fetcher (New-Fetcher) | Out-Null
            Get-CachedSubscribedSku -M365Environment 'gcc' -Fetcher (New-Fetcher) | Out-Null
            Clear-SkuCache
            $script:Hits = 0
            Get-CachedSubscribedSku -M365Environment 'commercial' -Fetcher (New-Fetcher) | Out-Null
            Get-CachedSubscribedSku -M365Environment 'gcc' -Fetcher (New-Fetcher) | Out-Null
            $script:Hits | Should -Be 2
        }

        It 'serves a cache hit without a Fetcher' {
            Get-CachedSubscribedSku -M365Environment 'commercial' -Fetcher (New-Fetcher) | Out-Null
            $script:Hits = 0
            $cached = Get-CachedSubscribedSku -M365Environment 'commercial'
            $cached.SkuPartNumber | Should -Be 'DEMO'
            $script:Hits | Should -Be 0
        }

        It 'does not cache empty/failed results (no fail-open poisoning)' {
            # First call: fetcher returns @() like TryCommand on error.
            $miss = Get-CachedSubscribedSku -M365Environment 'commercial' -Fetcher (New-EmptyFetcher)
            @($miss).Count | Should -Be 0
            $script:Hits | Should -Be 1
            # Empty must NOT be cached -> fetcher runs again.
            Get-CachedSubscribedSku -M365Environment 'commercial' -Fetcher (New-EmptyFetcher) | Out-Null
            $script:Hits | Should -Be 2
            # A later good fetch must succeed (cache not poisoned with empty).
            $good = Get-CachedSubscribedSku -M365Environment 'commercial' -Fetcher (New-Fetcher)
            $good.SkuPartNumber | Should -Be 'DEMO'
        }

        It 'returns consistent data across cache hits' {
            $a = Get-CachedSubscribedSku -M365Environment 'commercial' -Fetcher (New-Fetcher)
            $b = Get-CachedSubscribedSku -M365Environment 'commercial' -Fetcher (New-Fetcher)
            $b.SkuPartNumber | Should -Be $a.SkuPartNumber
            $script:Hits | Should -Be 1
        }

        It 'throws on cache miss without a Fetcher' {
            { Get-CachedSubscribedSku -M365Environment 'commercial' } |
                Should -Throw '*Fetcher*'
        }
    }
}
AfterAll {
    Remove-Module LicenseHelper -Force -ErrorAction 'SilentlyContinue'
}
