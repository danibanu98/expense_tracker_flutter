import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker_nou/ui/login_page.dart';
import 'package:expense_tracker_nou/ui/main_screen.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

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
            // Trimite-l la ecranul principal CU MENIU
            return MainScreen();
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
