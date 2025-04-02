import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../models/parcelle.dart';
import '../models/chargement.dart';
import '../models/cellule.dart';
import '../models/semis.dart';
import '../models/variete_surface.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  int? _selectedYear;
  static const int ROWS_PER_PAGE = 25;

  Future<void> _generatePDF() async {
    try {
      final db = Provider.of<DatabaseProvider>(context, listen: false);
      final chargements = await db.chargements.toList();
      final parcelles = await db.parcelles.toList();
      final cellules = await db.cellules.toList();
      final semis = await db.semis.toList();
      final chargementsAnnee = chargements.where((c) => c.dateChargement.year == _selectedYear).toList();
      
      if (chargementsAnnee.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun chargement pour cette année')),
          );
        }
        return;
      }

      final pdf = pw.Document();

      // Couleurs personnalisées
      final mainColor = PdfColor.fromHex('#2E7D32'); // Vert foncé
      final secondaryColor = PdfColor.fromHex('#81C784'); // Vert clair
      final headerBgColor = PdfColor.fromHex('#E8F5E9'); // Vert très clair

      // Page de garde
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) {
            return pw.Container(
              alignment: pw.Alignment.center,
              width: double.infinity,
              height: double.infinity,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'GAEC de la BARADE',
                    style: pw.TextStyle(
                      fontSize: 45,
                      color: mainColor,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text(
                    'Récolte de Maïs',
                    style: pw.TextStyle(
                      fontSize: 35,
                      color: secondaryColor,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 60),
                  pw.Text(
                    'Année $_selectedYear',
                    style: const pw.TextStyle(
                      fontSize: 30,
                      color: PdfColors.black,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Variables pour le résumé final
      double poidsNetTotalGlobal = 0;
      double poidsNormesTotalGlobal = 0;
      double surfaceTotale = 0;
      int currentPage = 1;
      int totalPages = 1;

      // Calculer le nombre total de pages
      for (var parcelle in parcelles) {
        final chargementsP = chargementsAnnee.where((c) => c.parcelleId == parcelle.id).toList();
        if (chargementsP.isNotEmpty) {
          totalPages += (chargementsP.length / 25).ceil();
        }
      }
      if (parcelles.isNotEmpty) totalPages += 1; // Page de résumé

      // Pour chaque parcelle
      for (var parcelle in parcelles) {
        final chargementsP = chargementsAnnee
            .where((c) => c.parcelleId == parcelle.id)
            .toList()
          ..sort((a, b) => a.dateChargement.compareTo(b.dateChargement));

        if (chargementsP.isEmpty) continue;

        surfaceTotale += parcelle.surface;
        double poidsNetTotal = 0;
        double poidsNormesTotal = 0;
        double humiditeTotale = 0;

        for (var c in chargementsP) {
          poidsNetTotal += c.poidsNet ?? 0;
          poidsNormesTotal += c.poidsNormes ?? 0;
          humiditeTotale += c.humidite ?? 0;
        }

        poidsNetTotalGlobal += poidsNetTotal;
        poidsNormesTotalGlobal += poidsNormesTotal;
        final humiditeMoyenne = chargementsP.isEmpty ? 0 : humiditeTotale / chargementsP.length;

        // Diviser les chargements en pages de 25 lignes
        for (var i = 0; i < chargementsP.length; i += 25) {
          final pageChargements = chargementsP.skip(i).take(25).toList();
          
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4.landscape,
              build: (context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      color: headerBgColor,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Row(
                              children: [
                                pw.Text(
                                  'Parcelle: ${parcelle.nom}',
                                  style: pw.TextStyle(
                                    fontSize: 20,
                                    fontWeight: pw.FontWeight.bold,
                                    color: mainColor,
                                  ),
                                ),
                                pw.SizedBox(width: 20),
                                pw.Text(
                                  'Surface: ${parcelle.surface.toStringAsFixed(2)} ha',
                                  style: pw.TextStyle(
                                    fontSize: 16,
                                    color: mainColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.Text(
                            'Rendement: ${(poidsNormesTotal / 1000 / parcelle.surface).toStringAsFixed(2)} t/ha',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: mainColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    pw.SizedBox(height: 10),
                    
                    pw.Table(
                      border: pw.TableBorder.all(
                        color: PdfColors.grey400,
                        width: 0.5,
                      ),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(1.5), // DATE
                        1: const pw.FlexColumnWidth(2), // REMORQUE
                        2: const pw.FlexColumnWidth(1.5), // POIDS PLEIN
                        3: const pw.FlexColumnWidth(1.5), // POIDS VIDE
                        4: const pw.FlexColumnWidth(1.5), // POIDS NET
                        5: const pw.FlexColumnWidth(1), // HUMIDITE
                        6: const pw.FlexColumnWidth(1.5), // POIDS AU NORME
                        7: const pw.FlexColumnWidth(2), // VARIETE
                      },
                      children: [
                        pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: mainColor,
                          ),
                          children: [
                            _buildHeaderCell('DATE'),
                            _buildHeaderCell('REMORQUE'),
                            _buildHeaderCell('POIDS PLEIN'),
                            _buildHeaderCell('POIDS VIDE'),
                            _buildHeaderCell('POIDS NET'),
                            _buildHeaderCell('HUMIDITÉ'),
                            _buildHeaderCell('POIDS NORME'),
                            _buildHeaderCell('VARIÉTÉ'),
                          ],
                        ),
                        ...pageChargements.map((c) => pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: pageChargements.indexOf(c) % 2 == 0 
                                ? PdfColors.white 
                                : PdfColors.grey200,
                          ),
                          children: [
                            _buildDataCell('${c.dateChargement.day}/${c.dateChargement.month}'),
                            _buildDataCell(c.remorque ?? ''),
                            _buildDataCell('${c.poidsPlein?.toStringAsFixed(2) ?? ''}'),
                            _buildDataCell('${c.poidsVide?.toStringAsFixed(2) ?? ''}'),
                            _buildDataCell('${c.poidsNet?.toStringAsFixed(2) ?? ''}'),
                            _buildDataCell('${c.humidite?.toStringAsFixed(1) ?? ''}%'),
                            _buildDataCell('${c.poidsNormes?.toStringAsFixed(2) ?? ''}'),
                            _buildDataCell(c.variete ?? 'Inconnue'),
                          ],
                        )),
                      ],
                    ),
                    
                    pw.Spacer(),
                    
                    // Totaux de la parcelle
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Total Poids Net: ${(poidsNetTotal / 1000).toStringAsFixed(2)} t',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: mainColor,
                            ),
                          ),
                          pw.Text(
                            'Total Poids Normes: ${(poidsNormesTotal / 1000).toStringAsFixed(2)} t',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: mainColor,
                            ),
                          ),
                          pw.Text(
                            'Humidité Moyenne: ${humiditeMoyenne.toStringAsFixed(1)}%',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: mainColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    pw.Text(
                      'Page ${currentPage++}/$totalPages',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        color: PdfColors.grey700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }
      }

      // Page de résumé global
      if (surfaceTotale > 0) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    color: headerBgColor,
                    child: pw.Text(
                      'Résumé Global',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: mainColor,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoBox('Surface totale cultivée', '${surfaceTotale.toStringAsFixed(2)} ha'),
                      _buildInfoBox('Poids net total', '${(poidsNetTotalGlobal / 1000).toStringAsFixed(2)} tonnes'),
                      _buildInfoBox('Poids aux normes total', '${(poidsNormesTotalGlobal / 1000).toStringAsFixed(2)} tonnes'),
                      _buildInfoBox('Rendement moyen', '${(poidsNormesTotalGlobal / 1000 / surfaceTotale).toStringAsFixed(2)} t/ha'),
                    ],
                  ),
                  pw.SizedBox(height: 30),
                  pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfColors.grey400,
                      width: 0.5,
                    ),
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: mainColor,
                        ),
                        children: [
                          _buildHeaderCell('PARCELLE'),
                          _buildHeaderCell('SURFACE (ha)'),
                          _buildHeaderCell('VARIÉTÉ'),
                          _buildHeaderCell('POIDS NET (t)'),
                          _buildHeaderCell('POIDS NORMES (t)'),
                          _buildHeaderCell('RENDEMENT (t/ha)'),
                        ],
                      ),
                      ...parcelles.where((p) {
                        final parcelleChargements = chargementsAnnee
                            .where((c) => c.parcelleId == p.id)
                            .toList();
                        return parcelleChargements.isNotEmpty;
                      }).map((p) {
                        final parcelleChargements = chargementsAnnee
                            .where((c) => c.parcelleId == p.id)
                            .toList();
                        double poidsNet = 0;
                        double poidsNormes = 0;
                        
                        for (var c in parcelleChargements) {
                          poidsNet += c.poidsNet ?? 0;
                          poidsNormes += c.poidsNormes ?? 0;
                        }
                        
                        return pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: parcelles.indexOf(p) % 2 == 0 
                                ? PdfColors.white 
                                : PdfColors.grey200,
                          ),
                          children: [
                            _buildDataCell(p.nom),
                            _buildDataCell(p.surface.toStringAsFixed(2)),
                            _buildDataCell(db.getVarieteForParcelle(p.id)?.nom ?? "Inconnue"),
                            _buildDataCell((poidsNet / 1000).toStringAsFixed(2)),
                            _buildDataCell((poidsNormes / 1000).toStringAsFixed(2)),
                            _buildDataCell((poidsNormes / 1000 / p.surface).toStringAsFixed(2)),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                  pw.Spacer(),
                  pw.Text(
                    'Page $totalPages/$totalPages',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      color: PdfColors.grey700,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      // Ajouter une page de résumé par variété
      final varietesMap = <String, Map<String, dynamic>>{};
      
      // Première passe : initialiser les données pour chaque variété
      for (var chargement in chargementsAnnee) {
        final variete = chargement.variete ?? 'Inconnue';
        if (!varietesMap.containsKey(variete)) {
          varietesMap[variete] = {
            'poidsNet': 0.0,
            'poidsNormes': 0.0,
            'surface': 0.0,
            'chargements': <Chargement>[],
          };
        }
        
        varietesMap[variete]!['poidsNet'] += chargement.poidsNet ?? 0;
        varietesMap[variete]!['poidsNormes'] += chargement.poidsNormes ?? 0;
        varietesMap[variete]!['chargements'].add(chargement);
      }

      // Récupérer les semis de l'année sélectionnée
      final semisAnnee = semis
          .where((s) => s.date.year == _selectedYear)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      // Pour chaque parcelle, prendre le dernier semis de l'année
      for (var parcelle in parcelles) {
        final parcelleId = parcelle.id;
        if (parcelleId == null) continue;

        // Trouver le dernier semis pour cette parcelle
        final dernierSemis = semisAnnee
            .where((s) => s.parcelleId == parcelleId)
            .toList();

        if (dernierSemis.isNotEmpty) {
          // Prendre le semis le plus récent
          final semisParcelle = dernierSemis.first;
          
          // Pour chaque variété dans le semis
          for (var varieteSurface in semisParcelle.varietesSurfaces) {
            final variete = varieteSurface.nom;
            final pourcentage = varieteSurface.pourcentage;
            
            // Si la variété n'est pas encore dans le map, l'ajouter
            if (!varietesMap.containsKey(variete)) {
              varietesMap[variete] = {
                'poidsNet': 0.0,
                'poidsNormes': 0.0,
                'surface': 0.0,
                'chargements': <Chargement>[],
              };
            }
            
            // Ajouter la surface proportionnelle à la variété
            varietesMap[variete]!['surface'] += parcelle.surface * (pourcentage / 100);
          }
        }
      }

      // Ajouter la page de résumé par variété
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  color: headerBgColor,
                  child: pw.Text(
                    'Résumé par Variété',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: mainColor,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey400,
                    width: 0.5,
                  ),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: mainColor,
                      ),
                      children: [
                        _buildHeaderCell('VARIÉTÉ'),
                        _buildHeaderCell('SURFACE (ha)'),
                        _buildHeaderCell('POIDS NET (t)'),
                        _buildHeaderCell('POIDS NORMES (t)'),
                        _buildHeaderCell('RENDEMENT (t/ha)'),
                        _buildHeaderCell('NOMBRE DE CHARGEMENTS'),
                      ],
                    ),
                    ...varietesMap.entries.map((entry) {
                      final variete = entry.key;
                      final data = entry.value;
                      final poidsNet = data['poidsNet'] as double;
                      final poidsNormes = data['poidsNormes'] as double;
                      final surface = data['surface'] as double;
                      final chargements = data['chargements'] as List<Chargement>;
                      
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: varietesMap.keys.toList().indexOf(variete) % 2 == 0 
                              ? PdfColors.white 
                              : PdfColors.grey200,
                        ),
                        children: [
                          _buildDataCell(variete),
                          _buildDataCell(surface.toStringAsFixed(2)),
                          _buildDataCell((poidsNet / 1000).toStringAsFixed(2)),
                          _buildDataCell((poidsNormes / 1000).toStringAsFixed(2)),
                          _buildDataCell((poidsNormes / 1000 / surface).toStringAsFixed(2)),
                          _buildDataCell(chargements.length.toString()),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                pw.Spacer(),
                pw.Text(
                  'Page ${totalPages + 1}/${totalPages + 1}',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    color: PdfColors.grey700,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'recolte_${_selectedYear}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF généré avec succès'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la génération du PDF: $e')),
        );
      }
    }
  }

  pw.Widget _buildHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 12,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildDataCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildInfoBox(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export PDF'),
        backgroundColor: Colors.orange,
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, provider, child) {
          final years = provider.chargements
              .map((c) => c.dateChargement.year)
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));

          if (years.isEmpty) {
            return const Center(
              child: Text('Aucune donnée disponible pour l\'export'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  value: _selectedYear,
                  decoration: const InputDecoration(
                    labelText: 'Année',
                    border: OutlineInputBorder(),
                  ),
                  items: years.map((year) {
                    return DropdownMenuItem(
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
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _selectedYear == null
                      ? null
                      : () => _generatePDF(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Générer PDF'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 