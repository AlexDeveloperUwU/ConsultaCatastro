<#
.SYNOPSIS
    Property list behaviour: adding, validating, editing and removing rows, and the province and municipality lists.
#>

function Get-SelectedRow {
    <#
    .SYNOPSIS
        Returns the first selected list row, or nothing.
    #>
    $script:ui.lv.SelectedItems | Select-Object -First 1
}

function Test-ErrorRow($Item) {
    <#
    .SYNOPSIS
        Tells whether a list row is currently shown as an error.
    #>
    $Item.ForeColor -eq $script:Config.ErrorColor
}

function Test-DuplicateKey([string]$Key) {
    <#
    .SYNOPSIS
        Tells whether the list already holds a row with the same normalized key.
    #>
    [bool]($script:ui.lv.Items | Where-Object { $_.Tag.Key -eq $Key })
}

function Remove-DuplicateRow($Item) {
    <#
    .SYNOPSIS
        Removes the row when another valid row already resolved to the same cadastral reference.
    .OUTPUTS
        System.Boolean. True when the row was removed.
    #>
    $reference = $Item.SubItems[4].Text
    if (-not $reference -or (Test-ErrorRow $Item)) { return $false }
    $twin = $script:ui.lv.Items | Where-Object { $_ -ne $Item -and $_.SubItems[4].Text -eq $reference -and -not (Test-ErrorRow $_) }
    if (-not $twin) { return $false }
    $script:ui.lv.Items.Remove($Item)
    $true
}

function Update-Row($Item) {
    <#
    .SYNOPSIS
        Looks the row up in the Catastro and shows the reference, or a red error message.
    .NOTES
        Rows added by reference also get their province, municipality, polygon and parcel filled in.
    #>
    $previous = [Windows.Forms.Cursor]::Current
    [Windows.Forms.Cursor]::Current = [Windows.Forms.Cursors]::WaitCursor
    try { $lookup = Find-Properties $Item.Tag } finally { [Windows.Forms.Cursor]::Current = $previous }
    if (-not $lookup.Succeeded) {
        $Item.SubItems[4].Text = Format-LookupError $lookup (Get-Text)
        $Item.ForeColor = $script:Config.ErrorColor
        return
    }
    $Item.ForeColor = [Drawing.SystemColors]::WindowText
    $Item.SubItems[4].Text = $lookup.Props.RC -join ', '
    if ($Item.Tag.RC) {
        $first = $lookup.Props[0]
        $Item.Text = $first.Prov
        $Item.SubItems[1].Text = $first.Mun; $Item.SubItems[2].Text = $first.Pol; $Item.SubItems[3].Text = $first.Par
    }
}

function Add-ListRow([string[]]$Cells, [hashtable]$Request) {
    <#
    .SYNOPSIS
        Appends a row to the property list; the request is kept as the row's Tag.
    #>
    $item = New-Object Windows.Forms.ListViewItem($Cells[0])
    $Cells[1..($Cells.Count - 1)] | ForEach-Object { $null = $item.SubItems.Add($_) }
    $item.Tag = $Request
    $null = $script:ui.lv.Items.Add($item)
    $item
}

function Complete-RowAddition($Item) {
    <#
    .SYNOPSIS
        Validates a just-added row against the Catastro and drops it if it turns out to be a duplicate.
    #>
    Update-Row $Item
    if (Remove-DuplicateRow $Item) { Show-Warning (Get-Text).dup }
}

function Add-ParcelRow {
    <#
    .SYNOPSIS
        Adds the by-parcel form content to the list, after validating it.
    #>
    $ui = $script:ui; $text = Get-Text
    $province = $ui.tProv.Text.Trim(); $municipality = $ui.tMun.Text.Trim(); $polygon = $ui.tPol.Text.Trim(); $parcel = $ui.tPar.Text.Trim()
    if (-not (Test-ParcelFields $province $municipality $polygon $parcel)) { Show-Warning $text.errPP; return }
    $request = New-ParcelRequest $province $municipality $polygon $parcel
    if (Test-DuplicateKey $request.Key) { Show-Warning $text.dup; return }
    $item = Add-ListRow @($province.ToUpper(), $municipality.ToUpper(), $polygon, $parcel, '') $request
    $ui.tPol.Clear(); $ui.tPar.Clear(); [void]$ui.tPol.Focus()
    Complete-RowAddition $item
}

