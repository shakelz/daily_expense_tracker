import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'expense_tracker.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Create recurring_payments table for new version
      await db.execute(
        '''
        CREATE TABLE IF NOT EXISTS recurring_payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          day_of_month INTEGER NOT NULL,
          isIncome INTEGER NOT NULL,
          last_executed TEXT
        )
        ''',
      );
      print('Database upgraded: recurring_payments table created');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      '''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        isIncome INTEGER NOT NULL
      )
      ''',
    );
    print('Database table "transactions" created');

    if (version >= 2) {
      await db.execute(
        '''
        CREATE TABLE recurring_payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          day_of_month INTEGER NOT NULL,
          isIncome INTEGER NOT NULL,
          last_executed TEXT
        )
        ''',
      );
      print('Database table "recurring_payments" created');
    }
  }

  Future<int> insertTransaction({
    required String title,
    required double amount,
    required String category,
    required String date,
    required bool isIncome,
  }) async {
    final db = await database;
    final result = await db.insert(
      'transactions',
      {
        'title': title,
        'amount': amount,
        'category': category,
        'date': date,
        'isIncome': isIncome ? 1 : 0,
      },
    );
    print('Transaction inserted with ID: $result');
    return result;
  }

  Future<List<Map<String, dynamic>>> getAllTransactions({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    
    // Build WHERE clause dynamically
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereConditions.add('title LIKE ?');
      whereArgs.add('%$searchQuery%');
    }
    
    if (startDate != null && endDate != null) {
      whereConditions.add('date(date) BETWEEN date(?) AND date(?)');
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    }
    
    final results = await db.query(
      'transactions',
      where: whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC',
    );
    print('Fetched ${results.length} transactions from database');
    return results;
  }

  Future<int> updateTransaction({
    required int id,
    required String title,
    required double amount,
    required String category,
    required String date,
    required bool isIncome,
  }) async {
    final db = await database;
    final result = await db.update(
      'transactions',
      {
        'title': title,
        'amount': amount,
        'category': category,
        'date': date,
        'isIncome': isIncome ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Transaction with ID $id updated');
    return result;
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Transaction with ID $id deleted');
  }

  Future<void> clearAllTransactions() async {
    final db = await database;
    await db.delete('transactions');
    print('All transactions cleared');
  }

  // ========== RECURRING PAYMENTS METHODS ==========

  Future<int> insertRecurringPayment({
    required String title,
    required double amount,
    required String category,
    required int dayOfMonth,
    required bool isIncome,
  }) async {
    final db = await database;
    final result = await db.insert(
      'recurring_payments',
      {
        'title': title,
        'amount': amount,
        'category': category,
        'day_of_month': dayOfMonth,
        'isIncome': isIncome ? 1 : 0,
        'last_executed': null,
      },
    );
    print('Recurring payment inserted with ID: $result');
    return result;
  }

  Future<List<Map<String, dynamic>>> getAllRecurringPayments() async {
    final db = await database;
    final results = await db.query('recurring_payments', orderBy: 'day_of_month ASC');
    return results;
  }

  Future<List<Map<String, dynamic>>> getDueRecurringPayments() async {
    final db = await database;
    final today = DateTime.now();
    
    // Get all recurring payments that are due today
    final results = await db.query(
      'recurring_payments',
      where: 'day_of_month = ?',
      whereArgs: [today.day],
    );
    
    return results;
  }

  Future<void> updateRecurringPaymentLastExecuted(int id) async {
    final db = await database;
    await db.update(
      'recurring_payments',
      {'last_executed': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Recurring payment $id executed, last_executed updated');
  }

  Future<void> updateRecurringPayment({
    required int id,
    required String title,
    required double amount,
    required String category,
    required int dayOfMonth,
    required bool isIncome,
  }) async {
    final db = await database;
    await db.update(
      'recurring_payments',
      {
        'title': title,
        'amount': amount,
        'category': category,
        'day_of_month': dayOfMonth,
        'isIncome': isIncome ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Recurring payment with ID $id updated');
  }

  Future<void> deleteRecurringPayment(int id) async {
    final db = await database;
    await db.delete(
      'recurring_payments',
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Recurring payment with ID $id deleted');
  }

  Future<void> clearAllRecurringPayments() async {
    final db = await database;
    await db.delete('recurring_payments');
    print('All recurring payments cleared');
  }

  // Get category-wise expense totals (only expenses, not income)
  Future<List<Map<String, dynamic>>> getCategoryTotals() async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT category, SUM(amount) as total
      FROM transactions
      WHERE isIncome = 0
      GROUP BY category
      ORDER BY total DESC
      ''',
    );
    print('Fetched category totals: ${results.length} categories');
    return results;
  }

  // Get daily spending totals for the last N days
  Future<List<Map<String, dynamic>>> getDailyTotals(int days) async {
    final db = await database;
    final startDate = DateTime.now().subtract(Duration(days: days));
    final results = await db.rawQuery(
      '''
      SELECT 
        date(date) as day,
        SUM(CASE WHEN isIncome = 0 THEN amount ELSE 0 END) as expenses,
        SUM(CASE WHEN isIncome = 1 THEN amount ELSE 0 END) as income
      FROM transactions
      WHERE date(date) >= date(?)
      GROUP BY date(date)
      ORDER BY date(date) ASC
      ''',
      [startDate.toIso8601String()],
    );
    print('Fetched daily totals for last $days days: ${results.length} days');
    return results;
  }

  // ========== DETAILED ANALYTICS METHODS ==========

  /// Get spending analysis by hour of day using strftime
  /// Returns Map<int, double> where key is hour (0-23) and value is total spending
  Future<Map<int, double>> getSpendingByHour() async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT 
        CAST(strftime('%H', date) AS INTEGER) as hour,
        SUM(amount) as total
      FROM transactions
      WHERE isIncome = 0
      GROUP BY hour
      ORDER BY hour ASC
      ''',
    );
    
    final Map<int, double> hourlySpending = {};
    for (final row in results) {
      final hour = row['hour'] as int;
      final total = (row['total'] as num).toDouble();
      hourlySpending[hour] = total;
    }
    
    print('Fetched spending by hour: ${hourlySpending.length} hours with data');
    return hourlySpending;
  }

  /// Get spending analysis by day of week using strftime
  /// Returns Map<int, double> where key is day (0=Sunday, 6=Saturday) and value is total spending
  Future<Map<int, double>> getSpendingByDayOfWeek() async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT 
        CAST(strftime('%w', date) AS INTEGER) as day_of_week,
        SUM(amount) as total
      FROM transactions
      WHERE isIncome = 0
      GROUP BY day_of_week
      ORDER BY day_of_week ASC
      ''',
    );
    
    final Map<int, double> dailySpending = {};
    for (final row in results) {
      final day = row['day_of_week'] as int;
      final total = (row['total'] as num).toDouble();
      dailySpending[day] = total;
    }
    
    print('Fetched spending by day of week: ${dailySpending.length} days with data');
    return dailySpending;
  }

  /// Get category analysis with percentage contribution using CTE
  /// Returns list of categories sorted by spending with percentage of total
  Future<List<Map<String, dynamic>>> getCategoryAnalysis() async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      WITH monthly_expenses AS (
        SELECT 
          category,
          SUM(amount) as category_total,
          strftime('%Y-%m', date) as month
        FROM transactions
        WHERE isIncome = 0
          AND date >= date('now', '-30 days')
        GROUP BY category, month
      ),
      total_monthly AS (
        SELECT 
          SUM(category_total) as overall_total,
          month
        FROM monthly_expenses
        GROUP BY month
      )
      SELECT 
        me.category,
        SUM(me.category_total) as total_amount,
        ROUND(
          (SUM(me.category_total) * 100.0) / 
          (SELECT SUM(overall_total) FROM total_monthly),
          2
        ) as percentage
      FROM monthly_expenses me
      GROUP BY me.category
      ORDER BY total_amount DESC
      ''',
    );
    
    print('Fetched category analysis: ${results.length} categories');
    return results;
  }

  /// Get top spending categories (simplified version)
  /// Returns list of {category, total, count} sorted by total spending
  Future<List<Map<String, dynamic>>> getTopCategories({int limit = 10}) async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT 
        category,
        SUM(amount) as total,
        COUNT(*) as count
      FROM transactions
      WHERE isIncome = 0
      GROUP BY category
      ORDER BY total DESC
      LIMIT ?
      ''',
      [limit],
    );
    
    print('Fetched top $limit categories');
    return results;
  }

  /// Get spending trends over time (monthly aggregation)
  Future<List<Map<String, dynamic>>> getMonthlySpendingTrend({int months = 6}) async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT 
        strftime('%Y-%m', date) as month,
        SUM(CASE WHEN isIncome = 0 THEN amount ELSE 0 END) as expenses,
        SUM(CASE WHEN isIncome = 1 THEN amount ELSE 0 END) as income,
        COUNT(CASE WHEN isIncome = 0 THEN 1 END) as expense_count,
        COUNT(CASE WHEN isIncome = 1 THEN 1 END) as income_count
      FROM transactions
      WHERE date >= date('now', '-$months months')
      GROUP BY month
      ORDER BY month ASC
      ''',
    );
    
    print('Fetched monthly spending trend for last $months months');
    return results;
  }

  /// Get total expenses and income for a specific period
  Future<Map<String, double>> getTotalsByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT 
        SUM(CASE WHEN isIncome = 0 THEN amount ELSE 0 END) as total_expenses,
        SUM(CASE WHEN isIncome = 1 THEN amount ELSE 0 END) as total_income
      FROM transactions
      WHERE date(date) BETWEEN date(?) AND date(?)
      ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    
    if (results.isNotEmpty) {
      final row = results.first;
      return {
        'expenses': ((row['total_expenses'] ?? 0) as num).toDouble(),
        'income': ((row['total_income'] ?? 0) as num).toDouble(),
      };
    }
    
    return {'expenses': 0.0, 'income': 0.0};
  }

  /// Get Month-over-Month (MoM) comparison: current vs previous month
  /// Returns: {
  ///   'current_income': double,
  ///   'current_expense': double,
  ///   'previous_income': double,
  ///   'previous_expense': double,
  ///   'income_percent_change': double (positive = increase),
  ///   'expense_percent_change': double (positive = increase)
  /// }
  Future<Map<String, dynamic>> getMonthOverMonthComparison() async {
    final db = await database;
    
    // Get current month (YYYY-MM)
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final previousMonth = DateTime(now.year, now.month - 1).month == 0
        ? '${now.year - 1}-12'
        : '${now.year}-${(now.month - 1).toString().padLeft(2, '0')}';
    
    // Query: Current month totals
    final currentResults = await db.rawQuery(
      '''
      SELECT 
        SUM(CASE WHEN isIncome = 1 THEN amount ELSE 0 END) as income,
        SUM(CASE WHEN isIncome = 0 THEN amount ELSE 0 END) as expense
      FROM transactions
      WHERE strftime('%Y-%m', date) = ?
      ''',
      [currentMonth],
    );
    
    // Query: Previous month totals
    final previousResults = await db.rawQuery(
      '''
      SELECT 
        SUM(CASE WHEN isIncome = 1 THEN amount ELSE 0 END) as income,
        SUM(CASE WHEN isIncome = 0 THEN amount ELSE 0 END) as expense
      FROM transactions
      WHERE strftime('%Y-%m', date) = ?
      ''',
      [previousMonth],
    );
    
    final currentIncome = currentResults.isNotEmpty
        ? ((currentResults.first['income'] ?? 0) as num).toDouble()
        : 0.0;
    final currentExpense = currentResults.isNotEmpty
        ? ((currentResults.first['expense'] ?? 0) as num).toDouble()
        : 0.0;
    
    final previousIncome = previousResults.isNotEmpty
        ? ((previousResults.first['income'] ?? 0) as num).toDouble()
        : 0.0;
    final previousExpense = previousResults.isNotEmpty
        ? ((previousResults.first['expense'] ?? 0) as num).toDouble()
        : 0.0;
    
    // Calculate % change (handle divide by zero)
    double incomePercentChange = 0.0;
    if (previousIncome > 0) {
      incomePercentChange = ((currentIncome - previousIncome) / previousIncome) * 100;
    } else if (currentIncome > 0) {
      incomePercentChange = 100.0; // 0 → positive = 100% increase
    }
    
    double expensePercentChange = 0.0;
    if (previousExpense > 0) {
      expensePercentChange = ((currentExpense - previousExpense) / previousExpense) * 100;
    } else if (currentExpense > 0) {
      expensePercentChange = 100.0; // 0 → positive = 100% increase
    }
    
    print('MoM Comparison:');
    print('  Current: Income €$currentIncome, Expense €$currentExpense');
    print('  Previous: Income €$previousIncome, Expense €$previousExpense');
    print('  Income % Change: ${incomePercentChange.toStringAsFixed(1)}%');
    print('  Expense % Change: ${expensePercentChange.toStringAsFixed(1)}%');
    
    return {
      'current_income': currentIncome,
      'current_expense': currentExpense,
      'previous_income': previousIncome,
      'previous_expense': previousExpense,
      'income_percent_change': incomePercentChange,
      'expense_percent_change': expensePercentChange,
    };
  }

  /// Get Top 5 most expensive transactions
  /// Returns: List of {id, title, amount, category, date, isIncome}
  Future<List<Map<String, dynamic>>> getTop5Expenses() async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT 
        id,
        title,
        amount,
        category,
        date,
        isIncome
      FROM transactions
      WHERE isIncome = 0
      ORDER BY amount DESC
      LIMIT 5
      ''',
    );
    
    print('Fetched top 5 expenses: ${results.length} transactions');
    return results;
  }
}
