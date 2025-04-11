import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../models/cellule.dart';
import '../models/chargement.dart';
import 'cellule_form_screen.dart';
import 'cellule_details_screen.dart';

class CellulesScreen extends StatefulWidget {
  const CellulesScreen({super.key});

  @override
  State<CellulesScreen> createState() => _CellulesScreenState();
}

class _CellulesScreenState extends State<CellulesScreen> {
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cellules'),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, provider, child) {
          final cellules = provider.cellules;
          final chargements = provider.chargements;

          if (cellules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warehouse,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune cellule enregistrée',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          // Grouper les cellules par année de création
          final Map<int, List<Cellule>> cellulesParAnnee = {};
          for (var cellule in cellules) {
            final annee = cellule.dateCreation.year;
            if (!cellulesParAnnee.containsKey(annee)) {
              cellulesParAnnee[annee] = [];
            }
            cellulesParAnnee[annee]!.add(cellule);
          }

          // Trier les années par ordre décroissant
          final List<int> annees = cellulesParAnnee.keys..sort((a, b) => b.compareTo(a));

          // Trier les cellules par date décroissante dans chaque année
          cellulesParAnnee.forEach((annee, cellules) {
            cellules.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
          });

          // Si aucune année n'est sélectionnée, sélectionner la plus récente
          if (_selectedYear == null && annees.isNotEmpty) {
            _selectedYear = annees.first;
          }

          // Calculer les statistiques de l'année sélectionnée
          final chargementsAnnee = _selectedYear != null ? chargements.where(
            (c) => c.dateChargement.year == _selectedYear &&
                   cellulesParAnnee[_selectedYear]!.any((cell) => cell.id == c.celluleId)
          ) : [];

          final poidsTotalNormeAnnee = chargementsAnnee.fold<double>(
            0,
            (sum, c) => sum + c.poidsNormes,
          );

          final poidsTotalNetAnnee = chargementsAnnee.fold<double>(
            0,
            (sum, c) => sum + c.poidsNet,
          );

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.withOpacity(0.1),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: InputDecoration(
                        labelText: 'Année',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: annees.map((annee) {
                        return DropdownMenuItem(
                          value: annee,
                          child: Text(annee.toString()),
                        );
                      }),
                      onChanged: (value) {
                        setState(() {
                          _selectedYear = value;
                        });
                      },
                    ),
                    if (_selectedYear != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            'Poids total normé',
                            '${(poidsTotalNormeAnnee / 1000).toStringAsFixed(2)} T',
                            Icons.scale,
                            Colors.blue,
                          ),
                          _buildStatCard(
                            'Poids total net',
                            '${(poidsTotalNetAnnee / 1000).toStringAsFixed(2)} T',
                            Icons.monitor_weight,
                            Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (cellulesParAnnee[_selectedYear] != null) Text(
                        '${cellulesParAnnee[_selectedYear]!.length} cellules en $_selectedYear',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: _selectedYear == null
                    ? const Center(child: Text('Sélectionnez une année'))
                    : cellulesParAnnee[_selectedYear] == null
                        ? const Center(child: Text('Aucune cellule pour cette année'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: cellulesParAnnee[_selectedYear]!.length,
                            itemBuilder: (context, index) {
                              final cellule = cellulesParAnnee[_selectedYear]![index];
                              
                              // Calculer les statistiques de la cellule pour l'année sélectionnée
                              final chargementsCellule = chargements
                                  .where((c) => c.celluleId == cellule.id && 
                                               c.dateChargement.year == _selectedYear)
                                  ;

                              final poidsTotal = chargementsCellule.fold<double>(
                                0,
                                (sum, c) => sum + c.poidsNet,
                              );

                              final poidsTotalNorme = chargementsCellule.fold<double>(
                                0,
                                (sum, c) => sum + c.poidsNormes,
                              );

                              final tauxRemplissage = (poidsTotalNorme / cellule.capacite) * 100;
                              final humiditeMoyenne = chargementsCellule.isEmpty ? 0.0 : 
                                chargementsCellule.fold<double>(0, (sum, c) => sum + c.humidite) / chargementsCellule.length;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CelluleDetailsScreen(
                                          cellule: cellule,
                                        ),
                                      ),
                                    ).then((_) => setState(() {}));
                                  },
                                  borderRadius: BorderRadius.circular(15),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Cellule ${cellule.reference}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.info),
                                                  color: Colors.blue,
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => CelluleDetailsScreen(
                                                          cellule: cellule,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete),
                                                  color: Colors.red,
                                                  onPressed: () => _showDeleteConfirmation(context, cellule),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.warehouse,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${(cellule.capacite / 1000).toStringAsFixed(2)} T',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Créée le ${_formatDate(cellule.dateCreation)}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (chargementsCellule.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            value: tauxRemplissage / 100,
                                            backgroundColor: Colors.blue.withOpacity(0.2),
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              tauxRemplissage > 90
                                                  ? Colors.red
                                                  : tauxRemplissage > 70
                                                      ? Colors.orange
                                                      : Colors.blue,
                                            ),
                                            minHeight: 8,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Taux de remplissage: ${tauxRemplissage.toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                'Net: ${(poidsTotal / 1000).toStringAsFixed(2)} T\nNormé: ${(poidsTotalNorme / 1000).toStringAsFixed(2)} T',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                                textAlign: TextAlign.end,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Humidité moyenne: ${humiditeMoyenne.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
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
              builder: (context) => const CelluleFormScreen(),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteConfirmation(BuildContext context, Cellule cellule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette cellule ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DatabaseProvider>().supprimerCellule.fromMap(cellule.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
} 