import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_helper.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  Map<int, double> _hourlySpending = {};
  List<Map<String, dynamic>> _categoryAnalysis = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      final hourly = await _dbHelper.getSpendingByHour();
      final categories = await _dbHelper.getCategoryAnalysis();
      
      setState(() {
        _hourlySpending = hourly;
        _categoryAnalysis = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF7C4DFF),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      color: const Color(0xFF7C4DFF),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Detailed Analytics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7C4DFF),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Optimize your Berlin budget with data-driven insights',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // Spending by Hour Chart
            _buildHourlySpendingChart(),
            const SizedBox(height: 32),

            // Category Analysis List
            _buildCategoryAnalysis(),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlySpendingChart() {
    if (_hourlySpending.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No hourly spending data available yet.\nAdd transactions to see your spending patterns.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // Fill missing hours with 0
    final completeData = <int, double>{};
    for (int hour = 0; hour < 24; hour++) {
      completeData[hour] = _hourlySpending[hour] ?? 0.0;
    }

    final maxSpending = completeData.values.reduce((a, b) => a > b ? a : b);
    final barGroups = completeData.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: const Color(0xFF7C4DFF),
            width: 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF7C4DFF).withOpacity(0.7),
                const Color(0xFF9C27B0),
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ],
      );
    }).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFF7C4DFF)),
                const SizedBox(width: 8),
                const Text(
                  'Spending by Hour',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxSpending > 0 ? maxSpending * 1.2 : 100,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF2A2A3E),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${group.x}:00\n€${rod.toY.toStringAsFixed(2)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
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
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 3 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${value.toInt()}h',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '€${value.toInt()}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxSpending > 0 ? maxSpending / 5 : 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryAnalysis() {
    if (_categoryAnalysis.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No category data available yet.\nStart tracking expenses to see category breakdown.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category, color: Color(0xFF7C4DFF)),
                const SizedBox(width: 8),
                const Text(
                  'Category Breakdown (Last 30 Days)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._categoryAnalysis.map((category) {
              final name = category['category'] as String;
              final total = ((category['total_amount'] ?? 0) as num).toDouble();
              final percentage = ((category['percentage'] ?? 0) as num).toDouble();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(name),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '€${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C4DFF),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C4DFF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7C4DFF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getCategoryColor(name),
                      ),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Food': const Color(0xFFFF6B6B),
      'Rent': const Color(0xFF4ECDC4),
      'Transport': const Color(0xFFFFE66D),
      'Shopping': const Color(0xFF95E1D3),
      'Utilities': const Color(0xFF9C88FF),
      'Salary': const Color(0xFF2ECC71),
      'Freelance': const Color(0xFF3498DB),
      'Investment': const Color(0xFFF39C12),
      'Gift': const Color(0xFFE91E63),
    };
    
    return colors[category] ?? const Color(0xFF7C4DFF);
  }
}
