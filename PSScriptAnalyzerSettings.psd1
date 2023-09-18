# PSScriptAnalyzerSettings.psd1
@{
    Severity=@('Error','Warning','Information')
    ExcludeRules=@(
      'PSUseSingularNouns',
      'PSUseShouldProcessForStateChangingFunctions',
      'PSUseOutputTypeCorrectly'
      )
}
