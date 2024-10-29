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
                $Output | Should -Be "See this example, https://example.com#anchor?p1=v1&amp;p2=v2 for more details."
            }
            It 'Reformats links without target' {
                $Output = Format-PlainText 'See <a href="example.com">this example</a> for more details.'
                $Output | Should -Be "See this example, example.com for more details."
            }
            It 'Reformats links when there is no trailing content' {
                $Output = Format-PlainText 'See <a href="https://example.com#anchor?p1=v1&p2=v2" target="_blank">this example</a>.'
                $Output | Should -Be "See this example, https://example.com#anchor?p1=v1&amp;p2=v2."
            }
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}