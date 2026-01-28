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
  bool _isCustomSelected = false;
  late FocusNode _amountFocusNode;
  
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _customCategoryController = TextEditingController();

  final List<String> _incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Gift',
    'Custom',
  ];

  final List<String> _expenseCategories = [
    'Food',
    'Rent',
    'Transport',
    'Shopping',
    'Utilities',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _amountFocusNode = FocusNode();
    if (widget.editEntry != null) {
      _titleController.text = widget.editEntry!.title;
      _amountController.text = widget.editEntry!.amount.toString();
      _isIncome = widget.editEntry!.isIncome;
      _selectedCategory = widget.editEntry!.category;
      // Check if it's a custom category
      if (!_currentCategories.contains(_selectedCategory)) {
        _isCustomSelected = true;
        _customCategoryController.text = _selectedCategory;
        _selectedCategory = 'Custom';
      }
    }
    
    // Auto-focus amount field if specified
    if (widget.autofocusAmount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _amountFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _customCategoryController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  List<String> get _currentCategories =>
      _isIncome ? _incomeCategories : _expenseCategories;

  void _handleSave() async {
    final finalCategory = _isCustomSelected
        ? _customCategoryController.text
        : _selectedCategory;

    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();

    if (title.isEmpty || amountText.isEmpty) {
      print('Error: Title and amount are required');
      return;
    }

    try {
      final amount = double.parse(amountText);
      
      // Save to database (insert or update)
      if (widget.editEntry != null) {
        // Update existing transaction
        await DatabaseHelper().updateTransaction(
          id: widget.editEntry!.id!,
          title: title,
          amount: amount,
          category: finalCategory,
          date: widget.editEntry!.date.toIso8601String(),
          isIncome: _isIncome,
        );
        print('=== UPDATE TRANSACTION ===');
      } else {
        // Insert new transaction
        await DatabaseHelper().insertTransaction(
          title: title,
          amount: amount,
          category: finalCategory,
          date: DateTime.now().toIso8601String(),
          isIncome: _isIncome,
        );
        print('=== SAVE TRANSACTION ===');
      }
      print('Type: ${_isIncome ? "Income" : "Expense"}');
      print('Title: $title');
      print('Amount: €$amountText');
      print('Category: $finalCategory');
      print('Status: Saved to database');
      print('========================');
      
      // Clear form
      _titleController.clear();
      _amountController.clear();
      _customCategoryController.clear();

      // Trigger refresh on HomePage
      if (widget.onSave != null) {
        widget.onSave!();
        print('✓ Refresh triggered on HomePage');
      }
      
      _close();
    } catch (e) {
      print('Error saving transaction: $e');
    }
  }

  void _handleLater() {
    print('=== LATER (15 min snooze) ===');
    _close();
  }

  void _handleNoTransaction() {
    print('=== NO TRANSACTION ===');
    _close();
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
    
    return Stack(
      children: [
        // Semi-transparent background
        GestureDetector(
          onTap: widget.onClose,
          child: Container(
            color: Colors.black54,
          ),
        ),
        
        // Draggable floating form
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                // Update position while dragging
                _position = Offset(
                  (_position.dx + details.delta.dx).clamp(
                    0.0,
                    screenSize.width - 340,
                  ),
                  (_position.dy + details.delta.dy).clamp(
                    0.0,
                    screenSize.height - 500,
                  ),
                );
              });
            },
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFF1E2128),
              child: Container(
                width: 340,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    
                    // Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Transaction',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                        onPressed: _close,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Income/Expense Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1115),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _isIncome = false;
                                _isCustomSelected = false;
                                _selectedCategory = _expenseCategories.first;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isIncome
                                      ? Colors.redAccent
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_upward,
                                      size: 18,
                                      color: !_isIncome
                                          ? Colors.white
                                          : Colors.grey[400],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Expense',
                                      style: TextStyle(
                                        color: !_isIncome
                                            ? Colors.white
                                            : Colors.grey[400],
                                        fontWeight: !_isIncome
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _isIncome = true;
                                _isCustomSelected = false;
                                _selectedCategory = _incomeCategories.first;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isIncome
                                      ? Colors.greenAccent
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_downward,
                                      size: 18,
                                      color: _isIncome
                                          ? Colors.black
                                          : Colors.grey[400],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Income',
                                      style: TextStyle(
                                        color: _isIncome
                                            ? Colors.black
                                            : Colors.grey[400],
                                        fontWeight: _isIncome
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Title Field
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g., Groceries',
                        filled: true,
                        fillColor: const Color(0xFF0F1115),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Amount Field with Euro Symbol
                    TextField(
                      controller: _amountController,
                      focusNode: _amountFocusNode,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount (€)',
                        hintText: '0.00',
                        prefixText: '€ ',
                        prefixStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0F1115),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Category Dropdown
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1115),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E2128),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey[400],
                          ),
                          items: _currentCategories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCategory = newValue;
                                _isCustomSelected = (newValue == 'Custom');
                              });
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Custom Category TextField (shown only if Custom is selected)
                    if (_isCustomSelected)
                      TextField(
                        controller: _customCategoryController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Enter Custom Category',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          hintText: 'e.g., Groceries, Taxi',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: const Color(0xFF0F1115),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),

                    if (_isCustomSelected) const SizedBox(height: 12),
                    
                    if (!_isCustomSelected) const SizedBox(height: 20),
                    
                    // Action Buttons
                    ElevatedButton.icon(
                      onPressed: _handleSave,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C4DFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _handleLater,
                            icon: const Icon(Icons.schedule, size: 18),
                            label: const Text('Later'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orangeAccent,
                              side: const BorderSide(color: Colors.orangeAccent),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _handleNoTransaction,
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('No Transaction'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[400],
                              side: BorderSide(color: Colors.grey[600]!),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
