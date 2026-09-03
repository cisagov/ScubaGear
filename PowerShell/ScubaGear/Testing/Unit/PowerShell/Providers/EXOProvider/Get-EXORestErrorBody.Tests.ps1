$HelperPath = "../../../../../Modules/Providers/ProviderHelpers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($HelperPath)/EXORestHelper.psm1") -Force

InModuleScope EXORestHelper {
    Describe -Tag 'EXORestHelper' -Name "Get-EXORestErrorBody" {
        BeforeAll {
            function New-TestErrorRecord {
                param (
                    [Parameter(Mandatory = $false)]
                    [string]
                    $Details
                )

                $Exception = [System.Exception]::new("Response status code does not indicate success: 400 (Bad Request).")
                $Record = [System.Management.Automation.ErrorRecord]::new(
                    $Exception,
                    "WebCmdletWebResponseException",
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $null
                )

                if (-not [string]::IsNullOrWhiteSpace($Details)) {
                    $Record.ErrorDetails = [System.Management.Automation.ErrorDetails]::new($Details)
                }

                return $Record
            }
        }

        It "Returns the response body the error record carries" {
            $Body = '{"error":{"code":"BadRequest","message":"Error executing cmdlet"}}'
            $Record = New-TestErrorRecord -Details $Body

            Get-EXORestErrorBody -ErrorRecord $Record | Should -Be $Body
        }

        It "Returns an empty string when there is no body and no response to read" {
            $Record = New-TestErrorRecord

            Get-EXORestErrorBody -ErrorRecord $Record | Should -Be ""
        }
    }
}

AfterAll {
    Remove-Module EXORestHelper -Force -ErrorAction SilentlyContinue
}
