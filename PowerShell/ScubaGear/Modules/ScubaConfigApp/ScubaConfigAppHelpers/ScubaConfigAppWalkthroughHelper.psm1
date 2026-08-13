function Convert-MarkdownInline {
    # BasePath is used inside the [regex]::Replace closures below; the analyzer can't see that.
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'BasePath')]
    param(
        [string]$Text,
        [string]$BasePath
    )

    $result = [System.Security.SecurityElement]::Escape($Text)

    $result = [regex]::Replace($result, '!(\[[^\]]*\])\(([^)]+)\)', {
        param($match)
        $alt = $match.Groups[1].Value.Trim('[', ']')
        $src = $match.Groups[2].Value.Trim()
        if ($src -and -not ($src -match '^(https?:|data:|#)')) {
            $resolved = if ([System.IO.Path]::IsPathRooted($src)) { $src } else { [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $BasePath) $src)) }
            $src = 'file:///' + ($resolved -replace '\\', '/')
        }
        $safeAlt = [System.Security.SecurityElement]::Escape($alt)
        return '<img src="' + $src + '" alt="' + $safeAlt + '" style="max-width:100%;height:auto;border-radius:6px;margin:10px 0;" />'
    })

    $result = [regex]::Replace($result, '\[([^\]]+)\]\(([^)]+)\)', {
        param($match)
        $label = $match.Groups[1].Value
        $href = $match.Groups[2].Value
        if ($href -and -not ($href -match '^(https?:|mailto:|#)')) {
            $resolved = if ([System.IO.Path]::IsPathRooted($href)) { $href } else { [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $BasePath) $href)) }
            $href = 'file:///' + ($resolved -replace '\\', '/')
        }
        return '<a href="' + $href + '" style="color:#0b57d0;text-decoration:underline;">' + $label + '</a>'
    })

    $result = [regex]::Replace($result, '`([^`]+)`', {
        param($match)
        $inlineCode = [System.Security.SecurityElement]::Escape($match.Groups[1].Value)
        return '<code style="font-family:Consolas, ''Courier New'', monospace;background:#f3f4f6;padding:2px 6px;border-radius:4px;">' + $inlineCode + '</code>'
    })

    $result = [regex]::Replace($result, '\*\*([^*]+)\*\*', '<strong>$1</strong>')
    $result = [regex]::Replace($result, '(?<!\*)\*([^*]+)\*(?!\*)', '<em>$1</em>')
    $result = [regex]::Replace($result, '^(\s*)--\s*$', '<hr style="border:none;border-top:1px solid #d1d5db;margin:16px 0;" />', [System.Text.RegularExpressions.RegexOptions]::Multiline)

    return $result
}

