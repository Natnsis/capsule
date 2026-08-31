import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';

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
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails('capsule_due', 'Capsule reminders',
              importance: Importance.high, priority: Priority.high),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
          linux: LinuxNotificationDetails(),
        ),
      );
    } catch (_) {}
  }
}
