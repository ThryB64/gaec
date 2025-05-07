import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mais_tracker/services/sync_service.dart';
import 'package:mais_tracker/models/parcelle.dart';
import 'package:mais_tracker/models/cellule.dart';
import 'package:mais_tracker/models/chargement.dart';
import 'package:mais_tracker/models/semis.dart';
import 'package:mais_tracker/models/variete.dart';

class MockDatabase extends Mock implements Database {}
class MockFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentReference extends Mock implements DocumentReference {}
class MockQuerySnapshot extends Mock implements QuerySnapshot {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}

void main() {
  late SyncService syncService;
  late MockDatabase mockDatabase;
  late MockFirestore mockFirestore;

  setUp(() {
    mockDatabase = MockDatabase();
    mockFirestore = MockFirestore();
    syncService = SyncService(mockDatabase);
  });

  group('SyncService Tests', () {
    test('syncParcelles should handle local to Firestore sync', () async {
      // Arrange
      final localParcelles = [
        {
          'id': 1,
          'document_id': 'doc1',
          'nom': 'Parcelle 1',
          'surface': 10.5,
          'date_creation': DateTime.now().toIso8601String(),
          'notes': 'Test notes',
        }
      ];

      when(mockDatabase.query('parcelles')).thenAnswer((_) async => localParcelles);

      // Act
      await syncService.syncParcelles();

      // Assert
      verify(mockDatabase.query('parcelles')).called(1);
    });

    test('syncCellules should handle local to Firestore sync', () async {
      // Arrange
      final localCellules = [
        {
          'id': 1,
          'document_id': 'doc1',
          'reference': 'Cellule 1',
          'capacite': 1000.0,
          'date_creation': DateTime.now().toIso8601String(),
          'notes': 'Test notes',
        }
      ];

      when(mockDatabase.query('cellules')).thenAnswer((_) async => localCellules);

      // Act
      await syncService.syncCellules();

      // Assert
      verify(mockDatabase.query('cellules')).called(1);
    });

    test('syncChargements should handle local to Firestore sync', () async {
      // Arrange
      final localChargements = [
        {
          'id': 1,
          'document_id': 'doc1',
          'cellule_id': 1,
          'parcelle_id': 1,
          'remorque': 'Remorque 1',
          'date_chargement': DateTime.now().toIso8601String(),
          'poids_plein': 1000.0,
          'poids_vide': 500.0,
          'poids_net': 500.0,
          'poids_normes': 450.0,
          'humidite': 15.0,
          'variete': 'Variété 1',
        }
      ];

      when(mockDatabase.query('chargements')).thenAnswer((_) async => localChargements);

      // Act
      await syncService.syncChargements();

      // Assert
      verify(mockDatabase.query('chargements')).called(1);
    });

    test('syncSemis should handle local to Firestore sync', () async {
      // Arrange
      final localSemis = [
        {
          'id': 1,
          'document_id': 'doc1',
          'parcelle_id': 1,
          'date': DateTime.now().toIso8601String(),
          'varietes_surfaces': '{"Variété 1": 5.0}',
          'notes': 'Test notes',
        }
      ];

      when(mockDatabase.query('semis')).thenAnswer((_) async => localSemis);

      // Act
      await syncService.syncSemis();

      // Assert
      verify(mockDatabase.query('semis')).called(1);
    });

    test('syncVarietes should handle local to Firestore sync', () async {
      // Arrange
      final localVarietes = [
        {
          'id': 1,
          'document_id': 'doc1',
          'nom': 'Variété 1',
          'description': 'Test description',
          'date_creation': DateTime.now().toIso8601String(),
        }
      ];

      when(mockDatabase.query('varietes')).thenAnswer((_) async => localVarietes);

      // Act
      await syncService.syncVarietes();

      // Assert
      verify(mockDatabase.query('varietes')).called(1);
    });

    test('syncAll should sync all collections', () async {
      // Arrange
      when(mockDatabase.query(any)).thenAnswer((_) async => []);

      // Act
      await syncService.syncAll();

      // Assert
      verify(mockDatabase.query('parcelles')).called(1);
      verify(mockDatabase.query('cellules')).called(1);
      verify(mockDatabase.query('chargements')).called(1);
      verify(mockDatabase.query('semis')).called(1);
      verify(mockDatabase.query('varietes')).called(1);
    });

    test('should handle errors gracefully', () async {
      // Arrange
      when(mockDatabase.query('parcelles')).thenThrow(Exception('Test error'));

      // Act & Assert
      expect(() => syncService.syncParcelles(), throwsException);
    });
  });
} 