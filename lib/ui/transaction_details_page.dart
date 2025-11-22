import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:expense_tracker_nou/ui/add_transaction_sheet.dart';
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

  // --- FUNCȚIE PENTRU A OBȚINE NUMELE UTILIZATORULUI DIN DB ---
  Future<String> _getUserName(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        return userDoc.get('name') ?? 'Necunoscut';
      }
      return 'Necunoscut';
    } catch (e) {
      return 'Eroare';
    }
  }

  // --- FUNCȚIE PENTRU ICONIȚE MARI (BRANDURI) ---
  Widget _buildBigTransactionIcon(Map<String, dynamic> data, bool isExpense) {
    String description = (data['description'] ?? '').toLowerCase();
    String category = data['category'] ?? 'Altul';
    double imageSize = 50;

    if (description.contains('netflix')) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.white, // Netflix are fundal negru de obicei
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
        backgroundColor: Colors.white, // Netflix are fundal negru de obicei
        child: Image.asset(
          'assets/images/nn.png',
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
    // Logica Generic
    return CircleAvatar(
      radius: 40,
      backgroundColor: isExpense
          ? Colors.red.withOpacity(0.1)
          : const Color(0xff2f7e79).withOpacity(0.1),
      child: Icon(
        _getIconForCategory(category),
        size: 40,
        color: isExpense ? Colors.red[400] : const Color(0xff2f7e79),
      ),
    );
  }

  Widget _buildBrandAvatar(String assetPath, Color bgColor, double size) {
    return CircleAvatar(
      radius: 40,
      backgroundColor: bgColor,
      child: Image.asset(assetPath, width: size, height: size),
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

    return Scaffold(
      body: Stack(
        children: [
          // --- 1. FUNDALUL VERDE ---
          ClipPath(
            clipper: _TopCurveClipper(),
            child: Container(
              height: 300,
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
                // --- 2. ANTET ---
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
                      // --- GRUP DE BUTOANE (EDIT & DELETE) ---
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.white),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddTransactionSheet(
                                    transactionId: transactionId,
                                    transactionData: data,
                                  ),
                                ),
                              );
                              if (result == true && context.mounted)
                                Navigator.of(context).pop();
                            },
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
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // --- 3. CARDUL PRINCIPAL ---
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
                          // A. Iconița Mare
                          _buildBigTransactionIcon(data, isExpense),
                          SizedBox(height: 16),

                          // B. Pilula cu Tipul (Venit/Cheltuială)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isExpense
                                  ? Colors.red.withOpacity(0.1)
                                  : const Color(0xff2f7e79).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isExpense ? 'Cheltuială' : 'Venit',
                              style: TextStyle(
                                color: isExpense
                                    ? Colors.red[400]
                                    : const Color(0xff2f7e79),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),

                          // C. Suma Mare
                          Text(
                            '${isExpense ? '-' : '+'}${settings.currencySymbol}${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),

                          SizedBox(height: 40),

                          // D. Header "Transaction details"
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Detalii Tranzacție',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(Icons.keyboard_arrow_up, color: Colors.grey),
                            ],
                          ),
                          SizedBox(height: 20),

                          // E. Lista de Detalii
                          _buildDetailRow(
                            context,
                            'Status',
                            'Finalizat',
                            textColor: isExpense
                                ? Colors.red
                                : const Color(0xff2f7e79),
                            isBold: true,
                          ),

                          // --- AICI E SCHIMBAREA: Numele Real ---
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Adăugat de',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                FutureBuilder<String>(
                                  future: _getUserName(
                                    ownerUid,
                                  ), // Căutăm numele în DB
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return SizedBox(
                                        width: 15,
                                        height: 15,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      );
                                    }
                                    return Text(
                                      snapshot.data ??
                                          '...', // Afișăm numele real
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          // --------------------------------------
                          _buildDetailRow(context, 'Ora', formattedTime),
                          _buildDetailRow(context, 'Data', formattedDate),

                          SizedBox(height: 20),
                          Divider(),
                          SizedBox(height: 20),

                          // F. Total Footer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${settings.currencySymbol}${amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 30),
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

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? textColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
            ),
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
