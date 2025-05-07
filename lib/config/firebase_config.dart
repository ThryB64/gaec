import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static FirebaseOptions get options {
    if (kDebugMode) {
      debugPrint('Initialisation de Firebase avec les variables d\'environnement');
    }

    return const FirebaseOptions(
      apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
      appId: String.fromEnvironment('FIREBASE_APP_ID'),
      messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
      projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
      storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    );
  }
} 