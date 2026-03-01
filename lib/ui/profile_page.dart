import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/services/biometric_service.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:expense_tracker_nou/theme/theme.dart';
import 'package:expense_tracker_nou/ui/personal_profile_page.dart';
import 'package:expense_tracker_nou/ui/settings_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isUploading = false;
  bool _supportsBiometrics = false;
  bool _biometricsEnabled = false;
  final _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _loadBiometricsState();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _loadBiometricsState() async {
    try {
      final supported = await _biometricService.isDeviceSupported();
      final enabled =
          supported && await _biometricService.getBiometricsEnabled();
      if (!mounted) return;
      setState(() {
        _supportsBiometrics = supported;
        _biometricsEnabled = enabled;
      });
    } catch (e) {
      debugPrint('Error loading biometrics state: $e');
    }
  }

  Future<void> _onBiometricsChanged(bool value) async {
    if (value) {
      final success = await _biometricService.enableBiometricsWithCheck(
        context,
      );
      if (!mounted) return;
      setState(() {
        _biometricsEnabled = success;
      });
      return;
    } else {
      await _biometricService.setBiometricsEnabled(false);
      if (!mounted) return;
      setState(() {
        _biometricsEnabled = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      final file = File(pickedFile.path);
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_pictures/${user.uid}.jpg',
      );

      final uploadTask = storageRef.putFile(file, metadata);
      final snapshot = await uploadTask.whenComplete(() => null);

      if (snapshot.state != TaskState.success) {
        throw Exception('Upload task failed with state: ${snapshot.state}');
      }

      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'photoUrl': downloadUrl},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poză de profil actualizată cu succes!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      if (mounted) {
        final String message;
        if (e.toString().contains('object-not-found') ||
            e.toString().contains('firebase_storage/object-not-found')) {
          message =
              'Storage neactivat. Activează Firebase Storage din Consola Firebase (Storage → Upgrade project) sau verifică regulile de securitate.';
        } else {
          message = 'Eroare la adăugarea imaginii: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      debugPrint('Profile image upload error: $e\n$stackTrace');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestoreService.users.doc(user?.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return Container(
              color: accentGreen,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          String userName = 'Utilizator';
          String userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
          String householdId = '';
          String? photoUrl;

          if (userSnapshot.data!.exists) {
            var userData = userSnapshot.data!.data() as Map<String, dynamic>;
            userName = userData['name'] ?? 'Utilizator';
            householdId = userData['householdId'] ?? '';
            photoUrl = userData['photoUrl'];
          }

          String initial = userName.isNotEmpty
              ? userName.substring(0, 1).toUpperCase()
              : 'U';

          return Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // Background arch
                  ClipPath(
                    clipper: _TopCurveClipper(),
                    child: Container(
                      height: 210,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/fundal.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 30.0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Profil',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 48), // Spacer
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Avatar intersecting the curve exactly
                  Positioned(
                    bottom: -10, // Moves avatar down by half its radius
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: Theme.of(
                            context,
                          ).scaffoldBackgroundColor,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xff2f7e79),
                            backgroundImage: photoUrl != null
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null
                                ? Text(
                                    initial,
                                    style: const TextStyle(
                                      fontSize: 40,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        if (_isUploading)
                          const Positioned(
                            right: 0,
                            bottom: 0,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.white,
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        else
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xff2f7e79),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Spacer below avatar
              Text(
                userName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.black87,
                ),
              ),
              if (userEmail.isNotEmpty)
                Text(
                  userEmail,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xff2f7e79),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 30),

              // Profile Options List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildInviteCard(
                          context,
                          firestoreService,
                          householdId,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildProfileOption(
                        icon: Icons.person,
                        title: 'Profil Personal',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PersonalProfilePage(),
                            ),
                          );
                        },
                      ),
                      _buildProfileOption(
                        icon: Icons.account_balance,
                        title: 'Informații Cont',
                        onTap: () {},
                      ),
                      _buildProfileOption(
                        icon: Icons.settings,
                        title: 'Setări',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsPage(),
                            ),
                          );
                        },
                      ),
                      if (_supportsBiometrics)
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          secondary: const Icon(Icons.fingerprint),
                          title: const Text('Autentificare biometrică'),
                          subtitle: const Text(
                            'Cere amprentă când deschizi aplicația',
                          ),
                          value: _biometricsEnabled,
                          onChanged: _onBiometricsChanged,
                        ),
                      Divider(
                        color: Colors.grey[800],
                        height: 30,
                        indent: 20,
                        endIndent: 20,
                      ),
                      _buildProfileOption(
                        icon: Icons.logout,
                        title: 'Deconectare',
                        iconColor: const Color(0xff7b0828),
                        onTap: signOut,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInviteCard(
    BuildContext context,
    FirestoreService firestoreService,
    String householdId,
  ) {
    if (householdId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: firestoreService.households.doc(householdId).snapshots(),
      builder: (context, householdSnapshot) {
        if (householdSnapshot.hasData) {
          String inviteCode = '...';
          String householdName = 'Gospodărie';
          if (householdSnapshot.data!.exists) {
            var householdData =
                householdSnapshot.data!.data() as Map<String, dynamic>;
            inviteCode = householdData['inviteCode'] ?? 'EROARE';
            householdName = householdData['name'] ?? 'Gospodărie';
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 5),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bine ai venit în $householdName',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),
                const Text(
                  'CODUL TĂU DE INVITAȚIE:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        inviteCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.copy,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Codul a fost copiat!')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
      onTap: onTap,
    );
  }
}

class _TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 80,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
