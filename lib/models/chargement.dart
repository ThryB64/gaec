import 'package:cloud_firestore/cloud_firestore.dart';

class Chargement {
  int? id;
  final int celluleId;
  final int parcelleId;
  final String remorque;
  final DateTime dateChargement;
  final double poidsPlein;
  final double poidsVide;
  double _poidsNet;
  double _poidsNormes;
  final double humidite;
  final String variete;
  final String? documentId; // ID du document Firestore

  Chargement({
    this.id,
    required this.celluleId,
    required this.parcelleId,
    required this.remorque,
    required this.dateChargement,
    required this.poidsPlein,
    required this.poidsVide,
    required double poidsNet,
    required double poidsNormes,
    required this.humidite,
    required this.variete,
    this.documentId,
  }) : _poidsNet = poidsNet,
       _poidsNormes = poidsNormes;

  double get poidsNet => _poidsNet;
  set poidsNet(double value) => _poidsNet = value;

  double get poidsNormes => _poidsNormes;
  set poidsNormes(double value) => _poidsNormes = value;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cellule_id': celluleId,
      'parcelle_id': parcelleId,
      'remorque': remorque,
      'date_chargement': dateChargement.toIso8601String(),
      'poids_plein': poidsPlein,
      'poids_vide': poidsVide,
      'poids_net': _poidsNet,
      'poids_normes': _poidsNormes,
      'humidite': humidite,
      'variete': variete,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cellule_id': celluleId,
      'parcelle_id': parcelleId,
      'remorque': remorque,
      'date_chargement': Timestamp.fromDate(dateChargement),
      'poids_plein': poidsPlein,
      'poids_vide': poidsVide,
      'poids_net': _poidsNet,
      'poids_normes': _poidsNormes,
      'humidite': humidite,
      'variete': variete,
    };
  }

  factory Chargement.fromMap(Map<String, dynamic> map) {
    return Chargement(
      id: map['id'],
      celluleId: map['cellule_id'],
      parcelleId: map['parcelle_id'],
      remorque: map['remorque'],
      dateChargement: DateTime.parse(map['date_chargement']),
      poidsPlein: map['poids_plein'] is int ? (map['poids_plein'] as int).toDouble() : map['poids_plein'],
      poidsVide: map['poids_vide'] is int ? (map['poids_vide'] as int).toDouble() : map['poids_vide'],
      poidsNet: map['poids_net'] is int ? (map['poids_net'] as int).toDouble() : map['poids_net'],
      poidsNormes: map['poids_normes'] is int ? (map['poids_normes'] as int).toDouble() : map['poids_normes'],
      humidite: map['humidite'] is int ? (map['humidite'] as int).toDouble() : map['humidite'],
      variete: map['variete'] ?? '',
    );
  }

  factory Chargement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Chargement(
      documentId: doc.id,
      celluleId: data['cellule_id'] ?? 0,
      parcelleId: data['parcelle_id'] ?? 0,
      remorque: data['remorque'] ?? '',
      dateChargement: (data['date_chargement'] as Timestamp).toDate(),
      poidsPlein: (data['poids_plein'] ?? 0.0).toDouble(),
      poidsVide: (data['poids_vide'] ?? 0.0).toDouble(),
      poidsNet: (data['poids_net'] ?? 0.0).toDouble(),
      poidsNormes: (data['poids_normes'] ?? 0.0).toDouble(),
      humidite: (data['humidite'] ?? 0.0).toDouble(),
      variete: data['variete'] ?? '',
    );
  }

  Chargement copyWith({
    int? id,
    int? celluleId,
    int? parcelleId,
    String? remorque,
    DateTime? dateChargement,
    double? poidsPlein,
    double? poidsVide,
    double? poidsNet,
    double? poidsNormes,
    double? humidite,
    String? variete,
    String? documentId,
  }) {
    return Chargement(
      id: id ?? this.id,
      celluleId: celluleId ?? this.celluleId,
      parcelleId: parcelleId ?? this.parcelleId,
      remorque: remorque ?? this.remorque,
      dateChargement: dateChargement ?? this.dateChargement,
      poidsPlein: poidsPlein ?? this.poidsPlein,
      poidsVide: poidsVide ?? this.poidsVide,
      poidsNet: poidsNet ?? this.poidsNet,
      poidsNormes: poidsNormes ?? this.poidsNormes,
      humidite: humidite ?? this.humidite,
      variete: variete ?? this.variete,
      documentId: documentId ?? this.documentId,
    );
  }

  @override
  String toString() => 'Chargement(id: $id, celluleId: $celluleId, parcelleId: $parcelleId, poidsNet: $_poidsNet, poidsNormes: $_poidsNormes, variete: $variete)';
} 