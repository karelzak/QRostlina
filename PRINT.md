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

// 4. Replace named objects — signature: (data, objectName)
await printer.replaceTextName(species.name, "txt_name");
await printer.replaceTextName(species.id, "qr_id");

// 5. Print
PrinterStatus status = await printer.flushPTTPrint();
```

### Available Replacement Methods
| Method | Signature | Purpose |
|--------|-----------|---------|
| `replaceText` | `(String data)` | Replace next object by number order |
| `replaceTextIndex` | `(String data, int index)` | Replace object by index |
| `replaceTextName` | `(String data, String objectName)` | Replace object by name (preferred) |

### QR Code / Barcode Replacement
- **No dedicated barcode/QR method exists.** `replaceTextName()` is the only way.
- The Brother P-touch Template system treats all named replaceable objects uniformly — text, barcodes, and QR codes are all replaced via `replaceTextName()`.
- **Requirement:** In P-touch Editor, the QR/barcode object must be set as "replaceable" and given a name (e.g., `qr_id`).
- **Status:** Needs real-device verification to confirm QR data updates correctly.

### Important: No `TemplateObjectReplacer` Class
The `another_brother` SDK does **NOT** have a `TemplateObjectReplacer` class. Replacement is done directly via `Printer` methods (`replaceTextName`, etc.).

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
  final Map<String, String> fieldMappings; // Object Name in P-touch -> Field in Species

  PrintTemplate({
    required this.id,
    required this.name,
    required this.localPath,
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

### Phase 2: Template Management
- [ ] Create `PrintTemplate` model.
- [ ] Pick `.blf` file from device, copy to app documents directory.
- [ ] Template list in Settings PRINTING tab (add/delete).
- [ ] Store template metadata in SharedPreferences (or JSON).
- [ ] (Later) Cloud sync: upload to Firebase Storage, metadata in Firestore.

### Phase 3: Printing Logic
- [ ] Implement the P-touch Template workflow (`transfer` → `startPTTPrint` → `replaceTextName` → `flushPTTPrint`).
- [ ] Verify QR code replacement works on real device.
- [ ] Handle errors (printer offline, low battery, wrong tape size).
- [ ] Auto-discover printer if not connected at print time.

### Phase 4: UI Completion
- [ ] Add print icon to `DetailScreen` (Species only).
- [ ] Create `SpeciesPrintingScreen` with template selection.
- [ ] "Last used template" persistence.

## 8. Open Questions
- **QR Code in Template:** Needs real-device test to confirm `replaceTextName` updates QR code data in `.blf` when the object is set as replaceable with protocol QR.
- **Template IDs:** Plan: always use Template ID `1` and overwrite. Simple, sufficient for single-species printing.
- **Tape Size:** Should the app detect or validate tape size compatibility before printing?
- **Template transfer frequency:** Does the printer retain templates after power cycle, or do we need to re-transfer each session?
