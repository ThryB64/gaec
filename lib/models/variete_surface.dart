import 'dart:convert';

class VarieteSurface {
  final String nom;
  final double pourcentage;

  VarieteSurface({
    required this.nom,
    required this.pourcentage,
  });

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'pourcentage': pourcentage,
    };
  }

  factory VarieteSurface.fromMap(Map<String, dynamic> map) {
    return VarieteSurface(
      nom: map['nom'],
      pourcentage: map['pourcentage'],
    );
  }
} 