import 'package:cloud_firestore/cloud_firestore.dart';

class Parcelle {
  int? id;
  final String nom;
  final double surface;
  final DateTime dateCreation;
  final String? notes;
  final String? documentId; // ID du document Firestore

  Parcelle({
    this.id,
    required this.nom,
    required this.surface,
    DateTime? dateCreation,
    this.notes,
    this.documentId,
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

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'surface': surface,
      'date_creation': Timestamp.fromDate(dateCreation),
      'notes': notes,
    };
  }

  factory Parcelle.fromMap(Map<String, dynamic> map) {
    return Parcelle(
      id: map['id'],
      nom: map['nom'],
      surface: map['surface'] is int ? (map['surface'] as int).toDouble() : map['surface'],
      dateCreation: DateTime.parse(map['date_creation']),
      notes: map['notes'],
    );
  }

  factory Parcelle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Parcelle(
      documentId: doc.id,
      nom: data['nom'] ?? '',
      surface: (data['surface'] ?? 0.0).toDouble(),
      dateCreation: (data['date_creation'] as Timestamp).toDate(),
      notes: data['notes'],
    );
  }

  Parcelle copyWith({
    int? id,
    String? nom,
    double? surface,
    DateTime? dateCreation,
    String? notes,
    String? documentId,
  }) {
    return Parcelle(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      surface: surface ?? this.surface,
      dateCreation: dateCreation ?? this.dateCreation,
      notes: notes ?? this.notes,
      documentId: documentId ?? this.documentId,
    );
  }

  @override
  String toString() => 'Parcelle(id: $id, nom: $nom, surface: $surface)';
} 