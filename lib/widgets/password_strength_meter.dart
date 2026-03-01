import 'package:flutter/material.dart';

class PasswordStrengthMeter extends StatelessWidget {
  final String password;

  const PasswordStrengthMeter({super.key, required this.password});

  int _calculateScore(String value) {
    if (value.isEmpty) return 0;
    int score = 0;

    if (value.length >= 8) score++;
    if (value.length >= 12) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) {
      score++;
    }
    // includem și underscore și liniuță ca și caractere „speciale”
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(value)) score++;

    return score.clamp(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    final score = _calculateScore(password);
    final strength = score / 5.0;

    Color barColor;
    String label;
    IconData icon;

    if (strength == 0) {
      barColor = Colors.grey;
      label = 'Introduce o parolă';
      icon = Icons.remove;
    } else if (strength <= 0.4) {
      barColor = Colors.red;
      label = 'Parolă slabă';
      icon = Icons.warning_amber_rounded;
    } else if (strength <= 0.7) {
      barColor = Colors.orange;
      label = 'Parolă medie';
      icon = Icons.check_circle_outline;
    } else {
      barColor = Colors.green;
      label = 'Parolă puternică';
      icon = Icons.verified;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: strength == 0
                ? 0.02
                : (score >= 4 ? 1.0 : strength), // când e verde, bara e plină
            minHeight: 10,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(icon, size: 18, color: barColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: barColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

