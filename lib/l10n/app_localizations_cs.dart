// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appTitle => 'QRostlina';

  @override
  String get scanQrCode => 'SKENOVAT QR KÓD';

  @override
  String get speciesList => 'ODRŮDY';

  @override
  String get locations => 'UMÍSTĚNÍ';

  @override
  String get manualIdEntry => 'MANUÁLNÍ ZADÁNÍ (např. S-001)';

  @override
  String get submitId => 'ODESLAT ID';

  @override
  String get cameraOnlyMobile =>
      'Kamera je dostupná pouze na Android/iOS.\nPro testování na Linuxu použijte manuální vstup.';

  @override
  String get scanned => 'Naskenováno';

  @override
  String get addNewSpecies => 'PŘIDAT NOVOU ODRŮDU';
}
