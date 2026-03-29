import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_cs.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('cs'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'QRostlina'**
  String get appTitle;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'SCAN QR CODE'**
  String get scanQrCode;

  /// No description provided for @speciesList.
  ///
  /// In en, this message translates to:
  /// **'SPECIES'**
  String get speciesList;

  /// No description provided for @locations.
  ///
  /// In en, this message translates to:
  /// **'LOCATIONS'**
  String get locations;

  /// No description provided for @manualIdEntry.
  ///
  /// In en, this message translates to:
  /// **'MANUAL ID ENTRY (e.g. S-001)'**
  String get manualIdEntry;

  /// No description provided for @submitId.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT ID'**
  String get submitId;

  /// No description provided for @cameraOnlyMobile.
  ///
  /// In en, this message translates to:
  /// **'Camera only available on Android/iOS.\nUse manual input below for Linux testing.'**
  String get cameraOnlyMobile;

  /// No description provided for @scanned.
  ///
  /// In en, this message translates to:
  /// **'Scanned'**
  String get scanned;

  /// No description provided for @addNewSpecies.
  ///
  /// In en, this message translates to:
  /// **'ADD NEW SPECIES'**
  String get addNewSpecies;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settings;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'GENERAL'**
  String get general;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'DATA'**
  String get data;

  /// No description provided for @auth.
  ///
  /// In en, this message translates to:
  /// **'AUTH'**
  String get auth;

  /// No description provided for @access.
  ///
  /// In en, this message translates to:
  /// **'ACCESS'**
  String get access;

  /// No description provided for @cloudMode.
  ///
  /// In en, this message translates to:
  /// **'CLOUD MODE'**
  String get cloudMode;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'SIGN OUT'**
  String get signOut;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN WITH GOOGLE'**
  String get signInWithGoogle;

  /// No description provided for @storageStatus.
  ///
  /// In en, this message translates to:
  /// **'STORAGE STATUS:'**
  String get storageStatus;

  /// No description provided for @dumpData.
  ///
  /// In en, this message translates to:
  /// **'DUMP ALL DATA (JSON)'**
  String get dumpData;

  /// No description provided for @restoreData.
  ///
  /// In en, this message translates to:
  /// **'RESTORE ALL DATA (JSON)'**
  String get restoreData;

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'CLOUD SYNC:'**
  String get cloudSync;

  /// No description provided for @pushToCloud.
  ///
  /// In en, this message translates to:
  /// **'PUSH LOCAL DATA TO CLOUD'**
  String get pushToCloud;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'RESTORE'**
  String get restore;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'REMOVE'**
  String get remove;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get save;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'CAMERA'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'GALLERY'**
  String get gallery;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'PHOTO'**
  String get photo;

  /// No description provided for @idExists.
  ///
  /// In en, this message translates to:
  /// **'ID {id} already exists!'**
  String idExists(String id);

  /// No description provided for @authorize.
  ///
  /// In en, this message translates to:
  /// **'AUTHORIZE'**
  String get authorize;

  /// No description provided for @authorizeUser.
  ///
  /// In en, this message translates to:
  /// **'Authorize User'**
  String get authorizeUser;

  /// No description provided for @authorizeNewEmail.
  ///
  /// In en, this message translates to:
  /// **'AUTHORIZE NEW EMAIL'**
  String get authorizeNewEmail;

  /// No description provided for @noUsersAuthorized.
  ///
  /// In en, this message translates to:
  /// **'No users authorized yet'**
  String get noUsersAuthorized;

  /// No description provided for @removeUser.
  ///
  /// In en, this message translates to:
  /// **'Remove User?'**
  String get removeUser;

  /// No description provided for @removeUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {email} from authorized users?'**
  String removeUserConfirm(String email);

  /// No description provided for @clearLocation.
  ///
  /// In en, this message translates to:
  /// **'Clear Location?'**
  String get clearLocation;

  /// No description provided for @clearLocationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove ALL species from this location?'**
  String get clearLocationConfirm;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'YES, CLEAR ALL'**
  String get clearAll;

  /// No description provided for @createNew.
  ///
  /// In en, this message translates to:
  /// **'CREATE NEW'**
  String get createNew;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @changeSpecies.
  ///
  /// In en, this message translates to:
  /// **'Change Species'**
  String get changeSpecies;

  /// No description provided for @removeDied.
  ///
  /// In en, this message translates to:
  /// **'Remove (Died)'**
  String get removeDied;

  /// No description provided for @meters.
  ///
  /// In en, this message translates to:
  /// **'{count} Meters'**
  String meters(int count);

  /// No description provided for @grid.
  ///
  /// In en, this message translates to:
  /// **'Grid (2 Lines)'**
  String get grid;

  /// No description provided for @linear.
  ///
  /// In en, this message translates to:
  /// **'Linear (Meters only)'**
  String get linear;

  /// No description provided for @density.
  ///
  /// In en, this message translates to:
  /// **'{rows}x{cols} ({total} per meter)'**
  String density(int rows, int cols, int total);

  /// No description provided for @deleteLocation.
  ///
  /// In en, this message translates to:
  /// **'Delete Location?'**
  String get deleteLocation;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export {type} (CSV)'**
  String export(String type);

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import {type} (CSV)'**
  String import(String type);

  /// No description provided for @scannerNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Scanner not available on Desktop.'**
  String get scannerNotAvailable;

  /// No description provided for @invalidLabelType.
  ///
  /// In en, this message translates to:
  /// **'Invalid label type. Expected {type}'**
  String invalidLabelType(String type);

  /// No description provided for @notSpeciesQr.
  ///
  /// In en, this message translates to:
  /// **'Not a Species QR code (S-xxx expected)'**
  String get notSpeciesQr;

  /// No description provided for @noMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found.'**
  String get noMatchesFound;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @latin.
  ///
  /// In en, this message translates to:
  /// **'Latin'**
  String get latin;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @length.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get length;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @notUsedInLocation.
  ///
  /// In en, this message translates to:
  /// **'Not used in any location.'**
  String get notUsedInLocation;

  /// No description provided for @crateIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Crate is empty.'**
  String get crateIsEmpty;

  /// No description provided for @noBedsFound.
  ///
  /// In en, this message translates to:
  /// **'No beds found.'**
  String get noBedsFound;

  /// No description provided for @noCratesFound.
  ///
  /// In en, this message translates to:
  /// **'No crates found.'**
  String get noCratesFound;

  /// No description provided for @noSpeciesFound.
  ///
  /// In en, this message translates to:
  /// **'No species found.'**
  String get noSpeciesFound;

  /// No description provided for @deleteSpecies.
  ///
  /// In en, this message translates to:
  /// **'Delete Species?'**
  String get deleteSpecies;

  /// No description provided for @deleteSpeciesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {id}? This will also remove all its location references!'**
  String deleteSpeciesConfirm(String id);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['cs', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'cs':
      return AppLocalizationsCs();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
