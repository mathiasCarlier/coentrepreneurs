// pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:coentrepreneurs/models/user.dart' as user_model;
import 'package:coentrepreneurs/widgets/cgu_acceptance_dialog.dart';
import 'package:coentrepreneurs/services/cgu_service.dart';

class SettingsPage extends StatefulWidget {
  final user_model.User user;

  const SettingsPage({super.key, required this.user});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late user_model.User _user;
  late TextEditingController _prenom;
  late TextEditingController _nom;
  late TextEditingController _phoneController;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  File? _selectedPhoto;
  final CGUService _cguService = CGUService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    
    _prenom = TextEditingController(text: _user.prenom);
    _nom = TextEditingController(text: _user.nom);
    _phoneController = TextEditingController(text: _user.phone);
  }

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        setState(() => _selectedPhoto = File(pickedFile.path));
        _uploadPhoto();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadPhoto() async {
    if (_selectedPhoto == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final fileName = '${_user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child(fileName);

      final uploadTask = ref.putFile(_selectedPhoto!);
      final snapshot = await uploadTask;
      final photoUrl = await snapshot.ref.getDownloadURL();

      // Mettre à jour Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .update({'photoUrl': photoUrl});

      // Mettre à jour l'objet local
      setState(() {
        _user.photoUrl = photoUrl;
        _selectedPhoto = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Photo de profil mise à jour'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _saveUserInfo() async {
    if (_prenom.text.trim().isEmpty || _nom.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le prénom et le nom ne peuvent pas être vides'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .update({
            'prenom': _prenom.text.trim(),
            'nom': _nom.text.trim(),
            'phone': _phoneController.text.trim(),
          });

      // Mettre à jour l'objet _user
      _user.prenom = _prenom.text.trim();
      _user.nom = _nom.text.trim();
      _user.phone = _phoneController.text.trim();

      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Informations mises à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showCGUDialog() async {
    // Vérifier si l'utilisateur a déjà accepté les CGU
    final userAcceptedCGU = await _cguService.hasUserAcceptedCGU(_user.uid);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => CGUAcceptanceDialog(
        alreadyAccepted: userAcceptedCGU,
        userId: _user.uid,
        onAccepted: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ CGU acceptées avec succès'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

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
              // Section Profil avec photo
              _buildProfileSection(context, _user, isDark),
              const SizedBox(height: 32),

              // Section Informations Personnelles (avec édition)
              _buildUserInfoSection(context, _user, isDark),
              const SizedBox(height: 32),

              // Section Sécurité
              _buildSecuritySection(context, isDark),
              const SizedBox(height: 32),

              // Section Légal (CGU)
              _buildLegalSection(context, isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    user_model.User user,
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
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue[600],
                  border: Border.all(
                    color: Colors.blue[400]!,
                    width: 3,
                  ),
                ),
                child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          user.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                '${user.prenom[0]}${user.nom.split(' ').first[0]}'
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          '${user.prenom[0]}${user.nom.split(' ').first[0]}'
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploadingPhoto ? null : _pickPhoto,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: _isUploadingPhoto
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.prenom} ${user.nom}',
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
    user_model.User user,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Informations personnelles',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (!_isEditing)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Modifier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isEditing)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Champ Prénom - ÉDITABLE
                TextField(
                  controller: _prenom,
                  decoration: InputDecoration(
                    labelText: 'Prénom',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),

                // Champ Nom - ÉDITABLE
                TextField(
                  controller: _nom,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),

                // Champ Téléphone - ÉDITABLE
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),

                // Email - NON ÉDITABLE
                _InfoItem(
                  icon: Icons.email,
                  label: 'Email',
                  value: user.email,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // Rôle - NON ÉDITABLE
                _InfoItem(
                  icon: Icons.badge,
                  label: 'Rôle',
                  value: _getRoleLabel(user.role),
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                // Boutons d'action
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              // Réinitialiser les champs
                              _prenom.text = user.prenom;
                              _nom.text = user.nom;
                              _phoneController.text = user.phone;
                              setState(() => _isEditing = false);
                            },
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveUserInfo,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save, size: 16),
                      label: Text(
                          _isSaving ? 'Enregistrement...' : 'Enregistrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoItem(
                  icon: Icons.person,
                  label: 'Prénom',
                  value: user.prenom,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _InfoItem(
                  icon: Icons.person,
                  label: 'Nom',
                  value: user.nom,
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

  Widget _buildLegalSection(BuildContext context, bool isDark) {
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
            'Légal',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.description_outlined,
              color: Colors.blue[600],
            ),
            title: Text(
              'Conditions d\'utilisation',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            subtitle: Text(
              'Consulter les CGU',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showCGUDialog,
          ),
        ],
      ),
    );
  }

  String _getRoleLabel(user_model.UserRole role) {
    switch (role) {
      case user_model.UserRole.admin:
        return 'Administrateur';
      case user_model.UserRole.adherent:
        return 'Adhérent';
      case user_model.UserRole.invite:
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