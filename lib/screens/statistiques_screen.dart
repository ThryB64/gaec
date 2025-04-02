import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/database_provider.dart';
import '../models/chargement.dart';
import '../models/semis.dart';
import '../models/parcelle.dart';

class StatistiquesScreen extends StatefulWidget {
  const StatistiquesScreen({super.key});

  @override
  State<StatistiquesScreen> createState() => _StatistiquesScreenState();
}

class _StatistiquesScreenState extends State<StatistiquesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _selectedYear;
  int? _selectedParcelleId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: Colors.orange,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Vue générale'),
            Tab(text: 'Détail par parcelle'),
            Tab(text: 'Analyse variétés'),
          ],
          onTap: (index) {
            if (index != 1) {
              setState(() {
                _selectedParcelleId = null;
              });
            }
          },
        ),
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, provider, child) {
          final chargements = provider.chargements;
          final semis = provider.semis;
          final parcelles = provider.parcelles;

          // Calculer les statistiques annuelles
          final Map<int, Map<String, dynamic>> statsParAnnee = {};
          for (var chargement in chargements) {
            final annee = chargement.dateChargement.year;
            if (!statsParAnnee.containsKey(annee)) {
              statsParAnnee[annee] = {
                'poidsTotal': 0.0,
                'humiditeMoyenne': 0.0,
                'nombreChargements': 0,
              };
            }
            statsParAnnee[annee]!['poidsTotal'] = statsParAnnee[annee]!['poidsTotal'] + chargement.poidsNormes;
            statsParAnnee[annee]!['humiditeMoyenne'] = statsParAnnee[annee]!['humiditeMoyenne'] + chargement.humidite;
            statsParAnnee[annee]!['nombreChargements'] = statsParAnnee[annee]!['nombreChargements'] + 1;
          }

          // Calculer les moyennes d'humidité
          statsParAnnee.forEach((annee, stats) {
            stats['humiditeMoyenne'] /= stats['nombreChargements'];
          });

          // Trier les années par ordre décroissant
          final annees = statsParAnnee.keys.toList()..sort((a, b) => b.compareTo(a));

          // Si aucune année n'est sélectionnée, prendre la plus récente
          if (_selectedYear == null && annees.isNotEmpty) {
            _selectedYear = annees.first;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
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
                    if (_tabController.index == 1) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedParcelleId,
                          decoration: const InputDecoration(
                            labelText: 'Parcelle',
                            border: OutlineInputBorder(),
                          ),
                          items: parcelles.map((parcelle) {
                            return DropdownMenuItem<int>(
                              value: parcelle.id,
                              child: Text(parcelle.nom),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedParcelleId = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Vue générale annuelle
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildEvolutionRendementChart(statsParAnnee),
                          const SizedBox(height: 24),
                          _buildEvolutionHumiditeChart(statsParAnnee),
                        ],
                      ),
                    ),
                    // Détail par parcelle
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildComparaisonRendementsParcellesChart(chargements, parcelles),
                          const SizedBox(height: 24),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sélectionnez une parcelle pour voir ses statistiques détaillées',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<int>(
                                    value: _selectedParcelleId,
                                    decoration: const InputDecoration(
                                      labelText: 'Parcelle',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: parcelles.map((parcelle) {
                                      return DropdownMenuItem<int>(
                                        value: parcelle.id,
                                        child: Text(parcelle.nom),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedParcelleId = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_selectedParcelleId != null) ...[
                            const SizedBox(height: 24),
                            _buildEvolutionRendementParcelleChart(chargements, _selectedParcelleId!, parcelles),
                            const SizedBox(height: 24),
                            _buildEvolutionHumiditeParcelleChart(chargements, _selectedParcelleId!, parcelles),
                          ],
                        ],
                      ),
                    ),
                    // Analyse des variétés
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildComparaisonRendementsVarietesChart(chargements, semis, parcelles),
                          const SizedBox(height: 24),
                          _buildRepartitionSurfacesVarietesChart(semis, parcelles),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEvolutionRendementChart(Map<int, Map<String, dynamic>> statsParAnnee) {
    final annees = statsParAnnee.keys.toList()..sort();
    if (annees.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Évolution du rendement total par an (T/ha)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Aucune donnée disponible',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Évolution du rendement total par an (T/ha)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            annees[value.toInt()].toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: annees.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          statsParAnnee[entry.value]!['poidsTotal'] / 1000,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
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

  Widget _buildEvolutionHumiditeChart(Map<int, Map<String, dynamic>> statsParAnnee) {
    final annees = statsParAnnee.keys.toList()..sort();
    if (annees.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Évolution de l\'humidité moyenne annuelle (%)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Aucune donnée disponible',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Évolution de l\'humidité moyenne annuelle (%)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            annees[value.toInt()].toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: annees.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          statsParAnnee[entry.value]!['humiditeMoyenne'],
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
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

  Widget _buildComparaisonRendementsParcellesChart(List<Chargement> chargements, List<Parcelle> parcelles) {
    final Map<int, double> rendements = {};
    for (var parcelle in parcelles) {
      final chargementsParcelle = chargements
          .where((c) => c.parcelleId == parcelle.id && c.dateChargement.year == _selectedYear)
          .toList();
      if (chargementsParcelle.isNotEmpty) {
        final poidsTotal = chargementsParcelle.fold<double>(
          0,
          (sum, c) => sum + c.poidsNormes,
        );
        rendements[parcelle.id!] = (poidsTotal / 1000) / parcelle.surface;
      }
    }

    if (rendements.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comparaison du rendement (T/ha) entre toutes les parcelles pour $_selectedYear',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Aucune donnée disponible',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparaison du rendement (T/ha) entre toutes les parcelles pour $_selectedYear',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: rendements.values.reduce((a, b) => a > b ? a : b) * 1.2,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final parcelle = parcelles.firstWhere((p) => p.id == rendements.keys.elementAt(value.toInt()));
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              parcelle.nom,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  barGroups: rendements.entries.map((entry) {
                    return BarChartGroupData(
                      x: rendements.keys.toList().indexOf(entry.key),
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: Colors.orange,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionRendementParcelleChart(List<Chargement> chargements, int parcelleId, List<Parcelle> parcelles) {
    final parcelle = parcelles.firstWhere((p) => p.id == parcelleId);
    final chargementsParcelle = chargements.where((c) => c.parcelleId == parcelleId).toList();

    // Grouper les chargements par année
    final Map<int, double> rendementsParAnnee = {};
    for (var chargement in chargementsParcelle) {
      final annee = chargement.dateChargement.year;
      if (!rendementsParAnnee.containsKey(annee)) {
        rendementsParAnnee[annee] = 0.0;
      }
      rendementsParAnnee[annee] = rendementsParAnnee[annee]! + chargement.poidsNormes;
    }

    final annees = rendementsParAnnee.keys.toList()..sort();
    if (annees.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Évolution du rendement par an pour ${parcelle.nom} (T/ha)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Aucune donnée disponible',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maxRendement = rendementsParAnnee.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Évolution du rendement par an pour ${parcelle.nom} (T/ha)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            annees[value.toInt()].toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: annees.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          rendementsParAnnee[entry.value]! / 1000,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  minY: 0,
                  maxY: maxRendement / 1000 * 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionHumiditeParcelleChart(List<Chargement> chargements, int parcelleId, List<Parcelle> parcelles) {
    final parcelle = parcelles.firstWhere((p) => p.id == parcelleId);
    final chargementsParcelle = chargements.where((c) => c.parcelleId == parcelleId).toList();

    // Grouper les chargements par année
    final Map<int, double> humiditeParAnnee = {};
    final Map<int, int> nombreChargementsParAnnee = {};
    for (var chargement in chargementsParcelle) {
      final annee = chargement.dateChargement.year;
      if (!humiditeParAnnee.containsKey(annee)) {
        humiditeParAnnee[annee] = 0.0;
        nombreChargementsParAnnee[annee] = 0;
      }
      humiditeParAnnee[annee] = humiditeParAnnee[annee]! + chargement.humidite;
      nombreChargementsParAnnee[annee] = nombreChargementsParAnnee[annee]! + 1;
    }

    // Calculer les moyennes
    humiditeParAnnee.forEach((annee, total) {
      humiditeParAnnee[annee] = total / nombreChargementsParAnnee[annee]!;
    });

    final annees = humiditeParAnnee.keys.toList()..sort();
    if (annees.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Évolution de l\'humidité moyenne par an pour ${parcelle.nom} (%)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Aucune donnée disponible',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maxHumidite = humiditeParAnnee.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Évolution de l\'humidité moyenne par an pour ${parcelle.nom} (%)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            annees[value.toInt()].toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: annees.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          humiditeParAnnee[entry.value]!,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  minY: 0,
                  maxY: maxHumidite * 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparaisonRendementsVarietesChart(List<Chargement> chargements, List<Semis> semis, List<Parcelle> parcelles) {
    final anneeSelectionnee = _selectedYear ?? DateTime.now().year;
    
    // Structure pour stocker les données par variété
    final poidsParVariete = <String, double>{};
    final surfacesParVariete = <String, double>{};
    
    // Calculer les surfaces par variété pour l'année sélectionnée
    for (var semis in semis.where((s) => s.date.year == anneeSelectionnee)) {
      final parcelle = parcelles.firstWhere((p) => p.id == semis.parcelleId);
      final surfaceTotale = parcelle.surface;
      
      for (var varieteSurface in semis.varietesSurfaces) {
        final surfaceVariete = surfaceTotale * (varieteSurface.pourcentage / 100);
        surfacesParVariete[varieteSurface.nom] = (surfacesParVariete[varieteSurface.nom] ?? 0) + surfaceVariete;
      }
    }
    
    // Calculer les poids par variété pour l'année sélectionnée
    for (var chargement in chargements.where((c) => c.dateChargement.year == anneeSelectionnee)) {
      // Vérifier que la variété existe dans les semis de l'année
      if (surfacesParVariete.containsKey(chargement.variete)) {
        poidsParVariete[chargement.variete] = (poidsParVariete[chargement.variete] ?? 0) + chargement.poidsNormes;
      }
    }
    
    // Calculer les rendements en tonnes par hectare
    final rendementsMoyens = <String, double>{};
    surfacesParVariete.forEach((variete, surface) {
      final poidsTotal = poidsParVariete[variete] ?? 0;
      if (surface > 0) {
        rendementsMoyens[variete] = (poidsTotal / 1000) / surface; // Conversion en tonnes par hectare
      }
    });
    
    if (rendementsMoyens.isEmpty) {
      return const Center(
        child: Text('Aucune donnée disponible pour cette année'),
      );
    }

    return Column(
      children: [
        const Text(
          'Rendements par variété',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: rendementsMoyens.values.reduce((a, b) => a > b ? a : b) * 1.2,
              barGroups: rendementsMoyens.entries.map((entry) {
                return BarChartGroupData(
                  x: rendementsMoyens.keys.toList().indexOf(entry.key),
                  barRods: [
                    BarChartRodData(
                      toY: entry.value,
                      color: Colors.orange,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value >= 0 && value < rendementsMoyens.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            rendementsMoyens.keys.elementAt(value.toInt()),
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toStringAsFixed(1)} T/ha',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepartitionSurfacesVarietesChart(List<Semis> semis, List<Parcelle> parcelles) {
    final anneeSelectionnee = _selectedYear ?? DateTime.now().year;
    
    // Calculer les surfaces par variété en tenant compte des pourcentages
    final surfacesParVariete = <String, double>{};
    
    // Filtrer les semis pour l'année sélectionnée
    final semisAnnee = semis.where((s) => s.date.year == anneeSelectionnee).toList();
    
    for (var semis in semisAnnee) {
      final parcelle = parcelles.firstWhere((p) => p.id == semis.parcelleId);
      
      // Calculer la surface totale de la parcelle
      final surfaceTotale = parcelle.surface;
      
      // Pour chaque variété dans le semis, ajouter sa surface réelle
      for (var varieteSurface in semis.varietesSurfaces) {
        final surfaceVariete = surfaceTotale * (varieteSurface.pourcentage / 100);
        surfacesParVariete[varieteSurface.nom] = (surfacesParVariete[varieteSurface.nom] ?? 0) + surfaceVariete;
      }
    }
    
    if (surfacesParVariete.isEmpty) {
      return const Center(
        child: Text('Aucune donnée disponible pour cette année'),
      );
    }

    final totalSurface = surfacesParVariete.values.reduce((a, b) => a + b);
    
    return Column(
      children: [
        const Text(
          'Répartition des surfaces par variété',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: PieChart(
            PieChartData(
              sections: surfacesParVariete.entries.map((entry) {
                return PieChartSectionData(
                  value: entry.value,
                  title: '${(entry.value / totalSurface * 100).toStringAsFixed(1)}%',
                  radius: 100,
                  color: Colors.orange,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          children: surfacesParVariete.entries.map((entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.key}: ${entry.value.toStringAsFixed(1)} ha',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
} 