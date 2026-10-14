$UtilityPath = '../../../../Modules/Utility/Utility.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $UtilityPath) -Function 'Get-HttpResponseDetails' -Force

InModuleScope Utility {
    Describe -Tag 'Utility' -Name 'Get-HttpResponseDetails' {
        Context 'HttpResponseMessage (PowerShell 7+ exception .Response shape)' {
            BeforeAll {
                # Not loaded by default on PS 5.1 Desktop; must be loaded explicitly before the type can be constructed.
                Add-Type -AssemblyName System.Net.Http
            }

            It 'Formats status, headers and body from the ErrorDetailsMessage parameter' {
                $Response = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::Unauthorized)
                $Response.ReasonPhrase = 'Unauthorized'
                $Response.Headers.Add('X-Test-Header', 'test-value')

                $Details = Get-HttpResponseDetails -HttpResponseObject $Response -ErrorDetailsMessage '{"message":"Bad credentials"}'

                $Details | Should -Match 'Response Type : System\.Net\.Http\.HttpResponseMessage'
                $Details | Should -Match 'Status Code   : 401'
                $Details | Should -Match 'Status Text   : Unauthorized'
                $Details | Should -Match 'X-Test-Header: test-value'
                $Details | Should -Match '\{"message":"Bad credentials"\}'
            }

            It 'Reports an empty body when ErrorDetailsMessage is not supplied' {
                $Response = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::InternalServerError)
                $Response.ReasonPhrase = 'Internal Server Error'

                $Details = Get-HttpResponseDetails -HttpResponseObject $Response

                $Details | Should -Match 'Empty response body\.'
            }
        }

        Context 'HttpWebResponse (PowerShell 5.1 exception .Response shape)' {
            BeforeAll {
                # HttpWebResponse has no public constructor, so we duck-type a fake with the same members
                # Get-HttpResponseDetails actually reads. It falls into this branch by not matching the other two.
                function New-FakeHttpWebResponse {
                    param(
                        [int] $StatusCode = 404,
                        [string] $StatusDescription = 'Not Found',
                        [string] $Body = '{"message":"Not Found"}',
                        [switch] $NoStream
                    )

                    $BodyBytes = [System.Text.Encoding]::UTF8.GetBytes($Body)
                    $FakeHeaders = [System.Net.WebHeaderCollection]::new()
                    $FakeHeaders.Add('X-Fake-Header', 'fake-value')

                    $Fake = [PSCustomObject]@{
                        StatusCode        = $StatusCode
                        StatusDescription = $StatusDescription
                        ContentType       = 'application/json'
                        ContentLength     = $BodyBytes.Length
                        Headers           = $FakeHeaders
                        FakeStream        = if ($NoStream) { $null } else { [System.IO.MemoryStream]::new($BodyBytes) }
                    }
                    $Fake | Add-Member -MemberType ScriptMethod -Name GetResponseStream -Value { return $this.FakeStream }
                    return $Fake
                }
            }

            It 'Formats status, headers and body from the response stream' {
                $Response = New-FakeHttpWebResponse -StatusCode 404 -StatusDescription 'Not Found' -Body '{"message":"Not Found"}'

                $Details = Get-HttpResponseDetails -HttpResponseObject $Response

                $Details | Should -Match 'Status Code   : 404'
                $Details | Should -Match 'Status Text   : Not Found'
                $Details | Should -Match 'Content Type  : application/json'
                $Details | Should -Match 'X-Fake-Header: fake-value'
                $Details | Should -Match '\{"message":"Not Found"\}'
            }

            It 'Reports no response stream when GetResponseStream returns null' {
                $Response = New-FakeHttpWebResponse -NoStream

                $Details = Get-HttpResponseDetails -HttpResponseObject $Response

                $Details | Should -Match 'No response stream in Error\.Exception\.Response object\.'
            }

            It 'Reports an empty body when the response stream has no content' {
                $Response = New-FakeHttpWebResponse -Body ''

                $Details = Get-HttpResponseDetails -HttpResponseObject $Response

                $Details | Should -Match 'Empty response body\.'
            }
        }

        Context 'WebResponseObject (direct Invoke-WebRequest success return value)' -Tag 'Network' {
            It 'Formats status, headers and body from a live HTTP response' {
                # WebResponseObject has no accessible constructor, and its assembly isn't even resolvable
                # until Invoke-WebRequest has been called at least once - a real request is the only reliable way to get one.
                $Response = Invoke-WebRequest -Uri 'https://www.githubstatus.com' -UseBasicParsing -ErrorAction Stop

                $Details = Get-HttpResponseDetails -HttpResponseObject $Response

                $Details | Should -Match 'Response Type : Microsoft\.PowerShell\.Commands\.'
                $Details | Should -Match 'Status Code   : 200'
                $Details | Should -Not -Match 'Empty response body\.'
            }
        }
    }
}

AfterAll {
    Remove-Module Utility -ErrorAction SilentlyContinue
}
