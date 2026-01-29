import 'package:flutter/material.dart';

import '../models/expense_entry.dart';
import '../services/database_helper.dart';

class FloatingTransactionForm extends StatefulWidget {
  const FloatingTransactionForm({
    super.key,
    this.onClose,
    this.onSave,
    this.editEntry,
    this.autofocusAmount = false,
  });

  final VoidCallback? onClose;
  final VoidCallback? onSave;
  final ExpenseEntry? editEntry;
  final bool autofocusAmount;

  @override
  State<FloatingTransactionForm> createState() =>
      _FloatingTransactionFormState();
}

class _FloatingTransactionFormState extends State<FloatingTransactionForm> {
  Offset _position = const Offset(20, 100);
  bool _isIncome = false;
  String _selectedCategory = 'Food';
  int? _selectedAccountId;
  List<Map<String, dynamic>> _accounts = [];
  late FocusNode _amountFocusNode;
  
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _dateController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountBalanceController = TextEditingController();

  final Map<String, IconData> _expenseCategories = {
    'Entertainment': Icons.movie,
    'Transport': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Utilities': Icons.bolt,
    'Food': Icons.restaurant,
    'Health': Icons.favorite,
    'Housing': Icons.home,
    'Other': Icons.more_horiz,
  };

  final Map<String, IconData> _incomeCategories = {
    'Salary': Icons.work,
    'Freelance': Icons.code,
    'Investment': Icons.trending_up,
    'Gift': Icons.card_giftcard,
    'Bonus': Icons.star,
    'Other': Icons.more_horiz,
  };

  // Color palette matching the mockup
  final Map<int, Color> _categoryColors = {
    0: const Color(0xFF0066CC), // Blue
    1: const Color(0xFF0066CC), // Blue
    2: const Color(0xFFE85D75), // Pink/Red
    3: const Color(0xFFE85D75), // Pink/Red
    4: const Color(0xFFE85D75), // Pink/Red
    5: const Color(0xFFE85D75), // Pink/Red
    6: const Color(0xFF0066CC), // Blue
    7: const Color(0xFFADB5BD), // Grey
  };

