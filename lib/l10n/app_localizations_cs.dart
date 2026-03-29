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

  @override
  String get settings => 'NASTAVENÍ';

  @override
  String get general => 'OBECNÉ';

  @override
  String get data => 'DATA';

  @override
  String get auth => 'AUTENTIZACE';

  @override
  String get access => 'PŘÍSTUP';

  @override
  String get cloudMode => 'CLOUDOVÝ REŽIM';

  @override
  String get signOut => 'ODHLÁSIT SE';

  @override
  String get signInWithGoogle => 'PŘIHLÁSIT SE PŘES GOOGLE';

  @override
  String get storageStatus => 'STAV ÚLOŽIŠTĚ:';

  @override
  String get dumpData => 'EXPORTOVAT VŠECHNA DATA (JSON)';

  @override
  String get restoreData => 'OBNOVIT VŠECHNA DATA (JSON)';

  @override
  String get cloudSync => 'SYNCHRONIZACE S CLOUDEM:';

  @override
  String get pushToCloud => 'NAHRÁT LOKÁLNÍ DATA DO CLOUDU';

  @override
  String get cancel => 'ZRUŠIT';

  @override
  String get restore => 'OBNOVIT';

  @override
  String get delete => 'SMAZAT';

  @override
  String get remove => 'ODEBRAT';

  @override
  String get save => 'ULOŽIT';

  @override
  String get camera => 'FOTOAPARÁT';

  @override
  String get gallery => 'GALERIE';

  @override
  String get photo => 'FOTKA';

  @override
  String idExists(String id) {
    return 'ID $id již existuje!';
  }

  @override
  String get authorize => 'AUTORIZOVAT';

  @override
  String get authorizeUser => 'Autorizovat uživatele';

  @override
  String get authorizeNewEmail => 'AUTORIZOVAT NOVÝ EMAIL';

  @override
  String get noUsersAuthorized => 'Zatím žádní autorizovaní uživatelé';

  @override
  String get removeUser => 'Odebrat uživatele?';

  @override
  String removeUserConfirm(String email) {
    return 'Odebrat $email z autorizovaných uživatelů?';
  }

  @override
  String get clearLocation => 'Vyčistit umístění?';

  @override
  String get clearLocationConfirm =>
      'Opravdu chcete odebrat VŠECHNY odrůdy z tohoto umístění?';

  @override
  String get clearAll => 'ANO, VYČISTIT VŠE';

  @override
  String get createNew => 'VYTVOŘIT NOVÝ';

  @override
  String get viewDetails => 'Zobrazit detaily';

  @override
  String get changeSpecies => 'Změnit odrůdu';

  @override
  String get removeDied => 'Odebrat (uhynulo)';

  @override
  String meters(int count) {
    return '$count metrů';
  }

  @override
  String get grid => 'Mřížka (2 řádky)';

  @override
  String get linear => 'Lineární (pouze metry)';

  @override
  String density(int rows, int cols, int total) {
    return '${rows}x$cols ($total na metr)';
  }

  @override
  String get deleteLocation => 'Smazat umístění?';

  @override
  String export(String type) {
    return 'Exportovat $type (CSV)';
  }

  @override
  String import(String type) {
    return 'Importovat $type (CSV)';
  }

  @override
  String get scannerNotAvailable => 'Skener není dostupný na desktopu.';

  @override
  String invalidLabelType(String type) {
    return 'Neplatný typ štítku. Očekáváno $type';
  }

  @override
  String get notSpeciesQr => 'Toto není QR kód odrůdy (očekáváno S-xxx)';

  @override
  String get noMatchesFound => 'Nebyly nalezeny žádné výsledky.';

  @override
  String get name => 'Název';

  @override
  String get latin => 'Latinský název';

  @override
  String get color => 'Barva';

  @override
  String get description => 'Popis';

  @override
  String get length => 'Délka';

  @override
  String get type => 'Typ';

  @override
  String get label => 'Označení';

  @override
  String get noDescription => 'Bez popisu';

  @override
  String get notUsedInLocation => 'Není v žádném umístění.';

  @override
  String get crateIsEmpty => 'Přepravka je prázdná.';

  @override
  String get noBedsFound => 'Žádné záhony nenalezeny.';

  @override
  String get noCratesFound => 'Žádné přepravky nenalezeny.';

  @override
  String get noSpeciesFound => 'Žádné odrůdy nenalezeny.';

  @override
  String get deleteSpecies => 'Smazat odrůdu?';

  @override
  String deleteSpeciesConfirm(String id) {
    return 'Opravdu chcete smazat $id? Tím se také odstraní všechny odkazy na toto umístění!';
  }
}
