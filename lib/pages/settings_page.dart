// pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
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

  // Contrôleurs pour les informations professionnelles
  late TextEditingController _companyNameController;
  late TextEditingController _skillsController;
  late TextEditingController _professionalAddressController;
  late TextEditingController _websiteController;

  // Contrôleurs pour les champs personnels supplémentaires
  late TextEditingController _passionsController;
  DateTime? _memberSince;

  bool _isEditing = false;
  bool _isEditingPro = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  XFile? _selectedPhoto;
  final CGUService _cguService = CGUService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _user = widget.user;

    _prenom = TextEditingController(text: _user.prenom);
    _nom = TextEditingController(text: _user.nom);
    _phoneController = TextEditingController(text: _user.phone);

    _companyNameController = TextEditingController(text: _user.companyName ?? '');
    _skillsController = TextEditingController(text: _user.skills ?? '');
    _professionalAddressController = TextEditingController(text: _user.professionalAddress ?? '');
    _websiteController = TextEditingController(text: _user.website ?? '');
    _passionsController = TextEditingController(text: _user.passions ?? '');
    _memberSince = _user.memberSince;

    // Charger les données les plus récentes depuis Supabase
    _loadUserData();
  }

  /// Charge les données de l'utilisateur depuis Supabase
  Future<void> _loadUserData() async {
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', _user.uid)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _user.prenom = data['prenom'] ?? '';
          _user.nom = data['nom'] ?? '';
          _user.phone = data['phone'] ?? '';
          _user.companyName = data['company_name'] ?? '';
          _user.skills = data['skills'] ?? '';
          _user.professionalAddress = data['professional_address'] ?? '';
          _user.website = data['website'] ?? '';
          _user.shareProInfo = data['share_pro_info'] ?? false;
          _user.passions = data['passions'] as String?;
          _user.memberSince = data['member_since'] != null
              ? DateTime.tryParse(data['member_since'] as String)
              : null;

          // Mettre à jour les contrôleurs aussi
          _prenom.text = _user.prenom;
          _nom.text = _user.nom;
          _phoneController.text = _user.phone;
          _companyNameController.text = _user.companyName ?? '';
          _skillsController.text = _user.skills ?? '';
          _professionalAddressController.text = _user.professionalAddress ?? '';
          _websiteController.text = _user.website ?? '';
          _passionsController.text = _user.passions ?? '';
          _memberSince = _user.memberSince;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur lors du chargement des données: $e');
    }
  }

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _skillsController.dispose();
    _professionalAddressController.dispose();
    _websiteController.dispose();
    _passionsController.dispose();
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
        setState(() => _selectedPhoto = pickedFile);
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
      final bytes = await _selectedPhoto!.readAsBytes();

      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(fileName, bytes);

      final photoUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      // Mettre à jour Supabase
      await Supabase.instance.client
          .from('users')
          .update({'photo_url': photoUrl})
          .eq('id', _user.uid);

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
      await Supabase.instance.client
          .from('users')
          .update({
            'prenom': _prenom.text.trim(),
            'nom': _nom.text.trim(),
            'phone': _phoneController.text.trim(),
            'member_since': _memberSince?.toIso8601String().substring(0, 10),
            'passions': _passionsController.text.trim().isEmpty
                ? null
                : _passionsController.text.trim(),
          })
          .eq('id', _user.uid);

      // Mettre à jour l'objet _user
      _user.prenom = _prenom.text.trim();
      _user.nom = _nom.text.trim();
      _user.phone = _phoneController.text.trim();
      _user.memberSince = _memberSince;
      _user.passions = _passionsController.text.trim().isEmpty
          ? null
          : _passionsController.text.trim();

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

  Future<void> _saveProfessionalInfo() async {
    setState(() => _isSaving = true);

    try {
      await Supabase.instance.client
          .from('users')
          .update({
            'company_name': _companyNameController.text.trim(),
            'skills': _skillsController.text.trim(),
            'professional_address': _professionalAddressController.text.trim(),
            'website': _websiteController.text.trim(),
            'share_pro_info': _user.shareProInfo ?? false,
          })
          .eq('id', _user.uid);

      // Mettre à jour l'objet _user
      _user.companyName = _companyNameController.text.trim();
      _user.skills = _skillsController.text.trim();
      _user.professionalAddress = _professionalAddressController.text.trim();
      _user.website = _websiteController.text.trim();

      setState(() {
        _isEditingPro = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Informations professionnelles mises à jour'),
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

  Future<void> _toggleShareProInfo() async {
    final newValue = !(_user.shareProInfo ?? false);

    try {
      await Supabase.instance.client
          .from('users')
          .update({'share_pro_info': newValue})
          .eq('id', _user.uid);

      setState(() {
        _user.shareProInfo = newValue;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newValue
                ? '✅ Informations professionnelles partagées'
                : '✅ Informations professionnelles masquées'),
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

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentPwdCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    final confirmPwdCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? errorMessage;
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final isDark =
              Theme.of(dialogContext).brightness == Brightness.dark;

          Future<void> submit() async {
            final currentPwd = currentPwdCtrl.text.trim();
            final newPwd = newPwdCtrl.text.trim();
            final confirmPwd = confirmPwdCtrl.text.trim();
            final messenger = ScaffoldMessenger.of(context);

            if (currentPwd.isEmpty || newPwd.isEmpty || confirmPwd.isEmpty) {
              setDialogState(
                  () => errorMessage = 'Veuillez remplir tous les champs.');
              return;
            }
            if (newPwd.length < 6) {
              setDialogState(() => errorMessage =
                  'Le nouveau mot de passe doit contenir au moins 6 caractères.');
              return;
            }
            if (newPwd != confirmPwd) {
              setDialogState(() =>
                  errorMessage = 'Les mots de passe ne correspondent pas.');
              return;
            }

            setDialogState(() {
              isLoading = true;
              errorMessage = null;
            });

            try {
              final supabaseUser =
                  Supabase.instance.client.auth.currentUser;
              if (supabaseUser == null || supabaseUser.email == null) {
                throw 'Utilisateur non connecté.';
              }

              // Ré-authentification obligatoire avant changement de mot de passe
              await Supabase.instance.client.auth.signInWithPassword(
                email: supabaseUser.email!,
                password: currentPwd,
              );

              // Mise à jour du mot de passe
              await Supabase.instance.client.auth.updateUser(
                UserAttributes(password: newPwd),
              );

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Mot de passe modifié avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } on AuthException catch (e) {
              String msg;
              switch (e.message) {
                case 'Invalid login credentials':
                case 'invalid_credentials':
                  msg = 'Mot de passe actuel incorrect.';
                  break;
                case 'Password should be at least 6 characters':
                  msg = 'Le nouveau mot de passe est trop faible.';
                  break;
                case 'Email rate limit exceeded':
                  msg = 'Trop de tentatives. Réessayez plus tard.';
                  break;
                default:
                  msg = 'Erreur : ${e.message}';
              }
              setDialogState(() => errorMessage = msg);
            } catch (e) {
              setDialogState(() => errorMessage = 'Erreur : $e');
            } finally {
              setDialogState(() => isLoading = false);
            }
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.lock_outline, size: 22),
                SizedBox(width: 10),
                Text('Modifier le mot de passe'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mot de passe actuel
                  TextField(
                    controller: currentPwdCtrl,
                    obscureText: obscureCurrent,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe actuel',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setDialogState(
                            () => obscureCurrent = !obscureCurrent),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor:
                          isDark ? Colors.grey[800] : Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Nouveau mot de passe
                  TextField(
                    controller: newPwdCtrl,
                    obscureText: obscureNew,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setDialogState(() => obscureNew = !obscureNew),
                      ),
                      helperText: 'Minimum 6 caractères',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor:
                          isDark ? Colors.grey[800] : Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Confirmation
                  TextField(
                    controller: confirmPwdCtrl,
                    obscureText: obscureConfirm,
                    enabled: !isLoading,
                    onSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      labelText: 'Confirmer le nouveau mot de passe',
                      prefixIcon: const Icon(Icons.lock_clock),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setDialogState(
                            () => obscureConfirm = !obscureConfirm),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor:
                          isDark ? Colors.grey[800] : Colors.grey[50],
                    ),
                  ),
                  // Message d'erreur
                  if (errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                  if (isLoading) ...[
                    const SizedBox(height: 14),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isLoading ? null : () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: Theme.of(dialogContext).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor:
                      Theme.of(dialogContext).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                ),
                child: const Text('Modifier'),
              ),
            ],
          );
        },
      ),
    );

    currentPwdCtrl.dispose();
    newPwdCtrl.dispose();
    confirmPwdCtrl.dispose();
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

              // Section Informations Professionnelles (nouvelles)
              // Disponible pour les adhérents ET les admins
              if (_user.role == user_model.UserRole.adherent ||
                  _user.role == user_model.UserRole.admin)
                ...[
                  _buildProfessionalInfoSection(context, _user, isDark),
                  const SizedBox(height: 32),
                ],

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
                  Colors.blue[900]!.withValues(alpha: 0.3),
                  Colors.purple[900]!.withValues(alpha: 0.3),
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
        color: isDark ? Colors.grey[900]?.withValues(alpha: 0.5) : Colors.grey[100],
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
                  label: const Text(
                    'Modifier',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
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

                // Date de première adhésion - ÉDITABLE
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _memberSince ?? DateTime.now(),
                      firstDate: DateTime(1990),
                      lastDate: DateTime.now(),
                      helpText: 'Date de première adhésion',
                      cancelText: 'Annuler',
                      confirmText: 'Confirmer',
                    );
                    if (picked != null) setState(() => _memberSince = picked);
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Date de première adhésion',
                        prefixIcon: const Icon(Icons.calendar_today),
                        hintText: 'Sélectionner une date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                      ),
                      controller: TextEditingController(
                        text: _memberSince != null
                            ? '${_memberSince!.day.toString().padLeft(2, '0')}/${_memberSince!.month.toString().padLeft(2, '0')}/${_memberSince!.year}'
                            : '',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Passions - ÉDITABLE
                TextField(
                  controller: _passionsController,
                  decoration: InputDecoration(
                    labelText: 'Passions / Centres d\'intérêt',
                    prefixIcon: const Icon(Icons.favorite_outline),
                    hintText: 'ex: Randonnée, Lecture, Photographie...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                  ),
                  maxLines: 3,
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
                              _memberSince = user.memberSince;
                              _passionsController.text = user.passions ?? '';
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
                        _isSaving ? 'Enregistrement...' : 'Enregistrer',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
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
                if (user.memberSince != null) ...[
                  const SizedBox(height: 16),
                  _InfoItem(
                    icon: Icons.calendar_today,
                    label: 'Membre depuis',
                    value: '${user.memberSince!.day.toString().padLeft(2, '0')}/${user.memberSince!.month.toString().padLeft(2, '0')}/${user.memberSince!.year}',
                    isDark: isDark,
                  ),
                ],
                if ((user.passions ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _InfoItem(
                    icon: Icons.favorite_outline,
                    label: 'Passions',
                    value: user.passions!,
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

  Widget _buildProfessionalInfoSection(
    BuildContext context,
    user_model.User user,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900]?.withValues(alpha: 0.5) : Colors.grey[100],
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
                'Informations professionnelles',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (!_isEditingPro)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _isEditingPro = true),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text(
                    'Modifier',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Toggle pour partager les infos pro
          if (!_isEditingPro)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Partager vos informations',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Visibles dans l\'annuaire',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _user.shareProInfo ?? false,
                    onChanged: (_) => _toggleShareProInfo(),
                  ),
                ],
              ),
            ),

          if (_isEditingPro)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom de l'entreprise
                TextField(
                  controller: _companyNameController,
                  decoration: InputDecoration(
                    labelText: 'Entreprise / Organisation',
                    prefixIcon: const Icon(Icons.business),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),

                // Coctivités / Compétences
                TextField(
                  controller: _skillsController,
                  decoration: InputDecoration(
                    labelText: 'Activités / Compétences',
                    prefixIcon: const Icon(Icons.lightbulb),
                    hintText: 'ex: Gestion, Marketing, Développement...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Adresse professionnelle
                TextField(
                  controller: _professionalAddressController,
                  decoration: InputDecoration(
                    labelText: 'Adresse professionnelle',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),

                // Site web
                TextField(
                  controller: _websiteController,
                  decoration: InputDecoration(
                    labelText: 'Site web / Portfolio',
                    prefixIcon: const Icon(Icons.language),
                    hintText: 'https://...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                  ),
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
                              _companyNameController.text = user.companyName ?? '';
                              _skillsController.text = user.skills ?? '';
                              _professionalAddressController.text = user.professionalAddress ?? '';
                              _websiteController.text = user.website ?? '';
                              setState(() => _isEditingPro = false);
                            },
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveProfessionalInfo,
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
                        _isSaving ? 'Enregistrement...' : 'Enregistrer',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
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
                if ((user.companyName ?? '').isNotEmpty) ...[
                  _InfoItem(
                    icon: Icons.business,
                    label: 'Entreprise',
                    value: user.companyName!,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                ],
                if ((user.skills ?? '').isNotEmpty) ...[
                  _InfoItem(
                    icon: Icons.lightbulb,
                    label: 'Activités / Compétences',
                    value: user.skills!,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                ],
                if ((user.professionalAddress ?? '').isNotEmpty) ...[
                  _InfoItem(
                    icon: Icons.location_on,
                    label: 'Adresse',
                    value: user.professionalAddress!,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                ],
                if ((user.website ?? '').isNotEmpty) ...[
                  _InfoItem(
                    icon: Icons.language,
                    label: 'Site web',
                    value: user.website!,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                ],
                if ((user.companyName ?? '').isEmpty &&
                    (user.skills ?? '').isEmpty &&
                    (user.professionalAddress ?? '').isEmpty &&
                    (user.website ?? '').isEmpty)
                  Text(
                    'Aucune information professionnelle renseignée',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
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
        color: isDark ? Colors.grey[900]?.withValues(alpha: 0.5) : Colors.grey[100],
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
            onTap: () => _showChangePasswordDialog(context),
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
        color: isDark ? Colors.grey[900]?.withValues(alpha: 0.5) : Colors.grey[100],
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
