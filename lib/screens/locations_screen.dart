import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../l10n/app_localizations.dart';
import '../models/location.dart';
import '../services/service_locator.dart';
import '../services/qr_scanner_service.dart';
import 'detail_screen.dart';
import 'edit_location_screen.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Bed>? _beds;
  List<Crate>? _crates;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final beds = await locator.db.getAllBeds();
    final crates = await locator.db.getAllCrates();
    if (mounted) {
      setState(() {
        _beds = beds;
        _crates = crates;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.locations),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              final isBed = _tabController.index == 0;
              // Handle CSV import/export for current tab
            },
            itemBuilder: (context) {
              final type = _tabController.index == 0 ? l10n.beds : l10n.crates;
              return [
                PopupMenuItem(value: 'export', child: Text(l10n.export(type))),
                PopupMenuItem(value: 'import', child: Text(l10n.import(type))),
              ];
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          tabs: [
            Tab(text: l10n.beds.toUpperCase()),
            Tab(text: l10n.crates.toUpperCase()),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBedsList(l10n),
                _buildCratesList(l10n),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final isBed = _tabController.index == 0;
          final result = await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (context) => EditLocationScreen(isBed: isBed)),
          );
          if (result != null) _loadData();
        },
        backgroundColor: Colors.yellow,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildBedsList(AppLocalizations l10n) {
    if (_beds == null || _beds!.isEmpty) {
      return Center(child: Text(l10n.noBedsFound, style: const TextStyle(color: Colors.white70)));
    }
    return ListView.builder(
      itemCount: _beds!.length,
      itemBuilder: (context, index) {
        final bed = _beds![index];
        return ListTile(
          leading: const Icon(Icons.grid_view, color: Colors.yellow),
          title: Text(bed.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${bed.id} | ${l10n.label}: ${bed.row ?? "-"}', style: const TextStyle(color: Colors.white70)),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => _deleteLocation(bed.id, l10n),
          ),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailScreen(id: bed.id, type: ScannedType.bed))),
        );
      },
    );
  }

  Widget _buildCratesList(AppLocalizations l10n) {
    if (_crates == null || _crates!.isEmpty) {
      return Center(child: Text(l10n.noCratesFound, style: const TextStyle(color: Colors.white70)));
    }
    return ListView.builder(
      itemCount: _crates!.length,
      itemBuilder: (context, index) {
        final crate = _crates![index];
        return ListTile(
          leading: const Icon(Icons.inventory_2, color: Colors.yellow),
          title: Text(crate.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${crate.id} | ${l10n.type}: ${crate.type}', style: const TextStyle(color: Colors.white70)),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => _deleteLocation(crate.id, l10n),
          ),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailScreen(id: crate.id, type: ScannedType.crate))),
        );
      },
    );
  }

  void _deleteLocation(String id, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(l10n.deleteLocation, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await locator.db.deleteLocation(id);
      _loadData();
    }
  }
}
