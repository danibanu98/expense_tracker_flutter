import 'package:flutter/material.dart';

class BrandService {
  // --- 1. MAPPING BRANDURI (Extins cu lista ta) ---
  static const Map<String, String> _brandAssets = {
    'netflix': 'netflix.png',
    'youtube': 'youtube.png',
    'asigurare ale': 'nn.png', // Asigură-te că ai poza nn.png
    'rata bt': 'bt.png', // Asigură-te că ai poza bt.png
    'orange': 'orange.png',
    'digi': 'digi.png',
    'rcs': 'digi.png',
    'curent ppc': 'enel.png', // Asigură-te că ai poza enel.png
    'eon': 'eon.png',
    'revolut': 'revolut.png',
    'lidl': 'lidl.png',
    'starbucks': 'starbucks.png',
    'glovo': 'glovo.png',
    'tazz': 'glovo.png', // Folosim glovo și pentru tazz dacă nu ai logo separat
    'omv': 'omv.png',
    'petrom': 'omv.png',
  };

  // --- 2. LOGICA PENTRU BRANDURI (Logo-uri vs Iconițe) ---
  // Aceasta este funcția apelată din StatisticsPage și HomePage
  static Widget getTransactionLeading({
    required String description,
    required String category,
    required bool isExpense,
    // Parametrul getIconForCategory este opțional acum, îl folosim pe cel intern
    IconData Function(String)? getIconForCategory,
  }) {
    final String descLower = description.toLowerCase();

    // Căutăm în mapa de branduri
    for (var entry in _brandAssets.entries) {
      if (descLower.contains(entry.key)) {
        return _buildBrandLogo('assets/images/${entry.value}');
      }
    }

    // FALLBACK: Dacă nu e brand, returnăm iconița colorată de categorie
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isExpense
            ? const Color(0xff7b0828).withOpacity(0.1) // Roșu pal
            : const Color(0xff2f7e79).withOpacity(0.1), // Verde pal
        shape: BoxShape.circle,
      ),
      child: Icon(
        BrandService.getIconForCategory(category), // Apelăm funcția internă
        color: isExpense ? const Color(0xff7b0828) : const Color(0xff2f7e79),
        size: 24,
      ),
    );
  }

  // --- 3. ICONIȚA MARE (Pentru pagina de Detalii) ---
  static Widget getBigTransactionIcon({
    required String description,
    required String category,
    required bool isExpense,
    IconData Function(String)? getIconForCategory,
  }) {
    final String descLower = description.toLowerCase();

    for (var entry in _brandAssets.entries) {
      if (descLower.contains(entry.key)) {
        return _buildBigBrandLogo('assets/images/${entry.value}');
      }
    }

    // Fallback mare
    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        color: isExpense
            ? const Color(0xff7b0828).withOpacity(0.1)
            : const Color(0xff2f7e79).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        BrandService.getIconForCategory(category),
        color: isExpense ? const Color(0xff7b0828) : const Color(0xff2f7e79),
        size: 40,
      ),
    );
  }

  // --- 4. ICONIȚE PENTRU CATEGORII (Mapping-ul tău extins) ---
  static IconData getIconForCategory(String category) {
    switch (category) {
      case 'Alimente & Băuturi':
      case 'Mâncare':
        return Icons.restaurant;
      case 'Cumpărături':
        return Icons.shopping_bag;
      case 'Locuinţă':
      case 'Facturi':
        return Icons.home;
      case 'Transport':
        return Icons.directions_bus;
      case 'Maşină':
        return Icons.directions_car;
      case 'Viaţă & Divertisment':
      case 'Distracție':
        return Icons.sports_esports;
      case 'Hardware PC':
        return Icons.computer;
      case 'Cheltuieli financiare':
        return Icons.payments;
      case 'Investiţii':
        return Icons.trending_up;
      case 'Salariu':
        return Icons.work;
      case 'Bonus':
        return Icons.card_giftcard;
      case 'Cadou':
        return Icons.cake;
      case 'Sănătate':
        return Icons.medical_services;
      case 'Altele':
        return Icons.category;
      default:
        return Icons.money;
    }
  }

  // --- HELPER: Construiește imaginea mică ---
  static Widget _buildBrandLogo(String assetPath) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        image: DecorationImage(
          image: AssetImage(assetPath),
          fit: BoxFit.contain,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
    );
  }

  // --- HELPER: Construiește imaginea mare ---
  static Widget _buildBigBrandLogo(String assetPath) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        image: DecorationImage(
          image: AssetImage(assetPath),
          fit: BoxFit.contain,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
    );
  }
}
