Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/CreateReport') `
    -Function 'Get-PolicyTableLinkHtml' -Force

InModuleScope CreateReport {
    Describe -Tag CreateReport -Name 'Get-PolicyTableLinkHtml' {
        BeforeAll {
            # The anchors these link to are set on the table headings by
            # SecuritySuiteTableFunctions.js.
            function Get-MockTest {
                param([string[]]$Commandlet)
                [PSCustomObject]@{ "Commandlet" = $Commandlet }
            }
        }

        Context "When a failing control was evaluated against a policy table" {
            It 'Links <PolicyId> to <Anchor>' -ForEach @(
                @{
                    PolicyId = 'MS.SECURITYSUITE.1.1v1'
                    Commandlet = @("Get-MalwareFilterPolicy", "Get-MalwareFilterRule", "Get-EOPProtectionPolicyRule")
                    Anchor = 'securitysuite-anti-malware-policies-table'
                    Label = 'anti-malware'
                },
                @{
                    PolicyId = 'MS.SECURITYSUITE.2.1v1'
                    Commandlet = @("Get-AntiPhishPolicy", "Get-AntiPhishRule", "Get-EOPProtectionPolicyRule")
                    Anchor = 'securitysuite-anti-phish-policies-table'
                    Label = 'anti-phish'
                },
                @{
                    PolicyId = 'MS.SECURITYSUITE.6.1v1'
                    Commandlet = @("Get-HostedContentFilterPolicy", "Get-HostedContentFilterRule", "Get-EOPProtectionPolicyRule")
                    Anchor = 'securitysuite-anti-spam-policies-table'
                    Label = 'anti-spam'
                }
            ) {
                $Test = Get-MockTest -Commandlet $Commandlet
                $Result = Get-PolicyTableLinkHtml -BaselineName "SecuritySuite" -Test $Test -DisplayString "Fail"
                $Result | Should -Be "<br/><a href='#$Anchor'>View all $Label policies</a>"
            }

            It 'Links <PolicyId> to an anchor SecuritySuiteTableFunctions.js creates' -ForEach @(
                @{ PolicyId = 'MS.SECURITYSUITE.1.1v1'; Commandlet = @("Get-MalwareFilterPolicy") },
                @{ PolicyId = 'MS.SECURITYSUITE.2.1v1'; Commandlet = @("Get-AntiPhishPolicy") },
                @{ PolicyId = 'MS.SECURITYSUITE.6.1v1'; Commandlet = @("Get-HostedContentFilterPolicy") }
            ) {
                # The table heading's id is its CSS class, so every anchor this function emits
                # must appear as a table class in the script that builds the tables. Without this
                # the two can drift apart and the link silently goes nowhere.
                $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/CreateReport/scripts/SecuritySuiteTableFunctions.js' -Resolve
                $TableScript = Get-Content -Path $ScriptPath -Raw

                $Test = Get-MockTest -Commandlet $Commandlet
                $Link = Get-PolicyTableLinkHtml -BaselineName "SecuritySuite" -Test $Test -DisplayString "Fail"
                $Anchor = [regex]::Match($Link, "href='#([^']+)'").Groups[1].Value

                $Anchor | Should -Not -BeNullOrEmpty
                # Compared as a boolean so a failure reports the missing anchor rather than
                # dumping the whole script into the test output.
                $TableScript.Contains("`"$Anchor`"") | Should -BeTrue -Because "$PolicyId links to '#$Anchor', which must be a table class in SecuritySuiteTableFunctions.js"
            }

            It 'Links failed SHOULD controls, which display as a warning' {
                $Test = Get-MockTest -Commandlet @("Get-HostedContentFilterPolicy")
                $Result = Get-PolicyTableLinkHtml -BaselineName "SecuritySuite" -Test $Test -DisplayString "Warning"
                $Result | Should -Be "<br/><a href='#securitysuite-anti-spam-policies-table'>View all anti-spam policies</a>"
            }
        }

        Context "When the control should not link to a table" {
            It 'Returns nothing for a <DisplayString> result' -ForEach @(
                @{ DisplayString = 'Pass' },
                @{ DisplayString = 'N/A' },
                @{ DisplayString = 'Error' }
            ) {
                $Test = Get-MockTest -Commandlet @("Get-HostedContentFilterPolicy")
                $Result = Get-PolicyTableLinkHtml -BaselineName "SecuritySuite" -Test $Test -DisplayString $DisplayString
                $Result | Should -Be ""
            }

            It 'Returns nothing when no table shows the policies the control was evaluated against' {
                # MS.SECURITYSUITE.1.3v1 and 7.1v1 check safe attachment and safe links policies,
                # which have no table in the report.
                $Test = Get-MockTest -Commandlet @("Get-SafeAttachmentPolicy", "Get-SafeAttachmentRule")
                $Result = Get-PolicyTableLinkHtml -BaselineName "SecuritySuite" -Test $Test -DisplayString "Fail"
                $Result | Should -Be ""

                $Test = Get-MockTest -Commandlet @("Get-SafeLinksPolicy", "Get-SafeLinksRule", "Get-EOPProtectionPolicyRule")
                $Result = Get-PolicyTableLinkHtml -BaselineName "SecuritySuite" -Test $Test -DisplayString "Fail"
                $Result | Should -Be ""
            }

            It 'Returns nothing for the <BaselineName> baseline' -ForEach @(
                @{ BaselineName = 'AAD' },
                @{ BaselineName = 'EXO' },
                @{ BaselineName = 'Teams' }
            ) {
                # The tables only exist in the Security Suite report, so no other baseline links
                # to them even when its test ran the same cmdlet.
                $Test = Get-MockTest -Commandlet @("Get-AntiPhishPolicy")
                $Result = Get-PolicyTableLinkHtml -BaselineName $BaselineName -Test $Test -DisplayString "Fail"
                $Result | Should -Be ""
            }

            It 'Returns nothing when the test has no commandlets' {
                $Test = Get-MockTest -Commandlet @()
                $Result = Get-PolicyTableLinkHtml -BaselineName "SecuritySuite" -Test $Test -DisplayString "Fail"
                $Result | Should -Be ""
            }
        }
    }
}
