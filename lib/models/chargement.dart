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

  factory Chargement.fromMap(Map<String, dynamic> map) {
    return Chargement(
      id: map['id'],
      celluleId: map['cellule_id'],
      parcelleId: map['parcelle_id'],
      remorque: map['remorque'],
      dateChargement: DateTime.parse(map['date_chargement']),
      poidsPlein: map['poids_plein'],
      poidsVide: map['poids_vide'],
      poidsNet: map['poids_net'],
      poidsNormes: map['poids_normes'],
      humidite: map['humidite'],
      variete: map['variete'],
    );
  }

  @override
  String toString() => 'Chargement(id: $id, celluleId: $celluleId, parcelleId: $parcelleId, poidsNet: $_poidsNet, poidsNormes: $_poidsNormes, variete: $variete)';
} 