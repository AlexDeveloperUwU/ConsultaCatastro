<#
.SYNOPSIS
    Application service: downloads every request into a results folder and writes the summary.
#>

function New-SummaryRow($Prop, [string]$PdfPath, [string]$Status, [hashtable]$Texts) {
    <#
    .SYNOPSIS
        Builds the Excel row of a property, in the order of the summary headers.
    #>
    $type = if ($Prop.Type) { $Texts[$Prop.Type] } else { '' }
    , @($Prop.Prov, $Prop.Mun, $Prop.Pol, $Prop.Par, $Prop.RC, $type, $Prop.Use, $Prop.Built, $Prop.Plot, $Prop.Addr,
        $Prop.Locality, $Prop.Place, $Prop.Postal, $PdfPath, $Status)
}

function New-ErrorRow($Source, [string]$Message) {
    <#
    .SYNOPSIS
        Builds the Excel row of a request or property that failed, keeping whatever identifying data is known.
    #>
    , @($Source.Prov, $Source.Mun, $Source.Pol, $Source.Par, $Source.RC, '', '', '', '', '', '', '', '', '', $Message)
}

function Save-PropertyFiles($Prop, [string]$ResultsDir, [hashtable]$Texts) {
    <#
    .SYNOPSIS
        Creates the property's folder with its map shortcut, data shortcut, PDF record and parcel drawing.
    .OUTPUTS
        Object with Row (the Excel row), Record (the report page data) and Saved (whether the PDF was obtained).
    #>
    $point = Get-Coordinates $Prop
    $Prop.Lat = $point.Lat; $Prop.Lon = $point.Lon
    $folder = Join-Path $ResultsDir $Prop.RC
    $null = New-Item -ItemType Directory -Path $folder -Force
    Write-InternetShortcut (Join-Path $folder $Texts.mapFile) (Get-MapUrl $Prop)
    Write-InternetShortcut (Join-Path $folder $Texts.dataFile) (Get-DataUrl $Prop)
    $relativePdf = Join-Path $Prop.RC "$($Prop.RC).pdf"
    $saved = Save-Pdf $Prop (Join-Path $ResultsDir $relativePdf)
    $hasCroquis = Save-Croquis $Prop (Join-Path $folder 'Croquis.png')
    $row = if ($saved) { New-SummaryRow $Prop $relativePdf $Texts.ok $Texts } else { New-SummaryRow $Prop '' $Texts.errPdf $Texts }
    [pscustomobject]@{ Row = $row; Saved = $saved; Record = (New-PropertyRecord $Prop $saved $hasCroquis $Texts) }
}

function Invoke-Download($Requests, [string]$BaseDir, [hashtable]$Texts, [scriptblock]$OnProgress) {
    <#
    .SYNOPSIS
        Downloads every request into a new timestamped folder and writes the Excel summary.
    .DESCRIPTION
        Each property gets a sub-folder named after its reference with the PDF record, the parcel drawing,
        two internet shortcuts (map and data) and its own Consulta.html. Catastro.html at the root indexes
        them all. A property already saved in the run is skipped, and a failure on one property becomes
        an error row without stopping the rest.
    .PARAMETER Texts
        Text table (see $script:Texts) used for the summary headers, statuses and file names.
    .PARAMETER OnProgress
        Called with (completed, total, stage): before each request (stage item) and once more before the
        summary and pages are written (stage finish).
    .OUTPUTS
        Hashtable with Ok, Bad (counts) and Dir (the folder created).
    #>
    $resultsDir = Join-Path $BaseDir ('Catastro_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
    $null = New-Item -ItemType Directory -Path $resultsDir -Force
    $rows = New-Object Collections.ArrayList
    $records = New-Object Collections.ArrayList
    $saved = @{}
    $ok = 0; $bad = 0; $index = 0
    $total = @($Requests).Count
    foreach ($request in $Requests) {
        $index++
        if ($OnProgress) { & $OnProgress ($index - 1) $total 'item' }
        $lookup = Find-Properties $request
        if (-not $lookup.Succeeded) {
            $bad++
            $message = Format-LookupError $lookup $Texts
            $null = $rows.Add((New-ErrorRow $request $message))
            $null = $records.Add((New-ErrorRecord $request $message))
            continue
        }
        foreach ($prop in $lookup.Props | Where-Object { -not $saved.ContainsKey($_.RC) }) {
            $saved[$prop.RC] = $true
            try {
                $outcome = Save-PropertyFiles $prop $resultsDir $Texts
                $null = $rows.Add($outcome.Row)
                $null = $records.Add($outcome.Record)
                if ($outcome.Saved) { $ok++ } else { $bad++ }
            } catch {
                $bad++
                $null = $rows.Add((New-ErrorRow $prop $_.Exception.Message))
                $null = $records.Add((New-ErrorRecord $prop $_.Exception.Message))
            }
        }
        Start-Sleep -Milliseconds $script:Config.RequestPauseMs
    }
    if ($OnProgress) { & $OnProgress $total $total 'finish' }
    Write-Xlsx (Join-Path $resultsDir $Texts.summary) $Texts.sheet $Texts.headers $rows @(7, 8)
    Write-ReportPages $records $resultsDir $Texts
    @{ Ok = $ok; Bad = $bad; Dir = $resultsDir }
}
