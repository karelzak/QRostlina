# Data Import/Export Formats

This document describes the CSV formats used for importing and exporting data in QRostlina. All CSV files are expected to use standard comma-separated values.

## Species

Used for importing and exporting plant species definitions.

| Column | Name | Description | Example |
| :--- | :--- | :--- | :--- |
| 1 | **ID** | Unique identifier (Prefix `S-` recommended) | `S-123` |
| 2 | **Name** | Common name of the species | `Tomato 'Cherry'` |
| 3 | **Latin Name** | Scientific name (optional) | `Solanum lycopersicum` |
| 4 | **Color** | Hex color or name for UI (optional) | `#FF0000` |
| 5 | **Description**| Detailed notes (optional) | `Small red fruit` |
| 6 | **Photo URL** | URL or local path to species photo (optional) | `https://example.com/p.jpg` |

**Filename:** `species_export.csv`

---

## Beds (Locations)

Used for importing and exporting bed layouts and their current plantings.

| Column | Name | Description | Example |
| :--- | :--- | :--- | :--- |
| 1 | **ID** | Unique identifier (Prefix `B-` recommended) | `B-01` |
| 2 | **Name** | Display name of the bed | `Main Bed A` |
| 3 | **Label** | Physical identifier/Row label | `Row A` |
| 4 | **Length** | Length in meters (integer) | `10` |
| 5 | **LinesPerMeter**| Sub-divisions across bed width (integer) | `2` |
| 6 | **RowsPerMeter**| Sub-divisions per meter along length (integer) | `2` |
| 7 | **Layout** | Placement logic: `grid`, `linear`, or `rand` | `grid` |
| 8 | **SpeciesMap** | JSON encoded map of positions to Species IDs | `{"1-1":"S-1", "1-2":"S-2"}` |
| 9 | **RandSpeciesIds**| Semicolon-separated list of Species IDs (for `rand` layout) | `S-1;S-5;S-10` |

### SpeciesMap Details
The `SpeciesMap` column contains a JSON string where:
- Keys are formatted as `"{line}-{row}"`.
- Values are the corresponding `Species ID`.
- For `linear` layout, `line` is always `1`.
- For `grid` layout, `line` ranges from `1` to `LinesPerMeter`.
- `row` ranges from `1` to `Length * RowsPerMeter`.

**Filename:** `beds_export.csv`

---

## Crates (Locations)

Used for importing and exporting transport/storage crates.

| Column | Name | Description | Example |
| :--- | :--- | :--- | :--- |
| 1 | **ID** | Unique identifier (Prefix `C-` recommended) | `C-05` |
| 2 | **Name** | Display name of the crate | `Green Crate` |
| 3 | **Type** | Material or category | `plastic` |
| 4 | **SpeciesIDs** | Semicolon-separated list of Species IDs | `S-1;S-4;S-12` |

**Filename:** `crates_export.csv`
