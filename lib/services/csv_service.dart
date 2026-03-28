import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/species.dart';
import '../models/location.dart';
import 'mock_database_service.dart';

class CSVService {
  static Future<void> exportSpecies() async {
    final species = await MockDatabaseService.getAllSpecies();
    List<List<dynamic>> rows = [
      ['ID', 'Name', 'Latin Name', 'Color', 'Description']
    ];

    for (var s in species) {
      rows.add([s.id, s.name, s.latinName ?? '', s.color ?? '', s.description ?? '']);
    }

    await _saveCSV(rows, 'species_export.csv');
  }

  static Future<void> exportBeds() async {
    final beds = await MockDatabaseService.getAllBeds();
    List<List<dynamic>> rows = [
      ['ID', 'Name', 'Label', 'Length', 'RowsPerMeter', 'Layout', 'SpeciesMap']
    ];

    for (var b in beds) {
      rows.add([
        b.id,
        b.name,
        b.row ?? '',
        b.length,
        b.rowsPerMeter,
        b.layout.name,
        jsonEncode(b.speciesMap)
      ]);
    }

    await _saveCSV(rows, 'beds_export.csv');
  }

  static Future<void> exportCrates() async {
    final crates = await MockDatabaseService.getAllCrates();
    List<List<dynamic>> rows = [
      ['ID', 'Name', 'Type', 'SpeciesIDs']
    ];

    for (var c in crates) {
      rows.add([c.id, c.name, c.type, c.speciesIds.join(';')]);
    }

    await _saveCSV(rows, 'crates_export.csv');
  }

  static Future<int> importSpecies() async {
    final rows = await _pickAndReadCSV();
    if (rows == null || rows.isEmpty) return 0;

    int count = 0;
    // Skip header
    for (int i = 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.length < 2) continue;

      final s = Species(
        id: r[0].toString().trim(),
        name: r[1].toString().trim(),
        latinName: r.length > 2 && r[2].toString().isNotEmpty ? r[2].toString() : null,
        color: r.length > 3 && r[3].toString().isNotEmpty ? r[3].toString() : null,
        description: r.length > 4 && r[4].toString().isNotEmpty ? r[4].toString() : null,
      );
      await MockDatabaseService.addSpecies(s);
      count++;
    }
    return count;
  }

  static Future<int> importBeds() async {
    final rows = await _pickAndReadCSV();
    if (rows == null || rows.isEmpty) return 0;

    int count = 0;
    for (int i = 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.length < 6) continue;

      try {
        final speciesMapRaw = r.length > 6 ? r[6].toString() : '{}';
        final Map<String, dynamic> decodedMap = jsonDecode(speciesMapRaw);
        
        final b = Bed(
          id: r[0].toString().trim(),
          name: r[1].toString().trim(),
          row: r[2].toString().isNotEmpty ? r[2].toString() : null,
          length: int.tryParse(r[3].toString()) ?? 10,
          rowsPerMeter: int.tryParse(r[4].toString()) ?? 2,
          layout: BedLayout.values.byName(r[5].toString().trim().toLowerCase()),
          speciesMap: Map<String, String>.from(decodedMap),
        );
        await MockDatabaseService.saveLocation(b);
        count++;
      } catch (e) {
        debugPrint('Error importing bed row $i: $e');
      }
    }
    return count;
  }

  static Future<int> importCrates() async {
    final rows = await _pickAndReadCSV();
    if (rows == null || rows.isEmpty) return 0;

    int count = 0;
    for (int i = 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.length < 3) continue;

      final speciesIdsRaw = r.length > 3 ? r[3].toString() : '';
      final speciesIds = speciesIdsRaw.split(';').where((s) => s.isNotEmpty).toList();

      final c = Crate(
        id: r[0].toString().trim(),
        name: r[1].toString().trim(),
        type: r[2].toString().trim(),
        speciesIds: speciesIds,
      );
      await MockDatabaseService.saveLocation(c);
      count++;
    }
    return count;
  }

  static Future<void> _saveCSV(List<List<dynamic>> rows, String defaultName) async {
    String csv = const ListToCsvConverter().convert(rows);
    
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
       // On mobile we might want to save to documents or use share
       final directory = await getApplicationDocumentsDirectory();
       final file = File('${directory.path}/$defaultName');
       await file.writeAsString(csv);
       debugPrint('Exported to ${file.path}');
       // Ideally use share_plus here, but we'll stick to basic file for now
    } else {
      // Desktop / Linux
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV Export',
        fileName: defaultName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(csv);
      }
    }
  }

  static Future<List<List<dynamic>>?> _pickAndReadCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final input = await file.readAsString();
      return const CsvToListConverter().convert(input);
    }
    return null;
  }
}
