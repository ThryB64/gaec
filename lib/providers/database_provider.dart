import 'package:flutter/foundation.dart';
import '../models/parcelle.dart';
import '../models/cellule.dart';
import '../models/chargement.dart';
import '../models/semis.dart';
import '../models/variete.dart';
import '../services/firebase_service.dart';
import '../utils/poids_utils.dart';

class DatabaseProvider with ChangeNotifier {
  final FirebaseService _db;
  List<Parcelle> _parcelles = [];
  List<Cellule> _cellules = [];
  List<Chargement> _chargements = [];
  List<Semis> _semis = [];
  List<Variete> _varietes = [];

  DatabaseProvider() : _db = FirebaseService() {
    _loadData();
  }

  List<Parcelle> get parcelles => _parcelles;
  List<Cellule> get cellules => _cellules;
  List<Chargement> get chargements => _chargements;
  List<Semis> get semis => _semis;
  List<Variete> get varietes => _varietes;

  Future<void> initialize() async {
    try {
      await _loadData();
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    try {
      // Calculer la surface totale
      final surfaceTotale = _parcelles.fold<double>(
        0,
        (sum, p) => sum + p.surface,
      );

      // Obtenir l'année la plus récente avec des chargements
      final derniereAnnee = _chargements.isEmpty 
          ? DateTime.now().year 
          : _chargements
              .map((c) => c.dateChargement.year)
              .reduce((a, b) => a > b ? a : b);

      final chargementsDerniereAnnee = _chargements.where(
        (c) => c.dateChargement.year == derniereAnnee
      );

      // Calculer le poids total normé de l'année
      final poidsTotalNormeAnnee = chargementsDerniereAnnee.fold<double>(
        0,
        (sum, c) => sum + c.poidsNormes,
      );

      // Calculer le rendement moyen normé (en T/ha)
      final rendementMoyenNorme = surfaceTotale > 0
          ? (poidsTotalNormeAnnee / 1000) / surfaceTotale
          : 0.0;

      return {
        'surfaceTotale': surfaceTotale,
        'derniereAnnee': derniereAnnee,
        'poidsTotalNormeAnnee': poidsTotalNormeAnnee,
        'rendementMoyenNorme': rendementMoyenNorme,
      };
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      rethrow;
    }
  }

  Future<void> _loadData() async {
    try {
      final parcelles = await _db.getParcelles();
      final cellules = await _db.getCellules();
      final chargements = await _db.getChargements();
      final semis = await _db.getSemis.fromMap();
      final varietes = await _db.getVarietes();

      _parcelles = parcelles;
      _cellules = cellules;
      _chargements = chargements;
      _semis = semis;
      _varietes = varietes;

      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      rethrow;
    }
  }

  Future<void> ajouterParcelle.fromMap(Parcelle parcelle) async {
    final id = await _db.insertParcelle.fromMap(parcelle);
    parcelle.id = id;
    _parcelles.add(parcelle);
    notifyListeners();
  }

  Future<void> modifierParcelle.fromMap(Parcelle parcelle) async {
    if (parcelle.id != null) {
      await _db.updateParcelle.fromMap(parcelle);
      final index = _parcelles.indexWhere((p) => p.id == parcelle.id);
      if (index != -1) {
        _parcelles[index] = parcelle;
      }
      notifyListeners();
    }
  }

  Future<void> supprimerParcelle.fromMap(int id) async {
    await _db.deleteParcelle.fromMap(id);
    _parcelles.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> ajouterCellule.fromMap(Cellule cellule) async {
    final id = await _db.insertCellule.fromMap(cellule);
    cellule.id = id;
    _cellules.add(cellule);
    notifyListeners();
  }

  Future<void> modifierCellule.fromMap(Cellule cellule) async {
    if (cellule.id != null) {
      await _db.updateCellule.fromMap(cellule);
      final index = _cellules.indexWhere((c) => c.id == cellule.id);
      if (index != -1) {
        _cellules[index] = cellule;
      }
      notifyListeners();
    }
  }

  Future<void> supprimerCellule.fromMap(int id) async {
    await _db.deleteCellule.fromMap(id);
    _cellules.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Future<void> ajouterChargement.fromMap(Chargement chargement) async {
    try {
      // Valider les données
      if (!PoidsUtils.estPoidsValide(chargement.poidsPlein)) {
        throw Exception('Le poids plein doit être positif');
      }
      if (!PoidsUtils.estPoidsValide(chargement.poidsVide)) {
        throw Exception('Le poids vide doit être positif');
      }
      if (!PoidsUtils.estHumiditeValide(chargement.humidite)) {
        throw Exception('L\'humidité doit être comprise entre 0 et 100%');
      }

      // Calculer le poids net
      chargement.poidsNet = PoidsUtils.calculPoidsNet(
        chargement.poidsPlein,
        chargement.poidsVide,
      );

      // Calculer le poids aux normes
      chargement.poidsNormes = PoidsUtils.calculPoidsNormes(
        chargement.poidsNet,
        chargement.humidite,
      );

      final id = await _db.insertChargement.fromMap(chargement);
      chargement.id = id;
      _chargements.add(chargement);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> modifierChargement.fromMap(Chargement chargement) async {
    try {
      if (chargement.id != null) {
        // Valider les données
        if (!PoidsUtils.estPoidsValide(chargement.poidsPlein)) {
          throw Exception('Le poids plein doit être positif');
        }
        if (!PoidsUtils.estPoidsValide(chargement.poidsVide)) {
          throw Exception('Le poids vide doit être positif');
        }
        if (!PoidsUtils.estHumiditeValide(chargement.humidite)) {
          throw Exception('L\'humidité doit être comprise entre 0 et 100%');
        }

        // Calculer le poids net
        chargement.poidsNet = PoidsUtils.calculPoidsNet(
          chargement.poidsPlein,
          chargement.poidsVide,
        );

        // Calculer le poids aux normes
        chargement.poidsNormes = PoidsUtils.calculPoidsNormes(
          chargement.poidsNet,
          chargement.humidite,
        );

        await _db.updateChargement.fromMap(chargement);
        final index = _chargements.indexWhere((c) => c.id == chargement.id);
        if (index != -1) {
          _chargements[index] = chargement;
        }
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> supprimerChargement.fromMap(int id) async {
    try {
      await _db.deleteChargement.fromMap(id);
      _chargements.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> ajouterSemis.fromMap(Semis semis) async {
    final id = await _db.insertSemis.fromMap(semis);
    semis.id = id;
    _semis.add(semis);
    notifyListeners();
  }

  Future<void> modifierSemis.fromMap(Semis semis) async {
    if (semis.id != null) {
      await _db.updateSemis.fromMap(semis);
      final index = _semis.indexWhere((s) => s.id == semis.id);
      if (index != -1) {
        _semis[index] = semis;
      }
      notifyListeners();
    }
  }

  Future<void> supprimerSemis.fromMap(int id) async {
    await _db.deleteSemis.fromMap(id);
    _semis.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Future<void> deleteAllData() async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.rawDelete('DELETE FROM chargements');
      await txn.rawDelete('DELETE FROM semis');
      await txn.rawDelete('DELETE FROM parcelles');
      await txn.rawDelete('DELETE FROM cellules');
      await txn.rawDelete('DELETE FROM varietes');
    });
    await _loadData();
  }

  Future<void> importData(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      // Supprimer les données existantes
      await txn.rawDelete('DELETE FROM chargements');
      await txn.rawDelete('DELETE FROM semis');
      await txn.rawDelete('DELETE FROM parcelles');
      await txn.rawDelete('DELETE FROM cellules');
      await txn.rawDelete('DELETE FROM varietes');

      // Importer les variétés
      if (data['varietes'] != null) {
        for (var varieteData in data['varietes']) {
          await txn.insert('varietes', {
            'nom': varieteData['nom'],
            'description': varieteData['description'],
            'date_creation': varieteData['date_creation'],
          });
        }
      }

      // Importer les parcelles
      if (data['parcelles'] != null) {
        for (var parcelleData in data['parcelles']) {
          await txn.insert('parcelles', {
            'nom': parcelleData['nom'],
            'surface': parcelleData['surface'],
            'date_creation': parcelleData['date_creation'],
            'notes': parcelleData['notes'],
          });
        }
      }

      // Importer les cellules
      if (data['cellules'] != null) {
        for (var celluleData in data['cellules']) {
          await txn.insert('cellules', {
            'reference': celluleData['reference'] ?? celluleData['nom'],
            'capacite': celluleData['capacite'],
            'date_creation': celluleData['date_creation'],
            'notes': celluleData['notes'],
          });
        }
      }

      // Importer les semis
      if (data['semis'] != null) {
        for (var semisData in data['semis']) {
          await txn.insert('semis', {
            'parcelle_id': semisData['parcelle_id'],
            'date': semisData['date'],
            'varietes_surfaces': semisData['varietes_surfaces'],
            'notes': semisData['notes'],
          });
        }
      }

      // Importer les chargements
      if (data['chargements'] != null) {
        for (var chargementData in data['chargements']) {
          // Convertir explicitement en double pour éviter les problèmes de type
          final double poidsPlein = double.tryParse(chargementData['poids_plein'].toString()) ?? 0.0;
          final double poidsVide = double.tryParse(chargementData['poids_vide'].toString()) ?? 0.0;
          final double humidite = double.tryParse(chargementData['humidite'].toString()) ?? 0.0;
          
          // Calculer le poids net et le poids aux normes
          final double poidsNet = PoidsUtils.calculPoidsNet(poidsPlein, poidsVide);
          final double poidsNormes = PoidsUtils.calculPoidsNormes(poidsNet, humidite);
          
          // Convertir la date de chargement
          final DateTime dateChargement = DateTime.parse(chargementData['date_chargement']);
          
          await txn.insert('chargements', {
            'cellule_id': chargementData['cellule_id'],
            'parcelle_id': chargementData['parcelle_id'],
            'remorque': chargementData['remorque'] ?? 'Remorque 1',
            'date_chargement': dateChargement.toIso8601String(),
            'poids_plein': poidsPlein,
            'poids_vide': poidsVide,
            'poids_net': poidsNet,
            'poids_normes': poidsNormes,
            'humidite': humidite,
            'variete': chargementData['variete'] ?? '',
          });
        }
      }
    });
    
    await _loadData();
  }

  Future<void> ajouterVariete.fromMap(Variete variete) async {
    final id = await _db.insertVariete.fromMap(variete);
    variete.id = id;
    _varietes.add(variete);
    notifyListeners();
  }

  Future<void> modifierVariete.fromMap(Variete variete) async {
    if (variete.id != null) {
      await _db.updateVariete.fromMap(variete);
      final index = _varietes.indexWhere((v) => v.id == variete.id);
      if (index != -1) {
        _varietes[index] = variete;
      }
      notifyListeners();
    }
  }

  Future<void> supprimerVariete.fromMap(int id) async {
    await _db.deleteVariete.fromMap(id);
    _varietes.removeWhere((v) => v.id == id);
    notifyListeners();
  }

  Future<void> updateAllChargementsPoidsNormes() async {
    try {
      print('Début de la mise à jour des poids aux normes');
      await _db.updateAllChargementsPoidsNormes();
      print('Mise à jour des poids aux normes terminée');
      // Recharger les données après la mise à jour
      await _loadData();
      print('Données rechargées après la mise à jour');
      notifyListeners();
      print('Listeners notifiés');
    } catch (e) {
      print('Erreur lors de la mise à jour des poids aux normes: $e');
      rethrow;
    }
  }

  Variete? getVarieteForParcelle.fromMap(int? parcelleId) {
    if (parcelleId == null) return null;
    
    final semis = _semis.where((s) => s.parcelleId == parcelleId)
        
        ..sort((a, b) => b.date.compareTo(a.date));
    
    if (semis.isEmpty) return null;
    
    final dernierSemis = semis.first;
    return _varietes.firstWhere(
      (v) => v.nom == dernierSemis.varietes.first,
      orElse: () => Variete.fromMap(
        nom: 'Inconnue',
        dateCreation: DateTime.now(),
      ),
    );
  }
} 

  Future<void> loadParcelles() async {
    _parcelles = await _db.getParcelles();
    notifyListeners();
  }

  Future<void> addParcelle.fromMap(Parcelle p) async {
    await _db.addParcelle.fromMap(p);
    await loadParcelles();
  }

  Future<void> deleteParcelle.fromMap(String id) async {
    await _db.deleteParcelle.fromMap(id);
    await loadParcelles();
  }

  Future<void> loadCellules() async {
    _cellules = await _db.getCellules();
    notifyListeners();
  }

  Future<void> addCellule.fromMap(Cellule c) async {
    await _db.addCellule.fromMap(c);
    await loadCellules();
  }

  Future<void> deleteCellule.fromMap(String id) async {
    await _db.deleteCellule.fromMap(id);
    await loadCellules();
  }

  Future<void> loadChargements() async {
    _chargements = await _db.getChargements();
    notifyListeners();
  }

  Future<void> addChargement.fromMap(Chargement c) async {
    await _db.addChargement.fromMap(c);
    await loadChargements();
  }

  Future<void> deleteChargement.fromMap(String id) async {
    await _db.deleteChargement.fromMap(id);
    await loadChargements();
  }

  Future<void> loadSemis.fromMap() async {
    _semis = await _db.getSemis.fromMap();
    notifyListeners();
  }

  Future<void> addSemis.fromMap(Semis s) async {
    await _db.addSemis.fromMap(s);
    await loadSemis.fromMap();
  }

  Future<void> deleteSemis.fromMap(String id) async {
    await _db.deleteSemis.fromMap(id);
    await loadSemis.fromMap();
  }

  Future<void> loadVarietes() async {
    _varietes = await _db.getVarietes();
    notifyListeners();
  }

  Future<void> addVariete.fromMap(Variete v) async {
    await _db.addVariete.fromMap(v);
    await loadVarietes();
  }

  Future<void> deleteVariete.fromMap(String id) async {
    await _db.deleteVariete.fromMap(id);
    await loadVarietes();
  }
