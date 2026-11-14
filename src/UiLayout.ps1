<#
.SYNOPSIS
    Window construction: controls, layout and anchors.
#>

function New-UiControl([string]$Type, [int]$X, [int]$Y, [int]$Width, [int]$Height, $Parent) {
    <#
    .SYNOPSIS
        Creates a WinForms control at the given bounds and adds it to its parent.
    #>
    $control = New-Object "Windows.Forms.$Type"
    $control.SetBounds($X, $Y, $Width, $Height)
    if ($Parent) { $Parent.Controls.Add($control) }
    $control
}

function New-LanguageSelector {
    <#
    .SYNOPSIS
        Creates the language label and dropdown in the top-right corner.
    #>
    $ui = $script:ui
    $ui.langLbl = New-UiControl Label 540 14 80 24 $ui.form
    $ui.langBox = New-UiControl ComboBox 625 10 120 28 $ui.form
    $ui.langBox.DropDownStyle = 'DropDownList'
    $null = $ui.langBox.Items.AddRange(@('Español', 'English'))
    $ui.langBox.SelectedIndex = [int]($script:State.Lang -eq 'en')
}

function New-ParcelTab {
    <#
    .SYNOPSIS
        Creates the by-parcel tab: province and municipality dropdowns, polygon and parcel boxes, and the add button.
    #>
    $ui = $script:ui; $tab = $ui.tabPP
    $ui.lProv = New-UiControl Label 10 12 200 22 $tab; $ui.lMun = New-UiControl Label 250 12 200 22 $tab
    $ui.lPol = New-UiControl Label 490 12 100 22 $tab; $ui.lPar = New-UiControl Label 600 12 100 22 $tab
    $ui.tProv = New-UiControl ComboBox 10 38 230 28 $tab; $ui.tMun = New-UiControl ComboBox 250 38 230 28 $tab
    foreach ($box in $ui.tProv, $ui.tMun) { $box.AutoCompleteMode = 'SuggestAppend'; $box.AutoCompleteSource = 'ListItems' }
    $ui.tPol = New-UiControl TextBox 490 38 100 28 $tab; $ui.tPar = New-UiControl TextBox 600 38 100 28 $tab
    $ui.addPP = New-UiControl Button 10 78 160 34 $tab
    Initialize-ProvinceList
}

function New-ReferenceTab {
    <#
    .SYNOPSIS
        Creates the cadastral reference tab: one 20-character box and the add button.
    #>
    $ui = $script:ui; $tab = $ui.tabRC
    $ui.lRC = New-UiControl Label 10 12 400 22 $tab
    $ui.tRC = New-UiControl TextBox 10 38 400 28 $tab
    $ui.tRC.MaxLength = $script:Config.ReferenceLength; $ui.tRC.CharacterCasing = 'Upper'
    $ui.addRC = New-UiControl Button 10 78 160 34 $tab
}

function New-ListSection {
    <#
    .SYNOPSIS
        Creates the property list with its remove and edit buttons.
    #>
    $ui = $script:ui
    $ui.listLbl = New-UiControl Label 15 205 400 22 $ui.form
    $list = $ui.lv = New-UiControl ListView 15 230 735 190 $ui.form
    $list.View = 'Details'; $list.FullRowSelect = $true; $list.GridLines = $true; $list.HideSelection = $false
    1..5 | ForEach-Object { $null = $list.Columns.Add('', 100) }
    $ui.remove = New-UiControl Button 15 428 200 34 $ui.form
    $ui.edit = New-UiControl Button 225 428 200 34 $ui.form
}

function New-FooterSection {
    <#
    .SYNOPSIS
        Creates the destination folder row, the download button, the progress bar and the status line.
    #>
    $ui = $script:ui
    $ui.folderLbl = New-UiControl Label 15 478 90 24 $ui.form
    $ui.folder = New-UiControl TextBox 105 474 515 28 $ui.form
    $ui.folder.Text = [Environment]::GetFolderPath('MyDocuments')
    $ui.change = New-UiControl Button 630 472 120 32 $ui.form
    $ui.download = New-UiControl Button 15 518 735 44 $ui.form
    $ui.download.Font = New-Object Drawing.Font('Segoe UI', 12, [Drawing.FontStyle]::Bold)
    $ui.bar = New-UiControl ProgressBar 15 572 735 14 $ui.form
    $ui.status = New-UiControl Label 15 590 735 24 $ui.form
}

function Set-ControlAnchors {
    <#
    .SYNOPSIS
        Pins controls to the window edges so the list grows with the window and the footer stays at the bottom.
    #>
    $ui = $script:ui
    foreach ($name in 'listLbl', 'remove', 'edit', 'folderLbl', 'folder', 'change', 'download', 'bar', 'status') { $ui[$name].Anchor = 'Left,Right,Bottom' }
    $ui.lv.Anchor = 'Top,Left,Right,Bottom'; $ui.tabs.Anchor = 'Top,Left,Right'; $ui.listLbl.Anchor = 'Top,Left'
    $ui.remove.Anchor = 'Left,Bottom'; $ui.edit.Anchor = 'Left,Bottom'; $ui.folderLbl.Anchor = 'Left,Bottom'; $ui.change.Anchor = 'Right,Bottom'
}

function New-MainWindow {
    <#
    .SYNOPSIS
        Builds the main window, its controls and its event handlers into $script:ui.
    #>
    $ui = $script:ui = @{}
    $form = $ui.form = New-UiControl Form 0 0 780 640 $null
    $form.StartPosition = 'CenterScreen'; $form.Font = New-Object Drawing.Font('Segoe UI', 10)
    $form.ClientSize = New-Object Drawing.Size(780, 630); $form.MinimumSize = $form.Size
    New-LanguageSelector
    $ui.tabs = New-UiControl TabControl 15 45 735 150 $form
    $ui.tabPP = New-Object Windows.Forms.TabPage; $ui.tabRC = New-Object Windows.Forms.TabPage
    $ui.tabs.TabPages.AddRange(@($ui.tabPP, $ui.tabRC))
    New-ParcelTab
    New-ReferenceTab
    New-ListSection
    New-FooterSection
    Set-ControlAnchors
    Register-InputEvents
    Register-ListEvents
    Register-ActionEvents
    Set-UiLanguage
    Resize-ListColumns
}
