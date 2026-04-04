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
  - `settings_screen.dart`: Auth, Data (Sync/Backup), and Language settings.
- `lib/services/`:
  - `database_service.dart`: Interface for data operations.
  - `firestore_database_service.dart`: Implementation for Firebase/Cloud mode.
  - `local_storage_service.dart`: Implementation for Local/Offline mode (JSON).
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

## Phase 2: Cloud Support & Synchronization (In Progress)
...
16. [x] Linear Bed Support.
    - Status: High-density support (Lines x Rows) implemented.
17. [x] Random (Disorganized) Bed Support.
    - Status: Implemented as flat species list.

## MVP Scope (Phase 1)
...
15. [x] Visual Grid Map for Beds.
    - Status: Organized by meter, supports sub-grid layouts and human-friendly indexing.
16. [x] Linear Bed Support with High-Density Calculation.
17. [x] Random Bed Support (List view).

