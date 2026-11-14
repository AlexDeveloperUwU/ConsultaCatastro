<#
.SYNOPSIS
    HTML report pages: a root index and one page per property, built from the templates in src\templates.
#>

function Format-Area($Value) {
    <#
    .SYNOPSIS
        Formats a surface in square metres, or a dash when the Catastro gave none.
    #>
    if ($Value) { "$Value m$([char]0x00B2)" } else { '-' }
}

function New-PropertyRecord($Prop, [bool]$HasPdf, [bool]$HasCroquis, [hashtable]$Texts) {
    <#
    .SYNOPSIS
        Builds the data record the report pages show for a property.
    .NOTES
        Paths are relative to the results folder; the property page rewrites the ones it needs.
    #>
    $folder = $Prop.RC
    $polpar = if ($Prop.Pol -and $Prop.Par) { "$($Prop.Pol) / $($Prop.Par)" } else { '-' }
    $points = Get-MapPointUrls $Prop
    @{
        rc = $Prop.RC; province = $Prop.Prov; municipality = $Prop.Mun; polygon = $Prop.Pol; parcel = $Prop.Par; polpar = $polpar
        type = $(if ($Prop.Type) { $Texts[$Prop.Type] } else { '' }); typeCode = $Prop.Type; use = $Prop.Use
        built = (Format-Area $Prop.Built); plot = (Format-Area $Prop.Plot); address = $Prop.Addr
        hasPdf = $HasPdf; hasCroquis = $HasCroquis; error = ''
        href = "$folder/Consulta.html"; pdfHref = "$folder/$($Prop.RC).pdf"; pdfFile = "$($Prop.RC).pdf"
        mapUrl = (Get-MapUrl $Prop); dataUrl = (Get-DataUrl $Prop)
        locality = $Prop.Locality; place = $Prop.Place; postal = $Prop.Postal
        age = $Prop.Age; crops = @($Prop.Crops); builds = @($Prop.Builds)
        lat = $Prop.Lat; lon = $Prop.Lon; googleUrl = $points.Google
    }
}

function New-ErrorRecord($Source, [string]$Message) {
    <#
    .SYNOPSIS
        Builds the report record of a request that could not be resolved: no links, just the message.
    #>
    $polpar = if ($Source.Pol -and $Source.Par) { "$($Source.Pol) / $($Source.Par)" } else { '-' }
    @{
        rc = $Source.RC; province = $Source.Prov; municipality = $Source.Mun; polygon = $Source.Pol; parcel = $Source.Par; polpar = $polpar
        type = ''; typeCode = ''; use = ''; built = '-'; plot = '-'; address = ''
        hasPdf = $false; hasCroquis = $false; error = $Message
        href = ''; pdfHref = ''; pdfFile = ''; mapUrl = ''; dataUrl = ''
        locality = ''; place = ''; postal = ''; age = ''; crops = @(); builds = @()
        lat = ''; lon = ''; googleUrl = ''
    }
}

function ConvertTo-SafeJson($Data) {
    <#
    .SYNOPSIS
        Serializes data to compact JSON that is safe to embed inside a script tag.
    #>
    (ConvertTo-Json $Data -Depth 6 -Compress).Replace('<', '<')
}

function Write-HtmlPage([string]$Template, [string]$Path, $Data, [string]$Head = '') {
    <#
    .SYNOPSIS
        Fills a template with the JSON data and writes the page as UTF-8.
    .PARAMETER Head
        Extra lines for the page head, such as preload and prefetch hints for files only this page needs.
    #>
    $html = [IO.File]::ReadAllText((Join-Path $script:Config.TemplateDir $Template), [Text.Encoding]::UTF8)
    $html = $html.Replace('__HEAD__', $Head).Replace('__DATA__', (ConvertTo-SafeJson $Data))
    [IO.File]::WriteAllText($Path, $html, (New-Object Text.UTF8Encoding $false))
}

function Get-PropertyPageHead($Record, [string]$Previous, [string]$Next) {
    <#
    .SYNOPSIS
        Builds the preload and prefetch hints of a property page: its drawing, and the neighbouring pages.
    #>
    $lines = New-Object Collections.Generic.List[string]
    if ($Record.hasCroquis) { $lines.Add('<link rel="preload" as="image" href="Croquis.png">') }
    foreach ($href in $Previous, $Next) { if ($href) { $lines.Add("<link rel=`"prefetch`" href=`"$href`">") } }
    $lines -join "`n"
}

function Write-ReportPages($Records, [string]$ResultsDir, [hashtable]$Texts) {
    <#
    .SYNOPSIS
        Writes Catastro.html at the root and a Consulta.html inside the folder of every resolved property.
    .PARAMETER Records
        Records made by New-PropertyRecord and New-ErrorRecord, in download order.
    #>
    $generated = Get-Date -Format 'yyyy-MM-dd HH:mm'
    Write-HtmlPage 'Catastro.html' (Join-Path $ResultsDir 'Catastro.html') @{ t = $Texts.web; lang = $Texts.code; generated = $generated; records = @($Records) }
    $pages = @($Records | Where-Object { $_.href })
    for ($i = 0; $i -lt $pages.Count; $i++) {
        $previous = if ($i -gt 0) { "../$($pages[$i - 1].href)" } else { '' }
        $next = if ($i -lt $pages.Count - 1) { "../$($pages[$i + 1].href)" } else { '' }
        $path = Join-Path (Join-Path $ResultsDir $pages[$i].rc) 'Consulta.html'
        $data = @{ t = $Texts.web; lang = $Texts.code; record = $pages[$i]; prev = $previous; next = $next }
        Write-HtmlPage 'Consulta.html' $path $data (Get-PropertyPageHead $pages[$i] $previous $next)
    }
}
