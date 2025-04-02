class Variete {
  int? id;
  final String nom;
  final String? description;
  final DateTime dateCreation;

  Variete({
    this.id,
    required this.nom,
    this.description,
    required this.dateCreation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'date_creation': dateCreation.toIso8601String(),
    };
  }

  factory Variete.fromMap(Map<String, dynamic> map) {
    return Variete(
      id: map['id'],
      nom: map['nom'],
      description: map['description'],
      dateCreation: DateTime.parse(map['date_creation']),
    );
  }

  @override
  String toString() => 'Variete(id: $id, nom: $nom)';
} 