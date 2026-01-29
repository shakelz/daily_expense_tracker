import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/expense_entry.dart';
import 'services/database_helper.dart';

/// Transaction form that can appear as a popup or floating form
class TransactionBubbleForm extends StatefulWidget {
  final bool showAsSheet;
  
  const TransactionBubbleForm({
    super.key,
    this.showAsSheet = false,
  });

  @override
  State<TransactionBubbleForm> createState() => _TransactionBubbleFormState();
}

class _TransactionBubbleFormState extends State<TransactionBubbleForm> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isIncome = false;
  String _selectedCategory = 'Food';

  List<String> get _incomeCategories =>
      ['Salary', 'Freelance', 'Investment', 'Gift', 'Other'];

  List<String> get _expenseCategories =>
      ['Food', 'Rent', 'Transport', 'Shopping', 'Utilities', 'Other'];

  List<String> get _currentCategories =>
      _isIncome ? _incomeCategories : _expenseCategories;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _expenseCategories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _toggleTransactionType() {
    setState(() {
      _isIncome = !_isIncome;
      _selectedCategory = _currentCategories.first;
    });
  }

  Future<void> _handleSave() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      _showErrorSnackbar('Please fill in all fields');
      return;
    }

    try {
      final amount = double.parse(_amountController.text);
      final transaction = ExpenseEntry(
        id: null,
        title: _titleController.text,
        amount: amount,
        category: _selectedCategory,
        date: DateTime.now(),
        isIncome: _isIncome,
      );

      await DatabaseHelper().insertTransaction(transaction);

      debugPrint(
        '=== TRANSACTION ADDED FROM BUBBLE ===\n'
        'Title: ${transaction.title}\n'
        'Amount: €${transaction.amount.toStringAsFixed(2)}\n'
        'Category: ${transaction.category}\n'
        'Type: ${_isIncome ? 'Income' : 'Expense'}\n'
        '====================================\n',
      );

      _showSuccessSnackbar('Transaction added successfully!');
      _clearForm();
      
      // Check if widget is still mounted before navigating
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackbar('Invalid amount. Please enter a valid number.');
    }
  }

  void _clearForm() {
    _titleController.clear();
    _amountController.clear();
    _isIncome = false;
    _selectedCategory = _expenseCategories.first;
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF2B7A91);
    const Color darkBg = Color(0xFF0F1115);
    const Color surfaceColor = Color(0xFF1A1B23);

    return Dialog(
      backgroundColor: darkBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isIncome ? 'Add Income' : 'Add Expense',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Transaction Type Toggle
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (_isIncome) _toggleTransactionType();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: !_isIncome ? primaryTeal : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      'Expense',
                      style: TextStyle(
                        color: !_isIncome ? primaryTeal : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (!_isIncome) _toggleTransactionType();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _isIncome ? primaryTeal : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      'Income',
                      style: TextStyle(
                        color: _isIncome ? primaryTeal : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Title Field
            Text(
              'Description',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., Coffee, Salary',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // Amount Field
            Text(
              'Amount (€)',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // Category Field
            Text(
              'Category',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: surfaceColor,
                style: const TextStyle(color: Colors.white),
                items: _currentCategories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Text(category),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? _currentCategories.first;
                  });
                },
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save Transaction',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
