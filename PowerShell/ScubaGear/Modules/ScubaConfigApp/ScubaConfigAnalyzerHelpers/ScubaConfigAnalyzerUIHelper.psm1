<#
.SYNOPSIS
    UI wiring + multithreaded orchestration for the ScubaGear Config Analyzer window

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

    ----------------------------------------------------------------------------------
    HOW THIS FILE FITS TOGETHER (read this first)
    ----------------------------------------------------------------------------------
    There are two modules behind the analyzer window:
      - ScubaConfigAnalyzerEngine.psm1   -> pure logic, NO WPF. Reads ScubaResults /
                                            tenant Graph data and returns plain objects.
                                            Unit-testable headlessly.
      - ScubaConfigAnalyzerUIHelper.psm1  -> THIS file. All the WPF/UI code. It calls the
                                            engine, then pushes the returned objects into
                                            the window's controls.
    The engine never touches the UI; the UI never re-implements analysis logic. That is
    the whole reason the code is in two files.

    Control flow when the user clicks "Connect & Scan":
      Start-ScubaAnalyzerTenantScan
        -> Connect-ScubaAnalyzerGraph      (engine, on UI thread so sign-in works)
        -> Get-ScubaTenantGraphData        (engine, reads CA policies from Graph)
        -> Invoke-ScubaTenantScan          (engine, on a BACKGROUND runspace)
        -> Update-ScubaAnalyzerFindings    (fills the findings list + header)
        -> Update-ScubaAnalyzerFullYaml    (regenerates the aggregate YAML)
    "Load results file" is the same, minus Graph: Start-ScubaAnalyzerAnalysis instead.

    ----------------------------------------------------------------------------------
    THE BACKGROUND-RUNSPACE PATTERN (used 3x below - this is the confusing bit)
    ----------------------------------------------------------------------------------
    WPF has one UI thread. If we run a multi-second analysis on it, the window freezes.
    So the heavy work runs on a second runspace and the answer is handed back like this:

      1. Make a synchronized hashtable as the "mailbox":
             @{ IsComplete = $false; Result = $null; Error = $null }
      2. Create an MTA runspace, copy in the values the worker needs
         (SessionStateProxy.SetVariable), and BeginInvoke a script that:
             imports the engine, does the work, writes Result/Error, sets IsComplete.
      3. Start a DispatcherTimer on the UI thread that ticks every ~200ms and does
         nothing until IsComplete is $true. When it flips true it: stops the timer,
         EndInvoke + disposes the runspace, then reads Result/Error and updates the UI.
    The DispatcherTimer tick runs BACK on the UI thread, so it is safe to touch controls
    there. The worker script must never touch $syncHash controls directly.

    ----------------------------------------------------------------------------------
    DATA CONTRACTS (shapes handed around - so you can predict what a variable holds)
    ----------------------------------------------------------------------------------
    $syncHash.Analysis  (returned by the engine; also what Invoke-ScubaTenantScan returns):
        MetaData = @{ DisplayName; Organization; TenantId; ScanDate; ResultsPath }
        Summary  = @{ Passes; Failures; Warnings; Errors; Manual; Total; ComplianceRate }
        Products = @('aad', ...)
        Findings = @( <Finding>, ... )          # one per analyzed control
        DisplayNameLookup = @{ '<object id>' = '<display name>' }

    <Finding> (one control - drives one row in the findings list + the detail pane):
        ControlId          = 'MS.AAD.3.1v1'
        ProductConfigKey   = 'Aad'              # top-level YAML key for this product
        Requirement        = 'Legacy authentication SHALL be blocked.'
        Result             = 'Fail' | 'Warning' | 'Pass' | 'Error' | 'Manual'
        Configurable       = $true              # can config (exclusions) make it pass?
        ExclusionField     = 'CapExclusions' | 'none'
        ConfigAction       = 'EXCLUDE' | 'FIX_TENANT' | ...
        DetectedExclusions = @{ Users=@(); Groups=@(); Applications=@(); GuestUserTypes=@() }
        AllPolicies        = @( <PolicyCandidate>, ... )   # matching CA policies
        BestMatch          = <PolicyCandidate> | $null     # closest to compliant
        SelectedPolicyId   = '<policy id>'      # which candidate the YAML follows
        RootCause, Recommendations, RemediationSteps, Details, Criticality, ...

    <PolicyCandidate> (one Conditional Access policy that relates to the control):
        Id, DisplayName, State
        Issues = @( 'WARNING: <msg>|DETAILS:<k>: <v>|SUGGESTION:<text>', ... )
        IssueCount, DetectedExclusions = @{ Users; Groups; Applications; GuestUserTypes }

    Key $syncHash UI handles used below: Window, Environment_ComboBox, Product_ListBox,
    Findings_List, Detail_* (detail pane controls), FullYaml_TextBox, Run_Button,
    Run_Progress, RunOutput_TextBox, TenantText / ConnectionText / ScanDateText (header).
    Launch params also on $syncHash: AppId, CertificateThumbprint, Organization,
    M365Environment, and the schema paths (AnalyzerEnginePath, BaselineSchemaPath, ...).

.NOTES
    Part of the ScubaGear project - https://github.com/cisagov/ScubaGear
#>

# ------------------------------------------------------------------------------------
# Small helpers
# ------------------------------------------------------------------------------------
function Get-ScubaAnalyzerText {
    <#
    .SYNOPSIS
    Returns a localized status-bar string from the control JSON (localeStatusMessages), applying
    -f formatting. Falls back to the key name if the locale is missing so nothing is silently blank.
    #>
    param(
        [Parameter(Mandatory)][string]$Key,
        [object[]]$FormatArgs
    )
    $text = $null
    try { $text = [string]$syncHash.Locale.localeStatusMessages.$Key } catch { $text = $null }
    if ([string]::IsNullOrEmpty($text)) { return $Key }
    if ($FormatArgs) { return ($text -f $FormatArgs) }
    return $text
}

function Set-ScubaAnalyzerStatus {
    <#
    .SYNOPSIS
    Writes a one-line message to the status bar at the bottom of the window.
    .DESCRIPTION
    Safe to call from ANY thread: it marshals the update onto the UI thread via the
    window dispatcher (WPF controls may only be touched from the thread that owns them).
    Wrapped in try/catch so a status update can never crash the operation behind it.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Message', Justification = 'Used inside the dispatcher [Action] scriptblock, which the analyzer does not inspect.')]
    param([string]$Message)
    try {
        # Only attempt the update once the window + status control actually exist.
        if ($syncHash.Window -and $syncHash.Status_Text) {
            # Dispatcher.Invoke hops onto the UI thread before setting the text.
            $syncHash.Window.Dispatcher.Invoke([Action] { $syncHash.Status_Text.Text = $Message })
        }
    } catch { Write-Verbose "Set-ScubaAnalyzerStatus failed: $($_.Exception.Message)" }
}

