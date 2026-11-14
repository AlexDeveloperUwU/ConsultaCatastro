<#
.SYNOPSIS
    Shared configuration constants and mutable application state.
#>

$script:Config = @{
    UserAgent         = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'
    ApiBase           = 'https://ovc.catastro.meh.es/OVCServWeb/OVCWcfCallejero/COVCCallejero.svc/json'
    CoordsApi         = 'https://ovc.catastro.meh.es/OVCServWeb/OVCWcfCallejero/COVCCoordenadas.svc/json'
    MaxPolygonDigits  = 3
    MaxParcelDigits   = 5
    PdfUrl           = 'https://www1.sedecatastro.gob.es/CYCBienInmueble/SECImprimirCroquisYDatos.aspx'
    DataUrl           = 'https://www1.sedecatastro.gob.es/CYCBienInmueble/OVCConCiud.aspx'
    MapUrl            = 'https://www1.sedecatastro.gob.es/Cartografia/mapa.aspx'
    CroquisUrl        = 'https://www1.sedecatastro.gob.es/Cartografia/GeneraGraficoParcela.aspx'
    CroquisSize       = 400
    TemplateDir       = Join-Path $PSScriptRoot 'templates'
    RootDir           = Split-Path $PSScriptRoot -Parent
    MaxAttempts       = 3
    RetryDelaySeconds = 2
    RequestPauseMs    = 500
    ReferenceLength   = 20
    ErrorColor        = [Drawing.Color]::Firebrick
}

$script:State = @{ Lang = 'en'; Busy = $false; Offline = $false; MunicipalitiesFor = $null; ClickedCell = $null }
$script:ui = @{}
