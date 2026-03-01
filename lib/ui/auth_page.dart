import 'package:expense_tracker_nou/services/biometric_service.dart';
import 'package:expense_tracker_nou/ui/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker_nou/ui/login_page.dart';

class AuthPage extends StatelessWidget {
  final int lastTabIndex;
  const AuthPage({super.key, required this.lastTabIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        // 1. Aici e magia: ne abonăm la starea de autentificare
        stream: FirebaseAuth.instance.authStateChanges(),

        builder: (context, snapshot) {
          // 2. Încă se verifică? Arată un cerc de încărcare
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // 3. Utilizatorul ESTE logat?
          // (Firebase ne-a trimis un obiect 'User')
          if (snapshot.hasData) {
            // Utilizator logat: verificăm dacă trebuie să ceară autentificare biometrică.
            return _BiometricGate(lastTabIndex: lastTabIndex);
          }
          // 4. Utilizatorul NU este logat?
          // (Firebase ne-a trimis 'null')
          else {
            // Trimite-l la pagina de login
            return LoginPage();
          }
        },
      ),
    );
  }
}

class _BiometricGate extends StatefulWidget {
  final int lastTabIndex;
  const _BiometricGate({required this.lastTabIndex});

  @override
  State<_BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<_BiometricGate> {
  final _biometricService = BiometricService();
  bool _loading = true;
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final enabled = await _biometricService.getBiometricsEnabled();
    final supported = await _biometricService.isDeviceSupported();

    bool allowed = true;
    if (enabled && supported) {
      allowed = await _biometricService.authenticate(
        context: context,
        showErrors: true,
      );
    }

    if (!mounted) return;
    setState(() {
      _allowed = allowed;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_allowed) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Autentificarea biometrică a eșuat.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkBiometrics,
                child: const Text('Încearcă din nou'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text('Deconectează-te'),
              ),
            ],
          ),
        ),
      );
    }

    return MainScreen(lastTabIndex: widget.lastTabIndex);
  }
}