function Write-ScubaAnalyzerLog {
    <#
    .SYNOPSIS
    Appends a timestamped line to the "Run Output" activity log (and records it for -Passthru).
    .DESCRIPTION
    Mirrors ScubaConfigApp's Write-DebugOutput: records the entry in $syncHash.LogEntries and
    writes the Activity Log directly via the window dispatcher. -Level tags Warning/Error lines.
    .EXAMPLE
    Write-ScubaAnalyzerLog "Connected as admin@contoso (tenant 1234)."
    .EXAMPLE
    Write-ScubaAnalyzerLog "Graph read failed: ..." -Level Error
    #>
    param(
        [string]$Message,
        [ValidateSet('Info','Warning','Error')]
        [string]$Level = 'Info'
    )
    try {
        $prefix = if ($Level -ne 'Info') { "[$($Level.ToUpper())] " } else { "" }
        $line   = "[$(Get-Date -Format 'HH:mm:ss')] $prefix$Message"
        if ($syncHash.LogEntries) { [void]$syncHash.LogEntries.Add([pscustomobject]@{ Time = Get-Date; Level = $Level; Message = $Message }) }
        if ($syncHash.RunOutput_TextBox) {
            $syncHash.Window.Dispatcher.Invoke([Action] {
                $syncHash.RunOutput_TextBox.AppendText("$line`r`n")
                $syncHash.RunOutput_TextBox.ScrollToEnd()   # keep the newest line visible
            })
        }
    } catch { Write-Verbose "Write-ScubaAnalyzerLog failed: $($_.Exception.Message)" }
}

function Format-ScubaAnalyzerIssues {
    <#
    .SYNOPSIS
    Turns the engine's raw pipe-delimited issue strings into readable bullet text for
    the policy cards.
    .DESCRIPTION
    Each issue string the engine emits has up to three sections separated by '|':
        WARNING: <headline>|DETAILS:<key>: <values>|SUGGESTION:<what to do>
    This keeps the headline, appends the DETAILS in parentheses, and drops the
    WARNING:/ERROR: prefix and the SUGGESTION section (shown elsewhere).
    .EXAMPLE
    Format-ScubaAnalyzerIssues -Issues @(
        'WARNING: Policy has 2 excluded user(s)|DETAILS:IDs: 11.., 22..|SUGGESTION:review'
    )
    # Returns:
    #   - Policy has 2 excluded user(s)  (IDs: 11.., 22..)
    #>
    param([array]$Issues = @())

    $lines = @()
    foreach ($issue in @($Issues)) {
        if ([string]::IsNullOrWhiteSpace($issue)) { continue }
        $parts   = $issue -split '\|'                              # [0]=headline [1]=DETAILS [2]=SUGGESTION
        $main    = $parts[0] -replace '^(WARNING|ERROR):\s*', ''   # strip the severity prefix
        $detail  = @($parts | Where-Object { $_ -like 'DETAILS:*' }) -replace '^DETAILS:', ''
        $line    = "- $main"
        if ($detail) { $line += "  ($(($detail -join ' ').Trim()))" }   # tack DETAILS on in parens
        $lines += $line
    }
    return ($lines -join "`n")
}

# ------------------------------------------------------------------------------------
# YAML helpers (per-control + aggregate), driven by the detected exclusions
# ------------------------------------------------------------------------------------
function New-ScubaAnalyzerControlYamlText {
    <#
    .SYNOPSIS
    Builds the YAML snippet shown in the detail pane for ONE control (the "Control YAML"
    box), from that control's currently-selected exclusions.
    .DESCRIPTION
    This is the per-control preview only. The aggregate file for the whole tenant is
    built separately by the engine's Get-ScubaAnalyzerConfigYaml (see
    Update-ScubaAnalyzerFullYaml). Both intentionally produce the same layout.
    Controls whose ExclusionField is 'none' cannot be waived by config, so this returns
    an explanatory comment instead of a config block.
    .EXAMPLE
    # For MS.AAD.3.1v1 with two excluded users, returns text like:
    #   Aad:
    #     # Legacy authentication SHALL be blocked.
    #     # CA policy: Block legacy auth
    #     MS.AAD.3.1v1:
    #       CapExclusions:
    #         Users:
    #           - 1111....  # Break Glass 1
    #           - 2222....  # Break Glass 2
    #>
    param(
        [Parameter(Mandatory)]$Finding,
        $ExclusionValues = @{},                # field name -> @(values); covers principal AND list shapes
        [hashtable]$DisplayNameLookup = @{}   # object id -> friendly name, for '# name' comments
    )

    # Controls that don't support config exclusions get a comment, not a config block.
    if (-not $Finding.ExclusionField -or $Finding.ExclusionField -eq 'none') {
        return "# $($Finding.ControlId) does not support exclusions.`n# Remediate by creating or fixing the policy (see remediation steps)."
    }

    # Resolve the name of the CA policy the exclusions are based on (the user's selected
    # candidate if any, otherwise the best match) - emitted as a '# CA policy:' comment.
    $selId  = [string]$Finding.SelectedPolicyId
    $selPol = @($Finding.AllPolicies | Where-Object { [string]$_.Id -eq $selId }) | Select-Object -First 1
    $caName = if ($selPol) { $selPol.DisplayName } elseif ($Finding.BestMatch) { $Finding.BestMatch.DisplayName } else { $null }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("$($Finding.ProductConfigKey):")
    [void]$sb.AppendLine("  # $($Finding.Requirement)")
    if ($caName) { [void]$sb.AppendLine("  # CA policy: $caName") }
    [void]$sb.AppendLine("  $($Finding.ControlId):")
    [void]$sb.AppendLine("    $($Finding.ExclusionField):")

    # Principal-shape types (CapExclusions/RoleExclusions) expose named fields; list-shape
    # types (AllowedForwardingDomains, PartnerDomains, ...) have none and render as a flat list.
    $fieldDefs = @(Get-ScAExclusionFieldDefinitions -ExclusionField $Finding.ExclusionField)
    $didEmit = $false

    if (@($fieldDefs).Count -gt 0) {
        foreach ($fieldDef in $fieldDefs) {
            $fieldName = if ($fieldDef.value) { [string]$fieldDef.value } else { [string]$fieldDef.name }
            $fieldList = if ($ExclusionValues.Contains($fieldName)) { @($ExclusionValues[$fieldName]) } else { @() }
            if (@($fieldList).Count -eq 0) { continue }

            $didEmit = $true
            [void]$sb.AppendLine("      $($fieldName):")
            foreach ($item in @($fieldList)) {
                $key = [string]$item
                $comment = if ($DisplayNameLookup.ContainsKey($key)) { "  # $($DisplayNameLookup[$key])" } else { "" }
                [void]$sb.AppendLine("        - $item$comment")
            }
        }
        if (-not $didEmit) {
            $hint = @($fieldDefs | ForEach-Object { $_.value }) -join '/'
            [void]$sb.AppendLine("      # No exclusions. Add $hint only if justified.")
        }
    } else {
        $list = if ($ExclusionValues.Contains($Finding.ExclusionField)) { @($ExclusionValues[$Finding.ExclusionField]) } else { @() }
        if (@($list).Count -gt 0) {
            $didEmit = $true
            foreach ($v in @($list)) {
                $key = [string]$v
                $comment = if ($DisplayNameLookup.ContainsKey($key)) { "  # $($DisplayNameLookup[$key])" } else { "" }
                [void]$sb.AppendLine("      - $v$comment")
            }
        } else {
            [void]$sb.AppendLine("      # No entries detected. Add approved $($Finding.ExclusionField) here.")
        }
    }
    return $sb.ToString()
}

