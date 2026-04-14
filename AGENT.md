# QRostlina - Agent Instructions

## App Persona
- Senior Flutter Developer & Agricultural Tech Expert.
- Expert in high-contrast, accessibility-first UI for outdoor use.
- Focused on offline-first reliability and simple data models.

## User Context
- The user is managing a plant nursery or research field.
- Environment: Outdoors, bright sunlight, potentially wearing gloves.
- Needs: Fast scanning, clear visual feedback, minimal typing.

## Technical Architecture
- **Language:** Dart 3.x
- **Framework:** Flutter (Mobile/Linux)
- **Data Layer (Dual-Mode):**
  - **Local Mode (Linux/Offline):** Uses `MockDatabaseService` with JSON persistence (`qrostlina_data.json`).
  - **Cloud Mode (Android/Sync):** Uses Firestore for text data and Firebase Storage for images.
  - **Coexistence:** The app must seamlessly switch between Local and Cloud modes based on settings or platform capabilities. Linux defaults to Local JSON, while Android supports both.

## Project Structure & Files
- `lib/main.dart`: App entry point, theme definition, and service initialization.
- `lib/models/`:
  - `species.dart`: `Species` model (S-ID, name, description, photoUrl, etc.).
  - `location.dart`: `Location` base class, `Bed` and `Crate` models. `Bed` supports `grid`, `linear`, and `rand` layouts.
- `lib/screens/`:
  - `species_list_screen.dart`: Main list of all species with search.
  - `locations_screen.dart`: Tabs for Beds and Crates list.
  - `detail_screen.dart`: Unified detail view for S-, B-, and C- IDs. Handles Visual Map for Beds.
  - `edit_species_screen.dart` / `edit_location_screen.dart`: CRUD forms.
  - `scanner_screen.dart`: QR scanner interface (mobile) or manual ID entry (desktop).
  - `printing_screen.dart`: Generic label printing UI for all entity types and free-text labels.
  - `settings_screen.dart`: Auth, Data (Sync/Backup), and Language settings.
- `lib/services/`:
  - `database_service.dart`: Interface for data operations.
  - `firestore_database_service.dart`: Implementation for Firebase/Cloud mode.
  - `local_storage_service.dart`: Implementation for Local/Offline mode (JSON).
  - `printing_service.dart`: Brother printer discovery, label rendering, and printing.
  - `auth_service.dart`: Firebase Auth & Google Sign-In.
  - `service_locator.dart`: GetIt setup for dependency injection.
- `lib/widgets/`: Reusable UI components (ID inputs, dialogs).
- `lib/l10n/`: Localization files (`.arb` and generated `.dart`).

## Data Integrity & Synchronization
To prevent data loss and ensure consistent behavior across platforms, the following must always be kept in sync:

1. **Model Synchronization:**
   - Any change to fields in `lib/models/species.dart` or `lib/models/location.dart` **MUST** be reflected in:
     - `lib/services/csv_service.dart`: Update both `export...` and `import...` methods.
     - `EXPORTS.md`: Update the CSV column definitions and examples.
     - `toMap()` and `fromMap()` methods within the model classes themselves.
   - When adding new fields to CSV import/export, always append them to the end of the existing column list or carefully adjust all subsequent indices in `CSVService` to avoid data corruption.

2. **Persistence Integrity:**
   - Ensure both `FirestoreDatabaseService` (Cloud) and `LocalStorageService` (Local JSON) are updated to handle any new or modified fields.
   - Use `jsonEncode`/`jsonDecode` for complex fields (like Maps or Lists) when exporting to CSV to maintain structure.

3. **UI Safety Standards:**
   - **Deletion Confirmation:** Deleting a location (Bed or Crate) that is NOT empty (contains species) **MUST** trigger a dialog with a warning (e.g., `deleteLocationNotEmpty`) to prevent accidental data loss.
   - **Import/Export Actions:** Every screen containing an import/export menu (e.g., `SpeciesListScreen`, `LocationsScreen`) **MUST** fully implement the `onSelected` callback in its `PopupMenuButton` to trigger the corresponding `CSVService` methods and refresh the UI data.
   - **Alphabetical Sorting:** All primary lists (Species, Beds, Crates) **MUST** be sorted alphabetically by name (case-insensitive) when displayed in the UI.

## Bed Structure & Layouts
Beds (B-ID) are managed via three distinct layouts, each with specific logic for capacity and visualization:

1. **Grid Layout (Organized)**
   - **Purpose:** Precise mapping of individual plants.
   - **Structure:** Defined by `Length` (arbitrary meters), `Lines` (max 3), and `Rows` (max 3) *per meter*.
   - **Data Mapping:** Each entry in `speciesMap` (key: "line-row") represents **1 specific plant**.
   - **Capacity:** `Length * Lines * Rows`.
   - **Visual Map:** Shows a full sub-grid for every meter (e.g., 2 columns if 2 lines).
   - **Constraints:** Any structural change (Layout, Lines, Rows, or reducing Length) on a non-empty bed requires user confirmation and resets all plantings.

