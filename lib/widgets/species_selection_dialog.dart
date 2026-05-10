import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../l10n/app_localizations.dart';
import '../models/species.dart';
import '../services/qr_scanner_service.dart';
import '../services/service_locator.dart';
import 'search_dialog.dart';

class SpeciesSelectionDialog extends StatefulWidget {
  final String title;

  const SpeciesSelectionDialog({super.key, required this.title});

  static Future<void> addToHistory(String id) async {
    final prefs = locator.prefs;
    List<String> history = prefs.getStringList('species_history') ?? [];
    history.remove(id);
    history.insert(0, id);
    if (history.length > 10) history = history.sublist(0, 10);
    await prefs.setStringList('species_history', history);
  }

  @override
  State<SpeciesSelectionDialog> createState() => _SpeciesSelectionDialogState();
}

class _SpeciesSelectionDialogState extends State<SpeciesSelectionDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MobileScannerController _scannerController = MobileScannerController();
  List<Species> _allSpecies = [];
  List<Species> _historySpecies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final all = await locator.db.getAllSpecies();
    all.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    
    final historyIds = locator.prefs.getStringList('species_history') ?? [];
    final history = <Species>[];
    for (var id in historyIds) {
      final s = all.where((element) => element.id == id).firstOrNull;
      if (s != null) history.add(s);
    }

    if (mounted) {
      setState(() {
        _allSpecies = all;
        _historySpecies = history;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onSelected(String id) {
    SpeciesSelectionDialog.addToHistory(id);
    Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Text(widget.title, style: const TextStyle(color: Colors.yellow)),
      ),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: double.maxFinite,
        height: 450,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.yellow,
              labelColor: Colors.yellow,
              unselectedLabelColor: Colors.white54,
              tabs: [
                Tab(icon: const Icon(Icons.qr_code_scanner), text: l10n.scan),
                Tab(icon: const Icon(Icons.history), text: l10n.recent),
                Tab(icon: const Icon(Icons.search), text: l10n.search),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(), // Prevent accidental swipes during scanning
                children: [
                  _buildScannerTab(l10n),
                  _buildHistoryTab(l10n),
                  _buildSearchTab(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel, style: const TextStyle(color: Colors.yellow)),
        ),
      ],
    );
  }

  Widget _buildScannerTab(AppLocalizations l10n) {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(l10n.scannerNotAvailable, 
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final code = barcodes.first.rawValue;
                if (code != null) {
                  final result = QRScannerService.parse(code);
                  if (result.type == ScannedType.species) {
                    _onSelected(result.id);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.notSpeciesQr)),
                    );
                  }
                }
              }
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black,
          child: Text(l10n.scanQrCode, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildHistoryTab(AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Colors.yellow));
    if (_historySpecies.isEmpty) {
      return Center(child: Text(l10n.noMatchesFound, style: const TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      itemCount: _historySpecies.length,
      itemBuilder: (context, index) {
        final s = _historySpecies[index];
        return ListTile(
          title: Text(s.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(s.id, style: const TextStyle(color: Colors.white54)),
          onTap: () => _onSelected(s.id),
        );
      },
    );
  }

  Widget _buildSearchTab(AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Colors.yellow));
    
    // We can reuse logic or just implement simple search here to avoid deep nesting
    return _SearchSubTab(
      allSpecies: _allSpecies, 
      onSelected: _onSelected,
      l10n: l10n,
    );
  }
}

class _SearchSubTab extends StatefulWidget {
  final List<Species> allSpecies;
  final Function(String) onSelected;
  final AppLocalizations l10n;

  const _SearchSubTab({
    required this.allSpecies, 
    required this.onSelected,
    required this.l10n,
  });

  @override
  State<_SearchSubTab> createState() => _SearchSubTabState();
}

class _SearchSubTabState extends State<_SearchSubTab> {
  final TextEditingController _controller = TextEditingController();
  List<Species> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.allSpecies;
    _controller.addListener(_filter);
  }

  void _filter() {
    final query = _controller.text.toLowerCase();
    setState(() {
      _filtered = widget.allSpecies.where((s) {
        return s.name.toLowerCase().contains(query) || 
               s.id.toLowerCase().contains(query) ||
               (s.latinName?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: widget.l10n.search,
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.yellow),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filtered.length,
            itemBuilder: (context, index) {
              final s = _filtered[index];
              return ListTile(
                title: Text(s.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(s.id, style: const TextStyle(color: Colors.white54)),
                onTap: () => widget.onSelected(s.id),
              );
            },
          ),
        ),
      ],
    );
  }
}
