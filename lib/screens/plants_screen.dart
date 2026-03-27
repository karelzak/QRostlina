import 'package:flutter/material.dart';
import '../models/plant_unit.dart';
import '../models/species.dart';
import '../services/mock_database_service.dart';
import '../services/qr_scanner_service.dart';
import 'detail_screen.dart';
import 'edit_plant_screen.dart';

class PlantsScreen extends StatefulWidget {
  const PlantsScreen({super.key});

  @override
  State<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends State<PlantsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PlantUnit> _allPlants = [];
  Map<String, Species> _speciesMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final plants = await MockDatabaseService.getAllPlants();
    final speciesList = await MockDatabaseService.getAllSpecies();
    final speciesMap = {for (var s in speciesList) s.id: s};
    
    if (mounted) {
      setState(() {
        _allPlants = plants;
        _speciesMap = speciesMap;
        _isLoading = false;
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
        title: const Text('PLANTS'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'USED (IN FIELD/STOCK)'),
            Tab(text: 'UNUSED (NO LOC)'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPlantsList(used: true),
                _buildPlantsList(used: false),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const EditPlantScreen()),
          );
          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPlantsList({required bool used}) {
    final filteredPlants = _allPlants.where((p) {
      if (used) {
        return p.locationId != null;
      } else {
        return p.locationId == null;
      }
    }).toList();

    if (filteredPlants.isEmpty) {
      return Center(
        child: Text(
          used ? 'No plants in field or crates.' : 'No unused plants.',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredPlants.length,
      itemBuilder: (context, index) {
        final plant = filteredPlants[index];
        final species = _speciesMap[plant.speciesId];
        
        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(
              '${plant.id} - ${species?.name ?? "Unknown Species"}',
              style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Status: ${plant.status.toUpperCase()} | Loc: ${plant.locationId ?? "NONE"}',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(plant.id),
                ),
                const Icon(Icons.chevron_right, color: Colors.yellow),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailScreen(id: plant.id, type: ScannedType.plant),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Plant?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete $id?', style: const TextStyle(color: Colors.white70)),
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
      await MockDatabaseService.deletePlant(id);
      _loadData();
    }
  }
}
