import 'package:expense_tracker_nou/utils/validators.dart';
import 'package:expense_tracker_nou/widgets/password_strength_meter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PersonalProfilePage extends StatefulWidget {
  const PersonalProfilePage({super.key});

  @override
  State<PersonalProfilePage> createState() => _PersonalProfilePageState();
}

class _PersonalProfilePageState extends State<PersonalProfilePage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCurrentVisible = false;
  bool _isNewVisible = false;
  bool _isConfirmVisible = false;
  bool _loadingChange = false;
  bool _loadingReset = false;

  String _newPasswordValue = '';
  String _confirmPasswordValue = '';

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utilizatorul nu este autentificat corect.'),
        ),
      );
      return;
    }

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    var error = Validators.password(currentPassword);
    error ??= Validators.strongPassword(newPassword);
    error ??= Validators.confirmPassword(confirmPassword, newPassword);

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() {
      _loadingChange = true;
    });

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parola a fost schimbată cu succes.')),
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _newPasswordValue = '';
        _confirmPasswordValue = '';
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'A apărut o eroare la schimbarea parolei.';
      if (e.code == 'wrong-password') {
        message = 'Parola curentă este incorectă.';
      } else if (e.code == 'weak-password') {
        message = 'Parola nouă este prea slabă pentru Firebase.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Eroare: $e')));
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingChange = false;
      });
    }
  }

  Future<void> _sendResetEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nu există un email asociat contului.')),
      );
      return;
    }

    setState(() {
      _loadingReset = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Email de resetare a parolei trimis la ${user.email}. '
            'Verifică și folderul Spam / Junk.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'A apărut o eroare la trimiterea emailului.',
          ),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingReset = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool passwordsMatch =
        _newPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _newPasswordController.text == _confirmPasswordController.text;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Valul verde din partea de sus
            Stack(
              children: [
                ClipPath(
                  clipper: _PersonalTopCurveClipper(),
                  child: Container(
                    height: 210,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/fundal.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 50.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(context).maybePop();
                          },
                        ),
                        const Text(
                          'Profil personal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(15),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Securitatea contului',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Actualizează-ți parola pentru a-ți proteja bugetul.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildPasswordField(
                                label: 'Parola curentă',
                                controller: _currentPasswordController,
                                isVisible: _isCurrentVisible,
                                onToggleVisibility: () {
                                  setState(() {
                                    _isCurrentVisible = !_isCurrentVisible;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildPasswordField(
                                label: 'Parolă nouă',
                                controller: _newPasswordController,
                                isVisible: _isNewVisible,
                                onChanged: (value) {
                                  setState(() {
                                    _newPasswordValue = value;
                                  });
                                },
                                onToggleVisibility: () {
                                  setState(() {
                                    _isNewVisible = !_isNewVisible;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              if (_newPasswordValue.isNotEmpty)
                                PasswordStrengthMeter(
                                  password: _newPasswordValue,
                                ),
                              const SizedBox(height: 16),
                              _buildPasswordField(
                                label: 'Confirmă parola nouă',
                                controller: _confirmPasswordController,
                                isVisible: _isConfirmVisible,
                                onChanged: (value) {
                                  setState(() {
                                    _confirmPasswordValue = value;
                                  });
                                },
                                onToggleVisibility: () {
                                  setState(() {
                                    _isConfirmVisible = !_isConfirmVisible;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              if (_confirmPasswordValue.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(
                                      passwordsMatch
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      size: 18,
                                      color: passwordsMatch
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      passwordsMatch
                                          ? 'Parolele se potrivesc'
                                          : 'Parolele nu se potrivesc',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: passwordsMatch
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loadingChange
                                      ? null
                                      : _changePassword,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _loadingChange
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Salvează parola'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 0,
                        color: theme.colorScheme.surfaceVariant.withOpacity(
                          0.6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ai uitat parola?',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Trimite-ți un email de resetare a parolei. '
                                'Dacă nu găsești mesajul, verifică și folderul Spam.',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _loadingReset
                                      ? null
                                      : _sendResetEmail,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    side: BorderSide(
                                      color: theme.colorScheme.primary,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _loadingReset
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Trimite email de resetare'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    ValueChanged<String>? onChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          obscureText: !isVisible,
          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: theme.scaffoldBackgroundColor,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            suffixIcon: IconButton(
              icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: onToggleVisibility,
            ),
          ),
        ),
      ],
    );
  }
}

class _PersonalTopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
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
