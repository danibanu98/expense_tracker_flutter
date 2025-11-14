import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _currentDisplayDate = DateTime.now();
  int _selectedPeriodIndex = 2; // 0=Ziua, 1=Săpt, 2=Luna, 3=Anul
  final List<String> _periods = ['Ziua', 'Săpt', 'Luna', 'Anul'];
  String _selectedType = 'expense'; // 'expense' sau 'income'

  // Funcția de filtrare a tranzacțiilor (e corectă)
  List<QueryDocumentSnapshot> _filterTransactionsByPeriod(
    List<QueryDocumentSnapshot> allTransactions,
    int periodIndex,
  ) {
    DateTime now = _currentDisplayDate;
    DateTime startDate;
    DateTime endDate;

    switch (periodIndex) {
      case 0: // Ziua
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(Duration(days: 1));
        break;
      case 1: // Săptămâna
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(Duration(days: 7));
        break;
      case 2: // Luna
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
      case 3: // Anul
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year + 1, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
    }

    return allTransactions.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
      DateTime date = timestamp.toDate();
      return (date.isAfter(startDate) || date.isAtSameMomentAs(startDate)) &&
          date.isBefore(endDate);
    }).toList();
  }

  // Funcția de procesare a datelor pentru grafic (e corectă)
  Map<int, double> _calculateChartTotals(
    List<QueryDocumentSnapshot> transactions,
    int periodIndex,
  ) {
    Map<int, double> totals = {};
    for (var doc in transactions) {
      var data = doc.data() as Map<String, dynamic>;
      Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
      DateTime date = timestamp.toDate();
      double amount = (data['amount'] ?? 0.0).toDouble();

      int key;
      if (periodIndex == 0) {
        key = date.hour;
      } else if (periodIndex == 1) {
        key = date.weekday;
      } else {
        key = date.month;
      }
      totals[key] = (totals[key] ?? 0) + amount;
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Statistici')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getExpensesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('A apărut o eroare: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Nici o tranzacție de analizat'));
          }

          var allTransactions = snapshot.data!.docs;

          // --- LOGICA DE FILTRARE ---
          var periodFilteredTransactions = _filterTransactionsByPeriod(
            allTransactions,
            _selectedPeriodIndex,
          );
          var typeFilteredTransactions = periodFilteredTransactions.where((
            doc,
          ) {
            var data = doc.data() as Map<String, dynamic>;
            return data['type'] == _selectedType;
          }).toList();
          var sortedTransactions = List<QueryDocumentSnapshot>.from(
            typeFilteredTransactions,
          );
          sortedTransactions.sort((a, b) {
            double amountA =
                (a.data() as Map<String, dynamic>)['amount'] ?? 0.0;
            double amountB =
                (b.data() as Map<String, dynamic>)['amount'] ?? 0.0;
            return amountB.compareTo(amountA);
          });

          // --- LOGICA PENTRU GRAFIC (O SINGURĂ DATĂ) ---
          // **FIX:** Am șters blocul duplicat de la tine
          Map<int, double> chartTotals = _calculateChartTotals(
            typeFilteredTransactions,
            _selectedPeriodIndex,
          );
          List<FlSpot> spots = chartTotals.entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value);
          }).toList();
          spots.sort((a, b) => a.x.compareTo(b.x));

          double maxY = 0;
          if (spots.isNotEmpty) {
            maxY =
                spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) *
                1.2;
          }
          if (maxY == 0) maxY = 10;
          // --- SFÂRȘIT LOGICĂ GRAFIC ---

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- FILTRELE DE PERIOADĂ ---
                  ToggleButtons(
                    isSelected: List.generate(
                      4,
                      (index) => index == _selectedPeriodIndex,
                    ),
                    onPressed: (index) {
                      setState(() {
                        _selectedPeriodIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    selectedColor: Colors.white,
                    fillColor: Theme.of(context).colorScheme.primary,
                    children: _periods
                        .map(
                          (period) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text(period),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 16),

                  // --- SELECTORUL DE PERIOADĂ ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left),
                        onPressed: _previousPeriod,
                      ),
                      Text(
                        _formatPeriodText(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right),
                        onPressed: _nextPeriod,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // --- FILTRUL (Cheltuieli / Venituri) ---
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    items: [
                      DropdownMenuItem(
                        value: 'expense',
                        child: Text('Cheltuieli'),
                      ),
                      DropdownMenuItem(
                        value: 'income',
                        child: Text('Venituri'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),

                  // --- GRAFICUL LINIAR ---
                  Text(
                    _selectedType == 'expense'
                        ? 'Sumar Cheltuieli'
                        : 'Sumar Venituri',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    // **FIX:** Am folosit 'spots' în loc de 'chartSpots'
                    child: _buildLineChart(spots, maxY, _selectedPeriodIndex),
                  ),
                  SizedBox(height: 30),

                  // --- LISTA "TOP" ---
                  Text(
                    _selectedType == 'expense'
                        ? 'Top Cheltuieli'
                        : 'Top Venituri',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  if (typeFilteredTransactions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'Nicio tranzacție de acest tip în această perioadă.',
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      itemCount: sortedTransactions.length > 5
                          ? 5
                          : sortedTransactions.length,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        var doc = sortedTransactions[index];
                        var data = doc.data() as Map<String, dynamic>;

                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: Icon(
                              _getIconForCategory(data['category'] ?? 'Altul'),
                              color: _selectedType == 'expense'
                                  ? Colors.red[300]
                                  : Colors.green[300],
                            ),
                            title: Text(
                              data['description'] ?? 'N/A',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              data['category'] ?? 'Fără categorie',
                            ),
                            trailing: Text(
                              // **FIX:** Am scos '${netBalance.toStringAsFixed(2)}'
                              '${_selectedType == 'expense' ? '-' : '+'}${settings.currencySymbol}${(data['amount'] ?? 0.0).toStringAsFixed(2)}',
                              style: TextStyle(
                                color: _selectedType == 'expense'
                                    ? Colors.red[400]
                                    : Colors.green[400],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- FUNCȚIILE HELPER (Toate sunt corecte, le lași așa cum sunt) ---

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

  Widget _buildLineChart(List<FlSpot> spots, double maxY, int periodIndex) {
    if (spots.isEmpty) {
      return Center(child: Text('Date insuficiente pentru grafic.'));
    }

    double minX, maxX;
    switch (periodIndex) {
      case 0:
        minX = 0;
        maxX = 23;
        break;
      case 1:
        minX = 1;
        maxX = 7;
        break;
      default:
        minX = 1;
        maxX = 12;
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) =>
                  _buildBottomAxisTitles(value, meta, periodIndex),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  Theme.of(context).colorScheme.primary.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minX: minX,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
      ),
    );
  }

  Widget _buildBottomAxisTitles(double value, TitleMeta meta, int periodIndex) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    String text;

    switch (periodIndex) {
      case 0:
        text = value.toInt() % 6 == 0 ? '${value.toInt()}h' : '';
        break;
      case 1:
        switch (value.toInt()) {
          case 1:
            text = 'L';
            break;
          case 2:
            text = 'Ma';
            break;
          case 3:
            text = 'Mi';
            break;
          case 4:
            text = 'J';
            break;
          case 5:
            text = 'V';
            break;
          case 6:
            text = 'S';
            break;
          case 7:
            text = 'D';
            break;
          default:
            text = '';
        }
        break;
      default:
        switch (value.toInt()) {
          case 1:
            text = 'Ian';
            break;
          case 2:
            text = 'Feb';
            break;
          case 3:
            text = 'Mar';
            break;
          case 4:
            text = 'Apr';
            break;
          case 5:
            text = 'Mai';
            break;
          case 6:
            text = 'Iun';
            break;
          case 7:
            text = 'Iul';
            break;
          case 8:
            text = 'Aug';
            break;
          case 9:
            text = 'Sep';
            break;
          case 10:
            text = 'Oct';
            break;
          case 11:
            text = 'Noi';
            break;
          case 12:
            text = 'Dec';
            break;
          default:
            text = '';
        }
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10,
      child: Text(text, style: style),
    );
  }

  void _previousPeriod() {
    setState(() {
      if (_selectedPeriodIndex == 0) {
        _currentDisplayDate = _currentDisplayDate.subtract(Duration(days: 1));
      } else if (_selectedPeriodIndex == 1) {
        _currentDisplayDate = _currentDisplayDate.subtract(Duration(days: 7));
      } else if (_selectedPeriodIndex == 2) {
        _currentDisplayDate = DateTime(
          _currentDisplayDate.year,
          _currentDisplayDate.month - 1,
          1,
        );
      } else {
        _currentDisplayDate = DateTime(_currentDisplayDate.year - 1, 1, 1);
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_selectedPeriodIndex == 0) {
        _currentDisplayDate = _currentDisplayDate.add(Duration(days: 1));
      } else if (_selectedPeriodIndex == 1) {
        _currentDisplayDate = _currentDisplayDate.add(Duration(days: 7));
      } else if (_selectedPeriodIndex == 2) {
        _currentDisplayDate = DateTime(
          _currentDisplayDate.year,
          _currentDisplayDate.month + 1,
          1,
        );
      } else {
        _currentDisplayDate = DateTime(_currentDisplayDate.year + 1, 1, 1);
      }
    });
  }

  String _formatPeriodText() {
    switch (_selectedPeriodIndex) {
      case 0:
        return DateFormat('d MMM yyyy').format(_currentDisplayDate);
      case 1:
        DateTime startOfWeek = _currentDisplayDate.subtract(
          Duration(days: _currentDisplayDate.weekday - 1),
        );
        DateTime endOfWeek = startOfWeek.add(Duration(days: 6));
        return '${DateFormat('d MMM').format(startOfWeek)} - ${DateFormat('d MMM yyyy').format(endOfWeek)}';
      case 2:
        return DateFormat('MMMM yyyy', 'ro').format(_currentDisplayDate);
      case 3:
        return DateFormat('yyyy').format(_currentDisplayDate);
      default:
        return '';
    }
  }
}
