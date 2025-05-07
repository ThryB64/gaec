import 'package:cloud_firestore/cloud_firestore.dart';

class Cellule {
  int? id;
  final String reference;
  final double capacite;
  final DateTime dateCreation;
  final String? notes;
  final String? documentId; // ID du document Firestore

  Cellule({
    this.id,
    String? reference,
    DateTime? dateCreation,
    this.notes,
    this.documentId,
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

  Map<String, dynamic> toFirestore() {
    return {
      'reference': reference,
      'capacite': capacite,
      'date_creation': Timestamp.fromDate(dateCreation),
      'notes': notes,
    };
  }

  factory Cellule.fromMap(Map<String, dynamic> map) {
    return Cellule(
      id: map['id'],
      reference: map['reference'],
      dateCreation: DateTime.parse(map['date_creation']),
      notes: map['notes'],
    );
  }

  factory Cellule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Cellule(
      documentId: doc.id,
      reference: data['reference'] ?? _generateReference(DateTime.now()),
      dateCreation: (data['date_creation'] as Timestamp).toDate(),
      notes: data['notes'],
    );
  }

  Cellule copyWith({
    int? id,
    String? reference,
    double? capacite,
    DateTime? dateCreation,
    String? notes,
    String? documentId,
  }) {
    return Cellule(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      dateCreation: dateCreation ?? this.dateCreation,
      notes: notes ?? this.notes,
      documentId: documentId ?? this.documentId,
    );
  }

  @override
  String toString() => 'Cellule(id: $id, reference: $reference, capacite: $capacite)';
} 