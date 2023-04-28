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
        [string]
        $BaselineName,

        [Parameter(Mandatory=$true)]
        [string]
        $FullName,

        # The location to save the html report in.
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -PathType Container $_})]
        [string]
        $IndividualReportPath,

        # The location to save the html report in.
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -PathType Container $_})]
        [string]
        $OutPath,

        [Parameter(Mandatory=$true)]
        [string]
        $OutProviderFileName,

        [Parameter(Mandatory=$true)]
        [string]
        $OutRegoFileName,

        [Parameter(Mandatory=$true)]
        [switch]
        $DarkMode
    )

    $ScubaGitHubUrl = "https://github.com/cisagov/ScubaGear"

    $SecureBaselines =  Import-SecureBaseline
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
    $MetaDataTable = $MetaDataTable -replace '^(.*?)<table>','<table style = "text-align:center;">'
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
                    "Result"= if ($Control.Deleted) {"-"} else {$Result}
                    "Criticality"=if ($Control.Deleted) {"-"} else {$Test.Criticality}
                    "Details"=if ($Control.Deleted) {"-"} else {$Test.ReportDetails}
                }
            }
            else {
                $Fragment += [pscustomobject]@{
                    "Control ID"=$Control.Id
                    "Requirement"=$Control.Value
                    "Result"= "Bug - Test results missing"
                    "Criticality"= "-"
                    "Details"= "Report bug on <a href=`"$ScubaGitHubUrl/issues`" target=`"_blank`">GitHub</a>"
                }
            }
        }

        $Number = $BaselineName.ToUpper() + '-' + $BaselineGroup.GroupNumber
        $Name = $BaselineGroup.GroupName
        $GroupAnchor = New-MarkdownAnchor -GroupNumber $BaselineGroup.GroupNumber -GroupName $BaselineGroup.GroupName
        #$MarkdownLink = "<a href=`"$($ScubaGitHubUrl)/blob/$($SettingsExport.module_version)/baselines/$($BaselineName.ToLower()).md#$GroupAnchor`">$Name</a>"
        $MarkdownLink = "<a href=`"$ScubaGitHubUrl/blob/AutoBaselineSync/baselines/$($BaselineName.ToLower()).md$GroupAnchor`" target=`"_blank`">$Name</a>"
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
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateScript({Test-Path -PathType Container $_})]
        [string]
        $BaselinePath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\baselines\")
    )

    # $ProductNames = Get-ChildItem $BaselinePath -Filter "*.md" | ForEach-Object {$_.Name.SubString(0, $_.Name.Length - 3)}
    # TODO as other products are updated to the new format
    $ProductNames =  Get-ChildItem $BaselinePath -Filter "teams.md" | ForEach-Object {$_.Name.SubString(0, $_.Name.Length - 3)}
    # add them to above list. Once all products have been updated, replace the list with
    # the commented out code above to generate the list automatically.

    $Output = @{}

    foreach ($Product in $ProductNames) {
        $Output[$Product] = ,@()
        $ProductPath = Join-Path -Path $BaselinePath -ChildPath "$Product.md"
        $MdLines = Get-Content -Path $ProductPath

        # Select-String line numbers aren't 0-indexed, hence the "-1" on the next line
        $LineNumbers = Select-String "## [0-9]+\." "$($BaselinePath)$($Product).md" | ForEach-Object {$_."LineNumber"-1}
        $Groups = $LineNumbers | ForEach-Object {$MdLines[$_]}

        foreach ($GroupName in $Groups) {
            $Group = @{}
            $Group.GroupNumber = $GroupName.Split(".")[0].SubString(3) # 3 to remove the "## "
            $Group.GroupName = $GroupName.Split(".")[1].Trim() # 1 to remove the leading space
            $Group.Controls = @()

            $IdRegex =  "#### MS\.[$($Product.ToUpper())]+\.$($Group.GroupNumber)\."
            # Select-String line numbers aren't 0-indexed, hence the "-1" on the next line
            $LineNumbers = Select-String $IdRegex "$($BaselinePath)$($Product).md" | ForEach-Object {$_."LineNumber"-1}

            foreach ($LineNumber in $LineNumbers) {
                # This assumes that the value is on the immediate next line after the ID
                $LineAdvance = 1;
                $Value = ([string]$MdLines[$LineNumber+$LineAdvance]).Trim()

                while ($Value.Substring($Value.Length-1,1) -ne "."){
                    $LineAdvance++
                    $Value += ' ' + ([string]$MdLines[$LineNumber+$LineAdvance]).Trim()
                }
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

                $Group.Controls += @{"Id"=$Id; "Value"=$Value; "Deleted"=$Deleted}
            }

            $Output[$Product] += $Group
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
    $MangledName = $GroupName.ToLower().Trim().Replace(' ', '-')
    "#$GroupNumber-$MangledName"
}

Export-ModuleMember -Function @(
    'New-Report'
)
