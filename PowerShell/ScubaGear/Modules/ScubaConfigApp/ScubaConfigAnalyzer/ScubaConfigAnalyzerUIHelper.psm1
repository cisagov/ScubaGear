<#
.SYNOPSIS
    UI wiring + multithreaded orchestration for the ScubaGear Config Analyzer window
    (launched by Start-SCuBAConfigAnalyzer in ScubaConfigApp.psm1).

.DESCRIPTION
    This module is imported INSIDE the analyzer's STA runspace. It:
      - Populates the toolbar controls and wires every UI event.
      - Runs the analysis on a background runspace (never on the UI dispatcher) and
        marshals the result back with a DispatcherTimer, so the window stays
        responsive while a large tenant is analyzed.
      - Runs ScubaGear in a separate, visible process (so interactive Graph auth
        works) and polls for completion, then analyzes the fresh export.
      - Renders per-control findings, best-match policy, remediation steps and the
        editable exclusion lists, and keeps the per-control + aggregate YAML in sync.

    All shared state lives on the synchronized $syncHash so DispatcherTimer ticks and
    event handlers can reach it after the launching function has returned.

.NOTES
    Part of the ScubaGear project - https://github.com/cisagov/ScubaGear
#>

# ------------------------------------------------------------------------------------
# Small helpers
# ------------------------------------------------------------------------------------
function Set-ScubaAnalyzerStatus {
    param([string]$Message)
    try {
        if ($syncHash.Window -and $syncHash.Status_Text) {
            $syncHash.Window.Dispatcher.Invoke([Action] { $syncHash.Status_Text.Text = $Message })
        }
    } catch { Write-Verbose "Set-ScubaAnalyzerStatus failed: $($_.Exception.Message)" }
}

function Write-ScubaAnalyzerLog {
    param([string]$Message)
    try {
        $ts = Get-Date -Format 'HH:mm:ss'
        if ($syncHash.RunOutput_TextBox) {
            $syncHash.Window.Dispatcher.Invoke([Action] {
                $syncHash.RunOutput_TextBox.AppendText("[$ts] $Message`r`n")
                $syncHash.RunOutput_TextBox.ScrollToEnd()
            })
        }
    } catch { Write-Verbose "Write-ScubaAnalyzerLog failed: $($_.Exception.Message)" }
}

function Format-ScubaAnalyzerIssues {
    <#
    .SYNOPSIS
    Turns raw issue strings ("WARNING: ...|DETAILS:...|SUGGESTION:...") into readable
    bullet text for the policy cards.
    #>
    param([array]$Issues = @())

    $lines = @()
    foreach ($issue in @($Issues)) {
        if ([string]::IsNullOrWhiteSpace($issue)) { continue }
        $parts   = $issue -split '\|'
        $main    = $parts[0] -replace '^(WARNING|ERROR):\s*', ''
        $detail  = @($parts | Where-Object { $_ -like 'DETAILS:*' }) -replace '^DETAILS:', ''
        $line    = "- $main"
        if ($detail) { $line += "  ($(($detail -join ' ').Trim()))" }
        $lines += $line
    }
    return ($lines -join "`n")
}

# ------------------------------------------------------------------------------------
# YAML helpers (per-control + aggregate), driven by the detected exclusions
# ------------------------------------------------------------------------------------
function New-ScubaAnalyzerControlYamlText {
    param(
        [Parameter(Mandatory)]$Finding,
        [array]$Users = @(),
        [array]$Groups = @(),
        [array]$Applications = @(),
        [array]$GuestUserTypes = @(),
        [hashtable]$DisplayNameLookup = @{}
    )

    if ($Finding.ExclusionField -eq 'none') {
        return "# $($Finding.ControlId) does not support exclusions.`n# Remediate by creating or fixing the policy (see remediation steps)."
    }

    # The Conditional Access policy the exclusions are based on (in use / best match).
    $selId  = [string]$Finding.SelectedPolicyId
    $selPol = @($Finding.AllPolicies | Where-Object { [string]$_.Id -eq $selId }) | Select-Object -First 1
    $caName = if ($selPol) { $selPol.DisplayName } elseif ($Finding.BestMatch) { $Finding.BestMatch.DisplayName } else { $null }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("$($Finding.ProductConfigKey):")
    [void]$sb.AppendLine("  # $($Finding.Requirement)")
    if ($caName) { [void]$sb.AppendLine("  # CA policy: $caName") }
    [void]$sb.AppendLine("  $($Finding.ControlId):")
    [void]$sb.AppendLine("    $($Finding.ExclusionField):")
    if (@($Users).Count -gt 0) {
        [void]$sb.AppendLine("      Users:")
        foreach ($id in $Users) { $c = if ($DisplayNameLookup.ContainsKey($id)) { " # $($DisplayNameLookup[$id])" } else { "" }; [void]$sb.AppendLine("        - $id$c") }
    }
    if (@($Groups).Count -gt 0) {
        [void]$sb.AppendLine("      Groups:")
        foreach ($id in $Groups) { $c = if ($DisplayNameLookup.ContainsKey($id)) { " # $($DisplayNameLookup[$id])" } else { "" }; [void]$sb.AppendLine("        - $id$c") }
    }
    if (@($Applications).Count -gt 0) {
        [void]$sb.AppendLine("      Applications:")
        foreach ($app in $Applications) { $c = if ($DisplayNameLookup.ContainsKey($app)) { " # $($DisplayNameLookup[$app])" } else { "" }; [void]$sb.AppendLine("        - $app$c") }
    }
    if (@($GuestUserTypes).Count -gt 0) {
        [void]$sb.AppendLine("      GuestUserTypes:")
        foreach ($gt in $GuestUserTypes) { [void]$sb.AppendLine("        - $gt") }
    }
    if (@($Users).Count -eq 0 -and @($Groups).Count -eq 0 -and @($Applications).Count -eq 0 -and @($GuestUserTypes).Count -eq 0) {
        [void]$sb.AppendLine("      # No exclusions. Add Users/Groups/Applications/GuestUserTypes only if justified (e.g. break-glass).")
    }
    return $sb.ToString()
}

