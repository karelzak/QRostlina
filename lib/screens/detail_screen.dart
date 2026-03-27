import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/species.dart';
import '../models/plant_unit.dart';
import '../models/location.dart';
import '../services/mock_database_service.dart';
import '../services/qr_scanner_service.dart';
import 'edit_species_screen.dart';
import 'edit_plant_screen.dart';
import 'edit_location_screen.dart';

class DetailScreen extends StatefulWidget {
  final String id;
  final ScannedType type;

  const DetailScreen({super.key, required this.id, required this.type});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  dynamic _data;
  Location? _parentLocation;
  List<PlantUnit>? _children;
  Map<String, Species> _speciesMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    _speciesMap = {};
    
    switch (widget.type) {
      case ScannedType.species:
        _data = await MockDatabaseService.getSpeciesById(widget.id);
        if (_data != null) {
          _children = await MockDatabaseService.getPlantsBySpecies(widget.id);
          _speciesMap[widget.id] = _data as Species;
        }
        break;
      case ScannedType.plant:
        _data = await MockDatabaseService.getPlantById(widget.id);
        if (_data != null) {
          final p = _data as PlantUnit;
          final s = await MockDatabaseService.getSpeciesById(p.speciesId);
          if (s != null) _speciesMap[p.speciesId] = s;

          if (p.locationId != null) {
            final locId = p.locationId!;
            if (locId.startsWith('B-')) {
              _parentLocation = await MockDatabaseService.getBedById(locId);
            } else if (locId.startsWith('C-')) {
              _parentLocation = await MockDatabaseService.getCrateById(locId);
            }
          }
        }
        break;
      case ScannedType.bed:
        _data = await MockDatabaseService.getBedById(widget.id);
        if (_data != null) {
          _children = await MockDatabaseService.getPlantsByLocation(widget.id);
          // Fetch species for all plants in this bed
          if (_children != null) {
            for (var p in _children!) {
              if (!_speciesMap.containsKey(p.speciesId)) {
                final s = await MockDatabaseService.getSpeciesById(p.speciesId);
                if (s != null) _speciesMap[p.speciesId] = s;
              }
            }
          }
        }
        break;
      case ScannedType.crate:
        _data = await MockDatabaseService.getCrateById(widget.id);
        if (_data != null) {
          _children = await MockDatabaseService.getPlantsByLocation(widget.id);
          if (_children != null) {
            for (var p in _children!) {
              if (!_speciesMap.containsKey(p.speciesId)) {
                final s = await MockDatabaseService.getSpeciesById(p.speciesId);
                if (s != null) _speciesMap[p.speciesId] = s;
              }
            }
          }
        }
        break;
      case ScannedType.unknown:
        break;
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _confirmDeletePlant(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Plant Die?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete plant $id?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('YES, DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await MockDatabaseService.deletePlant(id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String title = '${widget.type.name.toUpperCase()}: ${widget.id}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (widget.type == ScannedType.species && _data != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (context) => EditSpeciesScreen(species: _data as Species)),
                );
                if (result == true) {
                  _loadData();
                }
              },
            ),
          if (widget.type == ScannedType.plant && _data != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (context) => EditPlantScreen(plant: _data as PlantUnit)),
                );
                if (result == true) {
                  _loadData();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _confirmDeletePlant(context, widget.id),
              tooltip: 'Mark as Dead/Delete',
            ),
          ],
          if ((widget.type == ScannedType.bed || widget.type == ScannedType.crate) && _data != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditLocationScreen(
                      location: _data as Location,
                      isBed: widget.type == ScannedType.bed,
                    ),
                  ),
                );
                if (result == true) {
                  _loadData();
                }
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
          : _data == null
              ? _buildNotFound(l10n)
              : _buildContent(l10n),
    );
  }

  Widget _buildNotFound(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            '${widget.type.name.toUpperCase()} ${widget.id} not found.',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              Widget screen;
              switch (widget.type) {
                case ScannedType.species:
                  screen = const EditSpeciesScreen();
                  break;
                case ScannedType.plant:
                  screen = const EditPlantScreen();
                  break;
                case ScannedType.bed:
                  screen = const EditLocationScreen(isBed: true);
                  break;
                case ScannedType.crate:
                  screen = const EditLocationScreen(isBed: false);
                  break;
                case ScannedType.unknown:
                  return;
              }
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (context) => screen),
              );
              if (result == true) {
                _loadData();
              }
            },
            child: const Text('CREATE NEW'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          if (_data is Bed) ...[
            const SizedBox(height: 24),
            const Text(
              'VISUAL MAP',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.yellow),
            ),
            const Divider(color: Colors.yellow),
            const SizedBox(height: 8),
            _buildGridMap(),
          ],
          if (_children != null && widget.type != ScannedType.bed) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.type == ScannedType.species ? 'INSTANCES' : 'CONTENTS',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.yellow),
                ),
                IconButton(
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditPlantScreen(
                          initialSpeciesId: widget.type == ScannedType.species ? widget.id : null,
                          plant: (widget.type == ScannedType.bed || widget.type == ScannedType.crate)
                              ? PlantUnit(
                                  id: 'P-',
                                  speciesId: 'S-',
                                  locationId: widget.id,
                                )
                              : null,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadData();
                    }
                  },
                  icon: const Icon(Icons.add, color: Colors.yellow, size: 32),
                ),
              ],
            ),
            const Divider(color: Colors.yellow),
            const SizedBox(height: 8),
            _buildChildrenList(),
          ],
        ],
      ),
    );
  }

  Widget _buildGridMap() {
    final bed = _data as Bed;
    final Map<String, PlantUnit> occupancy = {};
    if (_children != null) {
      for (var p in _children!) {
        if (p.gridRow != null) {
          final key = "${p.gridLine ?? 1}-${p.gridRow}";
          occupancy[key] = p;
        }
      }
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bed.length,
      itemBuilder: (context, meterIdx) {
        int meter = meterIdx + 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.straighten, color: Colors.yellow, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "METER $meter",
                    style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Expanded(child: Divider(indent: 16, color: Colors.white24)),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.8, // Slightly taller for bigger font
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 2 * bed.rowsPerMeterEffective,
              itemBuilder: (context, cellIdx) {
                // Determine line and sub-row within this meter
                int lineIdx = (cellIdx % 2) + 1;
                int subRow = (cellIdx / 2).floor() + 1;
                // Calculate absolute gridRow
                int rowIdx = (meter - 1) * bed.rowsPerMeterEffective + subRow;

                final key = "$lineIdx-$rowIdx";
                final plant = occupancy[key];
                final species = plant != null ? _speciesMap[plant.speciesId] : null;
                String cellLabel = bed.layout == BedLayout.grid ? "$subRow" : "";

                return GestureDetector(
                  onTap: () async {
                    if (plant != null) {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (context) => DetailScreen(id: plant.id, type: ScannedType.plant)),
                      );
                      if (result == true) _loadData();
                    } else {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPlantScreen(
                            plant: PlantUnit(
                              id: 'P-',
                              speciesId: 'S-',
                              locationId: bed.id,
                              gridLine: lineIdx,
                              gridRow: rowIdx,
                            ),
                          ),
                        ),
                      );
                      if (result == true) _loadData();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: plant != null ? Colors.yellow : Colors.grey[900],
                      border: Border.all(color: Colors.yellow, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 2,
                          left: 4,
                          child: Text(
                            cellLabel,
                            style: TextStyle(
                              fontSize: 14,
                              color: plant != null ? Colors.black54 : Colors.yellow.withOpacity(0.5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Center(
                          child: plant != null
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        plant.id,
                                        style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      Text(
                                        species?.name ?? plant.speciesId,
                                        style: const TextStyle(
                                          color: Colors.black, 
                                          fontSize: 14, 
                                          fontWeight: FontWeight.bold,
                                          overflow: TextOverflow.ellipsis
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                )
                              : const Icon(Icons.add, color: Colors.white10, size: 24),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard() {
    if (_data is Species) {
      final s = _data as Species;
      return Card(
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Name', s.name),
              _infoRow('Latin', s.latinName ?? '-'),
              _infoRow('Color', s.color ?? '-'),
              const SizedBox(height: 8),
              const Text('Description:', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
              Text(s.description ?? 'No description', style: const TextStyle(fontSize: 18)),
            ],
          ),
        ),
      );
    } else if (_data is PlantUnit) {
      final p = _data as PlantUnit;
      String locationStr = p.locationId ?? 'None';
      if (p.locationId != null && _parentLocation is Bed) {
        locationStr = (_parentLocation as Bed).formatPosition(p.gridLine, p.gridRow);
      }
      return Card(
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Species ID', p.speciesId),
              _infoRow('Status', p.status.toUpperCase()),
              _infoRow('Position', locationStr),
            ],
          ),
        ),
      );
    } else if (_data is Bed) {
      final b = _data as Bed;
      return Card(
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Name', b.name),
              _infoRow('Field Row', b.row ?? '-'),
              _infoRow('Length', '${b.length} Meters'),
              _infoRow('Layout', '${b.layout.name.toUpperCase()} (2 Lines x ${b.rowsPerMeterEffective} Rows/m)'),
              _infoRow('Total Cells', '${b.totalCells} cells'),
            ],
          ),
        ),
      );
    } else if (_data is Crate) {
      final c = _data as Crate;
      return Card(
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Name', c.name),
              _infoRow('Type', c.type),
            ],
          ),
        ),
      );
    }
    return const SizedBox();
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 18)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 18))),
        ],
      ),
    );
  }

  Widget _buildChildrenList() {
    if (_children == null || _children!.isEmpty) {
      return const Text('No items found.', style: TextStyle(fontStyle: FontStyle.italic));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _children!.length,
      itemBuilder: (context, index) {
        final plant = _children![index];
        String locStr = plant.locationId ?? '-';
        if (plant.locationId != null && _data is Bed) {
          locStr = (_data as Bed).formatPosition(plant.gridLine, plant.gridRow);
        }
        return ListTile(
          tileColor: Colors.grey[900],
          leading: const Icon(Icons.local_florist, color: Colors.yellow),
          title: Text(plant.id, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Status: ${plant.status.toUpperCase()} | $locStr'),
          trailing: const Icon(Icons.chevron_right, color: Colors.yellow),
          onTap: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(id: plant.id, type: ScannedType.plant),
              ),
            );
            if (result == true) {
              _loadData();
            }
          },
        );
      },
    );
  }
}
