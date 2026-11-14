<#
.SYNOPSIS
    Hand-built .xlsx writer (XML parts zipped with System.IO.Compression); Excel is not required.
#>

function Get-ColumnLetter([int]$Index) {
    <#
    .SYNOPSIS
        Converts a zero-based column index to its spreadsheet letter (supports A to Z).
    #>
    [string][char](65 + $Index)
}

function ConvertTo-CellXml([string]$Ref, [string]$Value, [bool]$AsNumber = $false, [bool]$IsHeader = $false) {
    <#
    .SYNOPSIS
        Builds the XML of one worksheet cell: a number, or an inline string (bold when it is a header).
    #>
    if ($AsNumber) { return "<c r=`"$Ref`"><v>$Value</v></c>" }
    $style = if ($IsHeader) { ' s="1"' } else { '' }
    "<c r=`"$Ref`" t=`"inlineStr`"$style><is><t>$([Security.SecurityElement]::Escape($Value))</t></is></c>"
}

function New-SheetDataXml([string[]]$Headers, $Rows, [int[]]$NumericColumns) {
    <#
    .SYNOPSIS
        Builds the sheetData XML: a header row followed by one row per data row. Empty values produce no cell.
    #>
    $xml = New-Object Text.StringBuilder
    $null = $xml.Append('<row r="1">')
    for ($col = 0; $col -lt $Headers.Count; $col++) {
        $null = $xml.Append((ConvertTo-CellXml "$(Get-ColumnLetter $col)1" $Headers[$col] -IsHeader $true))
    }
    $null = $xml.Append('</row>')
    $rowNumber = 1
    foreach ($row in $Rows) {
        $rowNumber++
        $null = $xml.Append("<row r=`"$rowNumber`">")
        for ($col = 0; $col -lt $Headers.Count; $col++) {
            $value = [string]$row[$col]
            if ($value -eq '') { continue }
            $isNumber = ($NumericColumns -contains $col) -and $value -match '^\d+(\.\d+)?$'
            $null = $xml.Append((ConvertTo-CellXml "$(Get-ColumnLetter $col)$rowNumber" $value -AsNumber $isNumber))
        }
        $null = $xml.Append('</row>')
    }
    $xml.ToString()
}

function Get-XlsxParts([string]$SheetName, [int]$ColumnCount, [string]$SheetData) {
    <#
    .SYNOPSIS
        Returns the XML parts of a minimal one-sheet workbook, keyed by their path inside the zip.
    #>
    $main = 'xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"'
    $rel = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
    $pkgRel = 'xmlns="http://schemas.openxmlformats.org/package/2006/relationships"'
    $widths = 14, 16, 10, 10, 24, 10, 20, 18, 16, 50, 18, 22, 12, 26, 40
    $cols = -join (0..($ColumnCount - 1) | ForEach-Object { "<col min=`"$($_ + 1)`" max=`"$($_ + 1)`" width=`"$($widths[$_])`" customWidth=`"1`"/>" })
    $font = '<sz val="11"/><name val="Calibri"/>'
    [ordered]@{
        '[Content_Types].xml'        = '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>'
        '_rels/.rels'                = "<Relationships $pkgRel><Relationship Id=`"rId1`" Type=`"$rel/officeDocument`" Target=`"xl/workbook.xml`"/></Relationships>"
        'xl/workbook.xml'            = "<workbook $main xmlns:r=`"$rel`"><sheets><sheet name=`"$([Security.SecurityElement]::Escape($SheetName))`" sheetId=`"1`" r:id=`"rId1`"/></sheets></workbook>"
        'xl/_rels/workbook.xml.rels' = "<Relationships $pkgRel><Relationship Id=`"rId1`" Type=`"$rel/worksheet`" Target=`"worksheets/sheet1.xml`"/><Relationship Id=`"rId2`" Type=`"$rel/styles`" Target=`"styles.xml`"/></Relationships>"
        'xl/styles.xml'              = "<styleSheet $main><fonts count=`"2`"><font>$font</font><font><b/>$font</font></fonts><fills count=`"2`"><fill><patternFill patternType=`"none`"/></fill><fill><patternFill patternType=`"gray125`"/></fill></fills><borders count=`"1`"><border><left/><right/><top/><bottom/><diagonal/></border></borders><cellStyleXfs count=`"1`"><xf numFmtId=`"0`" fontId=`"0`" fillId=`"0`" borderId=`"0`"/></cellStyleXfs><cellXfs count=`"2`"><xf numFmtId=`"0`" fontId=`"0`" fillId=`"0`" borderId=`"0`" xfId=`"0`"/><xf numFmtId=`"0`" fontId=`"1`" fillId=`"0`" borderId=`"0`" xfId=`"0`" applyFont=`"1`"/></cellXfs></styleSheet>"
        'xl/worksheets/sheet1.xml'   = "<worksheet $main><sheetViews><sheetView workbookViewId=`"0`"><pane ySplit=`"1`" topLeftCell=`"A2`" activePane=`"bottomLeft`" state=`"frozen`"/></sheetView></sheetViews><cols>$cols</cols><sheetData>$SheetData</sheetData></worksheet>"
    }
}

function Write-ZipEntries([string]$Path, $Parts) {
    <#
    .SYNOPSIS
        Zips each XML part (UTF-8, no BOM, with XML declaration) into a new file.
    #>
    $utf8 = New-Object Text.UTF8Encoding $false
    $file = [IO.File]::Create($Path)
    try {
        $zip = New-Object IO.Compression.ZipArchive($file, [IO.Compression.ZipArchiveMode]::Create)
        try {
            foreach ($name in $Parts.Keys) {
                $bytes = $utf8.GetBytes('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + $Parts[$name])
                $stream = $zip.CreateEntry($name).Open()
                $stream.Write($bytes, 0, $bytes.Length)
                $stream.Close()
            }
        } finally { $zip.Dispose() }
    } finally { $file.Close() }
}

function Write-Xlsx([string]$Path, [string]$Sheet, [string[]]$Headers, $Rows, [int[]]$NumericColumns) {
    <#
    .SYNOPSIS
        Writes a one-sheet .xlsx file by hand-building the XML parts; Excel is not required.
    .PARAMETER Rows
        Array of string arrays, one per row, in the same order as Headers.
    .PARAMETER NumericColumns
        Zero-based indexes of the columns stored as numbers when the value is numeric.
    #>
    $sheetData = New-SheetDataXml $Headers $Rows $NumericColumns
    Write-ZipEntries $Path (Get-XlsxParts $Sheet $Headers.Count $sheetData)
}
