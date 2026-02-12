import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:expense_tracker_nou/services/brand_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';

class StatisticsPage extends StatefulWidget {
  final VoidCallback? onBackTap;

  const StatisticsPage({super.key, this.onBackTap});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();

  DateTime _currentDisplayDate = DateTime.now();
  int _selectedPeriodIndex = 2; // 0=Ziua, 1=Săptămâna, 2=Lună
  final List<String> _periods = ['Ziua', 'Săptămâna', 'Lună'];
  String _selectedType = 'expense';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToEnd();
    });
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients &&
        (_selectedPeriodIndex == 0 || _selectedPeriodIndex == 2)) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  // --- FUNCȚII HELPER ---
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
      case 2: // Luna (Tot anul)
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year + 1, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year + 1, 1, 1);
    }

    return allTransactions.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
      DateTime date = timestamp.toDate();
      return (date.isAfter(startDate) || date.isAtSameMomentAs(startDate)) &&
          date.isBefore(endDate);
    }).toList();
  }

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
    final Color primaryGreen = const Color(0xff2f7e79);

    // --- LOGICA PENTRU TEMĂ ---
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Culori dinamice
    final Color backgroundColor = isDarkMode
        ? const Color(0xff121212)
        : Colors.grey[50]!;
    final Color cardColor = isDarkMode ? const Color(0xff1E1E1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color subTextColor = isDarkMode
        ? Colors.grey[400]!
        : Colors.grey[600]!;
    final Color borderColor = isDarkMode
        ? Colors.grey[800]!
        : Colors.grey[300]!;

    // --- AICI ESTE DEFINIȚIA CARE LIPSEA ---
    final Color shadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.5)
        : Colors.grey.withValues(alpha: 0.15);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: textColor,
                      size: 22,
                    ),
                    onPressed: () {
                      if (widget.onBackTap != null) {
                        widget.onBackTap!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  Text(
                    'Statistici',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getExpensesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Eroare: ${snapshot.error}',
                        style: TextStyle(color: textColor),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Nicio tranzacție.',
                        style: TextStyle(color: textColor),
                      ),
                    );
                  }

                  var allTransactions = snapshot.data!.docs;
                  var periodFilteredTransactions = _filterTransactionsByPeriod(
                    allTransactions,
                    _selectedPeriodIndex,
                  );
                  var typeFilteredTransactions = periodFilteredTransactions
                      .where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        return data['type'] == _selectedType;
                      })
                      .toList();
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
                        spots
                            .map((spot) => spot.y)
                            .reduce((a, b) => a > b ? a : b) *
                        1.2;
                  }
                  if (maxY == 0) maxY = 10;

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // --- SELECTOR PERIOADĂ ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(_periods.length, (index) {
                              bool isSelected = _selectedPeriodIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedPeriodIndex = index;
                                    _currentDisplayDate = DateTime.now();
                                  });
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    _scrollToEnd();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 13,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryGreen
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  child: Text(
                                    _periods[index],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : subTextColor,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 20),

                          // --- DROPDOWN TIP (STIL NOU, ADAPTABIL) ---
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              height: 45,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: cardColor,
                                border: Border.all(
                                  color: borderColor,
                                ), // Folosim borderColor aici
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        shadowColor, // Folosim shadowColor definită sus
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedType,
                                  dropdownColor: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  icon: Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: textColor,
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'expense',
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [Text('Cheltuieli')],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'income',
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [Text('Venituri')],
                                      ),
                                    ),
                                  ],
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedType = newValue!;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // --- GRAFIC SCROLLABIL ---
                          LayoutBuilder(
                            builder: (context, constraints) {
                              double chartWidth = constraints.maxWidth;
                              if (_selectedPeriodIndex == 2) {
                                chartWidth = constraints.maxWidth * 2;
                              } else if (_selectedPeriodIndex == 0) {
                                chartWidth = constraints.maxWidth * 1.5;
                              }

                              return SingleChildScrollView(
                                controller: _scrollController,
                                scrollDirection: Axis.horizontal,
                                physics: const ClampingScrollPhysics(),
                                child: Container(
                                  width: chartWidth,
                                  height: 250,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: _buildLineChart(
                                    spots,
                                    maxY,
                                    _selectedPeriodIndex,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 30),

                          // --- TITLU LISTĂ ---
                          Text(
                            _selectedType == 'expense'
                                ? 'Top Cheltuieli'
                                : 'Top Venituri',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // --- LISTA TRANZACȚII ---
                          if (typeFilteredTransactions.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  'Nicio tranzacție de acest tip în această perioadă.',
                                  style: TextStyle(color: subTextColor),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              itemCount: sortedTransactions.length > 5
                                  ? 5
                                  : sortedTransactions.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                var doc = sortedTransactions[index];
                                var data = doc.data() as Map<String, dynamic>;
                                bool isExpense =
                                    (data['type'] ?? 'expense') == 'expense';

                                return Card(
                                  color: cardColor,
                                  elevation: 2,
                                  shadowColor: isDarkMode
                                      ? Colors.black
                                      : Colors.grey.shade200,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    leading: _buildTransactionLeading(
                                      data,
                                      isExpense,
                                    ),
                                    title: Text(
                                      data['description'] ?? 'N/A',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: textColor,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        data['category'] ?? 'Fără categorie',
                                        style: TextStyle(color: subTextColor),
                                      ),
                                    ),
                                    trailing: Text(
                                      '${(data['amount'] ?? 0.0).toStringAsFixed(2)} ${settings.currencySymbol}',
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
                            ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionLeading(Map<String, dynamic> data, bool isExpense) {
    final description = data['description'] ?? '';
    final category = data['category'] ?? 'Altele';
    return BrandService.getTransactionLeading(
      description: description,
      category: category,
      isExpense: isExpense,
      getIconForCategory: BrandService.getIconForCategory,
    );
  }

  Widget _buildLineChart(List<FlSpot> spots, double maxY, int periodIndex) {
    if (spots.isEmpty) {
      return const Center(child: Text('Date insuficiente pentru grafic.'));
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
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
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
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
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
    // Culoare adaptabilă pentru axa X
    final color = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[400]
        : Colors.grey;

    final style = TextStyle(
      color: color,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    String text;
    switch (periodIndex) {
      case 0: // Ziua
        text = value.toInt() % 6 == 0 ? '${value.toInt()}h' : '';
        break;
      case 1: // Săptămâna
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
      default: // Luna
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
}
