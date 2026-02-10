import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker_nou/ui/register_page.dart';
import 'package:expense_tracker_nou/utils/validators.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1. "Controllere" pentru a citi textul din câmpuri
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false; // Implicit, parola e ascunsă

  Future<void> signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final emailError = Validators.email(email);
    if (emailError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emailError)),
      );
      return;
    }
    final passwordError = Validators.password(password);
    if (passwordError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passwordError)),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'A apărut o eroare')),
      );
    }
  }

  // 5. Ne asigurăm că eliberăm controllerele când ecranul e închis
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Aici construim interfața (UI) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // Permite scroll dacă nu încape pe ecran
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Un text de salut
                Text(
                  'Bine ai venit!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 40),

                // --- Câmpul pentru Email ---
                TextField(
                  controller: _emailController,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20),

                // --- Câmpul pentru Parolă ---
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible, // <-- Folosește variabila
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Parolă',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    // --- BUTONUL "OCHI" ADĂUGAT AICI ---
                    suffixIcon: IconButton(
                      icon: Icon(
                        // Schimbă iconița în funcție de stare
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        // Schimbă starea la apăsare
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    // --- SFÂRȘIT ---
                  ),
                ),
                SizedBox(height: 30),

                // --- Butonul de Login ---
                SizedBox(
                  width: double.infinity, // Ocupă toată lățimea
                  child: ElevatedButton(
                    onPressed: signIn,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ), // Apelează funcția de login
                    child: Text('Login'),
                  ),
                ),
                SizedBox(height: 20), // Adaugă un spațiu
                // --- Butonul de Înregistrare ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Nu ai cont?'),
                    TextButton(
                      onPressed: () {
                        // Navigăm la pagina de înregistrare
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Înregistrează-te',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                // Vom adăuga butonul de "Înregistrare" mai târziu
              ],
            ),
          ),
        ),
      ),
    );
  }
}
