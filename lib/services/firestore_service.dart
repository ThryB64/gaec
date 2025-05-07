import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parcelle.dart';
import '../models/cellule.dart';
import '../models/chargement.dart';
import '../models/semis.dart';
import '../models/variete.dart';
import 'dart:convert';

abstract class FirestoreService<T> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection;

  FirestoreService(this.collection);

  // Convertir un document Firestore en objet T
  T fromFirestore(DocumentSnapshot doc);

  // Convertir un objet T en Map pour Firestore
  Map<String, dynamic> toFirestore(T item);

  // Créer un nouvel élément
  Future<String> create(T item) async {
    final docRef = await _firestore.collection(collection).add(toFirestore(item));
    return docRef.id;
  }

  // Lire un élément par son ID
  Future<T?> read(String id) async {
    final doc = await _firestore.collection(collection).doc(id).get();
    if (!doc.exists) return null;
    return fromFirestore(doc);
  }

  // Mettre à jour un élément
  Future<void> update(String id, T item) async {
    await _firestore.collection(collection).doc(id).update(toFirestore(item));
  }

  // Supprimer un élément
  Future<void> delete(String id) async {
    await _firestore.collection(collection).doc(id).delete();
  }

  // Lister tous les éléments
  Stream<List<T>> list() {
    return _firestore.collection(collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  // Lister les éléments avec un filtre
  Stream<List<T>> listWhere(String field, dynamic value) {
    return _firestore
        .collection(collection)
        .where(field, isEqualTo: value)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  // Lister les éléments avec plusieurs filtres
  Stream<List<T>> listWhereMultiple(List<Map<String, dynamic>> conditions) {
    Query query = _firestore.collection(collection);
    for (var condition in conditions) {
      query = query.where(
        condition['field'],
        isEqualTo: condition['value'],
      );
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }
}

class FirestoreServiceParcelle extends FirestoreService<Parcelle> {
  FirestoreServiceParcelle() : super('parcelles');

  @override
  Parcelle fromFirestore(DocumentSnapshot doc) => Parcelle.fromMap(doc.data() as Map<String, dynamic>);

  @override
  Map<String, dynamic> toFirestore(Parcelle parcelle) => parcelle.toMap();
}

class FirestoreServiceCellule extends FirestoreService<Cellule> {
  FirestoreServiceCellule() : super('cellules');

  @override
  Cellule fromFirestore(DocumentSnapshot doc) => Cellule.fromMap(doc.data() as Map<String, dynamic>);

  @override
  Map<String, dynamic> toFirestore(Cellule cellule) => cellule.toMap();
}

class FirestoreServiceChargement extends FirestoreService<Chargement> {
  FirestoreServiceChargement() : super('chargements');

  @override
  Chargement fromFirestore(DocumentSnapshot doc) => Chargement.fromMap(doc.data() as Map<String, dynamic>);

  @override
  Map<String, dynamic> toFirestore(Chargement chargement) => chargement.toMap();
}

class FirestoreServiceSemis extends FirestoreService<Semis> {
  FirestoreServiceSemis() : super('semis');

  @override
  Semis fromFirestore(DocumentSnapshot doc) => Semis.fromMap(doc.data() as Map<String, dynamic>);

  @override
  Map<String, dynamic> toFirestore(Semis semis) => semis.toMap();
}

class FirestoreServiceVariete extends FirestoreService<Variete> {
  FirestoreServiceVariete() : super('varietes');

  @override
  Variete fromFirestore(DocumentSnapshot doc) => Variete.fromMap(doc.data() as Map<String, dynamic>);

  @override
  Map<String, dynamic> toFirestore(Variete variete) => variete.toMap();
}

class FirestoreServiceInitialSync {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collections
  static const String _parcellesCollection = 'parcelles';
  static const String _cellulesCollection = 'cellules';
  static const String _chargementsCollection = 'chargements';
  static const String _semisCollection = 'semis';
  static const String _varietesCollection = 'varietes';

  // Méthode pour la synchronisation initiale
  Future<void> syncInitialData({
    required List<Parcelle> parcelles,
    required List<Cellule> cellules,
    required List<Chargement> chargements,
    required List<Semis> semis,
    required List<Variete> varietes,
  }) async {
    final batch = _firestore.batch();

    // Synchroniser les parcelles
    for (var parcelle in parcelles) {
      final docRef = _firestore
          .collection(_parcellesCollection)
          .doc(parcelle.id.toString());
      batch.set(docRef, parcelle.toMap());
    }

    // Synchroniser les cellules
    for (var cellule in cellules) {
      final docRef = _firestore
          .collection(_cellulesCollection)
          .doc(cellule.id.toString());
      batch.set(docRef, cellule.toMap());
    }

    // Synchroniser les chargements
    for (var chargement in chargements) {
      final docRef = _firestore
          .collection(_chargementsCollection)
          .doc(chargement.id.toString());
      batch.set(docRef, chargement.toMap());
    }

    // Synchroniser les semis
    for (var semis in semis) {
      final docRef = _firestore
          .collection(_semisCollection)
          .doc(semis.id.toString());
      batch.set(docRef, semis.toMap());
    }

    // Synchroniser les variétés
    for (var variete in varietes) {
      final docRef = _firestore
          .collection(_varietesCollection)
          .doc(variete.id.toString());
      batch.set(docRef, variete.toMap());
    }

    await batch.commit();
  }
} 