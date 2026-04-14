import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../models/species.dart';
import '../models/location.dart';
import '../services/service_locator.dart';
import '../services/qr_scanner_service.dart';
import '../services/csv_service.dart';
import '../services/local_image_service.dart';
import '../widgets/search_dialog.dart';
import 'edit_species_screen.dart';
import 'edit_location_screen.dart';
import 'printing_screen.dart';

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

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _loading = true);
    }

    // Use local variables to gather data
    dynamic newData;
    List<String>? newLocations;
    Map<String, Species> newSpeciesMap = {};
    int newBedInstanceCount = 0;
    int newCrateInstanceCount = 0;
    int newUniqueSpeciesInLocationCount = 0;
    File? newLocalPhotoFile;
    Map<String, File?> newLocalThumbnails = {};

    switch (widget.type) {
      case ScannedType.species:
        newData = await locator.db.getSpeciesById(widget.id);
        if (newData != null) {
          final s = newData as Species;
          newLocations = await locator.db.getLocationsForSpecies(widget.id);
          newSpeciesMap[widget.id] = s;

          if (s.photoUrl != null && !LocalImageService.isRemoteUrl(s.photoUrl!)) {
            newLocalPhotoFile = await LocalImageService.getLocalFile(s.photoUrl!);
          }

          for (var loc in newLocations!) {
            if (loc.startsWith('B-')) {
              newBedInstanceCount++;
            } else if (loc.startsWith('C-')) {
              newCrateInstanceCount++;
            }
          }
        }
        break;
      case ScannedType.bed:
        newData = await locator.db.getBedById(widget.id);
        if (newData != null) {
          final bed = newData as Bed;
          final uniqueIds = <String>{};
          
          final idsToFetch = bed.layout == BedLayout.rand 
              ? bed.randSpeciesIds 
              : bed.speciesMap.values;

          for (var sId in idsToFetch) {
            uniqueIds.add(sId);
            if (!newSpeciesMap.containsKey(sId)) {
              final s = await locator.db.getSpeciesById(sId);
              if (s != null) newSpeciesMap[sId] = s;
            }
          }
          newUniqueSpeciesInLocationCount = uniqueIds.length;
          
          for (var s in newSpeciesMap.values) {
            if (s.photoUrl != null && !LocalImageService.isRemoteUrl(s.photoUrl!)) {
              newLocalThumbnails[s.id] = await LocalImageService.getLocalFile(s.photoUrl!);
            }
          }
        }
        break;
      case ScannedType.crate:
        newData = await locator.db.getCrateById(widget.id);
        if (newData != null) {
          final crate = newData as Crate;
          newUniqueSpeciesInLocationCount = crate.speciesIds.length;
          for (var sId in crate.speciesIds) {
            if (!newSpeciesMap.containsKey(sId)) {
              final s = await locator.db.getSpeciesById(sId);
              if (s != null) newSpeciesMap[sId] = s;
            }
          }

          for (var s in newSpeciesMap.values) {
            if (s.photoUrl != null && !LocalImageService.isRemoteUrl(s.photoUrl!)) {
              newLocalThumbnails[s.id] = await LocalImageService.getLocalFile(s.photoUrl!);
            }
          }
        }
        break;
      case ScannedType.plant:
        newData = null; 
        break;
      case ScannedType.unknown:
        break;
    }

    if (mounted) {
      setState(() {
        _data = newData;
        _locations = newLocations;
        _speciesMap = newSpeciesMap;
        _bedInstanceCount = newBedInstanceCount;
        _crateInstanceCount = newCrateInstanceCount;
        _uniqueSpeciesInLocationCount = newUniqueSpeciesInLocationCount;
        _localPhotoFile = newLocalPhotoFile;
        _localThumbnails = newLocalThumbnails;
        _loading = false;
      });
    }
  }

  void _confirmClearLocation(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(l10n.clearLocation, style: const TextStyle(color: Colors.white)),
        content: Text(l10n.clearLocationConfirm, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.clearAll, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await locator.db.clearLocation(widget.id);
      _loadData(showLoading: false);
    }
  }

  void _deleteLocation(AppLocalizations l10n) async {
    final location = _data as Location;
    bool isEmpty = true;
    if (location is Bed) {
      isEmpty = location.filledCells <= 0;
    } else if (location is Crate) {
      isEmpty = location.speciesIds.isEmpty;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(l10n.deleteLocation, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  l10n.deleteLocationNotEmpty,
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
            Text(location.id, style: const TextStyle(color: Colors.white70)),
          ],
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

    if (confirmed == true && mounted) {
      await locator.db.deleteLocation(location.id);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String typeStr = widget.type == ScannedType.species ? l10n.speciesList : l10n.locations;
    String title = '${typeStr.toUpperCase()}: ${widget.id}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (widget.type == ScannedType.species && _data != null) ...[
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () {
                final s = _data as Species;
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => PrintingScreen(
                    qrData: s.id,
                    fixedText: s.name,
                    infoName: s.name,
                    infoId: s.id,
                    infoSubtitle: s.latinName,
                  ),
                ));
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (context) => EditSpeciesScreen(species: _data as Species)),
                );
                if (result == true) _loadData(showLoading: false);
              },
            ),
          ],
          if ((widget.type == ScannedType.bed || widget.type == ScannedType.crate) && _data != null) ...[
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () {
                if (widget.type == ScannedType.bed) {
                  final b = _data as Bed;
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => PrintingScreen(
                      qrData: b.id,
                      fixedText: b.id,
                      toggleableLabel: b.row,
                      infoName: b.name,
                      infoId: b.id,
                      infoSubtitle: b.row,
                    ),
                  ));
                } else {
                  final c = _data as Crate;
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => PrintingScreen(
                      qrData: c.id,
                      fixedText: c.id,
                      infoName: c.name,
                      infoId: c.id,
                      infoSubtitle: c.type,
                    ),
                  ));
                }
              },
            ),
             IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              onPressed: () => _confirmClearLocation(l10n),
              tooltip: 'Clear all species from this location',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditLocationScreen(
                      location: _data as Location,
                      isBed: widget.type == ScannedType.bed,
                    ),
                  ),
                );
                if (result != null) _loadData(showLoading: false);
              },
            ),
          ],
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              // Handle other menu actions here
            },
            itemBuilder: (context) => [
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
                final result = await Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute(builder: (context) => screen),
                );
                if (result != null) _loadData();
              },
              child: Text(l10n.createNew),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    return SingleChildScrollView(
      key: PageStorageKey('detail_${widget.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(l10n),
          if (_data is Bed) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  (_data as Bed).layout == BedLayout.rand ? l10n.speciesList : l10n.visualMap,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.yellow),
                ),
                const Spacer(),
                _countBadge(Icons.grid_view, '$_uniqueSpeciesInLocationCount ${l10n.speciesList}', Colors.orange),
                const SizedBox(width: 8),
                if ((_data as Bed).layout != BedLayout.rand)
                  _countBadge(Icons.check_circle_outline, '${(_data as Bed).filledCells}/${(_data as Bed).totalCells}', Colors.green)
                else
                  IconButton(
                    onPressed: () => _addSpeciesToRandBed(l10n),
                    icon: const Icon(Icons.add, color: Colors.yellow, size: 32),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const Divider(color: Colors.yellow),
            const SizedBox(height: 8),
            if ((_data as Bed).layout == BedLayout.rand)
              _buildRandSpeciesList(l10n)
            else
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: _buildGridMap(l10n),
                ),
              ),
          ],
          if (widget.type == ScannedType.species) ...[
             const SizedBox(height: 24),
             Row(
               children: [
                 Text(
                  l10n.locations,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.yellow),
                ),
                const Spacer(),
                _countBadge(Icons.grid_view, _bedInstanceCount.toString(), Colors.orange),
                const SizedBox(width: 8),
                _countBadge(Icons.inventory_2, _crateInstanceCount.toString(), Colors.blue),
               ],
             ),
            const Divider(color: Colors.yellow),
            const SizedBox(height: 8),
            _buildLocationsList(l10n),
          ],
          if (_data is Crate) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  l10n.speciesInCrate,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.yellow),
                ),
                const Spacer(),
                _countBadge(Icons.local_florist, _uniqueSpeciesInLocationCount.toString(), Colors.blue),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _addSpeciesToCrate(l10n),
                  icon: const Icon(Icons.add, color: Colors.yellow, size: 32),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(color: Colors.yellow),
            const SizedBox(height: 8),
            _buildCrateSpeciesList(l10n),
          ],
        ],
      ),
    );
  }


  Widget _buildGridMap(AppLocalizations l10n) {
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
                    l10n.meterLabel(meter),
                    style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Expanded(child: Divider(indent: 16, color: Colors.white24)),
                ],
              ),
            ),
            if (bed.totalLines > 1)
              Row(
                children: [
                  Expanded(child: Center(child: Text(l10n.left, style: const TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold)))),
                  Expanded(child: Center(child: Text(l10n.right, style: const TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold)))),
                ],
              )
            else
              Center(child: Text(l10n.center, style: const TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold))),
            const SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: bed.layout == BedLayout.grid ? bed.linesPerMeter : 1,
                childAspectRatio: bed.layout == BedLayout.grid ? (bed.linesPerMeter == 1 ? 3.5 : 1.0) : 3.5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: bed.layout == BedLayout.grid ? bed.linesPerMeter * bed.rowsPerMeter : 1,
              itemBuilder: (context, cellIdx) {
                int lineIdx = bed.layout == BedLayout.grid ? (cellIdx % bed.linesPerMeter) + 1 : 1;
                int subRow = bed.layout == BedLayout.grid ? (cellIdx / bed.linesPerMeter).floor() + 1 : 1;
                int rowIdx = bed.layout == BedLayout.grid ? (meter - 1) * bed.rowsPerMeter + subRow : meter;

                final key = "$lineIdx-$rowIdx";
                final speciesId = bed.speciesMap[key];
                final species = speciesId != null ? _speciesMap[speciesId] : null;
                
                String cellLabel = "";
                if (bed.layout == BedLayout.grid) {
                   String lineStr = lineIdx == 1 ? 'L' : (lineIdx == 2 ? 'R' : 'C');
                   cellLabel = "$subRow$lineStr";
                } else {
                   cellLabel = l10n.meterLabel(meter);
                }

                return GestureDetector(
                  onLongPress: speciesId != null ? () async {
                    await locator.db.setSpeciesAtBedCell(bed.id, lineIdx, rowIdx, null);
                    _loadData(showLoading: false);
                  } : null,
                  onTap: () async {
                    if (speciesId == null) {
                      _selectSpeciesForCell(l10n, lineIdx, rowIdx);
                    } else {
                      _showCellActions(l10n, lineIdx, rowIdx, speciesId);
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
                              fontSize: 12,
                              color: speciesId != null ? Colors.black54 : Colors.yellow.withOpacity(0.5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (bed.layout == BedLayout.linear && speciesId != null)
                          Positioned(
                            top: 2,
                            right: 4,
                            child: Text(
                              "${bed.linesPerMeter * bed.rowsPerMeter}pcs",
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Center(
                          child: speciesId != null
                              ? Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 10), // Offset for cellLabel
                                      Text(
                                        species?.name ?? speciesId,
                                        style: const TextStyle(
                                          color: Colors.black, 
                                          fontSize: 11, 
                                          fontWeight: FontWeight.bold,
                                          overflow: TextOverflow.ellipsis
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 2),
                                      if (species?.photoUrl != null) 
                                        Expanded(child: _buildGridThumbnail(species!)),
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

  void _selectSpeciesForCell(AppLocalizations l10n, int line, int row) async {
    final allSpecies = await locator.db.getAllSpecies();
    final items = allSpecies.map((s) => SearchItem(id: s.id, name: s.name, subtitle: s.latinName)).toList();

    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SearchDialog(title: 'SELECT SPECIES', items: items),
    );

    if (result != null && mounted) {
      await locator.db.setSpeciesAtBedCell(widget.id, line, row, result);
      _loadData(showLoading: false);
    }
  }

  void _addSpeciesToRandBed(AppLocalizations l10n) async {
    final allSpecies = await locator.db.getAllSpecies();
    final items = allSpecies.map((s) => SearchItem(id: s.id, name: s.name, subtitle: s.latinName)).toList();

    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SearchDialog(title: 'ADD TO BED', items: items),
    );

    if (result != null && mounted) {
      await locator.db.addSpeciesToRandBed(widget.id, result);
      _loadData(showLoading: false);
    }
  }

  Widget _buildRandSpeciesList(AppLocalizations l10n) {
    final bed = _data as Bed;
    if (bed.randSpeciesIds.isEmpty) {
      return Text(l10n.crateIsEmpty, style: const TextStyle(fontStyle: FontStyle.italic));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bed.randSpeciesIds.length,
      itemBuilder: (context, index) {
        final sId = bed.randSpeciesIds[index];
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
              await locator.db.removeSpeciesFromRandBed(bed.id, sId);
              _loadData(showLoading: false);
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

  void _showCellActions(AppLocalizations l10n, int line, int row, String currentSpeciesId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Cell ${(_data as Bed).formatPosition(line, row)}', 
          style: const TextStyle(color: Colors.yellow, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blue),
              title: Text(l10n.viewDetails, style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => DetailScreen(id: currentSpeciesId, type: ScannedType.species)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.yellow),
              title: Text(l10n.changeSpecies, style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _selectSpeciesForCell(l10n, line, row);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(l10n.removeDied, style: const TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await locator.db.setSpeciesAtBedCell(widget.id, line, row, null);
                _loadData(showLoading: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addSpeciesToCrate(AppLocalizations l10n) async {
    final allSpecies = await locator.db.getAllSpecies();
    final items = allSpecies.map((s) => SearchItem(id: s.id, name: s.name, subtitle: s.latinName)).toList();

    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SearchDialog(title: 'ADD TO CRATE', items: items),
    );

    if (result != null && mounted) {
      await locator.db.addSpeciesToCrate(widget.id, result);
      _loadData(showLoading: false);
    }
  }

  Widget _buildInfoCard(AppLocalizations l10n) {
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
                        _infoRow(l10n.name, s.name),
                        _infoRow(l10n.latin, s.latinName ?? '-'),
                        _infoRow(l10n.color, s.color ?? '-'),
                        const SizedBox(height: 16),
                        Text('${l10n.description}:', style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
                        Text(s.description ?? l10n.noDescription, style: const TextStyle(fontSize: 18)),
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
              _infoRow(l10n.name, b.name),
              _infoRow(l10n.label, b.row ?? '-'),
              _infoRow(l10n.length, l10n.meters(b.length)),
              _infoRow(l10n.type, b.layout.name.toUpperCase()),
              if (b.layout != BedLayout.rand)
                _infoRow(l10n.density, l10n.densityValue(b.linesPerMeter, b.rowsPerMeter)),
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
              _infoRow(l10n.name, c.name),
              _infoRow(l10n.type, c.type),
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

  Widget _buildGridThumbnail(Species species, {double? size}) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
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
                  memCacheWidth: 160, // Much sharper for 80px icons
                  memCacheHeight: 160,
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 10, color: Colors.red),
                )
              : _localThumbnails[species.id] != null
                  ? Image.file(
                      _localThumbnails[species.id]!,
                      fit: BoxFit.cover,
                      cacheWidth: 160,
                      cacheHeight: 160,
                    )
                  : const Icon(Icons.image, size: 10, color: Colors.white12),
        ),
      ),
    );
  }

  Widget _buildLocationsList(AppLocalizations l10n) {
    if (_locations == null || _locations!.isEmpty) {
      return Text(l10n.notUsedInLocation, style: const TextStyle(fontStyle: FontStyle.italic));
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

  Widget _buildCrateSpeciesList(AppLocalizations l10n) {
    final crate = _data as Crate;
    if (crate.speciesIds.isEmpty) {
      return Text(l10n.crateIsEmpty, style: const TextStyle(fontStyle: FontStyle.italic));
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
              await locator.db.removeSpeciesFromCrate(crate.id, sId);
              _loadData(showLoading: false);
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
