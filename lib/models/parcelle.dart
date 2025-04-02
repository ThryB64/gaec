class Parcelle {
  int? id;
  final String nom;
  final double surface;
  final DateTime dateCreation;
  final String? notes;

  Parcelle({
    this.id,
    required this.nom,
    required this.surface,
    DateTime? dateCreation,
    this.notes,
  }) : dateCreation = dateCreation ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'surface': surface,
      'date_creation': dateCreation.toIso8601String(),
      'notes': notes,
    };
  }

  factory Parcelle.fromMap(Map<String, dynamic> map) {
    return Parcelle(
      id: map['id'],
      nom: map['nom'],
      surface: map['surface'],
      dateCreation: DateTime.parse(map['date_creation']),
      notes: map['notes'],
    );
  }

  @override
  String toString() => 'Parcelle(id: $id, nom: $nom, surface: $surface)';
} 