  @override
  void initState() {
    super.initState();
    _amountFocusNode = FocusNode();
    _loadAccounts();
    _dateController.text = _formatDate(DateTime.now());
    
    if (widget.editEntry != null) {
      _amountController.text = widget.editEntry!.amount.toString();
      _isIncome = widget.editEntry!.isIncome;
      _selectedCategory = widget.editEntry!.category;
      _noteController.text = widget.editEntry!.title;
      _dateController.text = _formatDate(widget.editEntry!.date);
    }
    
    if (widget.autofocusAmount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _amountFocusNode.requestFocus();
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (e) {
      return DateTime.now();
    }
  }

  Future<void> _loadAccounts() async {
    final accounts = await DatabaseHelper().getAllAccounts();
    setState(() {
      _accounts = accounts;
      if (_accounts.isNotEmpty && _selectedAccountId == null) {
        _selectedAccountId = _accounts.first['id'] as int;
      }
    });
  }

  void _showAddAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Bank/Cash Account'),
        backgroundColor: const Color(0xFF1E2128),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _accountNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Account Name',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'e.g., Sparkasse',
                hintStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF0F1115),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accountBalanceController,
              style: const TextStyle(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Initial Amount (€)',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: '0.00',
                hintStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF0F1115),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _accountNameController.text.trim();
              final balanceText = _accountBalanceController.text.trim();
              if (name.isEmpty || balanceText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }
              try {
                final balance = double.parse(balanceText);
                await DatabaseHelper().addAccount(
                  name: name,
                  initialBalance: balance,
                  accountType: 'Bank',
                );
                _accountNameController.clear();
                _accountBalanceController.clear();
                _loadAccounts();
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066CC),
            ),
            child: const Text('Add Account'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    _accountNameController.dispose();
    _accountBalanceController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Map<String, IconData> get _currentCategories =>
      _isIncome ? _incomeCategories : _expenseCategories;

  void _handleSave() async {
    final amountText = _amountController.text.trim();
    final note = _noteController.text.trim();

    if (amountText.isEmpty) {
      print('Error: Amount is required');
      return;
    }

    try {
      final amount = double.parse(amountText);
      final date = _parseDate(_dateController.text);
      
      if (widget.editEntry != null) {
        await DatabaseHelper().updateTransaction(
          id: widget.editEntry!.id!,
          title: note,
          amount: amount,
          category: _selectedCategory,
          date: date.toIso8601String(),
          isIncome: _isIncome,
        );
        print('=== UPDATE TRANSACTION ===');
      } else {
        await DatabaseHelper().insertTransaction(
          title: note,
          amount: amount,
          category: _selectedCategory,
          date: date.toIso8601String(),
          isIncome: _isIncome,
          accountId: _selectedAccountId,
        );
        print('=== SAVE TRANSACTION ===');
      }
      print('Type: ${_isIncome ? "Income" : "Expense"}');
      print('Amount: €$amountText');
      print('Category: $_selectedCategory');
      print('Note: $note');
      print('Status: Saved to database');
      print('========================');
      
      _amountController.clear();
      _noteController.clear();

      if (widget.onSave != null) {
        widget.onSave!();
      }
      
      _close();
    } catch (e) {
      print('Error saving transaction: $e');
    }
  }

  void _close() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final categories = _currentCategories.keys.toList();
    
    return Stack(
      children: [
        GestureDetector(
          onTap: _close,
          child: Container(color: Colors.black54),
        ),
        
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _position = Offset(
                  (_position.dx + details.delta.dx).clamp(0.0, screenSize.width - 400),
                  (_position.dy + details.delta.dy).clamp(0.0, screenSize.height - 500),
                );
              });
            },
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add Transaction',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black54),
                            onPressed: _close,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Expense/Income Toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isIncome = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_isIncome ? const Color(0xFF0066CC) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Expense',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: !_isIncome ? Colors.white : Colors.black54,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isIncome = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isIncome ? const Color(0xFF0066CC) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Income',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _isIncome ? Colors.white : Colors.black54,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Amount Display
                      GestureDetector(
                        onTap: () {
                          _amountFocusNode.requestFocus();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Text(
                                '\$',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 120,
                                child: TextField(
                                  controller: _amountController,
                                  focusNode: _amountFocusNode,
                                  onChanged: (_) => setState(() {}),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    hintStyle: TextStyle(
                                      fontSize: 32,
                                      color: Colors.grey[400],
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Category Grid
                      SizedBox(
                        height: 160,
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 0.85,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final icon = _currentCategories[category]!;
                            final isSelected = _selectedCategory == category;
                            final bgColor = _categoryColors[index] ?? const Color(0xFF0066CC);
                            
                            return GestureDetector(
                              onTap: () => setState(() => _selectedCategory = category),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: bgColor.withOpacity(isSelected ? 1.0 : 0.8),
                                      shape: BoxShape.circle,
                                      border: isSelected
                                          ? Border.all(color: Colors.black, width: 2)
                                          : null,
                                    ),
                                    child: Icon(
                                      icon,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      category,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF666666),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Date Field
                      TextField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _parseDate(_dateController.text),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            _dateController.text = _formatDate(date);
                          }
                        },
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Date',
                          labelStyle: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2B7A91), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF2B7A91), size: 20),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Title Field
                      TextField(
                        controller: _noteController,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          labelStyle: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          hintText: 'What did you buy?',
                          hintStyle: const TextStyle(
                            color: Color(0xFFBDBDBD),
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2B7A91), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Account Dropdown
                      if (_accounts.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedAccountId,
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: Colors.black87, fontSize: 14),
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF999999)),
                              items: _accounts.map((account) {
                                return DropdownMenuItem<int>(
                                  value: account['id'] as int,
                                  child: Text('${account['name']} (€${account['balance']})'),
                                );
                              }).toList(),
                              onChanged: (int? newValue) {
                                if (newValue != null) {
                                  setState(() => _selectedAccountId = newValue);
                                }
                              },
                            ),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _showAddAccountDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add your first account'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066CC),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Save Button
                      ElevatedButton(
                        onPressed: _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066CC),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Save Transaction',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
