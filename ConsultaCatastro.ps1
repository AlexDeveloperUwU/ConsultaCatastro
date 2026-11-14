<#
.SYNOPSIS
    Bulk download of Spanish cadastral records (PDF record + Excel summary), Spanish and English UI.
.DESCRIPTION
    Talks only to the public Catastro services and needs nothing but Windows PowerShell 5.1.
    The code lives in the src folder, one file per layer, loaded in dependency order below:
    configuration, localization, domain rules, Catastro gateway, file output, download service, window.
    Dot-source this file to load every function without opening the window.
#>
Add-Type -AssemblyName System.Windows.Forms, System.Drawing, System.IO.Compression
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

foreach ($module in 'Config', 'Localization', 'Domain', 'CatastroGateway', 'Xlsx', 'Files', 'Html', 'DownloadService', 'UiLayout', 'UiRows', 'UiBehavior', 'UiEvents') {
    . (Join-Path $PSScriptRoot "src\$module.ps1")
}

function Start-App {
    <#
    .SYNOPSIS
        Shows the main window in the Windows display language. Blocks until the window is closed.
    #>
    Hide-ConsoleWindow
    [Windows.Forms.Application]::EnableVisualStyles()
    $script:State.Lang = Get-DefaultLanguage
    New-MainWindow
    [void]$script:ui.form.ShowDialog()
}

if ($MyInvocation.InvocationName -ne '.') {
    try { Start-App } catch { [void][Windows.Forms.MessageBox]::Show($_.Exception.Message, 'ConsultaCatastro', 'OK', 'Error') }
}