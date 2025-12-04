import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controllere pentru email și cele două parole
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _inviteCodeController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Funcția pentru înregistrare
  Future<void> signUp() async {
    // Verificăm dacă parolele se potrivesc
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Parolele nu se potrivesc!')));
      return; // Oprim funcția dacă nu se potrivesc
    }

    try {
      // Arată un cerc de încărcare cât timp se creează contul
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Creăm documentele în Firestore
      await _firestoreService.createUserDocument(
        userCredential,
        _nameController.text.trim(),
        _inviteCodeController.text.trim(),
      );

      // Ascundem cercul de încărcare
      Navigator.of(context).pop();

      // Închidem pagina de register (ne întoarcem la Login sau AuthPage ne duce la Home)
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop(); // Ascundem loading-ul la eroare
      // ... afișare eroare ...
    }

    // Încercăm să creăm contul
    try {
      // 1. Prinde datele utilizatorului nou creat
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // --- PASUL NOU ȘI VITAL ---
      // 2. Trimite datele pentru a crea documentul în Firestore
      await _firestoreService.createUserDocument(
        userCredential,
        _nameController.text.trim(),
        _inviteCodeController.text.trim(), // <-- PARAMETRU NOU
      );
      // --- SFÂRȘIT PAS NOU ---

      if (mounted) Navigator.of(context).pop();
      // ... restul ...
    } on FirebaseAuthException catch (e) {
      // Arătăm erori (ex: email deja folosit, parolă prea slabă)
      print('Eroare la înregistrare: ${e.message}');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'A apărut o eroare')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Adăugăm o bară sus pentru a ne putea întoarce
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Creează un cont',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 40),
                // --- CÂMPUL NOU PENTRU NUME ---
                TextField(
                  controller: _nameController,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nume şi Prenume',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.name,
                ),
                SizedBox(height: 20),
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
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  obscureText: !_isPasswordVisible, // <-- Folosește variabila 1
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
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    // --- SFÂRȘIT ---
                  ),
                ),
                SizedBox(height: 20),
                // --- Câmpul pentru Confirmare Parolă ---
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ), // <-- Folosește variabila 2
                  decoration: InputDecoration(
                    hintText: 'Confirmă Parola',
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
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                    // --- SFÂRȘIT ---
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _inviteCodeController,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cod Invitație (Opțional)',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.group_add),
                  ),
                ),
                SizedBox(height: 30),
                // --- Butonul de Înregistrare ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: signUp,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ), // Apelează funcția de înregistrare
                    child: Text('Înregistrează-te'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
