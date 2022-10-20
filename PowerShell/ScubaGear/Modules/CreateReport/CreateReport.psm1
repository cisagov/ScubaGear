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

     # The location to save the html report in. Defaults to current directory.
    [Parameter(Mandatory=$true)]
    [string]
    $IndividualReportPath,

    # The location to save the html report in. Defaults to current directory.
    [Parameter(Mandatory=$true)]
    [string]
    $OutPath
)

$FileName = Join-Path -Path $PSScriptRoot -ChildPath "BaselineTitles.json"
$AllTitles =  Get-Content $FileName | ConvertFrom-Json
$Titles = $AllTitles.$BaselineName

$FileName = Join-Path -Path $OutPath -ChildPath "TestResults.json"
$TestResults =  Get-Content $FileName | ConvertFrom-Json

$FileName = Join-Path -Path $OutPath -ChildPath "ProviderSettingsExport.json"
$SettingsExport =  Get-Content $FileName | ConvertFrom-Json

$Fragments = @()

$MetaData += [pscustomobject]@{
    "Tenant Name"= $SettingsExport.tenant_details.DisplayName;
    "Report Date"=$SettingsExport.date;
    "Baseline Version"=$SettingsExport.baseline_version;
    "Module Version"=$SettingsExport.module_version
}

$Fragments += $MetaData | ConvertTo-HTML -Fragment

$ReportSummary = @{
    "Warnings" = 0;
    "Failures" = 0;
    "Passes" = 0;
    "Manual" = 0;
    "Date" = $SettingsExport.date;
}

ForEach ($Title in $Titles) {
    $Fragment = @()
    ForEach ($test in $TestResults | Where-Object -Property Control -eq $Title.Number) {
        if ($test.RequirementMet) {
            $Result = "Pass"
            $ReportSummary.Passes += 1
        }
        elseif ($test.Criticality -eq "Should") {
            $Result = "Warning"
            $ReportSummary.Warnings += 1
        }
        elseif ($test.Criticality.EndsWith('3rd Party') -or $test.Criticality.EndsWith('Not-Implemented')) {
            $Result = "N/A"
            $ReportSummary.Manual += 1
        }
        else {
            $Result = "Fail"
            $ReportSummary.Failures += 1
        }

        $Fragment += [pscustomobject]@{
            "Requirement"=$test.Requirement;
            "Result"=$Result;
            "Criticality"=$test.Criticality;
            "Details"=$test.ReportDetails}
    }

    $Number = $Title.Number
    $Name = $Title.Title
    $Fragments += $Fragment | ConvertTo-Html -PreContent "<h2>$Number $Name</h2>" -Fragment
}

$Title = "$($FullName) Baseline Report"
Add-Type -AssemblyName System.Web

$ReporterPath = $PSScriptRoot
$ReportHTML = Get-Content $(Join-Path -Path $ReporterPath -ChildPath "ReportTemplate.html")
$ReportHTML = $ReportHTML.Replace("{TITLE}", $Title)

$MainCSS = Get-Content $(Join-Path -Path $ReporterPath -ChildPath "main.css")
$ReportHTML = $ReportHTML.Replace("{MAIN_CSS}", "<style>$($MainCSS)</style>")

$MainJS = Get-Content $(Join-Path -Path $ReporterPath -ChildPath "main.js")
$ReportHTML = $ReportHTML.Replace("{MAIN_JS}", "<script>$($MainJS)</script>")

$ReportHTML = $ReportHTML.Replace("{TABLES}", $Fragments)
$FileName = Join-Path -Path $IndividualReportPath -ChildPath "$($BaselineName)Report.html"
[System.Web.HttpUtility]::HtmlDecode($ReportHTML) | Out-File $FileName

$ReportSummary
}

Export-ModuleMember -Function @(
    'New-Report'
)
