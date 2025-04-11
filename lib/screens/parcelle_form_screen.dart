import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../models/parcelle.dart';

class ParcelleFormScreen extends StatefulWidget {
  final Parcelle? parcelle;

  const ParcelleFormScreen({super.key, this.parcelle});

  @override
  State<ParcelleFormScreen> createState() => _ParcelleFormScreenState();
}

class _ParcelleFormScreenState extends State<ParcelleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _surfaceController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.parcelle?.nom ?? '');
    _surfaceController = TextEditingController(text: widget.parcelle?.surface.toString() ?? '');
    _notesController = TextEditingController(text: widget.parcelle?.notes ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _surfaceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parcelle == null ? 'Nouvelle parcelle' : 'Modifier la parcelle'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  if (value.length < 2) {
                    return 'Le nom doit contenir au moins 2 caractères';
                  }
                  if (value.length > 50) {
                    return 'Le nom ne doit pas dépasser 50 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _surfaceController,
                decoration: const InputDecoration(
                  labelText: 'Surface (ha)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une surface';
                  }
                  final surface = double.tryParse(value);
                  if (surface == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  if (surface <= 0) {
                    return 'La surface doit être positive';
                  }
                  if (surface > 1000) {
                    return 'La surface ne peut pas dépasser 1000 ha';
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
                    try {
                      final parcelle = Parcelle(
                        id: widget.parcelle?.id,
                        nom: _nomController.text.trim(),
                        surface: double.parse(_surfaceController.text),
                        dateCreation: widget.parcelle?.dateCreation ?? DateTime.now(),
                        notes: _notesController.text.isEmpty ? null : _notesController.text.trim(),
                      );

                      if (widget.parcelle == null) {
                        await context.read<DatabaseProvider>().ajouterParcelle(parcelle);
                      } else {
                        await context.read<DatabaseProvider>().modifierParcelle(parcelle);
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
                  widget.parcelle == null ? 'Ajouter' : 'Modifier',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 