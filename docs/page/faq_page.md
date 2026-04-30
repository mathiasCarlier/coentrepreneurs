# Résumé de `faq_page.dart`

**But :** Page FAQ statique présentant les questions fréquentes et la charte éthique
de l'association, organisées en catégories dépliables. Aucune interaction avec
Supabase — tout le contenu est déclaré en dur dans le widget.

---

## Architecture générale

FAQPage (StatefulWidget)
├── ListView (catégories)
│   └── _buildCategoryCard()    — ExpansionTile par catégorie
│       └── _buildFAQItem()     — Container question / réponse
└── _buildCharteImage()         — Image de la charte éthique (asset local)
Modèles de données (purs Dart)
├── FAQCategory                 — titre, icône, couleur, liste de FAQItem
└── FAQItem                     — question + réponse

---

## Contenu — Catégories et questions

Le contenu est déclaré dans `_categories`, une `List<FAQCategory>` initialisée
dans l'état du widget. Cinq catégories sont définies :

| # | Catégorie | Icône | Couleur | Nb questions |
|---|---|---|---|---|
| 1 | À propos de l'association | `group` | Bleu | 10 |
| 2 | Comment apporter son aide | `volunteer_activism` | Vert | 9 |
| 3 | Inviter un entrepreneur | `person_add` | Orange | 8 |
| 4 | Le partage et le réseau | `share` | Violet | 8 |
| 5 | Charte éthique | `policy` | Ambre | 10 |

---

## Composants détaillés

### `_buildCategoryCard(FAQCategory, isDark)`

`ExpansionTile` dans une `Card` (elevation 2, bords arrondis).

| Élément | Détail |
|---|---|
| Icône colorée | Container avec fond à 10 % d'opacité + `category.color` |
| Titre | `category.title` en gras |
| Sous-titre | `"N section(s)"` — compte les `FAQItem` de la catégorie |
| Enfants | Liste de `_buildFAQItem` pour chaque question |

Le `dividerColor` du `Theme` est forcé à `Colors.transparent` pour supprimer
le séparateur par défaut de l'`ExpansionTile`.

### `_buildFAQItem(FAQItem, isDark)`

`Container` arrondi avec fond grisé (adapté au thème) et bordure subtile.

| Élément | Détail |
|---|---|
| Icône `question_answer` | Bleue, 20 px, alignée en haut à gauche du texte |
| Question | Gras, bleu (`Colors.blue[700]` / `[300]`), 14 px |
| Réponse | Corps de texte gris, hauteur de ligne 1.5, 14 px |

Les réponses peuvent contenir des listes à puces avec le caractère `•`
inséré directement dans la chaîne (`String`), sans rendu Markdown.

### `_buildCharteImage()`

`Container` affiché après la liste des catégories, en dehors du `ListView`.
Charge `assets/images/charte_ethique.jpg` via `Image.asset` avec `BoxFit.cover`.
Bords arrondis (rayon 16) et ombre portée (`BoxShadow` noire à 20 % d'opacité).

> L'image doit être déclarée dans `pubspec.yaml` sous `flutter > assets`.

---

## Modèles de données

### `FAQCategory`

```dart
class FAQCategory {
  final String title;       // Titre de la catégorie
  final IconData icon;      // Icône Material affichée dans l'en-tête
  final Color color;        // Couleur thématique (fond icône + accent)
  final List<FAQItem> questions;
}
```

### `FAQItem`

```dart
class FAQItem {
  final String question;    // Intitulé de la question (affiché en bleu)
  final String answer;      // Réponse en texte libre (peut contenir des • manuels)
}
```

Les deux modèles sont définis en bas du fichier, en dehors de tout widget.
Ils sont purement Dart, sans sérialisation ni dépendance externe.

---

## Points d'attention

- Le contenu est entièrement statique — toute modification nécessite une mise à jour
  du code source et un redéploiement de l'application.
- Les listes à puces dans les réponses utilisent le caractère `•` inséré
  manuellement dans la chaîne. Si le rendu Markdown était activé
  (ex. `flutter_markdown_plus`), il faudrait adapter la syntaxe.
- La `FAQPage` est un `StatefulWidget` sans état réellement mutable :
  `_categories` est initialisée une seule fois et ne change jamais.
  Un `StatelessWidget` suffirait techniquement.
- L'image `charte_ethique.jpg` doit exister dans `assets/images/` et être
  référencée dans `pubspec.yaml`, sinon l'application lèvera une exception au
  chargement.