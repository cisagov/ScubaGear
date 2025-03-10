@{
    Severity     = @('Error', 'Warning', 'Information', 'Info')
    ExcludeRules = @(
        'PSUseSingularNouns',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSUseOutputTypeCorrectly'
    )
    Rules        = @{
        PSProvideCommentHelp = @{
            Enable                  = $true
            ExportedOnly            = $false
            BlockComment            = $true
            VSCodeSnippetCorrection = $false
            Placement               = 'begin'
        }
    }
}
