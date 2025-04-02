import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../models/chargement.dart';
import '../models/cellule.dart';
import 'chargement_form_screen.dart';

class ChargementsScreen extends StatefulWidget {
  const ChargementsScreen({super.key});

  @override
  State<ChargementsScreen> createState() => _ChargementsScreenState();
}

class _ChargementsScreenState extends State<ChargementsScreen> {
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chargements'),
        backgroundColor: Colors.green,
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, provider, child) {
          final chargements = provider.chargements;
          final cellules = provider.cellules;

          if (chargements.isEmpty) {
            return const Center(
              child: Text('Aucun chargement enregistré'),
            );
          }

          // Grouper les chargements par année
          final Map<int, List<Chargement>> chargementsParAnnee = {};
          for (var chargement in chargements) {
            final annee = chargement.dateChargement.year;
            chargementsParAnnee.putIfAbsent(annee, () => []).add(chargement);
          }

          // Trier les années par ordre décroissant
          final List<int> annees = chargementsParAnnee.keys.toList()..sort((a, b) => b.compareTo(a));

          // Trier les chargements par date décroissante dans chaque année
          chargementsParAnnee.forEach((annee, chargements) {
            chargements.sort((a, b) => b.dateChargement.compareTo(a.dateChargement));
          });

          // Si aucune année n'est sélectionnée, sélectionner la plus récente
          if (_selectedYear == null && annees.isNotEmpty) {
            _selectedYear = annees.first;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: const InputDecoration(
                          labelText: 'Année',
                          border: OutlineInputBorder(),
                        ),
                        items: annees.map((year) {
                          return DropdownMenuItem<int>(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedYear = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${chargementsParAnnee[_selectedYear]?.length ?? 0} chargements',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _selectedYear == null
                    ? const Center(child: Text('Sélectionnez une année'))
                    : ListView.builder(
                        itemCount: chargementsParAnnee[_selectedYear]!.length,
                        itemBuilder: (context, index) {
                          final chargement = chargementsParAnnee[_selectedYear]![index];
                          final cellule = cellules.firstWhere(
                            (c) => c.id == chargement.celluleId,
                            orElse: () => Cellule(
                              id: 0,
                              reference: 'Inconnu',
                              dateCreation: DateTime.now(),
                            ),
                          );

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text('Cellule ${cellule.reference}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Date: ${_formatDate(chargement.dateChargement)}'),
                                  Text('Poids net: ${(chargement.poidsNet / 1000).toStringAsFixed(2)} T'),
                                  Text('Poids aux normes: ${(chargement.poidsNormes / 1000).toStringAsFixed(2)} T'),
                                  Text('Humidité: ${chargement.humidite}%'),
                                  Text('Remorque: ${chargement.remorque}'),
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
                                          builder: (context) => ChargementFormScreen(
                                            chargement: chargement,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      _showDeleteConfirmation(context, chargement);
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
              builder: (context) => const ChargementFormScreen(),
            ),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteConfirmation(BuildContext context, Chargement chargement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce chargement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<DatabaseProvider>().supprimerChargement(chargement.id!);
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
} 