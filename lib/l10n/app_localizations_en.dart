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
  String get speciesList => 'SPECIES';

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

  @override
  String get settings => 'SETTINGS';

  @override
  String get general => 'GENERAL';

  @override
  String get data => 'DATA';

  @override
  String get auth => 'AUTH';

  @override
  String get access => 'ACCESS';

  @override
  String get cloudMode => 'CLOUD MODE';

  @override
  String get signOut => 'SIGN OUT';

  @override
  String get signInWithGoogle => 'SIGN IN WITH GOOGLE';

  @override
  String get storageStatus => 'STORAGE STATUS:';

  @override
  String get dumpData => 'DUMP ALL DATA (JSON)';

  @override
  String get restoreData => 'RESTORE ALL DATA (JSON)';

  @override
  String get cloudSync => 'CLOUD SYNC:';

  @override
  String get pushToCloud => 'PUSH LOCAL DATA TO CLOUD';

  @override
  String get cancel => 'CANCEL';

  @override
  String get restore => 'RESTORE';

  @override
  String get delete => 'DELETE';

  @override
  String get remove => 'REMOVE';

  @override
  String get save => 'SAVE';

  @override
  String get camera => 'CAMERA';

  @override
  String get gallery => 'GALLERY';

  @override
  String get photo => 'PHOTO';

  @override
  String idExists(String id) {
    return 'ID $id already exists!';
  }

  @override
  String get authorize => 'AUTHORIZE';

  @override
  String get authorizeUser => 'Authorize User';

  @override
  String get authorizeNewEmail => 'AUTHORIZE NEW EMAIL';

  @override
  String get noUsersAuthorized => 'No users authorized yet';

  @override
  String get removeUser => 'Remove User?';

  @override
  String get clearLocation => 'Clear Location?';

  @override
  String get clearLocationConfirm =>
      'Are you sure you want to remove ALL species from this location?';

  @override
  String get clearAll => 'YES, CLEAR ALL';

  @override
  String get createNew => 'CREATE NEW';

  @override
  String get viewDetails => 'View Details';

  @override
  String get changeSpecies => 'Change Species';

  @override
  String get removeDied => 'Remove (Died)';

  @override
  String meters(int count) {
    return '$count Meters';
  }

  @override
  String get grid => 'Grid (2 Lines)';

  @override
  String get linear => 'Linear (Meters only)';

  @override
  String density(int rows, int cols, int total) {
    return '${rows}x$cols ($total per meter)';
  }

  @override
  String get deleteLocation => 'Delete Location?';

  @override
  String export(String type) {
    return 'Export $type (CSV)';
  }

  @override
  String import(String type) {
    return 'Import $type (CSV)';
  }

  @override
  String get scannerNotAvailable => 'Scanner not available on Desktop.';

  @override
  String invalidLabelType(String type) {
    return 'Invalid label type. Expected $type';
  }

  @override
  String get notSpeciesQr => 'Not a Species QR code (S-xxx expected)';

  @override
  String get noMatchesFound => 'No matches found.';
}
