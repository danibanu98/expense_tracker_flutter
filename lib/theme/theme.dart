import 'package:flutter/material.dart';

// O nuanță de verde pe care o vom folosi
Color darkGreen = Color(0xFF2f7e79); // Un verde închis
Color accentGreen = Color(0xFF2f7e79); // Un verde mai deschis (din design)

ThemeData darkTheme = ThemeData(
  // Setează luminozitatea generală pe întunecat
  brightness: Brightness.dark,

  // Setează culoarea de fundal principală
  scaffoldBackgroundColor: Color(0xFF1A1A1A), // Un negru/gri foarte închis
  // Setează culorile pentru AppBar
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF252525), // Un gri puțin mai deschis
    elevation: 0,
  ),

  // Setează culorile pentru Meniul de Jos
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF252525),
    selectedItemColor: accentGreen, // Verde pentru iconița activă
    unselectedItemColor: Colors.grey[600],
    type: BottomNavigationBarType.fixed, // Asigură afișarea corectă a 4+ iteme
  ),

  // Setează culorile pentru Butoanele Plutitoare (+)
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: accentGreen,
    foregroundColor: Colors.white, // E bine să specificăm și asta
    shape: CircleBorder(), // <-- LINIA ADĂUGATĂ AICI
  ),

  // Setează culorile pentru Butoanele simple (ElevatedButton)
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: accentGreen,
      foregroundColor: Colors.white, // Culoarea textului
    ),
  ),

  // Setează schema de culori generală
  colorScheme: ColorScheme.dark(
    primary: accentGreen, // Culoarea principală (accent)
    secondary: accentGreen,
    surface: Color(0xFF252525), // Culoarea cardurilor, ferestrelor pop-up, etc.
  ),
);
// --- TEMĂ NOUĂ PENTRU MODUL LUMINOS ---
ThemeData lightTheme = ThemeData(
  brightness: Brightness.light, // Setează pe luminos
  // Fundalul principal
  scaffoldBackgroundColor: Color(0xFFF5F5F5),

  // AppBar-ul (bara de sus)
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFFF5F5F5), // Fundal deschis
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.black), // Iconițe negre
    titleTextStyle: TextStyle(
      color: Colors.black, // Text negru
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),

  // Meniul de jos
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: accentGreen, // Verde activ
    unselectedItemColor: Colors.grey[400], // Gri inactiv
    type: BottomNavigationBarType.fixed,
  ),

  // --- REZOLVAREA PENTRU BUTONUL + ---
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: accentGreen, // Setează culoarea verde
    foregroundColor: Colors.white, // Culoarea iconiței (+)
    shape: CircleBorder(), // Forțează forma rotundă
  ),
  // --- SFÂRȘIT REZOLVARE ---

  // Tema butoanelor
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: accentGreen,
      foregroundColor: Colors.white,
    ),
  ),

  // Schema de culori generală
  colorScheme: ColorScheme.light(
    primary: accentGreen,
    secondary: accentGreen,
    background: Color(0xFFF5F5F5),
    surface: Colors.white, // Culoarea cardurilor
  ),
);
