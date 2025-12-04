import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker_nou/theme/theme.dart';
import 'package:expense_tracker_nou/ui/settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestoreService.users.doc(user?.uid).snapshots(),
      builder: (context, userSnapshot) {
        // OPTIMISTIC UI: Loading doar dacă nu sunt date
        if (!userSnapshot.hasData) {
          return Container(
            color: accentGreen,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        String userName = 'Utilizator';
        String householdId = '';
        if (userSnapshot.data!.exists) {
          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          userName = userData['name'] ?? 'Utilizator';
          householdId = userData['householdId'] ?? '';
        }

        String initial = 'U';
        if (userName.isNotEmpty) {
          initial = userName.substring(0, 1).toUpperCase();
        }

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
                    userName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 30),

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
                          _buildInviteCard(
                            context,
                            _firestoreService,
                            householdId,
                          ),
                          SizedBox(height: 20),

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

  Widget _buildInviteCard(
    BuildContext context,
    FirestoreService firestoreService,
    String householdId,
  ) {
    if (householdId.isEmpty) return SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: firestoreService.households.doc(householdId).snapshots(),
      builder: (context, householdSnapshot) {
        // OPTIMISTIC UI: Afișăm dacă avem date
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
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gospodăria ta: $householdName',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        inviteCode,
                        style: TextStyle(
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
                          SnackBar(content: Text('Codul a fost copiat!')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        return Center(child: CircularProgressIndicator());
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
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
      onTap: onTap,
    );
  }
}
