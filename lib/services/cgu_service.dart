// services/cgu_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coentrepreneurs/models/cgu_acceptance.dart';

class CGUService {
  SupabaseClient get _supabase => Supabase.instance.client;

  // Version actuelle des CGU — incrémenter si le texte change afin de forcer
  // les utilisateurs à ré-accepter la nouvelle version.
  static const String currentCGUVersion = '1.0';

  /// Vérifie si l'utilisateur a accepté la version actuelle des CGU.
  Future<bool> hasUserAcceptedCGU(String userId) async {
    try {
      final data = await _supabase
          .from('cgu_acceptances')
          .select()
          .eq('user_id', userId)
          .eq('cgu_version', currentCGUVersion)
          .maybeSingle();

      if (data == null) return false;
      final acceptance = CGUAcceptance.fromMap(data);
      return acceptance.hasAccepted;
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur lors de la vérification des CGU: $e');
      // En cas d'erreur réseau, on ne bloque pas l'utilisateur
      return true;
    }
  }

  /// Enregistre l'acceptation des CGU par l'utilisateur.
  Future<void> acceptCGU(String userId) async {
    try {
      final now = DateTime.now().toIso8601String();

      // Vérifie si une acceptation existe déjà pour cette version
      final existing = await _supabase
          .from('cgu_acceptances')
          .select('id')
          .eq('user_id', userId)
          .eq('cgu_version', currentCGUVersion)
          .maybeSingle();

      if (existing != null) {
        // Mise à jour de l'enregistrement existant
        await _supabase
            .from('cgu_acceptances')
            .update({'has_accepted': true, 'accepted_date': now})
            .eq('user_id', userId)
            .eq('cgu_version', currentCGUVersion);
      } else {
        // Nouvel enregistrement
        await _supabase.from('cgu_acceptances').insert({
          'user_id': userId,
          'has_accepted': true,
          'accepted_date': now,
          'cgu_version': currentCGUVersion,
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur lors de l\'enregistrement de l\'acceptation des CGU: $e');
      rethrow;
    }
  }

  /// Contenu complet des CGU.
  static const String cguContent = '''
Conditions Générales d'Utilisation (CGU)
Application mobile CoEntrepreneurs

1. Objet de l'application
L'application CoEntrepreneurs est une plateforme communautaire destinée aux membres de l'association CoEntrepreneurs.
Elle a pour objectif de :

 - faciliter les échanges entre adhérents,

 - organiser et gérer les rencontres, événements et ateliers,

 - partager des ressources, idées et retours d'expérience,

 - favoriser l'entraide, la coopération et le développement entrepreneurial local.

L'application est un outil, pas une fin. Elle sert le collectif avant tout.

2. Accès à l'application
L'accès à l'application est réservé :

 - aux membres adhérents de l'association,

 - aux invités ponctuels autorisés par l'association,

 - aux administrateurs désignés.

Chaque utilisateur est responsable des informations fournies lors de son inscription et s'engage à fournir des données exactes et à jour.

Tout usage frauduleux, détourné ou contraire à l'esprit de l'association pourra entraîner une suspension ou suppression du compte, sans préavis.

3. Règles de politesse, de respect et de savoir-vivre
L'application CoEntrepreneurs est un espace humain avant d'être numérique.

Chaque utilisateur s'engage à :

 - s'exprimer avec courtoisie, respect et bienveillance,

 - accepter la diversité des parcours, des opinions et des niveaux d'expérience,

 - critiquer des idées, jamais des personnes,

 - écouter avant de répondre,

 - contribuer de manière constructive aux échanges.

Sont strictement interdits :

 - les propos agressifs, méprisants, humiliants ou dégradants,

 - toute forme de discrimination (origine, genre, âge, religion, orientation, situation professionnelle, etc.),

 - le harcèlement, l'intimidation ou les attaques personnelles,

 - la diffusion de fausses informations volontaires ou trompeuses,

 - le spam, l'auto-promotion abusive ou la sollicitation commerciale non consentie.

Le respect n'est pas une option.
C'est une condition d'appartenance.

4. Éthique et valeurs de l'association
En utilisant l'application, l'utilisateur adhère aux valeurs suivantes :

 - entraide plutôt que compétition stérile,

 - partage d'expérience plutôt que posture de sachant,

 - responsabilité individuelle dans un cadre collectif,

 - usage raisonné et conscient du numérique,

 - respect du temps, de l'énergie et des données des autres.

L'application n'est pas un terrain de chasse commerciale ni un ring idéologique.
C'est un lieu de coopération.

5. Contenus publiés par les utilisateurs
Chaque utilisateur reste pleinement responsable des contenus qu'il publie (textes, images, documents, messages).

Il s'engage à ne pas publier :

 -de contenu illégal ou contraire à la loi,

 - de contenu portant atteinte à la vie privée d'autrui,

 - de contenu protégé par des droits d'auteur sans autorisation,

 - de contenu diffamatoire ou mensonger.

L'association se réserve le droit de :

 - modérer,

 - masquer,

 - supprimer tout contenu jugé contraire aux présentes CGU ou à l'esprit de l'association.

6. Données personnelles et confidentialité
Les données collectées via l'application sont utilisées uniquement dans le cadre des activités de l'association CoEntrepreneurs.

Elles ne sont :

 - ni revendues,

 - ni exploitées à des fins commerciales externes,

 - ni utilisées sans lien avec la vie associative.

Chaque utilisateur dispose d'un droit d'accès, de modification et de suppression de ses données, conformément à la réglementation en vigueur (RGPD).

La confiance est une richesse collective. Elle ne se monnaye pas.

7. Responsabilité
L'association met tout en œuvre pour assurer le bon fonctionnement de l'application, mais ne peut garantir une disponibilité permanente.

L'association ne saurait être tenue responsable :

 - des interruptions temporaires du service,

 - des pertes de données liées à des incidents techniques,

 - des conséquences d'échanges ou décisions prises entre membres via l'application.

L'application facilite les liens. Elle ne se substitue ni au discernement individuel, ni à la responsabilité personnelle.

8. Sanctions et exclusions
En cas de non-respect des présentes CGU, l'association se réserve le droit de :

 - adresser un avertissement,

 - suspendre temporairement l'accès,

 - exclure définitivement un utilisateur.

Ces mesures ne sont jamais prises à la légère.
Elles visent à protéger le collectif, pas à punir arbitrairement.

9. Évolution des CGU
Les présentes CGU peuvent évoluer afin de s'adapter :

 - aux besoins de l'association,

 - aux évolutions techniques,

 - aux obligations légales.

Les utilisateurs seront informés des mises à jour importante.

10. Acceptation
L'utilisation de l'application CoEntrepreneurs vaut acceptation pleine et entière des présentes Conditions Générales d'Utilisation.

Participer au collectif, c'est accepter ses règles.
Et surtout, c'est choisir d'en être un acteur responsable


''';
}