function Update-ScubaAnalyzerControlYaml {
    param([Parameter(Mandatory)]$Finding)
    try {
        $users  = @($Finding.DetectedExclusions.Users)
        $groups = @($Finding.DetectedExclusions.Groups)
        $apps   = @($Finding.DetectedExclusions.Applications)
        $guests = @($Finding.DetectedExclusions.GuestUserTypes)
        $lookup = if ($syncHash.Analysis -and $syncHash.Analysis.DisplayNameLookup) { $syncHash.Analysis.DisplayNameLookup } else { @{} }
        $syncHash.Detail_Yaml.Text = New-ScubaAnalyzerControlYamlText -Finding $Finding -Users $users -Groups $groups -Applications $apps -GuestUserTypes $guests -DisplayNameLookup $lookup
    } catch { Write-Verbose "Update-ScubaAnalyzerControlYaml failed: $($_.Exception.Message)" }
}

function Update-ScubaAnalyzerFullYaml {
    try {
        if (-not $syncHash.Analysis) { return }
        $env = if ($syncHash.Environment_ComboBox.SelectedItem) { [string]$syncHash.Environment_ComboBox.SelectedItem } else { 'commercial' }
        $lookup = if ($syncHash.Analysis.DisplayNameLookup) { $syncHash.Analysis.DisplayNameLookup } else { @{} }
        $syncHash.FullYaml_TextBox.Text = Get-ScubaAnalyzerConfigYaml -Analysis $syncHash.Analysis -M365Environment $env -DisplayNameLookup $lookup -AppId $syncHash.AppId -CertificateThumbprint $syncHash.CertificateThumbprint -Organization $syncHash.Organization
    } catch {
        Write-ScubaAnalyzerLog "Failed to build configuration YAML: $($_.Exception.Message)"
    }
}

# ------------------------------------------------------------------------------------
# Findings list + detail rendering
# ------------------------------------------------------------------------------------
function Update-ScubaAnalyzerFindings {
    <#
    .SYNOPSIS
    Applies the Issues-only + search filters and (re)builds the findings list + header.
    #>
    if (-not $syncHash.Analysis) { return }
    $a = $syncHash.Analysis

    # Header + summary
    $syncHash.TenantText.Text = "Tenant: $($a.MetaData.DisplayName)"
    $syncHash.ScanDateText.Text = if ($a.MetaData.ScanDate) { "Scan: $($a.MetaData.ScanDate)" } else { "" }
    $s = $a.Summary
    $needAttention = @($a.Findings | Where-Object { $_.Result -ne 'Pass' }).Count
    $syncHash.SummaryText.Text = "$($s.Total) controls, $needAttention need attention"
    $syncHash.ComplianceText.Text = "Pass $($s.Passes) | Fail $($s.Failures) | Warn $($s.Warnings) | Error $($s.Errors) | Manual $($s.Manual) | $($s.ComplianceRate)% compliant"

    # Filter
    $issuesOnly = [bool]$syncHash.IssuesOnly_CheckBox.IsChecked
    $configurableOnly = if ($syncHash.ContainsKey('ConfigurableOnly_CheckBox') -and $syncHash.ConfigurableOnly_CheckBox) { [bool]$syncHash.ConfigurableOnly_CheckBox.IsChecked } else { $false }
    $search = if ($syncHash.Search_TextBox.Text) { $syncHash.Search_TextBox.Text.Trim() } else { "" }

    $filtered = @($a.Findings | Where-Object {
        (-not $issuesOnly -or $_.Result -ne 'Pass') -and
        (-not $configurableOnly -or $_.Configurable) -and
        ([string]::IsNullOrWhiteSpace($search) -or
         $_.ControlId -like "*$search*" -or
         $_.Requirement -like "*$search*")
    })

    $syncHash.Findings_List.ItemsSource = $filtered
    if (@($filtered).Count -eq 0) {
        $syncHash.DetailContent.Visibility = 'Collapsed'
        $syncHash.EmptyDetailText.Visibility = 'Visible'
        $syncHash.EmptyDetailText.Text = "No findings match the current filter."
    }
}

function Use-ScubaAnalyzerPolicy {
    <#
    .SYNOPSIS
    Switches the "in use" candidate policy for the selected finding. The chosen policy's
    detected exclusions become the finding's exclusions so both the per-control and the
    full configuration YAML follow the user's choice.
    #>
    param([Parameter(Mandatory)][string]$PolicyId)
    try {
        $finding = $syncHash.Findings_List.SelectedItem
        if (-not $finding) { return }
        $chosen = @($finding.AllPolicies | Where-Object { [string]$_.Id -eq $PolicyId }) | Select-Object -First 1
        if (-not $chosen) { return }
        $finding.SelectedPolicyId = $PolicyId
        $ex = if ($chosen.DetectedExclusions) { $chosen.DetectedExclusions } else { @{ Users = @(); Groups = @(); Applications = @(); GuestUserTypes = @() } }
        $finding.DetectedExclusions = @{ Users = @($ex.Users); Groups = @($ex.Groups); Applications = @($ex.Applications); GuestUserTypes = @($ex.GuestUserTypes) }
        Show-ScubaAnalyzerDetail
        Update-ScubaAnalyzerFullYaml
        Set-ScubaAnalyzerStatus "Using policy '$($chosen.DisplayName)' for $($finding.ControlId)."
    } catch {
        Write-ScubaAnalyzerLog "Use policy failed: $($_.Exception.Message)"
    }
}

