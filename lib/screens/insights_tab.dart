import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../services/database_helper.dart';

class InsightsTab extends StatefulWidget {
  const InsightsTab({super.key});

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> {
  int touchedIndex = -1;

  // Vibrant colors for categories
  final List<Color> categoryColors = [
    const Color(0xFFFF6B9D), // Pink
    const Color(0xFF4ECDC4), // Teal
    const Color(0xFFFFA07A), // Light Salmon
    const Color(0xFF9B59B6), // Purple
    const Color(0xFF3498DB), // Blue
    const Color(0xFFE74C3C), // Red
    const Color(0xFFF39C12), // Orange
    const Color(0xFF1ABC9C), // Turquoise
    const Color(0xFFE67E22), // Carrot
    const Color(0xFF16A085), // Green Sea
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Insights',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Visualize your spending patterns',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              _buildCategoryPieChart(),
              const SizedBox(height: 32),
              _buildDailyLineChart(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper().getCategoryTotals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 300,
            child: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        final categoryData = snapshot.data ?? [];

        if (categoryData.isEmpty) {
          return Container(
            height: 300,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No expense data to display\nAdd some transactions to see insights!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final totalExpenses = categoryData.fold<double>(
          0,
          (sum, item) => sum + (item['total'] as num).toDouble(),
        );

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1E1E2E),
                Color(0xFF2A2A3E),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.pie_chart, color: Color(0xFF7C4DFF)),
                  const SizedBox(width: 8),
                  const Text(
                    'Spending by Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Total: €${totalExpenses.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 220,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                touchedIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: List.generate(categoryData.length, (i) {
                            final isTouched = i == touchedIndex;
                            final fontSize = isTouched ? 16.0 : 12.0;
                            final radius = isTouched ? 65.0 : 55.0;
                            final amount = (categoryData[i]['total'] as num).toDouble();
                            final percentage = (amount / totalExpenses * 100);

                            return PieChartSectionData(
                              color: categoryColors[i % categoryColors.length],
                              value: amount,
                              title: '${percentage.toStringAsFixed(1)}%',
                              radius: radius,
                              titleStyle: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              badgeWidget: isTouched
                                  ? Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '€${amount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                              badgePositionPercentageOffset: 1.3,
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          math.min(categoryData.length, 5),
                          (i) {
                            final amount = (categoryData[i]['total'] as num).toDouble();
                            final percentage = (amount / totalExpenses * 100);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: categoryColors[i % categoryColors.length],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          categoryData[i]['category'] as String,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '€${amount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyLineChart() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper().getDailyTotals(7),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 300,
            child: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        final dailyData = snapshot.data ?? [];

        if (dailyData.isEmpty) {
          return Container(
            height: 300,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No transaction history yet\nStart tracking to see trends!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        // Fill in missing days with 0 values
        final now = DateTime.now();
        final filledData = <Map<String, dynamic>>[];
        for (int i = 6; i >= 0; i--) {
          final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
          final dateStr = date.toIso8601String().split('T')[0];
          final existing = dailyData.firstWhere(
            (d) => (d['day'] as String).startsWith(dateStr),
            orElse: () => {'day': dateStr, 'expenses': 0.0, 'income': 0.0},
          );
          filledData.add({
            'day': dateStr,
            'expenses': (existing['expenses'] ?? 0.0) as num,
            'income': (existing['income'] ?? 0.0) as num,
          });
        }

        final maxY = filledData.fold<double>(
          0,
          (max, item) {
            final expenseVal = (item['expenses'] as num).toDouble();
            final incomeVal = (item['income'] as num).toDouble();
            return math.max(max, math.max(expenseVal, incomeVal));
          },
        );

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1E1E2E),
                Color(0xFF2A2A3E),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.show_chart, color: Color(0xFF4ECDC4)),
                  const SizedBox(width: 8),
                  const Text(
                    '7-Day Spending Trend',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            if (value.toInt() < 0 || value.toInt() >= filledData.length) {
                              return const Text('');
                            }
                            final date = DateTime.parse(filledData[value.toInt()]['day'] as String);
                            final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                dayNames[(date.weekday - 1) % 7],
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: maxY > 0 ? maxY / 4 : 1,
                          reservedSize: 42,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Text(
                              '€${value.toInt()}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (filledData.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY > 0 ? maxY * 1.2 : 100,
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => Colors.black87,
                        tooltipRoundedRadius: 8,
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            final flSpot = barSpot;
                            return LineTooltipItem(
                              '€${flSpot.y.toStringAsFixed(2)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      // Expenses line
                      LineChartBarData(
                        spots: List.generate(
                          filledData.length,
                          (i) => FlSpot(
                            i.toDouble(),
                            (filledData[i]['expenses'] as num).toDouble(),
                          ),
                        ),
                        isCurved: true,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE74C3C), Color(0xFFFFA07A)],
                        ),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.redAccent,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFE74C3C).withOpacity(0.3),
                              const Color(0xFFE74C3C).withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      // Income line
                      LineChartBarData(
                        spots: List.generate(
                          filledData.length,
                          (i) => FlSpot(
                            i.toDouble(),
                            (filledData[i]['income'] as num).toDouble(),
                          ),
                        ),
                        isCurved: true,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4ECDC4), Color(0xFF1ABC9C)],
                        ),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.greenAccent,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF4ECDC4).withOpacity(0.3),
                              const Color(0xFF4ECDC4).withOpacity(0.0),
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Expenses', const Color(0xFFE74C3C)),
                  const SizedBox(width: 24),
                  _buildLegendItem('Income', const Color(0xFF4ECDC4)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}
