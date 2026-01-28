import 'package:workmanager/workmanager.dart';

import 'database_helper.dart';
import 'notification_helper.dart';

class RecurringPaymentService {
  static final RecurringPaymentService _instance =
      RecurringPaymentService._internal();
  final DatabaseHelper _db = DatabaseHelper();
  final NotificationHelper _notificationHelper = NotificationHelper();

  static const String uniqueName = 'checkRecurringPayments';

  factory RecurringPaymentService() {
    return _instance;
  }

  RecurringPaymentService._internal();

  /// Initialize recurring payment background task
  Future<void> initBackgroundTask() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: true,
      );

      // Schedule daily check - WorkManager will run it daily
      await Workmanager().registerPeriodicTask(
        uniqueName,
        'checkRecurringPaymentsTask',
        frequency: const Duration(days: 1),
        initialDelay: const Duration(seconds: 10),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 5),
      );

      print('✓ Recurring payment background task scheduled');
    } catch (e) {
      print('✗ Error initializing background task: $e');
    }
  }

  /// Cancel background task
  Future<void> cancelBackgroundTask() async {
    try {
      await Workmanager().cancelByUniqueName(uniqueName);
      print('✓ Background task cancelled');
    } catch (e) {
      print('✗ Error cancelling background task: $e');
    }
  }

  /// Check and execute due recurring payments
  Future<void> checkAndExecuteDuePayments() async {
    try {
      print('=== Checking for due recurring payments ===');

      final duePayments = await _db.getDueRecurringPayments();

      if (duePayments.isEmpty) {
        print('No payments due today');
        return;
      }

      print('Found ${duePayments.length} due payment(s)');

      for (final payment in duePayments) {
        final id = payment['id'] as int;
        final title = payment['title'] as String;
        final amount = payment['amount'] as double;
        final category = payment['category'] as String;
        final isIncome = payment['isIncome'] == 1;
        final lastExecuted = payment['last_executed'];

        // Check if already executed today
        if (lastExecuted != null) {
          final lastExecDate = DateTime.parse(lastExecuted as String);
          final today = DateTime.now();

          if (lastExecDate.year == today.year &&
              lastExecDate.month == today.month &&
              lastExecDate.day == today.day) {
            print('Payment $id already executed today, skipping');
            continue;
          }
        }

        // Insert transaction for this recurring payment
        await _db.insertTransaction(
          title: title,
          amount: amount,
          category: category,
          date: DateTime.now().toIso8601String(),
          isIncome: isIncome,
        );

        // Update last executed timestamp
        await _db.updateRecurringPaymentLastExecuted(id);

        // Show notification
        await _notificationHelper.showRecurringPaymentNotification(
          id: id,
          title: title,
          amount: amount,
        );

        print('✓ Executed recurring payment: $title (€$amount)');
      }

      print('=== Done checking recurring payments ===\n');
    } catch (e) {
      print('✗ Error checking recurring payments: $e');
    }
  }

  /// Get average daily spend (for forecasting)
  Future<double> getAverageDailySpend({int days = 30}) async {
    try {
      final today = DateTime.now();
      final startDate = today.subtract(Duration(days: days));

      final transactions = await _db.getAllTransactions(
        startDate: startDate,
        endDate: today,
      );

      // Filter only expenses (not income)
      double totalExpenses = 0;
      for (final txn in transactions) {
        if (txn['isIncome'] == 0) {
          totalExpenses += txn['amount'] as double;
        }
      }

      final average = totalExpenses / days;
      print('Average daily spend (last $days days): €${average.toStringAsFixed(2)}');
      return average;
    } catch (e) {
      print('✗ Error calculating average daily spend: $e');
      return 0.0;
    }
  }

  /// Forecast expenses for remainder of month
  /// Formula: Forecast = Average_Daily_Spend × Days_Remaining + Sum_of_Pending_Recurring
  Future<double> forecastMonthlyExpenses() async {
    try {
      final today = DateTime.now();
      final lastDayOfMonth =
          DateTime(today.year, today.month + 1, 0).day;
      final daysRemaining = lastDayOfMonth - today.day;

      // Get average daily spend
      final avgDailySpend = await getAverageDailySpend(days: 30);

      // Get sum of pending recurring payments due this month
      final allRecurring = await _db.getAllRecurringPayments();
      double sumRecurring = 0;

      for (final payment in allRecurring) {
        final dayOfMonth = payment['day_of_month'] as int;
        final isIncome = payment['isIncome'] == 1;

        // Only count future expenses (not income)
        if (dayOfMonth > today.day && !isIncome) {
          sumRecurring += payment['amount'] as double;
        }
      }

      final forecast = (avgDailySpend * daysRemaining) + sumRecurring;

      print('Forecast for ${daysRemaining} days + recurring: €${forecast.toStringAsFixed(2)}');
      return forecast;
    } catch (e) {
      print('✗ Error forecasting expenses: $e');
      return 0.0;
    }
  }

  /// Get total pending recurring payments (income and expenses)
  Future<Map<String, double>> getPendingRecurringSummary() async {
    try {
      final today = DateTime.now();
      final allRecurring = await _db.getAllRecurringPayments();

      double incomeSum = 0;
      double expenseSum = 0;

      for (final payment in allRecurring) {
        final dayOfMonth = payment['day_of_month'] as int;
        final isIncome = payment['isIncome'] == 1;
        final amount = payment['amount'] as double;

        // Only count future payments
        if (dayOfMonth >= today.day) {
          if (isIncome) {
            incomeSum += amount;
          } else {
            expenseSum += amount;
          }
        }
      }

      return {
        'income': incomeSum,
        'expenses': expenseSum,
        'net': incomeSum - expenseSum,
      };
    } catch (e) {
      print('✗ Error getting pending summary: $e');
      return {'income': 0.0, 'expenses': 0.0, 'net': 0.0};
    }
  }
}

/// Top-level function for background task execution
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == 'checkRecurringPaymentsTask') {
      final service = RecurringPaymentService();
      await service.checkAndExecuteDuePayments();
      return true;
    }
    return false;
  });
}
