import 'package:flutter/material.dart';
import '../models/location.dart';
import '../services/service_locator.dart';
import '../services/qr_scanner_service.dart';
import '../services/csv_service.dart';
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
    _refreshData(showLoading: true);
  }

  Future<void> _refreshData({bool showLoading = false}) async {
    if (showLoading) {
      setState(() => _loading = true);
    }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('LOCATIONS'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              final isBed = _tabController.index == 0;
              if (value == 'export') {
                if (isBed) {
                  await CSVService.exportBeds();
                } else {
                  await CSVService.exportCrates();
                }
              } else if (value == 'import') {
                final count = isBed ? await CSVService.importBeds() : await CSVService.importCrates();
                if (count > 0) {
                  _refreshData();
                }
              }
            },
            itemBuilder: (context) {
              final isBed = _tabController.index == 0;
              final type = isBed ? 'Beds' : 'Crates';
              return [
                PopupMenuItem(value: 'export', child: Text('Export $type (CSV)')),
                PopupMenuItem(value: 'import', child: Text('Import $type (CSV)')),
              ];
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'BEDS (B-)'),
            Tab(text: 'CRATES (C-)'),
          ],
        ),
      ),
      body: _loading && (_beds == null || _crates == null)
          ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBedsList(),
                _buildCratesList(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final isBed = _tabController.index == 0;
          final result = await Navigator.push<dynamic>(
            context,
            MaterialPageRoute(
              builder: (context) => EditLocationScreen(isBed: isBed),
            ),
          );
          if (result != null) {
            _refreshData();
          }
        },
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Location?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete $id? All species references at this location will be removed.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await locator.db.deleteLocation(id);
      _refreshData();
    }
  }

  Widget _buildBedsList() {
    final beds = _beds ?? [];
    return ListView.builder(
      key: const PageStorageKey('beds_list'),
      itemCount: beds.length,
      itemBuilder: (context, index) {
        final bed = beds[index];
        final uniqueSpeciesCount = bed.speciesMap.values.toSet().length;
        final totalOccupancy = bed.speciesMap.length;

        return ListTile(
          leading: const Icon(Icons.grid_view, color: Colors.yellow),
          title: Row(
            children: [
              Expanded(
                child: Text(bed.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              if (!bed.isConsistent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'DATA ERROR',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${bed.id} | Row: ${bed.row ?? "-"}', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Row(
                children: [
                  _countBadge('Species: $uniqueSpeciesCount', Colors.orange),
                  const SizedBox(width: 8),
                  _countBadge('Occupied: $totalOccupancy/${bed.totalCells}', Colors.green),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _confirmDelete(bed.id),
              ),
              const Icon(Icons.chevron_right, color: Colors.yellow),
            ],
          ),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(id: bed.id, type: ScannedType.bed),
              ),
            );
            _refreshData();
          },
        );
      },
    );
  }

  Widget _buildCratesList() {
    final crates = _crates ?? [];
    return ListView.builder(
      key: const PageStorageKey('crates_list'),
      itemCount: crates.length,
      itemBuilder: (context, index) {
        final crate = crates[index];
        final speciesCount = crate.speciesIds.length;

        return ListTile(
          leading: const Icon(Icons.inventory_2, color: Colors.yellow),
          title: Text(crate.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${crate.id} | Type: ${crate.type}', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              _countBadge('Species: $speciesCount', Colors.blue),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _confirmDelete(crate.id),
              ),
              const Icon(Icons.chevron_right, color: Colors.yellow),
            ],
          ),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(id: crate.id, type: ScannedType.crate),
              ),
            );
            _refreshData();
          },
        );
      },
    );
  }

  Widget _countBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
