import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:expense_tracker_nou/theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TransactionDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String transactionId;

  const TransactionDetailsPage({
    super.key,
    required this.data,
    required this.transactionId,
  });

  // --- FUNCȚIE CORECTATĂ PENTRU ICONIȚE MARI ---
  Widget _buildBigTransactionIcon(Map<String, dynamic> data, bool isExpense) {
    String description = (data['description'] ?? '').toLowerCase();
    String category = data['category'] ?? 'Altul';

    // Mărimea mare pentru pagina de detalii
    double imageSize = 50;

    // Logica pentru Brand-uri (folosim imageSize = 50)
    if (description.contains('netflix')) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.black, // Netflix are fundal negru de obicei
        child: Image.asset(
          'assets/images/netflix.png',
          width: imageSize,
          height: imageSize,
        ),
      );
    }
    if (description.contains('asigurare ale')) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.black, // Netflix are fundal negru de obicei
        child: Image.asset(
          'assets/images/nn.png',
          width: imageSize,
          height: imageSize,
        ),
      );
    }
    if (description.contains('youtube')) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.white,
        child: Image.asset(
          'assets/images/youtube.png',
          width: imageSize,
          height: imageSize,
        ),
      );
    }
    if (description.contains('rata bt')) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.white,
        child: Image.asset(
          'assets/images/bt.png',
          width: imageSize,
          height: imageSize,
        ),
      );
    }
    if (description.contains('orange')) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.white,
        child: Image.asset(
          'assets/images/orange.png',
          width: imageSize,
          height: imageSize,
        ),
      );
    }
    if (description.contains('digi')) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.white,
        child: Image.asset(
          'assets/images/digi.png',
          width: imageSize,
          height: imageSize,
        ),
      );
    }
    if (description.contains('enel')) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.white,
        child: Image.asset(
          'assets/images/enel.png',
          width: imageSize,
          height: imageSize,
        ),
      );
    }
    if (description.contains('eon')) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.white,
        child: Image.asset(
          'assets/images/eon.png',
          width: imageSize,
          height: imageSize,
        ),
      );
    }
    if (description.contains('revolut')) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.white,
        child: Image.asset(
          'assets/images/revolut.png',
          width: imageSize,
          height: imageSize,
        ),
      );
    }
    if (description.contains('starbucks')) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.white,
        child: Image.asset(
          'assets/images/starbucks.png',
          width: imageSize,
          height: imageSize,
        ),
      );
    }
    if (description.contains('upwork')) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.green[50],
        child: Image.asset(
          'assets/images/upwork.png',
          width: imageSize,
          height: imageSize,
        ),
      );
    }

    // Logica Generic (dacă nu e brand)
    return CircleAvatar(
      radius: 40,
      backgroundColor: isExpense
          ? Colors.red.withOpacity(0.1)
          : const Color(0xff2f7e79).withOpacity(0.1),
      child: Icon(
        _getIconForCategory(category),
        size: 40, // Iconiță mare
        color: isExpense ? Colors.red[400] : const Color(0xff2f7e79),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Mâncare':
        return Icons.fastfood;
      case 'Transport':
        return Icons.directions_car;
      case 'Facturi':
        return Icons.receipt_long;
      case 'Timp Liber':
        return Icons.sports_esports;
      case 'Cumpărături':
        return Icons.shopping_bag;
      case 'Salariu':
        return Icons.work;
      case 'Bonus':
        return Icons.card_giftcard;
      case 'Cadou':
        return Icons.cake;
      default:
        return Icons.money;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final FirestoreService firestoreService = FirestoreService();

    String description = data['description'] ?? 'N/A';
    String category = data['category'] ?? 'Altul';
    double amount = (data['amount'] ?? 0.0).toDouble();
    String type = data['type'] ?? 'expense';
    bool isExpense = type == 'expense';

    Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
    DateTime date = timestamp.toDate();
    String formattedDate = DateFormat('d MMMM yyyy', 'ro').format(date);
    String formattedTime = DateFormat('HH:mm').format(date);

    String ownerUid = data['uid'] ?? '';
    String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    bool isMe = ownerUid == currentUserUid;

    return Scaffold(
      body: Stack(
        children: [
          ClipPath(
            clipper: _TopCurveClipper(),
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentGreen.withOpacity(0.8), accentGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        'Detalii Tranzacție',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.white),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Ștergi tranzacția?'),
                              content: Text(
                                'Această acțiune este ireversibilă.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: Text('Anulează'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    firestoreService.deleteExpense(
                                      transactionId,
                                    );
                                    Navigator.of(ctx).pop();
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    'Șterge',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // --- APELĂM FUNCȚIA CORECTĂ ---
                          _buildBigTransactionIcon(data, isExpense),
                          // ------------------------------
                          SizedBox(height: 16),

                          Text(
                            category,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),

                          Text(
                            '${isExpense ? '-' : '+'}${settings.currencySymbol}${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isExpense
                                  ? Colors.red[400]
                                  : Colors.green[400],
                            ),
                          ),

                          SizedBox(height: 40),
                          Divider(),
                          SizedBox(height: 20),

                          _buildDetailRow(
                            'Tip',
                            isExpense ? 'Cheltuială' : 'Venit',
                          ),
                          _buildDetailRow('Status', 'Finalizat'),
                          _buildDetailRow('Data', formattedDate),
                          _buildDetailRow('Ora', formattedTime),
                          _buildDetailRow('Adăugat de', isMe ? 'Tu' : 'Soția'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
