import 'package:flutter/material.dart';

/// Serviciu centralizat pentru afișarea iconițelor/logo-urilor tranzacțiilor
/// pe baza descrierii (recunoaștere branduri) sau categoriei.
class BrandService {
  BrandService._();

  static const String _assetsPath = 'assets/images';

  /// Mapări descriere (lowercase) -> nume fișier asset (fără path).
  static const Map<String, String> _brandAssets = {
    'netflix': 'netflix.png',
    'youtube': 'youtube.png',
    'asigurare ale': 'nn.png',
    'rata bt': 'bt.png',
    'orange': 'orange.png',
    'digi': 'digi.png',
    'curent ppc': 'enel.png',
    'eon': 'eon.png',
    'revolut': 'revolut.png',
    'lidl': 'lidl.png',
    'starbucks': 'starbucks.png',
  };

  /// Verifică dacă descrierea conține un brand cunoscut și returnează path-ul asset-ului sau null.
  static String? getBrandAssetPath(String description) {
    final lower = description.trim().toLowerCase();
    for (final entry in _brandAssets.entries) {
      if (lower.contains(entry.key)) {
        return '$_assetsPath/${entry.value}';
      }
    }
    return null;
  }

  /// Returnează widget-ul pentru leading-ul unei tranzacții (listă): logo brand sau icon categorie.
  static Widget getTransactionLeading({
    required String description,
    required String category,
    required bool isExpense,
    double size = 28,
    required IconData Function(String category) getIconForCategory,
  }) {
    final assetPath = getBrandAssetPath(description);
    if (assetPath != null) {
      return CircleAvatar(
        backgroundColor: Colors.white,
        child: Image.asset(assetPath, width: size, height: size),
      );
    }
    return CircleAvatar(
      backgroundColor: isExpense
          ? const Color(0xff7b0828).withValues(alpha: 0.1)
          : const Color(0xff2f7e79).withValues(alpha: 0.1),
      child: Icon(
        getIconForCategory(category),
        color: isExpense ? const Color(0xff7b0828) : const Color(0xff2f7e79),
      ),
    );
  }

  /// Returnează iconița mare pentru pagina de detalii tranzacție.
  static Widget getBigTransactionIcon({
    required String description,
    required String category,
    required bool isExpense,
    double imageSize = 50,
    double avatarRadius = 40,
    required IconData Function(String category) getIconForCategory,
  }) {
    final assetPath = getBrandAssetPath(description);
    if (assetPath != null) {
      return CircleAvatar(
        radius: avatarRadius,
        backgroundColor: Colors.white,
        child: Image.asset(assetPath, width: imageSize, height: imageSize),
      );
    }
    return CircleAvatar(
      radius: avatarRadius,
      backgroundColor: isExpense
          ? const Color(0xff7b0828).withValues(alpha: 0.1)
          : const Color(0xff2f7e79).withValues(alpha: 0.1),
      child: Icon(
        getIconForCategory(category),
        size: 40,
        color: isExpense ? const Color(0xff7b0828) : const Color(0xff2f7e79),
      ),
    );
  }

  /// Icon pentru categorie (folosit peste tot același mapping).
  static IconData getIconForCategory(String category) {
    switch (category) {
      case 'Alimente & Băuturi':
        return Icons.restaurant;
      case 'Cumpărături':
        return Icons.shopping_bag;
      case 'Locuinţă':
        return Icons.home;
      case 'Transport':
        return Icons.car_rental;
      case 'Maşină':
        return Icons.directions_car;
      case 'Viaţă & Divertisment':
        return Icons.sports_esports;
      case 'Hardware PC':
        return Icons.computer;
      case 'Cheltuieli financiare':
        return Icons.payments;
      case 'Investiţii':
        return Icons.attach_money;
      case 'Salariu':
        return Icons.work;
      case 'Bonus':
        return Icons.card_giftcard;
      case 'Cadou':
        return Icons.cake;
      case 'Altele':
        return Icons.clear_all_rounded;
      default:
        return Icons.money;
    }
  }
}
