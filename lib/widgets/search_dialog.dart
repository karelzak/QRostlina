import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/qr_scanner_service.dart';
import 'qr_scanner_dialog.dart';

class SearchItem {
  final String id;
  final String name;
  final String? subtitle;

  SearchItem({required this.id, required this.name, this.subtitle});
}

class SearchDialog extends StatefulWidget {
  final String title;
  final List<SearchItem> items;

  const SearchDialog({super.key, required this.title, required this.items});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  late List<SearchItem> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _filteredItems = widget.items
          .where((item) =>
              item.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
              item.id.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Row(
        children: [
          Expanded(child: Text(widget.title, style: const TextStyle(color: Colors.yellow))),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.yellow),
            onPressed: () async {
              final result = await showDialog<ScannedResult>(
                context: context,
                builder: (context) => const QRScannerDialog(),
              );
              if (result != null) {
                if (result.type == ScannedType.species) {
                  if (context.mounted) Navigator.pop(context, result.id);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.notSpeciesQr)),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.search, color: Colors.yellow),
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: _filteredItems.isEmpty
                  ? Center(child: Text(l10n.noMatchesFound, style: const TextStyle(color: Colors.white70)))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return ListTile(
                          title: Text(item.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text('${item.id}${item.subtitle != null ? " | ${item.subtitle}" : ""}',
                              style: const TextStyle(color: Colors.white54)),
                          onTap: () => Navigator.pop(context, item.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel, style: const TextStyle(color: Colors.yellow)),
        ),
      ],
    );
  }
}
