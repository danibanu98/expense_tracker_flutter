import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker_nou/ui/register_page.dart';

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

  // 2. O funcție pentru a gestiona apăsarea butonului de Login
  Future<void> signIn() async {
    try {
      // 3. Folosim Firebase Auth pentru a face login
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Nu e nevoie să facem nimic după login.
      // "Dispecerul" nostru (AuthPage) va vedea automat
      // schimbarea și ne va trimite la HomePage!
    } on FirebaseAuthException catch (e) {
      // 4. Dacă apare o eroare (ex: parolă greșită), arătăm o alertă
      print('Eroare la login: ${e.message}');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'A apărut o eroare')));
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
      backgroundColor: Colors.grey[200], // Un fundal gri deschis
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
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: Colors.white,
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
                  decoration: InputDecoration(
                    hintText: 'Parolă',
                    filled: true,
                    fillColor: Colors.white,
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
