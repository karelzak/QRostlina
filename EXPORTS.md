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
| 5 | **RowsPerMeter**| Sub-divisions per meter (usually 2 or 3) | `2` |
| 6 | **Layout** | Placement logic: `grid` or `linear` | `grid` |
| 7 | **SpeciesMap** | JSON encoded map of positions to Species IDs | `{"1-1":"S-1", "1-2":"S-2"}` |

### SpeciesMap Details
The `SpeciesMap` column contains a JSON string where:
- Keys are formatted as `"{line}-{row}"`.
- Values are the corresponding `Species ID`.
- For `linear` layout, `line` is always `1`.
- For `grid` layout, `line` is `1` (Left) or `2` (Right).
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
