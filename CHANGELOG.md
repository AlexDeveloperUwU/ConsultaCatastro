# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.2] - 2026-11-14

### Added

- A short demo of the app (GIF and MP4) in the README.

## [1.1.1] - 2026-11-14

### Changed

- The README discloses that the project was fully generated with AI, with the same "Generated" label as the author's profile.

## [1.1.0] - 2026-11-14

### Added

- Property pages show coordinates with a Google Maps link, the crops of rural parcels, the constructions of urban properties, locality, place name, postal code and year built.
- The summary spreadsheet gains locality, place name and postal code columns.
- Plain-language messages for the Catastro error codes.
- Input limits: polygon up to 3 digits, parcel up to 5.
- HTML pages preload their scripts, fonts and neighbouring pages.

### Changed

- The index page no longer shows the three counter tiles.

## [1.0.0] - 2026-11-14

### Added

- Windows form to bulk-download Spanish cadastral records, opened with a double-click on `ConsultaCatastro.bat`.
- Search by province, municipality, polygon and parcel, with province and municipality lists loaded from the Catastro.
- Search by 20-character cadastral reference.
- One folder per property, named after its cadastral reference, with the PDF record and shortcuts to the map and the data page.
- Excel summary (`.xlsx`) written without Excel installed.
- HTML report: `Catastro.html` at the root indexes every property (search, filters, links to the data page and the map), and each property folder has its own `Consulta.html` with the data, parcel drawing and links. Built with Alpine.js and Tailwind CSS from CDN.
- Parcel drawing (`Croquis.png`) saved in each property folder.
- Spanish and English interface, following the Windows language by default.
- Immediate lookup when a property is added, with invalid ones highlighted in red.
- Edit, remove and Delete-key support, double-click or Ctrl+C to copy a cell, and Enter to add a complete form.
- Duplicate detection, folder checks, retries with pauses, and per-property error handling.
