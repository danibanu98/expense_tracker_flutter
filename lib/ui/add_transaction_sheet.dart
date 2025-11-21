import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  // Toate variabilele de stare și controllerele rămân la fel
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedType = 'expense';
  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedAccountId;
  late Future<List<QueryDocumentSnapshot>> _accountsFuture;
  final List<String> _expenseCategories = [
    'Mâncare',
    'Transport',
    'Facturi',
    'Timp Liber',
    'Cumpărături',
    'Altul',
  ];
  final List<String> _incomeCategories = ['Salariu', 'Bonus', 'Cadou', 'Altul'];
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedCategory = _selectedType == 'expense'
        ? _expenseCategories.first
        : _incomeCategories.first;
    _accountsFuture = _firestoreService.getAccountsList();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _saveTransaction() async {
    final description = _descriptionController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (description.isEmpty ||
        amount <= 0 ||
        _selectedAccountId == null ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Completează toate câmpurile, inclusiv contul și categoria.',
          ),
        ),
      );
      return;
    }

    try {
      await _firestoreService.addTransaction(
        description,
        amount,
        _selectedType,
        _selectedAccountId!,
        _selectedCategory!,
        _selectedDate,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Se va întoarce la pagina anterioară
      }
    } catch (e) {
      print('Eroare la salvare: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Eroare la salvare: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    return Scaffold(
      // Folosim un Stack pentru a suprapune valul verde și conținutul
      body: Stack(
        children: [
          // --- 1. FUNDALUL VERDE (VALUL) ---
          // --- 1. FUNDALUL VERDE (CU IMAGINE) ---
          ClipPath(
            clipper: _TopCurveClipper(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: BoxDecoration(
                // --- MODIFICAT PENTRU A FOLOSI IMAGINEA ---
                image: DecorationImage(
                  image: AssetImage(
                    'assets/images/fundal.png',
                  ), // <-- Numele imaginii
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // --- 2. CONȚINUTUL PAGINII ---
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 50),
                // --- A. ANTETUL (HEADER) PERSONALIZAT ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 0.0,
                  ), // Ajustăm padding-ul
                  child: Row(
                    children: [
                      // Butonul de înapoi
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      // Titlul (centrat)
                      Expanded(
                        child: Text(
                          _selectedType == 'expense'
                              ? 'Adaugă Cheltuială'
                              : 'Adaugă Venit',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 48.0),
                    ],
                  ),
                ),
                SizedBox(height: 60), // Spațiu după header și înainte de card
                // --- B. CARDUL ALB (FORMULARUL) ---
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(24.0), // Padding intern
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          // Adăugăm o umbră subtilă
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // --- TOGGLE BUTTONS (acum în interiorul cardului) ---
                          // Aici am adăugat și centrat ToggleButtons
                          Center(
                            child: ToggleButtons(
                              isSelected: [
                                _selectedType == 'expense',
                                _selectedType == 'income',
                              ],
                              onPressed: (index) {
                                setState(() {
                                  _selectedType = index == 0
                                      ? 'expense'
                                      : 'income';
                                  _selectedCategory = _selectedType == 'expense'
                                      ? _expenseCategories.first
                                      : _incomeCategories.first;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              selectedColor: Colors.white,
                              fillColor: _selectedType == 'expense'
                                  ? Colors.red[400]
                                  : const Color(0xff2f7e79),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Text('Cheltuială'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Text('Venit'),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 30,
                          ), // Mai mult spațiu după comutator
                          // Câmpurile (în ordinea corectă, nemodificate)

                          // 1. Categoria
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            hint: Text('Selectează Categoria'),
                            decoration: InputDecoration(
                              labelText: 'Categorie',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items:
                                (_selectedType == 'expense'
                                        ? _expenseCategories
                                        : _incomeCategories)
                                    .map((category) {
                                      return DropdownMenuItem(
                                        value: category,
                                        child: Text(category),
                                      );
                                    })
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                          ),
                          SizedBox(height: 20),

                          // 2. Suma
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _selectedType == 'expense'
                                  ? Colors.red[400]
                                  : const Color(0xff2f7e79),
                            ),
                            decoration: InputDecoration(
                              labelText: 'Sumă',
                              prefixText: settings.currencySymbol,
                              prefixStyle: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                              ),
                              hintText: '0.00',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),

                          // 3. Contul (cu FutureBuilder)
                          FutureBuilder<List<QueryDocumentSnapshot>>(
                            future:
                                _accountsFuture, // Viitorul pe care îl așteptăm
                            builder: (context, snapshot) {
                              // Cazul 1: Încă se încarcă?
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              // Cazul 2: A apărut o eroare?
                              if (snapshot.hasError) {
                                return Text(
                                  'Eroare la încărcarea conturilor: ${snapshot.error}',
                                );
                              }

                              // Cazul 3: Nu avem date (lista e goală)?
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Text(
                                  'Niciun cont. Mergi la "Portofel" și adaugă unul.',
                                );
                              }

                              // Cazul 4: Avem date! Construim dropdown-ul
                              var accountsList = snapshot.data!;

                              return DropdownButtonFormField<String>(
                                initialValue: _selectedAccountId,
                                hint: Text('Selectează Contul'),
                                decoration: InputDecoration(
                                  labelText: 'Cont',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: accountsList.map((doc) {
                                  var account =
                                      doc.data() as Map<String, dynamic>;
                                  return DropdownMenuItem(
                                    value: doc.id,
                                    child: Text(
                                      account['name'] ?? 'Cont Fără Nume',
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedAccountId = value;
                                  });
                                },
                              );
                            },
                          ),
                          SizedBox(height: 20),

                          // 4. Descrierea
                          TextField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Descriere (ex: Netflix, Salariu)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),

                          // 5. Data
                          InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Dată',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: TextButton(
                              onPressed: () => _selectDate(context),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    DateFormat(
                                      'EEE, d MMM yyyy',
                                      'ro',
                                    ).format(_selectedDate),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 30),

                          // Butonul de Salvare
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveTransaction,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('Salvează'),
                            ),
                          ),
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
}

// --- CLASA HELPER PENTRU "VALUL" VERDE (Copiată de pe HomePage) ---
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
