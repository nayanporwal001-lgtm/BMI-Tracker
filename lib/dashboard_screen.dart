import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'bmi_setup_screen.dart';
import 'login_screen.dart';
import 'weight_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<dynamic, dynamic>> _bmiHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBmiHistory();
  }

  Future<void> _fetchBmiHistory() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _database.child('users').child(user.uid).child('bmi_history').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final List<Map<dynamic, dynamic>> history = [];
        data.forEach((key, value) {
          history.add(value as Map<dynamic, dynamic>);
        });
        history.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
        setState(() {
          _bmiHistory = history;
          _isLoading = false;
        });
      } else {
        setState(() {
          _bmiHistory = [];
          _isLoading = false;
        });
      }
    }
  }

  void _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.show_chart),
          onPressed: () {
            if (_bmiHistory.length < 2) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add at least 2 records to see the graph')),
              );
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => WeightHistoryScreen(bmiHistory: _bmiHistory),
                ),
              );
            }
          },
        ),
        title: const Text('BMI Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          )
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9933)))
          : Stack(
              children: [
                _bmiHistory.isEmpty ? _buildEmptyState() : _buildHistoryList(),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const BmiSetupScreen()),
                        ).then((_) => _fetchBmiHistory());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 5,
                      ),
                      child: const Text('Update Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          const Text(
            'No BMI history yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap "Update Data" to calculate your BMI',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _bmiHistory.length,
      itemBuilder: (context, index) {
        final record = _bmiHistory[index];
        final bmi = (record['bmi'] as num).toDouble();
        final date = DateTime.fromMillisecondsSinceEpoch(record['timestamp'] as int);
        
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getBmiColor(bmi).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    bmi.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getBmiColor(bmi),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getBmiCategory(bmi),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy - hh:mm a').format(date),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${record['weight']} kg', style: const TextStyle(fontSize: 12)),
                    Text('${record['height']} cm', style: const TextStyle(fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  String _getBmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
}
