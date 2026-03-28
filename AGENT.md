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
- **Data Model:**
  - **Species (S-ID):** Name, latin name, description, color. (Root entity)
  - **Location (B-ID / C-ID):** 
    - **B-ID (Beds):** 2D Grid (Line L/R, Meter, Sub-row). Structured location tracking.
    - **C-ID (Crates):** Simple list of species stored in the crate.
- **Scanning Logic:**
  - **S-ID:** Open Species card, show its locations.
  - **P-ID:** (Deprecated) Notify user that individual plant tracking is no longer used.
  - **B-ID:** Show bed visual map, allow adding/removing species to cells.
  - **C-ID:** Show crate contents, allow adding/removing species from list.

## Development Environment
- **OS:** Linux (Fedora)
- **Flutter SDK Path:** `/home/work/flutter/bin`
- **Project Path:** `/home/work/QRostlina`
- **Environment Note:** Flutter has been added to `~/.bashrc`. If the `flutter` command is not found in a new session, ensure `/home/work/flutter/bin` is in the `PATH`.

## MVP Scope (Phase 1)
1. [x] Infrastructure, directory structure, git initialization.
2. [x] Create AGENT.md (this file).
3. [x] Flutter application skeleton (Android & Linux).
4. [x] High-contrast UI theme (Yellow/Black).
5. [x] Data Models (Species, Location with species mapping).
6. [x] QR Scanner Service & Mock Scanner Screen.
7. [x] Mock Database Service (In-memory + JSON persistence).
8. [x] Android SDK setup (Command Line Tools preferred).
9. [x] Script for Android deployment (`scripts/deploy_android.sh`).
10. [ ] Firebase integration (Auth & Firestore).
11. [x] Localization setup (English/Czech).
12. [x] Detailed Cards for Species (S-), Beds (B-), Crates (C-).
13. [x] Bed Visual Map & Crate Content List.
14. [x] CRUD for species and locations, plus species-location mapping.
15. [x] Visual Grid Map for Beds.
    - Status: Organized by meter, supports 2-column layout (Left/Right), human-friendly indexing (e.g. B-001-8M-2L), and species name display.
16. [x] Linear Bed Support.
    - Status: Support for "disorganized" beds with meter-only tracking.