function Show-ScubaAnalyzerDetail {
    <#
    .SYNOPSIS
    Populates the details pane for the selected finding.
    #>
    try {
        $finding = $syncHash.Findings_List.SelectedItem
        if (-not $finding) {
            $syncHash.DetailContent.Visibility = 'Collapsed'
            $syncHash.EmptyDetailText.Visibility = 'Visible'
            return
        }
        $syncHash.EmptyDetailText.Visibility = 'Collapsed'
        $syncHash.DetailContent.Visibility = 'Visible'

        $syncHash.Detail_ControlId.Text = $finding.ControlId
        $syncHash.Detail_ResultText.Text = $finding.Result
        $syncHash.Detail_ResultBadge.DataContext = $finding      # drives badge colour via DataTrigger
        $syncHash.Detail_Requirement.Text = $finding.Requirement
        $groupLabel = @("$($finding.GroupNumber) $($finding.GroupName)".Trim(), "Criticality: $($finding.Criticality)") -join '   -   '
        $syncHash.Detail_GroupText.Text = $groupLabel
        $syncHash.Detail_RootCause.Text = $finding.RootCause
        $syncHash.Detail_Details.Text = "ScubaGear details: $($finding.Details)"
        $syncHash.Detail_Criticality.Text = "Action: $($finding.RequiresAction)"

        # Recommendations
        $recs = @($finding.Recommendations)
        if (@($recs).Count -gt 0) {
            $syncHash.RecommendationsHeader.Visibility = 'Visible'
            $syncHash.Detail_Recommendations.Visibility = 'Visible'
            $syncHash.Detail_Recommendations.ItemsSource = $recs
        } else {
            $syncHash.RecommendationsHeader.Visibility = 'Collapsed'
            $syncHash.Detail_Recommendations.Visibility = 'Collapsed'
            $syncHash.Detail_Recommendations.ItemsSource = $null
        }

        # Matching policies. The user can pick which candidate to base the config on
        # ("Use this policy"); the selected one is expanded and drives the YAML.
        $policyItems = @()
        $best = $finding.BestMatch
        $selectedId = if ($finding.SelectedPolicyId) { [string]$finding.SelectedPolicyId } elseif ($best) { [string]$best.Id } else { $null }
        $multiple = (@($finding.AllPolicies).Count -gt 1)
        foreach ($p in @($finding.AllPolicies)) {
            $isBest     = ($best -and $p.Id -eq $best.Id)
            $isSelected = ($selectedId -and [string]$p.Id -eq $selectedId)
            $issuesText = Format-ScubaAnalyzerIssues -Issues @($p.Issues)
            if (-not $issuesText) { $issuesText = "This policy meets the baseline requirement - no changes needed." }
            # Offer 'Use this policy' on the other candidates only when there's a real choice.
            $showUse = ($multiple -and -not $isSelected)
            $policyItems += [pscustomobject]@{
                PolicyId            = [string]$p.Id
                DisplayName         = $p.DisplayName
                StateText           = "State: $($p.State)   -   Issues: $($p.IssueCount)"
                IssuesText          = $issuesText
                BestMatchVisibility = if ($isBest) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
                InUseVisibility     = if ($isSelected -and $multiple) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
                UseButtonVisibility = if ($showUse) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
                IssuesVisibility    = [System.Windows.Visibility]::Visible
                IsExpanded          = [bool]$isSelected
            }
        }
        if (@($policyItems).Count -gt 0) {
            $syncHash.PoliciesHeader.Visibility = 'Visible'
            $syncHash.Detail_Policies.Visibility = 'Visible'
            $syncHash.Detail_Policies.ItemsSource = $policyItems
        } else {
            $syncHash.PoliciesHeader.Visibility = 'Collapsed'
            $syncHash.Detail_Policies.Visibility = 'Collapsed'
            $syncHash.Detail_Policies.ItemsSource = $null
        }

        # Remediation steps
        $steps = @($finding.RemediationSteps)
        if (@($steps).Count -gt 0) {
            $syncHash.RemediationHeader.Visibility = 'Visible'
            $syncHash.Detail_Remediation.Visibility = 'Visible'
            $syncHash.Detail_Remediation.ItemsSource = $steps
        } else {
            $syncHash.RemediationHeader.Visibility = 'Collapsed'
            $syncHash.Detail_Remediation.Visibility = 'Collapsed'
            $syncHash.Detail_Remediation.ItemsSource = $null
        }

        Update-ScubaAnalyzerControlYaml -Finding $finding
    } catch {
        Write-ScubaAnalyzerLog "Failed to render finding: $($_.Exception.Message)"
    }
}

