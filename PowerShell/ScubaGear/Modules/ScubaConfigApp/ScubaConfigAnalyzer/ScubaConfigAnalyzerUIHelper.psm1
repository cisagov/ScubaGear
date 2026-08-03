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
    Appends a timestamped line to the "Run Output" tab's log box.
    .DESCRIPTION
    Like Set-ScubaAnalyzerStatus, this is thread-safe (marshals onto the UI thread) and
    swallows its own errors. Use it for progress the user should be able to scroll back
    through; use Set-ScubaAnalyzerStatus for the single current-state line.
    .EXAMPLE
    Write-ScubaAnalyzerLog "Connected as admin@contoso (tenant 1234)."
    # Appends:  [14:03:22] Connected as admin@contoso (tenant 1234).
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Message', Justification = 'Used inside the dispatcher [Action] scriptblock, which the analyzer does not inspect.')]
    param([string]$Message)
    try {
        $ts = Get-Date -Format 'HH:mm:ss'
        if ($syncHash.RunOutput_TextBox) {
            $syncHash.Window.Dispatcher.Invoke([Action] {
                $syncHash.RunOutput_TextBox.AppendText("[$ts] $Message`r`n")
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
        [array]$Users = @(),
        [array]$Groups = @(),
        [array]$Applications = @(),
        [array]$GuestUserTypes = @(),
        [hashtable]$DisplayNameLookup = @{}   # object id -> friendly name, for '# name' comments
    )

    # Controls that don't support config exclusions get a comment, not a config block.
    if ($Finding.ExclusionField -eq 'none') {
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
    if (@($Users).Count -gt 0) {
        [void]$sb.AppendLine("      Users:")
        foreach ($id in $Users) { $c = if ($DisplayNameLookup.ContainsKey($id)) { "  # $($DisplayNameLookup[$id])" } else { "" }; [void]$sb.AppendLine("        - $id$c") }
    }
    if (@($Groups).Count -gt 0) {
        [void]$sb.AppendLine("      Groups:")
        foreach ($id in $Groups) { $c = if ($DisplayNameLookup.ContainsKey($id)) { "  # $($DisplayNameLookup[$id])" } else { "" }; [void]$sb.AppendLine("        - $id$c") }
    }
    if (@($Applications).Count -gt 0) {
        [void]$sb.AppendLine("      Applications:")
        foreach ($app in $Applications) { $c = if ($DisplayNameLookup.ContainsKey($app)) { "  # $($DisplayNameLookup[$app])" } else { "" }; [void]$sb.AppendLine("        - $app$c") }
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
        # Split the detected exclusions into the four lists the YAML builder expects.
        $users  = @($Finding.DetectedExclusions.Users)
        $groups = @($Finding.DetectedExclusions.Groups)
        $apps   = @($Finding.DetectedExclusions.Applications)
        $guests = @($Finding.DetectedExclusions.GuestUserTypes)
        # DisplayNameLookup lets the snippet annotate each id with '# Friendly Name'.
        $lookup = if ($syncHash.Analysis -and $syncHash.Analysis.DisplayNameLookup) { $syncHash.Analysis.DisplayNameLookup } else { @{} }
        $syncHash.Detail_Yaml.Text = New-ScubaAnalyzerControlYamlText -Finding $Finding -Users $users -Groups $groups -Applications $apps -GuestUserTypes $guests -DisplayNameLookup $lookup
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
        Write-ScubaAnalyzerLog "Failed to build configuration YAML: $($_.Exception.Message)"
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
        Show-ScubaAnalyzerDetail        # re-render cards (updates which one is "in use")
        Update-ScubaAnalyzerFullYaml    # aggregate YAML follows the new choice
        Set-ScubaAnalyzerStatus "Using policy '$($chosen.DisplayName)' for $($finding.ControlId)."
    } catch {
        Write-ScubaAnalyzerLog "Use policy failed: $($_.Exception.Message)"
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
        Write-ScubaAnalyzerLog "Failed to render finding: $($_.Exception.Message)"
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
        Set-ScubaAnalyzerStatus "Results file not found: $ResultsPath"
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
    Set-ScubaAnalyzerStatus "Analyzing $(Split-Path $ResultsPath -Leaf) ..."
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
    $bgRunspace.SessionStateProxy.SetVariable("enginePath", $syncHash.AnalyzerEnginePath)
    $bgRunspace.SessionStateProxy.SetVariable("resultsPath", $ResultsPath)
    $bgRunspace.SessionStateProxy.SetVariable("product", $products)
    $bgRunspace.SessionStateProxy.SetVariable("baselineSchemaPath", $syncHash.BaselineSchemaPath)
    $bgRunspace.SessionStateProxy.SetVariable("analyzerSchemaPath", $syncHash.AnalyzerSchemaPath)
    $bgRunspace.SessionStateProxy.SetVariable("configSchemaPath", $syncHash.ConfigSchemaPath)

    $bgPS = [powershell]::Create()
    $bgPS.Runspace = $bgRunspace
    # The worker script: import the engine fresh (runspaces don't share module state),
    # run the analysis, and record the outcome in the mailbox. try/finally guarantees
    # IsComplete flips even on error, so the UI timer can never wait forever.
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
            Set-ScubaAnalyzerStatus "Analysis failed: $($syncHash.AnalysisSync.Error)"
            Write-ScubaAnalyzerLog "Analysis failed: $($syncHash.AnalysisSync.Error)"
            return
        }

        # Success: publish the result and repaint the findings list + aggregate YAML.
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
    .DESCRIPTION
    This is the "Connect & Scan" button handler. It runs in three phases:
      PHASE A - Connect to Graph ON THE UI THREAD. Interactive sign-in needs the UI
                thread; app-only cert auth is non-interactive. Either way the Graph
                session lives on this thread, so the reads in Phase B must run here too.
      PHASE B - Read tenant data (CA policies + display names) from Graph, still on the
                UI thread where the session is valid. This is quick relative to Phase C.
      PHASE C - Validate the policies against the baselines on a BACKGROUND runspace
                (pure CPU, no Graph), using the standard mailbox + DispatcherTimer
                pattern from the file header, then repaint the findings + YAML.
    Contrast with Start-ScubaAnalyzerAnalysis, which skips Phases A/B (data is on disk).
    #>
    try {
        # Products + environment come straight from the toolbar selections.
        $products = @($syncHash.Product_ListBox.SelectedItems | ForEach-Object { [string]$_.Key })
        if (@($products).Count -eq 0) { $products = @('aad') }
        $env     = if ($syncHash.Environment_ComboBox.SelectedItem) { [string]$syncHash.Environment_ComboBox.SelectedItem } else { 'commercial' }

        # ===== PHASE A: connect to Microsoft Graph (on the UI thread) =================
        $syncHash.Run_Button.IsEnabled = $false
        $syncHash.Run_Progress.IsIndeterminate = $true
        $syncHash.Run_Progress.Visibility = 'Visible'
        $syncHash.MainTabs.SelectedIndex = 2   # Run Output tab (shows sign-in progress)
        # App-only = both an AppId and a cert thumbprint were supplied at launch.
        $appOnly = [bool]($syncHash.AppId -and $syncHash.CertificateThumbprint)
        $connectStatus = if ($appOnly) { "Connecting to Microsoft Graph (appid & certificate)..." } else { "Connecting to Microsoft Graph - complete sign-in in the browser..." }
        Set-ScubaAnalyzerStatus $connectStatus
        Write-ScubaAnalyzerLog "Connecting to Microsoft Graph ($env) for products '$($products -join ', ')'$(if ($appOnly) { " - using noninteractive appid ($($syncHash.AppId))" })..."
        # Force the UI to paint the status before the (blocking) sign-in / connect.
        $syncHash.Window.Dispatcher.Invoke([action] {}, [System.Windows.Threading.DispatcherPriority]::Render)

        # Connect on the UI thread. App-only cert auth is non-interactive; otherwise use
        # interactive auth with the delegated scopes resolved from the API catalog.
        try {
            # The baseline schema tells Get-ScubaAnalyzerScopes which Graph scopes each product needs.
            $baseline = Get-Content $syncHash.BaselineSchemaPath -Raw | ConvertFrom-Json
            if ($appOnly) {
                # Service-principal + certificate: no browser, no scopes to request.
                $ctx = Connect-ScubaAnalyzerGraph -M365Environment $env -AppId $syncHash.AppId -CertificateThumbprint $syncHash.CertificateThumbprint -Organization $syncHash.Organization
            } else {
                # Delegated: gather the minimal scope set for the selected products, then sign in.
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
        if ($syncHash.ConnectionText) {
            $connMode = if ($appOnly) { 'Connected (app-only)' } else { 'Connected' }
            $connWho  = if ($appOnly) { [string]$syncHash.AppId } elseif ($ctx.Account) { [string]$ctx.Account } else { [string]$ctx.ClientId }
            $syncHash.ConnectionText.Text = "${connMode}: $connWho ($env)"
            $syncHash.ConnectionText.Foreground = [System.Windows.Media.Brushes]::LightGreen
        }
        Set-ScubaAnalyzerStatus "Connected. Retrieving tenant configuration from Microsoft Graph..."
        # Paint the status before the (blocking) Graph read.
        $syncHash.Window.Dispatcher.Invoke([action] {}, [System.Windows.Threading.DispatcherPriority]::Render)

        # ===== PHASE B: read tenant data (still on the UI/sign-in thread) =============
        # Read tenant data on THIS (sign-in) thread, where the Graph session is valid,
        # using only Microsoft Graph auth + raw Graph API calls. Then validate on a
        # background runspace so the UI stays responsive.
        try {
            # Accumulate across all selected products into one tenant-data bag.
            $tenantData = @{ conditional_access_policies = @(); OrgDisplayName = $null; Organization = $null; TenantId = $null; DisplayNameLookup = @{} }
            foreach ($p in $products) {
                # Get-ScubaTenantGraphData issues the raw Graph calls the schema declares for $p.
                $d = Get-ScubaTenantGraphData -Product $p -BaselineSchema $baseline -ApiCatalogPath $syncHash.ApiCatalogPath -AnalyzerSchemaPath $syncHash.AnalyzerSchemaPath
                if (@($d.conditional_access_policies).Count -gt 0) { $tenantData.conditional_access_policies = $d.conditional_access_policies }
                if ($d.OrgDisplayName) { $tenantData.OrgDisplayName = $d.OrgDisplayName }
                if ($d.Organization)  { $tenantData.Organization  = $d.Organization }
                if ($d.TenantId)      { $tenantData.TenantId      = $d.TenantId }
                # Merge each product's id->name map so YAML comments can show friendly names.
                if ($d.DisplayNameLookup) { foreach ($k in @($d.DisplayNameLookup.Keys)) { $tenantData.DisplayNameLookup[$k] = $d.DisplayNameLookup[$k] } }
            }
            Write-ScubaAnalyzerLog "Retrieved $(@($tenantData.conditional_access_policies).Count) Conditional Access policy/policies."
            # Update the header tenant to the verified primary domain once it's known.
            if ($syncHash.TenantText) {
                $tenantLabel = if ($tenantData.Organization) { $tenantData.Organization }
                               elseif ($tenantData.OrgDisplayName) { $tenantData.OrgDisplayName }
                               elseif ($syncHash.Organization) { $syncHash.Organization } else { $null }
                if ($tenantLabel) { $syncHash.TenantText.Text = "Tenant: $tenantLabel" }
            }
        } catch {
            $syncHash.Run_Button.IsEnabled = $true
            $syncHash.Run_Progress.Visibility = 'Collapsed'; $syncHash.Run_Progress.IsIndeterminate = $false
            Set-ScubaAnalyzerStatus "Failed to read tenant configuration: $($_.Exception.Message)"
            Write-ScubaAnalyzerLog "Graph read failed: $($_.Exception.Message)"
            return
        }
        Set-ScubaAnalyzerStatus "Analyzing $(@($tenantData.conditional_access_policies).Count) policies against the baselines..."

        # ===== PHASE C: validate on a background runspace (no Graph calls here) =======
        # Same mailbox + DispatcherTimer pattern as Start-ScubaAnalyzerAnalysis.
        # STEP 1: the mailbox.
        $scanSync = [hashtable]::Synchronized(@{ IsComplete = $false; Result = $null; Error = $null })
        $syncHash.ScanSync = $scanSync
        # STEP 2: worker runspace. tenantData (already fetched from Graph) is passed in as
        # plain data, so the worker never needs a Graph session of its own.
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
        # Worker: import engine, validate the fetched policies, record outcome in the mailbox.
        [void]$bgPS.AddScript({
            try {
                Import-Module $enginePath -Force -ErrorAction Stop
                $scanSync.Result = Invoke-ScubaTenantScan -Product $product -M365Environment $env -TenantData $tenantData -BaselineSchemaPath $baselineSchemaPath -AnalyzerSchemaPath $analyzerSchemaPath -ConfigSchemaPath $configSchemaPath
            } catch { $scanSync.Error = $_.Exception.Message } finally { $scanSync.IsComplete = $true }
        })
        $syncHash.ScanBgPS = $bgPS
        $syncHash.ScanBgHandle = $bgPS.BeginInvoke()
        $syncHash.ScanBgRunspace = $bg

        # STEP 3: poll from the UI thread; marshal the result back when the worker finishes.
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(250)
        $timer.Add_Tick({
            if (-not $syncHash.ScanSync.IsComplete) { return }   # wait for the worker
            $syncHash.ScanTimer.Stop()
            # Drain + dispose the worker (guarded so one failure can't abort the others).
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
            # Success: publish, repaint, and jump back to the Findings tab.
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
            Set-ScubaAnalyzerStatus "ScubaConfig app module not found."
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
    <#
    .SYNOPSIS
    Prompts for a path and saves the aggregate configuration YAML (FullYaml_TextBox) to
    disk as UTF-8. No-op with a status message if nothing has been generated yet.
    #>
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
      9. "Open ConfigApp" button - hands the generated YAML to Start-ScubaAnalyzerConfigApp.
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
                $null = $eventSender   # sender unused; the routed event args carry the clicked button
                try {
                    $btn = ($e.Source -as [System.Windows.Controls.Button])
                    if (-not $btn) { $btn = ($e.OriginalSource -as [System.Windows.Controls.Button]) }
                    if ($btn -and $btn.Tag) { Select-ScubaAnalyzerPolicy -PolicyId ([string]$btn.Tag) }
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
