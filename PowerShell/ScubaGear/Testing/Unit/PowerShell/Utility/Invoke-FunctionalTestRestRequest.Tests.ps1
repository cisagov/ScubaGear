Describe -Tag 'FunctionalTestUtils' -Name 'Invoke-FunctionalTestRestRequest' {
    BeforeAll {
        $FunctionalTestUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath '../../../../../../Testing/Functional/Products/FunctionalTestUtils.ps1'
        . $FunctionalTestUtilsPath
    }

    BeforeEach {
        $script:InvokeWebRequestCalls = @()
        $script:SleepCalls = @()

        Mock Start-Sleep {
            param([int] $Seconds)
            $script:SleepCalls += $Seconds
        }

        Mock Get-HttpResponseDetails { return "Bogus HTTP error response details" }
    }

    It 'polls a location URL after a 202 response until the request completes' {
        Mock Invoke-WebRequest {
            param(
                [string] $Uri,
                [string] $Method,
                [hashtable] $Headers,
                [string] $Body,
                [string] $ContentType,
                [string] $ErrorAction
            )

            $script:InvokeWebRequestCalls += [PSCustomObject]@{
                Uri = $Uri
                Method = $Method
                Headers = $Headers
                Body = $Body
                ContentType = $ContentType
                ErrorAction = $ErrorAction
            }

            if ($script:InvokeWebRequestCalls.Count -eq 1) {
                return [PSCustomObject]@{
                    StatusCode = 202
                    Headers = @{
                        Location = '/operations/tenant-isolation/123'
                        'Retry-After' = '7'
                    }
                    Content = ''
                }
            }

            return [PSCustomObject]@{
                StatusCode = 200
                Headers = @{}
                Content = '{"value":{"isDisabled":true}}'
            }
        }

        $result = Invoke-FunctionalTestRestRequest -Uri 'https://api.contoso.test/providers/example' -Method 'PUT' -Headers @{ Authorization = 'Bearer token' } -Body '{"enabled":true}' -ContentType 'application/json'

        $result.value.isDisabled | Should -BeTrue
        $script:SleepCalls | Should -Be @(7)
        $script:InvokeWebRequestCalls.Count | Should -Be 2
        $script:InvokeWebRequestCalls[0].Method | Should -Be 'PUT'
        $script:InvokeWebRequestCalls[1].Method | Should -Be 'GET'
        $script:InvokeWebRequestCalls[1].Uri | Should -Be 'https://api.contoso.test/operations/tenant-isolation/123'
    }

    It 'throws forbidden error when a Power BI update throws a 403 status code' {
        Mock Invoke-WebRequest {
            $exception = [System.Exception]::new('Forbidden')
            $exception | Add-Member -NotePropertyName Response -NotePropertyValue ([PSCustomObject]@{ StatusCode = 403 })
            throw $exception
        }

        { Set-PowerBITenantSetting -SettingName 'ExportData' -Settings @{ Enabled = $true; } } | Should -Throw '*Forbidden*'
    }

    It 'throws generic error when a Power BI update returns a 300 non-success status code but does not error' {
        Mock Invoke-WebRequest {
            return [PSCustomObject]@{
                StatusCode = 300
            }
        }

        { Set-PowerBITenantSetting -SettingName 'ExportData' -Settings @{ Enabled = $true; } } | Should -Throw '*unexpected HTTP status code*'
    }
}
