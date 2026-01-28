import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/database_helper.dart';

class CsvExport {
  static Future<void> exportToCSV() async {
    try {
      // Fetch all transactions from database
      final transactions = await DatabaseHelper().getAllTransactions();

      if (transactions.isEmpty) {
        throw Exception('No transactions to export');
      }

      // Prepare CSV data
      List<List<dynamic>> csvData = [
        // Header row
        ['Date', 'Title', 'Category', 'Type', 'Amount (€)'],
      ];

      // Add transaction rows
      for (var transaction in transactions) {
        final isIncome = (transaction['isIncome'] as int) == 1;
        final amount = (transaction['amount'] as num).toDouble();
        final date = DateTime.parse(transaction['date'] as String);
        
        csvData.add([
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
          transaction['title'],
          transaction['category'],
          isIncome ? 'Income' : 'Expense',
          '€${amount.toStringAsFixed(2)}',
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final path = '${directory.path}/expense_tracker_$timestamp.csv';

      // Write to file
      final file = File(path);
      await file.writeAsString(csv);

      print('CSV file created: $path');

      // Share the file
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Expense Tracker Export',
        text: 'My expense tracker data exported on ${DateTime.now().toString().split(' ')[0]}',
      );

      print('CSV file shared successfully');
    } catch (e) {
      print('Error exporting CSV: $e');
      rethrow;
    }
  }

  static Future<String> getExportSummary() async {
    final transactions = await DatabaseHelper().getAllTransactions();
    
    final totalIncome = transactions
        .where((t) => (t['isIncome'] as int) == 1)
        .fold<double>(0, (sum, t) => sum + (t['amount'] as num).toDouble());
    
    final totalExpense = transactions
        .where((t) => (t['isIncome'] as int) == 0)
        .fold<double>(0, (sum, t) => sum + (t['amount'] as num).toDouble());
    
    return '''
Transactions: ${transactions.length}
Total Income: €${totalIncome.toStringAsFixed(2)}
Total Expense: €${totalExpense.toStringAsFixed(2)}
Balance: €${(totalIncome - totalExpense).toStringAsFixed(2)}
''';
  }
}
