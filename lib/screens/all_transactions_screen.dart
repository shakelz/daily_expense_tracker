import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_helper.dart';
import '../models/expense_entry.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  List<ExpenseEntry> _allTransactions = [];
  List<ExpenseEntry> _filteredTransactions = [];
  bool _isLoading = true;

  // Color constants
  static const primaryTeal = Color(0xFF2B7A91);
  static const textDark = Color(0xFF1F2937);
  static const textMedium = Color(0xFF6B7280);
  static const incomeGreen = Color(0xFF10B981);
  static const expenseRed = Color(0xFFEF4444);
  static const white = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactionMaps = await _dbHelper.getAllTransactions();
      final transactions = transactionMaps
          .map((map) => ExpenseEntry.fromMap(map))
          .toList();
      
      setState(() {
        _allTransactions = transactions;
        _filteredTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterTransactions(String query) {
    if (query.isEmpty) {
      setState(() => _filteredTransactions = _allTransactions);
    } else {
      setState(() {
        _filteredTransactions = _allTransactions
            .where((transaction) =>
                transaction.title.toLowerCase().contains(query.toLowerCase()) ||
                transaction.category.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        backgroundColor: white,
        foregroundColor: textDark,
        elevation: 1,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterTransactions,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                hintStyle: GoogleFonts.poppins(
                  color: textMedium,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search, color: primaryTeal),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Transaction count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _filteredTransactions.isEmpty
                  ? 'No transactions found'
                  : '${_filteredTransactions.length} transactions',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: textMedium,
              ),
            ),
          ),
          // Transactions list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryTeal),
                  )
                : _filteredTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions found',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: textMedium,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredTransactions.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final transaction = _filteredTransactions[index];
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
                                // Icon
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isIncome
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _formatDate(transaction.date),
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Amount
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
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final transactionDate =
        DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
