// Roles applicatifs pour distinguer les permissions côté UI/back-end.
enum UserRole { admin, adherent, invite }

// Modèle `User` utilisé dans l'application.
// Contient les champs affichés et persistés dans la table Supabase `users`.
// Remarque: la conversion `role.toString().split('.').last` est utilisée
// pour stocker une représentation texte simple en base.
class User {
  final String uid;
  String email;
  String nom;
  String prenom;
  String phone;
  String? photoUrl;
  final UserRole role;

  // Champs professionnels (optionnels)
  String? companyName;
  String? skills;
  String? professionalAddress;
  String? website;
  bool? shareProInfo; // Contrôle de partage des infos pro

  User({
    required this.uid,
    required this.email,
    required this.nom,
    required this.prenom,
    this.phone = '',
    this.photoUrl,
    this.role = UserRole.invite,
    // Champs professionnels
    this.companyName,
    this.skills,
    this.professionalAddress,
    this.website,
    this.shareProInfo = false,
  });

  /// Convertit l'objet User en map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': role.toString().split('.').last,
      // Champs professionnels
      'companyName': companyName,
      'skills': skills,
      'professionalAddress': professionalAddress,
      'website': website,
      'shareProInfo': shareProInfo ?? false,
    };
  }

  /// Crée un User à partir d'une map
  factory User.fromMap(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] as String,
      email: json['email'] as String,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      phone: (json['phone'] ?? '') as String,
      photoUrl: json['photoUrl'] as String?,
      role: _parseRole(json['role']),
      // Champs professionnels
      companyName: json['companyName'] as String?,
      skills: json['skills'] as String?,
      professionalAddress: json['professionalAddress'] as String?,
      website: json['website'] as String?,
      shareProInfo: (json['shareProInfo'] ?? false) as bool,
    );
  }

  /// Convertit une chaîne en UserRole
  static UserRole _parseRole(String? roleStr) {
    switch (roleStr) {
      case 'admin':
        return UserRole.admin;
      case 'adherent':
        return UserRole.adherent;
      case 'invite':
      default:
        return UserRole.invite;
    }
  }

  /// Crée une copie avec modifications optionnelles
  User copyWith({
    String? uid,
    String? email,
    String? nom,
    String? prenom,
    String? phone,
    String? photoUrl,
    UserRole? role,
    String? companyName,
    String? skills,
    String? professionalAddress,
    String? website,
    bool? shareProInfo,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      companyName: companyName ?? this.companyName,
      skills: skills ?? this.skills,
      professionalAddress: professionalAddress ?? this.professionalAddress,
      website: website ?? this.website,
      shareProInfo: shareProInfo ?? this.shareProInfo,
    );
  }

  @override
  String toString() =>
      'User(uid: $uid, email: $email, prenom: $prenom, nom: $nom, phone: $phone, '
      'photoUrl: $photoUrl, role: $role, companyName: $companyName, skills: $skills, '
      'professionalAddress: $professionalAddress, website: $website, shareProInfo: $shareProInfo)';
}