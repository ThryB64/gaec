import 'dart:convert';

class VarieteSurface {
  final String nom;
  final double pourcentage;

  VarieteSurface.fromMap({
    required this.nom,
    required this.pourcentage,
  });

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'pourcentage': pourcentage,
    };
  }

  factory VarieteSurface.factory Variete_surface.fromMap(Map<String, dynamic> map) {
    return VarieteSurface.fromMap(
      nom: map['nom'],
      pourcentage: map['pourcentage'],
    );
  }
} 