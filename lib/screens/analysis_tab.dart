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
  
  // New: MoM and Top 5 expenses data
  Map<String, dynamic> _momData = {};
  List<Map<String, dynamic>> _top5Expenses = [];
  
  // Filter state variables
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String? _selectedCategory;
  List<String> _allCategories = [];
  bool _hasActiveFilter = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadAnalytics();
  }

  /// Load all available categories for filter chips
  Future<void> _loadCategories() async {
    try {
      final categories = await _dbHelper.getAllCategories();
      setState(() {
        _allCategories = categories;
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch transactions (either filtered or all)
      final transactionMaps = _hasActiveFilter
          ? await _dbHelper.queryTransactionsFiltered(
              startDate: _filterStartDate,
              endDate: _filterEndDate,
              category: _selectedCategory,
            )
          : await _dbHelper.getAllTransactions();
      
      final transactions = transactionMaps
          .map((map) => ExpenseEntry.fromMap(map))
          .toList();
      
      // Fetch analytics data (using filtered methods)
      final hourly = _hasActiveFilter
          ? await _dbHelper.getSpendingByHourFiltered(
              startDate: _filterStartDate,
              endDate: _filterEndDate,
              category: _selectedCategory,
            )
          : await _dbHelper.getSpendingByHour();
      
      final categories = _hasActiveFilter
          ? await _dbHelper.getCategoryAnalysisFiltered(
              startDate: _filterStartDate,
              endDate: _filterEndDate,
              category: _selectedCategory,
            )
          : await _dbHelper.getCategoryAnalysis();
      
      final momData = _hasActiveFilter
          ? await _dbHelper.getMonthOverMonthComparisonFiltered(
              category: _selectedCategory,
            )
          : await _dbHelper.getMonthOverMonthComparison();
      
      final top5 = _hasActiveFilter
          ? await _dbHelper.getTop5ExpensesFiltered(
              startDate: _filterStartDate,
              endDate: _filterEndDate,
              category: _selectedCategory,
            )
          : await _dbHelper.getTop5Expenses();
      
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
        _momData = momData;
        _top5Expenses = top5;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        actions: [
          // Filter button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: GestureDetector(
                onTap: _showFilterBottomSheet,
                child: Stack(
                  children: [
                    const Icon(Icons.filter_list, color: Color(0xFF7C4DFF)),
                    // Red dot indicator if filter is active
                    if (_hasActiveFilter)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        color: const Color(0xFF7C4DFF),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========== ACTIVE FILTER INDICATOR ==========
              if (_hasActiveFilter)
                _buildActiveFilterIndicator(),
              if (_hasActiveFilter) const SizedBox(height: 16),

              // ========== SUMMARY SECTION ==========
              _buildSummarySection(),
              const SizedBox(height: 32),

              // ========== PIE CHART SECTION ==========
              _buildPieChartSection(),
              const SizedBox(height: 32),

              // ========== HOURLY SPENDING CHART ==========
              _buildHourlyChartSection(),
              const SizedBox(height: 32),

              // ========== TOP 5 EXPENSES ==========
              _buildTop5ExpensesSection(),
              const SizedBox(height: 32),

              // ========== RECENT TRANSACTIONS ==========
              _buildRecentTransactionsSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Show the filter bottom sheet
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  /// Build the filter bottom sheet widget
  Widget _buildFilterBottomSheet() {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  // Reset button
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Date Presets Section
              const Text(
                'Date Range',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Preset buttons
              Wrap(
                spacing: 8,
                children: [
                  _buildDatePresetButton('Today', _setFilterToday),
                  _buildDatePresetButton('This Week', _setFilterThisWeek),
                  _buildDatePresetButton('This Month', _setFilterThisMonth),
                  _buildDatePresetButton('Custom', _setFilterCustom),
                ],
              ),

              // Selected date range display
              if (_filterStartDate != null && _filterEndDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '${_filterStartDate!.day}/${_filterStartDate!.month}/${_filterStartDate!.year} - ${_filterEndDate!.day}/${_filterEndDate!.month}/${_filterEndDate!.year}',
                    style: const TextStyle(
                      color: Color(0xFF7C4DFF),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Category Section
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Category chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // "All" option
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = null;
                      });
                    },
                    backgroundColor: const Color(0xFF2E2E3E),
                    selectedColor: const Color(0xFF7C4DFF),
                    labelStyle: TextStyle(
                      color: _selectedCategory == null
                          ? Colors.white
                          : Colors.white,
                    ),
                  ),
                  // Individual categories
                  ..._allCategories.map((category) {
                    return FilterChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                        });
                      },
                      backgroundColor: const Color(0xFF2E2E3E),
                      selectedColor: const Color(0xFF7C4DFF),
                      labelStyle: const TextStyle(color: Colors.white),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 24),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _applyFilters,
                  child: const Text(
                    'Apply Filter',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Build date preset button
  Widget _buildDatePresetButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF7C4DFF)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF7C4DFF)),
      ),
    );
  }

  /// Set filter to today
  void _setFilterToday() {
    final now = DateTime.now();
    setState(() {
      _filterStartDate = DateTime(now.year, now.month, now.day);
      _filterEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
  }

  /// Set filter to this week
  void _setFilterThisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    setState(() {
      _filterStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      _filterEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
  }

  /// Set filter to this month
  void _setFilterThisMonth() {
    final now = DateTime.now();
    setState(() {
      _filterStartDate = DateTime(now.year, now.month, 1);
      _filterEndDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    });
  }

  /// Set custom date filter (shows date picker)
  void _setFilterCustom() async {
    final startDate = await showDatePicker(
      context: context,
      initialDate: _filterStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (startDate != null && mounted) {
      final endDate = await showDatePicker(
        context: context,
        initialDate: _filterEndDate ?? DateTime.now(),
        firstDate: startDate,
        lastDate: DateTime.now(),
      );

      if (endDate != null && mounted) {
        setState(() {
          _filterStartDate = startDate;
          _filterEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        });
      }
    }
  }

  /// Reset all filters
  void _resetFilters() {
    setState(() {
      _filterStartDate = null;
      _filterEndDate = null;
      _selectedCategory = null;
      _hasActiveFilter = false;
    });
    Navigator.pop(context);
    _loadAnalytics();
  }

  /// Apply filters and refresh data
  void _applyFilters() {
    setState(() {
      _hasActiveFilter = (_filterStartDate != null && _filterEndDate != null) ||
          (_selectedCategory != null && _selectedCategory!.isNotEmpty);
    });
    Navigator.pop(context);
    _loadAnalytics();
  }

  /// Build active filter indicator badge
  Widget _buildActiveFilterIndicator() {
    List<String> filterLabels = [];

    if (_filterStartDate != null && _filterEndDate != null) {
      final start = _filterStartDate!;
      final end = _filterEndDate!;
      filterLabels.add(
        '${start.day}/${start.month} - ${end.day}/${end.month}',
      );
    }

    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filterLabels.add(_selectedCategory!);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF7C4DFF).withOpacity(0.2),
        border: Border.all(color: const Color(0xFF7C4DFF), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_list, color: Color(0xFF7C4DFF), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filtered: ${filterLabels.join(', ')}',
              style: const TextStyle(
                color: Color(0xFF7C4DFF),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _resetFilters,
            child: const Icon(Icons.close, color: Color(0xFF7C4DFF), size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final balance = _totalIncome - _totalExpense;
    final incomePercentChange = _momData['income_percent_change'] as double? ?? 0.0;
    final expensePercentChange = _momData['expense_percent_change'] as double? ?? 0.0;
    
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
                momPercentChange: incomePercentChange,
                isMomPositive: incomePercentChange >= 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Expense',
                amount: _totalExpense,
                color: Colors.redAccent,
                icon: Icons.arrow_upward,
                momPercentChange: expensePercentChange,
                isMomPositive: expensePercentChange <= 0, // Lower expenses is good
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

  Widget _buildTop5ExpensesSection() {
    if (_top5Expenses.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No expense data yet.\nAdd transactions to see top expenses.',
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
                const Icon(Icons.trending_up, color: Color(0xFF7C4DFF)),
                const SizedBox(width: 8),
                Text(
                  'Top 5 Expenses',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._top5Expenses.asMap().entries.map((entry) {
              final index = entry.key;
              final expense = entry.value;
              final title = expense['title'] as String;
              final amount = ((expense['amount'] ?? 0) as num).toDouble();
              final category = expense['category'] as String;
              final dateStr = expense['date'] as String;
              
              // Parse date
              final date = DateTime.tryParse(dateStr) ?? DateTime.now();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Rank badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C4DFF).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7C4DFF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Category icon + title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            category,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '€${amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _formatDate(date),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
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
  final double? momPercentChange;
  final bool? isMomPositive;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    this.momPercentChange,
    this.isMomPositive,
  });

  @override
  Widget build(BuildContext context) {
    final hasMoM = momPercentChange != null && momPercentChange != 0.0;
    final momColor = isMomPositive == true ? Colors.greenAccent : Colors.redAccent;
    final momArrow = (momPercentChange ?? 0) >= 0 
        ? Icons.arrow_upward 
        : Icons.arrow_downward;
    
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
          // MoM percentage indicator
          if (hasMoM)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    momArrow,
                    color: momColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${momPercentChange!.abs().toStringAsFixed(1)}% vs last month',
                    style: TextStyle(
                      color: momColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