# ------------------------------------------------------------------------------------
# Analysis (background runspace, polled by a DispatcherTimer)
# ------------------------------------------------------------------------------------
function Start-ScubaAnalyzerAnalysis {
    <#
    .SYNOPSIS
    Runs Invoke-ScubaConfigAnalysis on a background runspace so the UI never blocks.
    #>
    param([Parameter(Mandatory)][string]$ResultsPath)

    if (-not (Test-Path $ResultsPath)) {
        Set-ScubaAnalyzerStatus "Results file not found: $ResultsPath"
        return
    }

    $products = @($syncHash.Product_ListBox.SelectedItems | ForEach-Object { [string]$_.Key })
    if (@($products).Count -eq 0) { $products = @('aad') }

    $syncHash.Run_Progress.IsIndeterminate = $true
    $syncHash.Run_Progress.Visibility = 'Visible'
    # Loading a results file is not a live tenant connection.
    $syncHash.ConnectedTenant = $false
    Set-ScubaAnalyzerStatus "Analyzing $(Split-Path $ResultsPath -Leaf) ..."
    Write-ScubaAnalyzerLog "Analyzing results: $ResultsPath (products: $($products -join ', '))"

    $analysisSync = [hashtable]::Synchronized(@{ IsComplete = $false; Result = $null; Error = $null })
    $syncHash.AnalysisSync = $analysisSync

    $bgRunspace = [runspacefactory]::CreateRunspace()
    $bgRunspace.ApartmentState = "MTA"
    $bgRunspace.ThreadOptions = "ReuseThread"
    $bgRunspace.Open()
    $bgRunspace.SessionStateProxy.SetVariable("analysisSync", $analysisSync)
    $bgRunspace.SessionStateProxy.SetVariable("enginePath", $syncHash.AnalyzerEnginePath)
    $bgRunspace.SessionStateProxy.SetVariable("resultsPath", $ResultsPath)
    $bgRunspace.SessionStateProxy.SetVariable("product", $products)
    $bgRunspace.SessionStateProxy.SetVariable("baselineSchemaPath", $syncHash.BaselineSchemaPath)
    $bgRunspace.SessionStateProxy.SetVariable("analyzerSchemaPath", $syncHash.AnalyzerSchemaPath)
    $bgRunspace.SessionStateProxy.SetVariable("configSchemaPath", $syncHash.ConfigSchemaPath)

    $bgPS = [powershell]::Create()
    $bgPS.Runspace = $bgRunspace
    [void]$bgPS.AddScript({
        try {
            Import-Module $enginePath -Force -ErrorAction Stop
            $analysisSync.Result = Invoke-ScubaConfigAnalysis -ResultsPath $resultsPath -Product $product `
                -BaselineSchemaPath $baselineSchemaPath -AnalyzerSchemaPath $analyzerSchemaPath -ConfigSchemaPath $configSchemaPath -IncludePassing
        } catch {
            $analysisSync.Error = $_.Exception.Message
        } finally {
            $analysisSync.IsComplete = $true
        }
    })
    $syncHash.AnalysisBgPS = $bgPS
    $syncHash.AnalysisBgHandle = $bgPS.BeginInvoke()
    $syncHash.AnalysisBgRunspace = $bgRunspace

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(200)
    $timer.Add_Tick({
        if (-not $syncHash.AnalysisSync.IsComplete) { return }
        $syncHash.AnalysisTimer.Stop()
        try { [void]$syncHash.AnalysisBgPS.EndInvoke($syncHash.AnalysisBgHandle) } catch { Write-Verbose "Analysis EndInvoke cleanup: $($_.Exception.Message)" }
        try { $syncHash.AnalysisBgPS.Dispose() } catch { Write-Verbose "Analysis PS dispose cleanup: $($_.Exception.Message)" }
        try { $syncHash.AnalysisBgRunspace.Close(); $syncHash.AnalysisBgRunspace.Dispose() } catch { Write-Verbose "Analysis runspace dispose cleanup: $($_.Exception.Message)" }

        $syncHash.Run_Progress.Visibility = 'Collapsed'
        $syncHash.Run_Progress.IsIndeterminate = $false

        if ($syncHash.AnalysisSync.Error) {
            Set-ScubaAnalyzerStatus "Analysis failed: $($syncHash.AnalysisSync.Error)"
            Write-ScubaAnalyzerLog "Analysis failed: $($syncHash.AnalysisSync.Error)"
            return
        }

        $syncHash.Analysis = $syncHash.AnalysisSync.Result
        Update-ScubaAnalyzerFindings
        Update-ScubaAnalyzerFullYaml
        $count = @($syncHash.Analysis.Findings | Where-Object { $_.Result -ne 'Pass' }).Count
        Set-ScubaAnalyzerStatus "Analysis complete - $count control(s) need attention."
        Write-ScubaAnalyzerLog "Analysis complete."
    })
    $syncHash.AnalysisTimer = $timer
    $timer.Start()
}

# ------------------------------------------------------------------------------------
# ScubaGear run (separate visible process, polled by a DispatcherTimer)
# ------------------------------------------------------------------------------------
function Start-ScubaAnalyzerTenantScan {
    <#
    .SYNOPSIS
    Connects to Microsoft Graph (on the UI thread) then scans the live tenant on a
    background runspace, marshaling the findings back via a DispatcherTimer so the UI
    stays responsive. No ScubaGear run - the schema drives what to query.
    #>
    try {
        $products = @($syncHash.Product_ListBox.SelectedItems | ForEach-Object { [string]$_.Key })
        if (@($products).Count -eq 0) { $products = @('aad') }
        $env     = if ($syncHash.Environment_ComboBox.SelectedItem) { [string]$syncHash.Environment_ComboBox.SelectedItem } else { 'commercial' }

        $syncHash.Run_Button.IsEnabled = $false
        $syncHash.Run_Progress.IsIndeterminate = $true
        $syncHash.Run_Progress.Visibility = 'Visible'
        $syncHash.MainTabs.SelectedIndex = 2   # Run Output tab (shows sign-in progress)
        $appOnly = [bool]($syncHash.AppId -and $syncHash.CertificateThumbprint)
        $connectStatus = if ($appOnly) { "Connecting to Microsoft Graph (app-only certificate)..." } else { "Connecting to Microsoft Graph - complete sign-in in the browser..." }
        Set-ScubaAnalyzerStatus $connectStatus
        Write-ScubaAnalyzerLog "Connecting to Microsoft Graph ($env) for products '$($products -join ', ')'$(if ($appOnly) { " - app-only cert (app $($syncHash.AppId))" })..."
        # Force the UI to paint the status before the (blocking) sign-in / connect.
        $syncHash.Window.Dispatcher.Invoke([action] {}, [System.Windows.Threading.DispatcherPriority]::Render)

        # Connect on the UI thread. App-only cert auth is non-interactive; otherwise use
        # interactive auth with the delegated scopes resolved from the API catalog.
        try {
            $baseline = Get-Content $syncHash.BaselineSchemaPath -Raw | ConvertFrom-Json
            if ($appOnly) {
                $ctx = Connect-ScubaAnalyzerGraph -M365Environment $env -AppId $syncHash.AppId -CertificateThumbprint $syncHash.CertificateThumbprint -Organization $syncHash.Organization
            } else {
                $scopes = @()
                foreach ($p in $products) { $scopes += Get-ScubaAnalyzerScopes -Product $p -BaselineSchema $baseline -ApiCatalogPath $syncHash.ApiCatalogPath -AnalyzerSchemaPath $syncHash.AnalyzerSchemaPath }
                $scopes = @($scopes | Select-Object -Unique)
                Write-ScubaAnalyzerLog "Requesting Graph scopes: $($scopes -join ', ')"
                $ctx = Connect-ScubaAnalyzerGraph -Scopes $scopes -M365Environment $env
            }
        } catch {
            $syncHash.Run_Button.IsEnabled = $true
            $syncHash.Run_Progress.Visibility = 'Collapsed'; $syncHash.Run_Progress.IsIndeterminate = $false
            Set-ScubaAnalyzerStatus "Graph sign-in failed: $($_.Exception.Message)"
            Write-ScubaAnalyzerLog "Graph sign-in failed: $($_.Exception.Message)"
            return
        }
        Write-ScubaAnalyzerLog "Connected as $($ctx.Account) (tenant $($ctx.TenantId))."
        $syncHash.ConnectedTenant = $true
        $syncHash.ConnectedEnvironment = $env
        Set-ScubaAnalyzerStatus "Connected. Retrieving tenant configuration from Microsoft Graph..."
        # Paint the status before the (blocking) Graph read.
        $syncHash.Window.Dispatcher.Invoke([action] {}, [System.Windows.Threading.DispatcherPriority]::Render)

        # Read tenant data on THIS (sign-in) thread, where the Graph session is valid,
        # using only Microsoft Graph auth + raw Graph API calls. Then validate on a
        # background runspace so the UI stays responsive.
        try {
            $tenantData = @{ conditional_access_policies = @(); OrgDisplayName = $null; Organization = $null; TenantId = $null; DisplayNameLookup = @{} }
            foreach ($p in $products) {
                $d = Get-ScubaTenantGraphData -Product $p -BaselineSchema $baseline -ApiCatalogPath $syncHash.ApiCatalogPath -AnalyzerSchemaPath $syncHash.AnalyzerSchemaPath
                if (@($d.conditional_access_policies).Count -gt 0) { $tenantData.conditional_access_policies = $d.conditional_access_policies }
                if ($d.OrgDisplayName) { $tenantData.OrgDisplayName = $d.OrgDisplayName }
                if ($d.Organization)  { $tenantData.Organization  = $d.Organization }
                if ($d.TenantId)      { $tenantData.TenantId      = $d.TenantId }
                if ($d.DisplayNameLookup) { foreach ($k in @($d.DisplayNameLookup.Keys)) { $tenantData.DisplayNameLookup[$k] = $d.DisplayNameLookup[$k] } }
            }
            Write-ScubaAnalyzerLog "Retrieved $(@($tenantData.conditional_access_policies).Count) Conditional Access policy/policies."
        } catch {
            $syncHash.Run_Button.IsEnabled = $true
            $syncHash.Run_Progress.Visibility = 'Collapsed'; $syncHash.Run_Progress.IsIndeterminate = $false
            Set-ScubaAnalyzerStatus "Failed to read tenant configuration: $($_.Exception.Message)"
            Write-ScubaAnalyzerLog "Graph read failed: $($_.Exception.Message)"
            return
        }
        Set-ScubaAnalyzerStatus "Analyzing $(@($tenantData.conditional_access_policies).Count) policies against the baselines..."

        # Background validation keeps the UI responsive (no Graph calls here).
        $scanSync = [hashtable]::Synchronized(@{ IsComplete = $false; Result = $null; Error = $null })
        $syncHash.ScanSync = $scanSync
        $bg = [runspacefactory]::CreateRunspace(); $bg.ApartmentState = 'MTA'; $bg.ThreadOptions = 'ReuseThread'; $bg.Open()
        $bg.SessionStateProxy.SetVariable('scanSync', $scanSync)
        $bg.SessionStateProxy.SetVariable('enginePath', $syncHash.AnalyzerEnginePath)
        $bg.SessionStateProxy.SetVariable('product', $products)
        $bg.SessionStateProxy.SetVariable('env', $env)
        $bg.SessionStateProxy.SetVariable('tenantData', $tenantData)
        $bg.SessionStateProxy.SetVariable('baselineSchemaPath', $syncHash.BaselineSchemaPath)
        $bg.SessionStateProxy.SetVariable('analyzerSchemaPath', $syncHash.AnalyzerSchemaPath)
        $bg.SessionStateProxy.SetVariable('configSchemaPath', $syncHash.ConfigSchemaPath)
        $bgPS = [powershell]::Create(); $bgPS.Runspace = $bg
        [void]$bgPS.AddScript({
            try {
                Import-Module $enginePath -Force -ErrorAction Stop
                $scanSync.Result = Invoke-ScubaTenantScan -Product $product -M365Environment $env -TenantData $tenantData -BaselineSchemaPath $baselineSchemaPath -AnalyzerSchemaPath $analyzerSchemaPath -ConfigSchemaPath $configSchemaPath
            } catch { $scanSync.Error = $_.Exception.Message } finally { $scanSync.IsComplete = $true }
        })
        $syncHash.ScanBgPS = $bgPS
        $syncHash.ScanBgHandle = $bgPS.BeginInvoke()
        $syncHash.ScanBgRunspace = $bg

        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(250)
        $timer.Add_Tick({
            if (-not $syncHash.ScanSync.IsComplete) { return }
            $syncHash.ScanTimer.Stop()
            try { [void]$syncHash.ScanBgPS.EndInvoke($syncHash.ScanBgHandle) } catch { Write-Verbose "Scan EndInvoke cleanup: $($_.Exception.Message)" }
            try { $syncHash.ScanBgPS.Dispose() } catch { Write-Verbose "Scan PS dispose cleanup: $($_.Exception.Message)" }
            try { $syncHash.ScanBgRunspace.Close(); $syncHash.ScanBgRunspace.Dispose() } catch { Write-Verbose "Scan runspace dispose cleanup: $($_.Exception.Message)" }

            $syncHash.Run_Progress.Visibility = 'Collapsed'; $syncHash.Run_Progress.IsIndeterminate = $false
            $syncHash.Run_Button.IsEnabled = $true

            if ($syncHash.ScanSync.Error) {
                Set-ScubaAnalyzerStatus "Scan failed: $($syncHash.ScanSync.Error)"
                Write-ScubaAnalyzerLog "Scan failed: $($syncHash.ScanSync.Error)"
                return
            }
            $syncHash.Analysis = $syncHash.ScanSync.Result
            Update-ScubaAnalyzerFindings
            Update-ScubaAnalyzerFullYaml
            $syncHash.MainTabs.SelectedIndex = 0
            $count = @($syncHash.Analysis.Findings | Where-Object { $_.Result -ne 'Pass' }).Count
            Set-ScubaAnalyzerStatus "Scan complete - $count baseline(s) need action to pass ScubaGear."
            Write-ScubaAnalyzerLog "Scan complete."
        })
        $syncHash.ScanTimer = $timer
        $timer.Start()
    } catch {
        $syncHash.Run_Button.IsEnabled = $true
        $syncHash.Run_Progress.Visibility = 'Collapsed'; $syncHash.Run_Progress.IsIndeterminate = $false
        Set-ScubaAnalyzerStatus "Scan error: $($_.Exception.Message)"
        Write-ScubaAnalyzerLog "Scan error: $($_.Exception.Message)"
    }
}

# ------------------------------------------------------------------------------------
# Open the ScubaConfig app in-process (no new console / window-process)
# ------------------------------------------------------------------------------------
function Start-ScubaAnalyzerConfigApp {
    <#
    .SYNOPSIS
    Opens Start-SCuBAConfigApp inside this process (its own runspace, no extra console
    window) and, when a configuration YAML has been generated, pre-loads it so the
    detected exclusions are already populated.
    #>
    try {
        if (-not $syncHash.ScubaConfigAppModulePath -or -not (Test-Path $syncHash.ScubaConfigAppModulePath)) {
            Set-ScubaAnalyzerStatus "ScubaConfig app module not found."
            return
        }

        # Pre-load the generated config so the exclusions carry over into the app.
        $configFile = $null
        if ($syncHash.FullYaml_TextBox -and -not [string]::IsNullOrWhiteSpace($syncHash.FullYaml_TextBox.Text)) {
            $tmpDir = Join-Path $env:TEMP 'ScubaConfigAnalyzer'
            if (-not (Test-Path $tmpDir)) { New-Item -Path $tmpDir -ItemType Directory -Force | Out-Null }
            $configFile = Join-Path $tmpDir "AnalyzerConfig_$(Get-Date -Format 'yyyyMMdd_HHmmss').yaml"
            [System.IO.File]::WriteAllText($configFile, $syncHash.FullYaml_TextBox.Text, [System.Text.Encoding]::UTF8)
        }

        # If the analyzer is connected to a live tenant, open the config app Online against
        # the same environment so it targets the correct tenant type.
        $online = [bool]$syncHash.ConnectedTenant
        $envName = if ($syncHash.ConnectedEnvironment) { [string]$syncHash.ConnectedEnvironment }
                   elseif ($syncHash.Environment_ComboBox.SelectedItem) { [string]$syncHash.Environment_ComboBox.SelectedItem }
                   else { 'commercial' }

        $rs = [runspacefactory]::CreateRunspace()
        $rs.ApartmentState = 'STA'; $rs.ThreadOptions = 'ReuseThread'; $rs.Open()
        $rs.SessionStateProxy.SetVariable('modulePath', $syncHash.ScubaConfigAppModulePath)
        $rs.SessionStateProxy.SetVariable('configFile', $configFile)
        $rs.SessionStateProxy.SetVariable('online', $online)
        $rs.SessionStateProxy.SetVariable('envName', $envName)
        $ps = [powershell]::Create(); $ps.Runspace = $rs
        [void]$ps.AddScript({
            Import-Module $modulePath -Force
            $p = @{}
            if ($configFile -and (Test-Path $configFile)) { $p.ConfigFilePath = $configFile }
            if ($online) { $p.Online = $true; $p.M365Environment = $envName }
            Start-SCuBAConfigApp @p
        })
        [void]$ps.BeginInvoke()

        # Keep references so the runspace isn't collected while the config app is open.
        if (-not $syncHash.ConfigAppInstances) { $syncHash.ConfigAppInstances = [System.Collections.ArrayList]::new() }
        [void]$syncHash.ConfigAppInstances.Add(@{ Runspace = $rs; PowerShell = $ps })

        $mode = if ($online) { " (Online: $envName)" } else { "" }
        if ($configFile) { Set-ScubaAnalyzerStatus "ScubaConfig app opened with the configuration pre-loaded$mode." }
        else { Set-ScubaAnalyzerStatus "ScubaConfig app opened$mode." }
    } catch {
        Set-ScubaAnalyzerStatus "Could not open ScubaConfig app: $($_.Exception.Message)"
        Write-ScubaAnalyzerLog "Open ScubaConfig app failed: $($_.Exception.Message)"
    }
}

# ------------------------------------------------------------------------------------
# Export
# ------------------------------------------------------------------------------------
function Export-ScubaAnalyzerYaml {
    try {
        if ([string]::IsNullOrWhiteSpace($syncHash.FullYaml_TextBox.Text)) {
            Set-ScubaAnalyzerStatus "Nothing to export yet - run or load results first."
            return
        }
        $dlg = New-Object Microsoft.Win32.SaveFileDialog
        $dlg.Filter = "YAML files (*.yaml)|*.yaml|All files (*.*)|*.*"
        $dlg.FileName = "ScubaGearConfig.yaml"
        $dlg.Title = "Export ScubaGear configuration"
        if ($dlg.ShowDialog() -eq $true) {
            [System.IO.File]::WriteAllText($dlg.FileName, $syncHash.FullYaml_TextBox.Text, [System.Text.Encoding]::UTF8)
            Set-ScubaAnalyzerStatus "Configuration exported to $($dlg.FileName)"
            Write-ScubaAnalyzerLog "Configuration exported to $($dlg.FileName)"
        }
    } catch {
        Set-ScubaAnalyzerStatus "Export failed: $($_.Exception.Message)"
    }
}

# ------------------------------------------------------------------------------------
# Initialization + event wiring
# ------------------------------------------------------------------------------------
function Initialize-ScubaConfigAnalyzerUI {
    <#
    .SYNOPSIS
    Populates the toolbar and wires all UI events. Called once from the runspace after
    the XAML has loaded.
    #>

    # Logo + version
    try { if ($syncHash.ImgPath -and (Test-Path $syncHash.ImgPath)) { $syncHash.LogoImage.Source = $syncHash.ImgPath } } catch { Write-Verbose "Logo load failed: $($_.Exception.Message)" }
    if ($syncHash.AnalyzerVersion) { $syncHash.VersionText.Text = "v$($syncHash.AnalyzerVersion)" }

    # Environment combo
    foreach ($e in @('commercial', 'gcc', 'gcchigh', 'dod')) { [void]$syncHash.Environment_ComboBox.Items.Add($e) }
    $syncHash.Environment_ComboBox.SelectedIndex = 0

    # Products list: only configurable products (supportsExclusions=true in
    # ScubaConfigSchema.json), intersected with products that have baseline validations.
    # Items carry the product key + a friendly displayName (from the analyzer schema
    # productMap). Multi-select; nothing hardcoded.
    $configurable = @()
    try {
        $cs = Get-Content $syncHash.ConfigSchemaPath -Raw | ConvertFrom-Json
        foreach ($p in $cs.schemaMetadata.productCapabilities.PSObject.Properties) {
            if ($p.Value.supportsExclusions -eq $true) { $configurable += ([string]$p.Name).ToLower() }
        }
    } catch { Write-Verbose "Configurable products load failed: $($_.Exception.Message)" }
    $displayMap = @{}
    try {
        $as = Get-Content $syncHash.AnalyzerSchemaPath -Raw | ConvertFrom-Json
        foreach ($p in $as.productMap.PSObject.Properties) {
            if ($p.Name -match '^_') { continue }
            $displayMap[([string]$p.Name).ToLower()] = if ($p.Value.displayName) { [string]$p.Value.displayName } else { [string]$p.Name }
        }
    } catch { Write-Verbose "Product display-name load failed: $($_.Exception.Message)" }
    $products = @()
    try {
        $bs = Get-Content $syncHash.BaselineSchemaPath -Raw | ConvertFrom-Json
        $baselineProducts = @($bs.baselineValidations.PSObject.Properties.Name)
        $products = @($baselineProducts | Where-Object { $configurable -contains ([string]$_).ToLower() })
    } catch { Write-Verbose "Baseline products load failed: $($_.Exception.Message)" }
    if (@($products).Count -eq 0) { $products = @($configurable) }
    if (@($products).Count -eq 0) { $products = @('aad') }
    foreach ($p in $products) {
        $key  = ([string]$p).ToLower()
        $disp = if ($displayMap.ContainsKey($key)) { $displayMap[$key] } else { [string]$p }
        [void]$syncHash.Product_ListBox.Items.Add([pscustomobject]@{ Key = [string]$p; Display = $disp })
    }
    $syncHash.Product_ListBox.SelectAll()

    # Toolbar
    $syncHash.Run_Button.Add_Click({ Start-ScubaAnalyzerTenantScan })
    $syncHash.Load_Button.Add_Click({
        try {
            $dlg = New-Object Microsoft.Win32.OpenFileDialog
            $dlg.Filter = "ScubaGear results (*.json)|*.json|All files (*.*)|*.*"
            $dlg.Title = "Select a ScubaResults JSON"
            if ($dlg.ShowDialog() -eq $true) { Start-ScubaAnalyzerAnalysis -ResultsPath $dlg.FileName }
        } catch { Set-ScubaAnalyzerStatus "Could not open file: $($_.Exception.Message)" }
    })

    # Filters
    $syncHash.IssuesOnly_CheckBox.Add_Checked({ if ($syncHash.Analysis) { Update-ScubaAnalyzerFindings } })
    $syncHash.IssuesOnly_CheckBox.Add_Unchecked({ if ($syncHash.Analysis) { Update-ScubaAnalyzerFindings } })
    if ($syncHash.ConfigurableOnly_CheckBox) {
        $syncHash.ConfigurableOnly_CheckBox.Add_Checked({ if ($syncHash.Analysis) { Update-ScubaAnalyzerFindings } })
        $syncHash.ConfigurableOnly_CheckBox.Add_Unchecked({ if ($syncHash.Analysis) { Update-ScubaAnalyzerFindings } })
    }
    $syncHash.Search_TextBox.Add_TextChanged({ if ($syncHash.Analysis) { Update-ScubaAnalyzerFindings } })
    $syncHash.Findings_List.Add_SelectionChanged({ Show-ScubaAnalyzerDetail })
    $syncHash.Environment_ComboBox.Add_SelectionChanged({ if ($syncHash.Analysis) { Update-ScubaAnalyzerFullYaml } })

    # YAML copy/export
    $syncHash.CopyControlYaml_Button.Add_Click({
        try { [System.Windows.Clipboard]::SetText($syncHash.Detail_Yaml.Text); Set-ScubaAnalyzerStatus "Control YAML copied to clipboard." } catch { Write-Verbose "Clipboard copy failed: $($_.Exception.Message)" }
    })
    $syncHash.CopyAllYaml_Button.Add_Click({
        try { [System.Windows.Clipboard]::SetText($syncHash.FullYaml_TextBox.Text); Set-ScubaAnalyzerStatus "Configuration YAML copied to clipboard." } catch { Write-Verbose "Clipboard copy failed: $($_.Exception.Message)" }
    })
    $syncHash.ExportYaml_Button.Add_Click({ Export-ScubaAnalyzerYaml })

    # Jump to the current control in the ScubaGear baseline policy viewer
    $syncHash.ViewBaseline_Button.Add_Click({
        try {
            $f = $syncHash.Findings_List.SelectedItem
            if (-not $f) { return }
            if (-not $syncHash.ShowBaselinePolicyViewer) {
                Set-ScubaAnalyzerStatus "Baseline policy viewer is not available in this session."
                return
            }
            Set-ScubaAnalyzerStatus "Opening baseline policy viewer at $($f.ControlId)..."
            & $syncHash.ShowBaselinePolicyViewer -NavigateToPolicyId $f.ControlId | Out-Null
        } catch {
            Set-ScubaAnalyzerStatus "Could not open baseline viewer: $($_.Exception.Message)"
            Write-ScubaAnalyzerLog "Baseline viewer error: $($_.Exception.Message)"
        }
    })

    # Open the ScubaConfig app (in-process) with the detected exclusions pre-loaded
    $syncHash.OpenConfigApp_Button.Add_Click({ Start-ScubaAnalyzerConfigApp })

    # "Use this policy" buttons live inside the policy-card template; catch their clicks
    # at the container via the bubbling Button.Click routed event.
    if ($syncHash.Detail_Policies) {
        $syncHash.Detail_Policies.AddHandler(
            [System.Windows.Controls.Button]::ClickEvent,
            [System.Windows.RoutedEventHandler]{
                param($eventSender, $e)
                try {
                    $btn = ($e.Source -as [System.Windows.Controls.Button])
                    if (-not $btn) { $btn = ($e.OriginalSource -as [System.Windows.Controls.Button]) }
                    if ($btn -and $btn.Tag) { Use-ScubaAnalyzerPolicy -PolicyId ([string]$btn.Tag) }
                } catch { Write-Verbose "Use-policy click handler failed: $($_.Exception.Message)" }
            }
        )
    }

    Set-ScubaAnalyzerStatus "Ready. Connect & scan your tenant, or load an existing ScubaResults JSON, to begin."
}

Export-ModuleMember -Function @(
    'Initialize-ScubaConfigAnalyzerUI',
    'Start-ScubaAnalyzerAnalysis',
    'Start-ScubaAnalyzerTenantScan',
    'Show-ScubaAnalyzerDetail',
    'Update-ScubaAnalyzerFindings',
    'Update-ScubaAnalyzerFullYaml'
)
