import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_helper.dart';
import '../models/expense_entry.dart';

/// Budgets Tab - Shows overall budget and category-wise budget breakdown
class BudgetsTab extends StatefulWidget {
  const BudgetsTab({super.key});

  @override
  State<BudgetsTab> createState() => _BudgetsTabState();
}

class _BudgetsTabState extends State<BudgetsTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  // Colors
  static const Color primaryTeal = Color(0xFF2B7A91);
  static const Color surfaceLight = Color(0xFFF8FAFB);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textMedium = Color(0xFF6B7280);
  static const Color expenseRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF97316);

  bool _isLoading = true;
  double _totalBudget = 5000.0;
  double _totalSpent = 0;
  List<Map<String, dynamic>> _categoryBudgets = [];

  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    setState(() => _isLoading = true);

    try {
      // Get monthly budget from database
      final monthlyBudget = await _dbHelper.getMonthlyBudget();
      
      // Get expenses from current month
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final transactionMaps = await _dbHelper.getAllTransactions();
      final transactions = transactionMaps
          .map((map) => ExpenseEntry.fromMap(map))
          .toList();

      // Filter for current month and expenses only
      final currentMonthExpenses = transactions
          .where((tx) =>
              !tx.isIncome &&
              tx.date.isAfter(startOfMonth) &&
              tx.date.isBefore(endOfMonth))
          .toList();

      // Group by category
      final categoryMap = <String, double>{};
      double totalSpent = 0;

      for (final expense in currentMonthExpenses) {
        categoryMap[expense.category] =
            (categoryMap[expense.category] ?? 0) + expense.amount;
        totalSpent += expense.amount;
      }

      // Load category budgets from database
      final dbBudgets = await _dbHelper.getAllCategoryBudgets();
      final budgets = <Map<String, dynamic>>[];

      for (final dbBudget in dbBudgets) {
        final category = dbBudget['category'] as String;
        final budgetAmount = (dbBudget['budget_amount'] as num).toDouble();
        final spent = categoryMap[category] ?? 0.0;
        
        budgets.add({
          'category': category,
          'budget': budgetAmount,
          'spent': spent,
          'percentage': budgetAmount > 0 ? (spent / budgetAmount * 100) : 0,
        });
      }

      setState(() {
        _totalBudget = monthlyBudget;
        _totalSpent = totalSpent;
        _categoryBudgets = budgets;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading budget data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryTeal),
      );
    }

    final budgetPercentage =
        (_totalSpent / _totalBudget * 100).clamp(0.0, 100.0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budget'),
        backgroundColor: white,
        elevation: 0,
      ),
      backgroundColor: white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Budget Donut Chart
              _buildOverallBudgetCard(budgetPercentage),
              const SizedBox(height: 32),

              // Category Budgets Section
              _buildCategoryBudgetsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallBudgetCard(double percentage) {
    return Container(
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Monthly Budget',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              IconButton(
                onPressed: () => _showEditMonthlyBudgetDialog(),
                icon: const Icon(Icons.edit, size: 20, color: primaryTeal),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Donut Chart
                PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        color: primaryTeal,
                        value: percentage,
                        title: '${percentage.toStringAsFixed(0)}%',
                        radius: 60,
                        titleStyle: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        color: surfaceLight,
                        value: 100 - percentage,
                        title: '',
                        radius: 60,
                      ),
                    ],
                    centerSpaceRadius: 40,
                    sectionsSpace: 0,
                  ),
                ),
                // Center text
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Spent',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: textMedium,
                      ),
                    ),
                    Text(
                      '€${_totalSpent.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'Budget',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: textMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '€${_totalBudget.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[200],
              ),
              Column(
                children: [
                  Text(
                    'Remaining',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: textMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '€${(_totalBudget - _totalSpent).toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: percentage > 80 ? expenseRed : primaryTeal,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (percentage > 100)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: expenseRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_rounded, color: expenseRed, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'You have exceeded your budget',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: expenseRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Category Budgets',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddCategoryBudgetDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: GoogleFonts.poppins(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _categoryBudgets.isEmpty
            ? Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.category, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'No category budgets set',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: textMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap Add to create your first budget',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categoryBudgets.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
            final budget = _categoryBudgets[index];
            final percentage = (budget['percentage'] as double).clamp(0, 100);
            final isOverBudget = percentage > 100;
            final progressColor = percentage > 80
                ? warningOrange
                : percentage > 50
                    ? primaryTeal
                    : Colors.green;

            return Container(
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        budget['category'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: progressColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditCategoryBudgetDialog(
                                  budget['category'] as String,
                                  budget['budget'] as double,
                                );
                              } else if (value == 'delete') {
                                _deleteCategoryBudget(budget['category'] as String);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 18, color: expenseRed),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: expenseRed)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: (percentage / 100).clamp(0, 1),
                      backgroundColor: surfaceLight,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '€${(budget['spent'] as double).toStringAsFixed(2)} spent',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: textMedium,
                        ),
                      ),
                      Text(
                        '€${((budget['budget'] as double) - (budget['spent'] as double)).toStringAsFixed(2)} left',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOverBudget ? expenseRed : primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
  void _showEditMonthlyBudgetDialog() {
    final controller = TextEditingController(text: _totalBudget.toStringAsFixed(2));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Monthly Budget',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Budget Amount (€)',
            prefixText: '€ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                await _dbHelper.setMonthlyBudget(amount);
                Navigator.pop(context);
                _loadBudgetData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Monthly budget updated')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryBudgetDialog() {
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add Category Budget',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Food, Transport',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Budget Amount (€)',
                prefixText: '€ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final category = categoryController.text.trim();
              final amount = double.tryParse(amountController.text);
              
              if (category.isNotEmpty && amount != null && amount > 0) {
                await _dbHelper.setCategoryBudget(category, amount);
                Navigator.pop(context);
                _loadBudgetData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Budget for $category added')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryBudgetDialog(String category, double currentBudget) {
    final controller = TextEditingController(text: currentBudget.toStringAsFixed(2));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit $category Budget',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Budget Amount (€)',
            prefixText: '€ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                await _dbHelper.setCategoryBudget(category, amount);
                Navigator.pop(context);
                _loadBudgetData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Budget for $category updated')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategoryBudget(String category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Budget?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text('Remove budget for $category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: expenseRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteCategoryBudget(category);
      _loadBudgetData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Budget for $category deleted')),
      );
    }
  }}
