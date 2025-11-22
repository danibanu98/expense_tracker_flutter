import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:flutter/material.dart';

class AddAccountSheet extends StatefulWidget {
  // Dacă primim acest parametru, suntem în modul EDITARE
  final DocumentSnapshot? accountToEdit;

  const AddAccountSheet({super.key, this.accountToEdit});

  @override
  State<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<AddAccountSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  String _selectedCurrency = 'RON'; // Moneda implicită
  final List<String> _currencies = ['RON', 'EUR', 'USD', 'GBP'];

  @override
  void initState() {
    super.initState();
    // Dacă edităm, completăm câmpurile cu datele existente
    if (widget.accountToEdit != null) {
      final data = widget.accountToEdit!.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? '';
      _balanceController.text = (data['balance'] ?? 0.0).toString();
      _selectedCurrency = data['currency'] ?? 'RON';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _saveAccount() async {
    final name = _nameController.text.trim();
    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Numele contului este obligatoriu.')),
      );
      return;
    }

    try {
      if (widget.accountToEdit == null) {
        // MOD CREARE
        await _firestoreService.addAccount(name, balance, _selectedCurrency);
      } else {
        // MOD EDITARE (Update)
        await _firestoreService.updateAccount(
          widget.accountToEdit!.id,
          name,
          balance,
          _selectedCurrency,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      print('Eroare: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.accountToEdit != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isEditing ? 'Editează Cont' : 'Adaugă Cont Nou',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),

          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nume Cont (ex: Revolut, Cash)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 20),

          // Rând cu Suma și Moneda
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _balanceController,
                  decoration: InputDecoration(
                    labelText: 'Balanță',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  items: _currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCurrency = val!),
                  decoration: InputDecoration(
                    labelText: 'Monedă',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveAccount,
              child: Text(isEditing ? 'Actualizează' : 'Salvează'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
