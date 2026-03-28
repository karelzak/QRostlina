import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/species.dart';
import '../models/location.dart';
import 'database_service.dart';
import 'qr_scanner_service.dart';

class FirestoreDatabaseService implements DatabaseService {
  bool _initialized = false;
  FirebaseFirestore? _firestore;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    // Firebase on Linux is not fully supported for Firestore/Auth/Storage easily.
    // We should check platform before initializing.
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp();
        }
        _firestore = FirebaseFirestore.instance;
        _initialized = true;
      } catch (e) {
        debugPrint('Failed to initialize Firebase: $e');
      }
    } else {
      debugPrint('Firestore is not supported on this platform (${Platform.operatingSystem})');
    }
  }

  FirebaseFirestore get _db {
    if (_firestore == null) {
      throw Exception('Firestore not initialized. Ensure you are on a supported platform and have initialized Firebase.');
    }
    return _firestore!;
  }

  @override
  Future<bool> isIdUnique(String id) async {
    final type = QRScannerService.parse(id).type;
    String collection;
    switch (type) {
      case ScannedType.species: collection = 'species'; break;
      case ScannedType.bed: collection = 'beds'; break;
      case ScannedType.crate: collection = 'crates'; break;
      default: return true;
    }
    
    final doc = await _db.collection(collection).doc(id).get();
    return !doc.exists;
  }

  @override
  Future<String> generateNextId(ScannedType type) async {
    // For Firestore, we might want a different strategy, but for consistency:
    String prefix;
    String collection;
    switch (type) {
      case ScannedType.species: prefix = 'S-'; collection = 'species'; break;
      case ScannedType.bed: prefix = 'B-'; collection = 'beds'; break;
      case ScannedType.crate: prefix = 'C-'; collection = 'crates'; break;
      default: throw Exception('Unknown type');
    }

    final query = await _db.collection(collection)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: prefix)
        .where(FieldPath.documentId, isLessThan: '${prefix}z')
        .get();

    int maxId = 0;
    for (var doc in query.docs) {
      final id = doc.id;
      final numericPart = id.substring(prefix.length);
      final val = int.tryParse(numericPart) ?? 0;
      if (val > maxId) maxId = val;
    }

    return '$prefix${(maxId + 1).toString().padLeft(3, '0')}';
  }

  @override
  Future<List<Species>> getAllSpecies() async {
    final snapshot = await _db.collection('species').get();
    return snapshot.docs.map((doc) => Species.fromMap({...doc.data(), 'id': doc.id})).toList();
  }

  @override
  Future<List<Bed>> getAllBeds() async {
    final snapshot = await _db.collection('beds').get();
    return snapshot.docs.map((doc) => Bed.fromMap({...doc.data(), 'id': doc.id})).toList();
  }

  @override
  Future<List<Crate>> getAllCrates() async {
    final snapshot = await _db.collection('crates').get();
    return snapshot.docs.map((doc) => Crate.fromMap({...doc.data(), 'id': doc.id})).toList();
  }

  @override
  Future<Species?> getSpeciesById(String id) async {
    final doc = await _db.collection('species').doc(id).get();
    if (!doc.exists) return null;
    return Species.fromMap({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<Bed?> getBedById(String id) async {
    final doc = await _db.collection('beds').doc(id).get();
    if (!doc.exists) return null;
    return Bed.fromMap({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<Crate?> getCrateById(String id) async {
    final doc = await _db.collection('crates').doc(id).get();
    if (!doc.exists) return null;
    return Crate.fromMap({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<bool> speciesExists(String id) async {
    final doc = await _db.collection('species').doc(id).get();
    return doc.exists;
  }

  @override
  Future<bool> locationExists(String id) async {
    final collection = id.startsWith('B-') ? 'beds' : 'crates';
    final doc = await _db.collection(collection).doc(id).get();
    return doc.exists;
  }

  @override
  Future<void> addSpecies(Species species) async {
    await _db.collection('species').doc(species.id).set(species.toMap());
  }

  @override
  Future<void> deleteSpecies(String id) async {
    // Delete from species collection
    await _db.collection('species').doc(id).delete();
    
    // In a real app, we might use a Cloud Function to clean up references,
    // but here we'll do it manually for simplicity (this is slow if there are many beds)
    // Note: Transaction/Batch would be better.
    final beds = await _db.collection('beds').get();
    for (var bedDoc in beds.docs) {
      final bed = Bed.fromMap({...bedDoc.data(), 'id': bedDoc.id});
      if (bed.speciesMap.values.contains(id)) {
        bed.speciesMap.removeWhere((key, value) => value == id);
        await bedDoc.reference.update({'speciesMap': bed.speciesMap});
      }
    }
    
    final crates = await _db.collection('crates').get();
    for (var crateDoc in crates.docs) {
      final crate = Crate.fromMap({...crateDoc.data(), 'id': crateDoc.id});
      if (crate.speciesIds.contains(id)) {
        crate.speciesIds.remove(id);
        await crateDoc.reference.update({'speciesIds': crate.speciesIds});
      }
    }
  }

  @override
  Future<void> deleteLocation(String id) async {
    final collection = id.startsWith('B-') ? 'beds' : 'crates';
    await _db.collection(collection).doc(id).delete();
  }

  @override
  Future<void> saveLocation(Location location) async {
    if (location is Bed) {
      await _db.collection('beds').doc(location.id).set(location.toMap());
    } else if (location is Crate) {
      await _db.collection('crates').doc(location.id).set(location.toMap());
    }
  }

  @override
  Future<List<String>> getLocationsForSpecies(String speciesId) async {
    List<String> locations = [];
    
    final beds = await _db.collection('beds').get();
    for (var doc in beds.docs) {
      final bed = Bed.fromMap({...doc.data(), 'id': doc.id});
      bed.speciesMap.forEach((key, sId) {
        if (sId == speciesId) {
          final parts = key.split('-');
          final line = int.tryParse(parts[0]);
          final row = int.tryParse(parts[1]);
          locations.add(bed.formatPosition(line, row));
        }
      });
    }

    final crates = await _db.collection('crates').where('speciesIds', arrayContains: speciesId).get();
    for (var doc in crates.docs) {
      locations.add(doc.id);
    }

    return locations;
  }

  @override
  Future<void> setSpeciesAtBedCell(String bedId, int line, int row, String? speciesId) async {
    final docRef = _db.collection('beds').doc(bedId);
    final doc = await docRef.get();
    if (doc.exists) {
      final bed = Bed.fromMap({...doc.data()!, 'id': doc.id});
      final key = "$line-$row";
      if (speciesId == null) {
        bed.speciesMap.remove(key);
      } else {
        bed.speciesMap[key] = speciesId;
      }
      await docRef.update({'speciesMap': bed.speciesMap});
    }
  }

  @override
  Future<void> addSpeciesToCrate(String crateId, String speciesId) async {
    await _db.collection('crates').doc(crateId).update({
      'speciesIds': FieldValue.arrayUnion([speciesId])
    });
  }

  @override
  Future<void> removeSpeciesFromCrate(String crateId, String speciesId) async {
    await _db.collection('crates').doc(crateId).update({
      'speciesIds': FieldValue.arrayRemove([speciesId])
    });
  }

  @override
  Future<void> clearLocation(String id) async {
    final collection = id.startsWith('B-') ? 'beds' : 'crates';
    final field = id.startsWith('B-') ? 'speciesMap' : 'speciesIds';
    final value = id.startsWith('B-') ? {} : [];
    await _db.collection(collection).doc(id).update({field: value});
  }

  @override
  Future<void> exportData(String path) async {
    // This is more complex for Firestore, but we could implement it by fetching all data
    // and writing to JSON. For now, we'll focus on the core functionality.
    debugPrint('Export from Firestore to JSON not implemented yet.');
  }

  @override
  Future<void> importData(String path) async {
    final file = File(path);
    if (!await file.exists()) throw Exception('Import file not found');
    
    final content = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(content);

    final batch = _db.batch();

    if (data.containsKey('species')) {
      for (var s in data['species']) {
        batch.set(_db.collection('species').doc(s['id']), s);
      }
    }
    if (data.containsKey('beds')) {
      for (var b in data['beds']) {
        batch.set(_db.collection('beds').doc(b['id']), b);
      }
    }
    if (data.containsKey('crates')) {
      for (var c in data['crates']) {
        batch.set(_db.collection('crates').doc(c['id']), c);
      }
    }
    
    await batch.commit();
  }
}
