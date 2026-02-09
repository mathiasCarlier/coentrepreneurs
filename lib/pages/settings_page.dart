// pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:coentrepreneurs/models/user.dart';

class SettingsPage extends StatelessWidget {
  final User user;

  const SettingsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Profil
              _buildProfileSection(context, user, isDark),
              const SizedBox(height: 32),

              // Section Informations Personnelles
              _buildUserInfoSection(context, user, isDark),
              const SizedBox(height: 32),

              // Section Sécurité (optionnel)
              _buildSecuritySection(context, isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    User user,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.blue[900]!.withOpacity(0.3),
                  Colors.purple[900]!.withOpacity(0.3),
                ]
              : [Colors.blue[50]!, Colors.purple[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark ? Colors.blue[700]! : Colors.blue[200]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue[600],
            ),
            child: Center(
              child: Text(
                user.nomComplet
                    .split(' ')
                    .map((e) => e.isNotEmpty ? e[0] : '')
                    .take(2)
                    .join()
                    .toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nomComplet,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getRoleLabel(user.role),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(
    BuildContext context,
    User user,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900]?.withOpacity(0.5) : Colors.grey[100],
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations personnelles',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          _InfoItem(
            icon: Icons.person,
            label: 'Nom complet',
            value: user.nomComplet,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _InfoItem(
            icon: Icons.email,
            label: 'Email',
            value: user.email,
            isDark: isDark,
          ),
          if (user.phone.isNotEmpty) ...[
            const SizedBox(height: 16),
            _InfoItem(
              icon: Icons.phone,
              label: 'Téléphone',
              value: user.phone,
              isDark: isDark,
            ),
          ],
          const SizedBox(height: 16),
          _InfoItem(
            icon: Icons.badge,
            label: 'Rôle',
            value: _getRoleLabel(user.role),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900]?.withOpacity(0.5) : Colors.grey[100],
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sécurité',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.lock_outline,
              color: Colors.grey[600],
            ),
            title: Text(
              'Modifier le mot de passe',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité à venir'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.verified_user,
              color: Colors.grey[600],
            ),
            title: Text(
              'Vérification à deux facteurs',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: Icon(
              Icons.toggle_off,
              color: Colors.grey[600],
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité à venir'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.adherent:
        return 'Adhérent';
      case UserRole.invite:
        return 'Invité';
    }
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.blue[600],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[100] : Colors.grey[900],
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
