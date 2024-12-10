Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "..\Utility")

function New-Report {
     <#
    .Description
    This function creates the individual HTML/json reports using the TestResults.json.
    Output will be stored as HTML/json files in the InvidualReports folder in the OutPath Folder.
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

    $FileName = Join-Path -Path $OutPath -ChildPath "$($OutProviderFileName).json" -Resolve
    $SettingsExport =  Get-Utf8NoBom -FilePath $FileName | ConvertFrom-Json

    $FileName = Join-Path -Path $OutPath -ChildPath "$($OutRegoFileName).json" -Resolve
    $TestResults =  Get-Utf8NoBom -FilePath $FileName | ConvertFrom-Json

    $Fragments = @()

    $MetaData += [pscustomobject]@{
        "Tenant Display Name" = $SettingsExport.tenant_details.DisplayName;
        "Report Date" = $SettingsExport.date;
        "Baseline Version" = $SettingsExport.baseline_version;
        "Module Version" = $SettingsExport.module_version
    }

    # Json version of the product-specific report
    $ReportJson = @{
        "MetaData" = $MetaData
        "Results" = @()
    };

    $MetaDataTable = $MetaData | ConvertTo-HTML -Fragment
    $MetaDataTable = $MetaDataTable -replace '^(.*?)<table>','<table id="tenant-data" style = "text-align:center;">'
    $Fragments += $MetaDataTable
    $ReportSummary = @{
        "Warnings" = 0;
        "Failures" = 0;
        "Passes" = 0;
        "Omits" = 0;
        "Manual" = 0;
        "Errors" = 0;
        "Date" = $SettingsExport.date;
    }

    foreach ($BaselineGroup in $ProductSecureBaseline) {
        $Fragment = @()

        foreach ($Control in $BaselineGroup.Controls){

            $Test = $TestResults | Where-Object -Property PolicyId -eq $Control.Id

            if ($null -ne $Test){
                # Check if the config file indicates the control should be omitted
                $Config = $SettingsExport.scuba_config
                $Omit = Get-OmissionState $Config $Control.Id
                if ($Omit) {
                    $ReportSummary.Omits += 1
                    $OmitRationale = $Config.OmitPolicy.$($Control.Id).Rationale
                    if ([string]::IsNullOrEmpty($OmitRationale)) {
                        Write-Warning "Config file indicates omitting $($Control.Id), but no rationale provided."
                        $OmitRationale = "Rationale not provided."
                    }
                    else {
                        $OmitRationale = "`"$($OmitRationale)`""
                    }
                    $Fragment += [pscustomobject]@{
                        "Control ID"=$Control.Id
                        "Requirement"=$Control.Value
                        "Result"= "Omitted"
                        "Criticality"= $Test.Criticality
                        "Details"= "Test omitted by user. $($OmitRationale)"
                    }
                    continue
                }

                $MissingCommands = $Test.Commandlet | Where-Object {$SettingsExport."$($BaselineName)_successful_commands" -notcontains $_}

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

        # Build the markdown links for each policy table, append as a child inside header tags
        # Example: "AAD-1 Legacy Authentication"
        $Number = $BaselineName.ToUpper() + '-' + $BaselineGroup.GroupNumber
        $Name = $BaselineGroup.GroupName
        $GroupAnchor = New-MarkdownAnchor -GroupNumber $BaselineGroup.GroupNumber -GroupName $BaselineGroup.GroupName
        $GroupReferenceURL = "$($ScubaGitHubUrl)/blob/v$($SettingsExport.module_version)/PowerShell/ScubaGear/baselines/$($BaselineName.ToLower()).md$GroupAnchor"
        $MarkdownLink = "<a class='control_group' href=`"$($GroupReferenceURL)`" target=`"_blank`">$Name</a>"
        $Fragments += $Fragment | ConvertTo-Html -PreContent "<h2>$Number $MarkdownLink</h2>" -Fragment

        # Package Assessment Report into Report JSON by Policy Group
        $ReportJson.Results += [pscustomobject]@{
            GroupName = $BaselineGroup.GroupName;
            GroupNumber = $BaselineGroup.GroupNumber;
            GroupReferenceURL = $GroupReferenceURL;
            Controls = $Fragment;
        }

        # Regex will filter out any <table> tags without an id attribute (replace new fragments only, not <table> tags which have already been modified)
        $Fragments = $Fragments -replace ".*(<table(?![^>]+id)*>)", "<table class='policy-data' id='$Number'>"
    }

    # Craft the json report
    $ReportJson.ReportSummary = $ReportSummary
    $JsonFileName = Join-Path -Path $IndividualReportPath -ChildPath "$($BaselineName)Report.json"
    $ReportJson = ConvertTo-Json @($ReportJson) -Depth 5

    # ConvertTo-Json for some reason converts the <, >, and ' characters into unicode escape sequences.
    # Convert those back to ASCII.
    $ReportJson = $ReportJson.replace("\u003c", "<")
    $ReportJson = $ReportJson.replace("\u003e", ">")
    $ReportJson = $ReportJson.replace("\u0027", "'")
    $ReportJson | Out-File $JsonFileName

    # Finish building the html report
    $Title = "$($FullName) Baseline Report"
    $AADWarning = "Exclusions must only be used if they are approved within an organization's security risk acceptance process.
    Please reference <a href=`"$($ScubaGitHubUrl)/blob/v$($SettingsExport.module_version)/docs/configuration/configuration.md#entra-id-configuration`" target=`"_blank`">this section in the README file</a>
    file for a list of the policies that accept exclusions and the instructions for setting up exclusions in the configuration file.
    <i>Exclusions can introduce grave risks to your system and must be managed carefully.</i>"
    $NoWarning = "<br/>"
    Add-Type -AssemblyName System.Web

    $ReporterPath = $PSScriptRoot
    $ReportHTMLPath = Join-Path -Path $ReporterPath -ChildPath "IndividualReport"
    $ReportHTML = (Get-Content $(Join-Path -Path $ReportHTMLPath -ChildPath "IndividualReport.html")) -Join "`n"
    $ReportHTML = $ReportHTML.Replace("{TITLE}", $Title)
    $BaselineURL = "<a href=`"$($ScubaGitHubUrl)/blob/v$($SettingsExport.module_version)/PowerShell/ScubaGear/baselines/$($BaselineName.ToLower()).md`" target=`"_blank`"><h3 style=`"width: 100px;`">Baseline Documents</h3></a>"
    $ReportHTML = $ReportHTML.Replace("{BASELINE_URL}", $BaselineURL)

    # Handle AAD-specific reporting
    if ($BaselineName -eq "aad") {

        # Load the CSV file
        $csvPath = Join-Path -Path $PSScriptRoot -ChildPath "MicrosoftLicenseToProductNameMappings.csv"
        $csvData = Import-Csv -Path $csvPath

        $LicenseInfoArray = $SettingsExport.license_information | ForEach-Object {

            $SkuID = $_.SkuId
            # Find the corresponding product name
            $matchingRow = $csvData | Where-Object { $_.GUID -eq $SkuID } | Select-Object -First 1
            $productName = "Unknown SKU Name"
            if ($matchingRow) {
                $productName = $matchingRow.'Product_Display_Name'
            }
            # Create a custom object with relevant properties
            [pscustomobject]@{
                "Product Name" = $productName
                "License SKU Identifier" = $_.SkuPartNumber
                "Licenses in Use" = $_.ConsumedUnits
                "Total Licenses" = $_.PrepaidUnits.Enabled
            }
        }
        # Convert the custom objects to an HTML table
        $LicenseTable = $LicenseInfoArray | ConvertTo-Html -As Table -Fragment
        $LicenseTable = $LicenseTable -replace '^(.*?)<table>','<table id="license-info" style = "text-align:center;">'

        # Create a section header for the licensing information
        $LicensingHTML = "<h2>Tenant Licensing Information</h2>" + $LicenseTable

        # Create a section for privileged service principals
        $privilegedServicePrincipalsTable = $SettingsExport.privileged_service_principals.psobject.properties | ForEach-Object {
            $principal = $_.Value
            [pscustomobject]@{
                "Display Name" = $principal.DisplayName
                "Service Principal ID" = $principal.ServicePrincipalId
                "Roles" = ($principal.roles -join ", ")
                "App ID" = $principal.AppId

            }
        } | ConvertTo-Html -Fragment

        $privilegedServicePrincipalsTable = $privilegedServicePrincipalsTable -replace '^(.*?)<table>', '<table id="privileged-service-principals" style="text-align:center;">'

        # Create a section header for the service principal information
        $privilegedServicePrincipalsTableHTML = "<h2>Privileged Service Principal Table</h2>" + $privilegedServicePrincipalsTable


        $ReportHTML = $ReportHTML.Replace("{AADWARNING}", $AADWarning)
        $ReportHTML = $ReportHTML.Replace("{LICENSING_INFO}", $LicensingHTML)
        $ReportHTML = $ReportHTML.Replace("{SERVICE_PRINCIPAL}", $privilegedServicePrincipalsTableHTML)
        $CapJson = ConvertTo-Json $SettingsExport.cap_table_data
    }
    else {
        $ReportHTML = $ReportHTML.Replace("{AADWARNING}", $NoWarning)
        $ReportHTML = $ReportHTML.Replace("{LICENSING_INFO}", "")
        $ReportHTML = $ReportHTML.Replace("{SERVICE_PRINCIPAL}", "")
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

function Get-OmissionState {
    <#
    .Description
    Determine if the supplied control was marked for omission in the config file.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]
        $Config,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ControlId
    )
    $Omit = $false
    if ($Config.psobject.properties.name -Contains "OmitPolicy") {
        if ($Config.OmitPolicy.psobject.properties.name -Contains $ControlId) {
            # The config indicates the control should be omitted
            if ($Config.OmitPolicy.$($ControlId).psobject.properties.name -Contains "Expiration") {
                # An expiration date for the omission expiration was provided. Evaluate the date
                # to see if the control should still be omitted.
                if ($Config.OmitPolicy.$($ControlId).Expiration -eq "") {
                    # If the Expiration date is an empty string, omit the policy
                    $Omit = $true
                }
                else {
                    # An expiration date was provided and it's not an empty string
                    $Now = Get-Date
                    $ExpirationString = $Config.OmitPolicy.$($ControlId).Expiration
                    try {
                        $ExpirationDate = Get-Date -Date $ExpirationString
                        if ($ExpirationDate -lt $Now) {
                            # The expiration date is passed, don't omit the policy
                            $Warning = "Config file indicates omitting $($ControlId), but the provided "
                            $Warning += "expiration date, $ExpirationString, has passed. Control will "
                            $Warning += "not be omitted."
                            Write-Warning $Warning
                        }
                        else {
                            # The expiration date is in the future, omit the policy
                            $Omit = $true
                        }
                    }
                    catch {
                        # Malformed date, don't omit the policy
                        $Warning = "Config file indicates omitting $($ControlId), but the provided "
                        $Warning += "expiration date, $ExpirationString, is malformed. The expected "
                        $Warning += "format is yyyy-mm-dd. Control will not be omitted."
                        Write-Warning $Warning
                    }
                }
            }
            else {
                # The expiration date was not provided, omit the policy
                $Omit = $true
            }
        }
    }
    $Omit
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
        $BaselinePath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\baselines\")
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
                    $IsList = $false

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

                            # Policy description contains a list assuming list is denoted by a colon character.
                            if ($Value[-1] -eq ":") {
                                $isList = $true
                            }

                            if (-not [string]::IsNullOrWhiteSpace([string]$MdLines[$LineNumber+$LineAdvance])) {
                                # List case, use newline character between value text
                                if ($isList) {
                                    $Value += "`n" + ([string]$MdLines[$LineNumber+$LineAdvance]).Trim()
                                }
                                else { # Value ending with newline char, use whitespace character between value text
                                    $Value += " " + ([string]$MdLines[$LineNumber+$LineAdvance]).Trim()
                                }
                            }

                            if ($LineAdvance -gt $MaxLineSearch){
                                Write-Warning "Expected description for $id to end with period and be less than $MaxLineSearch lines"
                                break
                            }
                        }

                        # Description italics substitution
                        $Value = Resolve-HTMLMarkdown -OriginalString $Value -HTMLReplace "italic"

                        # Description bold substitution
                        $Value = Resolve-HTMLMarkdown -OriginalString $Value -HTMLReplace "bold"

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

function Resolve-HTMLMarkdown{
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OriginalString,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $HTMLReplace
    )

    # Replace markdown with italics substitution
    if ($HTMLReplace.ToLower() -match "italic") {
        $ResolvedString = $OriginalString -replace '(_)([^\v][^_]*[^\v])?(_)', '<i>${2}</i>'
        return $ResolvedString
    } elseif($HTMLReplace.ToLower() -match "bold") {
        $ResolvedString = $OriginalString -replace '(\*\*)(.*?)(\*\*)', '<b>${2}</b>'
        return $ResolvedString
    } else {
        $InvalidHTMLReplace = New-Object System.ArgumentException "$HTMLReplace is not valid"
        throw $InvalidHTMLReplace
        return $OriginalString
    }
}

Export-ModuleMember -Function @(
    'New-Report',
    'Import-SecureBaseline'
)
