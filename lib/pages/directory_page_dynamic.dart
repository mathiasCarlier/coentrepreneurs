import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class DirectoryPageDynamic extends StatefulWidget {
  const DirectoryPageDynamic({super.key});

  @override
  State<DirectoryPageDynamic> createState() => _DirectoryPageDynamicState();
}

class _DirectoryPageDynamicState extends State<DirectoryPageDynamic> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annuaire Adhérents'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Column(
        children: [
          // En-tête avec barre de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Annuaire — CoEntrepreneurs',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Adhérents - Contacts & activités',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                // Champ de recherche
                TextField(
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
              ],
            ),
          ),
          // Liste des adhérents et admins
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('❌ Erreur: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                final allMembers = snapshot.data!.docs;
                final filteredMembers = allMembers.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final role = data['role']?.toString().toLowerCase() ?? 'invite';
                  
                  // Exclure les invités
                  if (role == 'invite') {
                    return false;
                  }
                  
                  final prenom = data['prenom']?.toString().toLowerCase() ?? '';
                  final nom = data['nom']?.toString().toLowerCase() ?? '';
                  final email = data['email']?.toString().toLowerCase() ?? '';
                  final companyName = data['companyName']?.toString().toLowerCase() ?? '';
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

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredMembers.length,
                  itemBuilder: (context, index) {
                    final doc = filteredMembers[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildCard(context, data);
                  },
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
    
    // Informations professionnelles
    final shareProInfo = memberData['shareProInfo'] ?? false;
    final companyName = shareProInfo ? (memberData['companyName'] ?? '') : '';

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
                            // Badge Admin
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
                        // Entreprise si partagée
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
                  // Icône pour indiquer qu'il faut cliquer
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Tel et Email en ligne
              Row(
                children: [
                  if (phone.isNotEmpty)
                    Expanded(
                      child: Row(
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
                    ),
                ],
              ),
              if (phone.isNotEmpty && email.isNotEmpty)
                const SizedBox(height: 8),
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
      ),
    );
  }

  Widget _buildProInfo(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.orange[700],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo(String value, String label) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String phone, String email, String website) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Appeler
        if (phone.isNotEmpty)
          _buildButton(
            label: 'Appeler',
            onPressed: () => _launchURL('tel:$phone'),
          ),
        // Email
        if (email.isNotEmpty)
          _buildButton(
            label: 'Email',
            onPressed: () => _launchURL('mailto:$email'),
          ),
        // Visiter site
        if (website.isNotEmpty)
          _buildButton(
            label: 'Site web',
            onPressed: () => _launchURL(_formatWebsiteUrl(website)),
          ),
      ],
    );
  }

  String _formatWebsiteUrl(String website) {
    if (!website.startsWith('http://') && !website.startsWith('https://')) {
      return 'https://$website';
    }
    return website;
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
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
    final Uri uri = Uri.parse(url);
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
    
    // Informations professionnelles
    final shareProInfo = memberData['shareProInfo'] ?? false;
    final companyName = shareProInfo ? (memberData['companyName'] ?? '') : '';
    final skills = shareProInfo ? (memberData['skills'] ?? '') : '';
    final professionalAddress = shareProInfo ? (memberData['professionalAddress'] ?? '') : '';
    final website = shareProInfo ? (memberData['website'] ?? '') : '';

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
                  // Use a slightly lighter dark background and stronger border for contrast
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
                    color: isDark ? Colors.orange[900]?.withOpacity(0.08) : Colors.orange[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.orange[700]!.withOpacity(0.28) : Colors.orange[200]!,
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