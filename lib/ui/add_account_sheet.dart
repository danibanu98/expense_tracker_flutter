import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:flutter/material.dart';

class AddAccountSheet extends StatefulWidget {
  const AddAccountSheet({super.key});

  @override
  State<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<AddAccountSheet> {
  // Controllere pentru a citi textul din câmpuri
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();

  // Instanța serviciului
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  // Funcția de salvare
  void _saveAccount() async {
    // 1. Extrage datele
    final name = _nameController.text.trim();
    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;

    // 2. Verifică dacă datele sunt valide
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Numele contului este obligatoriu.')),
      );
      return; // Oprește funcția
    }

    // 3. Apelăm FirestoreService pentru a salva datele
    try {
      await _firestoreService.addAccount(name, balance);

      if (mounted) Navigator.of(context).pop(); // Închide fereastra
    } catch (e) {
      print('Eroare la salvarea contului: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Eroare la salvare: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding care ține cont de tastatură
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Ocupă spațiu minim
        children: [
          Text(
            'Adaugă Cont Nou',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),

          // --- Câmpul pentru Numele Contului ---
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nume Cont (ex: Portofel Daniel, Card Soție)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 20),

          // --- Câmpul pentru Balanța Inițială ---
          TextField(
            controller: _balanceController,
            decoration: InputDecoration(
              labelText: 'Balanță Inițială (Opțional)',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 30),

          // --- Butonul de Salvare ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveAccount,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ), // Apelează funcția de salvare
              child: Text('Salvează Cont'),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
