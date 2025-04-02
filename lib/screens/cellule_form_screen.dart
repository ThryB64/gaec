import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../models/cellule.dart';

class CelluleFormScreen extends StatefulWidget {
  final Cellule? cellule;

  const CelluleFormScreen({super.key, this.cellule});

  @override
  State<CelluleFormScreen> createState() => _CelluleFormScreenState();
}

class _CelluleFormScreenState extends State<CelluleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.cellule?.dateCreation.year ?? DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cellule == null ? 'Nouvelle cellule' : 'Modifier la cellule'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
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
                items: List.generate(20, (index) {
                  final year = 2020 + index;
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    _selectedYear = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner une année';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      final dateCreation = DateTime(_selectedYear!, DateTime.now().month, DateTime.now().day);
                      final cellule = Cellule(
                        id: widget.cellule?.id,
                        dateCreation: dateCreation,
                      );

                      if (widget.cellule == null) {
                        await context.read<DatabaseProvider>().ajouterCellule(cellule);
                      } else {
                        await context.read<DatabaseProvider>().modifierCellule(cellule);
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
                  widget.cellule == null ? 'Ajouter' : 'Modifier',
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