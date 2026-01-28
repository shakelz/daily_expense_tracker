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
}
