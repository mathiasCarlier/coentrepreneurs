Résumé de `location_service.dart`

But: Service d'intégration cartographique pour les lieux d'événements.

Points clés

- `openGoogleMaps(address)` : ouvre Google Maps avec recherche URL-encoded.
- `openAppleMaps(address)` : ouvre Apple Maps (schéma `maps://`, iOS uniquement).
- `openMaps(address)` : choix automatique selon la plateforme
  (Apple Maps sur iOS, Google Maps en fallback).
- `openMapsAlternative(address)` : version robuste sans vérification `canLaunchUrl`.

Pattern: détection de plateforme via `kIsWeb` et `defaultTargetPlatform`.
Utilise `url_launcher` avec mode `ExternalApplication`.