function Update-ScubaAnalyzerControlYaml {
    <#
    .SYNOPSIS
    Refreshes the detail pane's per-control YAML box (Detail_Yaml) for the given finding.
    .DESCRIPTION
    Pulls the finding's current DetectedExclusions (which change when the user picks a
    different candidate policy via Select-ScubaAnalyzerPolicy) and re-renders the snippet.
    Called whenever the selected finding or its chosen policy changes.
    #>
    param([Parameter(Mandatory)]$Finding)
    try {
        # Build one schema-keyed value map covering both principal and list exclusion shapes.
        $vals = [ordered]@{}
        if ($Finding.DetectedExclusions) {
            foreach ($k in @($Finding.DetectedExclusions.Keys)) {
                $v = $Finding.DetectedExclusions[$k]
                if ($null -ne $v -and @($v).Count -gt 0) { $vals[$k] = @($v) }
            }
        }
        if ($Finding.DetectedExclusionValues) {
            foreach ($k in @($Finding.DetectedExclusionValues.Keys)) {
                if (-not $vals.Contains($k) -and @($Finding.DetectedExclusionValues[$k]).Count -gt 0) {
                    $vals[$k] = @($Finding.DetectedExclusionValues[$k])
                }
            }
        }
        # DisplayNameLookup lets the snippet annotate each id with '# Friendly Name'.
        $lookup = if ($syncHash.Analysis -and $syncHash.Analysis.DisplayNameLookup) { $syncHash.Analysis.DisplayNameLookup } else { @{} }
        $syncHash.Detail_Yaml.Text = New-ScubaAnalyzerControlYamlText -Finding $Finding -ExclusionValues $vals -DisplayNameLookup $lookup
    } catch { Write-Verbose "Update-ScubaAnalyzerControlYaml failed: $($_.Exception.Message)" }
}

function Update-ScubaAnalyzerFullYaml {
    <#
    .SYNOPSIS
    Regenerates the aggregate configuration YAML (the "Configuration YAML" tab) for the
    whole tenant and pushes it into FullYaml_TextBox.
    .DESCRIPTION
    Delegates to the engine's Get-ScubaAnalyzerConfigYaml so the UI never re-implements
    YAML formatting. Call this after every change that can affect the file: a completed
    scan/analysis, a policy switch, or an environment-dropdown change. The selected
    environment and the launch-time app-only creds (AppId/Thumbprint) are folded into
    the generated header.
    #>
    try {
        if (-not $syncHash.Analysis) { return }   # nothing analyzed yet -> nothing to build
        # Environment drives the 'M365Environment:' line; default to commercial if unset.
        $env = if ($syncHash.Environment_ComboBox.SelectedItem) { [string]$syncHash.Environment_ComboBox.SelectedItem } else { 'commercial' }
        $lookup = if ($syncHash.Analysis.DisplayNameLookup) { $syncHash.Analysis.DisplayNameLookup } else { @{} }
        $syncHash.FullYaml_TextBox.Text = Get-ScubaAnalyzerConfigYaml -Analysis $syncHash.Analysis -M365Environment $env -DisplayNameLookup $lookup -AppId $syncHash.AppId -CertificateThumbprint $syncHash.CertificateThumbprint -Organization $syncHash.Organization
    } catch {
        Write-ScubaAnalyzerLog "Failed to build configuration YAML: $($_.Exception.Message)" -Level Error
    }
}

# ------------------------------------------------------------------------------------
# Findings list + detail rendering
# ------------------------------------------------------------------------------------
function Update-ScubaAnalyzerFindings {
    <#
    .SYNOPSIS
    Applies the toolbar filters (Issues-only, Configurable-only, search) and (re)builds
    the findings list + the header/summary line.
    .DESCRIPTION
    Reads the whole analysis from $syncHash.Analysis, updates the header (tenant, scan
    date, pass/fail counts), then binds the FILTERED subset of findings to the list.
    Call this after a scan/analysis completes and whenever a filter control changes.
    Setting Findings_List.ItemsSource is what actually repaints the list.
    #>
    if (-not $syncHash.Analysis) { return }
    $a = $syncHash.Analysis

    # --- Header + summary line -------------------------------------------------------
    # Prefer the tenant's primary domain (Organization); fall back to display name.
    $tenantLabel = if ($a.MetaData.Organization) { $a.MetaData.Organization } elseif ($a.MetaData.DisplayName) { $a.MetaData.DisplayName } else { '(unknown)' }
    $syncHash.TenantText.Text = "Tenant: $tenantLabel"
    $syncHash.ScanDateText.Text = if ($a.MetaData.ScanDate) { "Scan: $($a.MetaData.ScanDate)" } else { "" }
    $s = $a.Summary
    # "Need attention" = anything not a clean Pass.
    $needAttention = @($a.Findings | Where-Object { $_.Result -ne 'Pass' }).Count
    $syncHash.SummaryText.Text = "$($s.Total) controls, $needAttention need attention"
    $syncHash.ComplianceText.Text = "Pass $($s.Passes) | Fail $($s.Failures) | Warn $($s.Warnings) | Error $($s.Errors) | Manual $($s.Manual) | $($s.ComplianceRate)% compliant"

    # --- Read the three filter controls ----------------------------------------------
    $issuesOnly = [bool]$syncHash.IssuesOnly_CheckBox.IsChecked   # hide clean passes
    # ConfigurableOnly is optional (guard in case the XAML predates it).
    $configurableOnly = if ($syncHash.ContainsKey('ConfigurableOnly_CheckBox') -and $syncHash.ConfigurableOnly_CheckBox) { [bool]$syncHash.ConfigurableOnly_CheckBox.IsChecked } else { $false }
    $search = if ($syncHash.Search_TextBox.Text) { $syncHash.Search_TextBox.Text.Trim() } else { "" }

    # --- Apply all active filters (AND-combined) -------------------------------------
    $filtered = @($a.Findings | Where-Object {
        (-not $issuesOnly -or $_.Result -ne 'Pass') -and                 # Issues-only
        (-not $configurableOnly -or $_.Configurable) -and                # Configurable-only
        ([string]::IsNullOrWhiteSpace($search) -or                       # search matches id OR requirement
         $_.ControlId -like "*$search*" -or
         $_.Requirement -like "*$search*")
    })

    $syncHash.Findings_List.ItemsSource = $filtered   # bind = repaint the list
    # If nothing matches, hide the detail pane and show a placeholder message.
    if (@($filtered).Count -eq 0) {
        $syncHash.DetailContent.Visibility = 'Collapsed'
        $syncHash.EmptyDetailText.Visibility = 'Visible'
        $syncHash.EmptyDetailText.Text = "No findings match the current filter."
    }
}

function Select-ScubaAnalyzerPolicy {
    <#
    .SYNOPSIS
    Switches the "in use" candidate policy for the selected finding. The chosen policy's
    detected exclusions become the finding's exclusions so both the per-control and the
    full configuration YAML follow the user's choice.
    .DESCRIPTION
    A single control can match several Conditional Access policies, each with its own set
    of excluded users/groups. The user clicks "Use this policy" on a card to pick which
    one the generated config should mirror; this copies that candidate's exclusions onto
    the finding, then re-renders the detail pane and the aggregate YAML.
    .PARAMETER PolicyId
    The Id of the candidate policy (from the card's button Tag) to adopt.
    #>
    param([Parameter(Mandatory)][string]$PolicyId)
    try {
        $finding = $syncHash.Findings_List.SelectedItem
        if (-not $finding) { return }
        # Find the chosen candidate among this finding's matching policies.
        $chosen = @($finding.AllPolicies | Where-Object { [string]$_.Id -eq $PolicyId }) | Select-Object -First 1
        if (-not $chosen) { return }
        $finding.SelectedPolicyId = $PolicyId
        # Copy the candidate's exclusions onto the finding (fresh arrays so later edits
        # don't mutate the candidate). This is what the YAML builders read.
        $ex = if ($chosen.DetectedExclusions) { $chosen.DetectedExclusions } else { @{ Users = @(); Groups = @(); Applications = @(); GuestUserTypes = @() } }
        $finding.DetectedExclusions = @{ Users = @($ex.Users); Groups = @($ex.Groups); Applications = @($ex.Applications); GuestUserTypes = @($ex.GuestUserTypes) }
        # Keep the schema-keyed value map in sync so both YAML views follow the choice.
        $dv = [ordered]@{}
        foreach ($k in 'Users','Groups','Applications','GuestUserTypes') { if (@($finding.DetectedExclusions[$k]).Count -gt 0) { $dv[$k] = @($finding.DetectedExclusions[$k]) } }
        $finding.DetectedExclusionValues = $dv
        Show-ScubaAnalyzerDetail        # re-render cards (updates which one is "in use")
        Update-ScubaAnalyzerFullYaml    # aggregate YAML follows the new choice
        Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'UsingPolicy' @($chosen.DisplayName, $finding.ControlId))
    } catch {
        Write-ScubaAnalyzerLog "Use policy failed: $($_.Exception.Message)" -Level Error
    }
}

