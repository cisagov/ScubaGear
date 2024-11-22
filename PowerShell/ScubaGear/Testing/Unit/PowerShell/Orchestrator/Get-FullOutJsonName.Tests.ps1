$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Get-FullOutJsonName'

Describe -Tag 'Orchestrator' -Name 'Get-FullOutJsonName' {
    InModuleScope Orchestrator {
        It 'Adds the full UUID' {
            $FullNameParams = @{
                'OutJsonFileName'                  = "ScubaResults";
                'Guid'                             = "30ebce05-f8f0-4a09-8ec2-589efbbd0e72";
                'NumberOfUUIDCharactersToTruncate' = 0;
            }
            (Get-FullOutJsonName @FullNameParams) | Should -eq "ScubaResults_30ebce05-f8f0-4a09-8ec2-589efbbd0e72.json"
        }
        It 'Handles partial truncation' {
            $FullNameParams = @{
                'OutJsonFileName'                  = "ScubaResults";
                'Guid'                             = "30ebce05-f8f0-4a09-8ec2-589efbbd0e72";
                'NumberOfUUIDCharactersToTruncate' = 18;
            }
            (Get-FullOutJsonName @FullNameParams) | Should -eq "ScubaResults_30ebce05-f8f0-4a09.json"
        }
        It 'Handles full truncation' {
            $FullNameParams = @{
                'OutJsonFileName'                  = "ScubaResults";
                'Guid'                             = "30ebce05-f8f0-4a09-8ec2-589efbbd0e72";
                'NumberOfUUIDCharactersToTruncate' = 36;
            }
            (Get-FullOutJsonName @FullNameParams) | Should -eq "ScubaResults.json"
        }
        It 'Handles non-default names' {
            $FullNameParams = @{
                'OutJsonFileName'                  = "my_results";
                'Guid'                             = "30ebce05-f8f0-4a09-8ec2-589efbbd0e72";
                'NumberOfUUIDCharactersToTruncate' = 18;
            }
            (Get-FullOutJsonName @FullNameParams) | Should -eq "my_results_30ebce05-f8f0-4a09.json"
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}