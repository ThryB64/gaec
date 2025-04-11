
# Maïs Tracker - Version Firebase (iOS Ready)

Cette version de l'application est entièrement connectée à Firebase.
Toutes les données sont synchronisées via Firestore.

## ✅ Fonctionnalités ajoutées

- Firebase Core intégré
- Firestore pour les données : parcelles, cellules, chargements, semis, variétés
- Connexion automatique à un compte partagé :
  - Email : **ferme@famille.com**
  - Mot de passe : **tonChoix123**
- Prêt à compiler pour iOS via CodeMagic ou AltStore

## ⚙️ Étapes de configuration Firebase

1. Installe `flutterfire` CLI si ce n’est pas déjà fait :
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Lancer la configuration :
   ```bash
   flutterfire configure
   ```
   Cela génèrera le fichier `firebase_options.dart`

3. Installer les dépendances :
   ```bash
   flutter pub get
   ```

4. Lancer l’application :
   ```bash
   flutter run
   ```

## 📦 Compilation iOS

Tu peux compiler l’app pour iPhone en `.ipa` via :

- **CodeMagic** (recommandé sans Mac)
- **AltStore** avec AltServer et un `.ipa` généré

---

> 🔒 Assure-toi que Firestore est bien configuré dans ta console Firebase, avec les collections :
> `parcelles`, `cellules`, `chargements`, `semis`, `varietes`

> 🔐 Authentification : activer la méthode Email/Mot de passe dans Firebase

