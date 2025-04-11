class Cellule {
  int? id;
  final String reference;
  final double capacite;
  final DateTime dateCreation;
  final String? notes;

  Cellule.fromMap({
    this.id,
    String? reference,
    DateTime? dateCreation,
    this.notes,
  }) : dateCreation = dateCreation ?? DateTime.now(),
       reference = reference ?? _generateReference(dateCreation ?? DateTime.now()),
       capacite = 320000; // 320T en kg

  static String _generateReference(DateTime date) {
    return 'CELLULE_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reference': reference,
      'capacite': capacite,
      'date_creation': dateCreation.toIso8601String(),
      'notes': notes,
    };
  }

  factory Cellule.fromMap(Map<String, dynamic> map) {
    return Cellule.fromMap(
      id: map['id'],
      reference: map['reference'],
      dateCreation: DateTime.parse(map['date_creation']),
      notes: map['notes'],
    );
  }

  @override
  String toString() => 'Cellule.fromMap(id: $id, reference: $reference, capacite: $capacite)';
} 