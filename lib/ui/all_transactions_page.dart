import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:expense_tracker_nou/ui/transaction_details_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';

class AllTransactionsPage extends StatefulWidget {
  const AllTransactionsPage({super.key});

  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _currentDisplayDate = DateTime.now();

  // Filtrare tranzacții pentru luna selectată
  List<QueryDocumentSnapshot> _filterByMonth(
    List<QueryDocumentSnapshot> allDocs,
  ) {
    DateTime start = DateTime(
      _currentDisplayDate.year,
      _currentDisplayDate.month,
      1,
    );
    DateTime end = DateTime(
      _currentDisplayDate.year,
      _currentDisplayDate.month + 1,
      1,
    );

    return allDocs.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
      DateTime date = timestamp.toDate();
      return (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
          date.isBefore(end);
    }).toList();
  }

  // Calcul pentru graficul "Plăcintă" (Doar Cheltuieli)
  Map<String, double> _calculateCategoryExpenses(
    List<QueryDocumentSnapshot> docs,
  ) {
    Map<String, double> totals = {};
    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data['type'] == 'expense') {
        String category = data['category'] ?? 'Altul';
        double amount = (data['amount'] ?? 0.0).toDouble();
        totals[category] = (totals[category] ?? 0) + amount;
      }
    }
    return totals;
  }

  // Helper pentru iconițe
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

  // --- 1. LOGICA PENTRU LOGO-URI ÎN LISTĂ ---
  Widget _buildTransactionLeading(Map<String, dynamic> data, bool isExpense) {
    String description = (data['description'] ?? '').toLowerCase();
    String category = data['category'] ?? 'Altul';
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
    if (description.contains('enel')) {
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
    // (Poți adăuga restul brandurilor aici, exact ca în transaction_details_page)

    return CircleAvatar(
      backgroundColor: isExpense
          ? Colors.red.withOpacity(0.1)
          : const Color(0xff2f7e79).withOpacity(0.1),
      child: Icon(
        _getIconForCategory(category),
        color: isExpense ? Colors.red[300] : const Color(0xff2f7e79),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getExpensesStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          var monthlyDocs = _filterByMonth(snapshot.data!.docs);
          var categoryTotals = _calculateCategoryExpenses(monthlyDocs);

          return Stack(
            children: [
              // A. FUNDALUL CU IMAGINE
              ClipPath(
                clipper: _TopCurveClipper(),
                child: Container(
                  height: 380,
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
                    // B. ANTET (HEADER)
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
                            'Istoric Complet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 48),
                        ],
                      ),
                    ),

                    // C. SELECTOR DE LUNĂ (DROPDOWN NOU)
                    _buildMonthDropdown(),

                    // D. GRAFICUL PLĂCINTĂ
                    SizedBox(
                      height: 200,
                      child: categoryTotals.isEmpty
                          ? Center(
                              child: Text(
                                'Fără cheltuieli',
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          : PieChart(
                              PieChartData(
                                sections: _buildPieSections(categoryTotals),
                                centerSpaceRadius: 40,
                                sectionsSpace: 2,
                              ),
                            ),
                    ),

                    // E. LISTA DE TRANZACȚII
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(top: 20, left: 16, right: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tranzacțiile Lunii',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Expanded(
                              child: monthlyDocs.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Nicio tranzacție în această lună.',
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: monthlyDocs.length,
                                      itemBuilder: (context, index) {
                                        var doc = monthlyDocs[index];
                                        var data =
                                            doc.data() as Map<String, dynamic>;
                                        return _buildTransactionItem(
                                          doc.id,
                                          data,
                                          settings,
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
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

  // --- MODIFICARE 1: WIDGET PENTRU DROPDOWN ---
  Widget _buildMonthDropdown() {
    return Align(
      alignment: Alignment.centerRight, // 1. Aliniere la dreapta
      child: Padding(
        padding: const EdgeInsets.only(
          right: 16.0,
          bottom: 10.0,
        ), // Spațiu de la margine
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ), // Padding mai mic
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15), // Colțuri puțin mai mici
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              dropdownColor: const Color(0xff2f7e79),
              value: _currentDisplayDate.month,
              isDense: true, // 2. Face butonul mai compact
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 20,
              ), // Iconiță mai mică
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15, // 3. Font mai mic (era 18)
              ),
              items: List.generate(12, (index) {
                int monthIndex = index + 1;
                DateTime dummyDate = DateTime(
                  _currentDisplayDate.year,
                  monthIndex,
                  1,
                );
                String monthName = DateFormat(
                  'MMMM yyyy',
                  'ro',
                ).format(dummyDate);
                monthName = toBeginningOfSentenceCase(monthName) ?? monthName;

                return DropdownMenuItem(
                  value: monthIndex,
                  child: Text(monthName),
                );
              }),
              onChanged: (newMonth) {
                if (newMonth != null) {
                  setState(() {
                    _currentDisplayDate = DateTime(
                      _currentDisplayDate.year,
                      newMonth,
                      1,
                    );
                  });
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> totals) {
    List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
    ];
    int colorIndex = 0;
    return totals.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '',
        radius: 50,
        badgeWidget: _Badge(
          icon: _getIconForCategory(entry.key),
          size: 40,
          borderColor: color,
        ),
        badgePositionPercentageOffset: .98,
      );
    }).toList();
  }

  Widget _buildTransactionItem(
    String id,
    Map<String, dynamic> data,
    SettingsProvider settings,
  ) {
    String description = data['description'] ?? 'N/A';
    double amount = (data['amount'] ?? 0.0).toDouble();
    bool isExpense = data['type'] == 'expense';

    return Card(
      margin: EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TransactionDetailsPage(data: data, transactionId: id),
            ),
          );
        },
        leading: _buildTransactionLeading(
          data,
          isExpense,
        ), // Folosește helper-ul nou
        title: Text(description, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          DateFormat(
            'd MMM yyyy',
            'ro',
          ).format((data['timestamp'] as Timestamp).toDate()),
        ),
        // --- MODIFICARE 2: FONT MAI MARE LA SUMĂ ---
        trailing: Text(
          '${isExpense ? '-' : '+'}${settings.currencySymbol}${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: isExpense ? Colors.red : const Color(0xff2f7e79),
            fontWeight: FontWeight.bold,
            fontSize: 18, // <-- Mărit de la 14 la 18
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color borderColor;
  const _Badge({
    required this.icon,
    required this.size,
    required this.borderColor,
  });
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 3),
        ],
      ),
      child: Icon(icon, size: size * 0.6, color: Colors.black),
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
