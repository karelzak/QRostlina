import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../models/location.dart';
import '../services/service_locator.dart';
import '../services/qr_scanner_service.dart';
import '../widgets/id_input_field.dart';

class EditLocationScreen extends StatefulWidget {
  final Location? location;
  final bool isBed;

  const EditLocationScreen({super.key, this.location, this.isBed = true});

  @override
  State<EditLocationScreen> createState() => _EditLocationScreenState();
}

class _EditLocationScreenState extends State<EditLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _extraController; // Row for Bed, Type for Crate
  late TextEditingController _lengthController;
  int _linesPerMeter = 2;
  int _rowsPerMeter = 2;
  BedLayout _layout = BedLayout.grid;

  @override
  void initState() {
    super.initState();
    final loc = widget.location;
    _idController = TextEditingController(text: loc?.id ?? (widget.isBed ? 'B-' : 'C-'));
    _nameController = TextEditingController(text: loc?.name ?? '');
    
    int initialLength = 10;
    String extra = '';
    if (loc is Bed) {
      extra = loc.row ?? '';
      initialLength = loc.length;
      _linesPerMeter = loc.linesPerMeter;
      _rowsPerMeter = loc.rowsPerMeter;
      _layout = loc.layout;
    } else if (loc is Crate) {
      extra = loc.type;
    }
    _extraController = TextEditingController(text: extra);
    _lengthController = TextEditingController(text: initialLength.toString());
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _extraController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  void _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      final id = _idController.text.trim().toUpperCase();
      final newLength = int.tryParse(_lengthController.text) ?? 10;

      // If editing an existing bed, check if structural changes are allowed
      if (widget.location is Bed) {
        final bed = widget.location as Bed;
        final layoutChanged = bed.layout != _layout;
        
        // For Grid: layout change OR lines/rows change OR length reduction requires a check
        // For others: layout change OR length reduction requires a check
        bool structuralChange = layoutChanged || newLength < bed.length;
        if (bed.layout == BedLayout.grid && _layout == BedLayout.grid) {
          if (bed.linesPerMeter != _linesPerMeter || bed.rowsPerMeter != _rowsPerMeter) {
            structuralChange = true;
          }
        }

        if (structuralChange) {
          bool hasSpecies = bed.speciesMap.isNotEmpty || bed.randSpeciesIds.isNotEmpty;
          
          if (hasSpecies) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.grey[900],
                title: const Text('Change Bed Structure?', style: TextStyle(color: Colors.white)),
                content: const Text(
                  'Changing the layout, grid dimensions, or reducing length will reset all plantings in this bed. Proceed?',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('PROCEED', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            );

            if (confirm != true) return;
          }
        }
      }

      if (widget.location == null) {
        final isUnique = await locator.db.isIdUnique(id);
        if (!isUnique) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.idExists(id))),
            );
          }
          return;
        }
      }

      Location loc;
      if (widget.isBed) {
        final bed = widget.location as Bed?;
        bool structuralChange = false;
        if (bed != null) {
          structuralChange = bed.layout != _layout || newLength < bed.length;
          if (bed.layout == BedLayout.grid && _layout == BedLayout.grid) {
            if (bed.linesPerMeter != _linesPerMeter || bed.rowsPerMeter != _rowsPerMeter) {
              structuralChange = true;
            }
          }
        }

        loc = Bed(
          id: id,
          name: _nameController.text.trim(),
          row: _extraController.text.trim(),
          length: newLength,
          linesPerMeter: _layout == BedLayout.rand ? 1 : _linesPerMeter,
          rowsPerMeter: _rowsPerMeter,
          layout: _layout,
          speciesMap: structuralChange ? null : (widget.location is Bed ? (widget.location as Bed).speciesMap : null),
          randSpeciesIds: structuralChange ? null : (widget.location is Bed ? (widget.location as Bed).randSpeciesIds : null),
        );
      } else {
        loc = Crate(
          id: id,
          name: _nameController.text.trim(),
          type: _extraController.text.trim(),
          speciesIds: widget.location is Crate ? (widget.location as Crate).speciesIds : null,
        );
      }

      await locator.db.saveLocation(loc);
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pop(loc.id);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.location != null;
    final typeLabel = widget.isBed ? l10n.bed.toUpperCase() : l10n.crate.toUpperCase();

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'EDIT $typeLabel' : 'ADD NEW $typeLabel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              IdInputField(
                controller: _idController,
                label: 'ID (${widget.isBed ? "B-" : "C-"})',
                type: widget.isBed ? ScannedType.bed : ScannedType.crate,
                enabled: !isEditing,
                validator: (val) {
                  final prefix = widget.isBed ? 'B-' : 'C-';
                  if (val == null || val.trim().length <= 2 || !val.trim().toUpperCase().startsWith(prefix)) {
                    return 'Required (e.g. $prefix-001)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: l10n.name,
                validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _extraController,
                label: widget.isBed ? '${l10n.label} (e.g. A)' : '${l10n.type} (e.g. Plastic)',
              ),
              if (widget.isBed) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lengthController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.bedLength,
                    labelStyle: const TextStyle(color: Colors.yellow),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow, width: 2)),
                    suffixText: 'm',
                    suffixStyle: const TextStyle(color: Colors.yellow),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    final len = int.tryParse(val);
                    if (len == null || len <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BedLayout>(
                  value: _layout,
                  decoration: InputDecoration(
                    labelText: l10n.layoutType,
                    labelStyle: const TextStyle(color: Colors.yellow),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                  ),
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  items: [
                    DropdownMenuItem(value: BedLayout.grid, child: Text(l10n.grid)),
                    DropdownMenuItem(value: BedLayout.linear, child: Text(l10n.linear)),
                    DropdownMenuItem(value: BedLayout.rand, child: Text(l10n.rand)),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _layout = val!;
                    });
                  },
                ),
                if (_layout != BedLayout.rand) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _linesPerMeter > (_layout == BedLayout.grid ? 3 : 20) ? 1 : _linesPerMeter,
                    decoration: InputDecoration(
                      labelText: l10n.lines,
                      labelStyle: const TextStyle(color: Colors.yellow),
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                    ),
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    items: List.generate(_layout == BedLayout.grid ? 3 : 20, (index) => index + 1)
                        .map((val) => DropdownMenuItem(value: val, child: Text(val.toString())))
                        .toList(),
                    onChanged: (val) => setState(() => _linesPerMeter = val!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _rowsPerMeter > (_layout == BedLayout.grid ? 3 : 20) ? 1 : _rowsPerMeter,
                    decoration: InputDecoration(
                      labelText: _layout == BedLayout.grid ? l10n.rows : l10n.plantsPerMeter,
                      labelStyle: const TextStyle(color: Colors.yellow),
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                    ),
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    items: List.generate(_layout == BedLayout.grid ? 3 : 20, (index) => index + 1)
                        .map((val) => DropdownMenuItem(value: val, child: Text(val.toString())))
                        .toList(),
                    onChanged: (val) => setState(() => _rowsPerMeter = val!),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'TOTAL: ${_linesPerMeter * _rowsPerMeter} plants per meter',
                      style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
                child: Text('${l10n.save} $typeLabel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.yellow),
        disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!)),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow, width: 2)),
      ),
    );
  }
}
