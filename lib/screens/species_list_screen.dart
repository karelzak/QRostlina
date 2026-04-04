import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../models/species.dart';
import '../services/service_locator.dart';
import '../services/qr_scanner_service.dart';
import '../services/csv_service.dart';
import '../services/local_image_service.dart';
import 'detail_screen.dart';
import 'edit_species_screen.dart';

class SpeciesListScreen extends StatefulWidget {
  const SpeciesListScreen({super.key});

  @override
  State<SpeciesListScreen> createState() => _SpeciesListScreenState();
}

class _SpeciesListScreenState extends State<SpeciesListScreen> {
  List<Species>? _species;
  Map<String, int> _bedCounts = {};
  Map<String, int> _crateCounts = {};
  Map<String, File?> _localThumbnails = {};
  bool _loading = true;
  bool _countsLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshList(showLoading: true);
  }

  Future<void> _refreshList({bool showLoading = false}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _countsLoading = true;
      });
    }

    final species = await locator.db.getAllSpecies();
    species.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    
    // Create new local versions of data
    Map<String, File?> newLocalThumbnails = {};
    for (var s in species) {
      if (s.photoUrl != null && !LocalImageService.isRemoteUrl(s.photoUrl!)) {
        final file = await LocalImageService.getLocalFile(s.photoUrl!);
        newLocalThumbnails[s.id] = file;
      }
    }

    if (mounted) {
      setState(() {
        _species = species;
        _localThumbnails = newLocalThumbnails;
        _loading = false;
        // Keep _countsLoading = true for now, load counts next
      });
    }

    final beds = await locator.db.getAllBeds();
    final crates = await locator.db.getAllCrates();

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

  void _confirmDelete(String id, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(l10n.deleteSpecies, style: const TextStyle(color: Colors.white)),
        content: Text(
          l10n.deleteSpeciesConfirm(id),
          style: const TextStyle(color: Colors.white70),
        ),
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
      await locator.db.deleteSpecies(id);
      _refreshList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.speciesList),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'export') {
                await CSVService.exportSpecies();
              } else if (value == 'import') {
                final count = await CSVService.importSpecies();
                if (count > 0) {
                  _refreshList();
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'export', child: Text(l10n.export)),
              PopupMenuItem(value: 'import', child: Text(l10n.import)),
            ],
          ),
        ],
      ),
      body: _loading && _species == null
          ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
          : _species == null || _species!.isEmpty
              ? Center(child: Text(l10n.noSpeciesFound, style: const TextStyle(color: Colors.white70)))
              : ListView.builder(
                  key: const PageStorageKey('species_list'),
                  itemCount: _species!.length,
                  itemBuilder: (context, index) {
                    final s = _species![index];
                    final bedCount = _bedCounts[s.id] ?? 0;
                    final crateCount = _crateCounts[s.id] ?? 0;

                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: _buildThumbnail(s),
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
                              onPressed: () => _confirmDelete(s.id, l10n),
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

  Widget _buildThumbnail(Species species) {
    if (species.photoUrl == null) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: const Icon(Icons.local_florist, color: Colors.white24, size: 30),
      );
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow.withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: LocalImageService.isRemoteUrl(species.photoUrl!)
            ? CachedNetworkImage(
                imageUrl: species.photoUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 120, // Low-res cache for list performance
                memCacheHeight: 120,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.yellow)),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.red),
              )
            : _localThumbnails[species.id] != null
                ? Image.file(
                    _localThumbnails[species.id]!,
                    fit: BoxFit.cover,
                    cacheWidth: 120, // Low-res cache for list performance
                    cacheHeight: 120,
                  )
                : const Icon(Icons.image, color: Colors.white12),
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
