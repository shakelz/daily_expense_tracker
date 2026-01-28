import 'package:flutter/material.dart';

import '../services/database_helper.dart';
import '../services/recurring_payment_service.dart';

class RecurringTransactionsTab extends StatefulWidget {
  const RecurringTransactionsTab({super.key});

  @override
  State<RecurringTransactionsTab> createState() =>
      _RecurringTransactionsTabState();
}

class _RecurringTransactionsTabState extends State<RecurringTransactionsTab> {
  final DatabaseHelper _db = DatabaseHelper();
  final RecurringPaymentService _recurringService = RecurringPaymentService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadRecurringData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading recurring payments: ${snapshot.error}'),
          );
        }

        final data = snapshot.data ?? {};
        final recurringList =
            data['payments'] as List<Map<String, dynamic>>? ?? [];
        final summary = data['summary'] as Map<String, double>? ?? {};

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text(
                'Recurring Payments',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your Berlin bills and recurring expenses',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),

              // Summary Cards
              _buildSummaryCards(summary),

              const SizedBox(height: 24),

              // Add New Recurring Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showAddRecurringDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Recurring Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Recurring Payments List
              if (recurringList.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recurring payments yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    const Text(
                      'Your Recurring Payments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...recurringList.map((payment) {
                      final isIncome = payment['isIncome'] == 1;
                      return _buildRecurringPaymentCard(payment, isIncome);
                    }).toList(),
                  ],
                ),

              const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadRecurringData() async {
    final payments = await _db.getAllRecurringPayments();
    final summary = await _recurringService.getPendingRecurringSummary();
    return {
      'payments': payments,
      'summary': summary,
    };
  }

  Widget _buildSummaryCards(Map<String, double> summary) {
    final income = summary['income'] ?? 0.0;
    final expenses = summary['expenses'] ?? 0.0;
    final net = summary['net'] ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Expected Income',
            amount: income,
            color: Colors.greenAccent,
            icon: Icons.arrow_downward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Expected Expenses',
            amount: expenses,
            color: Colors.redAccent,
            icon: Icons.arrow_upward,
          ),
        ),
      ],
    );
  }

  Widget _buildRecurringPaymentCard(
      Map<String, dynamic> payment, bool isIncome) {
    final id = payment['id'] as int;
    final title = payment['title'] as String;
    final amount = payment['amount'] as double;
    final category = payment['category'] as String;
    final dayOfMonth = payment['day_of_month'] as int;

    final now = DateTime.now();
    final daysUntilDue = dayOfMonth > now.day ? dayOfMonth - now.day : 0;
    final dueText = daysUntilDue == 0
        ? 'Due today'
        : daysUntilDue == 1
            ? 'Due tomorrow'
            : 'Due in $daysUntilDue days';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isIncome
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isIncome ? Icons.trending_up : Icons.trending_down,
                    color: isIncome ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            dueText,
                            style: TextStyle(
                              fontSize: 12,
                              color: daysUntilDue == 0
                                  ? Colors.orangeAccent
                                  : Colors.grey[400],
                              fontWeight: daysUntilDue == 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '€${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isIncome ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Day $dayOfMonth',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editRecurringPayment(payment),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _deleteRecurringPayment(id, title),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRecurringDialog({Map<String, dynamic>? existingPayment}) {
    String title = existingPayment?['title'] ?? '';
    double amount = existingPayment?['amount'] ?? 0.0;
    String category = existingPayment?['category'] ?? 'Utilities';
    int dayOfMonth = existingPayment?['day_of_month'] ?? 1;
    bool isIncome = existingPayment?['isIncome'] == 1;
    int? paymentId = existingPayment?['id'];

    final incomeCategories = ['Salary', 'Freelance', 'Investment', 'Gift'];
    final expenseCategories = [
      'Food',
      'Rent',
      'Transport',
      'Shopping',
      'Utilities'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(paymentId == null ? 'Add Recurring Payment' : 'Edit Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Rent, Electricity',
                  ),
                  onChanged: (value) => title = value,
                  controller: TextEditingController(text: title),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Expense'),
                        selected: !isIncome,
                        onSelected: (selected) {
                          setState(() => isIncome = false);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Income'),
                        selected: isIncome,
                        onSelected: (selected) {
                          setState(() => isIncome = true);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  items: (isIncome ? incomeCategories : expenseCategories)
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (value) => category = value ?? category,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Amount (€)',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    amount = double.tryParse(value) ?? 0.0;
                  },
                  controller: TextEditingController(text: amount.toString()),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Day of Month (1-31)',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    dayOfMonth = int.tryParse(value) ?? 1;
                    dayOfMonth = dayOfMonth.clamp(1, 31);
                  },
                  controller: TextEditingController(text: dayOfMonth.toString()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (title.isEmpty || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields correctly'),
                    ),
                  );
                  return;
                }

                if (paymentId == null) {
                  await _db.insertRecurringPayment(
                    title: title,
                    amount: amount,
                    category: category,
                    dayOfMonth: dayOfMonth,
                    isIncome: isIncome,
                  );
                } else {
                  await _db.updateRecurringPayment(
                    id: paymentId,
                    title: title,
                    amount: amount,
                    category: category,
                    dayOfMonth: dayOfMonth,
                    isIncome: isIncome,
                  );
                }

                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
              ),
              child: Text(paymentId == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _editRecurringPayment(Map<String, dynamic> payment) {
    _showAddRecurringDialog(existingPayment: payment);
  }

  void _deleteRecurringPayment(int id, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Payment'),
        content: Text('Delete recurring payment "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _db.deleteRecurringPayment(id);
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '€${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
