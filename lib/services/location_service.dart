// services/location_service.dart - AVEC SUPPORT WEB
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService {
  /// Ouvrir Google Maps avec une adresse
  /// Fonctionne sur Android, iOS et Web
  static Future<void> openGoogleMaps(String address) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);
      final googleMapsUrl = 'https://www.google.com/maps/search/$encodedAddress';
      
      // Sur le web, utiliser directement launchUrl
      if (kIsWeb) {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.platformDefault,
        );
      } else {
        // Sur mobile (Android/iOS)
        if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
          await launchUrl(
            Uri.parse(googleMapsUrl),
            mode: LaunchMode.externalApplication,
          );
        } else {
          throw 'Impossible d\'ouvrir Google Maps';
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'ouverture de Google Maps: $e');
      rethrow;
    }
  }

  /// Ouvrir Apple Maps (iOS uniquement)
  static Future<void> openAppleMaps(String address) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);
      final appleMapsUrl = 'maps://maps.apple.com/?address=$encodedAddress';
      
      // Apple Maps fonctionne seulement sur iOS (pas sur web)
      if (!kIsWeb) {
        if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
          await launchUrl(
            Uri.parse(appleMapsUrl),
            mode: LaunchMode.externalApplication,
          );
        } else {
          throw 'Apple Maps non disponible';
        }
      } else {
        throw 'Apple Maps non disponible sur web';
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'ouverture d\'Apple Maps: $e');
      rethrow;
    }
  }

  /// Ouvrir l'app Maps appropriée selon la plateforme
  /// Sur iOS: essaie Apple Maps d'abord, puis Google Maps
  /// Sur Android/Web: ouvre Google Maps
  static Future<void> openMaps(String address) async {
    try {
      // Sur iOS, essayer Apple Maps d'abord
      if (!kIsWeb) {
        try {
          await openAppleMaps(address);
          return;
        } catch (e) {
          debugPrint('⚠️ Apple Maps non disponible, essai Google Maps...');
        }
      }
      
      // Fallback ou défaut: Google Maps
      await openGoogleMaps(address);
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'ouverture de Maps: $e');
      rethrow;
    }
  }

  /// Version alternative pour web et mobile (plus robuste)
  /// Essaie d'ouvrir directement sans vérification canLaunch
  static Future<void> openMapsAlternative(String address) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);
      
      // Sur iOS, essayer Apple Maps d'abord
      if (!kIsWeb && defaultTargetPlatform.name == 'ios') {
        try {
          final appleMapsUrl = 'maps://maps.apple.com/?address=$encodedAddress';
          await launchUrl(Uri.parse(appleMapsUrl));
          return;
        } catch (e) {
          debugPrint('⚠️ Apple Maps non disponible, essai Google Maps...');
        }
      }
      
      // Google Maps (fonctionne partout)
      final googleMapsUrl = 'https://www.google.com/maps/search/$encodedAddress';
      await launchUrl(Uri.parse(googleMapsUrl));
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'ouverture de Maps: $e');
      rethrow;
    }
  }
}