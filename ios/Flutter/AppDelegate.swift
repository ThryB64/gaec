import UIKit
import Flutter
import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialiser Firebase
    FirebaseApp.configure()
    
    // Configurer Firestore
    let db = Firestore.firestore()
    let settings = db.settings
    settings.isPersistenceEnabled = true
    settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
    db.settings = settings
    
    // Configurer le stockage Firebase
    let storage = Storage.storage()
    storage.maxDownloadRetryTime = 60
    storage.maxUploadRetryTime = 60
    
    // Configurer l'authentification Firebase
    Auth.auth().useEmulator(withHost: "localhost", port: 9099)
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func applicationWillTerminate(_ application: UIApplication) {
    // Sauvegarder les données avant la fermeture
    let db = Firestore.firestore()
    db.waitForPendingWrites { error in
      if let error = error {
        print("Erreur lors de la sauvegarde des données: \(error)")
      }
    }
  }
} 