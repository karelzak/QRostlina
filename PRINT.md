# Printing Support Plan - Brother PT-E920BT

This document outlines the strategy for implementing label printing support using Brother industrial printers.

## 1. Requirements & Goals
- **Target Printer:** Brother PT-E920BT (Bluetooth connectivity).
- **Template System:** Use `.blf` (Binary Label Format) files exported from Brother P-touch Editor.
- **Cloud Integration:** Templates stored in Firebase Cloud Storage; metadata in Firestore for sharing between users.
- **Offline Reliability:** Templates and settings should be cached locally.
- **Data to Print:** Species Name and Species ID (as QR code).

## 2. Technical Stack
- **Library:** `another_brother` (Flutter wrapper for Brother SDK v4).
- **Connectivity:** Bluetooth (Classic/BLE).
- **Permissions:** `permission_handler` for Bluetooth and Location (required for BT discovery on Android).

## 3. Data Models

### PrintTemplate
```dart
class PrintTemplate {
  final String id;
  final String name;
  final String storagePath; // Firebase Storage path
  final String tapeSize;    // e.g., "36mm", "24mm", "12mm"
  final Map<String, String> fieldMappings; // Object Name in P-touch -> Field in Species
  
  PrintTemplate({
    required this.id,
    required this.name,
    required this.storagePath,
    required this.tapeSize,
    this.fieldMappings = const {
      'txt_name': 'name',
      'qr_id': 'id',
    },
  });

  Map<String, dynamic> toMap() => { ... };
  factory PrintTemplate.fromMap(Map<String, dynamic> map) => { ... };
}
```

## 4. Proposed Architecture

### A. Printing Service (`lib/services/printing_service.dart`)
- `Future<void> initialize()`: Request permissions and setup SDK.
- `Future<List<BluetoothPrinter>> discoverPrinters()`: Search for nearby Brother printers.
- `Future<bool> printSpecies(Species species, PrintTemplate template)`:
  1. Download `.blf` if not cached.
  2. Connect to printer via MAC address.
  3. Transfer template to printer (ID 1).
  4. Use `TemplateObjectReplacer` to map species data to template objects.
     - **QR Codes:** The SDK's `replaceText` (via `TemplateObjectReplacer`) automatically updates the data within a barcode/QR code object if the object name matches.
  5. `printer.printTemplate(templateInfo, replacer)`.

### B. UI Changes
- **Settings Screen (`lib/screens/settings_screen.dart`):**
  - Add "Printing" tab.
  - Printer configuration (MAC address, Model selection).
  - Template management (Add/Delete/Sync).
- **Species Detail Screen (`lib/screens/detail_screen.dart`):**
  - Add a "Print" icon button in the AppBar (for Species only).
- **Species Printing Screen (`lib/screens/species_printing_screen.dart`):**
  - Show selected species info.
  - Dropdown to select a template.
  - Printer status indicator (Connected/Disconnected).
  - Large "PRINT" button.

## 5. Implementation Phases

### Phase 1: Setup & Discovery
- Add `another_brother` and `permission_handler` to `pubspec.yaml`.
- Create `PrintingService` interface and `BrotherPrintingService` implementation.
- Implement Bluetooth discovery and printer selection in Settings.

### Phase 2: Template Management
- Create `PrintTemplate` model.
- Add Firestore support for storing template metadata.
- Implement `.blf` upload to Firebase Storage in the Settings tab.
- Implement local caching of `.blf` files.

### Phase 3: Printing Logic
- Implement the "P-touch Template" workflow.
- Test field replacement (Text and QR code).
- Handle errors (printer offline, low battery, wrong tape size).

### Phase 4: UI Completion
- Add the print icon to `DetailScreen`.
- Create `SpeciesPrintingScreen` with template selection.
- Implement "Last used template" persistence.

## 6. Open Questions & Investigations
- **QR Code in Template:** Confirm that `replaceText` correctly updates QR code objects in `.blf` when the object's protocol is set to QR.
- **Template IDs:** Since we only print one species at a time, can we always use Template ID `1` on the printer and overwrite it, or should we manage multiple IDs? (Proposed: Overwrite ID `1` for simplicity).
- **Tape Size:** Should the app detect or validate tape size compatibility before printing?
