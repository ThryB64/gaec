import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import '../models/parcelle.dart';
import '../models/cellule.dart';
import '../models/chargement.dart';
import '../models/semis.dart';
import '../models/variete.dart';
import 'firestore_service.dart';

class SyncService {
  final Database _db;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreServiceParcelle _parcelleService = FirestoreServiceParcelle();
  final FirestoreServiceCellule _celluleService = FirestoreServiceCellule();
  final FirestoreServiceChargement _chargementService = FirestoreServiceChargement();
  final FirestoreServiceSemis _semisService = FirestoreServiceSemis();
  final FirestoreServiceVariete _varieteService = FirestoreServiceVariete();
  
  // Streams pour les changements Firestore
  late StreamSubscription<QuerySnapshot> _parcellesSubscription;
  late StreamSubscription<QuerySnapshot> _cellulesSubscription;
  late StreamSubscription<QuerySnapshot> _chargementsSubscription;
  late StreamSubscription<QuerySnapshot> _semisSubscription;
  late StreamSubscription<QuerySnapshot> _varietesSubscription;

  SyncService(this._db) {
    _initializeFirestoreListeners();
  }

  void _initializeFirestoreListeners() {
    _parcellesSubscription = _firestore.collection('parcelles')
        .snapshots()
        .listen(_handleParcellesChanges);
    
    _cellulesSubscription = _firestore.collection('cellules')
        .snapshots()
        .listen(_handleCellulesChanges);
    
    _chargementsSubscription = _firestore.collection('chargements')
        .snapshots()
        .listen(_handleChargementsChanges);
    
    _semisSubscription = _firestore.collection('semis')
        .snapshots()
        .listen(_handleSemisChanges);
    
    _varietesSubscription = _firestore.collection('varietes')
        .snapshots()
        .listen(_handleVarietesChanges);
  }

  void dispose() {
    _parcellesSubscription.cancel();
    _cellulesSubscription.cancel();
    _chargementsSubscription.cancel();
    _semisSubscription.cancel();
    _varietesSubscription.cancel();
  }

