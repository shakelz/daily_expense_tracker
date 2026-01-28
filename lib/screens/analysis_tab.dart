import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_helper.dart';
import '../models/expense_entry.dart';

class AnalysisTab extends StatefulWidget {
  const AnalysisTab({super.key});

  @override
  State<AnalysisTab> createState() => _AnalysisTabState();
}

class _AnalysisTabState extends State<AnalysisTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  List<ExpenseEntry> _transactions = [];
  Map<int, double> _hourlySpending = {};
  List<Map<String, dynamic>> _categoryAnalysis = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch transactions
      final transactionMaps = await _dbHelper.getAllTransactions();
      final transactions = transactionMaps
          .map((map) => ExpenseEntry.fromMap(map))
          .toList();
      
      // Fetch analytics data
      final hourly = await _dbHelper.getSpendingByHour();
      final categories = await _dbHelper.getCategoryAnalysis();
      
      // Calculate totals
      double income = 0;
      double expense = 0;
      for (final tx in transactions) {
        if (tx.isIncome) {
          income += tx.amount;
        } else {
          expense += tx.amount;
        }
      }
      
      setState(() {
        _transactions = transactions.take(10).toList();
        _hourlySpending = hourly;
        _categoryAnalysis = categories;
        _totalIncome = income;
        _totalExpense = expense;
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
            // ========== SUMMARY SECTION ==========
            _buildSummarySection(),
            const SizedBox(height: 32),

            // ========== PIE CHART SECTION ==========
            _buildPieChartSection(),
            const SizedBox(height: 32),

            // ========== HOURLY SPENDING CHART ==========
            _buildHourlyChartSection(),
            const SizedBox(height: 32),

            // ========== RECENT TRANSACTIONS ==========
            _buildRecentTransactionsSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    final balance = _totalIncome - _totalExpense;
    
    return Column(
      children: [
        Text(
          'Financial Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF7C4DFF),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Income',
                amount: _totalIncome,
                color: Colors.greenAccent,
                icon: Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Expense',
                amount: _totalExpense,
                color: Colors.redAccent,
                icon: Icons.arrow_upward,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          title: 'Balance',
          amount: balance,
          color: balance >= 0 ? Colors.lightGreenAccent : Colors.orangeAccent,
          icon: Icons.wallet,
        ),
      ],
    );
  }

  Widget _buildPieChartSection() {
    if (_categoryAnalysis.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No spending data yet.\nAdd transactions to see category breakdown.',
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
                const Icon(Icons.pie_chart, color: Color(0xFF7C4DFF)),
                const SizedBox(width: 8),
                Text(
                  'Spending by Category',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildPieChart(),
            ),
            const SizedBox(height: 16),
            // Category legend
            ..._categoryAnalysis.map((category) {
              final name = category['category'] as String;
              final percentage = ((category['percentage'] ?? 0) as num).toDouble();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
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
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C4DFF),
                      ),
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

  Widget _buildPieChart() {
    final sections = _categoryAnalysis.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final amount = ((category['total_amount'] ?? 0) as num).toDouble();
      final percentage = ((category['percentage'] ?? 0) as num).toDouble();
      
      return PieChartSectionData(
        color: _getCategoryColor(category['category'] as String),
        value: percentage,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildHourlyChartSection() {
    if (_hourlySpending.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No hourly spending data yet.\nAdd transactions to see spending patterns.',
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
            width: 6,
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
                Text(
                  'Spending by Hour',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
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

  Widget _buildRecentTransactionsSection() {
    if (_transactions.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No transactions yet.',
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
                const Icon(Icons.history, color: Color(0xFF7C4DFF)),
                const SizedBox(width: 8),
                Text(
                  'Recent Transactions (Last 10)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._transactions.map((tx) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: tx.isIncome
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      child: Icon(
                        tx.isIncome
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: tx.isIncome ? Colors.greenAccent : Colors.redAccent,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${tx.category} • ${_formatDate(tx.date)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${tx.isIncome ? '+' : '-'}€${tx.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tx.isIncome ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 14,
                      ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
      'Custom': const Color(0xFF7C4DFF),
    };
    
    return colors[category] ?? const Color(0xFF7C4DFF);
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '€${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
