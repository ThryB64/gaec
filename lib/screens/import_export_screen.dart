import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/database_provider.dart';
import '../models/parcelle.dart';
import '../models/cellule.dart';
import '../models/chargement.dart';
import '../models/semis.dart';
import '../models/variete.dart';

class ImportExportScreen extends StatelessWidget {
  const ImportExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import/Export'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'État de la base',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<DatabaseProvider>(
                      builder: (context, provider, child) {
                        return Column(
                          children: [
                            _buildDataSummary(
                              'Parcelles',
                              provider.parcelles.length,
                              Icons.landscape,
                              Colors.green,
                            ),
                            const SizedBox(height: 8),
                            _buildDataSummary(
                              'Cellules',
                              provider.cellules.length,
                              Icons.warehouse,
                              Colors.blue,
                            ),
                            const SizedBox(height: 8),
                            _buildDataSummary(
                              'Chargements',
                              provider.chargements.length,
                              Icons.local_shipping,
                              Colors.orange,
                            ),
                            const SizedBox(height: 8),
                            _buildDataSummary(
                              'Semis',
                              provider.semis.length,
                              Icons.agriculture,
                              Colors.brown,
                            ),
                            const SizedBox(height: 8),
                            _buildDataSummary(
                              'Variétés',
                              provider.varietes.length,
                              Icons.eco,
                              Colors.purple,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await provider.updateAllChargementsPoidsNormes();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Poids aux normes mis à jour avec succès'),
                                        duration: Duration(seconds: 5),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    // Forcer le rafraîchissement de l'interface
                                    provider.notifyListeners();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erreur lors de la mise à jour: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Mettre à jour les poids aux normes'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Export complet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Exporte toutes les données de la base dans un fichier JSON',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _exportData(context),
                      icon: const Icon(Icons.download),
                      label: const Text('Exporter la base'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Import complet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Importe toutes les données depuis un fichier JSON',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _importData(context),
                      icon: const Icon(Icons.upload),
                      label: const Text('Importer la base'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSummary(String title, int count, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          '$title : $count',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final provider = context.read<DatabaseProvider>();
      
      // Créer un objet contenant toutes les données
      final data = {
        'version': '2.0', // Version du format d'export
        'parcelles': provider.parcelles.map((p) => p.toMap()),
        'cellules': provider.cellules.map((c) => c.toMap()),
        'chargements': provider.chargements.map((c) => c.toMap()),
        'semis': provider.semis.map((s) => s.toMap()),
        'varietes': provider.varietes.map((v) => v.toMap()),
      };

      // Convertir en JSON avec indentation pour une meilleure lisibilité
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      // Obtenir le répertoire de téléchargement
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw 'Impossible d\'accéder au répertoire de téléchargement';
      }

      // Créer le nom de fichier avec la date et l'heure
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'mais_tracker_db_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      // Sauvegarder le fichier
      await file.writeAsString(jsonString);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Base de données exportée dans ${directory.path}/$fileName'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'export: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    try {
      // Obtenir le répertoire de téléchargement
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw 'Impossible d\'accéder au répertoire de téléchargement';
      }

      // Lister tous les fichiers JSON dans le répertoire
      final files = directory.listSync()
          .where((file) => file is File && file.path.endsWith('.json'))
          .map((file) => file as File)
          ;

      if (files.isEmpty) {
        throw 'Aucun fichier JSON trouvé dans le répertoire de téléchargement';
      }

      // Trier les fichiers par date de modification (plus récent en premier)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // Prendre le fichier le plus récent
      final file = files.first;
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);

      // Vérifier la structure des données
      if (!_validateDataStructure(data)) {
        throw 'Format de fichier invalide. Veuillez utiliser un fichier exporté depuis l\'application.';
      }

      // Afficher un résumé des données à importer
      final summary = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Résumé des données à importer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Version du fichier: ${data['version'] ?? '1.0'}'),
              const SizedBox(height: 8),
              Text('Parcelles : ${data['parcelles'].length}'),
              Text('Cellules : ${data['cellules'].length}'),
              Text('Chargements : ${data['chargements'].length}'),
              Text('Semis : ${data['semis'].length}'),
              Text('Variétés : ${data['varietes'].length}'),
              const SizedBox(height: 16),
              const Text(
                'Les données existantes seront remplacées. '
                'Voulez-vous continuer ?',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, data),
              child: const Text('Importer'),
            ),
          ],
        ),
      );

      if (summary != null) {
        final provider = context.read<DatabaseProvider>();
        
        // Supprimer les données existantes
        await provider.deleteAllData();
        
        // Importer les nouvelles données
        await provider.importData(summary);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Base de données importée avec succès')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'import: $e')),
        );
      }
    }
  }

  bool _validateDataStructure(Map<String, dynamic> data) {
    return data.containsKey('parcelles') &&
           data.containsKey('cellules') &&
           data.containsKey('chargements') &&
           data.containsKey('semis') &&
           data.containsKey('varietes') &&
           data['parcelles'] is List &&
           data['cellules'] is List &&
           data['chargements'] is List &&
           data['semis'] is List &&
           data['varietes'] is List;
  }
} 

  Future<void> exportData(BuildContext context) async {
    final provider = Provider.of<DatabaseProvider>(context, listen: false);
    await provider.loadParcelles();
    await provider.loadCellules();
    await provider.loadChargements();
    await provider.loadSemis.fromMap();
    await provider.loadVarietes();

    final data = {
      'parcelles': provider.parcelles.map((e) => e.toMap()),
      'cellules': provider.cellules.map((e) => e.toMap()),
      'chargements': provider.chargements.map((e) => e.toMap()),
      'semis': provider.semis.map((e) => e.toMap()),
      'varietes': provider.varietes.map((e) => e.toMap()),
    };

    final jsonString = jsonEncode(data);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/export_maistracker.json');
    await file.writeAsString(jsonString);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export terminé !')),
    );
  }

  Future<void> importData(BuildContext context) async {
    final provider = Provider.of<DatabaseProvider>(context, listen: false);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/export_maistracker.json');

    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fichier d’import introuvable')),
      );
      return;
    }

    final jsonString = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(jsonString);

    for (var p in (data['parcelles'] as List)) {
      await provider.addParcelle.fromMap(Parcelle.fromMap(Map<String, dynamic>.from(p)));
    }
    for (var c in (data['cellules'] as List)) {
      await provider.addCellule.fromMap(Cellule.fromMap(Map<String, dynamic>.from(c)));
    }
    for (var ch in (data['chargements'] as List)) {
      await provider.addChargement.fromMap(Chargement.fromMap(Map<String, dynamic>.from(ch)));
    }
    for (var s in (data['semis'] as List)) {
      await provider.addSemis.fromMap(Semis.fromMap(Map<String, dynamic>.from(s)));
    }
    for (var v in (data['varietes'] as List)) {
      await provider.addVariete.fromMap(Variete.fromMap(Map<String, dynamic>.from(v)));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import terminé !')),
    );
  }
