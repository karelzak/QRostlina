import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../models/print_template.dart';
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
  bool _isDiscovering = false;

  static const String _printerMacKey = 'printer_mac';
  static const String _printerNameKey = 'printer_name';
  static const String _printerModelIdKey = 'printer_model_id';
  String _savedPrinterMac = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadPath();
    _loadPrinterSettings();
    _loadTemplates();
  }

  Future<void> _loadPrinterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPrinterMac = prefs.getString(_printerMacKey) ?? '';
    });
  }

  Future<void> _savePrinter(String mac, String name, {int modelId = -1}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_printerMacKey, mac);
    await prefs.setString(_printerNameKey, name);
    if (modelId >= 0) {
      await prefs.setInt(_printerModelIdKey, modelId);
    }
    setState(() {
      _savedPrinterMac = mac;
      _statusMessage = 'Saved: $name';
    });
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
    final l10n = AppLocalizations.of(context)!;
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
        title: Text(l10n.restore, style: const TextStyle(color: Colors.white)),
        content: Text(
          '${l10n.restoreData} ${result.files.single.name}. Continue?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.restore, style: const TextStyle(color: Colors.red)),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          isScrollable: true,
          tabs: [
            Tab(text: l10n.general),
            Tab(text: l10n.data),
            Tab(text: l10n.auth),
            Tab(text: l10n.access),
            const Tab(text: 'PRINTING'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(l10n),
          _buildDataTab(l10n),
          _buildAuthTab(l10n),
          _buildAccessTab(l10n),
          _buildPrintingTab(l10n),
        ],
      ),
    );
  }

  Widget _buildGeneralTab(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(l10n.cloudMode, style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
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

  Widget _buildAuthTab(AppLocalizations l10n) {
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
                  label: Text(l10n.signOut),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                ),
              ] else ...[
                const Icon(Icons.cloud_off, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  l10n.auth,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                  label: Text(l10n.signInWithGoogle),
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

  Widget _buildDataTab(AppLocalizations l10n) {
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
                    Text(l10n.storageStatus, style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
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
              label: Text(l10n.dumpData),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 80)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _import,
              icon: const Icon(Icons.download),
              label: Text(l10n.restoreData),
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
              Text(l10n.cloudSync, style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
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
                label: Text(l10n.pushToCloud),
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

  Widget _buildAccessTab(AppLocalizations l10n) {
    if (!locator.isCloudMode) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                l10n.access,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Whitelist management is only available in Cloud mode.',
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<List<String>>(
      future: locator.db.getAuthorizedUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final emailController = TextEditingController();
                  final result = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: Text(l10n.authorizeUser, style: const TextStyle(color: Colors.white)),
                      content: TextField(
                        controller: emailController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'user@gmail.com',
                          hintStyle: TextStyle(color: Colors.white24),
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
                        TextButton(
                          onPressed: () => Navigator.pop(context, emailController.text),
                          child: Text(l10n.authorize),
                        ),
                      ],
                    ),
                  );

                  if (result != null && result.isNotEmpty) {
                    try {
                      await locator.db.authorizeUser(result);
                      setState(() => _statusMessage = 'Authorized $result');
                    } catch (e) {
                      setState(() => _statusMessage = 'Authorization failed: $e');
                    }
                  }
                },
                icon: const Icon(Icons.person_add),
                label: Text(l10n.authorizeNewEmail),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: users.isEmpty
                  ? Center(child: Text(l10n.noUsersAuthorized, style: const TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final email = users[index];
                        return ListTile(
                          leading: const Icon(Icons.person, color: Colors.yellow),
                          title: Text(email, style: const TextStyle(color: Colors.white)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.grey[900],
                                  title: Text(l10n.removeUser, style: const TextStyle(color: Colors.white)),
                                  content: Text(l10n.removeUserConfirm(email), style: const TextStyle(color: Colors.white70)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text(l10n.remove, style: const TextStyle(color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                try {
                                  await locator.db.deauthorizeUser(email);
                                  setState(() => _statusMessage = 'Deauthorized $email');
                                } catch (e) {
                                  setState(() => _statusMessage = 'Deauthorization failed: $e');
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  List<PrintTemplate> _templates = [];

  Future<void> _loadTemplates() async {
    final templates = await locator.print.getTemplates();
    if (mounted) setState(() => _templates = templates);
  }

  Future<void> _addTemplate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (result == null || result.files.single.path == null) return;
    final filePath = result.files.single.path!;
    final fileName = result.files.single.name;
    final ext = fileName.toLowerCase();

    if (!ext.endsWith('.blf') && !ext.endsWith('.pdz')) {
      if (!mounted) return;
      final hint = ext.endsWith('.lbx')
          ? 'This is a P-touch Editor project file.\nExport it as .blf via Transfer Manager first.'
          : 'Only .blf and .pdz files are supported.';
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Unsupported File', style: TextStyle(color: Colors.redAccent)),
          content: Text(hint, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;

    // Ask for template name and tape size
    final nameController = TextEditingController(text: fileName.replaceAll(RegExp(r'\.(blf|pdz)$', caseSensitive: false), ''));
    String tapeSize = '36mm';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Add Template', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Template Name',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: tapeSize,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tape Size',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                items: const [
                  DropdownMenuItem(value: '6mm', child: Text('6mm')),
                  DropdownMenuItem(value: '9mm', child: Text('9mm')),
                  DropdownMenuItem(value: '12mm', child: Text('12mm')),
                  DropdownMenuItem(value: '18mm', child: Text('18mm')),
                  DropdownMenuItem(value: '24mm', child: Text('24mm')),
                  DropdownMenuItem(value: '36mm', child: Text('36mm')),
                ],
                onChanged: (v) => setDialogState(() => tapeSize = v!),
              ),
              const SizedBox(height: 12),
              Text('File: $fileName', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add', style: TextStyle(color: Colors.yellow)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await locator.print.addTemplate(filePath, nameController.text, tapeSize);
      await _loadTemplates();
      setState(() => _statusMessage = 'Template added: ${nameController.text}');
    } catch (e) {
      setState(() => _statusMessage = 'Failed to add template: $e');
    }
  }

  Future<void> _deleteTemplate(PrintTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Template?', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${template.name}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await locator.print.deleteTemplate(template.id);
    await _loadTemplates();
    setState(() => _statusMessage = 'Deleted: ${template.name}');
  }

  void _discoverPrinters() async {
    setState(() {
      _isDiscovering = true;
      _statusMessage = 'Discovering printers...';
    });

    try {
      await locator.print.discoverPrinters();
      setState(() {
        _isDiscovering = false;
        _statusMessage = 'Found ${locator.print.lastDiscoveredPrinters.length} printers';
      });
    } catch (e) {
      setState(() {
        _isDiscovering = false;
        _statusMessage = 'Discovery failed: $e';
      });
    }
  }

  Widget _buildPrintingTab(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isDiscovering ? null : _discoverPrinters,
              icon: _isDiscovering
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.bluetooth_searching),
              label: const Text('DISCOVER PRINTERS'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            ),
            const SizedBox(height: 16),
            if (locator.print.lastDiscoveredPrinters.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: locator.print.lastDiscoveredPrinters.length,
                itemBuilder: (context, index) {
                  final printer = locator.print.lastDiscoveredPrinters[index];
                  bool isSelected = _savedPrinterMac == printer.macAddress;
                  return ListTile(
                    tileColor: isSelected ? Colors.yellow.withValues(alpha: 0.1) : Colors.grey[900],
                    title: Text(printer.name, style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text(printer.macAddress,
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.yellow)
                      : const Icon(Icons.radio_button_unchecked, color: Colors.white24),
                    onTap: () {
                      _savePrinter(printer.macAddress, printer.name, modelId: printer.model.getId());
                    },
                  );
                },
              )
            else if (!_isDiscovering)
              const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No printers found yet. Tap Discover to scan.',
                  style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
              )),
            const SizedBox(height: 24),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TEMPLATES', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.yellow),
                  onPressed: _addTemplate,
                ),
              ],
            ),
            if (_templates.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _templates.length,
                itemBuilder: (context, index) {
                  final template = _templates[index];
                  return ListTile(
                    tileColor: Colors.grey[900],
                    leading: const Icon(Icons.description, color: Colors.white54),
                    title: Text(template.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(template.tapeSize, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteTemplate(template),
                    ),
                  );
                },
              )
            else
              const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No templates. Tap + to add a .blf file from P-touch Editor.',
                  style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
              )),
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