function Show-ScubaAnalyzerDetail {
    <#
    .SYNOPSIS
    Populates the right-hand detail pane for the finding currently selected in the list.
    .DESCRIPTION
    Fired by the Findings_List SelectionChanged event. Fills every Detail_* control:
    the header (control id, result badge, requirement, group, root cause, ScubaGear
    details), the recommendations, the matching-policy cards, the remediation steps, and
    finally the per-control YAML box. Each optional section is shown or Collapsed based
    on whether it has content, so empty sections don't leave gaps.
    #>
    try {
        $finding = $syncHash.Findings_List.SelectedItem
        # Nothing selected -> hide the detail pane, show the placeholder, and bail.
        if (-not $finding) {
            $syncHash.DetailContent.Visibility = 'Collapsed'
            $syncHash.EmptyDetailText.Visibility = 'Visible'
            return
        }
        $syncHash.EmptyDetailText.Visibility = 'Collapsed'
        $syncHash.DetailContent.Visibility = 'Visible'

        # --- Header block ------------------------------------------------------------
        $syncHash.Detail_ControlId.Text = $finding.ControlId
        $syncHash.Detail_ResultText.Text = $finding.Result
        $syncHash.Detail_ResultBadge.DataContext = $finding      # drives badge colour via DataTrigger
        $syncHash.Detail_Requirement.Text = $finding.Requirement
        $groupLabel = @("$($finding.GroupNumber) $($finding.GroupName)".Trim(), "Criticality: $($finding.Criticality)") -join '   -   '
        $syncHash.Detail_GroupText.Text = $groupLabel
        $syncHash.Detail_RootCause.Text = $finding.RootCause
        $syncHash.Detail_Details.Text = "ScubaGear details: $($finding.Details)"
        $syncHash.Detail_Criticality.Text = "Action: $($finding.RequiresAction)"

        # --- Recommendations (show the list only if there are any) -------------------
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

        # --- Matching-policy cards ---------------------------------------------------
        # Each card = one CA policy that relates to this control. The user can pick which
        # candidate the config follows ("Use this policy"); the selected one is expanded
        # and drives the YAML. We project each PolicyCandidate into a flat view-model with
        # pre-computed Visibility flags (WPF binds to these; it can't run logic itself).
        $policyItems = @()
        $best = $finding.BestMatch
        # Selected = the user's explicit choice, else the engine's best match.
        $selectedId = if ($finding.SelectedPolicyId) { [string]$finding.SelectedPolicyId } elseif ($best) { [string]$best.Id } else { $null }
        $multiple = (@($finding.AllPolicies).Count -gt 1)   # only offer a choice when >1
        foreach ($p in @($finding.AllPolicies)) {
            $isBest     = ($best -and $p.Id -eq $best.Id)
            $isSelected = ($selectedId -and [string]$p.Id -eq $selectedId)
            # Turn the raw issue strings into readable bullets; if none, the policy is clean.
            $issuesText = Format-ScubaAnalyzerIssues -Issues @($p.Issues)
            if (-not $issuesText) { $issuesText = "This policy meets the baseline requirement - no changes needed." }
            # Offer 'Use this policy' on the OTHER candidates only when there's a real choice.
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
                IsExpanded          = [bool]$isSelected   # expand the in-use card
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

        # --- Remediation steps (show only if the schema supplied any) ----------------
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

        # --- Per-control YAML box (reflects the currently-selected policy's exclusions)
        Update-ScubaAnalyzerControlYaml -Finding $finding
    } catch {
        Write-ScubaAnalyzerLog "Failed to render finding: $($_.Exception.Message)" -Level Error
    }
}

# ------------------------------------------------------------------------------------
# Analysis (background runspace, polled by a DispatcherTimer)
# ------------------------------------------------------------------------------------
function Start-ScubaAnalyzerAnalysis {
    <#
    .SYNOPSIS
    Analyzes an existing ScubaResults JSON (the "Load results file" path) on a background
    runspace so the UI never blocks.
    .DESCRIPTION
    This is the textbook version of the background-runspace pattern described in the file
    header. Follow the numbered STEP comments below to see the three phases:
      STEP 1  build the synchronized "mailbox"
      STEP 2  spin up the worker runspace and BeginInvoke the engine call
      STEP 3  poll the mailbox from the UI thread with a DispatcherTimer, then marshal
              the result back into the findings list + YAML.
    Use this when the data is already on disk; Start-ScubaAnalyzerTenantScan is the live
    Graph equivalent.
    .PARAMETER ResultsPath
    Path to a ScubaResults_*.json file to analyze.
    #>
    param([Parameter(Mandatory)][string]$ResultsPath)

    if (-not (Test-Path $ResultsPath)) {
        Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'ResultsFileNotFound' $ResultsPath)
        return
    }

    # Which products to analyze = whatever is selected in the Products list (default aad).
    $products = @($syncHash.Product_ListBox.SelectedItems | ForEach-Object { [string]$_.Key })
    if (@($products).Count -eq 0) { $products = @('aad') }

    # Show the indeterminate progress bar while the worker runs.
    $syncHash.Run_Progress.IsIndeterminate = $true
    $syncHash.Run_Progress.Visibility = 'Visible'
    # Loading a results file is NOT a live tenant connection - reflect that in the header.
    $syncHash.ConnectedTenant = $false
    if ($syncHash.ConnectionText) { $syncHash.ConnectionText.Text = 'Offline - results file' }
    Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'AnalyzingFile' (Split-Path $ResultsPath -Leaf))
    Write-ScubaAnalyzerLog "Analyzing results: $ResultsPath (products: $($products -join ', '))"

    # STEP 1: the "mailbox" - a synchronized hashtable both threads can see. The worker
    # writes Result/Error + flips IsComplete; the UI timer only ever reads it.
    $analysisSync = [hashtable]::Synchronized(@{ IsComplete = $false; Result = $null; Error = $null })
    $syncHash.AnalysisSync = $analysisSync

    # STEP 2: create the worker runspace and copy in the values it needs. It runs MTA
    # (no UI thread affinity) and gets only plain data + paths - never live WPF controls.
    $bgRunspace = [runspacefactory]::CreateRunspace()
    $bgRunspace.ApartmentState = "MTA"
    $bgRunspace.ThreadOptions = "ReuseThread"
    $bgRunspace.Open()
    $bgRunspace.SessionStateProxy.SetVariable("analysisSync", $analysisSync)
    # Share the REAL synchronized $syncHash (same as Start-ScubaAnalyzerTenantScan) so the engine's
    # Import-ScAAnalyzerRules populates the ScA* caches the UI thread later reads when rendering the
    # per-control YAML (Get-ScAExclusionFieldDefinitions). A separate worker cache left the UI thread's
    # ScAExclusionDefinitions empty, so imported findings rendered "No entries detected".
    $bgRunspace.SessionStateProxy.SetVariable("syncHash", $syncHash)
    $bgRunspace.SessionStateProxy.SetVariable("helpersPath", $syncHash.HelperModulesPath)
    $bgRunspace.SessionStateProxy.SetVariable("resultsPath", $ResultsPath)
    $bgRunspace.SessionStateProxy.SetVariable("product", $products)
    $bgRunspace.SessionStateProxy.SetVariable("baselineSchemaPath", $syncHash.BaselineSchemaPath)
    $bgRunspace.SessionStateProxy.SetVariable("AnalyzerControlPath", $syncHash.AnalyzerControlPath)
    $bgRunspace.SessionStateProxy.SetVariable("configSchemaPath", $syncHash.ConfigSchemaPath)

    $bgPS = [powershell]::Create()
    $bgPS.Runspace = $bgRunspace
    # The worker script: import the analyzer helper modules fresh (runspaces don't share module
    # state), run the analysis, and record the outcome in the mailbox. try/finally guarantees
    # IsComplete flips even on error, so the UI timer can never wait forever.
    [void]$bgPS.AddScript({
        try {
            # Import every analyzer helper module (engine + helpers), excluding the UI helper.
            Get-ChildItem -Path $helpersPath -Filter '*.psm1' | Where-Object { $_.Name -ne 'ScubaConfigAnalyzerUIHelper.psm1' } | ForEach-Object {
                Import-Module $_.FullName -Force -ErrorAction Stop
            }
            $analysisSync.Result = Invoke-ScubaConfigAnalysis -ResultsPath $resultsPath -Product $product `
                -BaselineSchemaPath $baselineSchemaPath -AnalyzerControlPath $AnalyzerControlPath -ConfigSchemaPath $configSchemaPath -IncludePassing
        } catch {
            $analysisSync.Error = $_.Exception.Message
        } finally {
            $analysisSync.IsComplete = $true
        }
    })
    # BeginInvoke returns immediately; the work proceeds on the worker thread. Keep the
    # handles on $syncHash so the timer tick can EndInvoke + dispose them later.
    $syncHash.AnalysisBgPS = $bgPS
    $syncHash.AnalysisBgHandle = $bgPS.BeginInvoke()
    $syncHash.AnalysisBgRunspace = $bgRunspace

    # STEP 3: poll from the UI thread. The tick runs on the UI thread, so it is safe to
    # touch controls here. It does nothing until the worker flips IsComplete.
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(200)
    $timer.Add_Tick({
        if (-not $syncHash.AnalysisSync.IsComplete) { return }   # not done yet - wait for the next tick
        $syncHash.AnalysisTimer.Stop()
        # Drain + dispose the worker (each wrapped so one cleanup failure can't abort the rest).
        try { [void]$syncHash.AnalysisBgPS.EndInvoke($syncHash.AnalysisBgHandle) } catch { Write-Verbose "Analysis EndInvoke cleanup: $($_.Exception.Message)" }
        try { $syncHash.AnalysisBgPS.Dispose() } catch { Write-Verbose "Analysis PS dispose cleanup: $($_.Exception.Message)" }
        try { $syncHash.AnalysisBgRunspace.Close(); $syncHash.AnalysisBgRunspace.Dispose() } catch { Write-Verbose "Analysis runspace dispose cleanup: $($_.Exception.Message)" }

        $syncHash.Run_Progress.Visibility = 'Collapsed'
        $syncHash.Run_Progress.IsIndeterminate = $false

        # If the worker recorded an error, surface it and stop.
        if ($syncHash.AnalysisSync.Error) {
            Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'AnalysisFailed' $syncHash.AnalysisSync.Error)
            Write-ScubaAnalyzerLog "Analysis failed: $($syncHash.AnalysisSync.Error)" -Level Error
            return
        }

        # Success: publish the result and repaint the findings list + aggregate YAML.
        $syncHash.Analysis = $syncHash.AnalysisSync.Result
        Update-ScubaAnalyzerFindings
        Update-ScubaAnalyzerFullYaml
        Update-ScubaAnalyzerTenantGovernanceJson
        $count = @($syncHash.Analysis.Findings | Where-Object { $_.Result -ne 'Pass' }).Count
        Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'AnalysisComplete' $count)
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
    Connects to Microsoft Graph + Exchange Online, reads the live tenant, and validates it
    against the baselines - all on a BACKGROUND runspace - marshaling status/findings back via a
    DispatcherTimer so the UI never freezes during the (blocking) sign-in and Graph reads.
    .DESCRIPTION
    The "Connect & Scan" button handler. The UI thread only flips the button/progress and starts
    the worker; every blocking step runs off-thread:
      Worker  - Connect Graph (A), connect Exchange Online if needed (A2), read tenant data (B),
                then validate against the baselines (C). It reports progress + the result through
                the synchronized $connectSync mailbox and never touches WPF controls.
      UI tick - a DispatcherTimer drains $connectSync (status, log lines, header) and, on
                completion, repaints the findings + YAML and re-enables the button.
    #>
    try {
        # Products + environment come straight from the toolbar selections.
        $products = @($syncHash.Product_ListBox.SelectedItems | ForEach-Object { [string]$_.Key })
        if (@($products).Count -eq 0) { $products = @('aad') }
        $env     = if ($syncHash.Environment_ComboBox.SelectedItem) { [string]$syncHash.Environment_ComboBox.SelectedItem } else { 'commercial' }
        # App-only = both an AppId and a cert thumbprint were supplied at launch.
        $appOnly = [bool]($syncHash.AppId -and $syncHash.CertificateThumbprint)

        # UI-thread setup only (fast): disable the button, show progress, jump to Run Output.
        $syncHash.Run_Button.IsEnabled = $false
        $syncHash.Run_Progress.IsIndeterminate = $true
        $syncHash.Run_Progress.Visibility = 'Visible'
        $syncHash.MainTabs.SelectedItem = $syncHash.ActivityLogTab
        $syncHash.LastConnectStatus = $null
        Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText $(if ($appOnly) { 'ConnectingGraphAppOnly' } else { 'ConnectingGraphInteractive' }))

        # Mailbox: the worker writes Status/Log/connection info/Result; the UI timer only reads it.
        $connectSync = [hashtable]::Synchronized(@{
            IsComplete = $false; Error = $null; Result = $null; Status = $null
            Log = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
            Connected = $false; HeaderApplied = $false
            ConnMode = $null; ConnWho = $null; Environment = $null; TenantLabel = $null
        })
        $syncHash.ConnectSync = $connectSync

        # Background runspace. It shares the real (synchronized) $syncHash for the ScA caches, paths
        # and launch params, imports the analyzer helpers (not the UI helper), and runs A -> C.
        $bg = [runspacefactory]::CreateRunspace(); $bg.ApartmentState = 'MTA'; $bg.ThreadOptions = 'ReuseThread'; $bg.Open()
        $bg.SessionStateProxy.SetVariable('syncHash', $syncHash)
        $bg.SessionStateProxy.SetVariable('connectSync', $connectSync)
        $bg.SessionStateProxy.SetVariable('helpersPath', $syncHash.HelperModulesPath)
        $bg.SessionStateProxy.SetVariable('products', $products)
        $bg.SessionStateProxy.SetVariable('env', $env)
        $bg.SessionStateProxy.SetVariable('appOnly', $appOnly)
        $bgPS = [powershell]::Create(); $bgPS.Runspace = $bg
        [void]$bgPS.AddScript({
            try {
                Get-ChildItem -Path $helpersPath -Filter '*.psm1' | Where-Object { $_.Name -ne 'ScubaConfigAnalyzerUIHelper.psm1' } | ForEach-Object {
                    Import-Module $_.FullName -Force -ErrorAction Stop
                }
                $baseline = Get-Content $syncHash.BaselineSchemaPath -Raw | ConvertFrom-Json

                # Point the engine's activity sink at this run's log mailbox so the data-collection
                # helpers (Get-ScubaTenantGraphData, etc.) can report what they pull to the Activity Log.
                $syncHash.ScAActivitySink = $connectSync.Log

                # --- Phase A: Microsoft Graph ---
                [void]$connectSync.Log.Add(@{ Message = "Connecting to Microsoft Graph ($env) for products '$($products -join ', ')'$(if ($appOnly) { " - noninteractive appid ($($syncHash.AppId))" })..."; Level = 'Info' })
                if ($appOnly) {
                    $ctx = Connect-ScubaAnalyzerGraph -M365Environment $env -AppId $syncHash.AppId -CertificateThumbprint $syncHash.CertificateThumbprint -Organization $syncHash.Organization
                } else {
                    $scopes = @()
                    foreach ($p in $products) { $scopes += Get-ScubaAnalyzerScopes -Product $p -BaselineSchema $baseline -ApiCatalogPath $syncHash.ApiCatalogPath -AnalyzerControlPath $syncHash.AnalyzerControlPath }
                    $scopes = @($scopes | Select-Object -Unique)
                    [void]$connectSync.Log.Add(@{ Message = "Requesting Graph scopes: $($scopes -join ', ')"; Level = 'Info' })
                    $ctx = Connect-ScubaAnalyzerGraph -Scopes $scopes -M365Environment $env
                }
                $connectSync.ConnMode    = if ($appOnly) { 'Connected (app-only)' } else { 'Connected' }
                $connectSync.ConnWho     = if ($appOnly) { [string]$syncHash.AppId } elseif ($ctx.Account) { [string]$ctx.Account } else { [string]$ctx.ClientId }
                $connectSync.Environment = $env
                $connectSync.Connected   = $true
                [void]$connectSync.Log.Add(@{ Message = "Connected as $($ctx.Account) (tenant $($ctx.TenantId))."; Level = 'Info' })

                # --- Phase A2: Exchange Online (only if a selected product needs it) ---
                $connectSync.Status = "Retrieving tenant configuration..."
                try {
                    $fetchConns = @(Get-ScubaAnalyzerFetchConnections -Products $products -BaselineSchema $baseline -AnalyzerControlPath $syncHash.AnalyzerControlPath)
                    if (@($fetchConns | Where-Object { $_.connectCmdlet -eq 'Connect-ExchangeOnline' }).Count -gt 0) {
                        $connectSync.Status = if ($appOnly) { "Connecting to Exchange Online (appid & certificate)..." } else { "Connecting to Exchange Online..." }
                        [void]$connectSync.Log.Add(@{ Message = $connectSync.Status; Level = 'Info' })
                        if ($appOnly) {
                            Connect-ScubaAnalyzerExchange -M365Environment $env -AppId $syncHash.AppId -CertificateThumbprint $syncHash.CertificateThumbprint -Organization $syncHash.Organization | Out-Null
                        } else {
                            Connect-ScubaAnalyzerExchange -M365Environment $env -Organization $syncHash.Organization | Out-Null
                        }
                        [void]$connectSync.Log.Add(@{ Message = "Connected to Exchange Online."; Level = 'Info' })
                    }
                } catch {
                    # Non-fatal: affected controls report 'could not collect data' instead of a false pass.
                    [void]$connectSync.Log.Add(@{ Message = "Exchange Online connect failed: $($_.Exception.Message). EXO/SecuritySuite checks will be marked for review."; Level = 'Error' })
                }

                # --- Phase B: read tenant data ---
                $connectSync.Status = "Retrieving tenant configuration from Microsoft Graph..."
                $tenantData = @{ conditional_access_policies = @(); OrgDisplayName = $null; Organization = $null; TenantId = $null; DisplayNameLookup = @{} }
                foreach ($p in $products) {
                    $d = Get-ScubaTenantGraphData -Product $p -BaselineSchema $baseline -ApiCatalogPath $syncHash.ApiCatalogPath -AnalyzerControlPath $syncHash.AnalyzerControlPath
                    if (@($d.conditional_access_policies).Count -gt 0) { $tenantData.conditional_access_policies = $d.conditional_access_policies }
                    if ($d.OrgDisplayName) { $tenantData.OrgDisplayName = $d.OrgDisplayName }
                    if ($d.Organization)  { $tenantData.Organization  = $d.Organization }
                    if ($d.TenantId)      { $tenantData.TenantId      = $d.TenantId }
                    if ($d.DisplayNameLookup) { foreach ($k in @($d.DisplayNameLookup.Keys)) { $tenantData.DisplayNameLookup[$k] = $d.DisplayNameLookup[$k] } }
                    foreach ($k in @($d.Keys)) {
                        if ($k -in @('conditional_access_policies','OrgDisplayName','Organization','TenantId','DisplayNameLookup')) { continue }
                        if ($null -ne $d[$k]) { $tenantData[$k] = $d[$k] }
                    }
                }
                $connectSync.TenantLabel = if ($tenantData.Organization) { $tenantData.Organization } elseif ($tenantData.OrgDisplayName) { $tenantData.OrgDisplayName } elseif ($syncHash.Organization) { $syncHash.Organization } else { $null }
                [void]$connectSync.Log.Add(@{ Message = "Retrieved $(@($tenantData.conditional_access_policies).Count) Conditional Access policy/policies."; Level = 'Info' })

                # --- Phase C: validate against the baselines ---
                $connectSync.Status = "Analyzing $(@($tenantData.conditional_access_policies).Count) policies against the baselines..."
                $connectSync.Result = Invoke-ScubaTenantScan -Product $products -M365Environment $env -TenantData $tenantData -BaselineSchemaPath $syncHash.BaselineSchemaPath -AnalyzerControlPath $syncHash.AnalyzerControlPath -ConfigSchemaPath $syncHash.ConfigSchemaPath
            } catch {
                $connectSync.Error = $_.Exception.Message
            } finally {
                $syncHash.ScAActivitySink = $null
                $connectSync.IsComplete = $true
            }
        })
        $syncHash.ConnectBgPS = $bgPS
        $syncHash.ConnectBgHandle = $bgPS.BeginInvoke()
        $syncHash.ConnectBgRunspace = $bg

        # UI timer: reflect status/log/header and, on completion, repaint findings + re-enable.
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(250)
        $timer.Add_Tick({
            $cs = $syncHash.ConnectSync
            if (-not $cs) { return }

            # Drain queued log lines (worker only appends; the UI only removes from the front).
            while ($cs.Log.Count -gt 0) {
                $item = $null
                try { $item = $cs.Log[0]; $cs.Log.RemoveAt(0) } catch { break }
                if ($item) { Write-ScubaAnalyzerLog $item.Message -Level $item.Level }
            }
            # Current status line.
            if ($cs.Status -and $cs.Status -ne $syncHash.LastConnectStatus) {
                Set-ScubaAnalyzerStatus $cs.Status
                $syncHash.LastConnectStatus = $cs.Status
            }
            # Header: apply the connected badge once, then keep the tenant label current.
            if ($cs.Connected -and -not $cs.HeaderApplied) {
                $cs.HeaderApplied = $true
                $syncHash.ConnectedTenant = $true
                $syncHash.ConnectedEnvironment = $cs.Environment
                if ($syncHash.ConnectionText -and $cs.ConnMode) {
                    $syncHash.ConnectionText.Text = "$($cs.ConnMode): $($cs.ConnWho) ($($cs.Environment))"
                    $syncHash.ConnectionText.Foreground = [System.Windows.Media.Brushes]::LightGreen
                }
            }
            if ($cs.TenantLabel -and $syncHash.TenantText -and $syncHash.TenantText.Text -ne "Tenant: $($cs.TenantLabel)") {
                $syncHash.TenantText.Text = "Tenant: $($cs.TenantLabel)"
            }

            if (-not $cs.IsComplete) { return }
            $syncHash.ConnectTimer.Stop()
            # Drain + dispose the worker (guarded so one failure can't abort the others).
            try { [void]$syncHash.ConnectBgPS.EndInvoke($syncHash.ConnectBgHandle) } catch { Write-Verbose "Connect EndInvoke cleanup: $($_.Exception.Message)" }
            try { $syncHash.ConnectBgPS.Dispose() } catch { Write-Verbose "Connect PS dispose cleanup: $($_.Exception.Message)" }
            try { $syncHash.ConnectBgRunspace.Close(); $syncHash.ConnectBgRunspace.Dispose() } catch { Write-Verbose "Connect runspace dispose cleanup: $($_.Exception.Message)" }

            $syncHash.Run_Progress.Visibility = 'Collapsed'; $syncHash.Run_Progress.IsIndeterminate = $false
            $syncHash.Run_Button.IsEnabled = $true

            if ($cs.Error) {
                Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'ScanFailed' $cs.Error)
                Write-ScubaAnalyzerLog "Scan failed: $($cs.Error)" -Level Error
                return
            }
            # Success: publish, repaint, and jump back to the Findings tab.
            $syncHash.Analysis = $cs.Result
            Update-ScubaAnalyzerFindings
            Update-ScubaAnalyzerFullYaml
            Update-ScubaAnalyzerTenantGovernanceJson
            $syncHash.MainTabs.SelectedIndex = 0
            $count = @($syncHash.Analysis.Findings | Where-Object { $_.Result -ne 'Pass' }).Count
            Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'ScanComplete' $count)
            Write-ScubaAnalyzerLog "Scan complete."
        })
        $syncHash.ConnectTimer = $timer
        $timer.Start()
    } catch {
        $syncHash.Run_Button.IsEnabled = $true
        $syncHash.Run_Progress.Visibility = 'Collapsed'; $syncHash.Run_Progress.IsIndeterminate = $false
        Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'ScanError' $_.Exception.Message)
        Write-ScubaAnalyzerLog "Scan error: $($_.Exception.Message)" -Level Error
    }
}

# ------------------------------------------------------------------------------------
# Open the ScubaConfig app in-process (no new console / window-process)
# ------------------------------------------------------------------------------------
function Open-ScubaConfigAppFromAnalyzer {
    <#
    .SYNOPSIS
    Opens Start-SCuBAConfigApp inside this process (its own runspace, no extra console
    window) and, when a configuration YAML has been generated, pre-loads it so the
    detected exclusions are already populated.
    .DESCRIPTION
    The ScubaConfig app is a second WPF window, and every WPF window needs its own STA
    thread - so unlike the MTA analysis/scan workers above, this creates an STA runspace.
    We do NOT poll it with a DispatcherTimer: it is a fire-and-forget UI, not a job that
    returns a value. We only keep the runspace/PowerShell handles alive (in
    ConfigAppInstances) so the garbage collector doesn't tear the window down.
    The generated YAML is written to a temp file and passed via -ConfigFilePath; when the
    analyzer authenticated (app-only or live), those creds/environment are forwarded so
    the config app opens Online without a second sign-in.
    #>
    try {
        if (-not $syncHash.ScubaConfigAppModulePath -or -not (Test-Path $syncHash.ScubaConfigAppModulePath)) {
            Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'ConfigAppNotFound')
            return
        }

        # Pre-load the generated config so the exclusions carry over into the app.
        # (Written to TEMP; the config app reads it via -ConfigFilePath.)
        $configFile = $null
        if ($syncHash.FullYaml_TextBox -and -not [string]::IsNullOrWhiteSpace($syncHash.FullYaml_TextBox.Text)) {
            $tmpDir = Join-Path $env:TEMP 'ScubaConfigAnalyzer'
            if (-not (Test-Path $tmpDir)) { New-Item -Path $tmpDir -ItemType Directory -Force | Out-Null }
            $configFile = Join-Path $tmpDir "AnalyzerConfig_$(Get-Date -Format 'yyyyMMdd_HHmmss').yaml"
            [System.IO.File]::WriteAllText($configFile, $syncHash.FullYaml_TextBox.Text, [System.Text.Encoding]::UTF8)
        }

        # If the analyzer used app-only cert auth, or is connected to a live tenant, open the
        # config app Online against the same environment so the user isn't prompted to sign in
        # again. App-only creds (when provided) are forwarded so the config app connects silently.
        $appOnly = [bool]($syncHash.AppId -and $syncHash.CertificateThumbprint)
        $online  = [bool]$syncHash.ConnectedTenant -or $appOnly
        $envName = if ($syncHash.ConnectedEnvironment) { [string]$syncHash.ConnectedEnvironment }
                   elseif ($syncHash.Environment_ComboBox.SelectedItem) { [string]$syncHash.Environment_ComboBox.SelectedItem }
                   else { 'commercial' }

        $rs = [runspacefactory]::CreateRunspace()
        $rs.ApartmentState = 'STA'; $rs.ThreadOptions = 'ReuseThread'; $rs.Open()   # STA: it hosts a WPF window
        $rs.SessionStateProxy.SetVariable('modulePath', $syncHash.ScubaConfigAppModulePath)
        $rs.SessionStateProxy.SetVariable('configFile', $configFile)
        $rs.SessionStateProxy.SetVariable('online', $online)
        $rs.SessionStateProxy.SetVariable('envName', $envName)
        $rs.SessionStateProxy.SetVariable('appId', ([string]$syncHash.AppId))
        $rs.SessionStateProxy.SetVariable('certThumbprint', ([string]$syncHash.CertificateThumbprint))
        $rs.SessionStateProxy.SetVariable('tenantName', ([string]$syncHash.Organization))
        $ps = [powershell]::Create(); $ps.Runspace = $rs
        [void]$ps.AddScript({
            Import-Module $modulePath -Force
            $p = @{}
            if ($configFile -and (Test-Path $configFile)) { $p.ConfigFilePath = $configFile }
            if ($online) {
                $p.Online = $true
                $p.M365Environment = $envName
                if ($appId -and $certThumbprint) {
                    # Forward app-only creds so the config app connects without a new sign-in.
                    $p.AppId = $appId
                    $p.CertificateThumbprint = $certThumbprint
                    if ($tenantName) { $p.TenantName = $tenantName }
                }
            }
            Start-SCuBAConfigApp @p
        })
        [void]$ps.BeginInvoke()

        # Keep references so the runspace isn't collected while the config app is open.
        if (-not $syncHash.ConfigAppInstances) { $syncHash.ConfigAppInstances = [System.Collections.ArrayList]::new() }
        [void]$syncHash.ConfigAppInstances.Add(@{ Runspace = $rs; PowerShell = $ps })

        $mode = if ($appOnly) { " (Online, app-only: $envName)" } elseif ($online) { " (Online: $envName)" } else { "" }
        if ($configFile) { Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'ConfigAppOpenedWithConfig' $mode) }
        else { Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'ConfigAppOpened' $mode) }
    } catch {
        Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'ConfigAppOpenError' $_.Exception.Message)
        Write-ScubaAnalyzerLog "Open ScubaConfig app failed: $($_.Exception.Message)" -Level Error
    }
}

# ------------------------------------------------------------------------------------
# Export
# ------------------------------------------------------------------------------------
function Export-ScubaAnalyzerYaml {
    <#
    .SYNOPSIS
    Prompts for a path and saves the aggregate configuration YAML (FullYaml_TextBox) to
    disk as UTF-8. No-op with a status message if nothing has been generated yet.
    #>
    try {
        if ([string]::IsNullOrWhiteSpace($syncHash.FullYaml_TextBox.Text)) {
            Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'NothingToExport')
            return
        }
        $dlg = New-Object Microsoft.Win32.SaveFileDialog
        $dlg.Filter = "YAML files (*.yaml)|*.yaml|All files (*.*)|*.*"
        $dlg.FileName = "ScubaGearConfig.yaml"
        $dlg.Title = "Export ScubaGear configuration"
        if ($dlg.ShowDialog() -eq $true) {
            [System.IO.File]::WriteAllText($dlg.FileName, $syncHash.FullYaml_TextBox.Text, [System.Text.Encoding]::UTF8)
            Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'ConfigExported' $dlg.FileName)
            Write-ScubaAnalyzerLog "Configuration exported to $($dlg.FileName)"
        }
    } catch {
        Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'ExportFailed' $_.Exception.Message)
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
    .DESCRIPTION
    This is the "table of contents" for the window - read it to find which handler runs
    for any control. It executes top-to-bottom in these sections:
      1. Logo + version text.
      2. Header pre-fill from launch params (tenant, and app-only app id in amber).
      3. Environment dropdown   - filled from ScubaConfigSchema.json enum.
      4. Products list          - configurable products intersected with baselines.
      5. Toolbar buttons        - Run (Connect & Scan) and Load (results file).
      6. Filters                - Issues-only / Configurable-only / search -> refilter.
      7. YAML copy/export buttons.
      8. "View baseline" button  - jumps into the shared policy viewer.
      9. "Open ConfigApp" button - hands the generated YAML to Open-ScubaConfigAppFromAnalyzer.
     10. "Use this policy"       - one routed handler on the policy list catches every
                                  card's button (see the AddHandler note below).
    Every handler is a closure over $syncHash, so it can still reach the controls long
    after this function has returned.
    #>

    # Logo + version
    try { if ($syncHash.ImgPath -and (Test-Path $syncHash.ImgPath)) { $syncHash.LogoImage.Source = $syncHash.ImgPath } } catch { Write-Verbose "Logo load failed: $($_.Exception.Message)" }
    if ($syncHash.AnalyzerVersion) { $syncHash.VersionText.Text = "v$($syncHash.AnalyzerVersion)" }

    # Pre-fill the header from launch parameters: show the tenant (Organization) and, when launched
    # with app-only creds, the app id (amber = configured but not connected until Connect & Scan).
    if ($syncHash.Organization -and $syncHash.TenantText) {
        $syncHash.TenantText.Text = "Tenant: $($syncHash.Organization)"
    }
    if ($syncHash.ConnectionText -and $syncHash.AppId -and $syncHash.CertificateThumbprint) {
        $syncHash.ConnectionText.Text = "(not connected) App-only: $($syncHash.AppId)"
        $syncHash.ConnectionText.Foreground = [System.Windows.Media.Brushes]::Goldenrod
    }
    # Environments: pull from ScubaConfigSchema.json (properties.M365Environment.enum).
    try {
        $cs = Get-Content $syncHash.ConfigSchemaPath -Raw | ConvertFrom-Json
        foreach ($e in @($cs.properties.M365Environment.enum)) { [void]$syncHash.Environment_ComboBox.Items.Add($e) }
    } catch { Write-Verbose "Could not load M365Environment enum from schema: $($_.Exception.Message)" }
    if ($syncHash.Environment_ComboBox.Items.Count -gt 0) { $syncHash.Environment_ComboBox.SelectedIndex = 0 }

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
        $as = Get-Content $syncHash.AnalyzerControlPath -Raw | ConvertFrom-Json
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
        } catch { Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'LoadFileError' $_.Exception.Message) }
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
        try { [System.Windows.Clipboard]::SetText($syncHash.Detail_Yaml.Text); Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'ControlYamlCopied') } catch { Write-Verbose "Clipboard copy failed: $($_.Exception.Message)" }
    })
    $syncHash.CopyAllYaml_Button.Add_Click({
        try { [System.Windows.Clipboard]::SetText($syncHash.FullYaml_TextBox.Text); Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'ConfigYamlCopied') } catch { Write-Verbose "Clipboard copy failed: $($_.Exception.Message)" }
    })
    $syncHash.ExportYaml_Button.Add_Click({ Export-ScubaAnalyzerYaml })
    if ($syncHash.TenantGovernanceTab) {
        $syncHash.TenantGovernanceTab.Visibility = if ($syncHash.GenerateTenantGovernanceConfig) { 'Visible' } else { 'Collapsed' }
        $syncHash.CopyTenantGovernance_Button.Add_Click({ Copy-ScubaAnalyzerTenantGovernanceJson })
        $syncHash.ExportTenantGovernance_Button.Add_Click({ Export-ScubaAnalyzerTenantGovernanceJson })
    }

    # Jump to the current control in the ScubaGear baseline policy viewer
    $syncHash.ViewBaseline_Button.Add_Click({
        try {
            $f = $syncHash.Findings_List.SelectedItem
            if (-not $f) { return }
            if (-not $syncHash.ShowBaselinePolicyViewer) {
                Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'BaselineViewerUnavailable')
                return
            }
            Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'OpeningBaselineViewer' $f.ControlId)
            & $syncHash.ShowBaselinePolicyViewer -NavigateToPolicyId $f.ControlId | Out-Null
        } catch {
            Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'BaselineViewerError' $_.Exception.Message)
            Write-ScubaAnalyzerLog "Baseline viewer error: $($_.Exception.Message)" -Level Error
        }
    })

    # Open the ScubaConfig app (in-process) with the detected exclusions pre-loaded
    $syncHash.OpenConfigApp_Button.Add_Click({ Open-ScubaConfigAppFromAnalyzer })

    # "Use this policy" buttons live inside the policy-card template; catch their clicks
    # at the container via the bubbling Button.Click routed event.
    if ($syncHash.Detail_Policies) {
        $syncHash.Detail_Policies.AddHandler(
            [System.Windows.Controls.Button]::ClickEvent,
            [System.Windows.RoutedEventHandler]{
                param($eventSender, $e)
                $null = $eventSender   # sender unused; the routed event args carry the clicked button
                try {
                    $btn = ($e.Source -as [System.Windows.Controls.Button])
                    if (-not $btn) { $btn = ($e.OriginalSource -as [System.Windows.Controls.Button]) }
                    if ($btn -and $btn.Tag) { Select-ScubaAnalyzerPolicy -PolicyId ([string]$btn.Tag) }
                } catch { Write-Verbose "Use-policy click handler failed: $($_.Exception.Message)" }
            }
        )
    }

    Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'Ready')
}

# No Export-ModuleMember: like the other analyzer helper modules, all functions are exported
# so the launcher runspace can call them (Set-ScubaAnalyzerStatus, Write-ScubaAnalyzerLog,
# Export-ScubaAnalyzerYaml, Select-ScubaAnalyzerPolicy, etc.).
