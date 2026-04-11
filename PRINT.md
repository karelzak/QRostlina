# Printing Support Plan - Brother PT-E920BT

This document outlines the strategy for implementing label printing support using Brother industrial printers.

## 1. Requirements & Goals
- **Target Printer:** Brother PT-E920BT (Bluetooth connectivity).
- **Template System:** Use `.blf` (Binary Label Format) files exported from Brother P-touch Editor.
- **Cloud Integration:** Templates stored in Firebase Cloud Storage; metadata in Firestore for sharing between users.
- **Offline Reliability:** Templates and settings should be cached locally.
- **Data to Print:** Species Name and Species ID (as QR code).

## 2. Technical Stack
- **Library:** `another_brother` v2.2.4 (Flutter wrapper for Brother SDK v4).
- **Connectivity:** Bluetooth Classic (preferred, provides MAC address directly).
- **Permissions:** `permission_handler` for Bluetooth and Location (required for BT discovery on Android).

## 3. Known Issues & Workarounds

### PT-E920BT Model Not in SDK
The `another_brother` v2.2.4 `Model` enum does **not** include PT-E920BT.
- **Workaround:** Use `Model.PT_P910BT` as the closest compatible model (same 36mm tape, BT, PT label printer series).
- **Discovery:** Add `"PT-E920BT"` as an extra string to the BT discovery filter list. The SDK's `getBluetoothPrinters()` matches device name prefixes.
- **Device name:** Android sees it as `PT-E920BT3764` (with serial suffix). The `_modelFromName()` helper maps names starting with `PT-E920` to `PT_P910BT`.

### Discovery Results
- **Bluetooth Classic** finds the printer reliably (returns model name + MAC address).
- **BLE** returns 0 results for this printer — not needed since Classic works.
- **Network** returns 0 results — expected for BT-only setup.

## 4. SDK API Reference (Verified)

### Template Transfer
```dart
// Transfer .blf template file to printer (one-time per template)
Future<PrinterStatus> printer.transfer(String filepath);
// Supports .pdz (BT/USB) and .blf (all interfaces)
```

### P-touch Template Printing Workflow
```dart
// 1. Set up printer connection
final printer = Printer();
final printInfo = PrinterInfo();
printInfo.printerModel = Model.PT_P910BT;
printInfo.port = Port.BLUETOOTH;
printInfo.macAddress = "94:DD:F8:A9:2C:AF";
await printer.setPrinterInfo(printInfo);

// 2. Transfer template (one-time, printer stores it)
await printer.transfer('/path/to/template.blf');

// 3. Start template mode (key = template number in .blf)
bool started = await printer.startPTTPrint(1, "UTF-8");

// 4. Replace all well-known objects (no-op if missing in template)
await printer.replaceTextName(species.name, "NAME");
await printer.replaceTextName(species.name, "NAME1");
await printer.replaceTextName(species.name, "NAME2");
await printer.replaceTextName(species.id, "QR");
await printer.replaceTextName(species.id, "QR1");
await printer.replaceTextName(species.id, "QR2");
await printer.replaceTextName(species.id, "ID");
await printer.replaceTextName(userNote, "NOTE");

// 5. Print
PrinterStatus status = await printer.flushPTTPrint();
```

### Available Replacement Methods
| Method | Signature | Purpose |
|--------|-----------|---------|
| `replaceText` | `(String data)` | Replace next object by number order |
| `replaceTextIndex` | `(String data, int index)` | Replace object by index |
| `replaceTextName` | `(String data, String objectName)` | Replace object by name (preferred) |

### Object Naming Convention
Templates in P-touch Editor must use these object names. The app tries all of them on every print — objects not present in the template are silently skipped.

| Object Name | Data Source | Type | Description |
|-------------|-----------|------|-------------|
| `NAME` | `species.name` | Text | Species name |
| `NAME1` | `species.name` | Text | Species name (flag label, left side) |
| `NAME2` | `species.name` | Text | Species name (flag label, right side) |
| `QR` | `species.id` | QR Code | QR code with species ID |
| `QR1` | `species.id` | QR Code | QR code (flag label, left side) |
| `QR2` | `species.id` | QR Code | QR code (flag label, right side) |
| `ID` | `species.id` | Text | Species ID as plain text |
| `NOTE` | User input | Text | Per-label note typed before printing |
| `DATE` | *(auto)* | Date/Time | Auto-filled by printer, not replaced by app |

