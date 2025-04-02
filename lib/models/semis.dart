import 'dart:convert';
import 'variete_surface.dart';

class Semis {
  int? id;
  final int parcelleId;
  final DateTime date;
  final List<VarieteSurface> varietesSurfaces;
  final String? notes;

  Semis({
    this.id,
    required this.parcelleId,
    required this.date,
    required this.varietesSurfaces,
    this.notes,
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

  @override
  String toString() => 'Semis(id: $id, parcelleId: $parcelleId, date: $date, varietesSurfaces: $varietesSurfaces)';
} 