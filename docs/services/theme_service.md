# Résumé de `theme_service.dart`

**But :** Gestion du thème clair/sombre avec persistance dans le `localStorage`
du navigateur. Exposé via `Provider` et consommé dans `home_page` et `login_page`
pour le toggle de thème.

---

## `ThemeNotifier` (ChangeNotifier)

Singleton géré par `Provider` dans le widget tree.

### État

| Membre | Type | Rôle |
|---|---|---|
| `_mode` | `ThemeMode` | Thème actif (`light` ou `dark`) |
| `mode` | `ThemeMode` | Getter public |
| `isDark` | `bool` | Raccourci : `_mode == ThemeMode.dark` |

### Initialisation

Le constructeur appelle `_load()` directement — le thème est disponible
synchronement dès la création du `ThemeNotifier`, sans attendre un `Future`.

### `toggle()`

Bascule entre `ThemeMode.light` et `ThemeMode.dark`, persiste via `_save()`,
puis notifie les listeners pour déclencher le rebuild des widgets consommateurs.

---

## Persistance

### `_load()` (statique)

Lit la clé `'theme_mode'` depuis `localStorage`.
Retourne `ThemeMode.light` par défaut dans trois cas :
- Plateforme non-web (`!kIsWeb`)
- Clé absente du `localStorage`
- Exception lors de l'accès (ex. mode privé restrictif)

### `_save(mode)`

Écrit `'dark'` ou `'light'` dans `localStorage[_key]`.
No-op sur mobile (`!kIsWeb`). Les exceptions sont silencieusement ignorées.

---

## Points d'attention

- La persistance repose sur `universal_html` — fonctionne uniquement sur web.
  Sur mobile, le thème est toujours `ThemeMode.light` et non persisté.
- Le thème ne suit pas la préférence système (`ThemeMode.system` n'est pas
  utilisé) — l'utilisateur doit basculer manuellement.
- Les erreurs d'accès au `localStorage` (ex. navigateur en mode privé avec
  restrictions strictes) sont absorbées silencieusement — le thème clair
  est utilisé par défaut.