  // Gestionnaires de changements Firestore
  Future<void> _handleParcellesChanges(QuerySnapshot snapshot) async {
    for (var change in snapshot.docChanges) {
      try {
        final data = change.doc.data() as Map<String, dynamic>;
        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            final parcelle = Parcelle.fromFirestore(change.doc);
            await _updateLocalParcelle(parcelle);
            break;
          case DocumentChangeType.removed:
            await _deleteLocalParcelle(change.doc.id);
            break;
        }
      } catch (e) {
        print('Erreur lors de la synchronisation de la parcelle: $e');
      }
    }
  }

  Future<void> _handleCellulesChanges(QuerySnapshot snapshot) async {
    for (var change in snapshot.docChanges) {
      try {
        final data = change.doc.data() as Map<String, dynamic>;
        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            final cellule = Cellule.fromFirestore(change.doc);
            await _updateLocalCellule(cellule);
            break;
          case DocumentChangeType.removed:
            await _deleteLocalCellule(change.doc.id);
            break;
        }
      } catch (e) {
        print('Erreur lors de la synchronisation de la cellule: $e');
      }
    }
  }

  Future<void> _handleChargementsChanges(QuerySnapshot snapshot) async {
    for (var change in snapshot.docChanges) {
      try {
        final data = change.doc.data() as Map<String, dynamic>;
        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            final chargement = Chargement.fromFirestore(change.doc);
            await _updateLocalChargement(chargement);
            break;
          case DocumentChangeType.removed:
            await _deleteLocalChargement(change.doc.id);
            break;
        }
      } catch (e) {
        print('Erreur lors de la synchronisation du chargement: $e');
      }
    }
  }

  Future<void> _handleSemisChanges(QuerySnapshot snapshot) async {
    for (var change in snapshot.docChanges) {
      try {
        final data = change.doc.data() as Map<String, dynamic>;
        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            final semis = Semis.fromFirestore(change.doc);
            await _updateLocalSemis(semis);
            break;
          case DocumentChangeType.removed:
            await _deleteLocalSemis(change.doc.id);
            break;
        }
      } catch (e) {
        print('Erreur lors de la synchronisation du semis: $e');
      }
    }
  }

  Future<void> _handleVarietesChanges(QuerySnapshot snapshot) async {
    for (var change in snapshot.docChanges) {
      try {
        final data = change.doc.data() as Map<String, dynamic>;
        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            final variete = Variete.fromFirestore(change.doc);
            await _updateLocalVariete(variete);
            break;
          case DocumentChangeType.removed:
            await _deleteLocalVariete(change.doc.id);
            break;
        }
      } catch (e) {
        print('Erreur lors de la synchronisation de la variété: $e');
      }
    }
  }

  // Méthodes de mise à jour locale
  Future<void> _updateLocalParcelle(Parcelle parcelle) async {
    try {
      final existingParcelle = await _db.query(
        'parcelles',
        where: 'document_id = ?',
        whereArgs: [parcelle.documentId],
      );

      if (existingParcelle.isEmpty) {
        await _db.insert('parcelles', parcelle.toMap());
      } else {
        await _db.update(
          'parcelles',
          parcelle.toMap(),
          where: 'document_id = ?',
          whereArgs: [parcelle.documentId],
        );
      }
    } catch (e) {
      print('Erreur lors de la mise à jour locale de la parcelle: $e');
      rethrow;
    }
  }

  Future<void> _updateLocalCellule(Cellule cellule) async {
    try {
      final existingCellule = await _db.query(
        'cellules',
        where: 'document_id = ?',
        whereArgs: [cellule.documentId],
      );

      if (existingCellule.isEmpty) {
        await _db.insert('cellules', cellule.toMap());
      } else {
        await _db.update(
          'cellules',
          cellule.toMap(),
          where: 'document_id = ?',
          whereArgs: [cellule.documentId],
        );
      }
    } catch (e) {
      print('Erreur lors de la mise à jour locale de la cellule: $e');
      rethrow;
    }
  }

  Future<void> _updateLocalChargement(Chargement chargement) async {
    try {
      final existingChargement = await _db.query(
        'chargements',
        where: 'document_id = ?',
        whereArgs: [chargement.documentId],
      );

      if (existingChargement.isEmpty) {
        await _db.insert('chargements', chargement.toMap());
      } else {
        await _db.update(
          'chargements',
          chargement.toMap(),
          where: 'document_id = ?',
          whereArgs: [chargement.documentId],
        );
      }
    } catch (e) {
      print('Erreur lors de la mise à jour locale du chargement: $e');
      rethrow;
    }
  }

  Future<void> _updateLocalSemis(Semis semis) async {
    try {
      final existingSemis = await _db.query(
        'semis',
        where: 'document_id = ?',
        whereArgs: [semis.documentId],
      );

      if (existingSemis.isEmpty) {
        await _db.insert('semis', semis.toMap());
      } else {
        await _db.update(
          'semis',
          semis.toMap(),
          where: 'document_id = ?',
          whereArgs: [semis.documentId],
        );
      }
    } catch (e) {
      print('Erreur lors de la mise à jour locale du semis: $e');
      rethrow;
    }
  }

  Future<void> _updateLocalVariete(Variete variete) async {
    try {
      final existingVariete = await _db.query(
        'varietes',
        where: 'document_id = ?',
        whereArgs: [variete.documentId],
      );

      if (existingVariete.isEmpty) {
        await _db.insert('varietes', variete.toMap());
      } else {
        await _db.update(
          'varietes',
          variete.toMap(),
          where: 'document_id = ?',
          whereArgs: [variete.documentId],
        );
      }
    } catch (e) {
      print('Erreur lors de la mise à jour locale de la variété: $e');
      rethrow;
    }
  }

  // Méthodes de suppression locale
  Future<void> _deleteLocalParcelle(String documentId) async {
    try {
      await _db.delete(
        'parcelles',
        where: 'document_id = ?',
        whereArgs: [documentId],
      );
    } catch (e) {
      print('Erreur lors de la suppression locale de la parcelle: $e');
      rethrow;
    }
  }

  Future<void> _deleteLocalCellule(String documentId) async {
    try {
      await _db.delete(
        'cellules',
        where: 'document_id = ?',
        whereArgs: [documentId],
      );
    } catch (e) {
      print('Erreur lors de la suppression locale de la cellule: $e');
      rethrow;
    }
  }

  Future<void> _deleteLocalChargement(String documentId) async {
    try {
      await _db.delete(
        'chargements',
        where: 'document_id = ?',
        whereArgs: [documentId],
      );
    } catch (e) {
      print('Erreur lors de la suppression locale du chargement: $e');
      rethrow;
    }
  }

  Future<void> _deleteLocalSemis(String documentId) async {
    try {
      await _db.delete(
        'semis',
        where: 'document_id = ?',
        whereArgs: [documentId],
      );
    } catch (e) {
      print('Erreur lors de la suppression locale du semis: $e');
      rethrow;
    }
  }

  Future<void> _deleteLocalVariete(String documentId) async {
    try {
      await _db.delete(
        'varietes',
        where: 'document_id = ?',
        whereArgs: [documentId],
      );
    } catch (e) {
      print('Erreur lors de la suppression locale de la variété: $e');
      rethrow;
    }
  }

  // Synchronisation vers Firestore
  Future<void> syncParcelles() async {
    try {
      final List<Map<String, dynamic>> localParcelles = await _db.query('parcelles');
      final List<Parcelle> parcelles = localParcelles.map((map) => Parcelle.fromMap(map)).toList();

      for (var parcelle in parcelles) {
        if (parcelle.documentId != null) {
          await _parcelleService.update(parcelle.documentId!, parcelle);
        } else {
          final docId = await _parcelleService.create(parcelle);
          await _db.update(
            'parcelles',
            {'document_id': docId},
            where: 'id = ?',
            whereArgs: [parcelle.id],
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la synchronisation des parcelles: $e');
      rethrow;
    }
  }

  Future<void> syncCellules() async {
    try {
      final List<Map<String, dynamic>> localCellules = await _db.query('cellules');
      final List<Cellule> cellules = localCellules.map((map) => Cellule.fromMap(map)).toList();

      for (var cellule in cellules) {
        if (cellule.documentId != null) {
          await _celluleService.update(cellule.documentId!, cellule);
        } else {
          final docId = await _celluleService.create(cellule);
          await _db.update(
            'cellules',
            {'document_id': docId},
            where: 'id = ?',
            whereArgs: [cellule.id],
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la synchronisation des cellules: $e');
      rethrow;
    }
  }

  Future<void> syncChargements() async {
    try {
      final List<Map<String, dynamic>> localChargements = await _db.query('chargements');
      final List<Chargement> chargements = localChargements.map((map) => Chargement.fromMap(map)).toList();

      for (var chargement in chargements) {
        if (chargement.documentId != null) {
          await _chargementService.update(chargement.documentId!, chargement);
        } else {
          final docId = await _chargementService.create(chargement);
          await _db.update(
            'chargements',
            {'document_id': docId},
            where: 'id = ?',
            whereArgs: [chargement.id],
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la synchronisation des chargements: $e');
      rethrow;
    }
  }

  Future<void> syncSemis() async {
    try {
      final List<Map<String, dynamic>> localSemis = await _db.query('semis');
      final List<Semis> semis = localSemis.map((map) => Semis.fromMap(map)).toList();

      for (var semis in semis) {
        if (semis.documentId != null) {
          await _semisService.update(semis.documentId!, semis);
        } else {
          final docId = await _semisService.create(semis);
          await _db.update(
            'semis',
            {'document_id': docId},
            where: 'id = ?',
            whereArgs: [semis.id],
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la synchronisation des semis: $e');
      rethrow;
    }
  }

  Future<void> syncVarietes() async {
    try {
      final List<Map<String, dynamic>> localVarietes = await _db.query('varietes');
      final List<Variete> varietes = localVarietes.map((map) => Variete.fromMap(map)).toList();

      for (var variete in varietes) {
        if (variete.documentId != null) {
          await _varieteService.update(variete.documentId!, variete);
        } else {
          final docId = await _varieteService.create(variete);
          await _db.update(
            'varietes',
            {'document_id': docId},
            where: 'id = ?',
            whereArgs: [variete.id],
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la synchronisation des variétés: $e');
      rethrow;
    }
  }

  Future<void> syncAll() async {
    try {
      await syncParcelles();
      await syncCellules();
      await syncChargements();
      await syncSemis();
      await syncVarietes();
    } catch (e) {
      print('Erreur lors de la synchronisation complète: $e');
      rethrow;
    }
  }
} 