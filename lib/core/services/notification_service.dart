import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    try {
      await _notificationsPlugin.initialize(settings: initSettings);
      _initialized = true;
    } catch (_) {
      // Platform unsupported or testing environment
    }
  }

  Future<void> showBudgetWarning({
    required int id,
    required String budgetName,
    required double percent,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'budget_channel',
      'Budget Alerts',
      channelDescription: 'Notifications when approaching or exceeding budgets',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);
    try {
      await _notificationsPlugin.show(
        id: id,
        title: 'Budget Alert: $budgetName',
        body: 'You have consumed ${percent.toStringAsFixed(1)}% of your budget limit.',
        notificationDetails: details,
      );
    } catch (_) {}
  }

  Future<void> showBillDueReminder({
    required int id,
    required String title,
    required int amountCents,
    required DateTime dueDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'bill_channel',
      'Bill & Recurring Payment Due Reminders',
      channelDescription: 'Reminders for upcoming bills and recurring commitments',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);
    try {
      await _notificationsPlugin.show(
        id: id,
        title: 'Bill Due: $title',
        body: 'Payment of ${CurrencyFormatter.formatCents(amountCents)} is due on ${DateFormatter.formatDate(dueDate)}.',
        notificationDetails: details,
      );
    } catch (_) {}
  }
}
