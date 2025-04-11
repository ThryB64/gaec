
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parcelle.dart';
import '../models/cellule.dart';
import '../models/chargement.dart';
import '../models/semis.dart';
import '../models/variete.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // === Parcelles ===
  Future<List<Parcelle>> getParcelles() async {
    final snapshot = await _firestore.collection('parcelles').orderBy('date_creation').get();
    return snapshot.docs.map((doc) => Parcelle.fromMap({...doc.data(), 'id': doc.id}));
  }

  Future<void> addParcelle.fromMap(Parcelle parcelle) async {
    await _firestore.collection('parcelles').add(parcelle.toMap());
  }

  Future<void> deleteParcelle.fromMap(String id) async {
    await _firestore.collection('parcelles').doc(id).delete();
  }

  // === Cellules ===
  Future<List<Cellule>> getCellules() async {
    final snapshot = await _firestore.collection('cellules').orderBy('date_creation').get();
    return snapshot.docs.map((doc) => Cellule.fromMap({...doc.data(), 'id': doc.id}));
  }

  Future<void> addCellule.fromMap(Cellule cellule) async {
    await _firestore.collection('cellules').add(cellule.toMap());
  }

  Future<void> deleteCellule.fromMap(String id) async {
    await _firestore.collection('cellules').doc(id).delete();
  }

  // === Chargements ===
  Future<List<Chargement>> getChargements() async {
    final snapshot = await _firestore.collection('chargements').orderBy('dateChargement').get();
    return snapshot.docs.map((doc) => Chargement.fromMap({...doc.data(), 'id': doc.id}));
  }

  Future<void> addChargement.fromMap(Chargement chargement) async {
    await _firestore.collection('chargements').add(chargement.toMap());
  }

  Future<void> deleteChargement.fromMap(String id) async {
    await _firestore.collection('chargements').doc(id).delete();
  }

  // === Semis ===
  Future<List<Semis>> getSemis.fromMap() async {
    final snapshot = await _firestore.collection('semis').orderBy('date').get();
    return snapshot.docs.map((doc) => Semis.fromMap({...doc.data(), 'id': doc.id}));
  }

  Future<void> addSemis.fromMap(Semis semis) async {
    await _firestore.collection('semis').add(semis.toMap());
  }

  Future<void> deleteSemis.fromMap(String id) async {
    await _firestore.collection('semis').doc(id).delete();
  }

  // === Variétés ===
  Future<List<Variete>> getVarietes() async {
    final snapshot = await _firestore.collection('varietes').get();
    return snapshot.docs.map((doc) => Variete.fromMap({...doc.data(), 'id': doc.id}));
  }

  Future<void> addVariete.fromMap(Variete variete) async {
    await _firestore.collection('varietes').add(variete.toMap());
  }

  Future<void> deleteVariete.fromMap(String id) async {
    await _firestore.collection('varietes').doc(id).delete();
  }
}
