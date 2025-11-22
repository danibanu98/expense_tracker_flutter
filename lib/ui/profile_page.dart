import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker_nou/theme/theme.dart'; // Importăm culorile noastre (darkGreen, accentGreen)
import 'package:expense_tracker_nou/ui/settings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Pentru DocumentSnapshot
import 'package:expense_tracker_nou/services/firestore_service.dart'; // Pentru serviciu
import 'package:flutter/services.dart'; // Pentru copiere în clipboard

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Funcția de Logout
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Obține serviciul și utilizatorul curent
    final FirestoreService firestoreService = FirestoreService();
    final user = FirebaseAuth.instance.currentUser;

    // 2. StreamBuilder principal: Ascultă documentul 'users'
    return StreamBuilder<DocumentSnapshot>(
      stream: firestoreService.users.doc(user?.uid).snapshots(),
      builder: (context, userSnapshot) {
        // Cazul 1: Se încarcă datele utilizatorului
        if (!userSnapshot.hasData ||
            userSnapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: accentGreen, // Păstrăm fundalul verde
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        // Cazul 2: Avem datele utilizatorului
        String userName = 'Utilizator';
        String householdId = '';
        if (userSnapshot.data!.exists) {
          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          userName = userData['name'] ?? 'Utilizator';
          householdId = userData['householdId'] ?? '';
        }

        final String initial = userName.substring(0, 1).toUpperCase();

        // Construim interfața (codul tău vechi, ușor modificat)
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/fundal.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 30),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    userName, // <-- Acum e numele real
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    user?.email ?? '', // Email-ul sub nume
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 30),

                  // --- 3. LISTA DE OPȚIUNI (MODIFICATĂ) ---
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: ListView(
                        padding: EdgeInsets.all(20),
                        children: [
                          // --- CARDUL DE INVITAȚIE (NOU) ---
                          _buildInviteCard(
                            context,
                            firestoreService,
                            householdId,
                          ),
                          SizedBox(height: 20),

                          // Restul opțiunilor
                          _buildProfileOption(
                            icon: Icons.person,
                            title: 'Profil Personal',
                            onTap: () {},
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
                                  builder: (context) => SettingsPage(),
                                ),
                              );
                            },
                          ),
                          Divider(color: Colors.grey[800], height: 30),
                          _buildProfileOption(
                            icon: Icons.logout,
                            title: 'Deconectare',
                            iconColor: Colors.red[400]!,
                            onTap: signOut,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- FUNCȚIE HELPER PENTRU A CONSTRUI OPȚIUNILE ---
  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor, // Am redenumit în 'iconColor' și l-am făcut opțional
  }) {
    return ListTile(
      // Culoarea iconiței va fi culoarea primară a temei, dacă nu specificăm alta
      leading: Icon(icon, color: iconColor),
      // Textul va prelua automat culoarea corectă (alb/negru) de la temă
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
      onTap: onTap,
    );
  }

  // --- FUNCȚIE NOUĂ PENTRU CARDUL DE INVITAȚIE ---
  Widget _buildInviteCard(
    BuildContext context,
    FirestoreService firestoreService,
    String householdId,
  ) {
    // Dacă utilizatorul nu are o gospodărie (eroare), nu arăta cardul
    if (householdId.isEmpty) {
      return SizedBox.shrink();
    }

    // StreamBuilder "Nested" (Ascultă documentul 'households')
    return StreamBuilder<DocumentSnapshot>(
      stream: firestoreService.households.doc(householdId).snapshots(),
      builder: (context, householdSnapshot) {
        if (!householdSnapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        String inviteCode = '...';
        String householdName = 'Gospodărie';
        if (householdSnapshot.data!.exists) {
          var householdData =
              householdSnapshot.data!.data() as Map<String, dynamic>;
          inviteCode = householdData['inviteCode'] ?? 'EROARE';
          householdName = householdData['name'] ?? 'Gospodărie';
        }

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bine ai venit în: $householdName',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color.fromARGB(255, 114, 114, 114),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'CODUL TĂU DE INVITAȚIE:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Codul
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      inviteCode,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2, // Spațiu între litere
                      ),
                    ),
                  ),
                  // Butonul de copiere
                  IconButton(
                    icon: Icon(
                      Icons.copy,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      // Copiază în clipboard
                      Clipboard.setData(ClipboardData(text: inviteCode));
                      // Arată o confirmare
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Codul "$inviteCode" a fost copiat!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
