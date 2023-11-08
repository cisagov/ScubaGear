function New-Report {
     <#
    .Description
    This function creates the individual HTML report using the TestResults.json.
    Output will be stored as an HTML file in the InvidualReports folder in the OutPath Folder.
    The report Home page and link tree will be named BaselineReports.html
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Teams", "EXO", "Defender", "AAD", "PowerPlatform", "SharePoint", IgnoreCase = $false)]
        [string]
        $BaselineName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Microsoft Teams", "Exchange Online", "Microsoft 365 Defender", "Azure Active Directory", "Microsoft Power Platform", "SharePoint Online", IgnoreCase = $false)]
        [string]
        $FullName,

        # The location to save the html report in.
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -PathType Container $_})]
        [ValidateNotNullOrEmpty()]
        [string]
        $IndividualReportPath,

        # The location to save the html report in.
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -PathType Container $_})]
        [ValidateScript({Test-Path -IsValid $_})]
        [string]
        $OutPath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutProviderFileName,

        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -IsValid $_})]
        [string]
        $OutRegoFileName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [switch]
        $DarkMode,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [object]
        $SecureBaselines
    )

    $ScubaGitHubUrl = "https://github.com/cisagov/ScubaGear"

    $ProductSecureBaseline = $SecureBaselines.$BaselineName

    $FileName = Join-Path -Path $OutPath -ChildPath "$($OutProviderFileName).json"
    $SettingsExport =  Get-Content $FileName | ConvertFrom-Json

    $FileName = Join-Path -Path $OutPath -ChildPath "$($OutRegoFileName).json"
    $TestResults =  Get-Content $FileName | ConvertFrom-Json

    $Fragments = @()

    $MetaData += [pscustomobject]@{
        "Tenant Display Name" = $SettingsExport.tenant_details.DisplayName;
        "Report Date" = $SettingsExport.date;
        "Baseline Version" = $SettingsExport.baseline_version;
        "Module Version" = $SettingsExport.module_version
    }

    $MetaDataTable = $MetaData | ConvertTo-HTML -Fragment
    $MetaDataTable = $MetaDataTable -replace '^(.*?)<table>','<table id="tenant-data" style = "text-align:center;">'
    $Fragments += $MetaDataTable
    $ReportSummary = @{
        "Warnings" = 0;
        "Failures" = 0;
        "Passes" = 0;
        "Manual" = 0;
        "Errors" = 0;
        "Date" = $SettingsExport.date;
    }

    foreach ($BaselineGroup in $ProductSecureBaseline) {
        $Fragment = @()

        foreach ($Control in $BaselineGroup.Controls){

            $Test = $TestResults | Where-Object -Property PolicyId -eq $Control.Id

            if ($null -ne $Test){
                $MissingCommands = @()

                if ($SettingsExport."$($BaselineName)_successful_commands" -or $SettingsExport."$($BaselineName)_unsuccessful_commands") {
                    # If neither of these keys are present, it means the provider for that baseline
                    # hasn't been updated to the updated error handling method. This check
                    # here ensures backwards compatibility until all providers are udpated.
                    $MissingCommands = $Test.Commandlet | Where-Object {$SettingsExport."$($BaselineName)_successful_commands" -notcontains $_}
                }

                if ($MissingCommands.Count -gt 0) {
                    $Result = "Error"
                    $ReportSummary.Errors += 1
                    $MissingString = $MissingCommands -Join ", "
                    $Test.ReportDetails = "This test depends on the following command(s) which did not execute successfully: $($MissingString). See terminal output for more details."
                }
                elseif ($Test.RequirementMet) {
                    $Result = "Pass"
                    $ReportSummary.Passes += 1
                }
                elseif ($Test.Criticality -eq "Should") {
                    $Result = "Warning"
                    $ReportSummary.Warnings += 1
                }
                elseif ($Test.Criticality.EndsWith('3rd Party') -or $test.Criticality.EndsWith('Not-Implemented')) {
                    $Result = "N/A"
                    $ReportSummary.Manual += 1
                }
                else {
                    $Result = "Fail"
                    $ReportSummary.Failures += 1
                }

                $Fragment += [pscustomobject]@{
                    "Control ID"=$Control.Id
                    "Requirement"=$Control.Value
                    "Result"= if ($Control.Deleted) {
                        "-"
                    }
                    elseif ($Control.MalformedDescription) {
                        $ReportSummary.Errors += 1
                        "Error"
                    }
                    else {
                        $Result
                    }
                    "Criticality"=if ($Control.Deleted -or $Control.MalformedDescription) {"-"} else {$Test.Criticality}
                    "Details"=if ($Control.Deleted) {
                        "-"
                    }
                    elseif ($Control.MalformedDescription){
                        "Report issue on <a href=`"$ScubaGitHubUrl/issues`" target=`"_blank`">GitHub</a>"
                    }
                    else {
                        $Test.ReportDetails
                    }
                }
            }
            else {
                $ReportSummary.Errors += 1
                $Fragment += [pscustomobject]@{
                    "Control ID"=$Control.Id
                    "Requirement"=$Control.Value
                    "Result"= "Error - Test results missing"
                    "Criticality"= "-"
                    "Details"= "Report issue on <a href=`"$ScubaGitHubUrl/issues`" target=`"_blank`">GitHub</a>"
                }
                Write-Warning -Message "WARNING: No test results found for Control Id $($Control.Id)"
            }
        }

        $Number = $BaselineName.ToUpper() + '-' + $BaselineGroup.GroupNumber
        $Name = $BaselineGroup.GroupName
        $GroupAnchor = New-MarkdownAnchor -GroupNumber $BaselineGroup.GroupNumber -GroupName $BaselineGroup.GroupName
        $MarkdownLink = "<a class='control_group' href=`"$($ScubaGitHubUrl)/blob/v$($SettingsExport.module_version)/baselines/$($BaselineName.ToLower()).md#$GroupAnchor`" target=`"_blank`">$Name</a>"
        $Fragments += $Fragment | ConvertTo-Html -PreContent "<h2>$Number $MarkdownLink</h2>" -Fragment
    }

    $Title = "$($FullName) Baseline Report"
    $AADWarning = "<p> Note: Conditional Access (CA) Policy exclusions and additional policy conditions
    may limit a policy's scope more narrowly than desired. Recommend reviewing matching policies
    against the baseline statement to ensure a match between intent and implementation. </p>"
    $NoWarning = "<p><br/></p>"
    Add-Type -AssemblyName System.Web

    $ReporterPath = $PSScriptRoot
    $ReportHTMLPath = Join-Path -Path $ReporterPath -ChildPath "IndividualReport"
    $ReportHTML = (Get-Content $(Join-Path -Path $ReportHTMLPath -ChildPath "IndividualReport.html")) -Join "`n"
    $ReportHTML = $ReportHTML.Replace("{TITLE}", $Title)

    # Handle AAD-specific reporting
    if ($BaselineName -eq "aad") {
        $ReportHTML = $ReportHTML.Replace("{AADWARNING}", $AADWarning)
        $ReportHTML = $ReportHTML.Replace("{CAPTABLES}", "")
        $CapJson = ConvertTo-Json $SettingsExport.cap_table_data
    }
    else {
        $ReportHTML = $ReportHTML.Replace("{AADWARNING}", $NoWarning)
        $ReportHTML = $ReportHTML.Replace("{CAPTABLES}", "")
        $CapJson = "null"
    }

    $CssPath = Join-Path -Path $ReporterPath -ChildPath "styles"
    $MainCSS = (Get-Content $(Join-Path -Path $CssPath -ChildPath "main.css")) -Join "`n"
    $ReportHTML = $ReportHTML.Replace("{MAIN_CSS}", "<style>
        $($MainCSS)
    </style>")

    $ScriptsPath = Join-Path -Path $ReporterPath -ChildPath "scripts"
    $MainJS = (Get-Content $(Join-Path -Path $ScriptsPath -ChildPath "main.js")) -Join "`n"
    $MainJS = "const caps = $($CapJson);`n$($MainJS)"
    $UtilsJS = (Get-Content $(Join-Path -Path $ScriptsPath -ChildPath "utils.js")) -Join "`n"
    $MainJS = "$($MainJS)`n$($UtilsJS)"
    $ReportHTML = $ReportHTML.Replace("{MAIN_JS}", "<script>
        let darkMode = $($DarkMode.ToString().ToLower());
        $($MainJS)
    </script>")

    $ReportHTML = $ReportHTML.Replace("{TABLES}", $Fragments)
    $FileName = Join-Path -Path $IndividualReportPath -ChildPath "$($BaselineName)Report.html"
    [System.Web.HttpUtility]::HtmlDecode($ReportHTML) | Out-File $FileName

    $ReportSummary
}

function Import-SecureBaseline{
    <#
    .Description
    This function parses the secure baseline via each product markdown document to align policy with the
    software baseline.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", 'powerbi', IgnoreCase = $false)]
        [string[]]
        $ProductNames,
        [Parameter(Mandatory = $false)]
        [ValidateScript({Test-Path -PathType Container $_})]
        [string]
        $BaselinePath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\baselines\")
    )
    $Output = @{}

    foreach ($Product in $ProductNames) {
        try {
            Write-Debug "Processing secure baseline markdown for $Product"
            $Output[$Product] = @()
            $ProductPath = Join-Path -Path $BaselinePath -ChildPath "$Product.md"
            $MdLines = Get-Content -Path $ProductPath

            # Select-String line numbers aren't 0-indexed, hence the "-1" on the next line
            $LineNumbers = Select-String "^## [0-9]+\." $ProductPath | ForEach-Object {$_."LineNumber"-1}
            $Groups = $LineNumbers | ForEach-Object {$MdLines[$_]}
            Write-Debug "Found $($Groups.Count) groups"

            foreach ($GroupName in $Groups) {
                $Group = @{}
                $Group.GroupNumber = $GroupName.Split(".")[0].SubString(3) # 3 to remove the "## "
                $Group.GroupName = $GroupName.Split(".")[1].Trim() # 1 to remove the leading space
                $Group.Controls = @()

                $IdRegex =  "#### MS\.[$($Product.ToUpper())]+\.$($Group.GroupNumber)\.\d+v\d+\s*$"
                # Select-String line numbers aren't 0-indexed, hence the "-1" on the next line
                $LineNumbers = Select-String $IdRegex $ProductPath | ForEach-Object {$_."LineNumber"-1}

                # Iterate over matched policy ids found
                foreach ($LineNumber in $LineNumbers) {

                    $Value = [System.Net.WebUtility]::HtmlEncode($Value)
                    $Id = [string]$MdLines[$LineNumber].Substring(5)

                    if ($Id.EndsWith("X")){
                        $Deleted = $true
                        $Id = $Id -Replace ".$"
                        $Value = "[DELETED] " + $Value
                    }
                    else {
                        $Deleted = $false
                    }

                    # This assumes that the value is on the immediate next line after the ID and ends in a period.
                    $LineAdvance = 1;
                    $MaxLineSearch = 20;
                    $Value = ([string]$MdLines[$LineNumber+$LineAdvance]).Trim()
                    $IsMalformedDescription = $false

                    try {
                        if ([string]::IsNullOrWhiteSpace($Value)){
                            $IsMalformedDescription = $true
                            $Value = "Error - The baseline policy text is malformed. Description should start immediately after Policy Id."
                            Write-Error "Expected description for $Id to start on line $($LineNumber+$LineAdvance)"
                        }

                        # Processing multiline description.
                        # TODO: Improve processing GitHub issue #526
                        while ($Value.Substring($Value.Length-1,1) -ne "."){
                            $LineAdvance++

                            if ($Value -match [regex]::Escape("<!--")){
                                # Reached Criticality comment so policy description is complete.
                                break
                            }
                            if (-not [string]::IsNullOrWhiteSpace([string]$MdLines[$LineNumber+$LineAdvance])) {
                                $Value += "`n" + ([string]$MdLines[$LineNumber+$LineAdvance]).Trim()
                            }

                            if ($LineAdvance -gt $MaxLineSearch){
                                Write-Warning "Expected description for $id to end with period and be less than $MaxLineSearch lines"
                                break
                            }
                        }

                        $Group.Controls += @{"Id"=$Id; "Value"=$Value; "Deleted"=$Deleted; MalformedDescription=$IsMalformedDescription}
                    }
                    catch {
                        Write-Error "Error parsing for policies in Group $($Group.GroupNumber). $($Group.GroupName)"
                    }
                }

                $Output[$Product] += $Group
            }
        }
        catch {
            Write-Error -RecommendedAction "Check validity of $Product secure baseline markdown at $ProductPath" `
                -Message "Failed to parse $ProductName secure baseline markdown."
        }
    }

    $Output
}

function New-MarkdownAnchor{
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $GroupNumber,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $GroupName
    )
    [Int32]$OutNumber = $null

    if ($true -eq [Int32]::TryParse($GroupNumber, [ref]$OutNumber)){
        $MangledName = $GroupName.ToLower().Trim().Replace(' ', '-')
        return "#$($GroupNumber.Trim())-$MangledName"
    }
    else {
        $InvalidGroupNumber = New-Object System.ArgumentException "$GroupNumber is not valid"
        throw $InvalidGroupNumber
    }
}

Export-ModuleMember -Function @(
    'New-Report',
    'Import-SecureBaseline'
)
