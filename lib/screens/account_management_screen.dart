import 'package:flutter/material.dart';

import '../services/database_helper.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  List<Map<String, dynamic>> _accounts = [];
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedType = 'Bank';
  int? _editingId;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await DatabaseHelper().getAllAccounts();
    setState(() {
      _accounts = accounts;
    });
  }

  void _showAccountDialog({Map<String, dynamic>? account}) {
    _editingId = account?['id'] as int?;
    _nameController.text = account?['name'] ?? '';
    _balanceController.text = account?['balance'].toString() ?? '';
    _selectedType = account?['account_type'] ?? 'Bank';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_editingId == null ? 'Add Account' : 'Edit Account'),
          backgroundColor: Colors.white,
          titleTextStyle:
              const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Account Type Selection - Toggle Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setDialogState(() => _selectedType = 'Bank');
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedType == 'Bank'
                                ? const Color(0xFF0066CC)
                                : Colors.grey[200],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_balance,
                                color: _selectedType == 'Bank'
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Bank',
                                style: TextStyle(
                                  color: _selectedType == 'Bank'
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 1),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setDialogState(() => _selectedType = 'Cash');
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedType == 'Cash'
                                ? const Color(0xFF10B981)
                                : Colors.grey[200],
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.payments,
                                color: _selectedType == 'Cash'
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cash',
                                style: TextStyle(
                                  color: _selectedType == 'Cash'
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Account Name Field
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Account Name',
                    labelStyle: const TextStyle(color: Color(0xFF999999)),
                    hintText: _selectedType == 'Bank'
                        ? 'e.g., Sparkasse, ING'
                        : 'e.g., Wallet, Cash Box',
                    hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Balance/Amount Field
                TextField(
                  controller: _balanceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _selectedType == 'Bank'
                        ? 'Starting Balance (€)'
                        : 'Amount (€)',
                    labelStyle: const TextStyle(color: Color(0xFF999999)),
                    hintText: '0.00',
                    hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final balanceText = _balanceController.text.trim();

                if (name.isEmpty || balanceText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                try {
                  final balance = double.parse(balanceText);

                  if (_editingId == null) {
                    await DatabaseHelper().addAccount(
                      name: name,
                      initialBalance: balance,
                      accountType: _selectedType,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account added successfully')),
                    );
                  } else {
                    await DatabaseHelper().updateAccount(
                      id: _editingId!,
                      name: name,
                      balance: balance,
                      accountType: _selectedType,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account updated successfully')),
                    );
                  }

                  _nameController.clear();
                  _balanceController.clear();
                  _selectedType = 'Bank';
                  _editingId = null;
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
                foregroundColor: Colors.white,
              ),
              child: Text(_editingId == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper().deleteAccount(id);
      _loadAccounts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Accounts'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: _accounts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No accounts yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAccountDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066CC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _accounts.length,
              itemBuilder: (context, index) {
                final account = _accounts[index];
                final isBank = account['account_type'] == 'Bank';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  color: Colors.white,
                  child: ListTile(
                    leading: Icon(
                      isBank ? Icons.account_balance : Icons.payments,
                      color: const Color(0xFF0066CC),
                      size: 28,
                    ),
                    title: Text(
                      account['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      isBank ? 'Bank Account' : 'Cash Wallet',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '€${account['balance'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _showAccountDialog(account: account),
                    onLongPress: () => _deleteAccount(account['id']),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountDialog(),
        backgroundColor: const Color(0xFF0066CC),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }
}
