import 'package:flutter/material.dart';
import '../models/location.dart';
import '../services/mock_database_service.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBedsList(),
          _buildCratesList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final isBed = _tabController.index == 0;
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => EditLocationScreen(isBed: isBed),
            ),
          );
          if (result == true) {
            setState(() {});
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
          'Are you sure you want to delete $id? Plants at this location will be moved to "stock" (no location).',
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
      await MockDatabaseService.deleteLocation(id);
      setState(() {});
    }
  }

  Widget _buildBedsList() {
    return FutureBuilder<List<Bed>>(
      future: MockDatabaseService.getAllBeds(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.yellow));
        }
        final beds = snapshot.data ?? [];
        return ListView.builder(
          itemCount: beds.length,
          itemBuilder: (context, index) {
            final bed = beds[index];
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
                        'ERROR: LINEAR BUT 2 LINES',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              subtitle: Text('${bed.id} | Row: ${bed.row ?? "-"}', style: const TextStyle(color: Colors.white70)),
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailScreen(id: bed.id, type: ScannedType.bed),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCratesList() {
    return FutureBuilder<List<Crate>>(
      future: MockDatabaseService.getAllCrates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.yellow));
        }
        final crates = snapshot.data ?? [];
        return ListView.builder(
          itemCount: crates.length,
          itemBuilder: (context, index) {
            final crate = crates[index];
            return ListTile(
              leading: const Icon(Icons.inventory_2, color: Colors.yellow),
              title: Text(crate.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('${crate.id} | Type: ${crate.type}', style: const TextStyle(color: Colors.white70)),
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailScreen(id: crate.id, type: ScannedType.crate),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
