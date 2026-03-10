import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coentrepreneurs/models/badge_model.dart';

class BadgeData {
  final List<BadgeType> earned;
  final int eventsAttended;
  final int parrainages;

  const BadgeData({
    required this.earned,
    required this.eventsAttended,
    required this.parrainages,
  });
}

class BadgeService {
  static Future<BadgeData> loadBadges(Map<String, dynamic> userData) async {
    final userId = (userData['id'] ?? userData['uid']) as String?;
    if (userId == null) {
      return const BadgeData(earned: [], eventsAttended: 0, parrainages: 0);
    }

    // Nombre d'événements auxquels l'utilisateur a participé (statut 'confirmed')
    final registrationsResult = await Supabase.instance.client
        .from('registrations')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'confirmed');
    final eventsAttended = (registrationsResult as List).length;

    // Nombre de membres parrainés par cet utilisateur
    final parrainagesResult = await Supabase.instance.client
        .from('users')
        .select('id')
        .eq('parrain_id', userId);
    final parrainages = (parrainagesResult as List).length;

    final earned = computeBadges(
      userData: userData,
      eventsAttended: eventsAttended,
      parrainages: parrainages,
    );

    return BadgeData(
      earned: earned,
      eventsAttended: eventsAttended,
      parrainages: parrainages,
    );
  }

  static List<BadgeType> computeBadges({
    required Map<String, dynamic> userData,
    required int eventsAttended,
    required int parrainages,
  }) {
    final earned = <BadgeType>[];

    // ── Profil complet ──────────────────────────────────────────
    final prenom = (userData['prenom'] ?? '').toString().trim();
    final nom = (userData['nom'] ?? '').toString().trim();
    final phone = (userData['phone'] ?? '').toString().trim();
    final passions = (userData['passions'] ?? '').toString().trim();
    final memberSinceRaw = userData['member_since'];
    if (prenom.isNotEmpty &&
        nom.isNotEmpty &&
        phone.isNotEmpty &&
        passions.isNotEmpty &&
        memberSinceRaw != null) {
      earned.add(BadgeType.profilComplet);
    }

    // ── Fidèle & Pionnier ───────────────────────────────────────
    if (memberSinceRaw != null) {
      final memberSince = DateTime.tryParse(memberSinceRaw.toString());
      if (memberSince != null) {
        final yearsAsMember =
            DateTime.now().difference(memberSince).inDays / 365;
        if (yearsAsMember >= 1) earned.add(BadgeType.fidele);
        if (memberSince.year <= 2018) earned.add(BadgeType.pionnier);
      }
    }

    // ── Actif ───────────────────────────────────────────────────
    if (eventsAttended >= 10) earned.add(BadgeType.actif);

    // ── Ambassadeur ─────────────────────────────────────────────
    if (parrainages >= 2) earned.add(BadgeType.ambassadeur);

    return earned;
  }
}
