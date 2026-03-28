import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/service_locator.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _statusMessage = 'Ready';
  String _persistencePath = 'Loading...';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPath();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPath() async {
    final directory = await getApplicationDocumentsDirectory();
    if (mounted) {
      setState(() {
        _persistencePath = '${directory.path}/qrostlina_data.json';
      });
    }
  }

  void _export() async {
    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Full Data Dump',
        fileName: 'qrostlina_dump.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile != null) {
        await locator.db.exportData(outputFile);
        setState(() => _statusMessage = 'Dumped to file');
      }
    } catch (e) {
      setState(() => _statusMessage = 'Dump failed: $e');
    }
  }

  void _import() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Restore Data?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will OVERWRITE all current data with the contents of ${result.files.single.name}. Continue?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('RESTORE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await locator.db.importData(path);
        setState(() => _statusMessage = 'Restored successfully');
      } catch (e) {
        setState(() => _statusMessage = 'Restore failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          tabs: const [
            Tab(text: 'GENERAL'),
            Tab(text: 'DATA'),
            Tab(text: 'AUTH'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(),
          _buildDataTab(),
          _buildAuthTab(),
        ],
      ),
    );
  }

  Widget _buildGeneralTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('CLOUD MODE', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
            subtitle: Text(
              authService.isSupported 
                ? 'Enable Firestore & Cloud Storage' 
                : 'Not supported on this platform (${Platform.operatingSystem})',
              style: const TextStyle(color: Colors.white70),
            ),
            value: locator.isCloudMode,
            activeColor: Colors.yellow,
            onChanged: authService.isSupported ? (val) async {
              await locator.setStorageMode(val);
              setState(() {});
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthTab() {
    return StreamBuilder<User?>(
      stream: authService.userStream,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (user != null) ...[
                CircleAvatar(
                  radius: 40,
                  backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                  child: user.photoURL == null ? const Icon(Icons.person, size: 40) : null,
                ),
                const SizedBox(height: 16),
                Text(user.displayName ?? 'Cloud User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(user.email ?? '', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    await authService.signOut();
                    setState(() {});
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('SIGN OUT'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                ),
              ] else ...[
                const Icon(Icons.cloud_off, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                const Text(
                  'Google Cloud Authentication',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to sync your data across devices',
                  style: TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: authService.isSupported ? () async {
                    final result = await authService.signInWithGoogle();
                    if (result != null) {
                      setState(() => _statusMessage = 'Signed in as ${result.user?.displayName}');
                    } else {
                      setState(() => _statusMessage = 'Sign in failed or cancelled');
                    }
                  } : null,
                  icon: const Icon(Icons.login),
                  label: const Text('SIGN IN WITH GOOGLE'),
                ),
                if (!authService.isSupported)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'Authentication is not supported on this platform.',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
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
                    const Text('STORAGE STATUS:', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      locator.isCloudMode ? 'CLOUD (FIRESTORE)' : 'LOCAL (JSON FILE)',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      locator.isCloudMode ? 'Connected to Firebase' : _persistencePath,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _export,
              icon: const Icon(Icons.upload),
              label: const Text('DUMP ALL DATA (JSON)'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 80)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _import,
              icon: const Icon(Icons.download),
              label: const Text('RESTORE ALL DATA (JSON)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 80),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.black,
              ),
            ),
            if (locator.isCloudMode) ...[
              const SizedBox(height: 32),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              const Text('CLOUD SYNC:', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() => _statusMessage = 'Syncing local -> cloud...');
                  try {
                    // Temporary sync logic: export to temp, then import to cloud
                    final directory = await getTemporaryDirectory();
                    final path = '${directory.path}/sync_temp.json';
                    
                    // Force local mode temporarily or just use LocalStorageService directly
                    final local = LocalStorageService();
                    await local.initialize();
                    await local.exportData(path);
                    
                    await locator.db.importData(path);
                    setState(() => _statusMessage = 'Sync to cloud complete');
                  } catch (e) {
                    setState(() => _statusMessage = 'Sync failed: $e');
                  }
                },
                icon: const Icon(Icons.cloud_upload),
                label: const Text('PUSH LOCAL DATA TO CLOUD'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  backgroundColor: Colors.blueGrey,
                ),
              ),
            ],
            const SizedBox(height: 40),
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
