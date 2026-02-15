import 'package:flutter/material.dart';

class BrandService {
  // --- 1. MAPPING BRANDURI (Cheile sunt acum FRUMOASE, de afișat) ---
  static const Map<String, String> _brandAssets = {
    'Netflix': 'netflix.png', // <--- Scris cu N mare
    'YouTube': 'youtube.png',
    'Asigurare': 'nn.png',
    'Kaufland': 'kaufland.png',
    'Carrefour': 'carrefour.png',
    'Spotify': 'spotify.png',
    'Uber': 'uber.png',
    'Bolt': 'bolt.png',
    'eMAG': 'emag.png',
    'BT': 'bt.png',
    'Orange': 'orange.png',
    'Digi': 'digi.png',
    'PPC Energie': 'enel.png',
    'E.ON': 'eon.png',
    'Revolut': 'revolut.png',
    'Lidl': 'lidl.png',
    'Starbucks': 'starbucks.png',
    'Glovo': 'glovo.png',
    'Tazz': 'tazz.png',
    'OMV': 'omv.png',
    'Petrom': 'petrom.png',
    'Rompetrol': 'rompetrol.png',
    'Lukoil': 'lukoil.png',
    'MOL': 'mol.png',
    'Socar': 'socar.png',
    'Gazprom': 'gazprom.png',
    'Altex': 'altex.png',
    'Flanco': 'flanco.png',
    'Decathlon': 'decathlon.png',
    'H&M': 'hm.png',
    'Zara': 'zara.png',
  };

  static List<String> get knownBrands => _brandAssets.keys.toList();

  // --- MODIFICARE 1: Căutare inteligentă a imaginii ---
  static String? getAssetPathForBrand(String brandName) {
    // 1. Încercăm potrivire exactă (ex: a selectat "Netflix")
    if (_brandAssets.containsKey(brandName)) {
      return 'assets/images/${_brandAssets[brandName]}';
    }

    // 2. Dacă nu găsim, căutăm ignorând majusculele (ex: a scris manual "netflix")
    try {
      final key = _brandAssets.keys.firstWhere(
        (k) => k.toLowerCase() == brandName.toLowerCase(),
      );
      return 'assets/images/${_brandAssets[key]}';
    } catch (e) {
      return null;
    }
  }

  // --- MODIFICARE 2: Logica pentru tranzacții existente ---
  static Widget getTransactionLeading({
    required String description,
    required String category,
    required bool isExpense,
    IconData Function(String)? getIconForCategory,
  }) {
    final String descLower = description.toLowerCase();

    // Căutăm în mapă, dar transformăm CHEIA în litere mici pentru comparație
    for (var entry in _brandAssets.entries) {
      // Dacă descrierea "plata netflix" conține cheia "Netflix" (transformată în "netflix")
      if (descLower.contains(entry.key.toLowerCase())) {
        return _buildBrandLogo('assets/images/${entry.value}');
      }
    }

    // FALLBACK
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isExpense
            ? const Color(0xff7b0828).withValues(alpha: 0.1)
            : const Color(0xff2f7e79).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        BrandService.getIconForCategory(category),
        color: isExpense ? const Color(0xff7b0828) : const Color(0xff2f7e79),
        size: 24,
      ),
    );
  }

  static Widget getBigTransactionIcon({
    required String description,
    required String category,
    required bool isExpense,
    IconData Function(String)? getIconForCategory,
  }) {
    final String descLower = description.toLowerCase();

    for (var entry in _brandAssets.entries) {
      // La fel, comparăm lowercase cu lowercase
      if (descLower.contains(entry.key.toLowerCase())) {
        return _buildBigBrandLogo('assets/images/${entry.value}');
      }
    }

    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        color: isExpense
            ? const Color(0xff7b0828).withValues(alpha: 0.1)
            : const Color(0xff2f7e79).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        BrandService.getIconForCategory(category),
        color: isExpense ? const Color(0xff7b0828) : const Color(0xff2f7e79),
        size: 40,
      ),
    );
  }

  // ... Restul funcțiilor (getIconForCategory, _buildBrandLogo) rămân la fel ...
  static IconData getIconForCategory(String category) {
    // ... (păstrează codul tău existent aici)
    switch (category) {
      case 'Alimente & Băuturi':
        return Icons.local_grocery_store;
      // ... restul case-urilor tale ...
      default:
        return Icons.money;
    }
  }

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
          const BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }

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
          const BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
    );
  }
}
