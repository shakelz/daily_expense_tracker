import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  factory NotificationHelper() {
    return _instance;
  }

  NotificationHelper._internal();

  /// Initialize local notifications
  Future<void> init() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android initialization settings
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    print('✓ Notifications initialized');
  }

  /// Handle notification response (when user taps notification)
  void _onNotificationResponse(NotificationResponse response) {
    print('Notification response: ${response.payload}');
    // Payload can contain action info like "add_transaction:123"
    if (response.payload != null && response.payload!.startsWith('add_recurring:')) {
      final recurringId = response.payload!.replaceFirst('add_recurring:', '');
      print('User wants to add recurring payment $recurringId now');
      // This will be handled by the app's main logic
    }
  }

  /// Show notification for due recurring payment
  Future<void> showRecurringPaymentNotification({
    required int id,
    required String title,
    required double amount,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'recurring_payments_channel',
      'Recurring Payments',
      channelDescription: 'Notifications for due recurring payments',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      actions: [
        AndroidNotificationAction(
          'add_now',
          'Add Now',
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'dismiss',
          'Dismiss',
          cancelNotification: true,
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final message = 'Miyan, €${amount.toStringAsFixed(2)} for $title is due today.';

    await _flutterLocalNotificationsPlugin.show(
      id,
      'Recurring Payment Due',
      message,
      platformDetails,
      payload: 'add_recurring:$id',
    );

    print('✓ Notification shown for: $title (€$amount)');
  }

  /// Show a general notification
  Future<void> showGeneralNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'general_channel',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformDetails,
      payload: payload,
    );

    print('✓ General notification shown: $title');
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    print('✓ Notification $id cancelled');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    print('✓ All notifications cancelled');
  }

  /// Request notification permissions (Android 13+)
  Future<bool> requestPermissions() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    final android = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    final ios = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    // Request Android notification permission (Android 13+)
    final androidGranted = await android?.requestNotificationsPermission() ?? true;

    // Request iOS notification permission
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    ) ?? true;

    return androidGranted && iosGranted;
  }
}
