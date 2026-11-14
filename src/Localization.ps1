<#
.SYNOPSIS
    Spanish and English texts and helpers to pick the active language.
#>

$script:Texts = @{
    es = @{
        code = 'es'; title = 'Consulta Catastro - descarga de fichas'; lang = 'Idioma'
        tabPP = 'Por parcela'; tabRC = 'Por referencia catastral'
        prov = 'Provincia'; mun = 'Municipio'; pol = 'Polígono'; par = 'Parcela'; rc = 'Referencia catastral (20 caracteres)'
        add = 'Añadir'; remove = 'Quitar seleccionada'; edit = 'Editar seleccionada'; folder = 'Guardar en:'; change = 'Cambiar...'
        download = 'Descargar fichas'; ready = 'Listo.'; list = 'Propiedades a descargar'
        errPP = 'Rellena provincia, municipio, polígono (hasta 3 cifras) y parcela (hasta 5 cifras), solo números.'
        errCodes = @{
            '1' = 'El Catastro tiene un problema ahora mismo. Inténtalo de nuevo más tarde.'
            '3' = 'La referencia catastral debe tener 14, 18 o 20 caracteres.'
            '4' = 'La referencia catastral no está bien formada. Revísala.'
            '5' = 'El Catastro no tiene ninguna propiedad con esos datos.'
            '9' = 'Esa referencia catastral no existe en el Catastro.'
            '12' = 'El Catastro no reconoce esa provincia.'
            '22' = 'El Catastro no reconoce ese municipio. Revisa cómo está escrito o elígelo de la lista.'
            '61' = 'Falta el polígono.'; '62' = 'Falta la parcela.'
            '63' = 'El polígono puede tener como máximo 3 cifras.'
            '64' = 'La parcela puede tener como máximo 5 cifras.'
            '72' = 'El Catastro no tiene mapa de esa zona.'
        }
        errRC = 'La referencia catastral debe tener 20 letras o números.'
        errEmpty = 'Añade al menos una propiedad.'
        working = 'Descargando {0} de {1}...'; finishing = 'Generando resumen e informes...'
        done = 'Terminado: {0} correctas, {1} con problemas.'; openq = '¿Abrir la carpeta con los resultados?'
        ok = 'Correcto'; errNotFound = 'No encontrada en el Catastro'; errPdf = 'Datos obtenidos, pero la ficha PDF no se pudo descargar'
        dup = 'Esa propiedad ya está en la lista.'; copied = 'Copiado: {0}'; busyMsg = 'Hay una descarga en curso. Espera a que termine.'
        errFolder = 'No se puede usar esa carpeta. Elige otra con el botón "Cambiar...".'
        offline = 'Sin conexión con el Catastro: la descarga necesita internet.'
        errNet = 'Error de conexión'; summary = 'Resumen.xlsx'; sheet = 'Catastro'; mapFile = 'Mapa catastral.url'; dataFile = 'Datos catastrales.url'
        RU = 'Rústico'; UR = 'Urbano'
        web = @{
            eyebrow = 'Consulta Catastro'; title = 'Resumen de propiedades'; generated = 'Generado el {0}'
            search = 'Buscar por referencia, municipio o dirección'
            fAll = 'Todas'; fRural = 'Rústicas'; fUrban = 'Urbanas'; fProblems = 'Con problemas'
            colRef = 'Referencia catastral'; colMun = 'Municipio'; colPolPar = 'Pol. / Parc.'; colType = 'Tipo'
            colUse = 'Uso'; colPlot = 'Sup. parcela'; colLinks = 'Abrir'
            linkData = 'Datos'; linkPdf = 'PDF'; noPdf = 'Sin PDF'; empty = 'Ninguna propiedad coincide.'
            clear = 'Quitar filtros'; showing = 'Mostrando {0} de {1} propiedades'
            back = 'Todas las propiedades'; copy = 'Copiar'; copied = 'Copiado'; noPdfWarn = 'Sin ficha PDF'
            sectionData = 'Datos catastrales'; province = 'Provincia'; municipality = 'Municipio'; polygon = 'Polígono'; parcel = 'Parcela'
            type = 'Tipo'; use = 'Uso'; built = 'Superficie construida'; plot = 'Superficie de la parcela'; address = 'Dirección'
            croquis = 'Croquis de la parcela'; docsTitle = 'Documentos y enlaces'
            pdfTitle = 'Ficha PDF'; pdfSub = 'Consulta descriptiva y gráfica'
            mapTitle = 'Mapa catastral'; mapSub = 'Se abre en la Sede del Catastro'
            dataTitle = 'Datos catastrales'; dataSub = 'Verificar en la Sede del Catastro'
            notCertified = 'Este documento no es una certificación catastral. Sus datos pueden verificarse en el acceso a datos catastrales no protegidos de la Sede Electrónica del Catastro.'
            locality = 'Localidad'; place = 'Paraje'; postal = 'Código postal'
            age = 'Antigüedad'; coords = 'Coordenadas (lat., long.)'
            googleTitle = 'Google Maps'; pointSub = 'Centro de la parcela'
            cropsTitle = 'Cultivos de la parcela'; cropName = 'Cultivo'; cropClass = 'Clase'; cropIntensity = 'Intensidad productiva'; cropArea = 'Superficie'
            buildsTitle = 'Construcciones'; buildUse = 'Uso'; buildType = 'Tipología'; buildWhere = 'Situación'; buildArea = 'Superficie'
            prev = 'Anterior'; next = 'Siguiente'
        }
        headers = @('Provincia', 'Municipio', 'Polígono', 'Parcela', 'Referencia catastral', 'Tipo', 'Uso', 'Sup. construida (m²)', 'Sup. parcela (m²)', 'Dirección', 'Localidad', 'Paraje', 'Código postal', 'Ficha PDF', 'Estado')
    }
    en = @{
        code = 'en'; title = 'Cadastre lookup - bulk record download'; lang = 'Language'
        tabPP = 'By parcel'; tabRC = 'By cadastral reference'
        prov = 'Province'; mun = 'Municipality'; pol = 'Polygon'; par = 'Parcel'; rc = 'Cadastral reference (20 characters)'
        add = 'Add'; remove = 'Remove selected'; edit = 'Edit selected'; folder = 'Save to:'; change = 'Change...'
        download = 'Download records'; ready = 'Ready.'; list = 'Properties to download'
        errPP = 'Fill in province, municipality, polygon (up to 3 digits) and parcel (up to 5 digits), numbers only.'
        errCodes = @{
            '1' = 'The Cadastre has a problem right now. Try again later.'
            '3' = 'The cadastral reference must have 14, 18 or 20 characters.'
            '4' = 'The cadastral reference is not well formed. Check it.'
            '5' = 'The Cadastre has no property with those details.'
            '9' = 'That cadastral reference does not exist in the Cadastre.'
            '12' = 'The Cadastre does not recognise that province.'
            '22' = 'The Cadastre does not recognise that municipality. Check the spelling or pick it from the list.'
            '61' = 'The polygon is missing.'; '62' = 'The parcel is missing.'
            '63' = 'The polygon can have at most 3 digits.'
            '64' = 'The parcel can have at most 5 digits.'
            '72' = 'The Cadastre has no map for that area.'
        }
        errRC = 'The cadastral reference must be 20 letters or digits.'
        errEmpty = 'Add at least one property.'
        working = 'Downloading {0} of {1}...'; finishing = 'Writing summary and reports...'
        done = 'Finished: {0} succeeded, {1} with problems.'; openq = 'Open the results folder?'
        ok = 'OK'; errNotFound = 'Not found in the Cadastre'; errPdf = 'Data retrieved, but the PDF record could not be downloaded'
        dup = 'That property is already in the list.'; copied = 'Copied: {0}'; busyMsg = 'A download is in progress. Please wait until it finishes.'
        errFolder = 'That folder cannot be used. Choose another one with the "Change..." button.'
        offline = 'No connection to the Cadastre: downloading needs internet.'
        errNet = 'Connection error'; summary = 'Summary.xlsx'; sheet = 'Cadastre'; mapFile = 'Cadastral map.url'; dataFile = 'Cadastral data.url'
        RU = 'Rural'; UR = 'Urban'
        web = @{
            eyebrow = 'Cadastre lookup'; title = 'Property summary'; generated = 'Generated on {0}'
            search = 'Search by reference, municipality or address'
            fAll = 'All'; fRural = 'Rural'; fUrban = 'Urban'; fProblems = 'With problems'
            colRef = 'Cadastral reference'; colMun = 'Municipality'; colPolPar = 'Pol. / Parc.'; colType = 'Type'
            colUse = 'Use'; colPlot = 'Plot area'; colLinks = 'Open'
            linkData = 'Data'; linkPdf = 'PDF'; noPdf = 'No PDF'; empty = 'No property matches.'
            clear = 'Clear filters'; showing = 'Showing {0} of {1} properties'
            back = 'All properties'; copy = 'Copy'; copied = 'Copied'; noPdfWarn = 'No PDF record'
            sectionData = 'Cadastral data'; province = 'Province'; municipality = 'Municipality'; polygon = 'Polygon'; parcel = 'Parcel'
            type = 'Type'; use = 'Use'; built = 'Built area'; plot = 'Plot area'; address = 'Address'
            croquis = 'Parcel drawing'; docsTitle = 'Documents and links'
            pdfTitle = 'PDF record'; pdfSub = 'Descriptive and graphic query'
            mapTitle = 'Cadastral map'; mapSub = 'Opens on the Catastro website'
            dataTitle = 'Cadastral data'; dataSub = 'Verify on the Catastro website'
            notCertified = 'This document is not a cadastral certification. Its data can be verified through the access to unprotected cadastral data of the Sede Electronica del Catastro.'
            locality = 'Locality'; place = 'Place name'; postal = 'Postal code'
            age = 'Year built'; coords = 'Coordinates (lat., long.)'
            googleTitle = 'Google Maps'; pointSub = 'Centre of the parcel'
            cropsTitle = 'Parcel crops'; cropName = 'Crop'; cropClass = 'Class'; cropIntensity = 'Productive intensity'; cropArea = 'Area'
            buildsTitle = 'Constructions'; buildUse = 'Use'; buildType = 'Type'; buildWhere = 'Location'; buildArea = 'Area'
            prev = 'Previous'; next = 'Next'
        }
        headers = @('Province', 'Municipality', 'Polygon', 'Parcel', 'Cadastral reference', 'Type', 'Use', 'Built area (m²)', 'Plot area (m²)', 'Address', 'Locality', 'Place name', 'Postal code', 'PDF record', 'Status')
    }
}

function Get-Text {
    <#
    .SYNOPSIS
        Returns the text table of the language currently selected in the UI.
    #>
    $script:Texts[$script:State.Lang]
}

function Get-DefaultLanguage {
    <#
    .SYNOPSIS
        Picks the UI language from the Windows display language: es for Spanish, en for anything else.
    #>
    if ([Globalization.CultureInfo]::CurrentUICulture.TwoLetterISOLanguageName -eq 'es') { 'es' } else { 'en' }
}
