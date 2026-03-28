import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) {
        return item.name.toLowerCase().contains(query) ||
               item.id.toLowerCase().contains(query) ||
               (item.subtitle?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(color: Colors.yellow, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or ID...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.yellow),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.yellow),
                  onPressed: () async {
                    final code = await showDialog<String>(
                      context: context,
                      builder: (context) => const QRScannerDialog(),
                    );
                    if (code != null && context.mounted) {
                      final result = QRScannerService.parse(code);
                      if (result.type == ScannedType.species) {
                        // Attempt to find the exact item in the list
                        try {
                          final item = widget.items.firstWhere((i) => i.id == result.id);
                          Navigator.pop(context, item.id);
                        } catch (_) {
                          // Filter the list by the scanned ID if not an exact match in current list
                          _searchController.text = result.id;
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Not a Species QR code (S-xxx expected)')),
                        );
                      }
                    }
                  },
                ),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.yellow, width: 2)),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: _filteredItems.isEmpty
                    ? const Center(child: Text('No matches found.', style: TextStyle(color: Colors.white70)))
                    : ListView.builder(
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return ListTile(
                            title: Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              '${item.id}${item.subtitle != null ? " | ${item.subtitle}" : ""}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            onTap: () => Navigator.pop(context, item.id),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: Colors.yellow)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
