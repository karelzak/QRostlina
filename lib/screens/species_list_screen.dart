import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/species.dart';
import '../services/mock_database_service.dart';
import '../services/qr_scanner_service.dart';
import 'detail_screen.dart';

class SpeciesListScreen extends StatefulWidget {
  const SpeciesListScreen({super.key});

  @override
  State<SpeciesListScreen> createState() => _SpeciesListScreenState();
}

class _SpeciesListScreenState extends State<SpeciesListScreen> {
  late Future<List<Species>> _speciesList;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _speciesList = MockDatabaseService.getAllSpecies();
    });
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
                      Text(s.color ?? 'N/A', style: const TextStyle(color: Colors.white60)),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.yellow),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(id: s.id, type: ScannedType.species),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement add species screen
        },
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: Text(l10n.addNewSpecies, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
