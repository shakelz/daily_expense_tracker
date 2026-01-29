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
      version: 5,
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
    if (oldVersion < 3) {
      // Create accounts table
      await db.execute(
        '''
        CREATE TABLE IF NOT EXISTS accounts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          balance REAL NOT NULL DEFAULT 0.0,
          created_at TEXT NOT NULL
        )
        ''',
      );
      // Add account_id column to transactions table if not exists
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN account_id INTEGER DEFAULT NULL'
      );
      print('Database upgraded: accounts table created and account_id added to transactions');
    }
    if (oldVersion < 4) {
      // Add account_type column to accounts table
      try {
        await db.execute(
          'ALTER TABLE accounts ADD COLUMN account_type TEXT DEFAULT "Bank"'
        );
      } catch (e) {
        print('Column account_type already exists');
      }
      print('Database upgraded: account_type column added to accounts');
    }
    if (oldVersion < 5) {
      // Create budgets table
      await db.execute(
        '''
        CREATE TABLE IF NOT EXISTS budgets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL UNIQUE,
          budget_amount REAL NOT NULL,
          created_at TEXT NOT NULL
        )
        ''',
      );
      // Create overall monthly budget setting
      await db.execute(
        '''
        CREATE TABLE IF NOT EXISTS monthly_budget (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          budget_amount REAL NOT NULL,
          updated_at TEXT NOT NULL
        )
        ''',
      );
      print('Database upgraded: budgets and monthly_budget tables created');
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
        isIncome INTEGER NOT NULL,
        account_id INTEGER
      )
      ''',
    );
    print('Database table "transactions" created');

    // Create accounts table
    await db.execute(
      '''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        account_type TEXT NOT NULL DEFAULT 'Bank',
        created_at TEXT NOT NULL
      )
      ''',
    );
    print('Database table "accounts" created');

    // Create budgets table
    await db.execute(
      '''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL UNIQUE,
        budget_amount REAL NOT NULL,
        created_at TEXT NOT NULL
      )
      ''',
    );
    print('Database table "budgets" created');

    // Create overall monthly budget table
    await db.execute(
      '''
      CREATE TABLE monthly_budget (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        budget_amount REAL NOT NULL,
        updated_at TEXT NOT NULL
      )
      ''',
    );
    print('Database table "monthly_budget" created');

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
    int? accountId,
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
        'account_id': accountId,
      },
    );
    
    // Update account balance if accountId is provided
    if (accountId != null) {
      final balanceChange = isIncome ? amount : -amount;
      await db.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [balanceChange, accountId],
      );
      print('Account $accountId balance updated by €$balanceChange');
    }
    
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
      whereConditions.add('t.title LIKE ?');
      whereArgs.add('%$searchQuery%');
    }
    
    if (startDate != null && endDate != null) {
      whereConditions.add('date(t.date) BETWEEN date(?) AND date(?)');
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    }

    final whereClause = whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;
    
    final results = await db.rawQuery(
      '''
      SELECT 
        t.*, 
        COALESCE(a.name, 'No Account') as account_name,
        COALESCE(a.account_type, 'Bank') as account_type
      FROM transactions t
      LEFT JOIN accounts a ON t.account_id = a.id
      ${whereClause != null ? 'WHERE $whereClause' : ''}
      ORDER BY t.date DESC
      ''',
      whereArgs,
    );
    print('Fetched ${results.length} transactions from database with account info');
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
    
    // Get transaction details before deleting
    final results = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (results.isNotEmpty) {
      final transaction = results.first;
      final accountId = transaction['account_id'] as int?;
      final amount = (transaction['amount'] as num).toDouble();
      final isIncome = (transaction['isIncome'] as int) == 1;
      
      // Reverse the balance update if account exists
      if (accountId != null) {
        final balanceChange = isIncome ? -amount : amount;
        await db.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [balanceChange, accountId],
        );
        print('Account $accountId balance reversed by €$balanceChange');
      }
    }
    
    // Delete the transaction
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

  /// Get all unique categories from transactions
  /// Used for filter chips in the Analysis Tab
  Future<List<String>> getAllCategories() async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT DISTINCT category
      FROM transactions
      ORDER BY category ASC
      ''',
    );
    
    final categories = results.map((row) => row['category'] as String).toList();
    print('Fetched ${categories.length} unique categories');
    return categories;
  }

  /// Query transactions with optional filtering by date range and category
  /// Parameters:
  ///   - startDate: Start date (inclusive) for filtering
  ///   - endDate: End date (inclusive) for filtering
  ///   - category: Specific category to filter (null = all categories)
  /// Returns: List of filtered transactions
  Future<List<Map<String, dynamic>>> queryTransactionsFiltered({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    final db = await database;
    
    String query = '''
      SELECT 
        t.*,
        COALESCE(a.name, 'No Account') as account_name,
        COALESCE(a.account_type, 'Bank') as account_type
      FROM transactions t
      LEFT JOIN accounts a ON t.account_id = a.id
      WHERE 1=1
    ''';
    final params = <dynamic>[];
    
    // Add date range filter if provided
    if (startDate != null && endDate != null) {
      query += ' AND date(t.date) BETWEEN date(?) AND date(?)';
      params.add(startDate.toIso8601String());
      params.add(endDate.toIso8601String());
    }
    
    // Add category filter if provided
    if (category != null && category.isNotEmpty) {
      query += ' AND t.category = ?';
      params.add(category);
    }
    
    // Sort by date DESC (newest first)
    query += ' ORDER BY t.date DESC';
    
    final results = await db.rawQuery(query, params);
    
    print('Fetched ${results.length} filtered transactions');
    print('  Filter: startDate=$startDate, endDate=$endDate, category=$category');
    
    return results;
  }

  /// Get filtered spending by hour (for hourly chart with filters)
  Future<Map<int, double>> getSpendingByHourFiltered({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    final db = await database;
    
    String query = '''
      SELECT 
        CAST(strftime('%H', date) AS INTEGER) as hour,
        SUM(amount) as total
      FROM transactions
      WHERE isIncome = 0
    ''';
    final params = <dynamic>[];
    
    if (startDate != null && endDate != null) {
      query += ' AND date(date) BETWEEN date(?) AND date(?)';
      params.add(startDate.toIso8601String());
      params.add(endDate.toIso8601String());
    }
    
    if (category != null && category.isNotEmpty) {
      query += ' AND category = ?';
      params.add(category);
    }
    
    query += ' GROUP BY hour ORDER BY hour ASC';
    
    final results = await db.rawQuery(query, params);
    
    // Convert to map, filling missing hours with 0
    final hourlyMap = <int, double>{};
    for (int h = 0; h < 24; h++) {
      hourlyMap[h] = 0.0;
    }
    
    for (final row in results) {
      final hour = (row['hour'] as int);
      final total = ((row['total'] ?? 0) as num).toDouble();
      hourlyMap[hour] = total;
    }
    
    print('Fetched filtered hourly spending: ${results.length} hours with data');
    return hourlyMap;
  }

  /// Get filtered category analysis with percentages
  Future<List<Map<String, dynamic>>> getCategoryAnalysisFiltered({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    final db = await database;
    
    String query = '''
      WITH filtered_expenses AS (
        SELECT category, amount
        FROM transactions
        WHERE isIncome = 0
    ''';
    final params = <dynamic>[];
    
    if (startDate != null && endDate != null) {
      query += ' AND date(date) BETWEEN date(?) AND date(?)';
      params.add(startDate.toIso8601String());
      params.add(endDate.toIso8601String());
    }
    
    if (category != null && category.isNotEmpty) {
      query += ' AND category = ?';
      params.add(category);
    }
    
    query += '''
      ),
      category_totals AS (
        SELECT 
          category,
          SUM(amount) as total_amount
        FROM filtered_expenses
        GROUP BY category
      ),
      total_expenses AS (
        SELECT SUM(total_amount) as grand_total FROM category_totals
      )
      SELECT 
        ct.category,
        ct.total_amount,
        ROUND((ct.total_amount * 100.0) / te.grand_total, 2) as percentage
      FROM category_totals ct, total_expenses te
      WHERE te.grand_total > 0
      ORDER BY ct.total_amount DESC
    ''';
    
    final results = await db.rawQuery(query, params);
    
    print('Fetched filtered category analysis: ${results.length} categories');
    return results;
  }

  /// Get filtered top 5 expenses
  Future<List<Map<String, dynamic>>> getTop5ExpensesFiltered({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    final db = await database;
    
    String query = '''
      SELECT 
        id,
        title,
        amount,
        category,
        date,
        isIncome
      FROM transactions
      WHERE isIncome = 0
    ''';
    final params = <dynamic>[];
    
    if (startDate != null && endDate != null) {
      query += ' AND date(date) BETWEEN date(?) AND date(?)';
      params.add(startDate.toIso8601String());
      params.add(endDate.toIso8601String());
    }
    
    if (category != null && category.isNotEmpty) {
      query += ' AND category = ?';
      params.add(category);
    }
    
    query += ' ORDER BY amount DESC LIMIT 5';
    
    final results = await db.rawQuery(query, params);
    
    print('Fetched filtered top 5 expenses: ${results.length} transactions');
    return results;
  }

  /// Get MoM comparison with optional filters
  Future<Map<String, dynamic>> getMonthOverMonthComparisonFiltered({
    String? category,
  }) async {
    final db = await database;
    
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final previousMonth = DateTime(now.year, now.month - 1).month == 0
        ? '${now.year - 1}-12'
        : '${now.year}-${(now.month - 1).toString().padLeft(2, '0')}';
    
    String whereClause = '';
    final params = <dynamic>[];
    
    if (category != null && category.isNotEmpty) {
      whereClause = ' AND category = ?';
      params.add(category);
    }
    
    final currentResults = await db.rawQuery(
      '''
      SELECT 
        SUM(CASE WHEN isIncome = 1 THEN amount ELSE 0 END) as income,
        SUM(CASE WHEN isIncome = 0 THEN amount ELSE 0 END) as expense
      FROM transactions
      WHERE strftime('%Y-%m', date) = ?
      $whereClause
      ''',
      [currentMonth, ...params],
    );
    
    final previousResults = await db.rawQuery(
      '''
      SELECT 
        SUM(CASE WHEN isIncome = 1 THEN amount ELSE 0 END) as income,
        SUM(CASE WHEN isIncome = 0 THEN amount ELSE 0 END) as expense
      FROM transactions
      WHERE strftime('%Y-%m', date) = ?
      $whereClause
      ''',
      [previousMonth, ...params],
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
    
    double incomePercentChange = 0.0;
    if (previousIncome > 0) {
      incomePercentChange = ((currentIncome - previousIncome) / previousIncome) * 100;
    } else if (currentIncome > 0) {
      incomePercentChange = 100.0;
    }
    
    double expensePercentChange = 0.0;
    if (previousExpense > 0) {
      expensePercentChange = ((currentExpense - previousExpense) / previousExpense) * 100;
    } else if (currentExpense > 0) {
      expensePercentChange = 100.0;
    }
    
    return {
      'current_income': currentIncome,
      'current_expense': currentExpense,
      'previous_income': previousIncome,
      'previous_expense': previousExpense,
      'income_percent_change': incomePercentChange,
      'expense_percent_change': expensePercentChange,
    };
  }

  // Account Management Methods
  Future<int> addAccount({
    required String name,
    required double initialBalance,
    required String accountType,
  }) async {
    final db = await database;
    return await db.insert(
      'accounts',
      {
        'name': name,
        'balance': initialBalance,
        'account_type': accountType,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAllAccounts() async {
    final db = await database;
    return await db.query(
      'accounts',
      orderBy: 'name ASC',
    );
  }

  Future<Map<String, dynamic>?> getAccountById(int id) async {
    final db = await database;
    final results = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateAccountBalance({
    required int accountId,
    required double newBalance,
  }) async {
    final db = await database;
    await db.update(
      'accounts',
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  Future<void> deleteAccount(int id) async {
    final db = await database;
    await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateAccount({
    required int id,
    required String name,
    required double balance,
    required String accountType,
  }) async {
    final db = await database;
    await db.update(
      'accounts',
      {
        'name': name,
        'balance': balance,
        'account_type': accountType,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalBalanceByType(String accountType) async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT SUM(balance) as total FROM accounts WHERE account_type = ?',
      [accountType],
    );
    if (results.isNotEmpty) {
      return ((results.first['total'] ?? 0) as num).toDouble();
    }
    return 0.0;
  }

  /// Get spending by source (account name)
  /// Returns list of {account_name, account_type, total_expense} for all expenses
  Future<List<Map<String, dynamic>>> getSpendingBySource() async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT 
        a.name as account_name,
        a.account_type,
        SUM(t.amount) as total_expense,
        COUNT(t.id) as transaction_count
      FROM transactions t
      LEFT JOIN accounts a ON t.account_id = a.id
      WHERE t.isIncome = 0
      GROUP BY t.account_id
      ORDER BY total_expense DESC
      ''',
    );
    
    print('Fetched spending by source: ${results.length} accounts');
    return results;
  }

  /// Get spending by source for a specific date range
  Future<List<Map<String, dynamic>>> getSpendingBySourceFiltered({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    
    String query = '''
      SELECT 
        a.name as account_name,
        a.account_type,
        SUM(t.amount) as total_expense,
        COUNT(t.id) as transaction_count
      FROM transactions t
      LEFT JOIN accounts a ON t.account_id = a.id
      WHERE t.isIncome = 0
    ''';
    final params = <dynamic>[];
    
    if (startDate != null && endDate != null) {
      query += ' AND date(t.date) BETWEEN date(?) AND date(?)';
      params.add(startDate.toIso8601String());
      params.add(endDate.toIso8601String());
    }
    
    query += ' GROUP BY t.account_id ORDER BY total_expense DESC';
    
    final results = await db.rawQuery(query, params);
    print('Fetched filtered spending by source: ${results.length} accounts');
    return results;
  }

  // ============ Budget Operations ============

  /// Get monthly budget (overall limit)
  Future<double> getMonthlyBudget() async {
    final db = await database;
    final results = await db.query('monthly_budget', where: 'id = 1');
    if (results.isNotEmpty) {
      return (results.first['budget_amount'] as num).toDouble();
    }
    return 5000.0; // Default budget
  }

  /// Set monthly budget
  Future<void> setMonthlyBudget(double amount) async {
    final db = await database;
    await db.insert(
      'monthly_budget',
      {
        'id': 1,
        'budget_amount': amount,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('Monthly budget set to €$amount');
  }

  /// Get all category budgets
  Future<List<Map<String, dynamic>>> getAllCategoryBudgets() async {
    final db = await database;
    final results = await db.query('budgets', orderBy: 'category ASC');
    return results;
  }

  /// Get budget for specific category
  Future<double?> getCategoryBudget(String category) async {
    final db = await database;
    final results = await db.query(
      'budgets',
      where: 'category = ?',
      whereArgs: [category],
    );
    if (results.isNotEmpty) {
      return (results.first['budget_amount'] as num).toDouble();
    }
    return null;
  }

  /// Set category budget (insert or update)
  Future<void> setCategoryBudget(String category, double amount) async {
    final db = await database;
    await db.insert(
      'budgets',
      {
        'category': category,
        'budget_amount': amount,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('Budget for $category set to €$amount');
  }

  /// Delete category budget
  Future<void> deleteCategoryBudget(String category) async {
    final db = await database;
    await db.delete('budgets', where: 'category = ?', whereArgs: [category]);
    print('Budget for $category deleted');
  }

  /// Get all categories that have budgets
  Future<List<String>> getBudgetedCategories() async {
    final db = await database;
    final results = await db.query('budgets', columns: ['category']);
    return results.map((row) => row['category'] as String).toList();
  }

  /// Get spending by day filtered by date range
  Future<Map<String, double>> getSpendingByDayFiltered({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    
    String query = '''
      SELECT 
        date(date) as day,
        SUM(amount) as total
      FROM transactions
      WHERE isIncome = 0
    ''';
    final params = <dynamic>[];
    
    if (startDate != null && endDate != null) {
      query += ' AND date(date) BETWEEN date(?) AND date(?)';
      params.add(startDate.toIso8601String());
      params.add(endDate.toIso8601String());
    }
    
    query += ' GROUP BY day ORDER BY day ASC';
    
    final results = await db.rawQuery(query, params);
    
    final dailyMap = <String, double>{};
    for (final row in results) {
      final day = row['day'] as String;
      final total = ((row['total'] ?? 0) as num).toDouble();
      dailyMap[day] = total;
    }
    
    print('Fetched filtered daily spending: ${results.length} days with data');
    return dailyMap;
  }

  /// Get spending by month filtered by date range
  Future<Map<String, double>> getSpendingByMonthFiltered({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    
    String query = '''
      SELECT 
        strftime('%Y-%m', date) as month,
        SUM(amount) as total
      FROM transactions
      WHERE isIncome = 0
    ''';
    final params = <dynamic>[];
    
    if (startDate != null && endDate != null) {
      query += ' AND date(date) BETWEEN date(?) AND date(?)';
      params.add(startDate.toIso8601String());
      params.add(endDate.toIso8601String());
    }
    
    query += ' GROUP BY month ORDER BY month ASC';
    
    final results = await db.rawQuery(query, params);
    
    final monthlyMap = <String, double>{};
    for (final row in results) {
      final month = row['month'] as String;
      final total = ((row['total'] ?? 0) as num).toDouble();
      monthlyMap[month] = total;
    }
    
    print('Fetched filtered monthly spending: ${results.length} months with data');
    return monthlyMap;
  }
}

