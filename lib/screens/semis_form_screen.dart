import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../models/semis.dart';
import '../models/variete_surface.dart';

class SemisFormScreen extends StatefulWidget {
  final Semis? semis;

  const SemisFormScreen({super.key, this.semis});

  @override
  State<SemisFormScreen> createState() => _SemisFormScreenState();
}

class _SemisFormScreenState extends State<SemisFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  late TextEditingController _notesController;
  int? _selectedParcelleId;
  List<VarieteSurface> _selectedVarietesSurfaces = [];
  bool _showPourcentages = false;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
      text: widget.semis?.date != null
          ? _formatDate(widget.semis!.date)
          : _formatDate(DateTime.now()),
    );
    _notesController = TextEditingController(text: widget.semis?.notes ?? '');
    _selectedParcelleId = widget.semis?.parcelleId;
    _selectedVarietesSurfaces = widget.semis?.varietesSurfaces ?? [];
    _showPourcentages = _selectedVarietesSurfaces.isNotEmpty;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.semis?.date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != widget.semis?.date) {
      setState(() {
        _dateController.text = _formatDate(picked);
      });
    }
  }

  Widget _buildVarietesSection(DatabaseProvider provider) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Variétés',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            children: provider.varietes.map((variete) {
              final isSelected = _selectedVarietesSurfaces.any((v) => v.nom == variete.nom);
              return FilterChip(
                label: Text(variete.nom),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedVarietesSurfaces.add(VarieteSurface(
                        nom: variete.nom,
                        pourcentage: 0,
                      ));
                    } else {
                      _selectedVarietesSurfaces.removeWhere((v) => v.nom == variete.nom);
                    }
                    _showPourcentages = _selectedVarietesSurfaces.isNotEmpty;
                  });
                },
              );
            }).toList(),
          ),
          if (_selectedVarietesSurfaces.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Veuillez sélectionner au moins une variété',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPourcentagesSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Pourcentages de surface',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedVarietesSurfaces.length,
            itemBuilder: (context, index) {
              final varieteSurface = _selectedVarietesSurfaces[index];
              return ListTile(
                title: Text(varieteSurface.nom),
                trailing: SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: varieteSurface.pourcentage > 0 
                        ? varieteSurface.pourcentage.toString()
                        : '',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      suffix: Text('%'),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final pourcentage = double.tryParse(value) ?? 0;
                      setState(() {
                        _selectedVarietesSurfaces[index] = VarieteSurface(
                          nom: varieteSurface.nom,
                          pourcentage: pourcentage,
                        );
                      });
                    },
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final pourcentage = double.tryParse(value);
                        if (pourcentage == null || pourcentage < 0 || pourcentage > 100) {
                          return 'Pourcentage invalide';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Total : ${_selectedVarietesSurfaces.fold<double>(0, (sum, v) => sum + v.pourcentage)}%',
              style: TextStyle(
                color: _selectedVarietesSurfaces.fold<double>(0, (sum, v) => sum + v.pourcentage) == 100
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.semis == null ? 'Nouveau semis' : 'Modifier le semis'),
        backgroundColor: Colors.orange,
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, provider, child) {
          // Obtenir l'année en cours
          final anneeEnCours = DateTime.now().year;

          // Obtenir les parcelles qui ont déjà un semis cette année
          final parcellesAvecSemis = provider.semis
              .where((s) => s.date.year == anneeEnCours)
              .map((s) => s.parcelleId)
              .toSet();

          // Filtrer les parcelles pour ne garder que celles sans semis
          final parcellesDisponibles = provider.parcelles
              .where((p) => !parcellesAvecSemis.contains(p.id))
              .toList();

          // Si on modifie un semis existant, ajouter sa parcelle à la liste
          if (widget.semis != null) {
            final parcelleDuSemis = provider.parcelles
                .firstWhere((p) => p.id == widget.semis!.parcelleId);
            if (!parcellesDisponibles.contains(parcelleDuSemis)) {
              parcellesDisponibles.add(parcelleDuSemis);
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    value: _selectedParcelleId,
                    decoration: const InputDecoration(
                      labelText: 'Parcelle',
                      border: OutlineInputBorder(),
                    ),
                    items: parcellesDisponibles.map((parcelle) {
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
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner une parcelle';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildVarietesSection(provider),
                  if (_showPourcentages) ...[
                    const SizedBox(height: 16),
                    _buildPourcentagesSection(),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'Date',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context),
                      ),
                    ),
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner une date';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value != null && value.length > 500) {
                        return 'Les notes ne doivent pas dépasser 500 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        if (_selectedVarietesSurfaces.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Veuillez sélectionner au moins une variété'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final total = _selectedVarietesSurfaces.fold<double>(0, (sum, v) => sum + v.pourcentage);
                        if (total != 100) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Le total des pourcentages doit être égal à 100%'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          final dateParts = _dateController.text.split('/');
                          final date = DateTime(
                            int.parse(dateParts[2]),
                            int.parse(dateParts[1]),
                            int.parse(dateParts[0]),
                          );

                          final semis = Semis(
                            id: widget.semis?.id,
                            parcelleId: _selectedParcelleId!,
                            varietesSurfaces: _selectedVarietesSurfaces,
                            date: date,
                            notes: _notesController.text.isEmpty ? null : _notesController.text.trim(),
                          );

                          if (widget.semis == null) {
                            await provider.ajouterSemis(semis);
                          } else {
                            await provider.modifierSemis(semis);
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
                      widget.semis == null ? 'Ajouter' : 'Modifier',
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
} 