function Convert-MarkdownToHtml {
    param(
        [string]$Markdown,
        [string]$BasePath
    )

    $lines = $Markdown -split "`r?`n"
    $html = New-Object System.Collections.Generic.List[string]
    $i = 0

    while ($i -lt $lines.Length) {
        $line = $lines[$i]

        if ($line -match '^\s*$') {
            $i++
            continue
        }

        if ($line -match '^\s*>') {
            $quoteLines = New-Object System.Collections.Generic.List[string]
            while ($i -lt $lines.Length -and $lines[$i] -match '^\s*>') {
                $quoteLines.Add(($lines[$i] -replace '^\s*>\s*', '').Trim())
                $i++
            }

            $quoteHtmlParts = New-Object System.Collections.Generic.List[string]
            $codeContent = New-Object System.Collections.Generic.List[string]
            $insideCodeBlock = $false

            foreach ($quoteLine in $quoteLines) {
                if ($quoteLine -match '^```') {
                    if ($insideCodeBlock) {
                        $safeCode = [System.Security.SecurityElement]::Escape(($codeContent -join "`n"))
                        $quoteHtmlParts.Add('<pre style="background:#111827;color:#f3f4f6;padding:12px 14px;border-radius:8px;overflow:auto;margin:12px 0;font-family:Consolas, ''Courier New'', monospace;"><code>' + $safeCode + '</code></pre>')
                        $codeContent.Clear()
                        $insideCodeBlock = $false
                    }
                    else {
                        $insideCodeBlock = $true
                    }
                    continue
                }

                if ($insideCodeBlock) {
                    $codeContent.Add($quoteLine)
                    continue
                }

                if (-not [string]::IsNullOrWhiteSpace($quoteLine)) {
                    $quoteHtmlParts.Add((Convert-MarkdownInline -Text $quoteLine -BasePath $BasePath))
                }
            }

            if ($codeContent.Count -gt 0) {
                $safeCode = [System.Security.SecurityElement]::Escape(($codeContent -join "`n"))
                $quoteHtmlParts.Add('<pre style="background:#111827;color:#f3f4f6;padding:12px 14px;border-radius:8px;overflow:auto;margin:12px 0;font-family:Consolas, ''Courier New'', monospace;"><code>' + $safeCode + '</code></pre>')
            }

            if ($quoteHtmlParts.Count -gt 0) {
                $html.Add('<blockquote style="margin:14px 0;padding:10px 14px;border-left:4px solid #94a3b8;background:#f8fafc;color:#374151;">' + ($quoteHtmlParts -join '<br />') + '</blockquote>')
                continue
            }
        }

        if ($line -match '^\s*```') {
            $codeLines = New-Object System.Collections.Generic.List[string]
            $i++
            while ($i -lt $lines.Length -and $lines[$i] -notmatch '^\s*```') {
                $codeLines.Add($lines[$i])
                $i++
            }
            $codeText = ($codeLines -join "`n")
            $safeCode = [System.Security.SecurityElement]::Escape($codeText)
            $html.Add('<pre style="background:#111827;color:#f3f4f6;padding:12px 14px;border-radius:8px;overflow:auto;margin:12px 0;font-family:Consolas, ''Courier New'', monospace;"><code>' + $safeCode + '</code></pre>')
            if ($i -lt $lines.Length) { $i++ }
            continue
        }

        if ($line -match '^\s*#{1,6}\s+') {
            $level = [regex]::Match($line, '^\s*(#+)').Groups[1].Value.Length
            $headingText = ($line -replace '^\s*#{1,6}\s*', '').Trim()
            $html.Add('<h' + $level + ' style="margin:16px 0 8px 0;color:#1f2937;font-weight:700;">' + (Convert-MarkdownInline -Text $headingText -BasePath $BasePath) + '</h' + $level + '>')
            $i++
            continue
        }

        if ($line -match '^\s*\|.*\|\s*$') {
            $tableLines = New-Object System.Collections.Generic.List[string]
            $tableLines.Add($line)
            $i++
            while ($i -lt $lines.Length -and $lines[$i] -match '^\s*\|.*\|\s*$') {
                $tableLines.Add($lines[$i])
                $i++
            }

            if ($tableLines.Count -ge 2) {
                $headerLine = $tableLines[0]
                $separatorLine = $tableLines[1]
                if ($separatorLine -match '^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?\s*$') {
                    $rows = New-Object System.Collections.Generic.List[string]
                    $headerCells = $headerLine.Split('|') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
                    $rows.Add('<tr>' + (($headerCells | ForEach-Object { '<th style="padding:8px 10px;border:1px solid #d1d5db;background:#f3f4f6;text-align:left;">' + (Convert-MarkdownInline -Text $_ -BasePath $BasePath) + '</th>' }) -join '') + '</tr>')

                    for ($r = 2; $r -lt $tableLines.Count; $r++) {
                        $cells = $tableLines[$r].Split('|') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
                        if ($cells.Count -gt 0) {
                            $rows.Add('<tr>' + (($cells | ForEach-Object { '<td style="padding:8px 10px;border:1px solid #e5e7eb;vertical-align:top;">' + (Convert-MarkdownInline -Text $_ -BasePath $BasePath) + '</td>' }) -join '') + '</tr>')
                        }
                    }

                    $html.Add('<table style="border-collapse:collapse;width:100%;margin:12px 0;border:1px solid #e5e7eb;">' + ($rows -join '') + '</table>')
                    continue
                }
            }

            $html.Add('<p>' + (Convert-MarkdownInline -Text ($tableLines -join ' ') -BasePath $BasePath) + '</p>')
            continue
        }

        if ($line -match '^\s*[-*+]\s+') {
            $listItems = New-Object System.Collections.Generic.List[string]
            while ($i -lt $lines.Length -and $lines[$i] -match '^\s*[-*+]\s+') {
                $itemText = ($lines[$i] -replace '^\s*[-*+]\s*', '').Trim()
                $listItems.Add('<li style="margin:4px 0;">' + (Convert-MarkdownInline -Text $itemText -BasePath $BasePath) + '</li>')
                $i++
            }
            $html.Add('<ul style="margin:10px 0 10px 18px;padding-left:18px;">' + ($listItems -join '') + '</ul>')
            continue
        }

        if ($line -match '^\s*>') {
            $quoteLines = New-Object System.Collections.Generic.List[string]
            while ($i -lt $lines.Length -and $lines[$i] -match '^\s*>') {
                $quoteLines.Add(($lines[$i] -replace '^\s*>\s*', '').Trim())
                $i++
            }
            $quoteText = ($quoteLines -join '<br />')
            $html.Add('<blockquote style="margin:14px 0;padding:10px 14px;border-left:4px solid #94a3b8;background:#f8fafc;color:#374151;">' + (Convert-MarkdownInline -Text $quoteText -BasePath $BasePath) + '</blockquote>')
            continue
        }

        $paragraphLines = New-Object System.Collections.Generic.List[string]
        while ($i -lt $lines.Length -and $lines[$i] -and $lines[$i] -notmatch '^\s*$' -and $lines[$i] -notmatch '^\s*#{1,6}\s+' -and $lines[$i] -notmatch '^\s*[-*+]\s+' -and $lines[$i] -notmatch '^\s*>\s*' -and $lines[$i] -notmatch '^\s*\|.*\|\s*$' -and $lines[$i] -notmatch '^\s*```') {
            $paragraphLines.Add($lines[$i].Trim())
            $i++
        }

        if ($paragraphLines.Count -gt 0) {
            $paragraphText = ($paragraphLines -join ' ')
            $html.Add('<p style="margin:10px 0;line-height:1.55;color:#1f2937;">' + (Convert-MarkdownInline -Text $paragraphText -BasePath $BasePath) + '</p>')
            continue
        }

        $i++
    }

    $style = @'
<style>
body {
  font-family: "Segoe UI", Arial, sans-serif;
  color: #1f2937;
  background: #f8fafc;
  margin: 0;
  padding: 18px 18px 28px 18px;
}

p, li, td, th, blockquote {
  font-size: 14px;
  line-height: 1.5;
}

a { color: #0b57d0; }
code { font-family: Consolas, "Courier New", monospace; }
pre code {
  white-space: pre-wrap;
  word-break: break-word;
  font-size: 13px;
}

blockquote br {
  content: "";
  display: block;
  margin: 4px 0;
}
</style>
'@

    return '<html><head>' + $style + '</head><body>' + ($html -join "`n") + '</body></html>'
}

Function Show-ScubaConfigWalkthroughWindow {
    <#
    .SYNOPSIS
    Opens the ScubaConfigApp walkthrough guide in a separate WPF window.
    #>

    if ($syncHash.WalkthroughWindow -and -not $syncHash.WalkthroughWindow.IsClosed) {
        $syncHash.WalkthroughWindow.Activate()
        return
    }

    try {
        $walkthroughPath = $syncHash.WalkthroughPath
        if (-not $walkthroughPath -or -not (Test-Path $walkthroughPath)) {
            $syncHash.ShowMessageBox.Invoke("The walkthrough file could not be found. Update the WalkthroughMarkdownPath setting in the app control file.", "Help / Walkthrough", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            return
        }

        $rawContent = Get-Content -LiteralPath $walkthroughPath -Raw
        if ([string]::IsNullOrWhiteSpace($rawContent)) {
            $rawContent = "# Walkthrough content unavailable."
        }

        $htmlContent = Convert-MarkdownToHtml -Markdown $rawContent -BasePath $walkthroughPath

        $walkthroughXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="ScubaConfigApp Help / Walkthrough"
        Height="650"
        Width="920"
        MinHeight="400"
        MinWidth="600"
        WindowStartupLocation="CenterOwner"
        Background="#F6FBFE"
        Foreground="#333333"
        ShowInTaskbar="True"
        Topmost="False">

    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Orientation="Vertical" Margin="0,0,0,12">
            <TextBlock Text="Help / Walkthrough" FontSize="18" FontWeight="Bold" Margin="0,0,0,4"/>
            <TextBlock Text="ScubaConfigApp setup and usage guide" FontSize="12" Foreground="Gray" TextWrapping="Wrap"/>
        </StackPanel>

        <Border x:Name="WalkthroughHost" Grid.Row="1" BorderBrush="#D0D5E0" BorderThickness="1" CornerRadius="4" Background="White"/>

        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,16,0,0">
            <Button x:Name="OpenWalkthrough_Button" Content="View on GitHub" Padding="12,6" Margin="0,0,12,0"/>
            <Button x:Name="WalkthroughClose_Button" Content="Close" Padding="12,6" IsCancel="True"/>
        </StackPanel>
    </Grid>
</Window>
"@

        $walkthroughWindow = [Windows.Markup.XamlReader]::Parse($walkthroughXaml)
        $syncHash.WalkthroughWindow = $walkthroughWindow
        $syncHash.WalkthroughWindow.Icon = $syncHash.ImgPath

        $walkthroughHost = $walkthroughWindow.FindName("WalkthroughHost")
        $browser = New-Object System.Windows.Controls.WebBrowser
        $browser.NavigateToString($htmlContent)
        $walkthroughHost.Child = $browser

        $openButton = $walkthroughWindow.FindName("OpenWalkthrough_Button")
        $closeButton = $walkthroughWindow.FindName("WalkthroughClose_Button")

        $openButton.Add_Click({
            try {
                if ($syncHash.WalkthroughUrl) {
                    # http/https resolves to the default browser (GitHub renders the markdown), not an editor.
                    Start-Process $syncHash.WalkthroughUrl
                }
                elseif ($syncHash.WalkthroughPath -and (Test-Path $syncHash.WalkthroughPath)) {
                    Start-Process -FilePath $syncHash.WalkthroughPath
                }
            }
            catch {
                $syncHash.ShowMessageBox.Invoke("Could not open the walkthrough: $($_.Exception.Message)", "Help / Walkthrough", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            }
        }.GetNewClosure())

        $closeButton.Add_Click({
            $syncHash.WalkthroughWindow.Close()
        })

        $walkthroughWindow.Add_Closing({
            $syncHash.WalkthroughWindow = $null
        })

        if ($syncHash.Window) {
            $walkthroughWindow.Owner = $syncHash.Window
        }

        $walkthroughWindow.Show()
        $walkthroughWindow.Activate()
        Write-DebugOutput -Message "Walkthrough window opened successfully: $walkthroughPath" -Source $MyInvocation.MyCommand -Level "Info"
    }
    catch {
        Write-DebugOutput -Message "Error creating walkthrough window: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
        $syncHash.ShowMessageBox.Invoke("Failed to open the walkthrough window: $($_.Exception.Message)", "Help / Walkthrough", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
}
