import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DirectoryPage extends StatelessWidget {
  const DirectoryPage({Key? key}) : super(key: key);

  // Données de l'annuaire
  static const List<Map<String, dynamic>> members = [
    {
      'brand': 'UTOLYS',
      'name': 'Boris LEJUDE',
      'role':
          'Consultant et coach formateur en informatique, internet et sécurité numérique.',
      'phone': '+33614038742',
      'email': 'boris.lejude@gmail.com',
      'address': '7, rue des marchands, 86200 LOUDUN',
      'website': 'https://www.co-ia.fr',
      'avisGoogle': 'https://share.google/wiUDTEIf0yGKBk9Xr',
    },
    {
      'brand': 'Cathy Aiguilles',
      'name': 'Catherine BAILLERGEANT',
      'role': 'Créatrice travaux d\'aiguille uniques et originaux sur mesure.',
      'phone': '+33781332572',
      'email': 'cathy.baillergeant@gmail.com',
      'address': '7, rue Audin le Tiche, 86200 LOUDUN',
      'website': 'https://www.facebook.com/cathy.aiguilles',
    },
    {
      'brand': null,
      'name': 'Jacqueline DELUCHAT',
      'role': 'Vente à domicile : La boutique de Jackotte',
      'phone': '+33684782590',
      'email': 'jackotte@gmail.com',
      'address': '13 rue de la Malasserie, 79100 PLAINES LES VALLEES',
    },
    {
      'brand': 'Bobine et Tapisserie',
      'name': 'Angélique ORILLUS',
      'role': 'Création vêtements sur mesure - Restauration fauteuil',
      'phone': '+33603648847',
      'email': 'angel.orillus@gmail.com',
      'address': '32, avenue de Leuze, 86200 LOUDUN',
    },
    {
      'brand': null,
      'name': 'Patricia GUILLAUME',
      'role': 'Artiste peintre en décor mural et trompe-l\'œil',
      'phone': '+33683667236',
      'email': 'patricia.guillaume86@orange.fr',
      'address': '19, rue de Martaizé, 86330 AULNAY',
      'website': 'https://patricia-guillaume.com/',
    },
    {
      'brand': 'RETRO86',
      'name': 'Bruno BAILLERGEANT',
      'role': 'Vente et restauration voitures et renovation de cuir',
      'phone': '+33678588260',
      'email': 'retro86bruno@hotmail.fr',
      'address': '7, rue Audin le Tiche, 86200 LOUDUN',
    },
    {
      'brand': 'Allianz',
      'name': 'Willy DUBARD',
      'role': 'Conseiller assurance ALLIANZ. Agence Loudun',
      'phone': '+33749226957',
      'email': 'Willy.dubard@allianz.fr',
      'address': '2, place de la boeuffeterie, 86200 LOUDUN',
      'website': 'https://agence.allianz.fr/loudun-86200-H98639',
    },
    {
      'brand': 'Cfp Gastronomie',
      'name': 'Cécile et Fred PROUX',
      'role': 'Artisan conserveur passionnée, surprenant et surtout super bon',
      'phone': '+33617933208',
      'email': 'cfpgastronomie@orange.fr',
      'address': '19, avenue de touraine, 86200 LOUDUN',
      'website': 'http://www.cfpgastronomie.com/',
    },
    {
      'brand': 'CMO',
      'name': 'Olivier METAIS',
      'role': 'Conseiller ADE Stratégies en protection sociale et patrimoniale',
      'phone': '+33767944616',
      'email': 'o.metais@groupesofraco.com',
      'address': '2 Bis Route de Nieuil l\'Espoir, 86340 VILLEDIEU SUR CLAIN',
      'website': 'https://ade-strategies.fr/',
    },
    {
      'brand': 'Osier Viv',
      'name': 'Bruno METIVIER',
      'role':
          'Création sur mesure de structure osier vivant en pot ou plantées',
      'phone': '+33621734739',
      'email': 'brunolosierviv@hotmail.com',
      'address': '1, rue du Vannier Lieu-dit Nué, 86173 MOUTERRE SILLY',
      'website': 'https://www.losierviv.fr/',
    },
    {
      'brand': 'Marienergie',
      'name': 'Marinette LIEGE',
      'role': 'Magnetiseuse / Reiki / Créatrice de bijou',
      'phone': '+33629662020',
      'email': 'marienergie86@gmail.com',
      'address':
          '2 rue des rosiers - Lieu dit "Verger sur Dive", 86200 VERGER SUR DIVE',
      'website': 'https://www.marienergie-mineraux.fr/',
    },
    {
      'brand': 'Naturellement bien',
      'name': 'Nicole BONNET',
      'role': 'Passionnée par le bien-être et les solutions naturelles',
      'phone': '+33622257965',
      'email': 'naturellementbien86@outlook.fr',
      'address': '6, rue des championnieres - Velors, 86200 LOUDUN',
      'website': 'https://www.facebook.com/profile.php?id=61572205961695',
    },
    {
      'brand': '3 ptit points',
      'name': 'Steffie GUERIN',
      'role': 'Home Staging / Artiste / Infographie / Artisanat d\'art',
      'phone': '+33775296253',
      'email': '3petitspoints49@gmail.com',
      'address': '95 Rue Gérard Martin, 49700 DOUE LA FONTAINE',
      'website': 'https://www.3ptipoints.com/',
    },
    {
      'brand': null,
      'name': 'Eric MICHAUD',
      'role': 'Producteur légumes en culture raisonnée sur le Loudunais',
      'phone': '+33615386065',
      'email': 'ericmichaud86@gmail.com',
      'address': '9, rue george moreau, 86330 ST JEAN DE SAUVES',
    },
    {
      'brand': 'La Presqu\'île de l\'Ours Bleu',
      'name': 'Catherine BERNARD',
      'role': 'Créations textiles, Peinture, aquarelle, dessin',
      'phone': '+33637749469',
      'email': 'catherinebernard684@gmail.com',
      'address': '5 Route de la Sauline, 86420 GUESNES',
    },
    {
      'brand': 'Cap\'RICE',
      'name': 'Anne Laure POINT',
      'role': 'Institut bien-être, soins et accompagnement holistique',
      'phone': '+33549980327',
      'email': 'capriceloudun@gmail.com',
      'address': '8-10 rue Carnot 86200 LOUDUN',
      'website': 'https://capriceloudun.fr/',
    },
    {
      'brand': 'Celle qui croque',
      'name': 'Laeticia DUPORT',
      'role':
          'Créations artisanales en cyanotype : bijoux, déco et accessoires',
      'phone': '+33628079967',
      'email': 'cellequicroque@gmail.com',
      'address': '86200 GUESNES',
      'website': 'https://www.cellequicroque.com/',
    },
    {
      'brand': null,
      'name': 'Roger PERRIN',
      'role': 'Retraité automobile. Passionné chevaux et musique country',
      'phone': '+33668131879',
      'email': 'perrin_roger@orange.fr',
      'address': 'Clerville, 86200 LA ROCHE CLERMAULT',
    },
    {
      'brand': null,
      'name': 'Mesland TOMEN',
      'role': 'Solution technologique en gestion d\'énergie',
      'phone': '+33624011296',
      'email': 'it.mesland@gmail.com',
      'address': 'Région de thouars, 79100 THOUARS',
    },
    {
      'brand': null,
      'name': 'Francois MAUBERGER',
      'role': 'Gravure sur bois, metal - Réparation tel et Vapotage',
      'phone': '+33677770138',
      'email': 'vapophone@hotmail.com',
      'address': '21 RUE DE LA PORTE DE CHINON, 86200 LOUDUN',
      'website': 'https://www.facebook.com/vapophone.loudun/',
    },
    {
      'brand': 'SORECOV',
      'name': 'Jérémie LEFIEFF',
      'role': 'Recyclage de matériaux',
      'phone': '+33646369130',
      'email': 'exploitation.sorecov@gmail.com',
      'address': '15, Impasse du dépot, 86200 LOUDUN',
      'website': 'https://www.sorecov.fr/',
    },
    {
      'brand': 'Au café partagé',
      'name': 'Caroline BAH',
      'role': 'Association du café partagé - Soutien les coentrepreneurs',
      'phone': '+33764015671',
      'email': 'Bah.caroline@neuf.fr',
      'address': '8, rue du college, 86200 LOUDUN',
      'website': 'https://www.facebook.com/p/Au-Café-Partagé-100063784803299/',
    },
    {
      'brand': null,
      'name': 'Laurette HOULLIER',
      'role': 'Soutien la démarche collaborative',
      'email': 'houllierlaurette@orange.fr',
      'address': '1, rue de la fontaine, 86330 ST CLAIR',
    },
  ];

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // NOTE: _launchURL
  // - Ouvre une URL via `url_launcher`. Utilisé pour `tel:`, `mailto:` et
  //   liens web externes. L'appel utilise `LaunchMode.externalApplication`
  //   pour ouvrir l'application externe correspondante.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annuaire CoEntrepreneurs'),
        backgroundColor: Colors.blue[600],
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        children: [
          // En-tête
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
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
                  'Contacts & activités. ${members.length} adhérents.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          // Grille de cartes
          ...members.map((member) => _buildCard(context, member)).toList(),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
            // Marque
            if (member['brand'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    member['brand'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Nom
            Text(
              member['name'],
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            // Rôle
            Text(
              member['role'],
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 12),
            // Infos de contact
            _buildContactInfo(member['phone'], 'Tél'),
            _buildContactInfo(member['email'], 'Email'),
            if (member['address'] != null)
              _buildContactInfo(member['address'], 'Adresse'),
            const SizedBox(height: 12),
            // Boutons d'action
            _buildActionButtons(member),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(String? value, String label) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: TextStyle(fontSize: 14)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> member) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Appeler
        if (member['phone'] != null)
          _buildButton(
            label: 'Appeler',
            onPressed: () => _launchURL('tel:${member['phone']}'),
          ),
        // Email
        if (member['email'] != null)
          _buildButton(
            label: 'Email',
            onPressed: () => _launchURL('mailto:${member['email']}'),
          ),
        // Site
        if (member['website'] != null)
          _buildButton(
            label: 'Site',
            onPressed: () => _launchURL(member['website']),
          ),
        // Avis Google
        if (member['avisGoogle'] != null)
          _buildButton(
            label: 'Avis Google',
            onPressed: () => _launchURL(member['avisGoogle']),
          ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    // Retourne un bouton stylisé avec `InkWell` pour l'effet tactile.
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
