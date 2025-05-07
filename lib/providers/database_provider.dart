import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/parcelle.dart';
import '../models/cellule.dart';
import '../models/chargement.dart';
import '../models/semis.dart';
import '../models/variete.dart';
import '../services/sync_service.dart';
import '../services/firestore_service.dart';
import '../utils/poids_utils.dart';

class DatabaseProvider with ChangeNotifier {
  Database? _database;
  final SyncService _syncService;
  final FirestoreServiceParcelle _parcelleService = FirestoreServiceParcelle();
  final FirestoreServiceCellule _celluleService = FirestoreServiceCellule();
  final FirestoreServiceChargement _chargementService = FirestoreServiceChargement();
  final FirestoreServiceSemis _semisService = FirestoreServiceSemis();
  final FirestoreServiceVariete _varieteService = FirestoreServiceVariete();
  List<Parcelle> _parcelles = [];
  List<Cellule> _cellules = [];
  List<Chargement> _chargements = [];
  List<Semis> _semis = [];
  List<Variete> _varietes = [];
  bool _isInitialized = false;

  DatabaseProvider()
      : _syncService = SyncService(_database!),
        _initialize() {
  }

  List<Parcelle> get parcelles => _parcelles;
  List<Cellule> get cellules => _cellules;
  List<Chargement> get chargements => _chargements;
  List<Semis> get semis => _semis;
  List<Variete> get varietes => _varietes;

  Future<void> _initialize() async {
    try {
      await _loadData();
      _setupFirestoreListeners();
      _isInitialized = true;
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
      rethrow;
    }
  }

  void _setupFirestoreListeners() {
    // Écouter les changements des parcelles
    _parcelleService.getParcellesStream().listen((parcelles) {
      _parcelles = parcelles;
      notifyListeners();
    });

    // Écouter les changements des cellules
    _celluleService.getCellulesStream().listen((cellules) {
      _cellules = cellules;
      notifyListeners();
    });

    // Écouter les changements des chargements
    _chargementService.getChargementsStream().listen((chargements) {
      _chargements = chargements;
      notifyListeners();
    });

    // Écouter les changements des semis
    _semisService.getSemisStream().listen((semis) {
      _semis = semis;
      notifyListeners();
    });

    // Écouter les changements des variétés
    _varieteService.getVarietesStream().listen((varietes) {
      _varietes = varietes;
      notifyListeners();
    });
  }

