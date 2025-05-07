import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'variete_surface.dart';

class Semis {
  int? id;
  final int parcelleId;
  final DateTime date;
  final List<VarieteSurface> varietesSurfaces;
  final String? notes;
  final String? documentId; // ID du document Firestore

  Semis({
    this.id,
    required this.parcelleId,
    required this.date,
    required this.varietesSurfaces,
    this.notes,
    this.documentId,
  });

  // Getter pour la compatibilité avec le code existant
  List<String> get varietes => varietesSurfaces.map((v) => v.nom).toList();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parcelle_id': parcelleId,
      'date': date.toIso8601String(),
      'varietes_surfaces': jsonEncode(varietesSurfaces.map((v) => v.toMap()).toList()),
      'notes': notes,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'parcelle_id': parcelleId,
      'date': Timestamp.fromDate(date),
      'varietes_surfaces': varietesSurfaces.map((v) => v.toMap()).toList(),
      'notes': notes,
    };
  }

  factory Semis.fromMap(Map<String, dynamic> map) {
    final List<dynamic> varietesData = jsonDecode(map['varietes_surfaces']);
    return Semis(
      id: map['id'],
      parcelleId: map['parcelle_id'],
      date: DateTime.parse(map['date']),
      varietesSurfaces: varietesData.map((v) => VarieteSurface.fromMap(v)).toList(),
      notes: map['notes'],
    );
  }

  factory Semis.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Semis(
      documentId: doc.id,
      parcelleId: data['parcelle_id'] ?? 0,
      date: (data['date'] as Timestamp).toDate(),
      varietesSurfaces: (data['varietes_surfaces'] as List<dynamic>)
          .map((v) => VarieteSurface.fromMap(v))
          .toList(),
      notes: data['notes'],
    );
  }

  Semis copyWith({
    int? id,
    int? parcelleId,
    DateTime? date,
    List<VarieteSurface>? varietesSurfaces,
    String? notes,
    String? documentId,
  }) {
    return Semis(
      id: id ?? this.id,
      parcelleId: parcelleId ?? this.parcelleId,
      date: date ?? this.date,
      varietesSurfaces: varietesSurfaces ?? this.varietesSurfaces,
      notes: notes ?? this.notes,
      documentId: documentId ?? this.documentId,
    );
  }

  @override
  String toString() => 'Semis(id: $id, parcelleId: $parcelleId, date: $date, varietesSurfaces: $varietesSurfaces)';
} 