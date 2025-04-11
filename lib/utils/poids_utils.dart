class PoidsUtils {
  // Table de conversion des poids selon l'humidité
  static const Map<Range, double> _coefficientsHumidite = {
    Range(0, 15.01): 1.0,      // 0-15% : pas de correction
    Range(15.01, 15.51): 1.0,  // 15.01-15.50 : 1000
    Range(15.51, 16.01): 0.994,  // 15.51-16.00 : 994
    Range(16.01, 16.51): 0.988,  // 16.01-16.50 : 988
    Range(16.51, 17.01): 0.976,  // 16.51-17.00 : 976
    Range(17.01, 17.51): 0.970,  // 17.01-17.50 : 970
    Range(17.51, 18.01): 0.964,  // 17.51-18.00 : 964
    Range(18.01, 18.51): 0.958,  // 18.01-18.50 : 958
    Range(18.51, 19.01): 0.952,  // 18.51-19.00 : 952
    Range(19.01, 19.51): 0.946,  // 19.01-19.50 : 946
    Range(19.51, 20.01): 0.940,  // 19.51-20.00 : 940
    Range(20.01, 20.51): 0.934,  // 20.01-20.50 : 934
    Range(20.51, 21.01): 0.928,  // 20.51-21.00 : 928
    Range(21.01, 21.51): 0.922,  // 21.01-21.50 : 922
    Range(21.51, 22.01): 0.916,  // 21.51-22.00 : 916
    Range(22.01, 22.51): 0.910,  // 22.01-22.50 : 910
    Range(22.51, 23.01): 0.904,  // 22.51-23.00 : 904
    Range(23.01, 23.51): 0.898,  // 23.01-23.50 : 898
    Range(23.51, 24.01): 0.892,  // 23.51-24.00 : 892
    Range(24.01, 24.51): 0.886,  // 24.01-24.50 : 886
    Range(24.51, 25.01): 0.880,  // 24.51-25.00 : 880
    Range(25.01, 25.51): 0.87385,  // 25.01-25.50 : 873.85
    Range(25.51, 26.01): 0.86770,  // 25.51-26.00 : 867.70
    Range(26.01, 26.51): 0.86155,  // 26.01-26.50 : 861.55
    Range(26.51, 27.01): 0.85540,  // 26.51-27.00 : 855.40
    Range(27.01, 27.51): 0.84925,  // 27.01-27.50 : 849.25
    Range(27.51, 28.01): 0.84310,  // 27.51-28.00 : 843.10
    Range(28.01, 28.51): 0.83695,  // 28.01-28.50 : 836.95
    Range(28.51, 29.01): 0.83080,  // 28.51-29.00 : 830.80
    Range(29.01, 29.51): 0.82465,  // 29.01-29.50 : 824.65
    Range(29.51, 30.01): 0.81850,  // 29.51-30.00 : 818.50
    Range(30.01, 30.51): 0.81205,  // 30.01-30.50 : 812.05
    Range(30.51, 31.01): 0.80560,  // 30.51-31.00 : 805.60
    Range(31.01, 31.51): 0.79915,  // 31.01-31.50 : 799.15
    Range(31.51, 32.01): 0.79270,  // 31.51-32.00 : 792.70
    Range(32.01, 32.51): 0.78625,  // 32.01-32.50 : 786.25
    Range(32.51, 33.01): 0.77980,  // 32.51-33.00 : 779.80
    Range(33.01, 33.51): 0.77335,  // 33.01-33.50 : 773.35
    Range(33.51, 34.01): 0.76690,  // 33.51-34.00 : 766.90
    Range(34.01, 34.51): 0.76045,  // 34.01-34.50 : 760.45
    Range(34.51, 35.01): 0.75400,  // 34.51-35.00 : 754.00
    Range(35.01, 35.51): 0.74725,  // 35.01-35.50 : 747.25
    Range(35.51, 36.01): 0.74050,  // 35.51-36.00 : 740.50
    Range(36.01, 36.51): 0.73375,  // 36.01-36.50 : 733.75
    Range(36.51, 37.01): 0.72700,  // 36.51-37.00 : 727.00
    Range(37.01, 37.51): 0.72025,  // 37.01-37.50 : 720.25
    Range(37.51, 38.01): 0.71350,  // 37.51-38.00 : 713.50
    Range(38.01, 38.51): 0.70675,  // 38.01-38.50 : 706.75
    Range(38.51, 39.01): 0.70000,  // 38.51-39.00 : 700.00
    Range(39.01, 39.51): 0.69325,  // 39.01-39.50 : 693.25
    Range(39.51, 40.01): 0.68650,  // 39.51-40.00 : 686.50
  };

  /// Calcule le poids aux normes (15% d'humidité) à partir du poids net et de l'humidité
  static double calculPoidsNormes(double poidsNet, double humidite) {
    // Limiter l'humidité entre 0 et 100%
    humidite = humidite.clamp(0.0, 100.0);

    // Trouver le coefficient correspondant à l'humidité
    final coefficient = _coefficientsHumidite.entries
        .firstWhere(
          (entry) => entry.key.contains(humidite),
          orElse: () => const MapEntry(Range(0, 15.01), 1.0),
        )
        .value;

    // Calculer le poids aux normes
    return poidsNet * coefficient;
  }

  /// Calcule le poids net à partir du poids plein et du poids vide
  static double calculPoidsNet(double poidsPlein, double poidsVide) {
    if (poidsPlein < poidsVide) {
      throw ArgumentError('Le poids plein ne peut pas être inférieur au poids vide');
    }
    return poidsPlein - poidsVide;
  }

  /// Vérifie si un poids est valide (positif)
  static bool estPoidsValide(double poids) {
    return poids > 0;
  }

  /// Vérifie si une humidité est valide (entre 0 et 100)
  static bool estHumiditeValide(double humidite) {
    return humidite >= 0 && humidite <= 100;
  }
}

/// Classe utilitaire pour représenter une plage de valeurs
class Range {
  final double start;
  final double end;

  const Range(this.start, this.end);

  bool contains(double value) {
    return value >= start && value < end;
  }
} 