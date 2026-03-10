import 'package:flutter/material.dart';

enum BadgeType {
  profilComplet,
  fidele,
  actif,
  pionnier,
  ambassadeur,
}

class BadgeInfo {
  final BadgeType type;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const BadgeInfo({
    required this.type,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const Map<BadgeType, BadgeInfo> kBadges = {
  BadgeType.profilComplet: BadgeInfo(
    type: BadgeType.profilComplet,
    label: 'Profil complet',
    description: 'A renseigné toutes ses informations',
    icon: Icons.verified_user,
    color: Color(0xFF2196F3),
  ),
  BadgeType.fidele: BadgeInfo(
    type: BadgeType.fidele,
    label: 'Fidèle',
    description: 'Membre depuis plus d\'un an',
    icon: Icons.loyalty,
    color: Color(0xFF9C27B0),
  ),
  BadgeType.actif: BadgeInfo(
    type: BadgeType.actif,
    label: 'Actif',
    description: 'A participé à 10 événements',
    icon: Icons.local_fire_department,
    color: Color(0xFFFF5722),
  ),
  BadgeType.pionnier: BadgeInfo(
    type: BadgeType.pionnier,
    label: 'Pionnier',
    description: 'Membre fondateur (adhérent depuis 2018)',
    icon: Icons.emoji_events,
    color: Color(0xFFFFB300),
  ),
  BadgeType.ambassadeur: BadgeInfo(
    type: BadgeType.ambassadeur,
    label: 'Ambassadeur',
    description: 'A parrainé 2 membres ou plus',
    icon: Icons.groups,
    color: Color(0xFF4CAF50),
  ),
};
