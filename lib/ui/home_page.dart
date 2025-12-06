import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';
import 'package:expense_tracker_nou/ui/transaction_details_page.dart';
import 'package:expense_tracker_nou/ui/all_transactions_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onSeeAllPressed;
  const HomePage({super.key, required this.onSeeAllPressed});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService _firestoreService = FirestoreService();

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Alimente & Băuturi':
        return Icons.restaurant;
      case 'Cumpărături':
        return Icons.shopping_bag;
      case 'Locuinţă':
        return Icons.home;
      case 'Transport':
        return Icons.car_rental;
      case 'Maşină':
        return Icons.directions_car;
      case 'Viaţă & Divertisment':
        return Icons.sports_esports;
      case 'Hardware PC':
        return Icons.computer;
      case 'Cheltuieli financiare':
        return Icons.payments;
      case 'Investiţii':
        return Icons.attach_money;
      case 'Salariu':
        return Icons.work;
      case 'Cadou':
        return Icons.cake;
      case 'Bonus':
        return Icons.card_giftcard;
      case 'Altele':
        return Icons.clear_all_rounded;
      default:
        return Icons.money;
    }
  }

  String _getGreeting() {
    final int currentHour = DateTime.now().hour;
    if (currentHour >= 5 && currentHour < 12) {
      return 'Bună dimineața,';
    } else if (currentHour >= 12 && currentHour < 18) {
      return 'Bună ziua,';
    } else {
      return 'Bună seara,';
    }
  }

  Widget _buildTransactionLeading(Map<String, dynamic> data, bool isExpense) {
    String description = (data['description'] ?? '').toLowerCase();
    String category = data['category'] ?? 'Altele';

    // Logica pentru Brand-uri
    if (description.contains('netflix')) {
      return CircleAvatar(
        backgroundColor: Colors.white,
        child: Image.asset('assets/images/netflix.png', width: 28, height: 28),
      );
    }
    if (description.contains('asigurare ale')) {
      return CircleAvatar(
        backgroundColor: Colors.white,
        child: Image.asset('assets/images/nn.png', width: 28, height: 28),
      );
    }
    if (description.contains('youtube')) {
      return CircleAvatar(
        backgroundColor: Colors.white,
        child: Image.asset('assets/images/youtube.png', width: 28, height: 28),
      );
    }
    if (description.contains('rata bt')) {
      return CircleAvatar(
        backgroundColor: Colors.white,
        child: Image.asset('assets/images/bt.png', width: 28, height: 28),
      );
    }
    if (description.contains('orange')) {
      return CircleAvatar(
        backgroundColor: Colors.white,
        child: Image.asset('assets/images/orange.png', width: 28, height: 28),
      );
    }
    if (description.contains('digi')) {
      return CircleAvatar(
        backgroundColor: Colors.white,
        child: Image.asset('assets/images/digi.png', width: 28, height: 28),
      );
    }
    if (description.contains('curent ppc')) {
      return CircleAvatar(
        backgroundColor: Colors.white,
        child: Image.asset('assets/images/enel.png', width: 28, height: 28),
      );
    }
    if (description.contains('eon')) {
      return CircleAvatar(
        backgroundColor: Colors.white,
        child: Image.asset('assets/images/eon.png', width: 28, height: 28),
      );
    }
    if (description.contains('revolut')) {
      return CircleAvatar(
        backgroundColor: Colors.white,
        child: Image.asset('assets/images/revolut.png', width: 28, height: 28),
      );
    }
    if (description.contains('lidl')) {
      return CircleAvatar(
        backgroundColor: Colors.white,
        child: Image.asset('assets/images/lidl.png', width: 28, height: 28),
      );
    }
    if (description.contains('starbucks')) {
      return CircleAvatar(
        backgroundColor: Colors.white,
        child: Image.asset('assets/images/starbucks.png', width: 28, height: 28),
      );
    }

    return CircleAvatar(
      backgroundColor: isExpense
          ? const Color(0xff7b0828).withValues(alpha: 0.1)
          : const Color(0xff2f7e79).withValues(alpha: 0.1),
      child: Icon(
        _getIconForCategory(category),
        color: isExpense ? const Color(0xff7b0828) : const Color(0xff2f7e79),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.users.doc(user?.uid).snapshots(),
        builder: (context, userSnapshot) {
          // FIX CACHE 1: Verificăm doar dacă avem date. Dacă avem (chiar și din cache), afișăm.
          if (!userSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          String userName = 'Utilizator';
          if (userSnapshot.data!.exists) {
            var userData = userSnapshot.data!.data() as Map<String, dynamic>;
            userName = userData['name'] ?? userName;
          }
          String greeting = _getGreeting();

          return Stack(
            children: [
              ClipPath(
                clipper: _TopCurveClipper(),
                child: Container(
                  height: 350,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/fundal.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                greeting,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              Text(
                                userName,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Icons.light_mode
                                      : Icons.dark_mode,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  final settings =
                                      Provider.of<SettingsProvider>(
                                        context,
                                        listen: false,
                                      );
                                  if (Theme.of(context).brightness ==
                                      Brightness.dark) {
                                    settings.updateTheme(ThemeMode.light);
                                  } else {
                                    settings.updateTheme(ThemeMode.dark);
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.notifications,
                                  color: Colors.white,
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildSummaryCard(settings),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Istoric Tranzacții',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AllTransactionsPage(),
                                ),
                              );
                            },
                            child: Text('Vezi Tot'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestoreService.getExpensesStream(),
                        builder: (context, snapshot) {
                          // FIX 2: Gestionăm erorile mai întâi
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'A apărut o eroare: ${snapshot.error}',
                              ),
                            );
                          }
                          // FIX 3: Afișăm loading doar dacă NU avem date deloc
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Text('Nicio tranzacție adăugată'),
                            );
                          }

                          var expenses = snapshot.data!.docs;

                          return ListView.builder(
                            itemCount: expenses.length,
                            itemBuilder: (context, index) {
                              var expense = expenses[index];
                              var data = expense.data() as Map<String, dynamic>;
                              String description = data['description'] ?? 'N/A';
                              double amount = (data['amount'] ?? 0.0)
                                  .toDouble();
                              String type = data['type'] ?? 'expense';
                              bool isExpense = type == 'expense';
                              String expenseOwnerUid = data['uid'] ?? '';
                              String currentUserUid =
                                  FirebaseAuth.instance.currentUser?.uid ?? '';
                              bool isMyExpense =
                                  expenseOwnerUid == currentUserUid;

                              return Dismissible(
                                key: Key(expense.id),
                                onDismissed: (direction) {
                                  _firestoreService.deleteExpense(expense.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '$description a fost șters',
                                      ),
                                    ),
                                  );
                                },
                                background: Container(
                                  color: const Color(0xff7b0828),
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                child: ListTile(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TransactionDetailsPage(
                                              data: data,
                                              transactionId: expense.id,
                                            ),
                                      ),
                                    );
                                  },
                                  leading: _buildTransactionLeading(
                                    data,
                                    isExpense,
                                  ),
                                  title: Text(description),
                                  subtitle: Text(
                                    "${data['category'] ?? 'Fără categorie'} • ${isMyExpense ? 'Tu' : 'Soția'}",
                                  ),
                                  trailing: Text(
                                    '${isExpense ? '-' : '+'}${settings.currencySymbol}${amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: isExpense
                                          ? const Color(0xff7b0828)
                                          : const Color(0xff2f7e79),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(SettingsProvider settings) {
    return Card(
      margin: EdgeInsets.all(16.0),
      elevation: 0,
      color: const Color(0xff2f7e79).withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suma Totală',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getAccountsStream(),
              builder: (context, snapshot) {
                // FIX 4: La fel și aici, arată datele dacă există
                if (!snapshot.hasData) {
                  return CircularProgressIndicator(color: Colors.white);
                }

                double totalBalance = 0;
                for (var doc in snapshot.data!.docs) {
                  totalBalance +=
                      (doc.data() as Map<String, dynamic>)['balance'] ?? 0.0;
                }
                return Text(
                  '${settings.currencySymbol}${totalBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              },
            ),
            SizedBox(height: 5),
            Divider(color: Colors.white.withValues(alpha: 0.3)),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getExpensesStream(),
              builder: (context, snapshot) {
                // FIX 5: Arată widget gol doar dacă nu sunt date
                if (!snapshot.hasData) return SizedBox.shrink();

                double totalIncome = 0;
                double totalExpenses = 0;
                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  if (data['type'] == 'income') {
                    totalIncome += data['amount'] ?? 0.0;
                  } else {
                    totalExpenses += data['amount'] ?? 0.0;
                  }
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIncomeExpenseRow(
                      icon: Icons.arrow_downward,
                      color: Colors.greenAccent[100]!,
                      label: 'Venituri',
                      amount: totalIncome,
                      currencySymbol: settings.currencySymbol,
                    ),
                    _buildIncomeExpenseRow(
                      icon: Icons.arrow_upward,
                      color: const Color.fromARGB(255, 216, 0, 61),
                      label: 'Cheltuieli',
                      amount: totalExpenses,
                      currencySymbol: settings.currencySymbol,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseRow({
    required IconData icon,
    required Color color,
    required String label,
    required double amount,
    required String currencySymbol,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 30),
        ),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
            Text(
              '$currencySymbol${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
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
