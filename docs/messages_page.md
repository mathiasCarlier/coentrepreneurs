Résumé de `messages_page.dart`

But: Affichage et gestion des messages de contact soumis par les utilisateurs (vue admin).

Points clés

- Stream Realtime sur la table `messages`, triés par date décroissante.
- Chaque message affiche: auteur, email, rôle, catégorie, contenu, date.
- Pièces jointes supportées: image (avec viewer plein écran), lien, fichier.

- Actions admin
  - `_markAsRead(messageId)` : marque comme lu (champ `read`).
  - `_publishMessage(messageId)` : publie vers les notifications (champ `published`).
  - `_deleteMessage(messageId)` : suppression avec dialog de confirmation.

- Indicateurs visuels
  - Messages non lus en surbrillance, lus en opacité réduite.
  - Expansion tiles pour afficher les détails.

Table Supabase: `messages`
Champs: `user_name`, `user_email`, `user_role`, `category`, `message`,
`image_url`, `link_url`, `file_url`, `file_name`, `read`, `published`, `timestamp`
