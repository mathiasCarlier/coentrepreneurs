# Cloud Functions pour l'envoi d'emails

Cette fonction Firebase Cloud envoie automatiquement les emails quand un utilisateur soumet le formulaire de contact.

## Configuration

### 1. Installer les dépendances

```bash
cd functions
npm install
```

### 2. Configurer les variables d'environnement

#### Option A: Utiliser un mot de passe d'application Gmail (Recommandé pour commencer)

1. Aller à https://myaccount.google.com/apppasswords
2. Sélectionner "Mail" et "Windows Computer"
3. Copier le mot de passe généré
4. Créer un fichier `.env` dans le dossier `functions`:

```
EMAIL_USER=mathias1811@gmail.com
EMAIL_PASSWORD=your_16_char_password_here
```

⚠️ **NE JAMAIS pusher le fichier .env en production!**

#### Option B: Utiliser Firebase Secrets Manager (Pour production)

```bash
firebase functions:config:set gmail.email="mathias1811@gmail.com" gmail.password="your_password"
```

Puis modifier `index.js` pour lire depuis les config:
```javascript
const emailUser = functions.config().gmail.email;
const emailPassword = functions.config().gmail.password;
```

### 3. Tester localement

```bash
npm run serve
```

### 4. Déployer sur Firebase

```bash
npm run deploy
```

Ou depuis la racine du projet:
```bash
firebase deploy --only functions
```

## Règles Firestore (Important!)

Assurez-vous que votre collection `emails` a les bonnes règles de sécurité. Exemple:

```
match /emails/{document=**} {
  allow create: if request.auth != null;
  allow read, update: if request.auth.uid == resource.data.userId;
}
```

## Dépannage

### L'email n'est pas envoyé
- Vérifier les logs: `firebase functions:log`
- Vérifier que le mot de passe d'application Gmail est correct
- Vérifier que le compte Gmail a activé "Accès des applications moins sécurisées"

### Erreur "Gmail SMTP error"
- Vérifier le mot de passe d'application (pas le mot de passe Gmail habituel!)
- Utiliser un mot de passe d'application de 16 caractères généré depuis myaccount.google.com

### La fonction ne se déclenche pas
- Vérifier que le document a tous les champs: `to`, `subject`, `body`
- Vérifier les règles Firestore permettent la création

## Structure du document Firestore

Chaque document dans `emails` contient:

```json
{
  "to": "mathias1811@gmail.com",
  "subject": "[Nouvelle idée] - Nom de l'utilisateur",
  "body": "Contenu du message...",
  "timestamp": "2026-02-09T10:30:00Z",
  "status": "sent",
  "sentAt": "2026-02-09T10:30:05Z"
}
```

Le statut peut être:
- `pending` - En attente d'envoi
- `sent` - Envoyé avec succès
- `failed` - Erreur lors de l'envoi

## Support

Pour plus d'infos: https://firebase.google.com/docs/functions
