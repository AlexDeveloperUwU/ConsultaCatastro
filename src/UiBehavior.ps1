<#
.SYNOPSIS
    Window behaviour: language, column fitting, clipboard, Enter key and the download run.
#>

function Show-Warning([string]$Message) {
    <#
    .SYNOPSIS
        Shows a modal warning box with the application title.
    #>
    [void][Windows.Forms.MessageBox]::Show($Message, (Get-Text).title, 'OK', 'Warning')
}

function Set-UiLanguage {
    <#
    .SYNOPSIS
        Applies the texts of the selected language to every label, button, tab and column header.
    #>
    $ui = $script:ui; $text = Get-Text
    $ui.form.Text = $text.title; $ui.langLbl.Text = $text.lang
    $ui.tabPP.Text = $text.tabPP; $ui.tabRC.Text = $text.tabRC
    $ui.lProv.Text = $text.prov; $ui.lMun.Text = $text.mun; $ui.lPol.Text = $text.pol; $ui.lPar.Text = $text.par; $ui.lRC.Text = $text.rc
    $ui.addPP.Text = $text.add; $ui.addRC.Text = $text.add; $ui.remove.Text = $text.remove; $ui.edit.Text = $text.edit
    $ui.folderLbl.Text = $text.folder; $ui.change.Text = $text.change; $ui.download.Text = $text.download
    $ui.listLbl.Text = $text.list
    $ui.status.Text = if ($script:State.Offline) { $text.offline } else { $text.ready }
    0..4 | ForEach-Object { $ui.lv.Columns[$_].Text = $text.headers[$_] }
}

function Resize-ListColumns {
    <#
    .SYNOPSIS
        Spreads the list columns over the full list width; the last column takes the remainder.
    #>
    $list = $script:ui.lv
    $width = $list.ClientSize.Width - 2
    $shares = 0.22, 0.24, 0.10, 0.10
    $used = 0
    for ($i = 0; $i -lt $shares.Count; $i++) {
        $list.Columns[$i].Width = [int]($width * $shares[$i])
        $used += $list.Columns[$i].Width
    }
    $list.Columns[4].Width = [Math]::Max(60, $width - $used)
}

function Copy-TextToClipboard([string]$Text) {
    <#
    .SYNOPSIS
        Copies text to the clipboard and says so in the status bar. Silently ignores a busy clipboard.
    #>
    if (-not $Text) { return }
    try {
        [Windows.Forms.Clipboard]::SetText($Text)
        $script:ui.status.Text = (Get-Text).copied -f $Text
    } catch { return }
}

function Get-ListCopyText($List) {
    <#
    .SYNOPSIS
        Text for Ctrl+C: the last clicked cell, or the selected rows as tab-separated lines.
    #>
    $cell = $script:State.ClickedCell
    if ($cell -and $cell.Text) { return $cell.Text }
    (@($List.SelectedItems) | ForEach-Object { ($_.SubItems | ForEach-Object { $_.Text }) -join "`t" }) -join "`r`n"
}

function Invoke-EnterKey($Sender, $KeyArgs) {
    <#
    .SYNOPSIS
        Enter key on a form field: adds the row when the form is complete, otherwise moves to the next field without any message.
    #>
    if ($KeyArgs.KeyCode -ne 'Return') { return }
    $KeyArgs.SuppressKeyPress = $true
    $ui = $script:ui
    if ($Sender -eq $ui.tRC) {
        if ($Sender.Text.Trim().Length -eq $script:Config.ReferenceLength) { $Sender.Tag.PerformClick() }
        return
    }
    $complete = $ui.tProv.Text.Trim() -and $ui.tMun.Text.Trim() -and $ui.tPol.Text.Trim() -and $ui.tPar.Text.Trim()
    if ($complete) { $Sender.Tag.PerformClick() } else { [void]$Sender.Parent.SelectNextControl($Sender, $true, $true, $false, $false) }
}

function Set-Busy([bool]$Busy) {
    <#
    .SYNOPSIS
        Locks or unlocks the window while a download runs; the close button is also blocked while busy.
    #>
    $script:State.Busy = $Busy
    $script:ui.form.Enabled = -not $Busy
}

function Update-Progress([int]$Completed, [int]$Total, [string]$Stage) {
    <#
    .SYNOPSIS
        Shows the download progress and lets the window repaint.
    .PARAMETER Completed
        Requests already finished; the bar shows this value.
    .PARAMETER Stage
        item while requests run, finish while the summary and pages are written.
    .NOTES
        Setting the bar one step ahead and back skips the slow Windows fill animation, so it never lags behind the text.
    #>
    $text = Get-Text; $bar = $script:ui.bar
    $bar.Value = [Math]::Min($Completed + 1, $bar.Maximum)
    $bar.Value = $Completed
    $script:ui.status.Text = if ($Stage -eq 'finish') { $text.finishing } else { $text.working -f [Math]::Min($Completed + 1, $Total), $Total }
    [Windows.Forms.Application]::DoEvents()
}

function Hide-ConsoleWindow {
    <#
    .SYNOPSIS
        Hides the PowerShell console so only the application window shows.
    .NOTES
        Does nothing when the console is shared with other programs, such as a terminal the script was run from.
    #>
    if (-not ('ConsoleWindow' -as [type])) {
        Add-Type -Name ConsoleWindow -Namespace '' -MemberDefinition @'
[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
[DllImport("kernel32.dll")] public static extern uint GetConsoleProcessList(uint[] processList, uint processCount);
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr window, int command);
'@
    }
    $handle = [ConsoleWindow]::GetConsoleWindow()
    if ($handle -eq [IntPtr]::Zero) { return }
    if ([ConsoleWindow]::GetConsoleProcessList((New-Object uint32[] 8), 8) -le 1) { [void][ConsoleWindow]::ShowWindow($handle, 0) }
}

function Start-UiDownload {
    <#
    .SYNOPSIS
        Runs the download for the whole list, then reports the outcome and offers to open the results folder.
    #>
    $ui = $script:ui; $text = Get-Text
    if ($ui.lv.Items.Count -eq 0) { Show-Warning $text.errEmpty; return }
    $folder = $ui.folder.Text.Trim()
    if (-not (Initialize-Folder $folder)) { Show-Warning $text.errFolder; return }
    $requests = @($ui.lv.Items | ForEach-Object { $_.Tag })
    $ui.bar.Maximum = $requests.Count; $ui.bar.Value = 0
    $result = $null
    Set-Busy $true
    try { $result = Invoke-Download $requests $folder $text { param($completed, $total, $stage) Update-Progress $completed $total $stage } }
    catch { Show-Warning $_.Exception.Message }
    finally { Set-Busy $false }
    if (-not $result) { return }
    $summary = $text.done -f $result.Ok, $result.Bad
    $ui.bar.Value = $requests.Count; $ui.status.Text = $summary
    $answer = [Windows.Forms.MessageBox]::Show("$summary`n`n$($text.openq)", $text.title, 'YesNo', 'Information')
    if ($answer -eq 'Yes') { Start-Process explorer.exe $result.Dir }
}
