import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../models/semis.dart';
import '../models/parcelle.dart';
import 'semis_form_screen.dart';

class SemisScreen extends StatefulWidget {
  const SemisScreen({super.key});

  @override
  State<SemisScreen> createState() => _SemisScreenState();
}

class _SemisScreenState extends State<SemisScreen> {
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semis'),
        backgroundColor: Colors.purple,
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, provider, child) {
          final semis = provider.semis;
          final parcelles = provider.parcelles;

          if (semis.isEmpty) {
            return const Center(
              child: Text('Aucun semis enregistré'),
            );
          }

          // Grouper les semis par année
          final Map<int, List<Semis>> semisParAnnee = {};
          for (var s in semis) {
            final annee = s.date.year;
            semisParAnnee.putIfAbsent(annee, () => []).add(s);
          }

          // Trier les années par ordre décroissant
          final List<int> annees = semisParAnnee.keys.toList()..sort((a, b) => b.compareTo(a));

          // Trier les semis par date décroissante dans chaque année
          semisParAnnee.forEach((annee, semis) {
            semis.sort((a, b) => b.date.compareTo(a.date));
          });

          // Si aucune année n'est sélectionnée, sélectionner la plus récente
          if (_selectedYear == null && annees.isNotEmpty) {
            _selectedYear = annees.first;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<int>(
                  value: _selectedYear,
                  decoration: const InputDecoration(
                    labelText: 'Année',
                    border: OutlineInputBorder(),
                  ),
                  items: annees.map((annee) {
                    return DropdownMenuItem(
                      value: annee,
                      child: Text(annee.toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: _selectedYear == null
                    ? const Center(child: Text('Sélectionnez une année'))
                    : ListView.builder(
                        itemCount: semisParAnnee[_selectedYear]!.length,
                        itemBuilder: (context, index) {
                          final semis = semisParAnnee[_selectedYear]![index];
                          final parcelle = parcelles.firstWhere(
                            (p) => p.id == semis.parcelleId,
                            orElse: () => Parcelle(
                              id: 0,
                              nom: 'Inconnu',
                              surface: 0,
                              dateCreation: DateTime.now(),
                            ),
                          );

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(parcelle.nom),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Date: ${_formatDate(semis.date)}'),
                                  Text('Variétés: ${semis.varietes.join(", ")}'),
                                  if (semis.notes?.isNotEmpty ?? false) Text('Notes: ${semis.notes}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SemisFormScreen(
                                            semis: semis,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      _showDeleteConfirmation(context, semis);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SemisFormScreen(),
            ),
          );
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteConfirmation(BuildContext context, Semis semis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce semis ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<DatabaseProvider>().supprimerSemis(semis.id!);
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
} 