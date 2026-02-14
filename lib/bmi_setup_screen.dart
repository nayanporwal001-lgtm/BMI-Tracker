import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'bmi_result_screen.dart';

class BmiSetupScreen extends StatefulWidget {
  const BmiSetupScreen({super.key});

  @override
  State<BmiSetupScreen> createState() => _BmiSetupScreenState();
}

class _BmiSetupScreenState extends State<BmiSetupScreen> {
  final PageController _pageController = PageController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  int _currentPage = 0;
  bool _isCalculating = false;
  bool _isFirstTime = true;
  bool _isLoadingData = true;

  // Data to collect
  String? _gender;
  DateTime? _dob;
  
  // Weight related
  bool _isKg = true;
  int _selectedWeightKg = 60;
  int _selectedWeightLbs = 132;

  // Height related
  bool _isCm = true;
  int _selectedHeightCm = 170;
  int _selectedHeightIn = 67; 

  @override
  void initState() {
    super.initState();
    _checkUserData();
  }

  Future<void> _checkUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _database.child('users').child(user.uid).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        if (data.containsKey('gender') && data.containsKey('dob')) {
          setState(() {
            _gender = data['gender'];
            _dob = DateFormat('yyyy-MM-dd').parse(data['dob']);
            _isFirstTime = false;
            _isLoadingData = false;
          });
          // Skip first 2 pages (Gender and DOB)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _pageController.jumpToPage(2);
          });
          return;
        }
      }
    }
    setState(() => _isLoadingData = false);
  }

  void _nextPage() {
    int totalPages = 3;
    if (_currentPage < totalPages) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _calculateAndSaveBmi();
    }
  }

  void _previousPage() {
    int minPage = _isFirstTime ? 0 : 2;
    if (_currentPage > minPage) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _calculateAndSaveBmi() async {
    setState(() => _isCalculating = true);

    double finalWeightKg = _isKg ? _selectedWeightKg.toDouble() : _selectedWeightLbs * 0.453592;
    double finalHeightCm = _isCm ? _selectedHeightCm.toDouble() : _selectedHeightIn * 2.54;
    double finalHeightM = finalHeightCm / 100;
    double bmi = finalWeightKg / (finalHeightM * finalHeightM);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        await _database.child('users').child(user.uid).update({
          'gender': _gender,
          'dob': DateFormat('yyyy-MM-dd').format(_dob!),
          'lastWeight': finalWeightKg.toStringAsFixed(1),
          'lastHeight': finalHeightCm.toStringAsFixed(0),
          'lastBmi': bmi.toStringAsFixed(1),
        });

        await _database.child('users').child(user.uid).child('bmi_history').push().set({
          'bmi': double.parse(bmi.toStringAsFixed(1)),
          'weight': double.parse(finalWeightKg.toStringAsFixed(1)),
          'height': double.parse(finalHeightCm.toStringAsFixed(0)),
          'timestamp': timestamp,
          'unit': _isKg ? 'kg' : 'lbs',
        });

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => BmiResultScreen(
                bmi: bmi, 
                isFirstTime: _isFirstTime,
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFFF9933))));
    }

    return WillPopScope(
      onWillPop: () async {
        int minPage = _isFirstTime ? 0 : 2;
        if (_currentPage > minPage) {
          _previousPage();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
        appBar: AppBar(
          title: const Text(''),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: isDarkMode ? Colors.white : Colors.black,
          leading: _currentPage > (_isFirstTime ? 0 : 2)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _previousPage,
                )
              : null,
        ),
        body: _isCalculating 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9933)))
          : Column(
          children: [
            if (_isFirstTime) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                child: Stack(
                  children: [
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: 10,
                      width: MediaQuery.of(context).size.width * ((_currentPage + 1) / 4),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade700,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildGenderStep(),
                  _buildAgeStep(),
                  _buildWeightStep(),
                  _buildHeightStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContainer({required String title, required Widget child}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          Expanded(child: Center(child: child)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.white : Colors.black,
              foregroundColor: isDarkMode ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              _currentPage == 3 ? 'Calculate' : 'Next', 
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderStep() {
    return _buildStepContainer(
      title: 'Select Gender',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: ['Male', 'Female', 'Other'].map((gender) {
          bool isSelected = _gender == gender;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: InkWell(
              onTap: () => setState(() => _gender = gender),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.yellow.shade700 : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  color: isSelected ? Colors.yellow.shade50 : Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    gender,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAgeStep() {
    return _buildStepContainer(
      title: 'When is your birthday?',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_dob != null) ...[
            Text(
              '${_calculateAge(_dob!)} Years Old',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            _dob == null ? 'Not selected' : DateFormat('dd MMMM yyyy').format(_dob!),
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _dob ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _dob = picked);
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: const Text('Select Date'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              foregroundColor: Colors.blueAccent,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightStep() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return _buildStepContainer(
      title: 'What is your weight?',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isKg = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isKg ? (isDarkMode ? Colors.white : Colors.black) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'KG',
                      style: TextStyle(
                        color: _isKg ? (isDarkMode ? Colors.black : Colors.white) : (isDarkMode ? Colors.white : Colors.black),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isKg = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: !_isKg ? (isDarkMode ? Colors.white : Colors.black) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'LBS',
                      style: TextStyle(
                        color: !_isKg ? (isDarkMode ? Colors.black : Colors.white) : (isDarkMode ? Colors.white : Colors.black),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListWheelScrollView.useDelegate(
              itemExtent: 60,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                setState(() {
                  if (_isKg) {
                    _selectedWeightKg = index + 30;
                  } else {
                    _selectedWeightLbs = index + 60;
                  }
                });
              },
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  String text;
                  bool isSelected;
                  if (_isKg) {
                    int val = index + 30;
                    text = '$val kg';
                    isSelected = val == _selectedWeightKg;
                  } else {
                    int val = index + 60; 
                    text = '$val lbs';
                    isSelected = val == _selectedWeightLbs;
                  }
                  return Center(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: isSelected ? 32 : 24,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? (isDarkMode ? Colors.white : Colors.black) : Colors.grey.shade400,
                      ),
                    ),
                  );
                },
                childCount: _isKg ? 171 : 341,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightStep() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return _buildStepContainer(
      title: 'Your height',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isCm = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: !_isCm ? (isDarkMode ? Colors.white : Colors.black) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'IN',
                      style: TextStyle(
                        color: !_isCm ? (isDarkMode ? Colors.black : Colors.white) : (isDarkMode ? Colors.white : Colors.black),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isCm = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isCm ? (isDarkMode ? Colors.white : Colors.black) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'CM',
                      style: TextStyle(
                        color: _isCm ? (isDarkMode ? Colors.black : Colors.white) : (isDarkMode ? Colors.white : Colors.black),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListWheelScrollView.useDelegate(
              itemExtent: 60,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                setState(() {
                  if (_isCm) {
                    _selectedHeightCm = index + 100;
                  } else {
                    _selectedHeightIn = index + 40;
                  }
                });
              },
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  String text;
                  bool isSelected;
                  if (_isCm) {
                    int val = index + 100;
                    text = '$val cm';
                    isSelected = val == _selectedHeightCm;
                  } else {
                    int val = index + 40; 
                    text = '$val in';
                    isSelected = val == _selectedHeightIn;
                  }
                  return Center(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: isSelected ? 32 : 24,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? (isDarkMode ? Colors.white : Colors.black) : Colors.grey.shade400,
                      ),
                    ),
                  );
                },
                childCount: _isCm ? 151 : 61,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