  Future<void> initialize() async {
    if (!_isInitialized) {
      await _initialize();
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
      ).toList();

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
      final parcelles = await getParcelles();
      final cellules = await getCellules();
      final chargements = await getChargements();
      final semis = await getSemis();
      final varietes = await getVarietes();

      _parcelles = parcelles;
      _cellules = cellules;
      _chargements = chargements;
      _semis = semis;
      _varietes = varietes;

      // Synchroniser les données avec Firestore
      await syncAll();

      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      rethrow;
    }
  }

  Future<void> ajouterParcelle(Parcelle parcelle) async {
    final id = await _database!.insert('parcelles', parcelle.toMap());
    final newParcelle = parcelle.copyWith(id: id);
    if (parcelle.documentId == null) {
      final docId = await _parcelleService.create(newParcelle);
      await _database!.update(
        'parcelles',
        {'document_id': docId},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    _parcelles.add(newParcelle);
    notifyListeners();
  }

  Future<void> modifierParcelle(Parcelle parcelle) async {
    if (parcelle.id != null) {
      await updateParcelle(parcelle);
      final index = _parcelles.indexWhere((p) => p.id == parcelle.id);
      if (index != -1) {
        _parcelles[index] = parcelle;
      }
      notifyListeners();
    }
  }

  Future<void> supprimerParcelle(int id) async {
    final parcelle = (await _database!.query(
      'parcelles',
      where: 'id = ?',
      whereArgs: [id],
    )).first;
    
    if (parcelle['document_id'] != null) {
      await _parcelleService.delete(parcelle['document_id']);
    }
    
    await _database!.delete(
      'parcelles',
      where: 'id = ?',
      whereArgs: [id],
    );
    _parcelles.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> ajouterCellule(Cellule cellule) async {
    final id = await _database!.insert('cellules', cellule.toMap());
    final newCellule = cellule.copyWith(id: id);
    if (cellule.documentId == null) {
      final docId = await _celluleService.create(newCellule);
      await _database!.update(
        'cellules',
        {'document_id': docId},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    _cellules.add(newCellule);
    notifyListeners();
  }

  Future<void> modifierCellule(Cellule cellule) async {
    if (cellule.id != null) {
      await updateCellule(cellule);
      final index = _cellules.indexWhere((c) => c.id == cellule.id);
      if (index != -1) {
        _cellules[index] = cellule;
      }
      notifyListeners();
    }
  }

  Future<void> supprimerCellule(int id) async {
    final cellule = (await _database!.query(
      'cellules',
      where: 'id = ?',
      whereArgs: [id],
    )).first;
    
    if (cellule['document_id'] != null) {
      await _celluleService.delete(cellule['document_id']);
    }
    
    await _database!.delete(
      'cellules',
      where: 'id = ?',
      whereArgs: [id],
    );
    _cellules.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Future<void> ajouterChargement(Chargement chargement) async {
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

      final id = await _database!.insert('chargements', chargement.toMap());
      final newChargement = chargement.copyWith(id: id);
      if (chargement.documentId == null) {
        final docId = await _chargementService.create(newChargement);
        await _database!.update(
          'chargements',
          {'document_id': docId},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      _chargements.add(newChargement);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> modifierChargement(Chargement chargement) async {
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

        await updateChargement(chargement);
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

  Future<void> supprimerChargement(int id) async {
    final chargement = (await _database!.query(
      'chargements',
      where: 'id = ?',
      whereArgs: [id],
    )).first;
    
    if (chargement['document_id'] != null) {
      await _chargementService.delete(chargement['document_id']);
    }
    
    await _database!.delete(
      'chargements',
      where: 'id = ?',
      whereArgs: [id],
    );
    _chargements.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Future<void> ajouterSemis(Semis semis) async {
    final id = await _database!.insert('semis', semis.toMap());
    final newSemis = semis.copyWith(id: id);
    if (semis.documentId == null) {
      final docId = await _semisService.create(newSemis);
      await _database!.update(
        'semis',
        {'document_id': docId},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    _semis.add(newSemis);
    notifyListeners();
  }

  Future<void> modifierSemis(Semis semis) async {
    if (semis.id != null) {
      await updateSemis(semis);
      final index = _semis.indexWhere((s) => s.id == semis.id);
      if (index != -1) {
        _semis[index] = semis;
      }
      notifyListeners();
    }
  }

  Future<void> supprimerSemis(int id) async {
    final semis = (await _database!.query(
      'semis',
      where: 'id = ?',
      whereArgs: [id],
    )).first;
    
    if (semis['document_id'] != null) {
      await _semisService.delete(semis['document_id']);
    }
    
    await _database!.delete(
      'semis',
      where: 'id = ?',
      whereArgs: [id],
    );
    _semis.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Future<void> ajouterVariete(Variete variete) async {
    final id = await _database!.insert('varietes', variete.toMap());
    final newVariete = variete.copyWith(id: id);
    if (variete.documentId == null) {
      final docId = await _varieteService.create(newVariete);
      await _database!.update(
        'varietes',
        {'document_id': docId},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    _varietes.add(newVariete);
    notifyListeners();
  }

  Future<void> modifierVariete(Variete variete) async {
    if (variete.id != null) {
      await updateVariete(variete);
      final index = _varietes.indexWhere((v) => v.id == variete.id);
      if (index != -1) {
        _varietes[index] = variete;
      }
      notifyListeners();
    }
  }

  Future<void> supprimerVariete(int id) async {
    final variete = (await _database!.query(
      'varietes',
      where: 'id = ?',
      whereArgs: [id],
    )).first;
    
    if (variete['document_id'] != null) {
      await _varieteService.delete(variete['document_id']);
    }
    
    await _database!.delete(
      'varietes',
      where: 'id = ?',
      whereArgs: [id],
    );
    _varietes.removeWhere((v) => v.id == id);
    notifyListeners();
  }

  Future<void> deleteAllData() async {
    final db = await _database;
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
    final db = await _database;
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

  Future<void> updateAllChargementsPoidsNormes() async {
    try {
      print('Début de la mise à jour des poids aux normes');
      await _database!.update('chargements', {'poids_normes': 0}, where: 'poids_normes != 0');
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

  Variete? getVarieteForParcelle(int? parcelleId) {
    if (parcelleId == null) return null;
    
    final semis = _semis.where((s) => s.parcelleId == parcelleId)
        .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    
    if (semis.isEmpty) return null;
    
    final dernierSemis = semis.first;
    return _varietes.firstWhere(
      (v) => v.nom == dernierSemis.varietes.first,
      orElse: () => Variete(
        nom: 'Inconnue',
        dateCreation: DateTime.now(),
      ),
    );
  }

  Future<void> syncAll() async {
    await _syncService.syncAll();
    notifyListeners();
  }

  Future<List<Parcelle>> getParcelles() async {
    final List<Map<String, dynamic>> maps = await _database!.query('parcelles');
    return List.generate(maps.length, (i) => Parcelle.fromMap(maps[i]));
  }

  Future<List<Cellule>> getCellules() async {
    final List<Map<String, dynamic>> maps = await _database!.query('cellules');
    return List.generate(maps.length, (i) => Cellule.fromMap(maps[i]));
  }

  Future<List<Chargement>> getChargements() async {
    final List<Map<String, dynamic>> maps = await _database!.query('chargements');
    return List.generate(maps.length, (i) => Chargement.fromMap(maps[i]));
  }

  Future<List<Semis>> getSemis() async {
    final List<Map<String, dynamic>> maps = await _database!.query('semis');
    return List.generate(maps.length, (i) => Semis.fromMap(maps[i]));
  }

  Future<List<Variete>> getVarietes() async {
    final List<Map<String, dynamic>> maps = await _database!.query('varietes');
    return List.generate(maps.length, (i) => Variete.fromMap(maps[i]));
  }

  Future<void> updateParcelle(Parcelle parcelle) async {
    await _database!.update(
      'parcelles',
      parcelle.toMap(),
      where: 'id = ?',
      whereArgs: [parcelle.id],
    );
    if (parcelle.documentId != null) {
      await _parcelleService.update(parcelle.documentId!, parcelle);
    }
    notifyListeners();
  }

  Future<void> updateCellule(Cellule cellule) async {
    await _database!.update(
      'cellules',
      cellule.toMap(),
      where: 'id = ?',
      whereArgs: [cellule.id],
    );
    if (cellule.documentId != null) {
      await _celluleService.update(cellule.documentId!, cellule);
    }
    notifyListeners();
  }

  Future<void> updateChargement(Chargement chargement) async {
    await _database!.update(
      'chargements',
      chargement.toMap(),
      where: 'id = ?',
      whereArgs: [chargement.id],
    );
    if (chargement.documentId != null) {
      await _chargementService.update(chargement.documentId!, chargement);
    }
    notifyListeners();
  }

  Future<void> updateSemis(Semis semis) async {
    await _database!.update(
      'semis',
      semis.toMap(),
      where: 'id = ?',
      whereArgs: [semis.id],
    );
    if (semis.documentId != null) {
      await _semisService.update(semis.documentId!, semis);
    }
    notifyListeners();
  }

  Future<void> updateVariete(Variete variete) async {
    await _database!.update(
      'varietes',
      variete.toMap(),
      where: 'id = ?',
      whereArgs: [variete.id],
    );
    if (variete.documentId != null) {
      await _varieteService.update(variete.documentId!, variete);
    }
    notifyListeners();
  }
} 