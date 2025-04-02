import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../models/chargement.dart';
import '../models/cellule.dart';
import '../models/parcelle.dart';
import '../utils/poids_utils.dart';

class ChargementFormScreen extends StatefulWidget {
  final Chargement? chargement;

  const ChargementFormScreen({super.key, this.chargement});

  @override
  State<ChargementFormScreen> createState() => _ChargementFormScreenState();
}

class _ChargementFormScreenState extends State<ChargementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _poidsPleinController;
  late TextEditingController _poidsVideController;
  late TextEditingController _humiditeController;
  String? _selectedRemorque;
  int? _selectedParcelleId;
  int? _selectedCelluleId;
  int? _selectedYear;
  String? _selectedVariete;

  final List<String> _remorques = ['Duchesne', 'Leboulch', 'Maupu', 'Autres'];

  @override
  void initState() {
    super.initState();
    _poidsPleinController = TextEditingController(text: widget.chargement?.poidsPlein.toString() ?? '');
    _poidsVideController = TextEditingController(text: widget.chargement?.poidsVide.toString() ?? '');
    _humiditeController = TextEditingController(text: widget.chargement?.humidite.toString() ?? '');
    _selectedRemorque = widget.chargement?.remorque;
    _selectedParcelleId = widget.chargement?.parcelleId;
    _selectedCelluleId = widget.chargement?.celluleId;
    _selectedVariete = widget.chargement?.variete;

    // Si c'est un nouveau chargement, sélectionner automatiquement la dernière parcelle et le dernier silo utilisés
    if (widget.chargement == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<DatabaseProvider>();
        if (provider.chargements.isNotEmpty) {
          final dernierChargement = provider.chargements.first;
          setState(() {
            _selectedParcelleId = dernierChargement.parcelleId;
            _selectedCelluleId = dernierChargement.celluleId;
            _selectedYear = dernierChargement.dateChargement.year;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _poidsPleinController.dispose();
    _poidsVideController.dispose();
    _humiditeController.dispose();
    super.dispose();
  }

  List<String> _getVarietesDisponibles(DatabaseProvider provider) {
    if (_selectedParcelleId == null || _selectedYear == null) return [];

    final semisAnnee = provider.semis.where((s) => 
      s.parcelleId == _selectedParcelleId && 
      s.date.year == _selectedYear
    ).toList();

    final varietes = <String>{};
    for (var semis in semisAnnee) {
      varietes.addAll(semis.varietes);
    }
    return varietes.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chargement == null ? 'Nouveau chargement' : 'Modifier le chargement'),
        backgroundColor: Colors.orange,
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, provider, child) {
          final annees = provider.chargements
              .map((c) => c.dateChargement.year)
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));

          if (annees.isEmpty) {
            annees.add(DateTime.now().year);
          }

          final cellulesAnnee = provider.cellules
              .where((c) => c.dateCreation.year == (_selectedYear ?? DateTime.now().year))
              .toList();

          final varietesDisponibles = _getVarietesDisponibles(provider);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
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
                        _selectedCelluleId = null;
                        _selectedVariete = null;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner une année';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedParcelleId,
                    decoration: const InputDecoration(
                      labelText: 'Parcelle',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.parcelles.map((parcelle) {
                      return DropdownMenuItem(
                        value: parcelle.id,
                        child: Text(parcelle.nom),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedParcelleId = value;
                        _selectedVariete = null;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner une parcelle';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (varietesDisponibles.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: _selectedVariete,
                      decoration: const InputDecoration(
                        labelText: 'Variété',
                        border: OutlineInputBorder(),
                      ),
                      items: varietesDisponibles.map((variete) {
                        return DropdownMenuItem(
                          value: variete,
                          child: Text(variete),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedVariete = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Veuillez sélectionner une variété';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedCelluleId,
                    decoration: const InputDecoration(
                      labelText: 'Cellule',
                      border: OutlineInputBorder(),
                    ),
                    items: cellulesAnnee.map((cellule) {
                      return DropdownMenuItem(
                        value: cellule.id,
                        child: Text(cellule.reference),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCelluleId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner une cellule';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRemorque,
                    decoration: const InputDecoration(
                      labelText: 'Remorque',
                      border: OutlineInputBorder(),
                    ),
                    items: _remorques.map((remorque) {
                      return DropdownMenuItem(
                        value: remorque,
                        child: Text(remorque),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRemorque = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner une remorque';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _poidsPleinController,
                    decoration: const InputDecoration(
                      labelText: 'Poids plein (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer le poids plein';
                      }
                      final poids = double.tryParse(value);
                      if (poids == null || poids <= 0) {
                        return 'Veuillez entrer un poids valide';
                      }
                      return null;
                    },
                    onChanged: _calculerPoidsNet,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _poidsVideController,
                    decoration: const InputDecoration(
                      labelText: 'Poids vide (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer le poids vide';
                      }
                      final poids = double.tryParse(value);
                      if (poids == null || poids <= 0) {
                        return 'Veuillez entrer un poids valide';
                      }
                      return null;
                    },
                    onChanged: _calculerPoidsNet,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _humiditeController,
                    decoration: const InputDecoration(
                      labelText: 'Humidité (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer l\'humidité';
                      }
                      final humidite = double.tryParse(value);
                      if (humidite == null || humidite < 0 || humidite > 100) {
                        return 'Veuillez entrer une humidité valide (0-100)';
                      }
                      return null;
                    },
                    onChanged: _calculerPoidsNet,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          final poidsPlein = double.parse(_poidsPleinController.text);
                          final poidsVide = double.parse(_poidsVideController.text);
                          final humidite = double.parse(_humiditeController.text);
                          final poidsNet = poidsPlein - poidsVide;
                          final poidsNormes = PoidsUtils.calculPoidsNormes(poidsNet, humidite);

                          final chargement = Chargement(
                            id: widget.chargement?.id,
                            celluleId: _selectedCelluleId!,
                            parcelleId: _selectedParcelleId!,
                            remorque: _selectedRemorque!,
                            dateChargement: DateTime.now(),
                            poidsPlein: poidsPlein,
                            poidsVide: poidsVide,
                            poidsNet: poidsNet,
                            poidsNormes: poidsNormes,
                            humidite: humidite,
                            variete: _selectedVariete!,
                          );

                          final provider = context.read<DatabaseProvider>();
                          if (widget.chargement == null) {
                            await provider.ajouterChargement(chargement);
                          } else {
                            await provider.modifierChargement(chargement);
                          }

                          if (mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      widget.chargement == null ? 'Ajouter' : 'Modifier',
                      style: const TextStyle(fontSize: 16),
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

  void _calculerPoidsNet(String _) {
    if (_poidsPleinController.text.isNotEmpty && _poidsVideController.text.isNotEmpty) {
      final poidsPlein = double.tryParse(_poidsPleinController.text);
      final poidsVide = double.tryParse(_poidsVideController.text);
      if (poidsPlein != null && poidsVide != null) {
        final poidsNet = poidsPlein - poidsVide;
        if (poidsNet > 0) {
          setState(() {
            // Mettre à jour l'affichage du poids net si nécessaire
          });
        }
      }
    }
  }
} 