import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dash_bubble/dash_bubble.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense_entry.dart';
import '../services/database_helper.dart';
import '../services/recurring_payment_service.dart';
import '../widgets/floating_transaction_form.dart';
import '../utils/csv_export.dart';
import 'analysis_tab.dart';
import 'recurring_transactions_tab.dart';
import 'settings_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ValueNotifier<bool> _bubbleTapped;
  
  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _bubbleTapped = ValueNotifier<bool>(false);
    WidgetsBinding.instance.addObserver(this);
    _initializeBubble();
  }

  Future<void> _initializeBubble() async {
    // Check and request bubble permission if needed
    final hasPermission = await DashBubble.instance.hasOverlayPermission();
    if (!hasPermission && mounted) {
      final granted = await DashBubble.instance.requestOverlayPermission();
      if (!granted) {
        print('Bubble permission denied');
        return;
      }
    }
    print('Bubble permissions granted');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _bubbleTapped.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App going to background - show bubble
      _startBubble();
    } else if (state == AppLifecycleState.resumed) {
      // App coming to foreground - hide bubble and check if form should open
      _stopBubble();
      _checkAndOpenFormIfNeeded();
    }
  }

  Future<void> _startBubble() async {
    try {
      final isRunning = await DashBubble.instance.isRunning();
      if (isRunning) {
        print('Bubble already running');
        return;
      }

      await DashBubble.instance.startBubble(
        bubbleOptions: BubbleOptions(
          startLocationX: 0,
          startLocationY: 100,
          bubbleSize: 60,
          opacity: 0.9,
          enableAnimateToEdge: true,
          enableBottomShadow: true,
          keepAliveWhenAppExit: true,
        ),
        onTap: () {
          print('Bubble tapped - setting flag and bringing app to foreground');
          _bubbleTapped.value = true;
          _setFormOpenFlagAndLaunchApp();
        },
      );
      print('✓ Bubble started - floating transaction bubble now visible');
    } catch (e) {
      print('Error starting bubble: \$e');
    }
  }

  void _openTransactionForm() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: FloatingTransactionForm(
          autofocusAmount: true,
          onSave: () {
            // Refresh HomePage UI after save
            if (mounted) {
              setState(() {
                // Triggers FutureBuilder rebuild
              });
            }
          },
        ),
      ),
    );
  }

  Future<void> _setFormOpenFlagAndLaunchApp() async {
    try {
      // Save flag to SharedPreferences so it survives isolate boundaries
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('openFormOnResume', true);
      print('Form flag saved to SharedPreferences');

      // Use method channel to bring the app to foreground
      const platform = MethodChannel('com.example.my_expense_tracker/bubble');
      try {
        await platform.invokeMethod('launchApp');
        print('App launch requested via method channel');
      } catch (e) {
        print('Failed to launch app via method channel: $e');
        // The lifecycle listener will still catch the app resume and open the form
      }
    } catch (e) {
      print('Error in _setFormOpenFlagAndLaunchApp: $e');
    }
  }

  Future<void> _checkAndOpenFormIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shouldOpen = prefs.getBool('openFormOnResume') ?? false;
      
      if (shouldOpen && mounted) {
        // Clear the flag
        await prefs.setBool('openFormOnResume', false);
        
        // Small delay to ensure UI is ready
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            print('Opening form from bubble tap flag');
            _openTransactionForm();
          }
        });
      }
    } catch (e) {
      print('Error checking form flag: $e');
    }
  }

  Future<void> _stopBubble() async {
    try {
      final isRunning = await DashBubble.instance.isRunning();
      if (!isRunning) {
        return;
      }
      
      await DashBubble.instance.stopBubble();
      print('Bubble stopped - app in foreground');
    } catch (e) {
      print('Error stopping bubble: \$e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Expense Tracker'),
        actions: [
          IconButton(
            onPressed: _exportCSV,
            icon: const Icon(Icons.share),
            tooltip: 'Export to CSV',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF7C4DFF),
          indicatorWeight: 3,
          labelColor: const Color(0xFF7C4DFF),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Transactions'),
            Tab(icon: Icon(Icons.repeat), text: 'Recurring'),
            Tab(icon: Icon(Icons.analytics), text: 'Analysis'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFF7C4DFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            // Show in-app form dialog
            showDialog(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                child: FloatingTransactionForm(
                  onSave: () {
                    // Refresh HomePage UI after save
                    if (mounted) {
                      setState(() {
                        // Triggers FutureBuilder rebuild
                      });
                    }
                  },
                ),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionsTab(),
          const RecurringTransactionsTab(),
          const AnalysisTab(),
          SettingsTab(
            onDatabaseRestored: () {
              if (mounted) {
                setState(() {
                  // Refresh all tabs after database restore
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper().getAllTransactions(
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
          startDate: _startDate,
          endDate: _endDate,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading transactions: ${snapshot.error}'),
            );
          }

          final transactionMaps = snapshot.data ?? [];
          final entries = transactionMaps
              .map((map) => ExpenseEntry.fromMap(map))
              .toList();

          final totalIncome = entries
              .where((entry) => entry.isIncome)
              .fold<double>(0, (sum, entry) => sum + entry.amount);

          final totalExpense = entries
              .where((entry) => !entry.isIncome)
              .fold<double>(0, (sum, entry) => sum + entry.amount);

          final balance = totalIncome - totalExpense;

          return SafeArea(
            child: Column(
              children: [
                // Search and Filter Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search transactions...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1E1E2E),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      // Date Filter Row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _selectDateRange(context),
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                _startDate != null && _endDate != null
                                    ? '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}'
                                    : 'Filter by date',
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          if (_startDate != null && _endDate != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _startDate = null;
                                  _endDate = null;
                                });
                              },
                              icon: const Icon(Icons.clear, size: 20),
                              tooltip: 'Clear date filter',
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: 'Total Income',
                              amount: totalIncome,
                              color: Colors.greenAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Total Expense',
                              amount: totalExpense,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SummaryCard(
                        title: 'Balance',
                        amount: balance,
                        color: balance >= 0
                            ? Colors.lightGreenAccent
                            : Colors.orangeAccent,
                      ),
                      const SizedBox(height: 12),
                      _buildForecastingCard(),
                    ],
                  ),
                ),
                Expanded(
                  child: entries.isEmpty
                      ? const Center(
                          child: Text(
                            'No transactions yet. Add one to get started!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: entries.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                onTap: () => _showEditDeleteDialog(entry),
                                leading: CircleAvatar(
                                  backgroundColor: entry.isIncome
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.red.withOpacity(0.2),
                                  child: Icon(
                                    entry.isIncome
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: entry.isIncome
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                  ),
                                ),
                                title: Text(entry.title),
                                subtitle: Text(
                                  '${entry.category} • ${_formatDate(entry.date)}',
                                ),
                                trailing: Text(
                                  '${entry.isIncome ? '+' : '-'}€${entry.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: entry.isIncome
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
  }

  void _showEditDeleteDialog(ExpenseEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Options'),
        content: Text('What would you like to do with "${entry.title}"?'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _editTransaction(entry);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteTransaction(entry);
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _editTransaction(ExpenseEntry entry) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: FloatingTransactionForm(
          editEntry: entry,
          onSave: () {
            if (mounted) {
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(ExpenseEntry entry) async {
    try {
      await DatabaseHelper().deleteTransaction(entry.id!);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${entry.title} deleted'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error deleting transaction: $e');
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF7C4DFF),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _exportCSV() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Export CSV
      await CsvExport.exportToCSV();

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV exported successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildForecastingCard() {
    return FutureBuilder<double>(
      future: RecurringPaymentService().forecastMonthlyExpenses(),
      builder: (context, forecastSnapshot) {
        if (forecastSnapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          );
        }

        final forecast = forecastSnapshot.data ?? 0.0;

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2A1E3E),
                Color(0xFF1E2A3E),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.trending_down,
                      color: Color(0xFF7C4DFF),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Forecast (Rest of Month)',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: Colors.grey[400]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '€${forecast.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: forecast > 0
                        ? Colors.orangeAccent
                        : Colors.lightGreenAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Avg daily spend + pending recurring payments',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  final String title;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: Colors.grey[400]),
            ),
            const SizedBox(height: 12),
            Text(
              '€${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
