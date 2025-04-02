import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../models/parcelle.dart';
import '../models/cellule.dart';
import '../models/chargement.dart';
import '../models/semis.dart';
import '../models/variete.dart';
import '../utils/poids_utils.dart';
import 'parcelles_screen.dart';
import 'cellules_screen.dart';
import 'chargements_screen.dart';
import 'semis_screen.dart';
import 'varietes_screen.dart';
import 'import_export_screen.dart';
import 'statistiques_screen.dart';
import 'export_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final provider = Provider.of<DatabaseProvider>(context, listen: false);
      final stats = await provider.getStats();
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des statistiques: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GAEC de la BARADE'),
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade700,
                Colors.green.shade500,
              ],
            ),
          ),
        ),
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, provider, child) {
          final parcelles = provider.parcelles;
          final cellules = provider.cellules;
          final chargements = provider.chargements;
          final semis = provider.semis;
          final varietes = provider.varietes;

          // Calculer les statistiques globales
          final surfaceTotale = parcelles.fold<double>(
            0,
            (sum, p) => sum + p.surface,
          );

          // Obtenir l'année la plus récente avec des chargements
          final derniereAnnee = chargements.isEmpty 
              ? DateTime.now().year 
              : chargements
                  .map((c) => c.dateChargement.year)
                  .reduce((a, b) => a > b ? a : b);

          final chargementsDerniereAnnee = chargements.where(
            (c) => c.dateChargement.year == derniereAnnee
          ).toList();

          // Calculer le poids total normé de l'année
          final poidsTotalNormeAnnee = chargementsDerniereAnnee.fold<double>(
            0,
            (sum, c) => sum + c.poidsNormes,
          );

          // Calculer le rendement moyen normé (en T/ha)
          final rendementMoyenNorme = surfaceTotale > 0
              ? (poidsTotalNormeAnnee / 1000) / surfaceTotale
              : 0.0;

          // Calculer le nombre de variétés utilisées
          final varietesUtilisees = semis.expand((s) => s.varietes).toSet().length;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.green.shade50,
                  Colors.white,
                ],
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Carte de statistiques rapides
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.analytics,
                                  color: Colors.green,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Aperçu',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildStatCard(
                                      'Surface totale',
                                      '${surfaceTotale.toStringAsFixed(2)} ha',
                                      Icons.landscape,
                                      Colors.green,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildStatCard(
                                      'Rendement $derniereAnnee',
                                      '${rendementMoyenNorme.toStringAsFixed(3)} T/ha',
                                      Icons.trending_up,
                                      Colors.blue,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildStatCard(
                                      'Poids total $derniereAnnee',
                                      '${(poidsTotalNormeAnnee / 1000).toStringAsFixed(2)} T',
                                      Icons.scale,
                                      Colors.orange,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Menu principal
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.menu,
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Menu principal',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.5,
                          children: [
                            _buildMenuCard(
                              'Parcelles',
                              Icons.landscape,
                              Colors.green,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ParcellesScreen(),
                                ),
                              ),
                            ),
                            _buildMenuCard(
                              'Cellules',
                              Icons.grid_view,
                              Colors.orange,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CellulesScreen(),
                                ),
                              ),
                            ),
                            _buildMenuCard(
                              'Chargements',
                              Icons.local_shipping,
                              Colors.blue,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ChargementsScreen(),
                                ),
                              ),
                            ),
                            _buildMenuCard(
                              'Semis',
                              Icons.grass,
                              Colors.brown,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SemisScreen(),
                                ),
                              ),
                            ),
                            _buildMenuCard(
                              'Variétés',
                              Icons.eco,
                              Colors.lightGreen,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const VarietesScreen(),
                                ),
                              ),
                            ),
                            _buildMenuCard(
                              'Statistiques',
                              Icons.bar_chart,
                              Colors.purple,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StatistiquesScreen(),
                                ),
                              ),
                            ),
                            _buildMenuCard(
                              'Import/Export',
                              Icons.import_export,
                              Colors.teal,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ImportExportScreen(),
                                ),
                              ),
                            ),
                            _buildMenuCard(
                              'Export PDF',
                              Icons.picture_as_pdf,
                              Colors.red,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ExportScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 