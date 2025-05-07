import 'package:cloud_firestore/cloud_firestore.dart';

class Variete {
  final int? id;
  final String? documentId;
  final String nom;
  final String? description;
  final DateTime dateCreation;

  Variete({
    this.id,
    this.documentId,
    required this.nom,
    this.description,
    required this.dateCreation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'nom': nom,
      'description': description,
      'date_creation': dateCreation.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'description': description,
      'date_creation': Timestamp.fromDate(dateCreation),
    };
  }

  factory Variete.fromMap(Map<String, dynamic> map) {
    return Variete(
      id: map['id'] as int?,
      documentId: map['document_id'] as String?,
      nom: map['nom'] as String,
      description: map['description'] as String?,
      dateCreation: DateTime.parse(map['date_creation'] as String),
    );
  }

  factory Variete.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Variete(
      documentId: doc.id,
      nom: data['nom'] as String,
      description: data['description'] as String?,
      dateCreation: (data['date_creation'] as Timestamp).toDate(),
    );
  }

  Variete copyWith({
    int? id,
    String? documentId,
    String? nom,
    String? description,
    DateTime? dateCreation,
  }) {
    return Variete(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }

  @override
  String toString() => 'Variete(id: $id, nom: $nom)';
} 