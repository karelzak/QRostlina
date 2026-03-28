import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/species.dart';
import '../services/mock_database_service.dart';
import '../services/qr_scanner_service.dart';
import 'detail_screen.dart';
import 'edit_species_screen.dart';

class SpeciesListScreen extends StatefulWidget {
  const SpeciesListScreen({super.key});

  @override
  State<SpeciesListScreen> createState() => _SpeciesListScreenState();
}

class _SpeciesListScreenState extends State<SpeciesListScreen> {
  late Future<List<Species>> _speciesList;
  Map<String, int> _bedCounts = {};
  Map<String, int> _crateCounts = {};
  bool _countsLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  Future<void> _refreshList() async {
    setState(() {
      _speciesList = MockDatabaseService.getAllSpecies();
      _countsLoading = true;
    });

    final beds = await MockDatabaseService.getAllBeds();
    final crates = await MockDatabaseService.getAllCrates();

    final bedCounts = <String, int>{};
    final crateCounts = <String, int>{};

    for (var bed in beds) {
      bed.speciesMap.forEach((key, sId) {
        final cleanId = sId.trim();
        bedCounts[cleanId] = (bedCounts[cleanId] ?? 0) + 1;
      });
    }

    for (var crate in crates) {
      for (var sId in crate.speciesIds) {
        final cleanId = sId.trim();
        crateCounts[cleanId] = (crateCounts[cleanId] ?? 0) + 1;
      }
    }

    if (mounted) {
      setState(() {
        _bedCounts = bedCounts;
        _crateCounts = crateCounts;
        _countsLoading = false;
      });
    }
  }

  void _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Species?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete $id? This will also remove all its location references!',
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
      await MockDatabaseService.deleteSpecies(id);
      _refreshList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.speciesList)),
      body: FutureBuilder<List<Species>>(
        future: _speciesList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.yellow));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No species found.', style: TextStyle(color: Colors.white70)));
          }

          final species = snapshot.data!;
          return ListView.builder(
            itemCount: species.length,
            itemBuilder: (context, index) {
              final s = species[index];
              final bedCount = _bedCounts[s.id] ?? 0;
              final crateCount = _crateCounts[s.id] ?? 0;

              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    s.name.toUpperCase(),
                    style: const TextStyle(color: Colors.yellow, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.id, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 4),
                      if (!_countsLoading)
                        Row(
                          children: [
                            _countBadge(Icons.grid_view, bedCount.toString(), Colors.orange),
                            const SizedBox(width: 8),
                            _countBadge(Icons.inventory_2, crateCount.toString(), Colors.blue),
                          ],
                        )
                      else
                        const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.yellow)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _confirmDelete(s.id),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.yellow),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(id: s.id, type: ScannedType.species),
                      ),
                    );
                    await _refreshList();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<dynamic>(
            context,
            MaterialPageRoute(builder: (context) => const EditSpeciesScreen()),
          );
          if (result != null) {
            _refreshList();
          }
        },
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _countBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
