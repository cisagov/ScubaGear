@{
    Severity     = @('Error', 'Warning', 'Information')
    ExcludeRules = @(
        'PSUseSingularNouns',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSUseOutputTypeCorrectly',
        'PSAvoidUsingWriteHost'
    )
}
