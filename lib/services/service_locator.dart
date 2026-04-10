import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'local_storage_service.dart';
import 'firestore_database_service.dart';
import 'printing_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late SharedPreferences _prefs;
  late DatabaseService _dbService;
  late PrintingService _printService;
  
  static const String _storageModeKey = 'storage_mode';
  static const String _modeLocal = 'local';
  static const String _modeCloud = 'cloud';

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _initDatabaseService();
    _printService = BrotherPrintingService();
    await _printService.initialize();
  }

  Future<void> _initDatabaseService() async {
    final mode = _prefs.getString(_storageModeKey) ?? _modeLocal;
    
    if (mode == _modeCloud) {
      _dbService = FirestoreDatabaseService();
    } else {
      _dbService = LocalStorageService();
    }
    
    await _dbService.initialize();
  }

  DatabaseService get db => _dbService;
  PrintingService get print => _printService;

  bool get isCloudMode => _prefs.getString(_storageModeKey) == _modeCloud;

  Future<void> setStorageMode(bool cloud) async {
    await _prefs.setString(_storageModeKey, cloud ? _modeCloud : _modeLocal);
    await _initDatabaseService();
  }
}

// Global accessor
final locator = ServiceLocator();
