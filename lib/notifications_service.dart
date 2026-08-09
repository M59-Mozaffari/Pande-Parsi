import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pande_parsi/models/pand.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:pande_parsi/databases/local_dtb.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _baseId = 1000;
  static const int _daysToSchedule = 30;

  String? initialPayload;
  bool _isScheduling = false;

  // ================= INIT =================
  Future<void> init({
    required void Function(NotificationResponse response)
    onDidReceiveNotificationResponse,
  }) async {
    tz.initializeTimeZones();

    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }

    const androidInit = AndroidInitializationSettings(
      'ic_stat_ic_notification',
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    final details = await _plugin.getNotificationAppLaunchDetails();
    initialPayload = details?.notificationResponse?.payload;

    final androidImpl =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
  }

  // ================= SMART GAP =================

  int _randomGapMinutes(Random rnd) {
    return (3 * 60) + rnd.nextInt(3 * 60); // 3 تا 6 ساعت
  }

  // ================= CLEAN OLD =================

  Future<void> _cancelPandNotifications() async {
    final pending = await _plugin.pendingNotificationRequests();

    for (final n in pending) {
      if (n.id >= _baseId) {
        await _plugin.cancel(n.id);
      }
    }
  }

  // ================= BUILD QUEUE =================

  Future<List<Pand>> _buildQueue(List<Pand> all) async {
    final db = LocalDtb.instance;

    List<Pand> newPands = [];
    List<Pand> oldPands = [];

    for (final p in all) {
      final id = p.id;
      if (id == null) continue;

      final count = await db.getShownCount(id);

      if (count == 0) {
        newPands.add(p); // 🔥 اولویت بالا
      } else if (count < 2) {
        oldPands.add(p);
      }
    }

    /// اگر همه مصرف شدند → ریست
    if (newPands.isEmpty && oldPands.isEmpty) {
      await db.resetAllShownCounts();
      return _buildQueue(all);
    }

    newPands.shuffle();
    oldPands.shuffle();

    return [...newPands, ...oldPands];
  }

  // ================= SCHEDULE =================

  Future<void> scheduleAdvanced() async {
    if (_isScheduling) return;
    _isScheduling = true;

    await _cancelPandNotifications();

    final db = LocalDtb.instance;
    final allPands = await db.getAllPands();

    if (allPands.isEmpty) {
      _isScheduling = false;
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    final rnd = Random();

    List<Pand> queue = await _buildQueue(allPands);
    int qIndex = 0;

    int id = _baseId;

    for (int d = 0; d < _daysToSchedule; d++) {
      final baseDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + d,
      );

      int lastMinutes = 8 * 60; // شروع از 8 صبح

      for (int i = 0; i < 2; i++) {
        if (qIndex >= queue.length) {
          queue = await _buildQueue(allPands);
          qIndex = 0;
        }

        final pand = queue[qIndex++];
        final pandId = pand.id;
        if (pandId == null) continue;

        lastMinutes += _randomGapMinutes(rnd);

        if (lastMinutes > 22 * 60) {
          lastMinutes = 22 * 60;
        }

        var time = baseDate.add(Duration(minutes: lastMinutes));

        if (!time.isAfter(now)) {
          time = time.add(const Duration(days: 1));
        }

        await db.incrementShownCount(pandId);

        await _plugin.zonedSchedule(
          id++,
          pand.title,
          pand.sentence,
          time,
          _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: pandId.toString(),
        );
      }
    }

    _isScheduling = false;
  }

  // ================= ENSURE =================

  Future<void> ensureAdvanced() async {
    final pending = await _plugin.pendingNotificationRequests();

    final pandNotifs = pending.where((n) => n.id >= _baseId).toList();

    final db = LocalDtb.instance;
    final allPands = await db.getAllPands();

    /// 🔥 اگر نوتیف‌ها کم شدند یا دیتابیس تغییر کرد
    if (pandNotifs.length < 10 || pandNotifs.length < allPands.length) {
      await scheduleAdvanced();
    }
  }

  // ================= FOREGROUND =================

  Future<void> showForeground(Pand pand) async {
    final id = pand.id;
    if (id == null) return;

    await _plugin.show(
      9999,
      pand.title,
      pand.sentence,
      _details,
      payload: id.toString(),
    );
  }

  // ================= CLEAR =================

  /// 🔥 فقط برای تست
  // Future<void> clearAllNotifications() async {
  //   await _plugin.cancelAll();
  // }

  // ================= DETAILS =================

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'pands_daily',
      'Pands Daily',
      channelDescription: 'پندهای روزانه',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_ic_notification',
      color: Color(0xFF44300b),
    ),
  );
}
