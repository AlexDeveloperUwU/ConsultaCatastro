<#
.SYNOPSIS
    Pure rules: input validation, request keys and Sede URL builders. No I/O.
#>

function Remove-Accents([string]$Text) {
    <#
    .SYNOPSIS
        Strips diacritics from a string, so accented letters become their plain form.
    #>
    $decomposed = $Text.Normalize([Text.NormalizationForm]::FormD)
    -join ($decomposed.ToCharArray() | Where-Object { [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne 'NonSpacingMark' })
}

function Test-ParcelFields([string]$Province, [string]$Municipality, [string]$Polygon, [string]$Parcel) {
    <#
    .SYNOPSIS
        Validates the by-parcel form: names are required, polygon and parcel must be whole numbers.
    #>
    [bool]($Province -and $Municipality -and $Polygon -match '^\d+$' -and $Parcel -match '^\d+$')
}

function Test-ReferenceFormat([string]$Reference) {
    <#
    .SYNOPSIS
        Validates the shape of a cadastral reference: exactly 20 upper-case letters or digits.
    #>
    $Reference -match "^[A-Z0-9]{$($script:Config.ReferenceLength)}$"
}

function New-ParcelRequest([string]$Province, [string]$Municipality, [string]$Polygon, [string]$Parcel) {
    <#
    .SYNOPSIS
        Creates a by-parcel request with a normalized Key used to detect duplicates.
    .NOTES
        The key ignores case, accents and leading zeros, so the same parcel typed two ways collides.
    #>
    $key = '{0}|{1}|{2}|{3}' -f (Remove-Accents $Province).ToUpper(), (Remove-Accents $Municipality).ToUpper(), $Polygon.TrimStart('0'), $Parcel.TrimStart('0')
    @{ Prov = $Province; Mun = $Municipality; Pol = $Polygon; Par = $Parcel; Key = $key }
}

function New-ReferenceRequest([string]$Reference) {
    <#
    .SYNOPSIS
        Creates a by-cadastral-reference request.
    #>
    @{ RC = $Reference; Key = $Reference }
}

function Get-MapUrl($Prop) {
    <#
    .SYNOPSIS
        Builds the Sede map URL of a property (uses the 14-character parcel reference).
    #>
    "$($script:Config.MapUrl)?del=$($Prop.Cp)&mun=$($Prop.Cmc)&refcat=$($Prop.RC.Substring(0, 14))"
}

function Get-DataUrl($Prop) {
    <#
    .SYNOPSIS
        Builds the Sede URL of the public (non-certified) data page of a property.
    #>
    "$($script:Config.DataUrl)?RefC=$($Prop.RC)&del=$($Prop.Cp)&mun=$($Prop.Cmc)"
}

function Get-CroquisUrl($Prop) {
    <#
    .SYNOPSIS
        Builds the Sede URL of the parcel drawing (PNG), using the 14-character parcel reference.
    #>
    $size = $script:Config.CroquisSize
    "$($script:Config.CroquisUrl)?del=$($Prop.Cp)&mun=$($Prop.Cmc)&refcat=$($Prop.RC.Substring(0, 14))&AnchoPixels=$size&AltoPixels=$size"
}

function Get-PdfUrl($Prop) {
    <#
    .SYNOPSIS
        Builds the Sede URL of the property's PDF record.
    #>
    "$($script:Config.PdfUrl)?del=$($Prop.Cp)&mun=$($Prop.Cmc)&refcat=$($Prop.RC)"
}
