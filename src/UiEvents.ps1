<#
.SYNOPSIS
    Wires window events to the behaviour functions.
#>

function Register-InputEvents {
    <#
    .SYNOPSIS
        Wires the language selector, the province dropdown, the add buttons and the Enter key.
    #>
    $ui = $script:ui
    $ui.langBox.Add_SelectedIndexChanged({ $script:State.Lang = @('es', 'en')[$script:ui.langBox.SelectedIndex]; Set-UiLanguage })
    $ui.tProv.Add_SelectedIndexChanged({ Update-MunicipalityList }); $ui.tProv.Add_Leave({ Update-MunicipalityList })
    $ui.addPP.Add_Click({ Add-ParcelRow }); $ui.addRC.Add_Click({ Add-ReferenceRow })
    foreach ($field in $ui.tProv, $ui.tMun, $ui.tPol, $ui.tPar) { $field.Tag = $ui.addPP; $field.Add_KeyDown({ param($s, $e) Invoke-EnterKey $s $e }) }
    $ui.tRC.Tag = $ui.addRC; $ui.tRC.Add_KeyDown({ param($s, $e) Invoke-EnterKey $s $e })
}

function Register-ListEvents {
    <#
    .SYNOPSIS
        Wires the list: column fitting, retry on selection, cell copy, Delete and Ctrl+C keys, and the edit and remove buttons.
    #>
    $ui = $script:ui; $list = $ui.lv
    $list.Add_SizeChanged({ Resize-ListColumns })
    $list.Add_SelectedIndexChanged({
            $item = Get-SelectedRow
            if ($item -and ((Test-ErrorRow $item) -or -not $item.SubItems[4].Text)) { Update-Row $item }
        })
    $list.Add_MouseDown({ param($s, $e) $script:State.ClickedCell = $s.HitTest($e.X, $e.Y).SubItem })
    $list.Add_MouseDoubleClick({ if ($script:State.ClickedCell) { Copy-TextToClipboard $script:State.ClickedCell.Text } })
    $list.Add_KeyDown({
            param($s, $e)
            if ($e.KeyCode -eq 'Delete') { Remove-SelectedRows }
            elseif ($e.Control -and $e.KeyCode -eq 'C') { $e.SuppressKeyPress = $true; Copy-TextToClipboard (Get-ListCopyText $s) }
        })
    $ui.remove.Add_Click({ Remove-SelectedRows }); $ui.edit.Add_Click({ Edit-SelectedRow })
}

function Register-ActionEvents {
    <#
    .SYNOPSIS
        Wires the folder picker, the download button and the guard that blocks closing mid-download.
    #>
    $ui = $script:ui
    $ui.change.Add_Click({
            $dialog = New-Object Windows.Forms.FolderBrowserDialog
            $dialog.SelectedPath = $script:ui.folder.Text
            if ($dialog.ShowDialog() -eq 'OK') { $script:ui.folder.Text = $dialog.SelectedPath }
        })
    $ui.download.Add_Click({ Start-UiDownload })
    $ui.form.KeyPreview = $true
    $ui.form.Add_KeyDown({ param($s, $e) if ($e.Control -and $e.KeyCode -eq 'T') { $e.SuppressKeyPress = $true; Import-LocalTestData } })
    $ui.form.Add_FormClosing({ param($s, $e) if ($script:State.Busy) { $e.Cancel = $true; Show-Warning (Get-Text).busyMsg } })
}
