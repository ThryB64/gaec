import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../models/variete.dart';
import 'variete_form_screen.dart';

class VarietesScreen extends StatelessWidget {
  const VarietesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Variétés'),
        backgroundColor: Colors.orange,
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, provider, child) {
          final varietes = provider.varietes;

          if (varietes.isEmpty) {
            return const Center(
              child: Text('Aucune variété enregistrée'),
            );
          }

          return ListView.builder(
            itemCount: varietes.length,
            itemBuilder: (context, index) {
              final variete = varietes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(variete.nom),
                  subtitle: Text(variete.description ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VarieteFormScreen(
                                variete: variete,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirmation'),
                              content: Text('Voulez-vous supprimer la variété "${variete.nom}" ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    provider.supprimerVariete(variete.id!);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VarieteFormScreen(),
            ),
          );
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
} 