### QR Code / Barcode Replacement
- **No dedicated barcode/QR method exists.** `replaceTextName()` is used for all object types.
- In P-touch Editor, QR/barcode objects must be named (e.g., `QR1`) to be replaceable.
- **Status:** Needs real-device verification to confirm QR data updates correctly.

### Important: No `TemplateObjectReplacer` Class
The `another_brother` SDK does **NOT** have a `TemplateObjectReplacer` class. Replacement is done directly via `Printer` methods (`replaceTextName`, etc.).

### Template File Formats
- **`.lbx`** — P-touch Editor project file (ZIP with XML). Source format for editing.
- **`.blf`** — Binary Label Format for transfer to printer via SDK. Export via P-touch Transfer Manager.
- **`.pdz`** — Alternative transfer format (BT/USB only).
- Source `.lbx` files are stored in `print-templates/` for reference.

### PrinterInfo Template Settings
| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `numberOfCopies` | `int` | 1 | Number of copies to print |
| `useCopyCommandInTemplatePrint` | `bool` | false | Use copy commands in template print |

## 5. Data Models

### PrintTemplate
```dart
class PrintTemplate {
  final String id;
  final String name;
  final String localPath;  // Path in app documents directory
  final String tapeSize;   // e.g., "36mm", "24mm", "12mm"

  // No per-template field mappings needed.
  // The app tries all well-known object names on every print
  // (see Object Naming Convention above).
}
```

## 6. Architecture

### A. Printing Service (`lib/services/printing_service.dart`)
- `Future<void> initialize()`: Request permissions and setup SDK.
- `Future<List<DiscoveredPrinter>> discoverPrinters()`: Search for nearby Brother printers via BT/BLE/Network. Results cached in `lastDiscoveredPrinters`.
- `Future<bool> printSpecies(Species species, ...)`:
  1. Connect to printer via saved MAC address.
  2. Transfer template to printer.
  3. `startPTTPrint(1, "UTF-8")` to select template.
  4. `replaceTextName(data, objectName)` for each field.
  5. `flushPTTPrint()` to print.

### B. UI
- **Settings Screen** — PRINTING tab:
  - Discover button + printer list (tap to select, persisted to SharedPreferences).
  - Template management (Add/Delete from local storage).
- **Species Detail Screen** — Print icon in AppBar (Species only).
- **Species Printing Screen** — Template selection, printer status, PRINT button.

## 7. Implementation Phases

### Phase 1: Setup & Discovery ✅
- [x] Add `another_brother` and `permission_handler` to `pubspec.yaml`.
- [x] Create `PrintingService` interface and `BrotherPrintingService` implementation.
- [x] Bluetooth discovery with PT-E920BT model mapping.
- [x] Printer selection UI in Settings (discover-first flow).
- [x] Discovery results persist in service singleton across screen navigations.
- [x] Printer selection saved to SharedPreferences (MAC, name, model ID).

### Phase 2: Template Management ✅
- [x] Create `PrintTemplate` model (`lib/models/print_template.dart`).
- [x] Pick `.blf` file from device, copy to app documents `templates/` directory.
- [x] Template list in Settings PRINTING tab (add/delete).
- [x] Store template metadata as JSON in app documents.
- [ ] (Later) Cloud sync: upload to Firebase Storage, metadata in Firestore.

### Phase 3: Printing Logic ✅
- [x] Implement the P-touch Template workflow (`transfer` → `startPTTPrint` → `replaceTextName` → `flushPTTPrint`).
- [x] Object naming convention: try all well-known names (NAME, QR1, NOTE, etc.) on every print.
- [x] Per-label NOTE field: user-provided text entered before printing.
- [x] Auto-discover printer if none saved at print time.
- [ ] Verify QR code replacement works on real device.
- [ ] Handle errors (printer offline, low battery, wrong tape size).

### Phase 4: UI Completion ✅
- [x] Add print icon to `DetailScreen` AppBar (Species only).
- [x] Create `SpeciesPrintingScreen` (`lib/screens/species_printing_screen.dart`).
  - Species info card, printer status with re-discover button.
  - Template dropdown, NOTE text field, large PRINT button.
- [ ] "Last used template" persistence.

## 8. Open Questions
- **QR Code in Template:** Needs real-device test to confirm `replaceTextName` updates QR code data in `.blf` when the object is set as replaceable with protocol QR.
- **Template IDs:** Plan: always use Template ID `1` and overwrite. Simple, sufficient for single-species printing.
- **Tape Size:** Should the app detect or validate tape size compatibility before printing?
- **Template transfer frequency:** Does the printer retain templates after power cycle, or do we need to re-transfer each session?
