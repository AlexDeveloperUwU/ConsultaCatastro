<#
.SYNOPSIS
    Small file-system helpers: PDF record, parcel drawing, internet shortcuts and folders.
#>

function Save-Binary([string]$Url, [string]$Path, [byte[]]$Signature) {
    <#
    .SYNOPSIS
        Downloads a file and saves it only when it starts with the expected signature bytes.
    .OUTPUTS
        System.Boolean. False on any failure or when the content is not the expected type.
    #>
    try {
        $bytes = Get-Web $Url
        if ($bytes.Length -le $Signature.Length) { return $false }
        for ($i = 0; $i -lt $Signature.Length; $i++) { if ($bytes[$i] -ne $Signature[$i]) { return $false } }
        [IO.File]::WriteAllBytes($Path, $bytes)
        $true
    } catch {
        $false
    }
}

function Save-Pdf($Prop, [string]$Path) {
    <#
    .SYNOPSIS
        Saves the PDF record of a property. True only when the response really is a PDF.
    #>
    Save-Binary (Get-PdfUrl $Prop) $Path ([Text.Encoding]::ASCII.GetBytes('%PDF'))
}

function Save-Croquis($Prop, [string]$Path) {
    <#
    .SYNOPSIS
        Saves the parcel drawing of a property. True only when the response really is a PNG.
    #>
    Save-Binary (Get-CroquisUrl $Prop) $Path ([byte[]](0x89, 0x50, 0x4E, 0x47))
}

function Write-InternetShortcut([string]$Path, [string]$Url) {
    <#
    .SYNOPSIS
        Writes a Windows .url internet shortcut.
    #>
    [IO.File]::WriteAllText($Path, "[InternetShortcut]`r`nURL=$Url`r`n", [Text.Encoding]::ASCII)
}

function Initialize-Folder([string]$Path) {
    <#
    .SYNOPSIS
        Makes sure a folder exists and can be created.
    .OUTPUTS
        System.Boolean. False when the path is empty or cannot be created.
    #>
    try {
        if (-not $Path) { return $false }
        $null = New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop
        $true
    } catch {
        $false
    }
}
