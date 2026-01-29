import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
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
  
  // Track selected date preset in filter dialog
  String? _selectedDatePreset;

  // Section-specific filter states
  String _top5Filter = 'top5'; // 'top5', 'top10', 'lowest5'
  String _sourceFilter = 'highest'; // 'highest', 'lowest'
  String _transactionSort = 'descending'; // 'ascending', 'descending'
  bool _showAllTransactions = false; // false = last 10, true = all

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
          color: Color(0xFF2B7A91),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        backgroundColor: const Color(0xFFFFFFFF),
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
                    const Icon(Icons.filter_list, color: Color(0xFF2B7A91)),
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
        color: const Color(0xFF2B7A91),
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

              // ========== SPENDING BY SOURCE ==========
              _buildSpendingBySourceSection(),
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
    // Reset the selected preset to match current filter state
    _updateSelectedPreset();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF8FAFB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, bottomSheetSetState) => _buildFilterBottomSheet(bottomSheetSetState),
      ),
    );
  }

  /// Determine which preset is currently selected based on filter dates
  void _updateSelectedPreset() {
    if (_filterStartDate == null || _filterEndDate == null) {
      _selectedDatePreset = null;
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final filterStart = DateTime(_filterStartDate!.year, _filterStartDate!.month, _filterStartDate!.day);
    
    // Check if it's today
    if (filterStart == today) {
      _selectedDatePreset = 'Today';
      return;
    }

    // Check if it's this week
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final filterWeekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
    if (filterStart == filterWeekStart) {
      _selectedDatePreset = 'This Week';
      return;
    }

    // Check if it's this month
    final monthStart = DateTime(now.year, now.month, 1);
    final filterMonthStart = DateTime(_filterStartDate!.year, _filterStartDate!.month, 1);
    if (filterMonthStart == monthStart) {
      _selectedDatePreset = 'This Month';
      return;
    }

    _selectedDatePreset = 'Custom';
  }

  /// Build the filter bottom sheet widget
  Widget _buildFilterBottomSheet(StateSetter bottomSheetSetState) {
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

              // Preset buttons with visual selection
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedDatePreset == 'Today' ? const Color(0xFF2B7A91) : Colors.grey[800],
                    ),
                    onPressed: () {
                      _setFilterToday();
                      Navigator.pop(context);
                    },
                    child: const Text('Today'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedDatePreset == 'This Week' ? const Color(0xFF2B7A91) : Colors.grey[800],
                    ),
                    onPressed: () {
                      _setFilterThisWeek();
                      Navigator.pop(context);
                    },
                    child: const Text('This Week'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedDatePreset == 'This Month' ? const Color(0xFF2B7A91) : Colors.grey[800],
                    ),
                    onPressed: () {
                      _setFilterThisMonth();
                      Navigator.pop(context);
                    },
                    child: const Text('This Month'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedDatePreset == 'Custom' ? const Color(0xFF2B7A91) : Colors.grey[800],
                    ),
                    onPressed: () async {
                      await _setFilterCustom();
                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text('Custom'),
                  ),
                ],
              ),

              // Selected date range display
              if (_filterStartDate != null && _filterEndDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '${_filterStartDate!.day}/${_filterStartDate!.month}/${_filterStartDate!.year} - ${_filterEndDate!.day}/${_filterEndDate!.month}/${_filterEndDate!.year}',
                    style: const TextStyle(
                      color: Color(0xFF2B7A91),
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
                  const Text(
                    'Note: Category filters are applied per section',
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B7A91),
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

  /// Set filter to today
  void _setFilterToday() {
    final now = DateTime.now();
    setState(() {
      _filterStartDate = DateTime(now.year, now.month, now.day);
      _filterEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      _selectedDatePreset = 'Today';
      _hasActiveFilter = true;
    });
    _loadAnalytics();
  }

  /// Set filter to this week
  void _setFilterThisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    setState(() {
      _filterStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      _filterEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      _selectedDatePreset = 'This Week';
      _hasActiveFilter = true;
    });
    _loadAnalytics();
  }

  /// Set filter to this month
  void _setFilterThisMonth() {
    final now = DateTime.now();
    setState(() {
      _filterStartDate = DateTime(now.year, now.month, 1);
      _filterEndDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      _selectedDatePreset = 'This Month';
      _hasActiveFilter = true;
    });
    _loadAnalytics();
  }

  /// Set custom date filter (shows date picker)
  Future<void> _setFilterCustom() async {
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
          _selectedDatePreset = 'Custom';
          _hasActiveFilter = true;
        });
        _loadAnalytics();
      }
    }
  }

  /// Reset all filters
  void _resetFilters() {
    if (!mounted) return;
    
    setState(() {
      _filterStartDate = null;
      _filterEndDate = null;
      _selectedCategory = null;
      _selectedDatePreset = null;
      _hasActiveFilter = false;
    });
    
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    if (mounted) {
      _loadAnalytics();
    }
  }

  /// Apply filters and refresh data
  void _applyFilters() {
    if (!mounted) return;
    
    setState(() {
      _hasActiveFilter = (_filterStartDate != null && _filterEndDate != null) ||
          (_selectedCategory != null && _selectedCategory!.isNotEmpty);
    });
    
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    if (mounted) {
      _loadAnalytics();
    }
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
        color: const Color(0xFF2B7A91).withOpacity(0.2),
        border: Border.all(color: const Color(0xFF2B7A91), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_list, color: Color(0xFF2B7A91), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filtered: ${filterLabels.join(', ')}',
              style: const TextStyle(
                color: Color(0xFF2B7A91),
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
            child: const Icon(Icons.close, color: Color(0xFF2B7A91), size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final incomePercentChange = _momData['income_percent_change'] as double? ?? 0.0;
    final expensePercentChange = _momData['expense_percent_change'] as double? ?? 0.0;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Financial Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2B7A91),
              ),
            ),
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.filter_list, color: Color(0xFF2B7A91)),
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
              onPressed: _showFilterBottomSheet,
            ),
          ],
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.pie_chart, color: Color(0xFF2B7A91)),
                    const SizedBox(width: 8),
                    Text(
                      'Spending by Category',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.filter_list, color: Color(0xFF2B7A91), size: 20),
                      if (_hasActiveFilter)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: _showFilterBottomSheet,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
                        color: Color(0xFF2B7A91),
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
    return FutureBuilder<Map<String, double>>(
      future: _getDynamicSpendingData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No spending data in selected period.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          );
        }

        final timeRangeType = _getTimeRangeType();
        final spendingData = snapshot.data!;
        final maxSpending = spendingData.values.isEmpty 
          ? 100.0 
          : spendingData.values.reduce((a, b) => a > b ? a : b);

        List<BarChartGroupData> barGroups = [];
        int index = 0;
        
        for (final entry in spendingData.entries) {
          barGroups.add(BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: const Color(0xFF2B7A91),
                width: 6,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2B7A91).withOpacity(0.7),
                    const Color(0xFF9C27B0),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ],
          ));
          index++;
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Color(0xFF2B7A91)),
                        const SizedBox(width: 8),
                        Text(
                          'Spending by ${_getTimeRangeLabel()}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Stack(
                        children: [
                          const Icon(Icons.filter_list, color: Color(0xFF2B7A91), size: 20),
                          if (_hasActiveFilter)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: _showFilterBottomSheet,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
                            final label = spendingData.keys.toList()[group.x];
                            return BarTooltipItem(
                              '$label\n€${rod.toY.toStringAsFixed(2)}',
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
                              final labels = spendingData.keys.toList();
                              int idx = value.toInt();
                              
                              // Show every nth label to avoid crowding
                              int interval = (labels.length / 6).ceil();
                              if (interval < 1) interval = 1;
                              
                              if (idx % interval == 0 && idx < labels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    labels[idx],
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
        },
      );
    }

  Widget _buildTop5ExpensesSection() {
    final filteredExpenses = _filterTopExpenses(_top5Expenses);
    
    if (filteredExpenses.isEmpty) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_up, color: Color(0xFF2B7A91)),
                    const SizedBox(width: 8),
                    Text(
                      'Top ${_top5Filter == 'top10' ? '10' : _top5Filter == 'lowest5' ? 'Lowest 5' : '5'} Expenses',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.filter_list, color: Color(0xFF2B7A91), size: 20),
                      if (_top5Filter != 'top5')
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: _showTop5FilterDialog,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...filteredExpenses.asMap().entries.map((entry) {
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
                        color: const Color(0xFF2B7A91).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B7A91),
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

  Widget _buildSpendingBySourceSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _hasActiveFilter
          ? _dbHelper.getSpendingBySourceFiltered(
              startDate: _filterStartDate,
              endDate: _filterEndDate,
            )
          : _dbHelper.getSpendingBySource(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF2B7A91)),
              ),
            ),
          );
        }

        var spendingBySource = snapshot.data ?? [];
        
        // Apply section-specific sorting
        spendingBySource = _sortSpendingBySource(spendingBySource);
        
        if (spendingBySource.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No spending data available.\nAdd transactions and accounts to see spending by source.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          );
        }

        // Calculate total for percentage calculation
        final totalSpending = spendingBySource.fold<double>(
          0,
          (sum, item) => sum + ((item['total_expense'] ?? 0) as num).toDouble(),
        );

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Color(0xFF2B7A91)),
                        const SizedBox(width: 8),
                        Text(
                          'Spending by Source',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Stack(
                        children: [
                          const Icon(Icons.filter_list, color: Color(0xFF2B7A91), size: 20),
                          if (_sourceFilter != 'highest')
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: _showSourceFilterDialog,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...spendingBySource.asMap().entries.map((entry) {
                  final source = entry.value;
                  final accountName = source['account_name'] as String? ?? 'Unknown Account';
                  final accountType = source['account_type'] as String? ?? 'Bank';
                  final totalExpense = ((source['total_expense'] ?? 0) as num).toDouble();
                  
                  final percentage = totalSpending > 0 ? (totalExpense / totalSpending * 100) : 0.0;
                  
                  // Color based on account type
                  final accountColor = accountType == 'Bank' 
                      ? const Color(0xFF0066CC) 
                      : const Color(0xFF10B981);
                  
                  // Icon based on account type
                  final accountIcon = accountType == 'Bank' 
                      ? Icons.account_balance 
                      : Icons.wallet;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Account icon
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: accountColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                accountIcon,
                                color: accountColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Account name
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    accountName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    accountType,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Amount
                            Text(
                              '€${totalExpense.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            minHeight: 6,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(accountColor),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${percentage.toStringAsFixed(1)}% of total expenses',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentTransactionsSection() {
    final sortedTransactions = _sortTransactions(_transactions);
    
    if (sortedTransactions.isEmpty) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: Color(0xFF2B7A91)),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Transactions${_showAllTransactions ? '' : ' (Last 10)'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.filter_list, color: Color(0xFF2B7A91), size: 20),
                      if (_transactionSort != 'descending' || _showAllTransactions)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: _showTransactionFilterDialog,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...sortedTransactions.map((tx) {
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

  // ============ HELPER METHODS FOR DYNAMIC FILTERING ============

  /// Determine the time range type based on selected dates
  String _getTimeRangeType() {
    if (!_hasActiveFilter || _filterStartDate == null || _filterEndDate == null) {
      return 'month'; // Default to monthly
    }
    
    final difference = _filterEndDate!.difference(_filterStartDate!).inDays;
    
    if (difference == 0) {
      return 'hourly'; // Single day
    } else if (difference <= 7) {
      return 'daily'; // Week or less
    } else if (difference <= 31) {
      return 'daily'; // Month or less
    } else {
      return 'monthly'; // More than a month
    }
  }

  /// Get dynamic spending data based on time range
  Future<Map<String, double>> _getDynamicSpendingData() async {
    final timeRangeType = _getTimeRangeType();
    final startDate = _filterStartDate;
    final endDate = _filterEndDate;
    
    if (timeRangeType == 'hourly') {
      final hourlyMap = await _dbHelper.getSpendingByHourFiltered(
        startDate: startDate,
        endDate: endDate,
      );
      // Convert int keys (hours) to string
      return hourlyMap.map((hour, amount) => MapEntry(hour.toString(), amount));
    } else if (timeRangeType == 'daily') {
      return await _dbHelper.getSpendingByDayFiltered(
        startDate: startDate,
        endDate: endDate,
      );
    } else {
      // monthly
      return await _dbHelper.getSpendingByMonthFiltered(
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  /// Get time range label for display
  String _getTimeRangeLabel() {
    final timeType = _getTimeRangeType();
    if (timeType == 'hourly') {
      return 'Hourly';
    } else if (timeType == 'daily') {
      return 'Daily';
    } else {
      return 'Monthly';
    }
  }

  /// Sort and limit top expenses based on filter
  List<Map<String, dynamic>> _filterTopExpenses(List<Map<String, dynamic>> expenses) {
    List<Map<String, dynamic>> sorted = List.from(expenses);
    
    // Sort by amount descending for top, ascending for lowest
    if (_top5Filter == 'lowest5') {
      sorted.sort((a, b) => ((a['amount'] ?? 0) as num)
          .compareTo((b['amount'] ?? 0) as num));
      return sorted.take(5).toList();
    } else if (_top5Filter == 'top10') {
      sorted.sort((a, b) => ((b['amount'] ?? 0) as num)
          .compareTo((a['amount'] ?? 0) as num));
      return sorted.take(10).toList();
    } else {
      // top5 (default)
      sorted.sort((a, b) => ((b['amount'] ?? 0) as num)
          .compareTo((a['amount'] ?? 0) as num));
      return sorted.take(5).toList();
    }
  }

  /// Sort spending by source
  List<Map<String, dynamic>> _sortSpendingBySource(
    List<Map<String, dynamic>> spending,
  ) {
    List<Map<String, dynamic>> sorted = List.from(spending);
    
    if (_sourceFilter == 'lowest') {
      sorted.sort((a, b) => ((a['total_expense'] ?? 0) as num)
          .compareTo((b['total_expense'] ?? 0) as num));
    } else {
      // highest (default)
      sorted.sort((a, b) => ((b['total_expense'] ?? 0) as num)
          .compareTo((a['total_expense'] ?? 0) as num));
    }
    
    return sorted;
  }

  /// Sort and limit transactions
  List<ExpenseEntry> _sortTransactions(List<ExpenseEntry> txs) {
    List<ExpenseEntry> sorted = List.from(txs);
    
    if (_transactionSort == 'ascending') {
      sorted.sort((a, b) => a.amount.compareTo(b.amount));
    } else {
      // descending (default - by date)
      sorted.sort((a, b) => b.date.compareTo(a.date));
    }
    
    if (!_showAllTransactions) {
      return sorted.take(10).toList();
    }
    return sorted;
  }

  // ============ DIALOG METHODS FOR SECTION FILTERS ============

  /// Show Top 5 Expenses filter dialog
  void _showTop5FilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1B23),
          title: const Text(
            'Filter Top Expenses',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption(
                label: 'Top 5 Expenses',
                value: 'top5',
                groupValue: _top5Filter,
                onChanged: (value) {
                  setState(() => _top5Filter = value ?? 'top5');
                  Navigator.pop(context);
                },
              ),
              _buildFilterOption(
                label: 'Top 10 Expenses',
                value: 'top10',
                groupValue: _top5Filter,
                onChanged: (value) {
                  setState(() => _top5Filter = value ?? 'top10');
                  Navigator.pop(context);
                },
              ),
              _buildFilterOption(
                label: 'Lowest 5 Expenses',
                value: 'lowest5',
                groupValue: _top5Filter,
                onChanged: (value) {
                  setState(() => _top5Filter = value ?? 'lowest5');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show Spending by Source filter dialog
  void _showSourceFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1B23),
          title: const Text(
            'Filter by Source',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption(
                label: 'Highest Spending',
                value: 'highest',
                groupValue: _sourceFilter,
                onChanged: (value) {
                  setState(() => _sourceFilter = value ?? 'highest');
                  Navigator.pop(context);
                },
              ),
              _buildFilterOption(
                label: 'Lowest Spending',
                value: 'lowest',
                groupValue: _sourceFilter,
                onChanged: (value) {
                  setState(() => _sourceFilter = value ?? 'lowest');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show Recent Transactions filter dialog
  void _showTransactionFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1B23),
          title: const Text(
            'Filter Transactions',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort By:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildFilterOption(
                label: 'Most Recent',
                value: 'descending',
                groupValue: _transactionSort,
                onChanged: (value) {
                  setState(() => _transactionSort = value ?? 'descending');
                },
              ),
              _buildFilterOption(
                label: 'Oldest First',
                value: 'ascending',
                groupValue: _transactionSort,
                onChanged: (value) {
                  setState(() => _transactionSort = value ?? 'ascending');
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Show:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Show All Transactions', style: TextStyle(color: Colors.white, fontSize: 14)),
                value: _showAllTransactions,
                activeColor: const Color(0xFF2B7A91),
                onChanged: (value) {
                  setState(() => _showAllTransactions = value ?? false);
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done', style: TextStyle(color: Color(0xFF2B7A91))),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build filter radio option widget
  Widget _buildFilterOption({
    required String label,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      value: value,
      groupValue: groupValue,
      activeColor: const Color(0xFF2B7A91),
      onChanged: onChanged,
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
      'Custom': const Color(0xFF2B7A91),
    };
    
    return colors[category] ?? const Color(0xFF2B7A91);
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
        color: const Color(0xFFF8FAFB),
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
