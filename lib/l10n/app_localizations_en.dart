// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'QRostlina';

  @override
  String get scanQrCode => 'SCAN QR CODE';

  @override
  String get speciesList => 'SPECIES LIST';

  @override
  String get locations => 'LOCATIONS';

  @override
  String get manualIdEntry => 'MANUAL ID ENTRY (e.g. S-001)';

  @override
  String get submitId => 'SUBMIT ID';

  @override
  String get cameraOnlyMobile =>
      'Camera only available on Android/iOS.\nUse manual input below for Linux testing.';

  @override
  String get scanned => 'Scanned';

  @override
  String get addNewSpecies => 'ADD NEW SPECIES';
}