2. **Linear Layout (Density-based)**
   - **Purpose:** High-density planting where one species covers an entire meter.
   - **Structure:** Defined by `Length` (arbitrary meters), `Lines` (max 20), and `Rows` (max 20) *per meter*.
   - **Data Mapping:** Each entry in `speciesMap` (key: "1-meterIdx") represents **all plants in that meter**.
   - **Capacity:** `Length * Lines * Rows`. (e.g., 10 lines x 15 rows = 150 plants/m).
   - **Visual Map:** Simplified UI showing **one large cell per meter**. The cell displays the species name and total plant count (e.g., "150pcs").
   - **Constraints:** Layout or Length changes on non-empty beds require confirmation. However, `Lines` and `Rows` can be adjusted freely as they only affect the density/count calculation, not the mapping.

3. **Random / Disorganized Layout**
   - **Purpose:** Quick tracking of species in a bed without any spatial organization.
   - **Structure:** No meters, no grid.
   - **Data Mapping:** Uses a flat list `randSpeciesIds`.
   - **Capacity:** Infinite / Not applicable.
   - **Visual Map:** Replaced with a simple list of species (similar to a Crate).
   - **Constraints:** Layout changes on non-empty beds require confirmation.

## Phase 2: Cloud Support & Synchronization (Done)
16. [x] Linear Bed Support.
17. [x] Random (Disorganized) Bed Support.

## MVP Scope (Phase 1) — Complete
15. [x] Visual Grid Map for Beds.
16. [x] Linear Bed Support with High-Density Calculation.
17. [x] Random Bed Support (List view).

## Label Printing — Brother PT-E920BT

### Architecture
- **Service:** `lib/services/printing_service.dart` — entity-agnostic `PrintingService` interface + `BrotherPrintingService` implementation.
- **Screen:** `lib/screens/printing_screen.dart` — generic `PrintingScreen` used for all entity types and free-text labels.
- **Library:** `another_brother` v2.2.4 (Flutter wrapper for Brother SDK v4).
- **Connectivity:** Bluetooth Classic. Printer selection saved to SharedPreferences (MAC, name, model ID).

### PT-E920BT Workaround
The `another_brother` `Model` enum does **not** include PT-E920BT. Use `Model.PT_P910BT` as the closest compatible model. Discovery adds `"PT-E920BT"` as an extra BT filter name; `_modelFromName()` maps names starting with `PT-E920` to `PT_P910BT`. The printer runs at **360 DPI**.

### Label Generation (Image-Based)
Labels are rendered as `ui.Image` in code (not via `.blf` templates). Key parameters:
- `generateLabel(String? qrData, String text, int tapeWidthMm, LabelContent content)`
- `printLabel(String? qrData, String text, String macAddress, Model model, ...)`
- **Tape sizes:** 12mm, 18mm, 24mm, 36mm. QR disabled on 12mm (too small to scan).
- **Orientation:** Always LANDSCAPE.
- **Flag mode:** Mirrors label left/right with fold line for cable wrapping.

### Per-Entity Label Content
| Entity  | fixedText (always on) | toggleableLabel (Label chip) | QR data |
|---------|-----------------------|------------------------------|---------|
| Species | `name`                | —                            | `id`    |
| Bed     | `id`                  | `row` (field label)          | `id`    |
| Crate   | `id`                  | —                            | `id`    |
| Generic | — (user types text)   | —                            | label text |

### P-touch Template Printing (Alternative Path — Not Currently Used)
Templates (`.blf` files) can be transferred to the printer and filled via `replaceTextName()`. Object naming convention if templates are used in the future:

| Object Name | Data Source | Type | Description |
|-------------|-----------|------|-------------|
| `NAME` / `NAME1` / `NAME2` | entity name | Text | Label text (flag: left/right) |
| `QR` / `QR1` / `QR2` | entity ID | QR Code | QR code (flag: left/right) |
| `ID` | entity ID | Text | ID as plain text |
| `NOTE` | user input | Text | Per-label note |
| `DATE` | *(auto)* | Date/Time | Auto-filled by printer |

Template preparation requires Windows (P-touch Editor → P-touch Transfer Manager → export `.blf`). The app only accepts `.blf` and `.pdz` files.

### Open Questions
- **QR Code in Template:** Needs real-device test to confirm `replaceTextName` updates QR code data in `.blf`.
- **Template transfer frequency:** Does the printer retain templates after power cycle?

