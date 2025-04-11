import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../models/variete.dart';

class VarieteFormScreen extends StatefulWidget {
  final Variete? variete;

  const VarieteFormScreen({super.key, this.variete});

  @override
  State<VarieteFormScreen> createState() => _VarieteFormScreenState();
}

class _VarieteFormScreenState extends State<VarieteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.variete?.nom ?? '');
    _descriptionController = TextEditingController(text: widget.variete?.description ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.variete == null ? 'Nouvelle variété' : 'Modifier la variété'),
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
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.length > 500) {
                    return 'La description ne doit pas dépasser 500 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      final variete = Variete.fromMap(
                        id: widget.variete?.id,
                        nom: _nomController.text.trim(),
                        description: _descriptionController.text.isEmpty ? null : _descriptionController.text.trim(),
                        dateCreation: widget.variete?.dateCreation ?? DateTime.now(),
                      );

                      if (widget.variete == null) {
                        await context.read<DatabaseProvider>().ajouterVariete.fromMap(variete);
                      } else {
                        await context.read<DatabaseProvider>().modifierVariete.fromMap(variete);
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
                  widget.variete == null ? 'Ajouter' : 'Modifier',
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