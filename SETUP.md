# Setup sur PC vierge

## 1. Outils à installer

| Outil | Lien |
|---|---|
| Flutter SDK (stable) | https://flutter.dev/docs/get-started/install |
| Android Studio ou VS Code | Avec extensions Flutter + Dart |
| Git | https://git-scm.com |
| Node.js (optionnel, scripts) | https://nodejs.org |

## 2. Projet

```bash
git clone <url-repo>
cd coentrepreneurs-supabase
flutter pub get
```

## 3. Configuration Supabase

Créer `lib/supabase_config.dart` (non versionné) avec les clés de connexion.
Récupérer les valeurs dans **Supabase Studio → Settings → API** :

- **URL** : `http://46.225.133.77:8000`
- **Anon key** : clé publique affiché dans Studio

## 4. Accès VPS / Supabase self-hosted

| Accès | Valeur |
|---|---|
| IP du VPS | à compléter |
| SSH | `ssh user@IP` (clé privée nécessaire) |
| Supabase Studio | `http://46.225.133.77:8080` |
| Login Studio | voir `DASHBOARD_USERNAME` / `DASHBOARD_PASSWORD` dans `docker-compose.yml` |
| Fichier docker-compose | `/root/supabase/docker/docker-compose.yml` sur le VPS |

> Les identifiants Studio et les clés JWT se trouvent dans le fichier `.env` du dossier Supabase sur le VPS.

## 5. Firebase (push notifications uniquement)

L'app utilise Firebase uniquement pour les notifications push (FCM).
Les fichiers de config ne sont **pas versionnés** — les récupérer dans la console Firebase :

- **Console** : https://console.firebase.google.com
- **Projet ID** : `coentrepreneurs-7b291`
- `google-services.json` → à placer dans `android/app/`
- `GoogleService-Info.plist` → à placer dans `ios/Runner/`

## 6. Lancer l'app

```bash
flutter run          # choisir l'émulateur ou le device connecté
flutter analyze      # vérifier les erreurs statiques
flutter test         # lancer les tests
```

## 7. Commandes utiles

```bash
flutter pub get              # installer les dépendances
flutter build apk            # build Android release
flutter build web            # build Web release
flutter test test/router_utils_test.dart  # test spécifique
```
