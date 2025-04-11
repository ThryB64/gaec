import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../models/cellule.dart';
import '../models/chargement.dart';
import '../models/parcelle.dart';

class CelluleDetailsScreen extends StatelessWidget {
  final Cellule cellule;

  const CelluleDetailsScreen({super.key, required this.cellule});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(cellule.reference),
        centerTitle: true,
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, db, child) {
          final chargements = db.chargements
              .where((c) => c.celluleId == cellule.id)
              ;
          final parcelles = db.parcelles;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(context),
                const SizedBox(height: 16),
                _buildStatistiquesCard(context, chargements),
                const SizedBox(height: 16),
                _buildChargementsCard(context, chargements, parcelles),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Capacité', '${(cellule.capacite / 1000).toStringAsFixed(2)} T'),
            _buildInfoRow('Date de création', _formatDate(cellule.dateCreation)),
            if (cellule.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                'Notes:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(cellule.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatistiquesCard(BuildContext context, List<Chargement> chargements) {
    if (chargements.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Aucun chargement enregistré'),
        ),
      );
    }

    // Calculer les statistiques par année
    final Map<int, List<Chargement>> chargementsParAnnee = {};
    for (var chargement in chargements) {
      final annee = chargement.dateChargement.year;
      chargementsParAnnee.putIfAbsent(annee, () => []).add(chargement);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques par année',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...chargementsParAnnee.entries.map((entry) {
              final annee = entry.key;
              final chargementsAnnee = entry.value;
              final poidsTotalNet = chargementsAnnee.fold<double>(
                0,
                (sum, c) => sum + c.poidsNet,
              );
              final poidsTotalNorme = chargementsAnnee.fold<double>(
                0,
                (sum, c) => sum + c.poidsNormes,
              );
              final humiditeMoyenne = chargementsAnnee.fold<double>(
                0,
                (sum, c) => sum + c.humidite,
              ) / chargementsAnnee.length;
              final tauxRemplissage = (poidsTotalNorme / cellule.capacite) * 100;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    annee.toString(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Poids total net', '${(poidsTotalNet / 1000).toStringAsFixed(2)} T'),
                  _buildInfoRow('Poids total normé', '${(poidsTotalNorme / 1000).toStringAsFixed(2)} T'),
                  _buildInfoRow('Taux de remplissage', '${tauxRemplissage.toStringAsFixed(1)}%'),
                  _buildInfoRow('Humidité moyenne', '${humiditeMoyenne.toStringAsFixed(1)}%'),
                  _buildInfoRow('Nombre de chargements', chargementsAnnee.length.toString()),
                  const SizedBox(height: 16),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChargementsCard(BuildContext context, List<Chargement> chargements, List<Parcelle> parcelles) {
    if (chargements.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Aucun chargement enregistré'),
        ),
      );
    }

    // Grouper les chargements par année
    final Map<int, List<Chargement>> chargementsParAnnee = {};
    for (var chargement in chargements) {
      final annee = chargement.dateChargement.year;
      if (!chargementsParAnnee.containsKey(annee)) {
        chargementsParAnnee[annee] = [];
      }
      chargementsParAnnee[annee]!.add(chargement);
    }

    // Trier les années par ordre décroissant
    final annees = chargementsParAnnee.keys..sort((a, b) => b.compareTo(a));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historique des chargements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...annees.map((annee) {
              final chargementsAnnee = chargementsParAnnee[annee]!;
              chargementsAnnee.sort((a, b) => b.dateChargement.compareTo(a.dateChargement));

              final poidsTotalNet = chargementsAnnee.fold<double>(
                0,
                (sum, c) => sum + c.poidsNet,
              );
              final poidsTotalNorme = chargementsAnnee.fold<double>(
                0,
                (sum, c) => sum + c.poidsNormes,
              );
              final humiditeMoyenne = chargementsAnnee.fold<double>(
                0,
                (sum, c) => sum + c.humidite,
              ) / chargementsAnnee.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    annee.toString(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Poids total net: ${(poidsTotalNet / 1000).toStringAsFixed(2)} T',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Poids total normé: ${(poidsTotalNorme / 1000).toStringAsFixed(2)} T',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Humidité moyenne: ${humiditeMoyenne.toStringAsFixed(1)}%',
                            ),
                            Text(
                              'Nombre de chargements: ${chargementsAnnee.length}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...chargementsAnnee.map((chargement) {
                    final parcelle = parcelles.firstWhere(
                      (p) => p.id == chargement.parcelleId,
                      orElse: () => Parcelle.fromMap(
                        id: 0,
                        nom: 'Inconnue',
                        surface: 0,
                        dateCreation: DateTime.now(),
                      ),
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Parcelle: ${parcelle.nom}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Date: ${_formatDateTime(chargement.dateChargement)}',
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Net: ${(chargement.poidsNet / 1000).toStringAsFixed(2)} T',
                                ),
                                Text(
                                  'Normé: ${(chargement.poidsNormes / 1000).toStringAsFixed(2)} T',
                                ),
                              ],
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Humidité: ${chargement.humidite.toStringAsFixed(1)}%'),
                            Text('Remorque: ${chargement.remorque}'),
                            if (chargement.variete.isNotEmpty)
                              Text('Variété: ${chargement.variete}'),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
} 