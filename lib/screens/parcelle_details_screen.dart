import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../models/parcelle.dart';
import '../models/chargement.dart';
import '../models/semis.dart';
import 'parcelle_form_screen.dart';

class ParcelleDetailsScreen extends StatefulWidget {
  final Parcelle parcelle;

  const ParcelleDetailsScreen({super.key, required this.parcelle});

  @override
  State<ParcelleDetailsScreen> createState() => _ParcelleDetailsScreenState();
}

class _ParcelleDetailsScreenState extends State<ParcelleDetailsScreen> {
  int? _selectedYear;

  Widget _buildSemisDetails(Semis s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('Variétés:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...s.varietesSurfaces.map((vs) => 
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text('${vs.nom}: ${vs.pourcentage}%'),
          ),
        ),
        Text('Date: ${_formatDate(s.date)}'),
        if (s.notes?.isNotEmpty ?? false)
          Text('Notes: ${s.notes}'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parcelle.nom),
        backgroundColor: Colors.green,
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, provider, child) {
          final chargements = provider.chargements
              .where((c) => c.parcelleId == widget.parcelle.id)
              ;
          final semis = provider.semis
              .where((s) => s.parcelleId == widget.parcelle.id)
              ;

          // Grouper les chargements par année
          final Map<int, List<Chargement>> chargementsParAnnee = {};
          for (var chargement in chargements) {
            final annee = chargement.dateChargement.year;
            chargementsParAnnee.putIfAbsent(annee, () => []).add(chargement);
          }

          // Grouper les semis par année
          final Map<int, List<Semis>> semisParAnnee = {};
          for (var s in semis) {
            final annee = s.date.year;
            semisParAnnee.putIfAbsent(annee, () => []).add(s);
          }

          // Trier les années par ordre décroissant
          final List<int> annees = [...chargementsParAnnee.keys, ...semisParAnnee.keys].toSet()..sort((a, b) => b.compareTo(a));

          // Si aucune année n'est sélectionnée, sélectionner la plus récente
          if (_selectedYear == null && annees.isNotEmpty) {
            _selectedYear = annees.first;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text('Surface: ${widget.parcelle.surface} ha'),
                        Text('Date de création: ${_formatDate(widget.parcelle.dateCreation)}'),
                        if (widget.parcelle.notes != null)
                          Text('Notes: ${widget.parcelle.notes}'),
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
                        Text(
                          'Statistiques par année',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: _selectedYear,
                          decoration: const InputDecoration(
                            labelText: 'Année',
                            border: OutlineInputBorder(),
                          ),
                          items: annees.map((annee) {
                            return DropdownMenuItem<int>(
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
                          Text(
                            'Récolte de $_selectedYear',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (chargementsParAnnee[_selectedYear]?.isNotEmpty ?? false) ...[
                            Text(
                              'Poids total: ${(chargementsParAnnee[_selectedYear]!.fold<double>(0, (sum, c) => sum + c.poidsNet) / 1000).toStringAsFixed(2)} T',
                            ),
                            Text(
                              'Poids total normé: ${(chargementsParAnnee[_selectedYear]!.fold<double>(0, (sum, c) => sum + c.poidsNormes) / 1000).toStringAsFixed(2)} T',
                            ),
                            Text(
                              'Rendement moyen: ${(chargementsParAnnee[_selectedYear]!.fold<double>(0, (sum, c) => sum + c.poidsNormes) / (1000 * widget.parcelle.surface)).toStringAsFixed(2)} T/ha',
                            ),
                            Text(
                              'Humidité moyenne: ${(chargementsParAnnee[_selectedYear]!.fold<double>(0, (sum, c) => sum + c.humidite) / chargementsParAnnee[_selectedYear]!.length).toStringAsFixed(1)}%',
                            ),
                          ] else
                            const Text('Aucune récolte cette année'),
                          const SizedBox(height: 16),
                          Text(
                            'Semis de $_selectedYear',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (semisParAnnee[_selectedYear]?.isNotEmpty ?? false) ...[
                            ...semisParAnnee[_selectedYear]!.map((s) => _buildSemisDetails(s)),
                          ] else
                            const Text('Aucun semis cette année'),
                        ],
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
                        Text(
                          'Chargements',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (_selectedYear != null && (chargementsParAnnee[_selectedYear]?.isNotEmpty ?? false))
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: chargementsParAnnee[_selectedYear]!.length,
                            itemBuilder: (context, index) {
                              final chargement = chargementsParAnnee[_selectedYear]![index];
                              return ListTile(
                                title: Text(chargement.remorque),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Date: ${_formatDate(chargement.dateChargement)}'),
                                    Text('${(chargement.poidsNormes / 1000).toStringAsFixed(2)} T - ${chargement.humidite}%'),
                                  ],
                                ),
                              );
                            },
                          )
                        else
                          const Text('Aucun chargement enregistré'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 