import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/parcelle.dart';
import '../models/cellule.dart';
import '../models/chargement.dart';
import '../models/semis.dart';
import '../models/variete.dart';
import '../utils/poids_utils.dart';
import 'dart:convert';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'mais_tracker.db';
  static const int _dbVersion = 8;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    // Supprimer la base de données existante si la version a changé
    final dbExists = await databaseExists(path);
    if (dbExists) {
      final db = await openDatabase(path);
      final version = await db.getVersion();
      await db.close();
      if (version != _dbVersion) {
        await deleteDatabase();
      }
    }

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDb,
      onUpgrade: _onUpgrade,
      singleInstance: true,
      readOnly: false,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE parcelles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        surface REAL NOT NULL,
        date_creation TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cellules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reference TEXT NOT NULL,
        capacite REAL NOT NULL,
        date_creation TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE chargements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cellule_id INTEGER NOT NULL,
        parcelle_id INTEGER NOT NULL,
        remorque TEXT NOT NULL,
        date_chargement TEXT NOT NULL,
        poids_plein REAL NOT NULL,
        poids_vide REAL NOT NULL,
        poids_net REAL NOT NULL,
        poids_normes REAL NOT NULL,
        humidite REAL NOT NULL,
        variete TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (cellule_id) REFERENCES cellules (id),
        FOREIGN KEY (parcelle_id) REFERENCES parcelles (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE semis(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parcelle_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        varietes_surfaces TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (parcelle_id) REFERENCES parcelles (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE varietes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        description TEXT,
        date_creation TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      // Mise à jour de la table chargements
      await db.execute('''
        CREATE TABLE chargements_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cellule_id INTEGER NOT NULL,
          parcelle_id INTEGER NOT NULL,
          remorque TEXT NOT NULL,
          date_chargement TEXT NOT NULL,
          poids_plein REAL NOT NULL,
          poids_vide REAL NOT NULL,
          poids_net REAL NOT NULL,
          poids_normes REAL NOT NULL,
          humidite REAL NOT NULL,
          variete TEXT NOT NULL DEFAULT '',
          FOREIGN KEY (cellule_id) REFERENCES cellules (id),
          FOREIGN KEY (parcelle_id) REFERENCES parcelles (id)
        )
      ''');

      // Copier les données existantes
      await db.execute('''
        INSERT INTO chargements_new (
          id, cellule_id, parcelle_id, remorque, date_chargement,
          poids_plein, poids_vide, poids_net, poids_normes, humidite, variete
        )
        SELECT 
          id, cellule_id, parcelle_id, remorque, date_chargement,
          poids_net, 0, poids_net, poids_net, 0, ''
        FROM chargements
      ''');

      // Supprimer l'ancienne table et renommer la nouvelle
      await db.execute('DROP TABLE chargements');
      await db.execute('ALTER TABLE chargements_new RENAME TO chargements');
    }
    
    if (oldVersion < 7) {
      // Ajouter la colonne variete si elle n'existe pas déjà
      try {
        await db.execute('ALTER TABLE chargements ADD COLUMN variete TEXT NOT NULL DEFAULT ""');
      } catch (e) {
        // La colonne existe peut-être déjà
      }
    }

    if (oldVersion < 8) {
      // Migration pour la nouvelle structure des variétés dans les semis
      await db.execute('''
        CREATE TABLE semis_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          parcelle_id INTEGER NOT NULL,
          date TEXT NOT NULL,
          varietes_surfaces TEXT NOT NULL,
          notes TEXT,
          FOREIGN KEY (parcelle_id) REFERENCES parcelles (id)
        )
      ''');

      // Copier les données existantes en convertissant le format
      final List<Map<String, dynamic>> oldSemis = await db.query('semis');
      for (var semis in oldSemis) {
        final varietes = (semis['varietes'] as String).split(',');
        final varietesSurfaces = varietes.map((v) => {
          'nom': v,
          'pourcentage': 100.0 / varietes.length,
        }).toList();

        await db.insert('semis_new', {
          'id': semis['id'],
          'parcelle_id': semis['parcelle_id'],
          'date': semis['date'],
          'varietes_surfaces': jsonEncode(varietesSurfaces),
          'notes': semis['notes'],
        });
      }

      // Supprimer l'ancienne table et renommer la nouvelle
      await db.execute('DROP TABLE semis');
      await db.execute('ALTER TABLE semis_new RENAME TO semis');
    }
  }

  // Méthodes pour les parcelles
  Future<List<Parcelle>> getParcelles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('parcelles');
    return List.generate(maps.length, (i) => Parcelle.fromMap(maps[i]));
  }

  Future<int> insertParcelle(Parcelle parcelle) async {
    final db = await database;
    return await db.insert('parcelles', parcelle.toMap());
  }

  Future<void> updateParcelle(Parcelle parcelle) async {
    final db = await database;
    await db.update(
      'parcelles',
      parcelle.toMap(),
      where: 'id = ?',
      whereArgs: [parcelle.id],
    );
  }

  Future<void> deleteParcelle(int id) async {
    final db = await database;
    await db.delete(
      'parcelles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Méthodes pour les cellules
  Future<List<Cellule>> getCellules() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cellules');
    return List.generate(maps.length, (i) => Cellule.fromMap(maps[i]));
  }

  Future<int> insertCellule(Cellule cellule) async {
    final db = await database;
    return await db.insert('cellules', cellule.toMap());
  }

  Future<void> updateCellule(Cellule cellule) async {
    final db = await database;
    await db.update(
      'cellules',
      cellule.toMap(),
      where: 'id = ?',
      whereArgs: [cellule.id],
    );
  }

  Future<void> deleteCellule(int id) async {
    final db = await database;
    await db.delete(
      'cellules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Méthodes pour les chargements
  Future<List<Chargement>> getChargements() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('chargements');
    return List.generate(maps.length, (i) => Chargement.fromMap(maps[i]));
  }

  Future<int> insertChargement(Chargement chargement) async {
    final db = await database;
    return await db.transaction((txn) async {
      // Vérifier que la cellule existe
      final cellule = await txn.query(
        'cellules',
        where: 'id = ?',
        whereArgs: [chargement.celluleId],
      );
      if (cellule.isEmpty) {
        throw Exception('La cellule n\'existe pas');
      }

      // Vérifier que la parcelle existe
      final parcelle = await txn.query(
        'parcelles',
        where: 'id = ?',
        whereArgs: [chargement.parcelleId],
      );
      if (parcelle.isEmpty) {
        throw Exception('La parcelle n\'existe pas');
      }

      // Vérifier que le poids plein est supérieur au poids vide
      if (chargement.poidsPlein <= chargement.poidsVide) {
        throw Exception('Le poids plein doit être supérieur au poids vide');
      }

      // Vérifier que l'humidité est valide
      if (chargement.humidite < 0 || chargement.humidite > 100) {
        throw Exception('L\'humidité doit être comprise entre 0 et 100%');
      }

      return await txn.insert('chargements', chargement.toMap());
    });
  }

  Future<void> updateChargement(Chargement chargement) async {
    final db = await database;
    await db.transaction((txn) async {
      // Vérifier que le chargement existe
      final existing = await txn.query(
        'chargements',
        where: 'id = ?',
        whereArgs: [chargement.id],
      );
      if (existing.isEmpty) {
        throw Exception('Le chargement n\'existe pas');
      }

      // Vérifier que la cellule existe
      final cellule = await txn.query(
        'cellules',
        where: 'id = ?',
        whereArgs: [chargement.celluleId],
      );
      if (cellule.isEmpty) {
        throw Exception('La cellule n\'existe pas');
      }

      // Vérifier que la parcelle existe
      final parcelle = await txn.query(
        'parcelles',
        where: 'id = ?',
        whereArgs: [chargement.parcelleId],
      );
      if (parcelle.isEmpty) {
        throw Exception('La parcelle n\'existe pas');
      }

      // Vérifier que le poids plein est supérieur au poids vide
      if (chargement.poidsPlein <= chargement.poidsVide) {
        throw Exception('Le poids plein doit être supérieur au poids vide');
      }

      // Vérifier que l'humidité est valide
      if (chargement.humidite < 0 || chargement.humidite > 100) {
        throw Exception('L\'humidité doit être comprise entre 0 et 100%');
      }

      await txn.update(
        'chargements',
        chargement.toMap(),
        where: 'id = ?',
        whereArgs: [chargement.id],
      );
    });
  }

  Future<void> deleteChargement(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      // Vérifier que le chargement existe
      final existing = await txn.query(
        'chargements',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (existing.isEmpty) {
        throw Exception('Le chargement n\'existe pas');
      }

      await txn.delete(
        'chargements',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> updateAllChargementsPoidsNormes() async {
    final db = await database;
    await db.transaction((txn) async {
      // Récupérer tous les chargements
      final List<Map<String, dynamic>> chargements = await txn.query('chargements');
      print('Nombre de chargements à mettre à jour : ${chargements.length}');
      
      // Mettre à jour chaque chargement
      for (var chargement in chargements) {
        print('Chargement ID: ${chargement['id']}');
        print('Poids plein initial: ${chargement['poids_plein']}');
        print('Poids vide initial: ${chargement['poids_vide']}');
        print('Humidité initiale: ${chargement['humidite']}');
        
        // Convertir explicitement en double pour éviter les problèmes de type
        final double poidsPlein = double.tryParse(chargement['poids_plein'].toString()) ?? 0.0;
        final double poidsVide = double.tryParse(chargement['poids_vide'].toString()) ?? 0.0;
        final double humidite = double.tryParse(chargement['humidite'].toString()) ?? 0.0;
        
        print('Poids plein converti: $poidsPlein');
        print('Poids vide converti: $poidsVide');
        print('Humidité convertie: $humidite');
        
        // Calculer le poids net
        final double poidsNet = PoidsUtils.calculPoidsNet(poidsPlein, poidsVide);
        print('Poids net calculé: $poidsNet');
        
        // Calculer le poids aux normes (15% d'humidité)
        final double poidsNormes = PoidsUtils.calculPoidsNormes(poidsNet, humidite);
        print('Poids aux normes calculé: $poidsNormes');
        
        // Mettre à jour le chargement
        await txn.update(
          'chargements',
          {
            'poids_net': poidsNet,
            'poids_normes': poidsNormes,
          },
          where: 'id = ?',
          whereArgs: [chargement['id']],
        );
        print('Chargement mis à jour avec succès');
      }
    });
  }

  // Méthodes pour les semis
  Future<List<Semis>> getSemis() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('semis');
    return List.generate(maps.length, (i) => Semis.fromMap(maps[i]));
  }

  Future<int> insertSemis(Semis semis) async {
    final db = await database;
    return await db.insert('semis', semis.toMap());
  }

  Future<void> updateSemis(Semis semis) async {
    final db = await database;
    await db.update(
      'semis',
      semis.toMap(),
      where: 'id = ?',
      whereArgs: [semis.id],
    );
  }

  Future<void> deleteSemis(int id) async {
    final db = await database;
    await db.delete(
      'semis',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Méthodes pour les variétés
  Future<List<Variete>> getVarietes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('varietes');
    return List.generate(maps.length, (i) => Variete.fromMap(maps[i]));
  }

  Future<int> insertVariete(Variete variete) async {
    final db = await database;
    return await db.insert('varietes', variete.toMap());
  }

  Future<void> updateVariete(Variete variete) async {
    final db = await database;
    await db.update(
      'varietes',
      variete.toMap(),
      where: 'id = ?',
      whereArgs: [variete.id],
    );
  }

  Future<void> deleteVariete(int id) async {
    final db = await database;
    await db.delete(
      'varietes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
} 