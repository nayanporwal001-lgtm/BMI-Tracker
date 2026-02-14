import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class BmiResultScreen extends StatelessWidget {
  final double bmi;
  final bool isFirstTime;
  const BmiResultScreen({super.key, required this.bmi, this.isFirstTime = false});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String category = _getCategory(bmi);
    Color color = _getColor(bmi);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('Your Result'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        automaticallyImplyLeading: !isFirstTime,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category.toUpperCase(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              bmi.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 90,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _getMessage(category),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 80),
            ElevatedButton(
              onPressed: () {
                if (isFirstTime) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const DashboardScreen()),
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isFirstTime ? 'Go to Dashboard' : 'Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  String _getMessage(String category) {
    switch (category) {
      case 'Underweight': return 'You have a lower than normal body weight. You can eat a bit more.';
      case 'Normal': return 'You have a normal body weight. Good job!';
      case 'Overweight': return 'You have a higher than normal body weight. Try to exercise more.';
      case 'Obese': return 'You have a much higher than normal body weight. Please consult a health professional.';
      default: return '';
    }
  }
}
