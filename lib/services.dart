import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'tokens.dart';

/// Platform channel to the host for things no plugin covers (e.g. opening the
/// OS biometric-enrollment screen). Mirrors `capsule/system` in MainActivity.
const _systemChannel = MethodChannel('capsule/system');

/// Device biometric unlock. On platforms without a real sensor (desktop) it
/// falls back to an explicit "confirm it's you" dialog so the gate still works.
class Biometrics {
  Biometrics._();
  static final Biometrics instance = Biometrics._();

  final _auth = LocalAuthentication();
  bool? _available;

  Future<bool> get isAvailable async {
    if (_available != null) return _available!;
    try {
      _available = await _auth.isDeviceSupported() &&
          await _auth.canCheckBiometrics;
    } catch (_) {
      _available = false;
    }
    return _available!;
  }

  /// True only when the device actually has a fingerprint / face enrolled that
  /// this app can use — the real "is it set up in phone settings" check.
  /// Always queried fresh so it reflects changes made while the app is open.
  Future<bool> get isEnrolled async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Opens the OS screen where the user adds a fingerprint / face unlock.
  /// Returns false if the host couldn't launch it.
  Future<bool> openEnrollment() async {
    try {
      final ok = await _systemChannel.invokeMethod<bool>('openBiometricEnroll');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Returns true only if the user passed the check.
  Future<bool> authenticate(BuildContext context, String reason) async {
    if (await isAvailable) {
      try {
        return await _auth.authenticate(
          localizedReason: reason,
          biometricOnly: true,
          persistAcrossBackgrounding: true,
        );
      } catch (_) {
        return false;
      }
    }
    // No sensor: explicit confirmation stands in for the biometric prompt.
    if (!context.mounted) return false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.isDark ? C.lav1 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Confirm it’s you',
            style: C.t(18, weight: FontWeight.w800, color: C.ink)),
        content: Text(reason, style: C.t(14, color: C.bodyInk, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: C.t(14, weight: FontWeight.w700, color: C.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Confirm', style: C.t(14, weight: FontWeight.w800, color: C.ink)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}

/// OS notifications + the notification permission. Everything degrades to a
/// no-op when the platform/plugin can't do it, so the in-app feed still works.
class Notifier {
  Notifier._();
  static final Notifier instance = Notifier._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
          macOS: DarwinInitializationSettings(),
          linux: LinuxInitializationSettings(defaultActionName: 'Open'),
        ),
      );
      _inited = true;
    } catch (_) {
      _inited = false;
    }
  }

  bool get _hasOsGate => Platform.isAndroid || Platform.isIOS;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails('capsule_due', 'Capsule reminders',
        importance: Importance.high, priority: Priority.high),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
    linux: LinuxNotificationDetails(),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Whether the OS will honour exact-time alarms for this app. Android 14+
  /// denies "Alarms & reminders" by default; on 12–13 it's on unless revoked.
  /// Non-Android platforms schedule exactly anyway → true.
  Future<bool> canScheduleExact() async {
    if (!Platform.isAndroid) return true;
    try {
      return (await _android?.canScheduleExactNotifications()) ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Opens the system "Alarms & reminders" screen so the user can allow exact
  /// alarms. No-op off Android.
  Future<void> requestExactAlarm() async {
    if (!Platform.isAndroid) return;
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  /// Asks the OS to exempt the app from battery optimisation — aggressive OEM
  /// power managers (Xiaomi, Huawei, Oppo…) otherwise defer or drop the alarm.
  /// Returns true when the app is (now) exempt.
  Future<bool> requestBatteryException() async {
    if (!Platform.isAndroid) return true;
    try {
      if (await Permission.ignoreBatteryOptimizations.isGranted) return true;
      final res = await Permission.ignoreBatteryOptimizations.request();
      return res.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Hands the OS a one-shot alarm that fires at [when] even if the app is
  /// closed or swiped away. Uses an exact ("alarm clock") alarm when the OS
  /// allows it, falling back to an inexact one otherwise so a notification
  /// still lands. [id] is stable per capsule, so scheduling again replaces the
  /// pending alarm rather than stacking a duplicate. A [when] in the past just
  /// shows the notification now.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    await init();
    if (!_inited || !_hasOsGate) return;
    if (!when.isAfter(DateTime.now())) {
      await show(title, body);
      return;
    }
    // Schedule by absolute instant; the UTC location keeps the epoch exact
    // without needing the device's IANA zone name.
    final at = tz.TZDateTime.from(when.toUtc(), tz.UTC);
    final exact = await canScheduleExact();
    Future<void> put(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: at,
          notificationDetails: _details,
          androidScheduleMode: mode,
        );
    try {
      await put(exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle);
    } on PlatformException catch (e) {
      // Exact permission was pulled between the check and the call.
      if (e.code == 'exact_alarms_not_permitted') {
        try {
          await put(AndroidScheduleMode.inexactAllowWhileIdle);
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Drops a pending scheduled alarm (capsule opened, deleted, or its date /
  /// the global open-time changed).
  Future<void> cancel(int id) async {
    await init();
    if (!_inited) return;
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  Future<bool> get isGranted async {
    try {
      if (_hasOsGate) return await Permission.notification.isGranted;
    } catch (_) {}
    // Desktop: treat as granted (no OS gate to route to).
    return !_hasOsGate;
  }

  /// Whether the OS will still show a permission prompt, or the user has to go
  /// to Settings to change it.
  Future<bool> get isPermanentlyDenied async {
    try {
      if (_hasOsGate) return await Permission.notification.isPermanentlyDenied;
    } catch (_) {}
    return false;
  }

  Future<bool> request() async {
    try {
      if (_hasOsGate) {
        final res = await Permission.notification.request();
        return res.isGranted;
      }
    } catch (_) {}
    return true;
  }

  /// Sends the user to the OS settings page for this app.
  Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (_) {}
  }

  Future<void> show(String title, String body) async {
    await init();
    if (!_inited) return;
    try {
      await _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: _details,
      );
    } catch (_) {}
  }
}
