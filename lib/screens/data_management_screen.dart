import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/mock_database_service.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  String _statusMessage = 'Ready';
  String _persistencePath = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadPath();
  }

  Future<void> _loadPath() async {
    final directory = await getApplicationDocumentsDirectory();
    if (mounted) {
      setState(() {
        _persistencePath = '${directory.path}/qrostlina_data.json';
      });
    }
  }

  Future<String> _getExportPath() async {
    // For Linux/Android simplicity, we use a fixed name in Documents
    Directory? docDir;
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
       // On desktop, getApplicationDocumentsDirectory is usually ~/Documents
       docDir = await getApplicationDocumentsDirectory();
    } else {
       // On Android, we might want to use external storage, but for now internal is safer
       docDir = await getApplicationDocumentsDirectory();
    }
    return '${docDir.path}/qrostlina_export.json';
  }

  void _export() async {
    try {
      final path = await _getExportPath();
      await MockDatabaseService.exportData(path);
      setState(() => _statusMessage = 'Exported to $path');
    } catch (e) {
      setState(() => _statusMessage = 'Export failed: $e');
    }
  }

  void _import() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Import Data?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will OVERWRITE all current data with the contents of qrostlina_export.json. Continue?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('IMPORT', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final path = await _getExportPath();
        await MockDatabaseService.importData(path);
        setState(() => _statusMessage = 'Imported successfully from $path');
      } catch (e) {
        setState(() => _statusMessage = 'Import failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DATA MANAGEMENT')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CURRENT STORAGE:', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    SelectableText(_persistencePath, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _export,
              icon: const Icon(Icons.upload),
              label: const Text('EXPORT TO DOCUMENTS'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 80)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _import,
              icon: const Icon(Icons.download),
              label: const Text('IMPORT FROM DOCUMENTS'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 80),
                backgroundColor: Colors.orange,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
