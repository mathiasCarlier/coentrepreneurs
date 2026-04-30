# Résumé de `directory_page_dynamic.dart`

**But :** Annuaire dynamique listant les adhérents et admins de l'association,
avec recherche en temps réel et affichage détaillé par membre.
Composé de deux widgets distincts : `DirectoryPageDynamic` (liste) et
`DirectoryDetailPage` (fiche détaillée).

---

## Architecture générale

DirectoryPageDynamic (StatefulWidget)
├── TextField (recherche locale)
├── StreamBuilder → users (Realtime)
│   └── ListView
│       └── _buildCard()         — carte compacte par membre
│           └── Navigator.push → DirectoryDetailPage
DirectoryDetailPage (StatelessWidget)
├── Section en-tête              — avatar, nom, badge admin, contacts
├── Section infos professionnelles — si shareProInfo == true
├── BadgesSection                — widget externe de gamification
└── Section Actions              — boutons Appeler / Email / Site web

---

## `DirectoryPageDynamic`

### État local

| Variable | Type | Rôle |
|---|---|---|
| `_searchQuery` | `String` | Chaîne de recherche courante (en minuscules) |
| `_searchController` | `TextEditingController` | Lié au `TextField` de recherche |
| `_refreshKey` | `int` | Incrémenté au pull-to-refresh pour recréer le stream |

### Stream Supabase

Écoute la table `users` entière via `.stream(primaryKey: ['id'])` (Realtime).
Le filtrage est appliqué **côté Dart** après réception des données.

Deux niveaux de filtrage successifs :
1. **Par rôle** : exclut les utilisateurs dont le rôle contient `'invite'`
2. **Par recherche** : filtre sur `prenom`, `nom`, `email`, `company_name`, `skills`

> Les informations professionnelles (`company_name`, `skills`) sont incluses
> dans la recherche même si `share_pro_info == false`, car le filtrage porte
> sur les champs bruts. Seul l'affichage respecte le flag `share_pro_info`.

### Pull-to-refresh

`RefreshIndicator` incrémente `_refreshKey`, ce qui recrée le `StreamBuilder`
via sa `key: ValueKey(_refreshKey)` et force un nouveau stream Supabase.

### `_buildCard()`

Carte compacte (`Card` + `InkWell`) affichant :

| Élément | Condition |
|---|---|
| Avatar (photo ou initiales) | Toujours — bleu (adhérent) / rouge (admin) |
| Badge `Admin` rouge | Si `role == 'admin'` |
| Nom de l'entreprise | Si `share_pro_info == true` et `company_name` non vide |
| Téléphone | Si `phone` non vide |
| Email | Si `email` non vide |
| Flèche `›` | Toujours (indicateur de navigation) |

Un tap ouvre `DirectoryDetailPage` via `Navigator.push` avec la `Map` brute
du membre en paramètre.

---

## `DirectoryDetailPage`

Widget `StatelessWidget` recevant `memberData` (la `Map` Supabase brute).

### Respect du flag `share_pro_info`

Toutes les informations professionnelles sont conditionnées à `share_pro_info == true`.
Si le flag est `false`, les variables `companyName`, `skills`, `professionalAddress`
et `website` sont forcées à des chaînes vides, quel que soit le contenu en base.

| Champ | Affiché si |
|---|---|
| `company_name` | `share_pro_info == true` |
| `skills` | `share_pro_info == true` |
| `professional_address` | `share_pro_info == true` |
| `website` | `share_pro_info == true` |
| `phone`, `email` | Toujours (contacts de base) |

### Sections affichées

**En-tête** (`Container` grisé arrondi) :
- Avatar centré (rayon 40, photo ou initiales)
- Nom complet + badge `Admin` si applicable
- Entreprise en orange si `share_pro_info` et non vide
- Téléphone et email en lecture

**Informations professionnelles** (fond orange teinté) :
- Visible uniquement si `share_pro_info == true` et au moins un champ non vide
- Activités/Compétences, Adresse professionnelle, Site web

**Badges** : `BadgesSection(userData: memberData)` — widget externe de gamification

**Actions** : boutons `ElevatedButton` en bleu, affichés via `Wrap` si au moins
un contact ou site est disponible

### `_launchURL(String url)`

Ouvre une URL via `url_launcher` avec `LaunchMode.externalApplication`.
Schémas autorisés : `http`, `https`, `tel`, `mailto`.
Valide l'URI avant de tenter le lancement (`Uri.tryParse` + vérification du schéma).

### `_formatWebsiteUrl(String website)`

Préfixe `https://` si l'URL saisie ne commence pas par `http://` ou `https://`,
pour garantir un schéma valide avant `_launchURL`.

### `_buildDetailItem()`

Widget utilitaire local (similaire à `_InfoItem` dans `settings_page`).
Affiche une icône bleue + label grisé + valeur en semi-gras, adapté au thème.

---

## Table Supabase

| Table | Opération | Champs lus |
|---|---|---|
| `users` | SELECT (stream Realtime) | `id`, `prenom`, `nom`, `email`, `phone`, `role`, `photo_url`, `share_pro_info`, `company_name`, `skills`, `professional_address`, `website` |

Aucune écriture n'est effectuée depuis cette page.

## Widgets et packages externes

| Élément | Rôle |
|---|---|
| `BadgesSection` | Affichage des badges de gamification (dans la fiche détail) |
| `url_launcher` | Ouverture des liens `tel:`, `mailto:`, `https://` |

---

## Limites et points d'attention

- Le stream charge **tous** les utilisateurs sans pagination — à surveiller si
  la base grossit significativement.
- La recherche inclut `company_name` et `skills` sans tenir compte de
  `share_pro_info`, ce qui peut faire remonter un membre sur un critère
  professionnel qu'il ne souhaite pas afficher.
- Les numéros de téléphone et URLs ne sont pas normalisés à la saisie
  (voir `settings_page`) — `_formatWebsiteUrl` corrige partiellement ce point
  pour les sites web, mais pas pour les numéros.