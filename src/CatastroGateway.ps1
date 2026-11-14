<#
.SYNOPSIS
    Everything that talks to the Catastro web services.
#>

function Get-Web([string]$Url) {
    <#
    .SYNOPSIS
        Downloads a URL with the browser User-Agent the Catastro requires.
    .DESCRIPTION
        Makes several attempts with a pause between them. Requests are always sequential.
    .OUTPUTS
        System.Byte[] with the raw response body.
    .NOTES
        Throws the last error when every attempt fails.
    #>
    for ($attempt = 1; $attempt -le $script:Config.MaxAttempts; $attempt++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -UserAgent $script:Config.UserAgent -UseBasicParsing -TimeoutSec 60
            return , $response.RawContentStream.ToArray()
        } catch {
            if ($attempt -eq $script:Config.MaxAttempts) { throw }
            Start-Sleep -Seconds $script:Config.RetryDelaySeconds
        }
    }
}

function Get-Json([string]$Url) {
    <#
    .SYNOPSIS
        Downloads a Catastro JSON endpoint and parses it as UTF-8.
    #>
    [Text.Encoding]::UTF8.GetString((Get-Web $Url)) | ConvertFrom-Json
}

function Get-Provinces {
    <#
    .SYNOPSIS
        Lists the province names exactly as the Catastro spells them (for example ALACANT).
    .NOTES
        Navarra and the Basque provinces are not listed by the service. Throws when offline.
    #>
    @((Get-Json "$($script:Config.ApiBase)/ObtenerProvincias").consulta_provincieroResult.provinciero.prov | ForEach-Object { $_.np })
}

function Get-Municipalities([string]$Province) {
    <#
    .SYNOPSIS
        Lists the municipality names of a province as the Catastro spells them.
    .PARAMETER Province
        Province name as returned by Get-Provinces. Throws when offline.
    #>
    $url = "$($script:Config.ApiBase)/ObtenerMunicipios?Provincia=$([uri]::EscapeDataString($Province))&Municipio="
    @((Get-Json $url).consulta_municipieroResult.municipiero.muni | ForEach-Object { $_.nm })
}

function ConvertTo-Property($Item, $Bico) {
    <#
    .SYNOPSIS
        Flattens one property of a Catastro response into a plain object.
    .DESCRIPTION
        The 20-character reference is pc1+pc2+car+cc1+cc2. Fields missing in the response are left empty.
    .PARAMETER Item
        A bico.bi or bico.lrcdnp.rcdnp element.
    .PARAMETER Bico
        The parent bico node, used for the plot surface.
    #>
    $ref = if ($Item.idbi) { $Item.idbi.rc } else { $Item.rc }
    $location = $Item.dt.locs.lors.lorus.cpp
    [pscustomobject]@{
        RC = '{0}{1}{2}{3}{4}' -f $ref.pc1, $ref.pc2, $ref.car, $ref.cc1, $ref.cc2
        Cp = $Item.dt.loine.cp; Cmc = $Item.dt.cmc; Prov = $Item.dt.np; Mun = $Item.dt.nm
        Type = $Item.idbi.cn; Use = $Item.debi.luso; Built = $Item.debi.sfc; Plot = $Bico.finca.dff.ss
        Addr = $Item.ldt; Pol = $location.cpo; Par = $location.cpa
    }
}

function Get-LookupUrls($Request) {
    <#
    .SYNOPSIS
        Lists the Catastro URLs to try for a request, most specific first.
    .NOTES
        By-parcel requests are retried once with accents removed, since the service is picky about spelling.
    #>
    $api = $script:Config.ApiBase
    if ($Request.RC) { return @("$api/Consulta_DNPRC?RefCat=$($Request.RC)") }
    $province = $Request.Prov.ToUpper(); $municipality = $Request.Mun.ToUpper()
    $spellings = @(, @($province, $municipality))
    $plain = @((Remove-Accents $province), (Remove-Accents $municipality))
    if ($plain[0] -ne $province -or $plain[1] -ne $municipality) { $spellings += , $plain }
    @(foreach ($names in $spellings) {
            "$api/Consulta_DNPPP?Provincia=$([uri]::EscapeDataString($names[0]))&Municipio=$([uri]::EscapeDataString($names[1]))&Poligono=$($Request.Pol)&Parcela=$($Request.Par)"
        })
}

function Get-ResponseItems($Bico) {
    <#
    .SYNOPSIS
        Returns the property elements of a response, whether it holds one (bi) or several (lrcdnp).
    #>
    @(if ($Bico.bi) { $Bico.bi } elseif ($Bico.lrcdnp.rcdnp) { $Bico.lrcdnp.rcdnp })
}

function New-LookupResult($Props = @(), [string]$ErrorKind = '', [string]$Detail = '') {
    <#
    .SYNOPSIS
        Creates the outcome of a lookup: the properties found, or an error kind (NotFound, Network, Unexpected) with detail.
    #>
    [pscustomobject]@{ Props = @($Props); ErrorKind = $ErrorKind; Detail = $Detail; Succeeded = (-not $ErrorKind) }
}

function Find-Properties($Request) {
    <#
    .SYNOPSIS
        Looks up the properties of one request in the Catastro. Never throws.
    .PARAMETER Request
        Hashtable made by New-ParcelRequest or New-ReferenceRequest.
    .OUTPUTS
        The object made by New-LookupResult.
    .NOTES
        One response can contain several properties. A municipality that is not found is reported, never corrected.
    #>
    try {
        $detail = ''
        foreach ($url in Get-LookupUrls $Request) {
            try { $json = Get-Json $url } catch { return New-LookupResult -ErrorKind 'Network' -Detail $_.Exception.Message }
            $result = if ($json.consulta_dnprcResult) { $json.consulta_dnprcResult } else { $json.consulta_dnpppResult }
            $items = @(Get-ResponseItems $result.bico)
            if ($items.Count) { return New-LookupResult -Props @($items | ForEach-Object { ConvertTo-Property $_ $result.bico }) }
            if ($result.lerr) { $detail = $result.lerr[0].des }
        }
        New-LookupResult -ErrorKind 'NotFound' -Detail $detail
    } catch {
        New-LookupResult -ErrorKind 'Unexpected' -Detail $_.Exception.Message
    }
}

function Format-LookupError($Lookup, [hashtable]$Texts) {
    <#
    .SYNOPSIS
        Turns a failed lookup into a message in the language of the given text table.
    #>
    switch ($Lookup.ErrorKind) {
        'NotFound' { if ($Lookup.Detail) { "$($Texts.errNotFound): $($Lookup.Detail)" } else { $Texts.errNotFound } }
        'Network' { "$($Texts.errNet): $($Lookup.Detail)" }
        default { $Lookup.Detail }
    }
}
