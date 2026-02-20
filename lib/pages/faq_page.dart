// lib/pages/faq_page.dart

import 'package:flutter/material.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final List<FAQCategory> _categories = [
    FAQCategory(
      title: 'À propos de l\'association',
      icon: Icons.group,
      color: Colors.blue,
      questions: [
        FAQItem(
          question: 'Qu\'est-ce que l\'association des CoEntrepreneurs ?',
          answer: 'Les CoEntrepreneurs sont une association locale qui réunit des entrepreneurs, indépendants, artisans, commerçants et porteurs de projets souhaitant avancer ensemble. L\'objectif est de rompre l\'isolement, partager les expériences, développer son activité et créer des opportunités professionnelles dans un cadre simple et bienveillant.',
        ),
        FAQItem(
          question: 'À qui s\'adresse l\'association ?',
          answer: 'L\'association s\'adresse à toute personne ayant une activité professionnelle ou un projet en cours : indépendants, micro-entrepreneurs, dirigeants de petites structures, salariés en reconversion ou créateurs d\'entreprise. Aucun niveau ou secteur d\'activité n\'est requis.',
        ),
        FAQItem(
          question: 'Pourquoi adhérer plutôt que rester seul ?',
          answer: 'Entreprendre seul est souvent plus difficile. L\'association permet d\'échanger avec des personnes qui rencontrent les mêmes problématiques : trouver des clients, organiser son activité, prendre du recul ou simplement garder la motivation. Les rencontres permettent de gagner du temps, d\'éviter certaines erreurs et de bénéficier de l\'expérience des autres.',
        ),
        FAQItem(
          question: 'Quels sont les bénéfices concrets pour mon activité ?',
          answer: 'L\'adhésion permet notamment :\n\n• Développer son réseau local\n• Se faire connaître auprès d\'autres professionnels\n• Trouver des partenaires ou des clients\n• Échanger des compétences\n• Participer à des rencontres thématiques et ateliers pratiques\n\nBeaucoup de collaborations naissent simplement des échanges informels entre membres.',
        ),
        FAQItem(
          question: 'Est-ce un réseau d\'affaires ou un groupe d\'entraide ?',
          answer: 'Les deux, mais sans obligation commerciale. L\'objectif principal reste l\'entraide et la création de liens durables. Les opportunités professionnelles viennent naturellement lorsque la confiance s\'installe entre les membres.',
        ),
        FAQItem(
          question: 'Comment se déroulent les rencontres ?',
          answer: 'Les rencontres sont conviviales et ouvertes. Elles permettent de présenter son activité, partager ses problématiques, proposer des idées ou découvrir des sujets utiles à l\'entrepreneuriat (numérique, communication, organisation, outils, etc.). Chacun peut participer à son rythme.',
        ),
        FAQItem(
          question: 'Faut-il être disponible souvent ?',
          answer: 'Non. Chaque membre participe selon ses disponibilités. L\'association n\'impose pas de présence obligatoire. L\'idée est d\'apporter de la valeur sans ajouter de contrainte supplémentaire dans le quotidien professionnel.',
        ),
        FAQItem(
          question: 'Puis-je venir avant d\'adhérer ?',
          answer: 'Oui. Il est possible de participer à une rencontre pour découvrir l\'ambiance et le fonctionnement avant de rejoindre officiellement l\'association.',
        ),
        FAQItem(
          question: 'Quelle est la différence avec un réseau professionnel classique ?',
          answer: 'Les CoEntrepreneurs privilégient la proximité, la simplicité et l\'humain. Il n\'y a pas de pression commerciale, ni d\'obligation de recommandation. Le fonctionnement repose sur le partage d\'expérience, la confiance et la coopération locale.',
        ),
        FAQItem(
          question: 'Comment adhérer ?',
          answer: 'Il suffit de participer à une rencontre ou de contacter l\'association pour obtenir les informations d\'adhésion et d\'obtenir les conditions d\'admission. L\'objectif est avant tout de s\'assurer que chacun se reconnaît dans l\'esprit du groupe.',
        ),
      ],
    ),
    
    FAQCategory(
      title: 'Comment apporter son aide',
      icon: Icons.volunteer_activism,
      color: Colors.green,
      questions: [
        FAQItem(
          question: 'Faut-il être expert pour aider les autres ?',
          answer: 'Non. L\'aide ne vient pas forcément de l\'expertise technique. Un retour d\'expérience, une idée, un contact ou simplement une écoute attentive peuvent déjà débloquer une situation. Souvent, une question simple permet à quelqu\'un d\'y voir plus clair.',
        ),
        FAQItem(
          question: 'Comment puis-je aider concrètement pendant une rencontre ?',
          answer: 'Il suffit de participer activement : écouter, partager ce que tu as vécu, expliquer comment tu as résolu un problème similaire ou proposer une piste de réflexion. Les échanges informels sont souvent les plus utiles.',
        ),
        FAQItem(
          question: 'Je débute, est-ce que je peux vraiment apporter quelque chose ?',
          answer: 'Oui. Les débutants posent souvent les meilleures questions. Elles obligent à clarifier les choses et permettent à tout le monde d\'avancer. Une rencontre fonctionne quand chacun apporte son regard, pas seulement ses compétences.',
        ),
        FAQItem(
          question: 'Dois-je proposer mes services ou parler de mon activité ?',
          answer: 'Tu peux le faire naturellement, mais l\'objectif n\'est pas de vendre. L\'aide passe d\'abord par la compréhension des besoins des autres. Les collaborations arrivent ensuite, presque naturellement, lorsque la confiance s\'installe.',
        ),
        FAQItem(
          question: 'Comment aider sans prendre trop de place ?',
          answer: 'En laissant de la place aux autres. Poser des questions, reformuler, encourager les échanges permet souvent d\'aider davantage que de monopoliser la parole. Une bonne rencontre ressemble plus à une conversation qu\'à une présentation.',
        ),
        FAQItem(
          question: 'Puis-je aider après la rencontre ?',
          answer: 'Oui, et c\'est souvent là que les choses avancent vraiment. Envoyer un contact, partager un lien utile, proposer un échange rapide ou un retour d\'expérience quelques jours plus tard prolonge l\'esprit d\'entraide.',
        ),
        FAQItem(
          question: 'Et si je ne sais pas quoi dire sur le moment ?',
          answer: 'Ce n\'est pas un problème. L\'écoute est déjà une forme d\'aide. Comprendre les enjeux des autres permet parfois d\'apporter une idée plus tard, lorsque le recul est là.',
        ),
        FAQItem(
          question: 'Est-ce que l\'aide doit être réciproque ?',
          answer: 'Pas immédiatement. L\'association fonctionne sur un principe simple : chacun aide quand il peut, et reçoit de l\'aide à d\'autres moments. L\'équilibre se crée naturellement dans le temps.',
        ),
        FAQItem(
          question: 'Quelle est la meilleure manière d\'aider le groupe ?',
          answer: 'Venir avec un état d\'esprit ouvert, bienveillant et constructif. Partager les réussites comme les difficultés permet aux autres d\'apprendre plus vite et évite à chacun de refaire les mêmes erreurs.',
        ),
      ],
    ),
    
    FAQCategory(
      title: 'Inviter un entrepreneur',
      icon: Icons.person_add,
      color: Colors.orange,
      questions: [
        FAQItem(
          question: 'Pourquoi inviter un entrepreneur à une rencontre ?',
          answer: 'Parce qu\'un entrepreneur travaille souvent seul. Une rencontre permet de sortir du quotidien, d\'échanger avec d\'autres personnes qui vivent les mêmes réalités et de découvrir un environnement bienveillant. L\'objectif n\'est pas de convaincre, mais de faire découvrir.',
        ),
        FAQItem(
          question: 'Quelle est la bonne démarche pour inviter quelqu\'un ?',
          answer: 'La meilleure approche reste la simplicité. Parler de ton expérience personnelle fonctionne mieux qu\'un discours préparé. Expliquer ce que les rencontres t\'apportent concrètement crée une connexion naturelle.\n\nExemples de phrases simples :\n\n• "On se retrouve entre entrepreneurs une fois par mois pour échanger simplement, sans pression commerciale. Si ça te dit, tu peux venir voir comment ça se passe."\n\n• "Ça m\'aide à prendre du recul sur mon activité, je pense que ça pourrait aussi t\'intéresser."\n\n• "Viens une fois, tu verras si l\'ambiance te plaît."',
        ),
        FAQItem(
          question: 'Pourquoi l\'émotionnel est-il important dans l\'invitation ?',
          answer: 'Un entrepreneur ne vient pas pour une structure, mais pour une ambiance. Les premiers pas sont souvent hésitants : peur de ne pas connaître, de devoir se vendre, de perdre du temps. Ce qui rassure, c\'est de sentir qu\'il sera accueilli simplement, sans jugement. L\'envie de venir naît davantage d\'un ressenti que d\'un argument.',
        ),
        FAQItem(
          question: 'Comment mettre à l\'aise une personne qui vient pour la première fois ?',
          answer: 'L\'accueillir personnellement, la présenter aux autres et rester disponible au début de la rencontre. Les premières minutes comptent énormément. Quand quelqu\'un se sent attendu et intégré rapidement, il participe naturellement.',
        ),
        FAQItem(
          question: 'Faut-il expliquer tout le fonctionnement de l\'association ?',
          answer: 'Non. Trop d\'explications peuvent créer une barrière. Il suffit de donner l\'essentiel : un moment d\'échange entre entrepreneurs locaux. Le reste se découvre sur place.',
        ),
        FAQItem(
          question: 'Quelles sont les erreurs à éviter ?',
          answer: '• Présenter la rencontre comme un réseau d\'affaires ou un lieu pour trouver des clients rapidement\n\n• Mettre de la pression pour adhérer\n\n• Promettre des résultats ou des retours commerciaux\n\n• Faire un discours trop commercial ou trop structuré\n\n• Inviter quelqu\'un sans l\'accompagner lors de sa première venue\n\nUne invitation qui ressemble à une vente crée souvent de la méfiance.',
        ),
        FAQItem(
          question: 'Et si la personne ne souhaite pas venir ?',
          answer: 'Ce n\'est pas un problème. Le bon moment n\'est pas toujours le même pour tout le monde. L\'important est de laisser la porte ouverte sans insister.',
        ),
        FAQItem(
          question: 'Quel est le vrai objectif d\'une invitation réussie ?',
          answer: 'Permettre à quelqu\'un de faire un premier pas sereinement. Quand l\'accueil est simple et sincère, la suite se fait naturellement. Les relations professionnelles solides commencent presque toujours par un moment humain réussi.',
        ),
      ],
    ),
    
    FAQCategory(
      title: 'Le partage et le réseau',
      icon: Icons.share,
      color: Colors.purple,
      questions: [
        FAQItem(
          question: 'Qu\'est-ce qu\'un réseau d\'entrepreneurs, au fond ?',
          answer: 'Un réseau n\'est pas un carnet d\'adresses. C\'est un ensemble de relations vivantes où les informations, les idées et les opportunités circulent. Un réseau fonctionne quand chacun apporte un peu, pas quand chacun attend beaucoup. Ce qui crée de la valeur, ce ne sont pas les cartes de visite, mais la confiance entre les personnes.',
        ),
        FAQItem(
          question: 'Pourquoi le partage est-il si important ?',
          answer: 'Parce qu\'un entrepreneur ne peut pas tout savoir ni tout faire seul. Partager une expérience, une erreur ou une solution permet aux autres d\'avancer plus vite. Et ce qui est souvent oublié : celui qui partage apprend aussi. Expliquer, transmettre, recommander renforce sa propre compréhension et sa crédibilité.',
        ),
        FAQItem(
          question: 'Beaucoup d\'entrepreneurs gardent leurs contacts ou leurs idées. Est-ce une bonne stratégie ?',
          answer: 'À court terme, cela peut donner l\'impression de se protéger. À long terme, cela isole. Un réseau fermé finit par s\'appauvrir. À l\'inverse, un entrepreneur qui partage devient naturellement une personne ressource. Et les personnes ressources sont celles que l\'on recommande spontanément.',
        ),
        FAQItem(
          question: 'Pourquoi le bouche-à-oreille reste la première source de nouveaux clients ?',
          answer: 'Parce que la confiance ne se fabrique pas avec de la publicité. Quand quelqu\'un recommande un professionnel, il engage sa propre réputation. Cette recommandation vaut plus que n\'importe quel argument commercial. Le bouche-à-oreille naît presque toujours d\'une relation humaine positive.',
        ),
        FAQItem(
          question: 'Est-ce que partager signifie donner sans rien recevoir ?',
          answer: 'Non. Le partage n\'est pas un sacrifice, c\'est un échange dans le temps. L\'aide ne revient pas forcément de la même personne, ni immédiatement. Mais dans un groupe actif, celui qui contribue finit toujours par recevoir en retour, souvent de manière inattendue.',
        ),
        FAQItem(
          question: 'Comment partager concrètement lors d\'une rencontre ?',
          answer: 'En parlant de ses expériences réelles, en citant des contacts utiles, en orientant quelqu\'un vers la bonne personne, ou simplement en prenant le temps d\'écouter. Parfois, une mise en relation de deux minutes crée plus de valeur qu\'une longue présentation.',
        ),
        FAQItem(
          question: 'Pourquoi l\'humain est-il naturellement fait pour partager ?',
          answer: 'Depuis toujours, les groupes humains avancent grâce à la coopération. Les connaissances, les outils et les savoir-faire se transmettent. L\'entrepreneuriat moderne donne parfois l\'illusion qu\'il faut se battre seul, alors que les projets les plus solides naissent souvent d\'échanges et de collaborations.',
        ),
        FAQItem(
          question: 'Que se passe-t-il quand le partage devient naturel dans un groupe ?',
          answer: 'Le climat change. Les discussions deviennent plus ouvertes, les problèmes se résolvent plus vite, et les opportunités apparaissent sans être forcées. Le réseau cesse d\'être un lieu où l\'on cherche des clients et devient un espace où l\'on construit des relations durables.',
        ),
      ],
    ),
    
    FAQCategory(
      title: 'Charte éthique',
      icon: Icons.policy,
      color: Colors.amber,
      questions: [
        FAQItem(
          question: 'L\'esprit de la ruche',
          answer: 'Les CoEntrepreneurs sont une ruche d\'entrepreneurs. Une ruche ne vit pas grâce à une seule abeille, mais grâce à l\'équilibre entre toutes. Chacun y apporte son énergie, son expérience et son regard pour que l\'ensemble progresse.\n\nCette charte rappelle l\'état d\'esprit qui permet à la ruche de rester vivante, accueillante et constructive pour tous.',
        ),
        FAQItem(
          question: 'Le respect avant tout',
          answer: 'Dans une ruche, chaque abeille a sa place. Les échanges se font dans le respect des parcours, des opinions et des rythmes de chacun.\n\nLes attitudes dominantes, les jugements ou les comportements centrés sur l\'ego fragilisent l\'équilibre du groupe. La réussite individuelle est encouragée lorsqu\'elle s\'inscrit dans le respect collectif.',
        ),
        FAQItem(
          question: 'La bienveillance comme nectar commun',
          answer: 'La bienveillance consiste à vouloir faire progresser l\'autre, sans jugement. Chacun peut partager ses réussites comme ses difficultés en toute sécurité.\n\nLes CoEntrepreneurs sont aussi un espace où l\'on peut demander de l\'aide lorsque l\'activité devient difficile, lorsque le doute s\'installe ou lorsque l\'isolement se fait sentir. Une ruche forte soutient ses abeilles dans les moments plus fragiles.',
        ),
        FAQItem(
          question: 'La simplicité plutôt que l\'apparence',
          answer: 'Les rencontres privilégient l\'authenticité. Ici, on ne vient pas pour impressionner, mais pour échanger simplement.\n\nLes postures d\'expert, les discours trop commerciaux ou les démonstrations d\'ego éloignent du fonctionnement naturel de la ruche. La simplicité crée la confiance, et la confiance permet aux relations de durer.',
        ),
        FAQItem(
          question: 'La collaboration plutôt que la compétition',
          answer: 'Une abeille ne garde pas le pollen pour elle seule. Le partage d\'informations, d\'expériences et de contacts permet à chacun d\'avancer plus vite.\n\nLes CoEntrepreneurs encouragent les coopérations et les mises en relation. Le succès de l\'un nourrit souvent les opportunités des autres.',
        ),
        FAQItem(
          question: 'La joie comme énergie de la ruche',
          answer: 'Entreprendre est exigeant. Les rencontres sont aussi là pour retrouver de l\'élan, de la légèreté et du plaisir à échanger.\n\nLa joie, l\'humour et la convivialité font partie intégrante de la ruche. Un environnement positif permet de garder la motivation et de traverser les périodes plus complexes avec plus de force.',
        ),
        FAQItem(
          question: 'Le soutien sans jugement',
          answer: 'Prendre des décisions entrepreneuriales peut être difficile. La ruche est un espace où l\'on peut exposer ses doutes, ses choix ou ses hésitations sans crainte d\'être jugé.\n\nLes échanges ont pour objectif d\'éclairer, jamais d\'imposer. Chacun reste libre de ses décisions, tout en bénéficiant du regard collectif.',
        ),
        FAQItem(
          question: 'L\'abondance plutôt que le manque',
          answer: 'La ruche fonctionne sur un principe d\'abondance. Partager une idée, un contact ou une opportunité n\'appauvrit pas, au contraire. Plus les échanges circulent, plus les opportunités apparaissent.\n\nLe bouche-à-oreille, la recommandation et la confiance naissent naturellement dans un environnement où l\'on donne avant de chercher à recevoir.',
        ),
        FAQItem(
          question: 'L\'équilibre de la ruche',
          answer: 'Chacun est libre de participer à sa manière, mais chacun est aussi responsable de l\'ambiance collective. Lorsque l\'état d\'esprit s\'éloigne durablement de ces valeurs, un échange peut être proposé afin de préserver l\'harmonie du groupe.',
        ),
        FAQItem(
          question: 'Notre engagement commun',
          answer: 'Nous choisissons de construire un réseau humain, respectueux et vivant. Un lieu où l\'on peut avancer, partager, demander de l\'aide, célébrer les réussites et traverser les difficultés ensemble.\n\nUne ruche prospère lorsque chaque abeille contribue, même modestement. Ce sont ces contributions, répétées avec sincérité, qui fabriquent le miel collectif et l\'abondance pour tous.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ - Questions fréquentes'),
        elevation: 0,
        backgroundColor: isDark ? const Color.fromARGB(255, 17, 17, 17) : Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return _buildCategoryCard(_categories[index], isDark);
              },
            ),
            _buildCharteImage(),
          ],
        ),
      ),
    );
  }

  Widget _buildCharteImage() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/charte_ethique.jpg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildCategoryCard(FAQCategory category, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(category.icon, color: category.color),
          ),
          title: Text(
            category.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            '${category.questions.length} section(s)',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          children: category.questions.map((faq) {
            return _buildFAQItem(faq, isDark);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.question_answer,
                size: 20,
                color: isDark ? Colors.blue[300] : Colors.blue[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  faq.question,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.blue[300] : Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            faq.answer,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}

// Modèles de données
class FAQCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<FAQItem> questions;

  FAQCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.questions,
  });
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}