import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../data/models/product.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'shelfie_channel';
  static const _channelName = 'Shelfie';
  static const _channelDesc = 'Напоминания о продуктах';

  /// Порог «залежался» — сколько дней продукт лежит без изменений.
  static const _staleDays = 14;

  Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      final TimezoneInfo currentTimeZone =
          await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone.identifier));
      debugPrint('NotificationService: tz local = ${tz.local.name}');

      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();

      _initialized = true;
      debugPrint('NotificationService: init complete');
    } catch (e, st) {
      debugPrint('NotificationService: init failed: $e\n$st');
    }
  }

  /// Выбирает режим: точный, если разрешено, иначе неточный.
  Future<AndroidScheduleMode> _scheduleMode() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canExact =
        await androidPlugin?.canScheduleExactNotifications() ?? false;
    return canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Планирует напоминание о сроке годности.
  /// Если срок уже прошёл или истекает сегодня — пуш придёт через 10 секунд.
  /// Если срок в будущем — за 2 дня до истечения.
  Future<void> scheduleExpiryReminder(Product product) async {
    final expiry = product.expiryDate;
    if (expiry == null) return;

    final today = DateTime.now();
    final endOfExpiryDay = DateTime(expiry.year, expiry.month, expiry.day, 23, 59, 59);
    final DateTime when;

    if (!endOfExpiryDay.isAfter(today)) {
      // Срок сегодня или уже в прошлом — показываем сразу.
      when = today.add(const Duration(seconds: 10));
    } else {
      final notifyAt = expiry.subtract(const Duration(days: 2));
      when = notifyAt.isBefore(today)
          ? today.add(const Duration(seconds: 10))
          : notifyAt;
    }

    try {
      final mode = await _scheduleMode();
      await _plugin.zonedSchedule(
        _notificationId(product.id, 'expiry'),
        'Срок годности истекает',
        '${product.name} (${product.category.label}) '
            '— срок до ${_fmtDate(expiry)}',
        tz.TZDateTime.from(when, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: mode,
        payload: product.id,
      );
      debugPrint('scheduleExpiry: scheduled for $when');
    } catch (e, st) {
      debugPrint('scheduleExpiry: FAILED: $e\n$st');
    }
  }

  /// Планирует напоминание «продукт лежит без изменений 14 дней».
  /// Если продукт добавлен ≥ 14 дней назад — пуш придёт через 10 секунд.
  /// Если меньше — на addedAt + 14 дней.
  Future<void> scheduleStaleReminder(Product product) async {
    final now = DateTime.now();
    final staleAt = product.addedAt.add(const Duration(days: _staleDays));
    final actualDays = now.difference(product.addedAt).inDays;

    final DateTime when;
    if (!staleAt.isAfter(now)) {
      // Продукт уже «перележал» порог — показываем сразу.
      when = now.add(const Duration(seconds: 10));
    } else {
      when = staleAt;
    }

    final daysText = actualDays > 0 ? actualDays : _staleDays;

    try {
      final mode = await _scheduleMode();
      await _plugin.zonedSchedule(
        _notificationId(product.id, 'stale'),
        'Продукт залежался',
        '${product.name} лежит уже $daysText дней. Проверьте, всё ли в порядке.',
        tz.TZDateTime.from(when, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: mode,
        payload: product.id,
      );
      debugPrint('scheduleStale: scheduled for $when ($daysText дней)');
    } catch (e, st) {
      debugPrint('scheduleStale: FAILED: $e\n$st');
    }
  }

  Future<void> cancelForProduct(String productId) async {
    await _plugin.cancel(_notificationId(productId, 'expiry'));
    await _plugin.cancel(_notificationId(productId, 'stale'));
  }

  /// Генерирует 32-битный id в допустимом диапазоне плагина.
  int _notificationId(String productId, String kind) {
    final base = productId.hashCode & 0x1FFFFFFF;
    final kindBit = kind == 'expiry' ? 1 : 2;
    return (base << 1) | kindBit;
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}