import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class WeightHistoryScreen extends StatelessWidget {
  final List<Map<dynamic, dynamic>> bmiHistory;

  const WeightHistoryScreen({super.key, required this.bmiHistory});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Colors.yellow.shade700;

    // Filter and prepare data
    final sortedHistory = List<Map<dynamic, dynamic>>.from(bmiHistory)
      ..sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));

    if (sortedHistory.length < 2) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
        appBar: AppBar(
          title: const Text('Weight History'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: isDarkMode ? Colors.white : Colors.black,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.insights, size: 64, color: Colors.grey.withOpacity(0.5)),
              const SizedBox(height: 16),
              const Text(
                'Add at least 2 records to see the trend',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('Weight Progress', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: primaryColor),
                  const SizedBox(width: 12),
                  const Text(
                    'Weight Trend (kg)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedHistory.length) {
                            final date = DateTime.fromMillisecondsSinceEpoch(
                                sortedHistory[index]['timestamp'] as int);
                            return Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                DateFormat('dd/MM').format(date),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDarkMode ? Colors.grey : Colors.black54,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, 
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDarkMode ? Colors.grey : Colors.black54,
                            ),
                          );
                        }
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: isDarkMode ? Colors.grey[800]! : Colors.white,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y} kg',
                            const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: sortedHistory.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          (entry.value['weight'] as num).toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: primaryColor,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 6,
                          color: Colors.white,
                          strokeWidth: 3,
                          strokeColor: primaryColor,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.3),
                            primaryColor.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                const Text(
                  'Weight (kg) over time',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
