$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function Format-PlainText -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Format-PlainText' {
        It 'Removes new lines' {
            $Output = Format-PlainText "Hello`nworld"
            $Output | Should -Be "Hello world"
        }
        It 'Removes CAP link' {
            $Output = Format-PlainText "Hello world. <a href='#caps'>View all CA policies</a>. 123"
            $Output | Should -Be "Hello world.  123"
        }
        It 'Removes Security Suite policy table links' {
            $Output = Format-PlainText "Requirement not met.<br/><a href='#securitysuite-anti-spam-policies'>View all anti-spam policies</a>"
            $Output | Should -Be "Requirement not met. "
        }
        It 'Removes every in-page link in the string' {
            # The details of a single control can carry more than one link, and the text
            # between two of them has to survive.
            $Output = Format-PlainText "A. <a href='#caps'>View all CA policies</a>. B. <a href='#securitysuite-anti-spam-policies-table'>View all anti-spam policies</a> C."
            $Output | Should -Be "A.  B.  C."
        }
        It 'Keeps links that point outside the report' {
            # Policy indicators are anchors written with the same single quotes as the in-page
            # links, so the in-page rule has to key off the leading '#' and leave these alone.
            $Indicator = "<a href='https://www.cisa.gov/news-events/directives/bod-25-01' target='_blank' class='indicator'>BOD 25-01 Requirement</a>"
            $Output = Format-PlainText "Emails SHALL NOT be delivered.$Indicator"
            $Output | Should -Match "https://www\.cisa\.gov/news-events/directives/bod-25-01"
            $Output | Should -Match "BOD 25-01 Requirement"
        }
        It 'Removes br tags' {
            $Output = Format-PlainText "Hello world.<br/>123"
            $Output | Should -Be "Hello world. 123"
        }
        It 'Removes b tags' {
            $Output = Format-PlainText "<b>Hello world.</b> 123"
            $Output | Should -Be "Hello world. 123"
        }
        It 'Removes html comments' {
            $Output = Format-PlainText "Hello world.<!-- insert sneaky comment that shouldn't render--> 123"
            $Output | Should -Be "Hello world. 123"
        }
        It 'Removes multiple things at once' {
            $Output = Format-PlainText "<b>Hello</b><br/>world.<!-- insert sneaky comment that shouldn't render--> 123"
            $Output | Should -Be "Hello world. 123"
        }
        Context "When reformatting links" {
            It 'Reformats basic links' {
                $Output = Format-PlainText 'See <a href="example.com" target="_blank">this example</a> for more details.'
                $Output | Should -Be "See this example, example.com for more details."
            }
            It 'Reformats links with special symbols' {
                $Output = Format-PlainText 'See <a href="https://example.com#anchor?p1=v1&p2=v2" target="_blank">this example</a> for more details.'
                $Output | Should -Be "See this example, https://example.com#anchor?p1=v1&p2=v2 for more details."
            }
            It 'Reformats links without target' {
                $Output = Format-PlainText 'See <a href="example.com">this example</a> for more details.'
                $Output | Should -Be "See this example, example.com for more details."
            }
            It 'Reformats links when there is no trailing content' {
                $Output = Format-PlainText 'See <a href="https://example.com#anchor?p1=v1&p2=v2" target="_blank">this example</a>.'
                $Output | Should -Be "See this example, https://example.com#anchor?p1=v1&p2=v2."
            }
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}