enum ScannedType {
  species,  // S-
  plant,    // P-
  bed,      // B-
  crate,    // C-
  unknown,
}

class QRResult {
  final String id;
  final ScannedType type;

  QRResult({required this.id, required this.type});
}

class QRScannerService {
  /// Parses a raw scanned string into a QRResult.
  /// Standard format: [PREFIX]-[ID] (e.g., S-001)
  static QRResult parse(String code) {
    if (code.startsWith('S-')) {
      return QRResult(id: code, type: ScannedType.species);
    } else if (code.startsWith('P-')) {
      return QRResult(id: code, type: ScannedType.plant);
    } else if (code.startsWith('B-')) {
      return QRResult(id: code, type: ScannedType.bed);
    } else if (code.startsWith('C-')) {
      return QRResult(id: code, type: ScannedType.crate);
    } else {
      return QRResult(id: code, type: ScannedType.unknown);
    }
  }

  /// Navigates to the appropriate screen based on the QR result.
  /// (To be implemented once screens are created)
  static void routeResult(QRResult result) {
    // Logic will be added here to navigate to correct Detail/Card screens
  }
}
