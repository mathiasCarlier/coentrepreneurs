import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DirectoryPageDynamic extends StatefulWidget {
  const DirectoryPageDynamic({super.key});

  @override
  State<DirectoryPageDynamic> createState() => _DirectoryPageDynamicState();
}

class _DirectoryPageDynamicState extends State<DirectoryPageDynamic> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _refreshKey = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annuaire Adhérents'),
        elevation: 0,
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? const Color.fromARGB(255, 17, 17, 17)
                : Colors.white,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Chercher un adhérent...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          // Liste des adhérents et admins
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              key: ValueKey(_refreshKey),
              stream: Supabase.instance.client
                  .from('users')
                  .stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('❌ Erreur: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Aucun adhérent trouvé',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  );
                }

                // Filtrer les adhérents et admins selon la recherche (exclure les invités)
                final filteredMembers = snapshot.data!.where((data) {
                  final role = data['role']?.toString().toLowerCase() ?? 'invite';

                  // Exclure les invités
                  if (role == 'invite') return false;

                  final prenom = data['prenom']?.toString().toLowerCase() ?? '';
                  final nom = data['nom']?.toString().toLowerCase() ?? '';
                  final email = data['email']?.toString().toLowerCase() ?? '';
                  final companyName = data['company_name']?.toString().toLowerCase() ?? '';
                  final skills = data['skills']?.toString().toLowerCase() ?? '';

                  return prenom.contains(_searchQuery) ||
                      nom.contains(_searchQuery) ||
                      email.contains(_searchQuery) ||
                      companyName.contains(_searchQuery) ||
                      skills.contains(_searchQuery);
                }).toList();

                if (filteredMembers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Aucun adhérent ne correspond à votre recherche',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _refreshKey++);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filteredMembers.length,
                    itemBuilder: (context, index) {
                      return _buildCard(context, filteredMembers[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> memberData) {
    final prenom = memberData['prenom'] ?? 'N/A';
    final nom = memberData['nom'] ?? 'N/A';
    final email = memberData['email'] ?? '';
    final phone = memberData['phone'] ?? '';
    final role = memberData['role'] ?? 'adherent';
    final photoUrl = memberData['photo_url'] as String?;

    // Informations professionnelles
    final shareProInfo = memberData['share_pro_info'] ?? false;
    final companyName = shareProInfo ? (memberData['company_name'] ?? '') : '';

    final initials =
        '${prenom.isNotEmpty ? prenom[0] : ''}${nom != 'N/A' && nom.isNotEmpty ? nom[0] : ''}'
            .toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DirectoryDetailPage(memberData: memberData),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar : photo ou initiales
              CircleAvatar(
                radius: 26,
                backgroundColor: role == 'admin' ? Colors.red[100] : Colors.blue[100],
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null || photoUrl.isEmpty
                    ? Text(
                        initials.isEmpty ? '?' : initials,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: role == 'admin' ? Colors.red[700] : Colors.blue[700],
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom, prénom et badge admin
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '$prenom $nom',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (role == 'admin') ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red[600],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Admin',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (companyName.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  companyName,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (phone.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              phone,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (phone.isNotEmpty && email.isNotEmpty) const SizedBox(height: 6),
                    if (email.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.email, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              email,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

// ========================================
// 📄 PAGE DE DÉTAILS - Affichage complet
// ========================================

class DirectoryDetailPage extends StatelessWidget {
  final Map<String, dynamic> memberData;

  const DirectoryDetailPage({
    super.key,
    required this.memberData,
  });

  Future<void> _launchURL(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    const allowed = {'http', 'https', 'tel', 'mailto'};
    if (!allowed.contains(uri.scheme)) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatWebsiteUrl(String website) {
    if (!website.startsWith('http://') && !website.startsWith('https://')) {
      return 'https://$website';
    }
    return website;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prenom = memberData['prenom'] ?? 'N/A';
    final nom = memberData['nom'] ?? 'N/A';
    final email = memberData['email'] ?? '';
    final phone = memberData['phone'] ?? '';
    final role = memberData['role'] ?? 'adherent';
    final photoUrl = memberData['photo_url'] as String?;

    // Informations professionnelles
    final shareProInfo = memberData['share_pro_info'] ?? false;
    final companyName = shareProInfo ? (memberData['company_name'] ?? '') : '';
    final skills = shareProInfo ? (memberData['skills'] ?? '') : '';
    final professionalAddress = shareProInfo ? (memberData['professional_address'] ?? '') : '';
    final website = shareProInfo ? (memberData['website'] ?? '') : '';

    final initials =
        '${prenom.isNotEmpty && prenom != 'N/A' ? prenom[0] : ''}${nom.isNotEmpty && nom != 'N/A' ? nom[0] : ''}'
            .toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text('$prenom $nom'),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section En-tête
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar centré
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: role == 'admin' ? Colors.red[100] : Colors.blue[100],
                        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null || photoUrl.isEmpty
                            ? Text(
                                initials.isEmpty ? '?' : initials,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                  color: role == 'admin' ? Colors.red[700] : Colors.blue[700],
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Nom et badge
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$prenom $nom',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : null,
                                ),
                              ),
                              if (companyName.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  companyName,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDark ? Colors.orange[300] : Colors.orange[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (role == 'admin')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[600],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Admin',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Contacts
                    if (phone.isNotEmpty)
                      _buildDetailItem(
                        icon: Icons.phone,
                        label: 'Téléphone',
                        value: phone,
                        isDark: isDark,
                      ),
                    if (phone.isNotEmpty && email.isNotEmpty)
                      const SizedBox(height: 12),
                    if (email.isNotEmpty)
                      _buildDetailItem(
                        icon: Icons.email,
                        label: 'Email',
                        value: email,
                        isDark: isDark,
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Section Infos professionnelles si partagées
              if (shareProInfo && (skills.isNotEmpty || professionalAddress.isNotEmpty || website.isNotEmpty)) ...[
                Text(
                  'Informations professionnelles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // Dark mode: use a darker, slightly orange-tinted background
                    color: isDark ? Colors.orange[900]?.withValues(alpha: 0.08) : Colors.orange[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.orange[700]!.withValues(alpha: 0.28) : Colors.orange[200]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (skills.isNotEmpty) ...[
                        _buildDetailItem(
                          icon: Icons.lightbulb,
                          label: 'Activités / Compétences',
                          value: skills,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (professionalAddress.isNotEmpty) ...[
                        _buildDetailItem(
                          icon: Icons.location_on,
                          label: 'Adresse',
                          value: professionalAddress,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (website.isNotEmpty) ...[
                        _buildDetailItem(
                          icon: Icons.language,
                          label: 'Site web',
                          value: website,
                          isDark: isDark,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Boutons d'action
              if (phone.isNotEmpty || email.isNotEmpty || website.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (phone.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: () => _launchURL('tel:$phone'),
                            icon: const Icon(Icons.phone),
                            label: const Text('Appeler'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        if (email.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: () => _launchURL('mailto:$email'),
                            icon: const Icon(Icons.email),
                            label: const Text('Email'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        if (website.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: () => _launchURL(_formatWebsiteUrl(website)),
                            icon: const Icon(Icons.language),
                            label: const Text('Site web'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? Colors.blue[300] : Colors.blue[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[300] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}