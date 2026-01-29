import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bubble_overlay.dart';
import '../models/expense_entry.dart';
import '../services/bubble_manager.dart';
import '../services/database_helper.dart';
import 'account_management_screen.dart';
import 'all_transactions_screen.dart';
import 'analysis_tab.dart';
import 'budgets_tab.dart';
import 'settings_tab.dart';

/// Redesigned HomePage with Light Theme Material 3 Design
class HomePageRedesign extends StatefulWidget {
  const HomePageRedesign({super.key});

  @override
  State<HomePageRedesign> createState() => _HomePageRedesignState();
}

class _HomePageRedesignState extends State<HomePageRedesign>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  int _selectedNavIndex = 0;
  final BubbleManager _bubbleManager = BubbleManager();
  
  // Color constants
  static const Color primaryTeal = Color(0xFF2B7A91);
  static const Color surfaceLight = Color(0xFFF8FAFB);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textMedium = Color(0xFF6B7280);
  static const Color expenseRed = Color(0xFFEF4444);
  static const Color incomeGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize bubble manager
    _bubbleManager.initialize().then((_) {
      debugPrint('BubbleManager initialized on app startup');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        // App is backgrounded - show the bubble for quick access
        _bubbleManager.showBubble();
        debugPrint('=== APP PAUSED ===\nBubble shown on homescreen\n===============\n');
      case AppLifecycleState.resumed:
        // App is resumed - hide the bubble
        _bubbleManager.hideBubble();
        debugPrint('=== APP RESUMED ===\nBubble hidden\n================\n');
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Handle other states if needed
        break;
    }
  }

  void _openTransactionForm() {
    showDialog(
      context: context,
      builder: (context) => const TransactionBubbleForm(),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: _buildMainContent(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: primaryTeal.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
          shape: BoxShape.circle,
        ),
        child: FloatingActionButton(
          onPressed: _openTransactionForm,
          backgroundColor: primaryTeal,
          elevation: 6,
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: _selectedNavIndex == 0
          ? _buildDashboard()
          : _selectedNavIndex == 1
              ? const BudgetsTab()
              : _selectedNavIndex == 2
                  ? const AnalysisTab()
                  : SettingsTab(
                      onDatabaseRestored: () {
                        if (mounted) setState(() {});
                      },
                    ),
    );
  }

  Widget _buildDashboard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper().getAllTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryTeal),
          );
        }

        final transactionMaps = snapshot.data ?? [];
        final entries =
            transactionMaps.map((map) => ExpenseEntry.fromMap(map)).toList();

        final totalIncome = entries
            .where((entry) => entry.isIncome)
            .fold<double>(0, (sum, entry) => sum + entry.amount);

        final totalExpense = entries
            .where((entry) => !entry.isIncome)
            .fold<double>(0, (sum, entry) => sum + entry.amount);

        final recentTransactions = entries.take(8).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),

              // Account Cards (Side-by-Side)
              _buildAccountCardsRow(),
              const SizedBox(height: 32),

              // Income/Expense Summary
              _buildSummaryRow(totalIncome, totalExpense),
              const SizedBox(height: 32),

              // Quick Insights
              _buildQuickInsights(),
              const SizedBox(height: 32),

              // Recent Transactions
              _buildRecentTransactions(recentTransactions, transactionMaps),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMedium,
              ),
            ),
            Text(
              'Your Finances',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
          ],
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: surfaceLight,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Icon(Icons.person, color: primaryTeal),
        ),
      ],
    );
  }

  Widget _buildAccountCardsRow() {
    return FutureBuilder<Map<String, double>>(
      future: Future.wait([
        DatabaseHelper().getTotalBalanceByType('Bank'),
        DatabaseHelper().getTotalBalanceByType('Cash'),
      ]).then((values) => {
        'Bank': values[0],
        'Cash': values[1],
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 100);
        }

        final data = snapshot.data ?? {'Bank': 0.0, 'Cash': 0.0};
        final bankBalance = data['Bank'] ?? 0.0;
        final cashBalance = data['Cash'] ?? 0.0;

        return Row(
          children: [
            Expanded(
              child: _buildAccountCard(
                title: 'Bank Balance',
                amount: bankBalance,
                icon: Icons.account_balance,
                color: const Color(0xFF0066CC),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountManagementScreen(),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAccountCard(
                title: 'Cash in Hand',
                amount: cashBalance,
                icon: Icons.payments,
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountManagementScreen(),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textMedium,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '€${amount.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(double income, double expense) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Income',
            income,
            incomeGreen,
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Expense',
            expense,
            expenseRed,
            Icons.trending_down,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '€${amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInsights() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper().getAllTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final transactions = snapshot.data ?? [];
        final expenseTransactions = transactions
            .where((t) => (t['isIncome'] as int) == 0)
            .toList();
        
        if (expenseTransactions.isEmpty) {
          return const SizedBox.shrink();
        }

        // Calculate average daily spending
        final totalExpense = expenseTransactions.fold<double>(
          0,
          (sum, t) => sum + ((t['amount'] as num).toDouble()),
        );
        final avgDaily = expenseTransactions.isNotEmpty
            ? totalExpense / (expenseTransactions.length > 1 ? 30 : 1)
            : 0.0;

        // Find highest expense category
        final categoryTotals = <String, double>{};
        for (var t in expenseTransactions) {
          final category = t['category'] as String? ?? 'Other';
          categoryTotals[category] = (categoryTotals[category] ?? 0) +
              ((t['amount'] as num).toDouble());
        }
        final topCategory = categoryTotals.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Insights',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInsightCard(
                    title: 'Avg Daily',
                    value: '€${avgDaily.toStringAsFixed(2)}',
                    icon: Icons.trending_down,
                    color: const Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInsightCard(
                    title: 'Top Spending',
                    value: topCategory,
                    icon: Icons.category,
                    color: const Color(0xFFE91E63),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(
    List<ExpenseEntry> transactions,
    List<Map<String, dynamic>> transactionMaps,
  ) {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'No transactions yet',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textMedium,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllTransactionsScreen(),
                  ),
                );
              },
              child: Text(
                'See all',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final transactionMap = transactionMaps[index];
            final accountName = transactionMap['account_name'] as String? ?? 'No Account';
            final isIncome = transaction.isIncome;
            final color = isIncome ? incomeGreen : expenseRed;

            return Container(
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              transaction.category,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: textMedium,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                accountName,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDate(transaction.date),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: textMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isIncome ? '+' : '-'}€${transaction.amount.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
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

  Widget _buildBottomNavigationBar() {
    const items = [
      ('Home', Icons.home),
      ('Budget', Icons.account_balance_wallet),
      ('Reports', Icons.bar_chart),
      ('Settings', Icons.settings),
    ];

    return Container(
      decoration: BoxDecoration(
        color: white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final (label, icon) = items[index];
            final isSelected = _selectedNavIndex == index;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedNavIndex = index;
                  _tabController.index = index;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? primaryTeal : textMedium,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? primaryTeal : textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
