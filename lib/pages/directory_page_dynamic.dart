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
          // Liste des adhérents
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('role', isEqualTo: 'adherent')
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

                // Filtrer les adhérents selon la recherche
                final allMembers = snapshot.data!.docs;
                final filteredMembers = allMembers.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
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
    
    // Informations professionnelles
    final shareProInfo = memberData['shareProInfo'] ?? false;
    final companyName = shareProInfo ? (memberData['companyName'] ?? '') : '';
    final skills = shareProInfo ? (memberData['skills'] ?? '') : '';
    final professionalAddress = shareProInfo ? (memberData['professionalAddress'] ?? '') : '';
    final website = shareProInfo ? (memberData['website'] ?? '') : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom et prénom
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$prenom $nom',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
              ],
            ),
            const SizedBox(height: 6),
            
            // Rôle / Description
            Text(
              'Adhérent CoEntrepreneurs',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(
                height: 1.35,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            
            // Section informations professionnelles partagées
            if (shareProInfo && (companyName.isNotEmpty || skills.isNotEmpty || professionalAddress.isNotEmpty || website.isNotEmpty))
              ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange[200]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (skills.isNotEmpty) ...[
                        _buildProInfo(
                          context,
                          'Compétences',
                          skills,
                          Icons.lightbulb,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (professionalAddress.isNotEmpty) ...[
                        _buildProInfo(
                          context,
                          'Adresse',
                          professionalAddress,
                          Icons.location_on,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (website.isNotEmpty) ...[
                        _buildProInfo(
                          context,
                          'Site web',
                          website,
                          Icons.language,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            
            const SizedBox(height: 12),
            
            // Infos de contact
            if (phone.isNotEmpty) _buildContactInfo(phone, 'Tél'),
            if (email.isNotEmpty) _buildContactInfo(email, 'Email'),
            if (email.isNotEmpty || phone.isNotEmpty)
              const SizedBox(height: 12),
            
            // Boutons d'action
            _buildActionButtons(phone, email, website),
          ],
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