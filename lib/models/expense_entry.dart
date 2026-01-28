class ExpenseEntry {
  final int? id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final bool isIncome;

  const ExpenseEntry({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.isIncome,
  });

  /// Convert ExpenseEntry to a Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'isIncome': isIncome ? 1 : 0,
    };
  }

  /// Create ExpenseEntry from database Map
  factory ExpenseEntry.fromMap(Map<String, dynamic> map) {
    return ExpenseEntry(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: map['amount'] as double,
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      isIncome: (map['isIncome'] as int) == 1,
    );
  }
}
