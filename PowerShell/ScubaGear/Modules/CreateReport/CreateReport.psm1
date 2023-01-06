function Get-CapTable {
    $FileName = Join-Path -Path $OutPath -ChildPath "$($OutProviderFileName).json"
    $SettingsExport =  Get-Content $FileName | ConvertFrom-Json
    $Caps = $SettingsExport.conditional_access_policies

    $ExternalUserStrings = @{"b2bCollaborationGuest" = "B2B collaboration guest users";
        "b2bCollaborationMember" = "B2B collaboration member users";
        "b2bDirectConnectUser" = "B2B direct connect users";
        "internalGuest" = "Local guest users";
        "serviceProvider" = "Service provider users";
        "otherExternalUser" = "Other external users"}

    $Table = @()

    foreach ($Cap in $Caps) {

        $IncludedUsers = @()
        if ($Cap.Conditions.Users.IncludeUsers -Contains "All") {
            $IncludedUsers += "All"
        }
        elseif ($Cap.Conditions.Users.IncludeUsers -Contains "None") {
            $IncludedUsers += "None"
        }
        else {
            $SpecificUsers = @($Cap.Conditions.Users.IncludeUsers | Where-Object {$_ -ne "All"})
            if ($SpecificUsers.Length -eq 1) {
                $IncludedUsers += "$($SpecificUsers.Length) specific user"
            }
            elseif ($SpecificUsers.Length -gt 1) {
                $IncludedUsers += "$($SpecificUsers.Length) specific users"
            }

            $SpecificRoles = @($Cap.Conditions.Users.IncludeRoles | Where-Object {$_ -ne "All"})
            if ($SpecificRoles.Length -eq 1) {
                $IncludedUsers += "$($SpecificRoles.Length) specific role"
            }
            elseif ($SpecificRoles.Length -gt 1) {
                $IncludedUsers += "$($SpecificRoles.Length) specific roles"
            }

            $SpecificGroups = @($Cap.Conditions.Users.IncludeGroups | Where-Object {$_ -ne "All"})
            if ($SpecificGroups.Length -eq 1) {
                $IncludedUsers += "$($SpecificGroups.Length) specific group"
            }
            elseif ($SpecificGroups.Length -gt 1) {
                $IncludedUsers += "$($SpecificGroups.Length) specific groups"
            }

            if ($null -ne $Cap.Conditions.Users.IncludeGuestsOrExternalUsers.ExternalTenants.MembershipKind) {
                $GuestOrExternalUserTypes = $Cap.Conditions.Users.IncludeGuestsOrExternalUsers.GuestOrExternalUserTypes -Split ","
                $IncludedUsers += @($GuestOrExternalUserTypes | ForEach-Object {$ExternalUserStrings[$_]})
            }
        }
        $IncludedUsers = $IncludedUsers -Join ", "

        $CapDetails = [pscustomobject]@{
            "Name" = $Cap.DisplayName;
            "Users included" = $IncludedUsers -Join ", ";
            "Users excluded" = ""
        }

        $Table += $CapDetails
    }

    $TableHtml = $Table | ConvertTo-Html -Fragment
    $TableHtml = "<div class=caps>$($TableHtml)</div>"
    $TableHtml
}

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
        $OutRegoFileName
    )

    $FileName = Join-Path -Path $PSScriptRoot -ChildPath "BaselineTitles.json"
    $AllTitles =  Get-Content $FileName | ConvertFrom-Json
    $Titles = $AllTitles.$BaselineName

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

    foreach ($Title in $Titles) {
        $Fragment = @()
        foreach ($test in $TestResults | Where-Object -Property Control -eq $Title.Number) {
            $MissingCommands = @()

            if ($SettingsExport."$($BaselineName)_successful_commands" -or $SettingsExport."$($BaselineName)_unsuccessful_commands") {
                # If neither of these keys are present, it means the provider for that baseline
                # hasn't been updated to the updated error handling method. This check
                # here ensures backwards compatibility until all providers are udpated.
                $MissingCommands = $test.Commandlet | Where-Object {$SettingsExport."$($BaselineName)_successful_commands" -notcontains $_}
            }

            if ($MissingCommands.Count -gt 0) {
                $Result = "Error"
                $ReportSummary.Errors += 1
                $MissingString = $MissingCommands -Join ", "
                $test.ReportDetails = "This test depends on the following command(s) which did not execute successfully: $($MissingString). See terminal output for more details."
            }
            elseif ($test.RequirementMet) {
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

        if ($Number -eq "AAD 2.1") {
            $Fragments += Get-CapTable
        }
    }

    $Title = "$($FullName) Baseline Report"
    $AADWarning = "<p> Note: Conditional Access Policy exclusions and additional policy conditions
    may limit a policy's scope more narrowly than desired. Recommend reviewing matching policies
    against the baseline statement to ensure a match between intent and implementation. </p>"
    $NoWarning = "<p><br/></p>"
    Add-Type -AssemblyName System.Web

    $ReporterPath = $PSScriptRoot
    $ReportHTML = Get-Content $(Join-Path -Path $ReporterPath -ChildPath "ReportTemplate.html")
    $ReportHTML = $ReportHTML.Replace("{TITLE}", $Title)
    if ($BaselineName -eq "aad") {
        $ReportHTML = $ReportHTML.Replace("{AADWARNING}", $AADWarning)
    }
    else {
        $ReportHTML = $ReportHTML.Replace("{AADWARNING}", $NoWarning)
    }

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