function Add-ReferenceRow {
    <#
    .SYNOPSIS
        Adds the cadastral reference box content to the list, after validating it.
    #>
    $ui = $script:ui; $text = Get-Text
    $reference = $ui.tRC.Text.Trim()
    if (-not (Test-ReferenceFormat $reference)) { Show-Warning $text.errRC; return }
    $request = New-ReferenceRequest $reference
    if (Test-DuplicateKey $request.Key) { Show-Warning $text.dup; return }
    $item = Add-ListRow @('', '', '', '', $reference) $request
    $ui.tRC.Clear(); [void]$ui.tRC.Focus()
    Complete-RowAddition $item
}

function Import-LocalTestData {
    <#
    .SYNOPSIS
        Developer shortcut (Ctrl+T): fills the list from test-properties.local.txt next to the script.
    .DESCRIPTION
        One parcel per line as Province;Municipality;Polygon;Parcel. The file is git-ignored and does nothing when absent.
    #>
    $path = Join-Path $script:Config.RootDir 'test-properties.local.txt'
    if (-not (Test-Path $path)) { return }
    foreach ($line in Get-Content $path -Encoding UTF8) {
        $field = @($line.Split(';') | ForEach-Object { $_.Trim() })
        if ($field.Count -lt 4 -or -not (Test-ParcelFields $field[0] $field[1] $field[2] $field[3])) { continue }
        $request = New-ParcelRequest $field[0] $field[1] $field[2] $field[3]
        if (Test-DuplicateKey $request.Key) { continue }
        Complete-RowAddition (Add-ListRow @($field[0].ToUpper(), $field[1].ToUpper(), $field[2], $field[3], '') $request)
        [Windows.Forms.Application]::DoEvents()
    }
}

function Remove-SelectedRows {
    <#
    .SYNOPSIS
        Removes every selected row from the list.
    #>
    $script:State.ClickedCell = $null
    foreach ($item in @($script:ui.lv.SelectedItems)) { $script:ui.lv.Items.Remove($item) }
}

function Edit-SelectedRow {
    <#
    .SYNOPSIS
        Moves the selected row back into its form so it can be corrected and added again.
    #>
    $ui = $script:ui; $item = Get-SelectedRow
    if (-not $item) { return }
    $request = $item.Tag
    if ($request.RC) {
        $ui.tabs.SelectedTab = $ui.tabRC
        $ui.tRC.Text = $request.RC; [void]$ui.tRC.Focus()
    } else {
        $ui.tabs.SelectedTab = $ui.tabPP
        $ui.tProv.Text = $request.Prov
        Update-MunicipalityList
        $ui.tMun.Text = $request.Mun; $ui.tPol.Text = $request.Pol; $ui.tPar.Text = $request.Par; [void]$ui.tPol.Focus()
    }
    $ui.lv.Items.Remove($item)
}

function Update-MunicipalityList {
    <#
    .SYNOPSIS
        Fills the municipality box with the municipalities of the chosen province, only when the province changed.
    #>
    $ui = $script:ui
    if ($ui.tProv.Text -eq $script:State.MunicipalitiesFor) { return }
    $script:State.MunicipalitiesFor = $ui.tProv.Text
    $ui.tMun.Items.Clear(); $ui.tMun.Text = ''
    try { $null = $ui.tMun.Items.AddRange((Get-Municipalities $ui.tProv.Text)) } catch { return }
}

function Initialize-ProvinceList {
    <#
    .SYNOPSIS
        Loads the province box and records whether the Catastro could be reached.
    #>
    try { $null = $script:ui.tProv.Items.AddRange((Get-Provinces)) } catch { return }
    finally { $script:State.Offline = ($script:ui.tProv.Items.Count -eq 0) }
}
