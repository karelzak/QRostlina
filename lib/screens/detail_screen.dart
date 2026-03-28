import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../models/species.dart';
import '../models/location.dart';
import '../services/mock_database_service.dart';
import '../services/qr_scanner_service.dart';
import '../services/csv_service.dart';
import '../services/local_image_service.dart';
import '../widgets/search_dialog.dart';
import 'edit_species_screen.dart';
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
  List<String>? _locations; // For Species
  Map<String, Species> _speciesMap = {};
  bool _loading = true;
  File? _localPhotoFile;
  Map<String, File?> _localThumbnails = {};

  // Summary counts
  int _bedInstanceCount = 0;
  int _crateInstanceCount = 0;
  int _uniqueSpeciesInLocationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    _speciesMap = {};
    _bedInstanceCount = 0;
    _crateInstanceCount = 0;
    _uniqueSpeciesInLocationCount = 0;
    _localPhotoFile = null;
    _localThumbnails = {};

    switch (widget.type) {
      case ScannedType.species:
        _data = await MockDatabaseService.getSpeciesById(widget.id);
        if (_data != null) {
          final s = _data as Species;
          _locations = await MockDatabaseService.getLocationsForSpecies(widget.id);
          _speciesMap[widget.id] = s;

          if (s.photoUrl != null && !LocalImageService.isRemoteUrl(s.photoUrl!)) {
            _localPhotoFile = await LocalImageService.getLocalFile(s.photoUrl!);
          }

          for (var loc in _locations!) {
            if (loc.startsWith('B-')) {
              _bedInstanceCount++;
            } else if (loc.startsWith('C-')) {
              _crateInstanceCount++;
            }
          }
        }
        break;
      case ScannedType.bed:
        _data = await MockDatabaseService.getBedById(widget.id);
        if (_data != null) {
          final bed = _data as Bed;
          final uniqueIds = <String>{};
          for (var sId in bed.speciesMap.values) {
            uniqueIds.add(sId);
            if (!_speciesMap.containsKey(sId)) {
              final s = await MockDatabaseService.getSpeciesById(sId);
              if (s != null) _speciesMap[sId] = s;
            }
          }
          _uniqueSpeciesInLocationCount = uniqueIds.length;
          
          for (var s in _speciesMap.values) {
            if (s.photoUrl != null && !LocalImageService.isRemoteUrl(s.photoUrl!)) {
              _localThumbnails[s.id] = await LocalImageService.getLocalFile(s.photoUrl!);
            }
          }
        }
        break;
      case ScannedType.crate:
        _data = await MockDatabaseService.getCrateById(widget.id);
        if (_data != null) {
          final crate = _data as Crate;
          _uniqueSpeciesInLocationCount = crate.speciesIds.length;
          for (var sId in crate.speciesIds) {
            if (!_speciesMap.containsKey(sId)) {
              final s = await MockDatabaseService.getSpeciesById(sId);
              if (s != null) _speciesMap[sId] = s;
            }
          }

          for (var s in _speciesMap.values) {
            if (s.photoUrl != null && !LocalImageService.isRemoteUrl(s.photoUrl!)) {
              _localThumbnails[s.id] = await LocalImageService.getLocalFile(s.photoUrl!);
            }
          }
        }
        break;
      case ScannedType.plant:
        _data = null; 
        break;
      case ScannedType.unknown:
        break;
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _confirmClearLocation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Clear Location?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to remove ALL species from this location?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('YES, CLEAR ALL', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await MockDatabaseService.clearLocation(widget.id);
      _loadData();
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
                if (result == true) _loadData();
              },
            ),
          if ((widget.type == ScannedType.bed || widget.type == ScannedType.crate) && _data != null) ...[
             IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              onPressed: _confirmClearLocation,
              tooltip: 'Clear all species from this location',
            ),
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
                if (result == true) _loadData();
              },
            ),
          ],
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'export_all') {
                if (widget.type == ScannedType.species) {
                  await CSVService.exportSpecies();
                } else if (widget.type == ScannedType.bed) {
                  await CSVService.exportBeds();
                } else if (widget.type == ScannedType.crate) {
                  await CSVService.exportCrates();
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export_all',
                child: Text('Export All ${widget.type.name.toUpperCase()}S (CSV)'),
              ),
              const PopupMenuItem(
                value: 'log',
                enabled: false,
                child: Text('View Log (Soon)'),
              ),
              const PopupMenuItem(
                value: 'ai',
                enabled: false,
                child: Text('Chat with AI (Soon)'),
              ),
            ],
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
            widget.type == ScannedType.plant 
              ? 'Plant entities are no longer supported. Please scan a Species or Location.'
              : '${widget.type.name.toUpperCase()} ${widget.id} not found.',
            style: const TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (widget.type != ScannedType.plant)
            ElevatedButton(
              onPressed: () async {
                Widget screen;
                switch (widget.type) {
                  case ScannedType.species:
                    screen = const EditSpeciesScreen();
                    break;
                  case ScannedType.bed:
                    screen = const EditLocationScreen(isBed: true);
                    break;
                  case ScannedType.crate:
                    screen = const EditLocationScreen(isBed: false);
                    break;
                  default:
                    return;
                }
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (context) => screen),
                );
                if (result == true) _loadData();
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
            Row(
              children: [
                const Text(
                  'VISUAL MAP',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.yellow),
                ),
                const Spacer(),
                _countBadge(Icons.grid_view, '$_uniqueSpeciesInLocationCount Species', Colors.orange),
                const SizedBox(width: 8),
                _countBadge(Icons.check_circle_outline, '${(_data as Bed).speciesMap.length}/${(_data as Bed).totalCells}', Colors.green),
              ],
            ),
            const Divider(color: Colors.yellow),
            const SizedBox(height: 8),
            _buildGridMap(),
          ],
          if (widget.type == ScannedType.species) ...[
             const SizedBox(height: 24),
             Row(
               children: [
                 const Text(
                  'LOCATIONS',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.yellow),
                ),
                const Spacer(),
                _countBadge(Icons.grid_view, _bedInstanceCount.toString(), Colors.orange),
                const SizedBox(width: 8),
                _countBadge(Icons.inventory_2, _crateInstanceCount.toString(), Colors.blue),
               ],
             ),
            const Divider(color: Colors.yellow),
            const SizedBox(height: 8),
            _buildLocationsList(),
          ],
          if (_data is Crate) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'SPECIES IN CRATE',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.yellow),
                ),
                const Spacer(),
                _countBadge(Icons.local_florist, _uniqueSpeciesInLocationCount.toString(), Colors.blue),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addSpeciesToCrate,
                  icon: const Icon(Icons.add, color: Colors.yellow, size: 32),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(color: Colors.yellow),
            const SizedBox(height: 8),
            _buildCrateSpeciesList(),
          ],
        ],
      ),
    );
  }

  Widget _buildGridMap() {
    final bed = _data as Bed;

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
            if (bed.totalLines > 1)
              Row(
                children: [
                  Expanded(child: Center(child: Text("LEFT", style: TextStyle(color: Colors.yellow.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)))),
                  Expanded(child: Center(child: Text("RIGHT", style: TextStyle(color: Colors.yellow.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)))),
                ],
              )
            else
              Center(child: Text("CENTER", style: TextStyle(color: Colors.yellow.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold))),
            const SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: bed.totalLines,
                childAspectRatio: bed.totalLines == 1 ? 4.0 : 1.8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: bed.totalLines * bed.rowsPerMeterEffective,
              itemBuilder: (context, cellIdx) {
                int lineIdx = (cellIdx % bed.totalLines) + 1;
                int subRow = (cellIdx / bed.totalLines).floor() + 1;
                int rowIdx = (meter - 1) * bed.rowsPerMeterEffective + subRow;

                final key = "$lineIdx-$rowIdx";
                final speciesId = bed.speciesMap[key];
                final species = speciesId != null ? _speciesMap[speciesId] : null;
                
                String cellLabel = "";
                if (bed.layout == BedLayout.grid) {
                   String lineStr = lineIdx == 1 ? 'L' : 'R';
                   cellLabel = "$subRow$lineStr";
                } else {
                   cellLabel = "METER $meter";
                }

                return GestureDetector(
                  onLongPress: speciesId != null ? () async {
                    await MockDatabaseService.setSpeciesAtBedCell(bed.id, lineIdx, rowIdx, null);
                    _loadData();
                  } : null,
                  onTap: () async {
                    if (speciesId == null) {
                      _selectSpeciesForCell(lineIdx, rowIdx);
                    } else {
                      _showCellActions(lineIdx, rowIdx, speciesId);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: speciesId != null ? Colors.yellow : Colors.grey[900],
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
                              color: speciesId != null ? Colors.black54 : Colors.yellow.withOpacity(0.5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Center(
                          child: speciesId != null
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (species?.photoUrl != null) ...[
                                        _buildGridThumbnail(species!),
                                        const SizedBox(height: 2),
                                      ],
                                      Text(
                                        species?.name ?? speciesId,
                                        style: const TextStyle(
                                          color: Colors.black, 
                                          fontSize: 12, 
                                          fontWeight: FontWeight.bold,
                                          overflow: TextOverflow.ellipsis
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: species?.photoUrl != null ? 1 : 2,
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

  void _selectSpeciesForCell(int line, int row) async {
    final allSpecies = await MockDatabaseService.getAllSpecies();
    final items = allSpecies.map((s) => SearchItem(id: s.id, name: s.name, subtitle: s.latinName)).toList();

    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SearchDialog(title: 'SELECT SPECIES', items: items),
    );

    if (result != null && mounted) {
      await MockDatabaseService.setSpeciesAtBedCell(widget.id, line, row, result);
      _loadData();
    }
  }

  void _showCellActions(int line, int row, String currentSpeciesId) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cell ${(_data as Bed).formatPosition(line, row)}', 
              style: const TextStyle(color: Colors.yellow, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blue),
              title: const Text('View Species Details', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => DetailScreen(id: currentSpeciesId, type: ScannedType.species)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.yellow),
              title: const Text('Change Species', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _selectSpeciesForCell(line, row);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remove (Died)', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await MockDatabaseService.setSpeciesAtBedCell(widget.id, line, row, null);
                _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addSpeciesToCrate() async {
    final allSpecies = await MockDatabaseService.getAllSpecies();
    final items = allSpecies.map((s) => SearchItem(id: s.id, name: s.name, subtitle: s.latinName)).toList();

    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SearchDialog(title: 'ADD TO CRATE', items: items),
    );

    if (result != null && mounted) {
      await MockDatabaseService.addSpeciesToCrate(widget.id, result);
      _loadData();
    }
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('Name', s.name),
                        _infoRow('Latin', s.latinName ?? '-'),
                        _infoRow('Color', s.color ?? '-'),
                        const SizedBox(height: 16),
                        const Text('Description:', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
                        Text(s.description ?? 'No description', style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _buildPhotoHeader(s, height: 200),
                  ),
                ],
              ),
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
              _infoRow('Label', b.row ?? '-'),
              _infoRow('Length', '${b.length} Meters'),
              _infoRow(
                'Layout', 
                b.layout == BedLayout.grid 
                  ? 'GRID (2 Lines x ${b.rowsPerMeterEffective} Rows/m)' 
                  : 'LINEAR (1 Row/m)'
              ),
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

  Widget _buildPhotoHeader(Species species, {double height = 250}) {
    if (species.photoUrl == null) return const SizedBox();

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: LocalImageService.isRemoteUrl(species.photoUrl!)
            ? CachedNetworkImage(
                imageUrl: species.photoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.yellow)),
                errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
              )
            : _localPhotoFile != null
                ? Image.file(_localPhotoFile!, fit: BoxFit.cover)
                : const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.white24)),
      ),
    );
  }

  Widget _buildGridThumbnail(Species species, {double size = 30}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black26),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LocalImageService.isRemoteUrl(species.photoUrl!)
            ? CachedNetworkImage(
                imageUrl: species.photoUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 80, // High efficiency for tiny icons
                memCacheHeight: 80,
                errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 10, color: Colors.red),
              )
            : _localThumbnails[species.id] != null
                ? Image.file(
                    _localThumbnails[species.id]!,
                    fit: BoxFit.cover,
                    cacheWidth: 80,
                    cacheHeight: 80,
                  )
                : const Icon(Icons.image, size: 10, color: Colors.white12),
      ),
    );
  }

  Widget _buildLocationsList() {
    if (_locations == null || _locations!.isEmpty) {
      return const Text('Not used in any location.', style: TextStyle(fontStyle: FontStyle.italic));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _locations!.length,
      itemBuilder: (context, index) {
        final locStr = _locations![index];
        return ListTile(
          tileColor: Colors.grey[900],
          leading: Icon(locStr.startsWith('C-') ? Icons.inventory_2 : Icons.grid_view, color: Colors.yellow),
          title: Text(locStr, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.chevron_right, color: Colors.yellow),
          onTap: () {
            final id = locStr.split('-').take(2).join('-'); 
            final type = id.startsWith('B-') ? ScannedType.bed : ScannedType.crate;
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => DetailScreen(id: id, type: type)));
          },
        );
      },
    );
  }

  Widget _buildCrateSpeciesList() {
    final crate = _data as Crate;
    if (crate.speciesIds.isEmpty) {
      return const Text('Crate is empty.', style: TextStyle(fontStyle: FontStyle.italic));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: crate.speciesIds.length,
      itemBuilder: (context, index) {
        final sId = crate.speciesIds[index];
        final species = _speciesMap[sId];
        return ListTile(
          tileColor: Colors.grey[900],
          leading: species != null && species.photoUrl != null 
            ? _buildGridThumbnail(species, size: 40)
            : const Icon(Icons.local_florist, color: Colors.yellow),
          title: Text(species?.name ?? sId, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(sId),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
            onPressed: () async {
              await MockDatabaseService.removeSpeciesFromCrate(crate.id, sId);
              _loadData();
            },
          ),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => DetailScreen(id: sId, type: ScannedType.species)));
          },
        );
      },
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
