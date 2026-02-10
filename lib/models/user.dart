// Roles applicatifs pour distinguer les permissions côté UI/back-end.
enum UserRole { admin, adherent, invite }

// Modèle `User` utilisé dans l'application (séparé du `firebase_auth.User`).
// Contient les champs affichés et persistés dans Firestore (`users/{uid}`).
// Remarque: la conversion `role.toString().split('.').last` est utilisée
// pour stocker une représentation texte simple en Firestore.
class User {
  final String uid;
  final String email;
  String nom;
  String prenom;
  String phone;
  String? photoUrl;
  final UserRole role;

  User({
    required this.uid,
    required this.email,
    required this.nom,
    required this.prenom,
    this.phone = '',
    this.photoUrl,
    this.role = UserRole.invite,
  });

  /// Convertit l'objet User en JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': role.toString().split('.').last,
    };
  }

  /// Crée un User à partir d'un JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] as String,
      email: json['email'] as String,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      phone: (json['phone'] ?? '') as String,
      photoUrl: json['photoUrl'] as String?,
      role: _parseRole(json['role']),
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
    UserRole? role,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      phone: phone ?? this.phone,
      role: role ?? this.role,
    );
  }

  @override
  String toString() =>
      'User(uid: $uid, email: $email, prenom: $prenom, nom: $nom, phone: $phone, photoUrl: $photoUrl, role: $role)';
}